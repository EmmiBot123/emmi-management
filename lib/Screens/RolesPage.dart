import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emmi_management/Screens/Ads/ads_page.dart';

import '../Providers/AuthProvider.dart';

import 'Accounts/School_account_page.dart';
import 'Admin/admin_page.dart';
import 'Assembly/School_assembly_page.dart';
import 'Installation/installation_team_page.dart';
import 'TeleMarketing/TeleMarketing.dart';
import 'TeleMarketing/admin_to_telemarketing.dart';
import 'markerting/SchoolVisit/school_visit_list_page.dart';
import 'markerting/admin_to_marketing.dart';
import 'markerting/marketing_page.dart';
import 'SuperAdmin/super_admin_page.dart';
import 'Qubiq/qubiq_page.dart';
import 'Testing/testing_page.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  int selectedIndex = 0;

  final List<String> roles = [
    "Super Admin",
    "Admin",
    "Tele Marketing",
    "Marketing",
    "Accounts",
    "Assembly Team",
    "Installation Team",
    "Qubiq",
    "Ads",
    "Testing",
  ];
  final allowedRoles = {
    "Admin",
    "Tele Marketing",
    "Marketing",
  };

  IconData getRoleIcon(String role) {
    switch (role) {
      case "Super Admin":
        return Icons.security;
      case "Admin":
        return Icons.admin_panel_settings;
      case "Tele Marketing":
        return Icons.phone_in_talk;
      case "Marketing":
        return Icons.campaign;
      case "Accounts":
        return Icons.account_balance_wallet;
      case "Assembly Team":
        return Icons.build;
      case "Installation Team":
        return Icons.engineering;
      case "Qubiq":
        return Icons.api;
      case "Ads":
        return Icons.video_library;
      case "Testing":
        return Icons.bug_report;
      default:
        return Icons.person;
    }
  }

  Widget getRolePage(String role) {
    switch (role) {
      case "Super Admin":
        return const SuperAdminPage();
      case "Admin":
        return const AdminPage();
      case "Tele Marketing":
        final auth = context.watch<AuthProvider>();
        final String userRole = auth.role!;
        final String id = auth.userId!;
        final String name = auth.name!;
        if (userRole == "TELE_MARKETING") {
          return SchoolVisitListPage(
            userId: id,
            name: name,
            role: userRole,
          );
        } else {
          if (userRole == "SUPER_ADMIN") {
            return const AdminToTelemarketing();
          }
          return const TeleMarketingPage();
        }
      case "Marketing":
        final auth = context.watch<AuthProvider>();
        final String userRole = auth.role!;
        final String id = auth.userId!;
        final String name = auth.name!;
        if (userRole == "MARKETING") {
          return SchoolVisitListPage(
            userId: id,
            name: name,
            role: userRole,
          );
        } else {
          if (userRole == "SUPER_ADMIN") {
            return const AdminToMarketing();
          }
          return const MarketingPage();
        }
      case "Accounts":
        return SchoolVisitListPageAccounts();
      case "Assembly Team":
        return const SchoolAssemblyPage();
      case "Installation Team":
        return const InstallationTeamPage();
      case "Qubiq":
        return const QubiqPage();
      case "Ads":
        return const AdsPage();
      case "Testing":
        return const TestingPage();
      default:
        return const SizedBox();
    }
  }

  /// Filter roles based on logged in user role
  List<String> filterRoles(String userRole) {
    print(userRole);
    if (userRole == "SUPER_ADMIN") {
      return roles;
    }
    if (userRole == "ADMIN") {
      return roles.where(allowedRoles.contains).toList();
    }

    if (userRole == "MARKETING") {
      return ["Marketing"];
    }

    if (userRole == "TELE_MARKETING") {
      print("in tele");
      return ["Tele Marketing"];
    }

    if (userRole == "ACCOUNTS") {
      return ["Accounts"];
    }

    if (userRole == "ASSEMBLY_TEAM") {
      return ["Assembly Team", "Testing"];
    }

    if (userRole == "INSTALLATION_TEAM") {
      return ["Installation Team", "Testing"];
    }

    if (userRole == "QUBIQ") {
      return ["Qubiq"];
    }

    if (userRole == "ADS") {
      return ["Ads"];
    }

    if (userRole == "TESTING") {
      return ["Testing"];
    }

    return roles; // Super Admin sees everything
  }

  Future<void> logoutUser(BuildContext context) async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Safety check: if role is missing despite being logged in, force logout or show error
    if (auth.role == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthProvider>().logout();
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final String userRole = auth.role!;
    final List<String> visibleRoles = filterRoles(userRole);

    if (selectedIndex >= visibleRoles.length) {
      selectedIndex = 0;
    }

    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(visibleRoles[selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutUser(context),
          )
        ],
      ),
      drawer: isSmall ? buildDrawer(context, visibleRoles) : null,
      body: Row(
        children: [
          if (!isSmall) buildSideBar(visibleRoles),
          Expanded(
            child: Navigator(
              key: ValueKey(visibleRoles[selectedIndex]),
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => getRolePage(visibleRoles[selectedIndex]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Drawer for small screens
  Widget buildDrawer(BuildContext context, List<String> visibleRoles) {
    return Drawer(
      child: ListView.builder(
        itemCount: visibleRoles.length,
        itemBuilder: (context, i) {
          return ListTile(
            leading: Icon(getRoleIcon(visibleRoles[i])),
            title: Text(visibleRoles[i]),
            onTap: () {
              setState(() => selectedIndex = i);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  /// Sidebar for large screens
  Widget buildSideBar(List<String> visibleRoles) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (i) => setState(() => selectedIndex = i),
      destinations: visibleRoles
          .map(
            (r) => NavigationRailDestination(
              icon: Icon(getRoleIcon(r)),
              selectedIcon: Icon(getRoleIcon(r)),
              label: Text(r),
            ),
          )
          .toList(),
    );
  }
}
