import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Permissions/RolePermissionModel.dart';
import '../../Providers/Permissions/RolePermissionProvider.dart';

// ─── Theme Colors ───
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
  static const warning = Color(0xFFFFBB55);
}

class RolePermissionsPage extends StatefulWidget {
  final String? initialRoleKey;

  const RolePermissionsPage({super.key, this.initialRoleKey});

  @override
  State<RolePermissionsPage> createState() => _RolePermissionsPageState();
}

class _RolePermissionsPageState extends State<RolePermissionsPage> {
  late String _selectedRoleKey;
  RolePermissionModel? _workingModel;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  final Map<String, String> _roleDisplayNames = {
    'ADMIN': 'Administrator',
    'ASSEMBLY_TEAM': 'Assembly Team',
    'INSTALLATION_TEAM': 'Installation Team',
    'ACCOUNTS': 'Accounts & Billing',
    'MARKETING': 'Field Marketing',
    'TELE_MARKETING': 'Tele-Marketing',
    'DIGITAL_MARKETING': 'Digital Marketing & SEO',
    'QUBIQ': 'QubiQ Specialist',
    'ADS': 'Ads & Media',
    'TESTING': 'QA & Testing',
    'DEPLOYMENT': 'Deployment Staff',
    'TUTORIALS': 'Tutorials & Training',
  };

  final Map<String, IconData> _roleIcons = {
    'ADMIN': Icons.admin_panel_settings_rounded,
    'ASSEMBLY_TEAM': Icons.build_circle_rounded,
    'INSTALLATION_TEAM': Icons.engineering_rounded,
    'ACCOUNTS': Icons.account_balance_wallet_rounded,
    'MARKETING': Icons.campaign_rounded,
    'TELE_MARKETING': Icons.phone_in_talk_rounded,
    'DIGITAL_MARKETING': Icons.computer_rounded,
    'QUBIQ': Icons.api_rounded,
    'ADS': Icons.video_library_rounded,
    'TESTING': Icons.bug_report_rounded,
    'DEPLOYMENT': Icons.flight_takeoff_rounded,
    'TUTORIALS': Icons.menu_book_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedRoleKey = widget.initialRoleKey ?? RolePermissionProvider.supportedRoles.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRolePermissions(_selectedRoleKey);
    });
  }

  void _loadRolePermissions(String roleKey) {
    final provider = Provider.of<RolePermissionProvider>(context, listen: false);
    setState(() {
      _selectedRoleKey = roleKey;
      _workingModel = provider.getPermissionForRole(roleKey);
      _hasUnsavedChanges = false;
    });
  }

  void _onToggleChanged(RolePermissionModel updated) {
    setState(() {
      _workingModel = updated;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _savePermissions() async {
    if (_workingModel == null) return;
    setState(() => _isSaving = true);

    final provider = Provider.of<RolePermissionProvider>(context, listen: false);
    final success = await provider.updateRolePermissions(_workingModel!);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (success) _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: success ? _C.success : _C.danger,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              success
                  ? 'Permissions for ${_roleDisplayNames[_selectedRoleKey] ?? _selectedRoleKey} updated'
                  : 'Failed to update permissions: ${provider.errorMessage}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: _C.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _confirmResetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _C.surfaceLight),
        ),
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: _C.warning),
            SizedBox(width: 10),
            Text('Reset to Defaults?', style: TextStyle(color: _C.textPrimary, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all permissions for ${_roleDisplayNames[_selectedRoleKey] ?? _selectedRoleKey} to factory defaults?',
          style: const TextStyle(color: _C.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _C.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.warning,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset Defaults', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      final provider = Provider.of<RolePermissionProvider>(context, listen: false);
      final success = await provider.resetRoleToDefaults(_selectedRoleKey);

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _workingModel = provider.getPermissionForRole(_selectedRoleKey);
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Reset permissions to default successfully' : 'Reset failed',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _C.surfaceLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final model = _workingModel ?? RolePermissionModel.defaultForRole(_selectedRoleKey);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role & Permission Matrix',
              style: TextStyle(
                color: _C.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage screen access & operational privileges per role',
              style: TextStyle(
                color: _C.textSecondary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (_hasUnsavedChanges)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.warning.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 14, color: _C.warning),
                      SizedBox(width: 4),
                      Text(
                        'Unsaved Changes',
                        style: TextStyle(color: _C.warning, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Reset Role to Factory Defaults',
            icon: const Icon(Icons.restore_rounded, color: _C.textSecondary),
            onPressed: _confirmResetToDefaults,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 6),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasUnsavedChanges ? _C.accent : _C.surfaceLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_isSaving ? 'Saving...' : 'Save Matrix'),
              onPressed: _isSaving || !_hasUnsavedChanges ? null : _savePermissions,
            ),
          ),
        ],
      ),
      body: isWide ? _buildWideLayout(model) : _buildMobileLayout(model),
    );
  }

  Widget _buildWideLayout(RolePermissionModel model) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Role Selector Sidebar
        SizedBox(
          width: 300,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: _C.accent, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'User Roles',
                        style: TextStyle(
                          color: _C.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${RolePermissionProvider.supportedRoles.length}',
                          style: const TextStyle(color: _C.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _C.surfaceLight, height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: RolePermissionProvider.supportedRoles.length,
                    itemBuilder: (context, idx) {
                      final roleKey = RolePermissionProvider.supportedRoles[idx];
                      final isSelected = roleKey == _selectedRoleKey;
                      final label = _roleDisplayNames[roleKey] ?? roleKey;
                      final icon = _roleIcons[roleKey] ?? Icons.person_rounded;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? _C.accent.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _C.accent.withOpacity(0.5) : Colors.transparent,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            icon,
                            color: isSelected ? _C.accent : _C.textSecondary,
                            size: 20,
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : _C.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.chevron_right_rounded, color: _C.accent, size: 18)
                              : null,
                          onTap: () {
                            if (_hasUnsavedChanges) {
                              _promptUnsavedThenSwitch(roleKey);
                            } else {
                              _loadRolePermissions(roleKey);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Column: Permission Matrix Toggles
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 40),
            child: _buildPermissionSections(model),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(RolePermissionModel model) {
    return Column(
      children: [
        // Horizontal Role selector
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: _C.surface,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: RolePermissionProvider.supportedRoles.length,
            itemBuilder: (context, idx) {
              final roleKey = RolePermissionProvider.supportedRoles[idx];
              final isSelected = roleKey == _selectedRoleKey;
              final label = _roleDisplayNames[roleKey] ?? roleKey;

              return ChoiceChip(
                selected: isSelected,
                label: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _C.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selectedColor: _C.accent,
                backgroundColor: _C.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val && !isSelected) {
                    if (_hasUnsavedChanges) {
                      _promptUnsavedThenSwitch(roleKey);
                    } else {
                      _loadRolePermissions(roleKey);
                    }
                  }
                },
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildPermissionSections(model),
          ),
        ),
      ],
    );
  }

  void _promptUnsavedThenSwitch(String newRoleKey) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        title: const Text('Discard Unsaved Changes?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved changes in this role. Switching roles will discard them.',
          style: TextStyle(color: _C.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay Here', style: TextStyle(color: _C.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () {
              Navigator.pop(ctx);
              _loadRolePermissions(newRoleKey);
            },
            child: const Text('Discard & Switch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSections(RolePermissionModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _C.accent.withOpacity(0.2),
                _C.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _roleIcons[_selectedRoleKey] ?? Icons.security_rounded,
                  color: _C.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _roleDisplayNames[_selectedRoleKey] ?? _selectedRoleKey,
                      style: const TextStyle(
                        color: _C.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Internal Role Key: $_selectedRoleKey',
                      style: const TextStyle(color: _C.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Quick action buttons
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.textSecondary,
                  side: const BorderSide(color: _C.surfaceLight),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_box_outlined, size: 14),
                label: const Text('Grant All', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _onToggleChanged(
                    model.copyWith(
                      canAccessDashboard: true,
                      canAccessInventory: true,
                      canAccessOperations: true,
                      canAccessSales: true,
                      canAccessAccounts: true,
                      canAccessUsers: true,
                      canAccessTesting: true,
                      canAccessContentHub: true,
                      canAccessDigitalMarketing: true,
                      canAccessTutorials: true,
                      canAccessQubiq: true,
                      canAccessDeployment: true,
                      canModifyInventory: true,
                      canDeleteInventory: true,
                      canEditProducts: true,
                      canManageBills: true,
                      canManageUsers: true,
                      canSignOffInstallation: true,
                      canExportReports: true,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.textSecondary,
                  side: const BorderSide(color: _C.surfaceLight),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.disabled_by_default_outlined, size: 14),
                label: const Text('Revoke All', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _onToggleChanged(
                    model.copyWith(
                      canAccessDashboard: false,
                      canAccessInventory: false,
                      canAccessOperations: false,
                      canAccessSales: false,
                      canAccessAccounts: false,
                      canAccessUsers: false,
                      canAccessTesting: false,
                      canAccessContentHub: false,
                      canAccessDigitalMarketing: false,
                      canAccessTutorials: false,
                      canAccessQubiq: false,
                      canAccessDeployment: false,
                      canModifyInventory: false,
                      canDeleteInventory: false,
                      canEditProducts: false,
                      canManageBills: false,
                      canManageUsers: false,
                      canSignOffInstallation: false,
                      canExportReports: false,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section 1: Screen & Navigation Access
        _buildSectionHeader(
          title: 'Screen & Navigation Access',
          subtitle: 'Choose which portal screens and department modules are visible to this role',
          icon: Icons.dashboard_customize_rounded,
        ),
        const SizedBox(height: 12),
        _buildTileGrid([
          _ToggleItem(
            title: 'Inventory & Workshop Storage',
            description: 'Components catalogue, shelf numbers, stock levels, and audit trail',
            icon: Icons.inventory_2_rounded,
            value: model.canAccessInventory,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessInventory: val)),
          ),
          _ToggleItem(
            title: 'Operations Dashboard',
            description: 'Assembly line progress, installations, and factory work tracking',
            icon: Icons.precision_manufacturing_outlined,
            value: model.canAccessOperations,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessOperations: val)),
          ),
          _ToggleItem(
            title: 'Sales & Inquiries',
            description: 'Prospect pipeline, school interactions, and client lead management',
            icon: Icons.storefront_rounded,
            value: model.canAccessSales,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessSales: val)),
          ),
          _ToggleItem(
            title: 'Accounts & Billing',
            description: 'School payments, invoices, financial records, and revenue sheets',
            icon: Icons.account_balance_wallet_rounded,
            value: model.canAccessAccounts,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessAccounts: val)),
          ),
          _ToggleItem(
            title: 'Team & User Management',
            description: 'Directory of staff, role provisioning, and account management',
            icon: Icons.people_alt_rounded,
            value: model.canAccessUsers,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessUsers: val)),
          ),
          _ToggleItem(
            title: 'QA & Hardware Testing',
            description: 'Quality checklists, verification runs, and bug reporting',
            icon: Icons.bug_report_rounded,
            value: model.canAccessTesting,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessTesting: val)),
          ),
          _ToggleItem(
            title: 'Content Hub & Courses',
            description: 'Curriculum repository, educational modules, and resources',
            icon: Icons.school_rounded,
            value: model.canAccessContentHub,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessContentHub: val)),
          ),
          _ToggleItem(
            title: 'Digital Marketing & SEO',
            description: 'Analytics, outreach campaigns, and online branding trackers',
            icon: Icons.campaign_outlined,
            value: model.canAccessDigitalMarketing,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessDigitalMarketing: val)),
          ),
          _ToggleItem(
            title: 'Tutorials & Knowledge Base',
            description: 'Staff manuals, training videos, and walkthroughs',
            icon: Icons.video_library_rounded,
            value: model.canAccessTutorials,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessTutorials: val)),
          ),
          _ToggleItem(
            title: 'QubiQ Manager & Broadcasts',
            description: 'QubiQ school portal configs and live app update broadcasts',
            icon: Icons.hub_rounded,
            value: model.canAccessQubiq,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessQubiq: val)),
          ),
          _ToggleItem(
            title: 'Deployment Dashboard',
            description: 'Active installation milestones and on-site rollout statuses',
            icon: Icons.rocket_launch_rounded,
            value: model.canAccessDeployment,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessDeployment: val)),
          ),
          _ToggleItem(
            title: 'Super Admin Overview',
            description: 'High-level business aggregates and central master dashboard',
            icon: Icons.space_dashboard_rounded,
            value: model.canAccessDashboard,
            onChanged: (val) => _onToggleChanged(model.copyWith(canAccessDashboard: val)),
          ),
        ]),

        const SizedBox(height: 28),

        // Section 2: Workshop & Operational Capabilities
        _buildSectionHeader(
          title: 'Workshop & Operational Capabilities',
          subtitle: 'Actions this role can perform inside accessible modules',
          icon: Icons.engineering_rounded,
        ),
        const SizedBox(height: 12),
        _buildTileGrid([
          _ToggleItem(
            title: 'Modify Inventory & Move Shelves',
            description: 'Add new parts, update stock numbers, and transfer parts between shelves',
            icon: Icons.edit_note_rounded,
            value: model.canModifyInventory,
            onChanged: (val) => _onToggleChanged(model.copyWith(canModifyInventory: val)),
          ),
          _ToggleItem(
            title: 'Delete Inventory Components',
            description: 'Permanently remove parts from the workshop inventory catalog',
            icon: Icons.delete_forever_rounded,
            value: model.canDeleteInventory,
            onChanged: (val) => _onToggleChanged(model.copyWith(canDeleteInventory: val)),
          ),
          _ToggleItem(
            title: 'Edit Product Configurations',
            description: 'Change master product kits, bill-of-materials, and assembly checklists',
            icon: Icons.tune_rounded,
            value: model.canEditProducts,
            onChanged: (val) => _onToggleChanged(model.copyWith(canEditProducts: val)),
          ),
          _ToggleItem(
            title: 'Sign-Off Installations',
            description: 'Officially certify and sign off school hardware deployments',
            icon: Icons.assignment_turned_in_rounded,
            value: model.canSignOffInstallation,
            onChanged: (val) => _onToggleChanged(model.copyWith(canSignOffInstallation: val)),
          ),
        ]),

        const SizedBox(height: 28),

        // Section 3: Financial & Governance Controls
        _buildSectionHeader(
          title: 'Financial & Governance Controls',
          subtitle: 'Sensitive financial operations and administrative management',
          icon: Icons.verified_user_rounded,
        ),
        const SizedBox(height: 12),
        _buildTileGrid([
          _ToggleItem(
            title: 'Manage Bills & Invoices',
            description: 'Issue, mark paid, or alter billing ledgers and payment receipts',
            icon: Icons.receipt_long_rounded,
            value: model.canManageBills,
            onChanged: (val) => _onToggleChanged(model.copyWith(canManageBills: val)),
          ),
          _ToggleItem(
            title: 'Manage Users & Permissions',
            description: 'Create new user accounts, update passwords, and modify staff roles',
            icon: Icons.manage_accounts_rounded,
            value: model.canManageUsers,
            onChanged: (val) => _onToggleChanged(model.copyWith(canManageUsers: val)),
          ),
          _ToggleItem(
            title: 'Export Audit & Activity Reports',
            description: 'Download CSV/Excel data sheets for inventory logs and finances',
            icon: Icons.file_download_rounded,
            value: model.canExportReports,
            onChanged: (val) => _onToggleChanged(model.copyWith(canExportReports: val)),
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _C.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _C.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: _C.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTileGrid(List<_ToggleItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 82,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final item = items[idx];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.value ? _C.accent.withOpacity(0.4) : _C.surfaceLight,
                  width: item.value ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.value ? _C.accent.withOpacity(0.15) : _C.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: item.value ? _C.accent : _C.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: item.value ? Colors.white : _C.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: _C.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: item.value,
                    activeThumbColor: _C.accent,
                    activeTrackColor: _C.accent.withOpacity(0.4),
                    inactiveThumbColor: _C.textMuted,
                    inactiveTrackColor: _C.surfaceLight,
                    onChanged: item.onChanged,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ToggleItem {
  final String title;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
}
