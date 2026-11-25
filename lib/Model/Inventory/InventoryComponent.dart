import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryComponent {
  final String id;
  final String name;
  final String shelfNumber;
  final int? quantity; // Optional as per user requirements
  final String category;
  final String unit;
  final String description;
  final int? minStockAlert;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryComponent({
    this.id = '',
    required this.name,
    required this.shelfNumber,
    this.quantity,
    this.category = 'General',
    this.unit = 'pcs',
    this.description = '',
    this.minStockAlert,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasQuantity => quantity != null;
  bool get isOutOfStock => quantity != null && quantity! <= 0;
  bool get isLowStock =>
      quantity != null &&
      minStockAlert != null &&
      quantity! <= minStockAlert! &&
      quantity! > 0;

  String get displayQuantity =>
      quantity != null ? '$quantity $unit' : 'Untracked (In Shelf)';

  InventoryComponent copyWith({
    String? id,
    String? name,
    String? shelfNumber,
    int? quantity,
    bool clearQuantity = false,
    String? category,
    String? unit,
    String? description,
    int? minStockAlert,
    bool clearMinStockAlert = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryComponent(
      id: id ?? this.id,
      name: name ?? this.name,
      shelfNumber: shelfNumber ?? this.shelfNumber,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      category: category ?? this.category,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      minStockAlert: clearMinStockAlert
          ? null
          : (minStockAlert ?? this.minStockAlert),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InventoryComponent.fromJson(
    Map<String, dynamic>? json, [
    String? docId,
  ]) {
    if (json == null) {
      return const InventoryComponent(
        name: '',
        shelfNumber: '',
      );
    }

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    int? parseOptionalInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) {
        final trimmed = val.trim();
        if (trimmed.isEmpty) return null;
        return int.tryParse(trimmed);
      }
      return null;
    }

    return InventoryComponent(
      id: docId ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shelfNumber: json['shelfNumber']?.toString() ??
          json['shelf']?.toString() ??
          '',
      quantity: parseOptionalInt(json['quantity']),
      category: json['category']?.toString() ?? 'General',
      unit: json['unit']?.toString() ?? 'pcs',
      description: json['description']?.toString() ?? '',
      minStockAlert: parseOptionalInt(json['minStockAlert']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shelfNumber': shelfNumber,
      'quantity': quantity,
      'category': category,
      'unit': unit,
      'description': description,
      'minStockAlert': minStockAlert,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
