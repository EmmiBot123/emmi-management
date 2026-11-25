import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum InventoryActionType {
  created,
  shelfMoved,
  qtyAdjusted,
  qtySet,
  updated,
  deleted,
  imported,
}

class InventoryLog {
  final String id;
  final String componentId;
  final String componentName;
  final InventoryActionType actionType;
  final String? previousShelf;
  final String? newShelf;
  final int? previousQuantity;
  final int? newQuantity;
  final int? quantityChange;
  final String note;
  final String performedBy;
  final DateTime timestamp;

  const InventoryLog({
    this.id = '',
    required this.componentId,
    required this.componentName,
    required this.actionType,
    this.previousShelf,
    this.newShelf,
    this.previousQuantity,
    this.newQuantity,
    this.quantityChange,
    this.note = '',
    this.performedBy = 'Staff',
    required this.timestamp,
  });

  String get actionTitle {
    switch (actionType) {
      case InventoryActionType.created:
        return 'Component Added';
      case InventoryActionType.shelfMoved:
        return 'Shelf Location Changed';
      case InventoryActionType.qtyAdjusted:
        if (quantityChange != null && quantityChange! > 0) {
          return 'Stock Increased';
        }
        return 'Stock Decreased';
      case InventoryActionType.qtySet:
        return 'Stock Quantity Set';
      case InventoryActionType.updated:
        return 'Details Updated';
      case InventoryActionType.deleted:
        return 'Component Removed';
      case InventoryActionType.imported:
        return 'Imported from Products';
    }
  }

  String get actionDescription {
    switch (actionType) {
      case InventoryActionType.created:
        final qtyStr = newQuantity != null ? ' (Initial Qty: $newQuantity)' : ' (Untracked Qty)';
        return 'Added to Shelf "$newShelf"$qtyStr';
      case InventoryActionType.shelfMoved:
        return 'Moved from "$previousShelf" → "$newShelf"';
      case InventoryActionType.qtyAdjusted:
        final sign = (quantityChange ?? 0) >= 0 ? '+' : '';
        return 'Quantity adjusted by $sign$quantityChange ($previousQuantity → $newQuantity)';
      case InventoryActionType.qtySet:
        if (newQuantity == null) {
          return 'Quantity changed from $previousQuantity to untracked';
        }
        return 'Quantity updated from ${previousQuantity ?? "untracked"} → $newQuantity';
      case InventoryActionType.updated:
        return 'Component specifications or details modified';
      case InventoryActionType.deleted:
        return 'Removed from Shelf "$previousShelf"';
      case InventoryActionType.imported:
        return 'Batch imported into workshop inventory';
    }
  }

  IconData get icon {
    switch (actionType) {
      case InventoryActionType.created:
        return Icons.add_circle_outline_rounded;
      case InventoryActionType.shelfMoved:
        return Icons.drive_file_move_outlined;
      case InventoryActionType.qtyAdjusted:
        if (quantityChange != null && quantityChange! > 0) {
          return Icons.arrow_upward_rounded;
        }
        return Icons.arrow_downward_rounded;
      case InventoryActionType.qtySet:
        return Icons.pin_outlined;
      case InventoryActionType.updated:
        return Icons.edit_note_rounded;
      case InventoryActionType.deleted:
        return Icons.delete_outline_rounded;
      case InventoryActionType.imported:
        return Icons.download_rounded;
    }
  }

  Color get color {
    switch (actionType) {
      case InventoryActionType.created:
        return const Color(0xFF10B981); // emerald green
      case InventoryActionType.shelfMoved:
        return const Color(0xFF38BDF8); // neon cyan/blue
      case InventoryActionType.qtyAdjusted:
        if (quantityChange != null && quantityChange! > 0) {
          return const Color(0xFF10B981);
        }
        return const Color(0xFFF59E0B); // amber/warning
      case InventoryActionType.qtySet:
        return const Color(0xFF818CF8); // indigo
      case InventoryActionType.updated:
        return const Color(0xFF6C63FF); // purple
      case InventoryActionType.deleted:
        return const Color(0xFFEF4444); // red
      case InventoryActionType.imported:
        return const Color(0xFF38BDF8);
    }
  }

  factory InventoryLog.fromJson(Map<String, dynamic>? json, [String? docId]) {
    if (json == null) {
      return InventoryLog(
        componentId: '',
        componentName: '',
        actionType: InventoryActionType.updated,
        timestamp: DateTime.now(),
      );
    }

    InventoryActionType parseAction(dynamic val) {
      final str = val?.toString().toUpperCase() ?? '';
      if (str.contains('CREATE')) return InventoryActionType.created;
      if (str.contains('SHELF') || str.contains('MOVE')) return InventoryActionType.shelfMoved;
      if (str.contains('ADJUST')) return InventoryActionType.qtyAdjusted;
      if (str.contains('SET')) return InventoryActionType.qtySet;
      if (str.contains('DELETE')) return InventoryActionType.deleted;
      if (str.contains('IMPORT')) return InventoryActionType.imported;
      return InventoryActionType.updated;
    }

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) return int.tryParse(val.trim());
      return null;
    }

    return InventoryLog(
      id: docId ?? json['id']?.toString() ?? '',
      componentId: json['componentId']?.toString() ?? '',
      componentName: json['componentName']?.toString() ?? 'Component',
      actionType: parseAction(json['actionType']),
      previousShelf: json['previousShelf']?.toString(),
      newShelf: json['newShelf']?.toString(),
      previousQuantity: parseInt(json['previousQuantity']),
      newQuantity: parseInt(json['newQuantity']),
      quantityChange: parseInt(json['quantityChange']),
      note: json['note']?.toString() ?? '',
      performedBy: json['performedBy']?.toString() ?? 'Staff',
      timestamp: parseDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'componentId': componentId,
      'componentName': componentName,
      'actionType': actionType.name.toUpperCase(),
      'previousShelf': previousShelf,
      'newShelf': newShelf,
      'previousQuantity': previousQuantity,
      'newQuantity': newQuantity,
      'quantityChange': quantityChange,
      'note': note,
      'performedBy': performedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
