import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String? id;
  final String email;
  final String message;
  final String contactNumber;
  final String chatHistory;
  final String status;
  final String? adminResponse;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
   final bool isHardwareComplaint;
   final String? trackingLink;
   final String? manualTrackingStatus;
   final List<TicketReply> replies;

  SupportTicket({
    this.id,
    required this.email,
    required this.message,
    required this.contactNumber,
    required this.chatHistory,
    required this.status,
    this.adminResponse,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isHardwareComplaint = false,
    this.trackingLink,
    this.manualTrackingStatus,
    this.replies = const [],
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
      contactNumber: json['contactNumber'] ?? '',
      chatHistory: json['chatHistory'] ?? '',
      status: json['status'] ?? 'open',
      adminResponse: json['adminResponse'],
      respondedAt: parseDate(json['respondedAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      isHardwareComplaint: json['isHardwareComplaint'] ?? false,
      trackingLink: json['trackingLink'],
      manualTrackingStatus: json['manualTrackingStatus'],
      replies: (json['replies'] as List? ?? [])
          .map((r) => TicketReply.fromJson(r))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'message': message,
      'contactNumber': contactNumber,
      'chatHistory': chatHistory,
      'status': status,
      'adminResponse': adminResponse,
      'respondedAt': respondedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isHardwareComplaint': isHardwareComplaint,
      'trackingLink': trackingLink,
      'manualTrackingStatus': manualTrackingStatus,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}

class TicketReply {
  final String message;
  final String sender;
  final DateTime timestamp;

  TicketReply({
    required this.message,
    required this.sender,
    required this.timestamp,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return TicketReply(
      message: json['message'] ?? '',
      sender: json['sender'] ?? 'admin',
      timestamp: parseDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
