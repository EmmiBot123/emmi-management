import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qubiq_os/Model/Inventory/InventoryLog.dart';

void main() {
  group('InventoryLog Model Tests', () {
    test('creates shelf moved log with correct description and icons', () {
      final log = InventoryLog(
        id: 'log-1',
        componentId: 'comp-101',
        componentName: 'ESP32 DevKit',
        actionType: InventoryActionType.shelfMoved,
        previousShelf: 'Shelf A-01',
        newShelf: 'Shelf B-04',
        performedBy: 'John Doe',
        note: 'Relocated to microcontroller rack',
        timestamp: DateTime(2026, 9, 7, 10, 30),
      );

      expect(log.actionTitle, 'Shelf Location Changed');
      expect(log.actionDescription, 'Moved from "Shelf A-01" → "Shelf B-04"');
      expect(log.icon, Icons.drive_file_move_outlined);
      expect(log.color, const Color(0xFF38BDF8));
      expect(log.performedBy, 'John Doe');
      expect(log.note, 'Relocated to microcontroller rack');
    });

    test('creates stock adjustment log with positive and negative changes', () {
      final restockLog = InventoryLog(
        componentId: 'comp-102',
        componentName: 'Servo SG90',
        actionType: InventoryActionType.qtyAdjusted,
        previousQuantity: 20,
        newQuantity: 50,
        quantityChange: 30,
        timestamp: DateTime.now(),
      );

      expect(restockLog.actionTitle, 'Stock Increased');
      expect(restockLog.actionDescription, contains('Quantity adjusted by +30 (20 → 50)'));
      expect(restockLog.icon, Icons.arrow_upward_rounded);
      expect(restockLog.color, const Color(0xFF10B981));

      final deductionLog = InventoryLog(
        componentId: 'comp-102',
        componentName: 'Servo SG90',
        actionType: InventoryActionType.qtyAdjusted,
        previousQuantity: 50,
        newQuantity: 40,
        quantityChange: -10,
        timestamp: DateTime.now(),
      );

      expect(deductionLog.actionTitle, 'Stock Decreased');
      expect(deductionLog.actionDescription, contains('Quantity adjusted by -10 (50 → 40)'));
      expect(deductionLog.icon, Icons.arrow_downward_rounded);
      expect(deductionLog.color, const Color(0xFFF59E0B));
    });

    test('serializes to and from JSON correctly', () {
      final now = DateTime(2026, 9, 7, 15, 45);
      final log = InventoryLog(
        id: 'log-999',
        componentId: 'comp-88',
        componentName: 'Breadboard Mini',
        actionType: InventoryActionType.created,
        newShelf: 'Shelf C-02',
        newQuantity: 100,
        note: 'New batch received',
        performedBy: 'Alice',
        timestamp: now,
      );

      final json = log.toJson();
      final parsed = InventoryLog.fromJson(json, 'log-999');

      expect(parsed.id, 'log-999');
      expect(parsed.componentId, 'comp-88');
      expect(parsed.componentName, 'Breadboard Mini');
      expect(parsed.actionType, InventoryActionType.created);
      expect(parsed.newShelf, 'Shelf C-02');
      expect(parsed.newQuantity, 100);
      expect(parsed.performedBy, 'Alice');
      expect(parsed.note, 'New batch received');
    });
  });
}
