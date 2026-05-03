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
}
