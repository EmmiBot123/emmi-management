import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/Task_model.dart';
import '../Model/TaskMessageModel.dart';

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

  /// Filtered tasks stream for individual employees or departments
  Stream<List<TaskModel>> getTasksForUserStream(String userId, String userRole) {
    final normalizedRole = userRole.trim().toUpperCase();
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data(), docId: doc.id))
          .where((task) {
        if (normalizedRole == 'SUPER_ADMIN' || normalizedRole == 'CEO' || normalizedRole == 'ADMIN') {
          return true;
        }
        if (task.assignedToId == userId) {
          return true;
        }
        if (task.assigneeType == 'Department') {
          final dept = task.assignedToName.trim().toUpperCase();
          if (dept == normalizedRole ||
              dept.contains(normalizedRole) ||
              normalizedRole.contains(dept)) {
            return true;
          }
        }
        return false;
      }).toList();
    });
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
      await _firestore.collection('tasks').doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("Error updating task status: $e");
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      // First clean up messages in subcollection
      final messagesSnap = await _firestore
          .collection('tasks')
          .doc(id)
          .collection('messages')
          .get();
      for (final doc in messagesSnap.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('tasks').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Error deleting task: $e");
      return false;
    }
  }

  /// 💬 Stream of work updates / chat messages for a specific task
  Stream<List<TaskMessageModel>> getTaskMessagesStream(String taskId) {
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskMessageModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }

  /// 💬 Send a pure-text work update
  Future<bool> sendTaskMessage(String taskId, TaskMessageModel message) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('messages')
          .add({
        'taskId': taskId,
        'senderId': message.senderId,
        'senderName': message.senderName,
        'senderRole': message.senderRole,
        'text': message.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update task's last activity
      await _firestore.collection('tasks').doc(taskId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Error sending task update: $e");
      return false;
    }
  }

  /// 🗑️ Delete a work update / message
  Future<bool> deleteTaskMessage(String taskId, String messageId) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      debugPrint("Error deleting task message: $e");
      return false;
    }
  }
}

