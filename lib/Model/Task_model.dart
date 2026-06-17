import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String? id;
  String title;
  String description;
  String assigneeType; // 'Department' or 'Person'
  String assignedToId;
  String assignedToName;
  String status; // 'Pending', 'In Progress', 'Completed'
  String priority; // 'Low', 'Medium', 'High'
  DateTime? createdAt;

  TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.assigneeType,
    required this.assignedToId,
    required this.assignedToName,
    this.status = 'Pending',
    this.priority = 'Medium',
    this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return TaskModel(
      id: docId ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assigneeType: json['assigneeType'] ?? 'Person',
      assignedToId: json['assignedToId'] ?? '',
      assignedToName: json['assignedToName'] ?? '',
      status: json['status'] ?? 'Pending',
      priority: json['priority'] ?? 'Medium',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'assigneeType': assigneeType,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'status': status,
      'priority': priority,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
