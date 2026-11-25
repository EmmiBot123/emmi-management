import 'package:cloud_firestore/cloud_firestore.dart';

class TaskMessageModel {
  final String? id;
  final String taskId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime createdAt;

  const TaskMessageModel({
    this.id,
    required this.taskId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  factory TaskMessageModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    DateTime parsedDate;
    if (json['createdAt'] is Timestamp) {
      parsedDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      parsedDate = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return TaskMessageModel(
      id: docId ?? json['id'],
      taskId: json['taskId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Anonymous',
      senderRole: json['senderRole'] ?? 'STAFF',
      text: json['text'] ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskMessageModel copyWith({
    String? id,
    String? taskId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    DateTime? createdAt,
  }) {
    return TaskMessageModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper to check if a user is permitted to delete this message
  bool canDelete(String currentUserId, String currentUserRole) {
    if (currentUserId.isNotEmpty && currentUserId == senderId) {
      return true;
    }
    final normalized = currentUserRole.trim().toUpperCase();
    return normalized == 'SUPER_ADMIN' || normalized == 'CEO' || normalized == 'ADMIN';
  }
}
