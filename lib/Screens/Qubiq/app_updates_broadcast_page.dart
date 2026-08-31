import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../Model/Updates/app_update_model.dart';
import '../../Providers/Updates/app_update_provider.dart';

class AppUpdatesBroadcastPage extends StatefulWidget {
  const AppUpdatesBroadcastPage({super.key});

  @override
  State<AppUpdatesBroadcastPage> createState() => _AppUpdatesBroadcastPageState();
}

class _AppUpdatesBroadcastPageState extends State<AppUpdatesBroadcastPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppUpdateProvider>().fetchUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppUpdateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep Obsidian
      body: Stack(
        children: [
          // Background Glow Blobs
          Positioned(
            top: -60,
            right: -60,
            child: _buildBlob(350, const Color(0xFF38BDF8).withOpacity(0.12)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildBlob(400, const Color(0xFF7C3AED).withOpacity(0.12)),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchUpdates(),
              color: const Color(0xFF38BDF8),
              backgroundColor: const Color(0xFF0F172A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    // Metrics Bar
                    _buildMetricsBar(provider),
                    const SizedBox(height: 24),

                    // Controls & Filters Bar
                    _buildControlsBar(provider),
                    const SizedBox(height: 20),

                    // Broadcasts List
                    if (provider.isLoading && provider.updates.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(60.0),
                          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                        ),
                      )
                    else if (provider.filteredUpdates.isEmpty)
                      _buildEmptyState(provider)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.filteredUpdates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = provider.filteredUpdates[index];
                          return _buildBroadcastCard(item, provider);
                        },
                      ),

                    const SizedBox(height: 80), // Dock clearance
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF38BDF8),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "App Updates & Broadcasts",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Publish announcements, feature releases, and critical app alerts to all QubiQ users",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _openBroadcastDialog(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            "New Broadcast",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 4,
            shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsBar(AppUpdateProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: "Total Broadcasts",
            value: "${provider.totalCount}",
            icon: Icons.history_rounded,
            color: const Color(0xFF38BDF8),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            title: "Active Broadcasts",
            value: "${provider.activeCount}",
            icon: Icons.cell_tower_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            title: "Critical Alerts",
            value: "${provider.criticalCount}",
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 10,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsBar(AppUpdateProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Search Input
              SizedBox(
                width: 280,
                height: 42,
                child: TextField(
                  onChanged: (val) => provider.setSearchQuery(val),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Search updates...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF1E293B).withOpacity(0.7),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                    ),
                  ),
                ),
              ),

              // Filter by Target App
              _buildFilterDropdown(
                label: "Target App",
                value: provider.selectedAppFilter,
                items: [
                  {'id': 'all', 'name': 'All Apps'},
                  ...AppUpdateModel.supportedApps.where((a) => a['id'] != 'all'),
                ],
                onChanged: (val) => provider.setAppFilter(val ?? 'all'),
              ),

              // Filter by Criticality
              _buildFilterDropdown(
                label: "Severity",
                value: provider.selectedCriticalFilter,
                items: const [
                  {'id': 'all', 'name': 'All Severities'},
                  {'id': 'critical', 'name': 'Critical Alerts Only'},
                  {'id': 'normal', 'name': 'Informational Only'},
                ],
                onChanged: (val) => provider.setCriticalFilter(val ?? 'all'),
              ),

              // Filter by Status
              _buildFilterDropdown(
                label: "Status",
                value: provider.selectedStatusFilter,
                items: const [
                  {'id': 'all', 'name': 'All Statuses'},
                  {'id': 'active', 'name': 'Active Only'},
                  {'id': 'inactive', 'name': 'Inactive Only'},
                ],
                onChanged: (val) => provider.setStatusFilter(val ?? 'all'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF0F172A),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF94A3B8)),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(
                item['name'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBroadcastCard(AppUpdateModel item, AppUpdateProvider provider) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(item.createdAt);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: item.isCritical
                ? const Color(0xFF1E1B4B).withOpacity(0.4)
                : const Color(0xFF0F172A).withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isCritical
                  ? const Color(0xFFEF4444).withOpacity(0.4)
                  : Colors.white.withOpacity(0.09),
              width: item.isCritical ? 1.5 : 1,
            ),
            boxShadow: [
              if (item.isCritical && item.isActive)
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Badges and Quick Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Criticality Badge
                  if (item.isCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 14),
                          SizedBox(width: 4),
                          Text(
                            "CRITICAL ALERT",
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                      ),
                      child: const Text(
                        "UPDATE",
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                  // Target App Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                    ),
                    child: Text(
                      item.targetAppName,
                      style: const TextStyle(
                        color: Color(0xFFA78BFA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Version Tag Badge
                  if (item.versionTag != null && item.versionTag!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.versionTag!,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  if (item.blockAppLaunch) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Blocks App Entry",
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Active Switch
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          color: item.isActive ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: item.isActive,
                          activeColor: const Color(0xFF10B981),
                          activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                          inactiveThumbColor: const Color(0xFF64748B),
                          inactiveTrackColor: const Color(0xFF1E293B),
                          onChanged: (val) {
                            provider.toggleActiveStatus(item.id, val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 18),
                    tooltip: "Edit Broadcast",
                    onPressed: () => _openBroadcastDialog(context, existingUpdate: item),
                  ),

                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                    tooltip: "Delete",
                    onPressed: () => _confirmDelete(context, item, provider),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Title
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 6),

              // Description
              Text(
                item.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 14),

              // Bottom Details Row
              Row(
                children: [
                  // Target Roles
                  Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        "Audience: ${item.targetRoles.join(', ').toUpperCase()}",
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Action Button Tag (if any)
                  if (item.actionButtonText != null && item.actionButtonText!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 14, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 4),
                        Text(
                          "Action: ${item.actionButtonText}",
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),

                  const Spacer(),

                  // Timestamp & Author
                  Text(
                    "$formattedDate • by ${item.createdBy}",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppUpdateProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: Color(0xFF64748B),
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Broadcasts Found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Create an update or critical alert to broadcast to all QubiQ users.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openBroadcastDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Create First Broadcast"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppUpdateModel item, AppUpdateProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text("Delete Broadcast?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to delete '${item.title}'? This will remove the notification immediately from all client apps.",
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteUpdate(item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _openBroadcastDialog(BuildContext context, {AppUpdateModel? existingUpdate}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BroadcastDialog(existingUpdate: existingUpdate),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG FOR CREATING / EDITING A BROADCAST (WITH LIVE PREVIEW)
// ─────────────────────────────────────────────────────────────
class _BroadcastDialog extends StatefulWidget {
  final AppUpdateModel? existingUpdate;
  const _BroadcastDialog({this.existingUpdate});

  @override
  State<_BroadcastDialog> createState() => _BroadcastDialogState();
}

class _BroadcastDialogState extends State<_BroadcastDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _versionController;
  late TextEditingController _btnTextController;
  late TextEditingController _btnUrlController;

  String _selectedApp = 'all';
  bool _isCritical = false;
  bool _blockAppLaunch = false;
  bool _isActive = true;

  bool _forStudents = true;
  bool _forTeachers = true;
  bool _forAdmins = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.existingUpdate;
    _titleController = TextEditingController(text: u?.title ?? '');
    _descController = TextEditingController(text: u?.description ?? '');
    _versionController = TextEditingController(text: u?.versionTag ?? '');
    _btnTextController = TextEditingController(text: u?.actionButtonText ?? '');
    _btnUrlController = TextEditingController(text: u?.actionUrl ?? '');

    if (u != null) {
      _selectedApp = u.targetApp;
      _isCritical = u.isCritical;
      _blockAppLaunch = u.blockAppLaunch;
      _isActive = u.isActive;
      _forStudents = u.targetRoles.contains('all') || u.targetRoles.contains('student');
      _forTeachers = u.targetRoles.contains('all') || u.targetRoles.contains('teacher');
      _forAdmins = u.targetRoles.contains('all') || u.targetRoles.contains('admin');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _versionController.dispose();
    _btnTextController.dispose();
    _btnUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingUpdate != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: 900,
            constraints: const BoxConstraints(maxHeight: 850),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1120).withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isCritical
                            ? const Color(0xFFEF4444).withOpacity(0.2)
                            : const Color(0xFF38BDF8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isCritical ? Icons.warning_amber_rounded : Icons.campaign_rounded,
                        color: _isCritical ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? "Edit Broadcast Notification" : "Create Broadcast Notification",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "This message will be dispatched in real-time to QubiQ client apps",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 24),

                // Main Form with Live Preview
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Column (Left)
                      Expanded(
                        flex: 6,
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // Title Input
                              _buildFormField(
                                label: "Notification Title *",
                                controller: _titleController,
                                hint: "e.g. Robot Firmware v2.4 Released or Critical Update",
                                validator: (v) => v == null || v.trim().isEmpty ? "Title is required" : null,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),

                              // Description / Content
                              _buildFormField(
                                label: "Description / Changelog / Instructions *",
                                controller: _descController,
                                hint: "Explain the update or why this critical action is required...",
                                maxLines: 4,
                                validator: (v) => v == null || v.trim().isEmpty ? "Description is required" : null,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),

                              // Target App Selector
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Target Application / Workspace *",
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedApp,
                                        isExpanded: true,
                                        dropdownColor: const Color(0xFF0F172A),
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                                        items: AppUpdateModel.supportedApps.map((a) {
                                          return DropdownMenuItem(
                                            value: a['id'],
                                            child: Text(
                                              a['name'] ?? '',
                                              style: const TextStyle(color: Colors.white, fontSize: 14),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedApp = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Critical Switch & Block App Switch
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isCritical
                                      ? const Color(0xFFEF4444).withOpacity(0.1)
                                      : const Color(0xFF1E293B).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _isCritical
                                        ? const Color(0xFFEF4444).withOpacity(0.3)
                                        : Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text(
                                        "Critical / Mandatory Alert",
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                      ),
                                      subtitle: const Text(
                                        "Shows an urgent warning modal immediately on login and whenever opening the target app.",
                                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                      ),
                                      value: _isCritical,
                                      activeColor: const Color(0xFFEF4444),
                                      onChanged: (val) => setState(() => _isCritical = val),
                                    ),
                                    if (_isCritical) ...[
                                      const Divider(color: Colors.white10),
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          "Block App Launch Until Acknowledged",
                                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: const Text(
                                          "Prevent user from using the workspace until they acknowledge the update message.",
                                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                        ),
                                        value: _blockAppLaunch,
                                        activeColor: const Color(0xFFF59E0B),
                                        onChanged: (val) => setState(() => _blockAppLaunch = val),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Version Tag & Action Button in Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFormField(
                                      label: "Version Tag (Optional)",
                                      controller: _versionController,
                                      hint: "e.g. v2.4.0",
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildFormField(
                                      label: "Action Button Text (Optional)",
                                      controller: _btnTextController,
                                      hint: "e.g. Update Robot / Read Guide",
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildFormField(
                                label: "Action URL / External Link (Optional)",
                                controller: _btnUrlController,
                                hint: "https://...",
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 18),

                              // Audience Roles
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Target Audience Roles",
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildCheckbox("Students", _forStudents, (v) => setState(() => _forStudents = v!)),
                                      const SizedBox(width: 14),
                                      _buildCheckbox("Teachers", _forTeachers, (v) => setState(() => _forTeachers = v!)),
                                      const SizedBox(width: 14),
                                      _buildCheckbox("Admins", _forAdmins, (v) => setState(() => _forAdmins = v!)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 28),

                      // Live Preview Column (Right)
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF030712).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "Live Client Preview",
                                    style: TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _isCritical ? "Critical Dialog" : "Notification Card",
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Center(
                                  child: _buildPreviewCard(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),

                // Dialog Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveBroadcast,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCritical ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isEditing ? "Save Changes" : "Publish Broadcast",
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E293B).withOpacity(0.7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF38BDF8),
            checkColor: Colors.black,
            onChanged: onChanged,
          ),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final title = _titleController.text.trim().isEmpty ? "Sample Update Title" : _titleController.text.trim();
    final desc = _descController.text.trim().isEmpty
        ? "This is how your update message will look in the QubiQ client application when users launch the app or dashboard."
        : _descController.text.trim();
    final appName = AppUpdateModel.supportedApps.firstWhere(
      (a) => a['id'] == _selectedApp,
      orElse: () => {'name': _selectedApp},
    )['name']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isCritical ? const Color(0xFF1F1215) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isCritical ? const Color(0xFFEF4444).withOpacity(0.6) : const Color(0xFF38BDF8).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isCritical ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)).withOpacity(0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCritical ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                color: _isCritical ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isCritical ? "⚠️ CRITICAL APP NOTICE" : "🎉 WHAT'S NEW",
                  style: TextStyle(
                    color: _isCritical ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  appName,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
          ),
          if (_btnTextController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCritical ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_btnTextController.text.trim()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    List<String> targetRoles = [];
    if (_forStudents && _forTeachers && _forAdmins) {
      targetRoles = ['all'];
    } else {
      if (_forStudents) targetRoles.add('student');
      if (_forTeachers) targetRoles.add('teacher');
      if (_forAdmins) targetRoles.add('admin');
    }

    if (targetRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one target audience role")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final appName = AppUpdateModel.supportedApps.firstWhere(
      (a) => a['id'] == _selectedApp,
      orElse: () => {'name': _selectedApp},
    )['name']!;

    final update = AppUpdateModel(
      id: widget.existingUpdate?.id ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      targetApp: _selectedApp,
      targetAppName: appName,
      isCritical: _isCritical,
      blockAppLaunch: _blockAppLaunch,
      versionTag: _versionController.text.trim().isEmpty ? null : _versionController.text.trim(),
      actionButtonText: _btnTextController.text.trim().isEmpty ? null : _btnTextController.text.trim(),
      actionUrl: _btnUrlController.text.trim().isEmpty ? null : _btnUrlController.text.trim(),
      targetRoles: targetRoles,
      isActive: _isActive,
      createdAt: widget.existingUpdate?.createdAt ?? DateTime.now(),
      createdBy: 'Super Admin',
    );

    final provider = context.read<AppUpdateProvider>();
    bool success;
    if (widget.existingUpdate != null) {
      success = await provider.updateNotification(update);
    } else {
      success = await provider.createUpdate(update);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingUpdate != null ? "Broadcast updated!" : "Broadcast published to all users!"),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to publish broadcast: ${provider.errorMessage}"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
