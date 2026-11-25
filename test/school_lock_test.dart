import 'package:flutter_test/flutter_test.dart';
import 'package:qubiq_os/Model/Marketing/school_visit_model.dart';

void main() {
  group('School Lock Model & Logic Tests', () {
    SchoolVisit createSampleSchool({
      String id = 'visit-101',
      String name = 'Delhi Public School',
      String schoolCode = '4001',
      String adminId = 'admin-user-1',
      bool isLocked = false,
      String? lockedReason,
      DateTime? lockedAt,
      String? lockedBy,
    }) {
      return SchoolVisit.fromJson({
        'id': id,
        'createdByUserId': 'user-001',
        'createdByUserName': 'Sales Rep',
        'adminId': adminId,
        'adminName': 'Principal Sharma',
        'schoolCode': schoolCode,
        'isLocked': isLocked,
        'lockedReason': lockedReason,
        'lockedAt': lockedAt?.toIso8601String(),
        'lockedBy': lockedBy,
        'schoolProfile': {
          'name': name,
          'city': 'New Delhi',
          'state': 'Delhi',
          'address': 'Sector 4, RK Puram',
          'pinCode': '110022',
          'photoUrl': [],
          'latitude': 28.5,
          'longitude': 77.2,
          'googleMapLink': '',
        },
        'contactPersons': [],
        'proposalChecklist': {
          'sent': true,
          'whatsapp': false,
          'email': false,
          'approved': false,
          'remarks': '',
        },
        'visitDetails': {
          'status': 'CLOSED_WON',
          'visitDate': '2026-09-01',
          'revisitDate': null,
          'statusNotes': 'Completed demo',
        },
        'purchaseOrder': {
          'poReceived': true,
          'poNumber': 'PO-99',
          'poDate': '2026-09-01',
        },
        'payment': {
          'advanceTransferred': true,
          'amount': 50000.0,
          'transactionId': 'TXN123',
          'transferDate': '2026-09-01',
          'paymentConfirmed': true,
        },
        'shippingDetails': {
          'address': 'Sector 4, RK Puram',
          'city': 'New Delhi',
          'state': 'Delhi',
          'pinCode': '110022',
          'country': 'India',
          'shippingNumber': 'SHIP-123',
          'contactNumber': '9876543210',
          'photoUrl': '',
        },
        'installationChecklist': [],
        'requiredProducts': [],
        'labInformation': {
          'setupType': 'Robotics Lab',
          'pcConfig': {
            'processor': 'i5',
            'ram': '16GB',
            'storageType': 'SSD',
            'storageSize': '512GB',
          },
        },
      });
    }

    test('SchoolVisit defaults to unlocked (isLocked = false)', () {
      final school = createSampleSchool();
      expect(school.isLocked, isFalse);
      expect(school.lockedReason, isNull);
      expect(school.lockedAt, isNull);
      expect(school.lockedBy, isNull);
    });

    test('SchoolVisit can be instantiated in locked state', () {
      final lockTime = DateTime(2026, 9, 8, 10, 30);
      final school = createSampleSchool(
        isLocked: true,
        lockedReason: 'Overdue Subscription Fees',
        lockedAt: lockTime,
        lockedBy: 'Super Admin',
      );

      expect(school.isLocked, isTrue);
      expect(school.lockedReason, 'Overdue Subscription Fees');
      expect(school.lockedAt, lockTime);
      expect(school.lockedBy, 'Super Admin');
    });

    test('SchoolVisit.copyWith correctly locks and unlocks school', () {
      final school = createSampleSchool();
      expect(school.isLocked, isFalse);

      final lockTime = DateTime(2026, 9, 8, 12, 0);
      final lockedSchool = school.copyWith(
        isLocked: true,
        lockedReason: 'Contract Expired',
        lockedAt: lockTime,
        lockedBy: 'Admin Abhay',
      );

      expect(lockedSchool.isLocked, isTrue);
      expect(lockedSchool.lockedReason, 'Contract Expired');
      expect(lockedSchool.lockedAt, lockTime);
      expect(lockedSchool.lockedBy, 'Admin Abhay');
      expect(lockedSchool.id, school.id);
      expect(lockedSchool.schoolProfile.name, school.schoolProfile.name);

      final unlockedSchool = lockedSchool.copyWith(
        isLocked: false,
        lockedReason: null,
        lockedAt: null,
        lockedBy: null,
      );

      expect(unlockedSchool.isLocked, isFalse);
      expect(unlockedSchool.lockedReason, isNull);
      expect(unlockedSchool.lockedAt, isNull);
      expect(unlockedSchool.lockedBy, isNull);
    });

    test('toJson and fromJson correctly serialize and deserialize lock fields', () {
      final lockTime = DateTime(2026, 9, 8, 14, 15);
      final original = createSampleSchool(
        isLocked: true,
        lockedReason: 'Policy Violation - Multi-Account Misuse',
        lockedAt: lockTime,
        lockedBy: 'Super Admin Security',
      );

      final json = original.toJson();
      expect(json['isLocked'], isTrue);
      expect(json['lockedReason'], 'Policy Violation - Multi-Account Misuse');
      expect(json['lockedAt'], lockTime.toIso8601String());
      expect(json['lockedBy'], 'Super Admin Security');

      final deserialized = SchoolVisit.fromJson(json);
      expect(deserialized.isLocked, isTrue);
      expect(deserialized.lockedReason, 'Policy Violation - Multi-Account Misuse');
      expect(deserialized.lockedAt, lockTime);
      expect(deserialized.lockedBy, 'Super Admin Security');
    });

    test('Filtered schools logic accurately separates Active vs Locked', () {
      final schools = [
        createSampleSchool(id: 's1', name: 'Springfield High', isLocked: false, adminId: 'adm-1'),
        createSampleSchool(id: 's2', name: 'Oakridge Academy', isLocked: true, adminId: 'adm-2'),
        createSampleSchool(id: 's3', name: 'Pinecrest Global', isLocked: false, adminId: 'PENDING_SETUP'),
        createSampleSchool(id: 's4', name: 'Metro Valley School', isLocked: true, adminId: 'adm-4'),
      ];

      // "All" filter
      final allList = schools.where((s) => true).toList();
      expect(allList.length, 4);

      // "Active" filter (has admin AND not locked)
      final activeList = schools.where((s) {
        final hasAdmin = s.adminId != null && s.adminId!.isNotEmpty && s.adminId != 'PENDING_SETUP';
        return hasAdmin && !s.isLocked;
      }).toList();
      expect(activeList.length, 1);
      expect(activeList.first.id, 's1');

      // "Locked" filter
      final lockedList = schools.where((s) => s.isLocked).toList();
      expect(lockedList.length, 2);
      expect(lockedList.map((e) => e.id), containsAll(['s2', 's4']));

      // "Pending" filter
      final pendingList = schools.where((s) => s.adminId == 'PENDING_SETUP').toList();
      expect(pendingList.length, 1);
      expect(pendingList.first.id, 's3');
    });
  });
}
