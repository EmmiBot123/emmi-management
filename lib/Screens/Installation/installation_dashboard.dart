import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/AuthProvider.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Resources/theme_constants.dart';
import '../Assembly/sections/shipping_page.dart';
import 'installation_page.dart';
import 'add_installation_visit_page.dart';

class InstallationDashboard extends StatefulWidget {
  const InstallationDashboard({super.key});

  @override
  State<InstallationDashboard> createState() => _InstallationDashboardState();
}
class _InstallationDashboardState extends State<InstallationDashboard> {
  String _searchQuery = "";
  String _selectedTab = "ACTIVE"; // ACTIVE, COMPLETED, ALL

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<SchoolVisitProvider>().loadInstallationVisits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolVisitProvider>();
    final auth = context.watch<AuthProvider>();
    final isWeb = MediaQuery.of(context).size.width > 900;

    // Filtering logic
    final filteredVisits = provider.installationVisits.where((v) {
      final matchesSearch = v.schoolProfile.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.schoolProfile.city.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final isInstalled = v.shippingDetails.isInstalled == true;
      bool matchesTab = true;
      if (_selectedTab == "ACTIVE") matchesTab = !isInstalled;
      else if (_selectedTab == "COMPLETED") matchesTab = isInstalled;

      return matchesSearch && matchesTab;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Stack(
              children: [
                // ── Deep Background Glows ──
                Positioned(top: -150, right: -100, child: _buildGlowBlob(AppColors.accent.withValues(alpha: 0.1), 400)),
                Positioned(bottom: -100, left: -100, child: _buildGlowBlob(Colors.blueAccent.withValues(alpha: 0.08), 350)),
                Positioned(top: 400, left: -50, child: _buildGlowBlob(Colors.purpleAccent.withValues(alpha: 0.05), 200)),

                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      expandedHeight: 180,
                      collapsedHeight: 80,
                      floating: true,
                      pinned: true,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                          child: _buildGreeting(auth, isWeb),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsGrid(provider, isWeb),
                            const SizedBox(height: 40),
                            _buildFloatingSearchBar(),
                            const SizedBox(height: 24),
                            _buildTabSelector(),
                          ],
                        ),
                      ),
                    ),

                    _buildMissionsList(filteredVisits, isWeb),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),

                // ── Quick Add Floating Action ──
                Positioned(
                  bottom: 32,
                  right: 24,
                  child: _buildFab(context, auth),
                ),
              ],
            ),
    );
  }

  Widget _buildGlowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }

  Widget _buildGreeting(AuthProvider auth, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            Text(
              "MISSION COMMAND",
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: [Shadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 10)],
              ),
            ),
            const SizedBox(width: 12),
            _buildPulseIndicator(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Field Operations",
          style: TextStyle(
            color: Colors.white,
            fontSize: isWeb ? 32 : 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text("LIVE", style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFloatingSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: "Search missions by school or city...",
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          icon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: [
        _buildTabItem("ACTIVE", Icons.rocket_launch_outlined),
        const SizedBox(width: 12),
        _buildTabItem("COMPLETED", Icons.verified_user_outlined),
        const SizedBox(width: 12),
        _buildTabItem("ALL", Icons.grid_view_rounded),
      ],
    );
  }

  Widget _buildTabItem(String label, IconData icon) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(SchoolVisitProvider provider, bool isWeb) {
    final total = provider.installationVisits.length;
    final completed = provider.installationVisits.where((v) => v.shippingDetails.isInstalled == true).length;
    final pending = total - completed;

    return Row(
      children: [
        _buildStatCard("Active", pending.toString(), AppColors.accent),
        const SizedBox(width: 12),
        _buildStatCard("Success", completed.toString(), Colors.greenAccent),
        const SizedBox(width: 12),
        _buildStatCard("Inbound", total.toString(), Colors.blueAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionsList(List<dynamic> visits, bool isWeb) {
    if (visits.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? "No missions in this category" : "No results for '$_searchQuery'",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMissionCard(visits[index], isWeb),
          ),
          childCount: visits.length,
        ),
      ),
    );
  }

  Widget _buildMissionCard(dynamic visit, bool isWeb) {
    final isInstalled = visit.shippingDetails.isInstalled == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5), // Enhanced border visibility
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstallationVisitDetailsPage(visit: visit))),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildMissionIdBadge("SID: ${visit.id?.substring(visit.id!.length - 4).toUpperCase() ?? '0000'}"),
                          const SizedBox(width: 8),
                          if (visit.schoolCode != null)
                            _buildPinBadge(visit.schoolCode!),
                        ],
                      ),
                      _buildStatusBadge(isInstalled),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    visit.schoolProfile.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${visit.schoolProfile.city}, ${visit.schoolProfile.state}",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  _buildHardwareStatusSection(visit),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildAgentAvatar(visit.assignedUserName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("DEPLOYMENT PROGRESS", style: TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            const SizedBox(height: 6),
                            _buildProgressBar(isInstalled ? 1.0 : 0.4, isInstalled ? Colors.greenAccent : AppColors.accent),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildIconButton(
                        Icons.report_problem_outlined,
                        Colors.redAccent,
                        () => _showReportDefectDialog(visit),
                      ),
                      const SizedBox(width: 12),
                      _buildIconButton(
                        Icons.settings_suggest_outlined,
                        AppColors.accent,
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstallationVisitDetailsPage(visit: visit))),
                      ),
                      if (!isInstalled) ...[
                        const SizedBox(width: 12),
                        _buildCompleteAction(context, visit, isWeb),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareStatusSection(SchoolVisit visit) {
    if (visit.serviceOrders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_circle_outlined, color: Colors.redAccent, size: 12),
              const SizedBox(width: 8),
              Text(
                "HARDWARE STATUS (${visit.serviceOrders.length})",
                style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...visit.serviceOrders.map((order) {
            Color statusColor;
            switch (order.status) {
              case "Order Placed": statusColor = Colors.blue; break;
              case "Confirmed": statusColor = Colors.orange; break;
              case "Shipped": statusColor = Colors.purple; break;
              case "Resolved": statusColor = Colors.green; break;
              default: statusColor = Colors.grey;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${order.item}: ${order.description}",
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showReportDefectDialog(SchoolVisit visit) {
    String selectedItem = "BOT";
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Theme(
          data: ThemeData.dark().copyWith(
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            colorScheme: const ColorScheme.dark(primary: AppColors.accent),
          ),
          child: AlertDialog(
            title: const Text("Report Hardware Defect", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedItem,
                  dropdownColor: AppColors.surface,
                  items: ["BOT", "MOBILE", "CHARGER", "TABLET", "OTHER"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedItem = v!),
                  decoration: const InputDecoration(labelText: "Item Category"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Defect Description",
                    hintText: "What exactly is broken?",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL", style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (descCtrl.text.trim().isEmpty) return;
                  
                  final order = ServiceOrder(
                    item: selectedItem,
                    description: descCtrl.text,
                    createdAt: DateTime.now(),
                  );
                  
                  setState(() => visit.serviceOrders.add(order));
                  final provider = context.read<SchoolVisitProvider>();
                  await provider.updateVisit(visit);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Hardware Replacement Ordered")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("PLACE ORDER", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionIdBadge(String id) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        "#$id",
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Monospace'),
      ),
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Stack(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3)),
        ),
        Container(
          height: 6,
          width: 200 * progress, // Simplified for UI
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentAvatar(String? name) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.surfaceLight,
        child: Text(
          name?[0].toUpperCase() ?? '?',
          style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPinBadge(String pin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.key_rounded, color: Colors.orangeAccent, size: 10),
          const SizedBox(width: 6),
          Text(
            "PIN: $pin",
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isCompleted) {
    final color = isCompleted ? Colors.greenAccent : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            isCompleted ? "COMPLETED" : "IN PROGRESS",
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCompleteAction(BuildContext context, dynamic visit, bool isWeb) {
    return InkWell(
      onTap: () async {
        final success = await context.read<SchoolVisitProvider>().markAsInstalled(visit);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Mission ${visit.schoolProfile.name} marked as Installed!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
            if (isWeb) ...[
              const SizedBox(width: 8),
              const Text(
                "MARK AS INSTALLED",
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF6E6AFF)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddInstallationVisitPage(
                userId: auth.userId!,
                userName: auth.name!,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  "NEW MISSION",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
