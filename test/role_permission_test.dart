import 'package:flutter_test/flutter_test.dart';
import 'package:qubiq_os/Model/Permissions/RolePermissionModel.dart';

void main() {
  group('RolePermissionModel Tests', () {
    test('Default permissions for SUPER_ADMIN grant full privileges', () {
      final model = RolePermissionModel.defaultForRole('SUPER_ADMIN');

      expect(model.roleKey, 'SUPER_ADMIN');
      expect(model.canAccessDashboard, isTrue);
      expect(model.canAccessInventory, isTrue);
      expect(model.canAccessOperations, isTrue);
      expect(model.canAccessSales, isTrue);
      expect(model.canAccessAccounts, isTrue);
      expect(model.canAccessUsers, isTrue);
      expect(model.canModifyInventory, isTrue);
      expect(model.canDeleteInventory, isTrue);
      expect(model.canManageBills, isTrue);
      expect(model.canManageUsers, isTrue);
    });

    test('Default permissions for ASSEMBLY_TEAM grant workshop access only', () {
      final model = RolePermissionModel.defaultForRole('ASSEMBLY_TEAM');

      expect(model.roleKey, 'ASSEMBLY_TEAM');
      expect(model.canAccessOperations, isTrue);
      expect(model.canAccessInventory, isTrue);
      expect(model.canAccessTesting, isTrue);
      expect(model.canModifyInventory, isTrue);
      expect(model.canAccessAccounts, isFalse);
      expect(model.canAccessUsers, isFalse);
      expect(model.canManageBills, isFalse);
      expect(model.canDeleteInventory, isFalse);
    });

    test('Default permissions for ACCOUNTS grant financial access only', () {
      final model = RolePermissionModel.defaultForRole('ACCOUNTS');

      expect(model.roleKey, 'ACCOUNTS');
      expect(model.canAccessAccounts, isTrue);
      expect(model.canManageBills, isTrue);
      expect(model.canExportReports, isTrue);
      expect(model.canAccessInventory, isFalse);
      expect(model.canAccessOperations, isFalse);
    });

    test('canAccessRoleScreen maps correctly to screen flags', () {
      final model = const RolePermissionModel(
        roleKey: 'CUSTOM',
        roleTitle: 'Custom Role',
        canAccessInventory: true,
        canAccessOperations: false,
        canAccessAccounts: true,
      );

      expect(model.canAccessRoleScreen('Inventory'), isTrue);
      expect(model.canAccessRoleScreen('Operations'), isFalse);
      expect(model.canAccessRoleScreen('Accounts'), isTrue);
      expect(model.canAccessRoleScreen('Users'), isFalse);
    });

    test('toJson and fromJson preserve all boolean capability flags', () {
      final original = const RolePermissionModel(
        roleKey: 'AUDITOR',
        roleTitle: 'Internal Auditor',
        canAccessDashboard: true,
        canAccessInventory: true,
        canAccessAccounts: true,
        canExportReports: true,
        canModifyInventory: false,
        canDeleteInventory: false,
      );

      final json = original.toJson();
      final restored = RolePermissionModel.fromJson(json, 'AUDITOR');

      expect(restored.roleKey, 'AUDITOR');
      expect(restored.roleTitle, 'Internal Auditor');
      expect(restored.canAccessDashboard, isTrue);
      expect(restored.canAccessInventory, isTrue);
      expect(restored.canAccessAccounts, isTrue);
      expect(restored.canExportReports, isTrue);
      expect(restored.canModifyInventory, isFalse);
      expect(restored.canDeleteInventory, isFalse);
    });

    test('copyWith properly mutates targeted properties', () {
      final original = RolePermissionModel.defaultForRole('ASSEMBLY_TEAM');
      expect(original.canDeleteInventory, isFalse);

      final updated = original.copyWith(canDeleteInventory: true);
      expect(updated.canDeleteInventory, isTrue);
      expect(updated.canAccessInventory, isTrue); // Preserved
    });
  });
}
