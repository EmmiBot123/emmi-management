import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qubiq_os/Model/Notifications/SystemNotificationModel.dart';

void main() {
  group('SystemNotificationModel Tests', () {
    test('isReadByUser correctly identifies read status', () {
      final notif = SystemNotificationModel(
        id: 'notif_1',
        title: 'Low Stock Alert',
        message: 'Shelf A1 is low on screws',
        category: 'INVENTORY',
        priority: 'HIGH',
        readBy: const ['user_101', 'user_102'],
        createdAt: DateTime.now(),
      );

      expect(notif.isReadByUser('user_101'), isTrue);
      expect(notif.isReadByUser('user_102'), isTrue);
      expect(notif.isReadByUser('user_999'), isFalse);
    });

    test('isRelevantToRole matches role targets correctly', () {
      final broadcast = SystemNotificationModel(
        id: 'b1',
        title: 'Workshop Maintenance',
        message: 'Assembly hall closed tomorrow',
        targetRole: 'ALL',
        createdAt: DateTime.now(),
      );
      expect(broadcast.isRelevantToRole('MARKETING'), isTrue);
      expect(broadcast.isRelevantToRole('ASSEMBLY_TEAM'), isTrue);

      final targeted = SystemNotificationModel(
        id: 'b2',
        title: 'New Purchase Orders',
        message: 'Please review ledgers',
        targetRole: 'ACCOUNTS,ADMIN',
        createdAt: DateTime.now(),
      );
      expect(targeted.isRelevantToRole('ACCOUNTS'), isTrue);
      expect(targeted.isRelevantToRole('ADMIN'), isTrue);
      expect(targeted.isRelevantToRole('SUPER_ADMIN'), isTrue); // Always relevant
      expect(targeted.isRelevantToRole('ASSEMBLY_TEAM'), isFalse);
    });

    test('toJson and fromJson handle Timestamp and List serialization', () {
      final now = DateTime.now();
      final original = SystemNotificationModel(
        id: 'notif_abc',
        title: 'New Component Added',
        message: 'Relocated to Shelf B4',
        category: 'INVENTORY',
        priority: 'MEDIUM',
        targetRole: 'ADMIN,OPERATIONS',
        actionRoute: 'Inventory',
        actionId: 'comp_123',
        isRead: false,
        readBy: ['staff_1'],
        createdAt: now,
        createdBy: 'Admin User',
      );

      final json = original.toJson();
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['category'], 'INVENTORY');

      final restored = SystemNotificationModel.fromJson(json, 'notif_abc');
      expect(restored.id, 'notif_abc');
      expect(restored.title, 'New Component Added');
      expect(restored.category, 'INVENTORY');
      expect(restored.priority, 'MEDIUM');
      expect(restored.targetRole, 'ADMIN,OPERATIONS');
      expect(restored.actionRoute, 'Inventory');
      expect(restored.actionId, 'comp_123');
      expect(restored.readBy, contains('staff_1'));
      expect(restored.createdBy, 'Admin User');
    });

    test('copyWith properly mutates properties', () {
      final original = SystemNotificationModel(
        id: 'n1',
        title: 'Original Title',
        message: 'Original Message',
        createdAt: DateTime.now(),
      );

      final modified = original.copyWith(
        title: 'Updated Title',
        priority: 'URGENT',
      );

      expect(modified.id, 'n1');
      expect(modified.title, 'Updated Title');
      expect(modified.priority, 'URGENT');
      expect(modified.message, 'Original Message');
    });
  });
}
