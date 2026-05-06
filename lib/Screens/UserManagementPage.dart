import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Providers/AuthProvider.dart';
import '../../Providers/User_provider.dart';
import '../../Model/User_model.dart';

// ─── Palette ───
class _C {
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surfaceLight = Color(0xFF242836);
  static const accent = Color(0xFF6C63FF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B8FA3);
  static const textMuted = Color(0xFF565B73);
  static const danger = Color(0xFFFF6B6B);
  static const success = Color(0xFF00D4AA);
}

/// All available role options for user assignment
const _roleOptions = [
  {"key": "ADMIN", "label": "Admin", "icon": Icons.admin_panel_settings},
  {"key": "MARKETING", "label": "Marketing", "icon": Icons.campaign},
  {"key": "TELE_MARKETING", "label": "Tele Marketing", "icon": Icons.phone_in_talk},
  {"key": "ACCOUNTS", "label": "Accounts", "icon": Icons.account_balance_wallet},
  {"key": "ASSEMBLY_TEAM", "label": "Assembly", "icon": Icons.build},
  {"key": "INSTALLATION_TEAM", "label": "Installation", "icon": Icons.engineering},
  {"key": "QUBIQ", "label": "Qubiq", "icon": Icons.api},
  {"key": "ADS", "label": "Ads", "icon": Icons.video_library},
  {"key": "TESTING", "label": "Testing", "icon": Icons.bug_report},
];

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with SingleTickerProviderStateMixin {
  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String? _filterRole;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _loadUsers();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();
      _allUsers.sort((a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
    } catch (e) {
      debugPrint("Load users error: $e");
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeCtrl.forward(from: 0);
    }
  }

  List<UserModel> get _filteredUsers {
    var list = _allUsers;
    if (_filterRole != null) {
      list = list
          .where((u) => u.role?.toUpperCase() == _filterRole!.toUpperCase())
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((u) =>
              (u.name ?? '').toLowerCase().contains(q) ||
              (u.email ?? '').toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove User",
            style: TextStyle(
                color: _C.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        content: Text(
          "Remove ${user.name ?? user.email ?? 'this user'} from the team?",
          style: const TextStyle(color: _C.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text("Cancel", style: TextStyle(color: _C.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _C.danger),
            child: const Text("Remove",
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || user.id == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .delete();
      setState(() => _allUsers.removeWhere((u) => u.id == user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${user.name ?? 'User'} removed"),
          backgroundColor: _C.surface,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  void _showAddUserSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddUserSheet(onAdded: _loadUsers),
    );
  }

  void _showEditRoleSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditRoleSheet(
        user: user,
        onUpdated: (newRole) {
          // Update local list immediately
          setState(() {
            final idx = _allUsers.indexWhere((u) => u.id == user.id);
            if (idx != -1) {
              _allUsers[idx] = UserModel(
                id: user.id,
                name: user.name,
                email: user.email,
                phone: user.phone,
                role: newRole,
                roleId: user.roleId,
                isEnabled: user.isEnabled,
                createdTime: user.createdTime,
                createdById: user.createdById,
                createdByName: user.createdByName,
              );
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final users = _filteredUsers;

    return Container(
      color: _C.bg,
      child: Column(
        children: [
          // ═══ HEADER ═══
          Container(
            padding: EdgeInsets.only(
              top: topPad + 52,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B1464), Color(0xFF6C63FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -30,
                  top: -50,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Column(
                  children: [
                    // Title row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.people_alt,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Users",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "${_allUsers.length} team members",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add user button
                        GestureDetector(
                          onTap: _showAddUserSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    size: 18, color: Color(0xFF1B1464)),
                                SizedBox(width: 6),
                                Text(
                                  "Add User",
                                  style: TextStyle(
                                    color: Color(0xFF1B1464),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Search bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: Colors.white.withOpacity(0.4), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Search by name or email…",
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Role filter chips
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip("All", null),
                          ..._roleOptions.map((r) =>
                              _filterChip(r["label"] as String, r["key"] as String)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ═══ USER LIST ═══
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _C.accent))
                : users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search,
                                size: 48, color: _C.textMuted),
                            const SizedBox(height: 12),
                            const Text("No users found",
                                style: TextStyle(
                                    color: _C.textMuted, fontSize: 14)),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildUserTile(users[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? roleKey) {
    final isActive = _filterRole == roleKey;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterRole = roleKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1B1464) : Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    final roleColor = _getRoleColor(user.role);
    return GestureDetector(
      onTap: () => _showEditRoleSheet(user),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.surfaceLight, width: 1),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  (user.name ?? "?")[0].toUpperCase(),
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? "Unknown",
                    style: const TextStyle(
                      color: _C.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? "No email",
                    style: const TextStyle(
                      color: _C.textMuted,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatRole(user.role),
                style: TextStyle(
                  color: roleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Edit
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showEditRoleSheet(user),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.edit, size: 15, color: _C.accent),
              ),
            ),
            const SizedBox(width: 6),

            // Delete
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _deleteUser(user),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _C.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.delete_outline, size: 16, color: _C.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'SUPER_ADMIN':
        return _C.accent;
      case 'ADMIN':
        return _C.success;
      case 'MARKETING':
        return const Color(0xFFFFBB55);
      case 'TELE_MARKETING':
        return const Color(0xFF5B8DEF);
      case 'ACCOUNTS':
        return const Color(0xFFE17055);
      case 'ASSEMBLY_TEAM':
        return const Color(0xFF00CEC9);
      case 'INSTALLATION_TEAM':
        return const Color(0xFFA29BFE);
      case 'QUBIQ':
        return const Color(0xFF6C5CE7);
      case 'ADS':
        return const Color(0xFFFD79A8);
      case 'TESTING':
        return _C.danger;
      default:
        return _C.textSecondary;
    }
  }

  String _formatRole(String? role) {
    if (role == null) return "N/A";
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}

// ═══════════════════════════════════════════════════════
//  ADD USER BOTTOM SHEET
// ═══════════════════════════════════════════════════════
class _AddUserSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddUserSheet({required this.onAdded});

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _selectedRole;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showError("Please fill in name and email");
      return;
    }
    if (_selectedRole == null) {
      _showError("Please select a role");
      return;
    }

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final msg = await context.read<UserProvider>().sendTeamInvite(
          name: name,
          email: email,
          role: _selectedRole!,
          adminId: auth.userId!,
          adminName: auth.name!,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (msg.startsWith("http")) {
      widget.onAdded();
      
      // Show dialog with the link
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Setup Link Generated",
              style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Copy this link and send it to the new member:",
                style: TextStyle(color: _C.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.surfaceLight),
                ),
                child: SelectableText(
                  msg,
                  style: const TextStyle(color: _C.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: msg));
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: const Text("Link copied to clipboard"),
                  backgroundColor: _C.surface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: const Text("Copy", style: TextStyle(color: _C.accent, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Done", style: TextStyle(color: _C.textMuted)),
            ),
          ],
        ),
      );

      // Now close the bottom sheet
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: msg.toLowerCase().contains("failed") ? _C.danger : _C.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

      if (msg.toLowerCase().contains("successful")) {
        widget.onAdded();
        Navigator.pop(context);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _C.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: const BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Invite Team Member",
              style: TextStyle(
                color: _C.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "They'll receive an invitation link to create their account",
              style: TextStyle(color: _C.textMuted, fontSize: 13),
            ),

            const SizedBox(height: 24),

            // Name field
            _buildField(
              controller: _nameCtrl,
              label: "Full Name",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),

            // Email field
            _buildField(
              controller: _emailCtrl,
              label: "Email Address",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            // Role label
            const Text(
              "Assign Role",
              style: TextStyle(
                color: _C.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // Role grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roleOptions.map((r) {
                final key = r["key"] as String;
                final label = r["label"] as String;
                final icon = r["icon"] as IconData;
                final isSelected = _selectedRole == key;

                return GestureDetector(
                  onTap: () => setState(() => _selectedRole = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _C.accent.withOpacity(0.15)
                          : _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _C.accent.withOpacity(0.4)
                            : _C.surfaceLight,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 16,
                            color:
                                isSelected ? _C.accent : _C.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? _C.textPrimary
                                : _C.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Send Invitation Link",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.surfaceLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: _C.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !_isSaving,
              keyboardType: keyboardType,
              style: const TextStyle(color: _C.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  EDIT ROLE BOTTOM SHEET
// ═══════════════════════════════════════════════════════
class _EditRoleSheet extends StatefulWidget {
  final UserModel user;
  final void Function(String newRole) onUpdated;

  const _EditRoleSheet({required this.user, required this.onUpdated});

  @override
  State<_EditRoleSheet> createState() => _EditRoleSheetState();
}

class _EditRoleSheetState extends State<_EditRoleSheet> {
  late String? _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  String _formatRole(String? role) {
    if (role == null) return "N/A";
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  Future<void> _save() async {
    if (_selectedRole == null || _selectedRole == widget.user.role) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'role': _selectedRole});

      widget.onUpdated(_selectedRole!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "${widget.user.name ?? 'User'} updated to ${_formatRole(_selectedRole)}"),
          backgroundColor: _C.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Update role error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Failed to update role"),
          backgroundColor: _C.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final hasChanged = _selectedRole != widget.user.role;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: const BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User info header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (widget.user.name ?? "?")[0].toUpperCase(),
                      style: const TextStyle(
                        color: _C.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name ?? "Unknown",
                        style: const TextStyle(
                          color: _C.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email ?? "No email",
                        style: const TextStyle(
                          color: _C.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Current role
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _C.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 16, color: _C.textMuted),
                  const SizedBox(width: 10),
                  const Text(
                    "Current role:",
                    style: TextStyle(color: _C.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatRole(widget.user.role),
                    style: const TextStyle(
                      color: _C.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Change Role",
              style: TextStyle(
                color: _C.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // Role grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roleOptions.map((r) {
                final key = r["key"] as String;
                final label = r["label"] as String;
                final icon = r["icon"] as IconData;
                final isSelected = _selectedRole == key;

                return GestureDetector(
                  onTap: _isSaving ? null : () => setState(() => _selectedRole = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _C.accent.withOpacity(0.15)
                          : _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _C.accent.withOpacity(0.4)
                            : _C.surfaceLight,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 16,
                            color: isSelected ? _C.accent : _C.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color:
                                isSelected ? _C.textPrimary : _C.textSecondary,
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle,
                              size: 14, color: _C.accent),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isSaving || !hasChanged) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasChanged ? _C.accent : _C.surfaceLight,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _C.surfaceLight,
                  disabledForegroundColor: _C.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        hasChanged ? "Save Changes" : "No Changes",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
