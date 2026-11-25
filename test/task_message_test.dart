import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qubiq_os/Model/TaskMessageModel.dart';
import 'package:qubiq_os/Model/Task_model.dart';

void main() {
  group('TaskMessageModel Tests', () {
    test('toJson and fromJson handle Timestamp and String serialization', () {
      final now = DateTime(2026, 9, 8, 10, 30);
      final message = TaskMessageModel(
        id: 'msg_101',
        taskId: 'task_abc',
        senderId: 'user_42',
        senderName: 'Jane Engineer',
        senderRole: 'DEVELOPMENT',
        text: 'Finished compiling firmware for rev 2.1.',
        createdAt: now,
      );

      final json = message.toJson();
      expect(json['taskId'], equals('task_abc'));
      expect(json['senderId'], equals('user_42'));
      expect(json['senderName'], equals('Jane Engineer'));
      expect(json['senderRole'], equals('DEVELOPMENT'));
      expect(json['text'], equals('Finished compiling firmware for rev 2.1.'));
      expect(json['createdAt'], isA<Timestamp>());

      // Deserialization with docId
      final parsed = TaskMessageModel.fromJson(json, docId: 'msg_101');
      expect(parsed.id, equals('msg_101'));
      expect(parsed.taskId, equals('task_abc'));
      expect(parsed.senderId, equals('user_42'));
      expect(parsed.senderName, equals('Jane Engineer'));
      expect(parsed.text, equals('Finished compiling firmware for rev 2.1.'));
      expect(parsed.createdAt, equals(now));
    });

    test('fromJson handles ISO8601 string createdAt fallback', () {
      final json = {
        'taskId': 'task_1',
        'senderId': 'user_1',
        'senderName': 'Bob',
        'senderRole': 'MARKETING',
        'text': 'Contacted 5 schools today.',
        'createdAt': '2026-09-08T08:15:00.000Z',
      };

      final parsed = TaskMessageModel.fromJson(json, docId: 'doc_1');
      expect(parsed.id, equals('doc_1'));
      expect(parsed.senderName, equals('Bob'));
      expect(parsed.createdAt.year, equals(2026));
      expect(parsed.createdAt.month, equals(9));
    });

    test('canDelete permits message author to delete their own message', () {
      final msg = TaskMessageModel(
        id: 'msg_1',
        taskId: 'task_1',
        senderId: 'staff_123',
        senderName: 'Alice',
        senderRole: 'MARKETING',
        text: 'Initial outreach done.',
        createdAt: DateTime.now(),
      );

      // Same user -> allowed
      expect(msg.canDelete('staff_123', 'MARKETING'), isTrue);

      // Different staff member -> forbidden
      expect(msg.canDelete('staff_456', 'MARKETING'), isFalse);
      expect(msg.canDelete('staff_789', 'ACCOUNTS'), isFalse);
    });

    test('canDelete permits SUPER_ADMIN, CEO, and ADMIN to delete any message', () {
      final msg = TaskMessageModel(
        id: 'msg_2',
        taskId: 'task_1',
        senderId: 'staff_123',
        senderName: 'Alice',
        senderRole: 'MARKETING',
        text: 'Initial outreach done.',
        createdAt: DateTime.now(),
      );

      // Super admin can delete regardless of user ID
      expect(msg.canDelete('admin_999', 'SUPER_ADMIN'), isTrue);
      expect(msg.canDelete('admin_999', 'super_admin'), isTrue);

      // CEO can delete
      expect(msg.canDelete('ceo_001', 'CEO'), isTrue);
      expect(msg.canDelete('ceo_001', 'ceo'), isTrue);

      // Admin can delete
      expect(msg.canDelete('admin_100', 'ADMIN'), isTrue);
      expect(msg.canDelete('admin_100', 'admin'), isTrue);
    });

    test('copyWith updates specified fields only', () {
      final original = TaskMessageModel(
        id: 'msg_old',
        taskId: 'task_1',
        senderId: 'user_1',
        senderName: 'Dev',
        senderRole: 'TECH',
        text: 'Original text',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        text: 'Updated status report',
        id: 'msg_new',
      );

      expect(updated.id, equals('msg_new'));
      expect(updated.text, equals('Updated status report'));
      expect(updated.taskId, equals(original.taskId));
      expect(updated.senderId, equals(original.senderId));
      expect(updated.createdAt, equals(original.createdAt));
    });

    test('TaskModel department vs person assignment matching', () {
      final deptTask = TaskModel(
        id: 't_dept',
        title: 'Prepare Kits',
        description: 'Need 50 kits ready',
        assignedToId: 'OPERATIONS',
        assignedToName: 'Operations Team',
        assigneeType: 'Department',
        priority: 'High',
        status: 'In Progress',
        createdAt: DateTime.now(),
      );

      final personTask = TaskModel(
        id: 't_person',
        title: 'Review balance sheet',
        description: 'Q3 audit',
        assignedToId: 'user_acc_1',
        assignedToName: 'Sarah Accounts',
        assigneeType: 'Person',
        priority: 'Medium',
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      // Helper simulating matching
      bool matchesUser(TaskModel t, String userId, String userRole) {
        if (t.assigneeType == 'Person' && t.assignedToId == userId) return true;
        if (t.assigneeType == 'Department') {
          return userRole.toUpperCase().contains(t.assignedToId.toUpperCase());
        }
        return false;
      }

      // Department matching
      expect(matchesUser(deptTask, 'user_op_1', 'OPERATIONS'), isTrue);
      expect(matchesUser(deptTask, 'user_mkt_1', 'MARKETING'), isFalse);

      // Person matching
      expect(matchesUser(personTask, 'user_acc_1', 'ACCOUNTS'), isTrue);
      expect(matchesUser(personTask, 'user_acc_2', 'ACCOUNTS'), isFalse);
    });
  });
}
