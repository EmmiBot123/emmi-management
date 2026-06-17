import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Task_model.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TaskModel>> get tasksStream {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }

  Future<bool> addTask(TaskModel task) async {
    try {
      await _firestore.collection('tasks').add(task.toJson());
      return true;
    } catch (e) {
      debugPrint("Error adding task: $e");
      return false;
    }
  }

  Future<bool> updateTaskStatus(String id, String status) async {
    try {
      await _firestore.collection('tasks').doc(id).update({'status': status});
      return true;
    } catch (e) {
      debugPrint("Error updating task status: $e");
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _firestore.collection('tasks').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Error deleting task: $e");
      return false;
    }
  }
}
