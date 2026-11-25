import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../Providers/AuthProvider.dart';

import 'UserManagementPage.dart';
import 'OperationsPage.dart';
import 'SuperAdmin/super_admin_page.dart';
import 'Testing/testing_page.dart';
import 'Accounts/accounts_dashboard.dart';
import 'Qubiq/qubiq_page.dart';
import 'ContentHub/content_hub_page.dart';
import 'CEO/ceo_dashboard_page.dart';
import 'Assistant/assistant_dashboard_page.dart';
import 'Tutorials/tutorial_dashboard_page.dart';
import 'Deployment/deployment_dashboard_page.dart';
import 'Qubiq/qubiq_manager_dashboard_page.dart';
import 'Qubiq/app_updates_broadcast_page.dart';
import 'Inventory/inventory_page.dart';
import '../Providers/Permissions/RolePermissionProvider.dart';
import '../Providers/Notifications/NotificationProvider.dart';
import 'Notifications/notification_center_sheet.dart';
import '../Providers/TaskProvider.dart';
import '../Model/Task_model.dart';
import 'Tasks/staff_tasks_sheet.dart';
import 'markerting/marketing_dashboard_page.dart';
import 'DigitalMarketing/digital_marketing_dashboard_page.dart';

// ─── Dark palette (matches dashboard) ───
class _P {
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surfaceLight = Color(0xFF242836);
  static const accent = Color(0xFF6C63FF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B8FA3);
  static const textMuted = Color(0xFF565B73);
}

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  int selectedIndex = 0;

  final List<String> roles = [
    "Dashboard",
    "CEO Dashboard",
    "Assistant Dashboard",
    "Deployment Dashboard",
    "Users",
    "Marketing",
    "Digital Marketing",
    "Sales",
    "Accounts",
    "Operations",
    "Inventory",
    "Qubiq",
    "QubiQ Manager",
    "App Broadcasts",
    "Content Hub",
    "Testing",
    "Tutorials",
  ];
  final allowedRoles = {
    "Deployment Dashboard",
    "QubiQ Manager",
    "App Broadcasts",
    "Users",
    "Marketing",
    "Digital Marketing",
    "Sales",
    "Inventory",
    "Qubiq",
    "Content Hub",
    "Tutorials",
  };

  IconData getRoleIcon(String role) {
    switch (role) {
      case "Dashboard":
        return Icons.dashboard;
      case "CEO Dashboard":
        return Icons.analytics;
      case "Deployment Dashboard":
        return Icons.rocket_launch;
      case "Assistant Dashboard":
        return Icons.space_dashboard_outlined;
      case "Users":
        return Icons.people_alt;
      case "Marketing":
        return Icons.campaign_rounded;
      case "Digital Marketing":
        return Icons.computer_rounded;
      case "Sales":
        return Icons.storefront;
      case "Accounts":
        return Icons.account_balance_wallet;
      case "Operations":
        return Icons.precision_manufacturing_outlined;
      case "Inventory":
        return Icons.inventory_2_rounded;
      case "Qubiq":
        return Icons.api;
      case "QubiQ Manager":
        return Icons.hub;
      case "App Broadcasts":
        return Icons.campaign_rounded;
      case "Content Hub":
        return Icons.school_rounded;
      case "Testing":
        return Icons.bug_report;
      case "Tutorials":
        return Icons.video_library;
      default:
        return Icons.person;
    }
  }

  Widget getRolePage(String role) {
    switch (role) {
      case "Dashboard":
        return SuperAdminPage();
      case "CEO Dashboard":
        return const CeoDashboardPage();
      case "Deployment Dashboard":
        return const DeploymentDashboardPage();
      case "Assistant Dashboard":
        return const AssistantDashboardPage();
      case "Users":
        return UserManagementPage();
      case "Marketing":
        return const MarketingDashboardPage();
      case "Digital Marketing":
        return const DigitalMarketingDashboardPage();
      case "Sales":
        return const MarketingDashboardPage();
      case "Accounts":
        return AccountsDashboard();
      case "Operations":
        return const OperationsPage();
      case "Inventory":
        return const InventoryPage();
      case "Qubiq":
        return QubiqPage();
      case "QubiQ Manager":
        return const QubiqManagerDashboardPage();
      case "App Broadcasts":
        return const AppUpdatesBroadcastPage();
      case "Content Hub":
        return const ContentHubPage();
      case "Testing":
        return TestingPage();
      case "Tutorials":
        return const TutorialDashboardPage();
      default:
        return SizedBox();
    }
  }

  /// Filter roles based on logged in user role and RBAC matrix
  List<String> filterRoles(String userRole, [RolePermissionProvider? permProvider]) {
    print("User roles: $userRole");
    final userRolesList = userRole.split(',').map((e) => e.trim().toUpperCase()).toList();

    // CEO gets only the CEO Dashboard
    if (userRolesList.contains("CEO")) {
      return ["CEO Dashboard"];
    }

    // Assistant gets only the Assistant Dashboard
    if (userRolesList.contains("ASSISTANT")) {
      return ["Assistant Dashboard"];
    }

    if (userRolesList.contains("SUPER_ADMIN")) {
      return roles.where((r) => ![
        "CEO Dashboard", 
        "Assistant Dashboard", 
        "Deployment Dashboard",
        "Tutorials"
      ].contains(r)).toList();
    }

    // Check dynamic RBAC permissions if configured
    if (permProvider != null && permProvider.permissionsByRole.isNotEmpty) {
      final List<String> dynamicRoles = [];
      for (final r in roles) {
        if (permProvider.canUserAccessScreen(userRole, r)) {
          dynamicRoles.add(r);
        }
      }
      if (dynamicRoles.isNotEmpty) {
        return dynamicRoles;
      }
    }

    Set<String> visibleSections = {};

    if (userRolesList.contains("ADMIN")) {
      visibleSections.addAll(roles.where(allowedRoles.contains));
    }

    if (userRolesList.contains("MARKETING") || userRolesList.contains("TELE_MARKETING")) {
      visibleSections.add("Marketing");
      visibleSections.add("Sales");
    }

    if (userRolesList.contains("DIGITAL_MARKETING")) {
      visibleSections.add("Digital Marketing");
    }

    if (userRolesList.contains("ACCOUNTS")) {
      visibleSections.add("Accounts");
    }

    if (userRolesList.contains("ASSEMBLY_TEAM") || userRolesList.contains("INSTALLATION_TEAM")) {
      visibleSections.add("Operations");
      visibleSections.add("Testing");
      visibleSections.add("Inventory");
    }

    if (userRolesList.contains("INVENTORY") || userRolesList.contains("OPERATIONS")) {
      visibleSections.add("Inventory");
    }

    if (userRolesList.contains("QUBIQ")) {
      visibleSections.add("QubiQ Manager");
      visibleSections.add("Sales");
    }

    if (userRolesList.contains("ADS")) {
      visibleSections.add("Qubiq");
    }

    if (userRolesList.contains("TESTING")) {
      visibleSections.add("Testing");
    }

    if (userRolesList.contains("DEPLOYMENT")) {
      visibleSections.add("Deployment Dashboard");
      visibleSections.add("Operations"); // Installation staff access
      visibleSections.add("Content Hub"); // Course Hub
      visibleSections.add("Qubiq"); // Configure new schools
    }

    if (userRolesList.contains("TUTORIALS")) {
      visibleSections.add("Tutorials");
      visibleSections.add("Content Hub"); // Course Hub access
    }

    if (visibleSections.isEmpty) {
      return roles; // Fallback
    }

    // Return visible sections in original order
    return roles.where((r) => visibleSections.contains(r)).toList();
  }

  Future<void> logoutUser(BuildContext context) async {
    await context.read<AuthProvider>().logout();
  }

  /// Opens the modern dark navigation overlay
  void _openNavOverlay(List<String> visibleRoles) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Navigation",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, anim2) => const SizedBox(),
      transitionBuilder: (context, anim, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: FadeTransition(
            opacity: curvedAnim,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _NavPanel(
                visibleRoles: visibleRoles,
                selectedIndex: selectedIndex,
                getRoleIcon: getRoleIcon,
                onSelect: (i) {
                  setState(() => selectedIndex = i);
                  Navigator.pop(context);
                },
                onLogout: () {
                  Navigator.pop(context);
                  logoutUser(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.role == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthProvider>().logout();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String userRole = auth.role!;
    final permProvider = context.watch<RolePermissionProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final List<String> visibleRoles = filterRoles(userRole, permProvider);

    if (selectedIndex >= visibleRoles.length) {
      selectedIndex = 0;
    }

    final isDashboard = visibleRoles[selectedIndex] == "Dashboard";
    final showMenuButton = visibleRoles.length > 1;

    return Scaffold(
      backgroundColor: isDashboard ? _P.bg : null,
      body: Stack(
        children: [
          // Main content fills the entire screen
          Positioned.fill(
            child: Navigator(
              key: _navKey, // <--- Link to the key
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => getRolePage(visibleRoles[selectedIndex]),
              ),
            ),
          ),

          // Floating hamburger menu button - morphs into Back button if needed
          if (showMenuButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: _FloatingMenuButton(
                navKey: _navKey,
                isDashboard: isDashboard,
                onTap: () {
                  final nav = _navKey.currentState;
                  if (nav != null && nav.canPop()) {
                    nav.pop();
                    setState(() {}); // Refresh icon
                  } else {
                    _openNavOverlay(visibleRoles);
                  }
                },
              ),
            ),

          // Floating Tasks & Work Updates button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 64,
            child: _FloatingTasksButton(
              isDashboard: isDashboard,
              userId: auth.userId ?? '',
              userRole: userRole,
              onTap: () {
                StaffTasksSheet.show(context);
              },
            ),
          ),

          // Floating notification bell button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: _FloatingNotificationButton(
              isDashboard: isDashboard,
              unreadCount: notifProvider.getUnreadCount(
                auth.userId ?? '',
                userRole,
              ),
              onTap: () {
                NotificationCenterSheet.show(
                  context,
                  onNavigate: (route) {
                    final targetIdx = visibleRoles.indexOf(route);
                    if (targetIdx != -1) {
                      setState(() {
                        selectedIndex = targetIdx;
                      });
                      _navKey.currentState?.pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => getRolePage(visibleRoles[targetIdx]),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Floating Menu Button
// ═══════════════════════════════════════════════════════
class _FloatingMenuButton extends StatefulWidget {
  final GlobalKey<NavigatorState> navKey;
  final bool isDashboard;
  final VoidCallback onTap;

  const _FloatingMenuButton({
    required this.navKey,
    required this.isDashboard,
    required this.onTap,
  });

  @override
  State<_FloatingMenuButton> createState() => _FloatingMenuButtonState();
}

class _FloatingMenuButtonState extends State<_FloatingMenuButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    // Check the NESTED navigator's state specifically
    final canPop = widget.navKey.currentState?.canPop() ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _P.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering ? _P.accent : _P.surfaceLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            canPop ? Icons.close_rounded : Icons.menu_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Floating Notification Bell Button
// ═══════════════════════════════════════════════════════
class _FloatingNotificationButton extends StatefulWidget {
  final bool isDashboard;
  final int unreadCount;
  final VoidCallback onTap;

  const _FloatingNotificationButton({
    required this.isDashboard,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  State<_FloatingNotificationButton> createState() => _FloatingNotificationButtonState();
}

class _FloatingNotificationButtonState extends State<_FloatingNotificationButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _P.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering ? _P.accent : _P.surfaceLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: Colors.white,
              ),
              if (widget.unreadCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _P.bg, width: 1.5),
                    ),
                    child: Text(
                      '${widget.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Floating Tasks & Work Updates Button
// ═══════════════════════════════════════════════════════
class _FloatingTasksButton extends StatefulWidget {
  final bool isDashboard;
  final String userId;
  final String userRole;
  final VoidCallback onTap;

  const _FloatingTasksButton({
    required this.isDashboard,
    required this.userId,
    required this.userRole,
    required this.onTap,
  });

  @override
  State<_FloatingTasksButton> createState() => _FloatingTasksButtonState();
}

class _FloatingTasksButtonState extends State<_FloatingTasksButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final taskStream = taskProvider.getTasksForUserStream(widget.userId, widget.userRole);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: "Tasks & Work Updates",
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _P.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovering ? const Color(0xFF8B5CF6) : _P.surfaceLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: StreamBuilder<List<TaskModel>>(
              stream: taskStream,
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                final activeCount = tasks.where((t) => t.status != 'Completed').length;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    if (activeCount > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _P.bg, width: 1.5),
                          ),
                          child: Text(
                            '$activeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Navigation Panel (Categorized & Streamlined)
// ═══════════════════════════════════════════════════════

class _NavGroupDef {
  final String title;
  final IconData icon;
  final List<String> screens;

  const _NavGroupDef({
    required this.title,
    required this.icon,
    required this.screens,
  });
}

class _NavPanel extends StatelessWidget {
  final List<String> visibleRoles;
  final int selectedIndex;
  final IconData Function(String) getRoleIcon;
  final void Function(int) onSelect;
  final VoidCallback onLogout;

  const _NavPanel({
    required this.visibleRoles,
    required this.selectedIndex,
    required this.getRoleIcon,
    required this.onSelect,
    required this.onLogout,
  });

  static const List<_NavGroupDef> _groups = [
    _NavGroupDef(
      title: "EXECUTIVE & CORE",
      icon: Icons.space_dashboard_outlined,
      screens: [
        "Dashboard",
        "CEO Dashboard",
        "Assistant Dashboard",
        "Users",
        "Accounts",
      ],
    ),
    _NavGroupDef(
      title: "WORKSHOP & HARDWARE",
      icon: Icons.precision_manufacturing_outlined,
      screens: [
        "Operations",
        "Inventory",
        "Testing",
        "Deployment Dashboard",
      ],
    ),
    _NavGroupDef(
      title: "GROWTH & OUTREACH",
      icon: Icons.trending_up_rounded,
      screens: [
        "Marketing",
        "Digital Marketing",
        "Sales",
      ],
    ),
    _NavGroupDef(
      title: "QUBIQ & CONTENT",
      icon: Icons.hub_outlined,
      screens: [
        "QubiQ Manager",
        "App Broadcasts",
        "Qubiq",
        "Content Hub",
        "Tutorials",
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    // Collect widgets grouped by category
    final Set<String> matched = {};
    final List<Widget> navItems = [];

    for (final group in _groups) {
      final inThisGroup = group.screens.where(visibleRoles.contains).toList();
      if (inThisGroup.isNotEmpty) {
        matched.addAll(inThisGroup);

        // Category Header
        navItems.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              children: [
                Icon(group.icon, size: 12, color: _P.textMuted),
                const SizedBox(width: 6),
                Text(
                  group.title,
                  style: const TextStyle(
                    color: _P.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: _P.surfaceLight.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );

        // Group Screens
        for (final screen in inThisGroup) {
          final originalIdx = visibleRoles.indexOf(screen);
          final isSelected = originalIdx == selectedIndex;
          navItems.add(
            _NavItem(
              label: screen,
              icon: getRoleIcon(screen),
              isSelected: isSelected,
              onTap: () => onSelect(originalIdx),
            ),
          );
        }
      }
    }

    // Any remaining uncategorized screens
    final leftovers = visibleRoles.where((s) => !matched.contains(s)).toList();
    if (leftovers.isNotEmpty) {
      navItems.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Row(
            children: [
              const Icon(Icons.more_horiz_rounded, size: 12, color: _P.textMuted),
              const SizedBox(width: 6),
              const Text(
                "OTHER MODULES",
                style: TextStyle(
                  color: _P.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: _P.surfaceLight.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
      for (final screen in leftovers) {
        final originalIdx = visibleRoles.indexOf(screen);
        final isSelected = originalIdx == selectedIndex;
        navItems.add(
          _NavItem(
            label: screen,
            icon: getRoleIcon(screen),
            isSelected: isSelected,
            onTap: () => onSelect(originalIdx),
          ),
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 290,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: _P.bg,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 40,
              offset: Offset(8, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: topPadding + 16),

            // ── Logo / Brand ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "QUBIQ",
                        style: TextStyle(
                          color: _P.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "Operating System",
                        style: TextStyle(
                          color: _P.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Close button
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _P.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, color: _P.textMuted, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(height: 1, color: _P.surfaceLight),
            ),

            // ── Grouped Nav Items List ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                children: navItems,
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(height: 1, color: _P.surfaceLight),
            ),

            // ── Streamlined Footer Actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  // Compact APK download row
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => launchUrlString("/qubiq_os.apk"),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _P.surfaceLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.android_rounded, color: Colors.greenAccent, size: 15),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Mobile App",
                                  style: TextStyle(color: _P.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  "v1.0.0 • APK",
                                  style: TextStyle(color: _P.textMuted, fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.file_download_outlined, color: _P.accent, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Compact Logout button
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onLogout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 15),
                          SizedBox(width: 8),
                          Text(
                            "Logout",
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Single Nav Item (Compact & Ergonomic)
// ═══════════════════════════════════════════════════════
class _NavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? _P.accent.withValues(alpha: 0.14)
                  : (_hovering ? _P.surfaceLight.withValues(alpha: 0.7) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(color: _P.accent.withValues(alpha: 0.25), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // Left active indicator pill
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isActive ? _P.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _P.accent.withValues(alpha: 0.18)
                        : _P.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: isActive ? _P.accent : _P.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: isActive ? _P.textPrimary : _P.textSecondary,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _P.accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
