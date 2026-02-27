import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../Model/Marketing/school_visit_model.dart';
import '../Resources/api_endpoints.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Uses the IP directly as found in investigations
  // Note: ApiEndpoints.baseUrl is "http://35.154.150.95:3000"

  Future<Map<String, dynamic>?> findLegacyUser(String email) async {
    try {
      final Uri url = Uri.parse("${ApiEndpoints.baseUrl}/users");
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        final safeEmail = email.toLowerCase();

        // Find user by email
        final legacyUser = users.firstWhere(
          (u) => (u['email'] as String?)?.toLowerCase() == safeEmail,
          orElse: () => null,
        );
        return legacyUser;
      } else {
        print("Failed to fetch legacy users: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error finding legacy user: $e");
      return null;
    }
  }

  Future<List<SchoolVisit>> fetchLegacyVisits(String oldUserId) async {
    try {
      final url = Uri.parse("${ApiEndpoints.getVisitsByID(oldUserId)}");
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Assuming the model is correct and matches legacy response
        return data.map((json) => SchoolVisit.fromJson(json)).toList();
      } else {
        if (response.statusCode == 404) return [];
        throw Exception(
            "Failed to fetch legacy visits: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching legacy visits: $e");
      return [];
    }
  }

  Future<int> migrateVisitsToFirestore(
      List<SchoolVisit> visits, String newUserId) async {
    if (visits.isEmpty) return 0;

    int count = 0;
    WriteBatch batch = _firestore.batch();

    for (var visit in visits) {
      // Use the old ID as the Firestore document ID to preserve reference
      // If visit.id is null, generate one? Model says String? id.
      final String docId = visit.id?.isNotEmpty == true
          ? visit.id!
          : _firestore.collection('school_visits').doc().id;
      final docRef = _firestore.collection('school_visits').doc(docId);

      // Create a map to update
      final visitJson = visit.toJson();

      // Update creator to new Firebase User ID
      visitJson['createdByUserId'] = newUserId;
      // We can also update 'createdByName' if we have the new name, but keeping original might be safer for history?
      // Let's assume we keep the name as is or update it from AuthProvider if needed.

      // Add migration metadata
      visitJson['migration'] = {
        'originalId': visit.id,
        'migratedAt': FieldValue.serverTimestamp(),
        'source': 'legacy_api',
      };

      batch.set(docRef, visitJson, SetOptions(merge: true));
      count++;

      // Firestore batch limit is 500
      if (count % 400 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    if (count > 0) {
      await batch.commit(); // Commit remaining
    }

    return count;
  }

  /// Run the full migration for a given email and new UID
  /// Returns a status message.
  Future<String> runMigration(String email, String newUid) async {
    try {
      final legacyUser = await findLegacyUser(email);
      if (legacyUser == null) {
        return "No legacy account found for $email.";
      }

      final String? oldId = legacyUser['id'] ?? legacyUser['_id'];
      if (oldId == null) return "Legacy account found but ID is missing.";

      final visits = await fetchLegacyVisits(oldId);
      if (visits.isEmpty) {
        return "Account found (ID: $oldId), but no visits to migrate.";
      }

      final count = await migrateVisitsToFirestore(visits, newUid);
      return "Success: Migrated $count visits from legacy ID $oldId.";
    } catch (e) {
      return "Migration Error: $e";
    }
  }
}
