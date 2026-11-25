import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAllSchools() async {
    try {
      final snapshot = await _db.collection('schools').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Ensure schoolId is available (fallback to doc.id if missing)
        if (!data.containsKey('schoolId')) {
          data['schoolId'] = doc.id;
        }
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching schools: $e");
      return [];
    }
  }

  Future<void> lockSchool(
    String schoolId, {
    required String reason,
    required String lockedBy,
  }) async {
    try {
      await _db.collection('schools').doc(schoolId).set({
        'isLocked': true,
        'lockedReason': reason,
        'lockedAt': FieldValue.serverTimestamp(),
        'lockedBy': lockedBy,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error locking school in repository: $e");
      rethrow;
    }
  }

  Future<void> unlockSchool(
    String schoolId, {
    required String unlockedBy,
  }) async {
    try {
      await _db.collection('schools').doc(schoolId).set({
        'isLocked': false,
        'lockedReason': null,
        'lockedAt': null,
        'lockedBy': null,
        'unlockedAt': FieldValue.serverTimestamp(),
        'unlockedBy': unlockedBy,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error unlocking school in repository: $e");
      rethrow;
    }
  }

  Future<bool> isSchoolLocked(String schoolId) async {
    try {
      final doc = await _db.collection('schools').doc(schoolId).get();
      if (doc.exists) {
        return doc.data()?['isLocked'] == true;
      }
      return false;
    } catch (e) {
      print("Error checking school lock status: $e");
      return false;
    }
  }
}
