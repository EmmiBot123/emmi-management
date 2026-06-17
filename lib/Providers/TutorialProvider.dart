import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Tutorial_model.dart';

class TutorialProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TutorialModel>> get tutorialsStream {
    return _firestore
        .collection('tutorials')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TutorialModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }

  Future<bool> addTutorial(TutorialModel tutorial) async {
    try {
      await _firestore.collection('tutorials').add(tutorial.toJson());
      return true;
    } catch (e) {
      debugPrint("Error adding tutorial: $e");
      return false;
    }
  }

  Future<bool> deleteTutorial(String id) async {
    try {
      await _firestore.collection('tutorials').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Error deleting tutorial: $e");
      return false;
    }
  }
}
