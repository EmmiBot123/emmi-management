import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Testing/feedback_model.dart';

class TestingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// CREATE Feedback Document
  Future<bool> submitFeedback(TestingFeedback feedback) async {
    try {
      final String docId = feedback.id?.isNotEmpty == true
          ? feedback.id!
          : _firestore.collection('testing_feedback').doc().id;

      final feedbackData = feedback.toJson();
      feedbackData['id'] = docId; // Ensure ID is saved

      await _firestore
          .collection('testing_feedback')
          .doc(docId)
          .set(feedbackData);
      return true;
    } catch (e) {
      print("Firestore create feedback failed: $e");
      return false;
    }
  }

  /// GET All Feedback
  Future<List<TestingFeedback>> getAllFeedback() async {
    try {
      final snapshot = await _firestore
          .collection('testing_feedback')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TestingFeedback.fromJson(data);
      }).toList();
    } catch (e) {
      print("Error fetching all testing feedback from Firestore: $e");
      return [];
    }
  }

  /// GET All Feedback by section
  Future<List<TestingFeedback>> getFeedbackBySection(String section) async {
    try {
      final snapshot = await _firestore
          .collection('testing_feedback')
          .where('section', isEqualTo: section)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TestingFeedback.fromJson(data);
      }).toList();
    } catch (e) {
      print("Error fetching testing feedback from Firestore: $e");
      return [];
    }
  }
}
