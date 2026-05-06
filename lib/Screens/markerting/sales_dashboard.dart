import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/AuthProvider.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Resources/theme_constants.dart';
import 'SchoolVisit/school_visit_list_page.dart';
import 'SchoolVisit/add_visit_page.dart';
import 'Bills/my_bills_page.dart';

class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});

  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.userId != null) {
      context.read<SchoolVisitProvider>().loadVisits(auth.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<SchoolVisitProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(auth),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(provider),
                  const SizedBox(height: 24),
                  _buildBentoGrid(context, auth),
                  const SizedBox(height: 32),
                  _buildSectionHeader("RECENT MISSIONS", Icons.history),
                  const SizedBox(height: 16),
                  _buildRecentMissions(provider, auth),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 70,
      pinned: true,
      backgroundColor: AppColors.bg,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent.withOpacity(0.2), AppColors.bg],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sales HQ",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Welcome back, ${auth.name?.split(' ')[0] ?? 'Agent'}",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: const Icon(Icons.notifications_none, color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(SchoolVisitProvider provider) {
    final total = provider.visits.length;
    final approved = provider.visits.where((v) => v.visitDetails.status == "APPROVED").length;
    final pending = provider.visits.where((v) => v.visitDetails.status == "PENDING").length;

    return Row(
      children: [
        _buildStatCard("Total Visits", total.toString(), Icons.location_on_outlined, AppColors.accent),
        const SizedBox(width: 12),
        _buildStatCard("Approved", approved.toString(), Icons.verified_outlined, Colors.greenAccent),
        const SizedBox(width: 12),
        _buildStatCard("Pending", pending.toString(), Icons.history_toggle_off, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildBentoBox(
                "New Visit",
                "Log a school mission",
                Icons.add_location_alt_outlined,
                AppColors.accent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddVisitPage(userId: auth.userId!, name: auth.name!, role: auth.role!))),
                height: 160,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildBentoBox(
                "Nearby",
                "Find schools",
                Icons.near_me_outlined,
                Colors.blueAccent,
                () => _showMissionsPage(context, auth),
                height: 160,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBentoBox(
                "Expenses",
                "Manage bills",
                Icons.receipt_long_outlined,
                Colors.orangeAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyBillsPage(userId: auth.userId!, userName: auth.name!))),
                height: 120,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoBox(
                "Archive",
                "History",
                Icons.inventory_2_outlined,
                Colors.tealAccent,
                () => _showMissionsPage(context, auth),
                height: 120,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoBox(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {double height = 120}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 14),
      ],
    );
  }

  Widget _buildRecentMissions(SchoolVisitProvider provider, AuthProvider auth) {
    final visits = provider.visits.take(5).toList();

    if (visits.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceLight, style: BorderStyle.none),
        ),
        child: Column(
          children: [
            Icon(Icons.map_outlined, color: AppColors.textMuted.withOpacity(0.5), size: 48),
            const SizedBox(height: 16),
            const Text("No recent missions found", style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return Column(
      children: visits.map((visit) => _buildVisitCard(visit, auth)).toList(),
    );
  }

  Widget _buildVisitCard(dynamic visit, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.school_outlined, color: AppColors.accent, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.schoolProfile.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${visit.schoolProfile.city}, ${visit.schoolProfile.state}",
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(visit.visitDetails.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.accent;
    if (status == "APPROVED") color = Colors.greenAccent;
    if (status == "PENDING") color = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showMissionsPage(BuildContext context, AuthProvider auth) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchoolVisitListPage(
          userId: auth.userId!,
          name: auth.name!,
          role: auth.role!,
        ),
      ),
    );
  }
}
