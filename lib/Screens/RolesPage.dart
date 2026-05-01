import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/AuthProvider.dart';

import 'Accounts/School_account_page.dart';
import 'UserManagementPage.dart';
import 'OperationsPage.dart';
import 'SalesPage.dart';
import 'SuperAdmin/super_admin_page.dart';
import 'Qubiq/qubiq_page.dart';
import 'Testing/testing_page.dart';

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
    "Users",
    "Sales",
    "Accounts",
    "Operations",
    "Qubiq",
    "Testing",
  ];
  final allowedRoles = {
    "Users",
    "Sales",
    "Qubiq",
  };

  IconData getRoleIcon(String role) {
    switch (role) {
      case "Dashboard":
        return Icons.dashboard;
      case "Users":
        return Icons.people_alt;
      case "Sales":
        return Icons.storefront;
      case "Accounts":
        return Icons.account_balance_wallet;
      case "Operations":
        return Icons.precision_manufacturing;
      case "Qubiq":
        return Icons.api;
      case "Testing":
        return Icons.bug_report;
      default:
        return Icons.person;
    }
  }

  Widget getRolePage(String role) {
    switch (role) {
      case "Dashboard":
        return const SuperAdminPage();
      case "Users":
        return const UserManagementPage();
      case "Sales":
        return const SalesPage();
      case "Accounts":
        return SchoolVisitListPageAccounts();
      case "Operations":
        return const OperationsPage();
      case "Qubiq":
        return const QubiqPage();
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

    if (userRole == "MARKETING" || userRole == "TELE_MARKETING") {
      return ["Sales"];
    }

    if (userRole == "ACCOUNTS") {
      return ["Accounts"];
    }

    if (userRole == "ASSEMBLY_TEAM" || userRole == "INSTALLATION_TEAM") {
      return ["Operations", "Testing"];
    }

    if (userRole == "QUBIQ") {
      return ["Qubiq", "Sales"];
    }

    if (userRole == "ADS") {
      return ["Qubiq"];
    }

    if (userRole == "TESTING") {
      return ["Testing"];
    }

    return roles; // Super Admin sees everything
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

    final isDashboard = visibleRoles[selectedIndex] == "Dashboard";
    final showMenuButton = visibleRoles.length > 1;

    return Scaffold(
      backgroundColor: isDashboard ? _P.bg : null,
      // No AppBar at all — we handle navigation via the overlay
      body: Stack(
        children: [
          // Main content fills the entire screen
          Positioned.fill(
            child: Navigator(
              key: ValueKey(visibleRoles[selectedIndex]),
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => getRolePage(visibleRoles[selectedIndex]),
              ),
            ),
          ),

          // Floating hamburger menu button
          if (showMenuButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: _FloatingMenuButton(
                isDashboard: isDashboard,
                onTap: () => _openNavOverlay(visibleRoles),
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
  final bool isDashboard;
  final VoidCallback onTap;

  const _FloatingMenuButton({
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
            color: _hovering
                ? (widget.isDashboard
                    ? _P.surfaceLight
                    : Colors.grey.shade200)
                : (widget.isDashboard
                    ? _P.surface
                    : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDashboard
                  ? _P.surfaceLight
                  : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                    widget.isDashboard ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.menu,
            size: 22,
            color: widget.isDashboard
                ? _P.textSecondary
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Navigation Panel (overlay)
// ═══════════════════════════════════════════════════════
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EMMI",
                        style: TextStyle(
                          color: _P.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "Management Console",
                        style: TextStyle(
                          color: _P.textMuted,
                          fontSize: 11,
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
                      child: const Icon(Icons.close,
                          color: _P.textMuted, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 1,
                color: _P.surfaceLight,
              ),
            ),

            const SizedBox(height: 12),

            // ── Section Label ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "NAVIGATION",
                  style: TextStyle(
                    color: _P.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            // ── Nav Items ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: visibleRoles.length,
                itemBuilder: (context, i) {
                  final isSelected = i == selectedIndex;
                  final role = visibleRoles[i];
                  return _NavItem(
                    label: role,
                    icon: getRoleIcon(role),
                    isSelected: isSelected,
                    onTap: () => onSelect(i),
                  );
                },
              ),
            ),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(height: 1, color: _P.surfaceLight),
            ),

            // ── Logout ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onLogout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout,
                          color: Color(0xFFFF6B6B), size: 18),
                      SizedBox(width: 10),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Single Nav Item
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isActive
                  ? _P.accent.withOpacity(0.12)
                  : (_hovering ? _P.surfaceLight : Colors.transparent),
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(color: _P.accent.withOpacity(0.2), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _P.accent.withOpacity(0.15)
                        : _P.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: isActive ? _P.accent : _P.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
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
