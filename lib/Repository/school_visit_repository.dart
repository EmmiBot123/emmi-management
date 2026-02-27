import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Marketing/school_visit_model.dart';
import '../Resources/api_endpoints.dart';
import '../Services/api_service/api_service.dart';

class SchoolVisitRepository {
  final ApiService api = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// GET All by UserId from Firestore (Migrated Data)
  Future<List<SchoolVisit>> getVisitsFromFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('school_visits')
          .where('createdByUserId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SchoolVisit.fromJson(data);
      }).toList();
    } catch (e) {
      print("Error fetching visits from Firestore: $e");
      return [];
    }
  }

  /// GET All by UserId using AppConfig URL (Updated to check Firestore first)
  Future<List<SchoolVisit>> getVisits(String userId) async {
    // 1. Try fetching from Firestore (Migrated data)
    try {
      final firestoreVisits = await getVisitsFromFirestore(userId);
      if (firestoreVisits.isNotEmpty) {
        return firestoreVisits;
      }
    } catch (e) {
      print("Firestore fetch failed: $e");
    }

    // 2. Fallback to Legacy API (Only works if userId exists in legacy DB)
    try {
      final url = ApiEndpoints.getVisitsByID(userId);
      final response = await api.get(url);
      if (response == null) return [];
      return List.from(response).map((e) => SchoolVisit.fromJson(e)).toList();
    } catch (e) {
      print("Legacy API fetch failed: $e");
      return [];
    }
  }

  Future<List<SchoolVisit>> getVisitsShared(String userId) async {
    final url = ApiEndpoints.getVisitsBySharedId(userId);
    final response = await api.get(url);
    return List.from(response).map((e) => SchoolVisit.fromJson(e)).toList();
  }

  /// GET All by UserId using AppConfig URL
  Future<List<SchoolVisit>> getPaymentVisits() async {
    final url = ApiEndpoints.createVisit;
    final response = await api.get(url);
    return List.from(response).map((e) => SchoolVisit.fromJson(e)).toList();
  }

  /// CREATE Visit
  Future<bool> createVisit(SchoolVisit visit) async {
    // 1. Write to API (Legacy)
    try {
      final url = ApiEndpoints.createVisit;
      await api.post(url, visit.toJson());
    } catch (e) {
      print("API create failed: $e");
      // Continue to Firestore? Or fail?
      // If valid user (Firestore-only), API might fail. We should allow Firestore write.
    }

    // 2. Write to Firestore (New)
    try {
      // Ensure ID is generated if missing
      final String docId = visit.id?.isNotEmpty == true
          ? visit.id!
          : _firestore.collection('school_visits').doc().id;

      final visitData = visit.toJson();
      visitData['id'] = docId; // Ensure ID is in data

      await _firestore.collection('school_visits').doc(docId).set(visitData);
      return true;
    } catch (e) {
      print("Firestore create failed: $e");
      return false;
    }
  }

  /// UPDATE Visit
  Future<bool> updateVisit(SchoolVisit visit) async {
    if (visit.id == null) throw Exception("Visit ID missing!");

    // 1. Update API
    try {
      final url = ApiEndpoints.updateVisit(visit.id!);
      await api.put(url, visit.toJson());
    } catch (e) {
      print("API update failed: $e");
    }

    // 2. Update Firestore (Use set with merge to handle legacy docs that might not exist in Firestore yet)
    try {
      await _firestore
          .collection('school_visits')
          .doc(visit.id!)
          .set(visit.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print("Firestore update failed: $e");
      return false;
    }
  }

  /// DELETE Visit
  Future<bool> deleteVisit(String id) async {
    // 1. Delete from API
    try {
      final url = ApiEndpoints.deleteVisit(id);
      await api.delete(url);
    } catch (e) {
      print("API delete failed: $e");
    }

    // 2. Delete from Firestore
    try {
      await _firestore.collection('school_visits').doc(id).delete();
      return true;
    } catch (e) {
      print("Firestore delete failed: $e");
      return false;
    }
  }

  Future<bool> deleteVisitFiles(String id) async {
    final url = ApiEndpoints.deleteFileFolder(id);
    await api.delete(url);
    return true;
  }
}
