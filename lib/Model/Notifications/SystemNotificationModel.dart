import 'package:cloud_firestore/cloud_firestore.dart';

class SystemNotificationModel {
  final String id;
  final String title;
  final String message;
  final String category; // 'INVENTORY', 'OPERATIONS', 'ACCOUNTS', 'SYSTEM', 'GENERAL'
  final String priority; // 'LOW', 'MEDIUM', 'HIGH', 'URGENT'
  final String? targetRole; // e.g. 'ALL', 'ADMIN', 'ASSEMBLY_TEAM', 'ACCOUNTS'
  final String? actionRoute; // e.g. 'Inventory', 'Operations', 'Accounts'
  final String? actionId; // e.g. component id or order id
  final bool isRead;
  final List<String> readBy;
  final DateTime createdAt;
  final String? createdBy;

  const SystemNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.category = 'GENERAL',
    this.priority = 'MEDIUM',
    this.targetRole = 'ALL',
    this.actionRoute,
    this.actionId,
    this.isRead = false,
    this.readBy = const [],
    required this.createdAt,
    this.createdBy,
  });

  bool isReadByUser(String userId) {
    if (isRead) return true;
    return readBy.contains(userId);
  }

  bool isRelevantToRole(String role) {
    if (targetRole == null || targetRole == 'ALL' || targetRole!.isEmpty) {
      return true;
    }
    final normalized = role.trim().toUpperCase();
    if (normalized == 'SUPER_ADMIN') {
      return true;
    }
    final targets = targetRole!.toUpperCase().split(',').map((e) => e.trim());
    return targets.contains(normalized);
  }

  SystemNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    String? priority,
    String? targetRole,
    String? actionRoute,
    String? actionId,
    bool? isRead,
    List<String>? readBy,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return SystemNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      targetRole: targetRole ?? this.targetRole,
      actionRoute: actionRoute ?? this.actionRoute,
      actionId: actionId ?? this.actionId,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory SystemNotificationModel.fromJson(Map<String, dynamic>? json, [String? docId]) {
    if (json == null) {
      return SystemNotificationModel(
        id: docId ?? '',
        title: '',
        message: '',
        createdAt: DateTime.now(),
      );
    }

    DateTime parsedDate;
    final rawDate = json['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    List<String> readByList = [];
    if (json['readBy'] is List) {
      readByList = (json['readBy'] as List).map((e) => e.toString()).toList();
    }

    return SystemNotificationModel(
      id: docId ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      category: json['category']?.toString() ?? 'GENERAL',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      targetRole: json['targetRole']?.toString() ?? 'ALL',
      actionRoute: json['actionRoute']?.toString(),
      actionId: json['actionId']?.toString(),
      isRead: json['isRead'] as bool? ?? false,
      readBy: readByList,
      createdAt: parsedDate,
      createdBy: json['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'priority': priority,
      'targetRole': targetRole,
      'actionRoute': actionRoute,
      'actionId': actionId,
      'isRead': isRead,
      'readBy': readBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
