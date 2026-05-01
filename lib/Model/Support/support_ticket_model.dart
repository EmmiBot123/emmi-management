import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String? id;
  final String email;
  final String message;
  final String chatHistory;
  final String status;
  final String? adminResponse;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    this.id,
    required this.email,
    required this.message,
    required this.chatHistory,
    required this.status,
    this.adminResponse,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      if (date is Map && date.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(date['_seconds'] * 1000);
      }
      return DateTime.now();
    }

    return SupportTicket(
      id: json['id'],
      email: json['email'] ?? '',
      message: json['message'] ?? '',
      chatHistory: json['chatHistory'] ?? '',
      status: json['status'] ?? 'open',
      adminResponse: json['adminResponse'],
      respondedAt: parseDate(json['respondedAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'message': message,
      'chatHistory': chatHistory,
      'status': status,
      'adminResponse': adminResponse,
      'respondedAt': respondedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
