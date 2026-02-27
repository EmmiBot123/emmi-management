import 'package:cloud_firestore/cloud_firestore.dart';

class Bill {
  String? id;
  final String userId;
  final String userName;
  final double amount;
  final String type; // Travel, Food, Stay, Other
  final String description;
  final String? imageUrl;
  String status; // Pending, Approved, Rejected
  final DateTime createdAt;

  Bill({
    this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.type,
    required this.description,
    this.imageUrl,
    this.status = 'Pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'type': type,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map, String id) {
    return Bill(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'Other',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
