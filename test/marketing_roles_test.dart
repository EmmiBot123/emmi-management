import 'package:flutter_test/flutter_test.dart';
import 'package:qubiq_os/Model/Permissions/RolePermissionModel.dart';

void main() {
  group('Marketing & Digital Marketing Roles & Dashboard Tests', () {
    test('RolePermissionModel maps Marketing and Digital Marketing screens', () {
      final mktPerm = RolePermissionModel(
        roleKey: 'MARKETING',
        roleTitle: 'Field Marketing',
        canAccessSales: true,
      );

      expect(mktPerm.canAccessRoleScreen('Marketing'), isTrue);
      expect(mktPerm.canAccessRoleScreen('Sales'), isTrue);
      expect(mktPerm.canAccessRoleScreen('Digital Marketing'), isFalse);

      final digitalPerm = const RolePermissionModel(
        roleKey: 'DIGITAL_MARKETING',
        roleTitle: 'Digital Marketing & SEO',
        canAccessDigitalMarketing: true,
      );

      expect(digitalPerm.canAccessRoleScreen('Digital Marketing'), isTrue);
      expect(digitalPerm.canAccessRoleScreen('Marketing'), isFalse);
      expect(digitalPerm.canAccessRoleScreen('Sales'), isFalse);
    });

    test('Default permissions for MARKETING and DIGITAL_MARKETING keys', () {
      final defaultMkt = RolePermissionModel.defaultForRole('MARKETING');
      expect(defaultMkt.canAccessRoleScreen('Marketing'), isTrue);

      final defaultDigital = RolePermissionModel.defaultForRole('DIGITAL_MARKETING');
      expect(defaultDigital.canAccessRoleScreen('Digital Marketing'), isTrue);
    });

    test('Role-based navigation filtering accurately resolves screens', () {
      List<String> simulateFilter(String userRole) {
        final rolesList = userRole.split(',').map((e) => e.trim().toUpperCase()).toList();
        final Set<String> visible = {};

        if (rolesList.contains('MARKETING')) {
          visible.add('Marketing');
          visible.add('Sales');
        }

        if (rolesList.contains('DIGITAL_MARKETING')) {
          visible.add('Digital Marketing');
        }

        if (rolesList.contains('SUPER_ADMIN')) {
          visible.addAll(['Marketing', 'Digital Marketing', 'Sales', 'Dashboard']);
        }

        return visible.toList();
      }

      final mktScreens = simulateFilter('MARKETING');
      expect(mktScreens.contains('Marketing'), isTrue);
      expect(mktScreens.contains('Digital Marketing'), isFalse);

      final digitalScreens = simulateFilter('DIGITAL_MARKETING');
      expect(digitalScreens.contains('Digital Marketing'), isTrue);
      expect(digitalScreens.contains('Marketing'), isFalse);

      final superAdminScreens = simulateFilter('SUPER_ADMIN');
      expect(superAdminScreens.contains('Marketing'), isTrue);
      expect(superAdminScreens.contains('Digital Marketing'), isTrue);
    });

    test('UTM Generator parameter parsing and encoding', () {
      String generateUtm(String base, String? source, String? medium, String? campaign) {
        final uri = Uri.tryParse(base.trim());
        if (uri == null) return '';

        Map<String, String> params = {};
        if (uri.hasQuery) {
          params.addAll(uri.queryParameters);
        }

        if (source != null && source.trim().isNotEmpty) params['utm_source'] = source.trim();
        if (medium != null && medium.trim().isNotEmpty) params['utm_medium'] = medium.trim();
        if (campaign != null && campaign.trim().isNotEmpty) params['utm_campaign'] = campaign.trim();

        return uri.replace(queryParameters: params.isNotEmpty ? params : null).toString();
      }

      final cleanLink = generateUtm(
        'https://qubiq.emmi.in',
        'instagram',
        'story',
        'school_robotics_2026',
      );
      expect(cleanLink, equals('https://qubiq.emmi.in?utm_source=instagram&utm_medium=story&utm_campaign=school_robotics_2026'));

      final linkWithExistingParams = generateUtm(
        'https://qubiq.emmi.in?ref=agent42',
        'facebook',
        'cpc',
        'ai_lab',
      );
      expect(linkWithExistingParams, equals('https://qubiq.emmi.in?ref=agent42&utm_source=facebook&utm_medium=cpc&utm_campaign=ai_lab'));

      final linkNoParams = generateUtm('https://qubiq.emmi.in', '', '', '');
      expect(linkNoParams, equals('https://qubiq.emmi.in'));
    });

    test('Marketing KPI win-rate and expense accumulation calculations', () {
      final visits = [
        {'status': 'Confirmed', 'approved': true},
        {'status': 'Confirmed', 'approved': true},
        {'status': 'Pending', 'approved': false},
        {'status': 'Follow-up', 'approved': false},
      ];

      final totalVisits = visits.length;
      final confirmedCount = visits.where((v) => v['status'] == 'Confirmed' || v['approved'] == true).length;
      final winRate = totalVisits > 0 ? ((confirmedCount / totalVisits) * 100).toStringAsFixed(1) : '0.0';

      expect(totalVisits, equals(4));
      expect(confirmedCount, equals(2));
      expect(winRate, equals('50.0'));

      final bills = [
        {'amount': 450.0, 'type': 'Food'},
        {'amount': 1200.0, 'type': 'Travel'},
        {'amount': 800.0, 'type': 'Stay'},
      ];

      double totalClaims = 0.0;
      for (final b in bills) {
        totalClaims += (b['amount'] as double);
      }

      expect(totalClaims, equals(2450.0));
    });
  });
}
