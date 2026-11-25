import 'package:flutter_test/flutter_test.dart';
import 'package:qubiq_os/Model/Inventory/InventoryComponent.dart';

void main() {
  group('InventoryComponent Model Tests', () {
    test('creates component with shelf number and without quantity (optional)', () {
      final comp = InventoryComponent(
        id: 'comp-1',
        name: 'ESP32 Development Board',
        shelfNumber: 'Shelf A-04',
      );

      expect(comp.name, 'ESP32 Development Board');
      expect(comp.shelfNumber, 'Shelf A-04');
      expect(comp.quantity, isNull);
      expect(comp.hasQuantity, isFalse);
      expect(comp.isLowStock, isFalse);
      expect(comp.isOutOfStock, isFalse);
      expect(comp.displayQuantity, 'Untracked (In Shelf)');
    });

    test('creates component with shelf number and tracked quantity', () {
      final comp = InventoryComponent(
        id: 'comp-2',
        name: 'Servo SG90',
        shelfNumber: 'Shelf B-12',
        quantity: 45,
        unit: 'pcs',
        minStockAlert: 10,
      );

      expect(comp.name, 'Servo SG90');
      expect(comp.shelfNumber, 'Shelf B-12');
      expect(comp.quantity, 45);
      expect(comp.hasQuantity, isTrue);
      expect(comp.isLowStock, isFalse);
      expect(comp.isOutOfStock, isFalse);
      expect(comp.displayQuantity, '45 pcs');
    });

    test('correctly flags low stock and out of stock', () {
      final lowStockComp = InventoryComponent(
        name: 'Resistor 10k',
        shelfNumber: 'Shelf C-01',
        quantity: 5,
        minStockAlert: 10,
      );
      expect(lowStockComp.isLowStock, isTrue);
      expect(lowStockComp.isOutOfStock, isFalse);

      final outOfStockComp = InventoryComponent(
        name: 'Jumper Wires M-M',
        shelfNumber: 'Shelf C-02',
        quantity: 0,
        minStockAlert: 5,
      );
      expect(outOfStockComp.isOutOfStock, isTrue);
    });

    test('serializes to and from JSON correctly', () {
      final original = InventoryComponent(
        id: '123',
        name: 'OLED Display 0.96"',
        shelfNumber: 'Shelf D-03',
        quantity: 15,
        category: 'Displays',
        unit: 'units',
        description: 'I2C 128x64 Blue',
        minStockAlert: 5,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 7),
      );

      final json = original.toJson();
      final reconstructed = InventoryComponent.fromJson(json, '123');

      expect(reconstructed.id, '123');
      expect(reconstructed.name, original.name);
      expect(reconstructed.shelfNumber, 'Shelf D-03');
      expect(reconstructed.quantity, 15);
      expect(reconstructed.category, 'Displays');
      expect(reconstructed.unit, 'units');
      expect(reconstructed.description, 'I2C 128x64 Blue');
      expect(reconstructed.minStockAlert, 5);
    });

    test('handles JSON with null quantity without error', () {
      final json = {
        'name': 'Chassis Base Plate',
        'shelfNumber': 'Rack 1 / Bin A',
        'quantity': null,
        'category': 'Hardware',
      };

      final comp = InventoryComponent.fromJson(json, 'doc-99');
      expect(comp.id, 'doc-99');
      expect(comp.name, 'Chassis Base Plate');
      expect(comp.shelfNumber, 'Rack 1 / Bin A');
      expect(comp.quantity, isNull);
      expect(comp.hasQuantity, isFalse);
    });

    test('copyWith updates shelf number and can clear quantity', () {
      final comp = InventoryComponent(
        name: 'Breadboard',
        shelfNumber: 'Shelf A-01',
        quantity: 20,
      );

      final moved = comp.copyWith(shelfNumber: 'Shelf B-02');
      expect(moved.shelfNumber, 'Shelf B-02');
      expect(moved.quantity, 20);

      final clearedQty = comp.copyWith(clearQuantity: true);
      expect(clearedQty.quantity, isNull);
      expect(clearedQty.hasQuantity, isFalse);
    });
  });
}
