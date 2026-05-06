import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../Providers/Qubiq/QubiqProvider.dart';
import '../Support/support_ticket_list_page.dart';
import 'create_admin_dialog.dart';
import 'manage_keys_dialog.dart';
import 'school_detail_dialog.dart';
import 'search_school_dialog.dart';
import 'course_list_tab.dart';
import '../Ads/ads_page.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Model/Testing/feedback_model.dart';
import '../../Repository/Testing/testing_repository.dart';
import '../../Repository/Statistics/key_pool_repository.dart';

class QubiqPage extends StatefulWidget {
  const QubiqPage({super.key});

  @override
  State<QubiqPage> createState() => _QubiqPageState();
}

class _QubiqPageState extends State<QubiqPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QubiqProvider>().loadConfirmedSchools("");
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QubiqProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep Obsidian
      body: Stack(
        children: [
          // 1. Animated Mesh Gradient Blobs
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlob(
                300, const Color(0xFF1E40AF).withOpacity(0.2)), // Blue
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: _buildBlob(
                400, const Color(0xFF701A75).withOpacity(0.15)), // Purple
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.only(
                      left: 64, right: 24, top: 16, bottom: 16),
                  child: Row(
                    children: [
                      const Text(
                        "QUBIQ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      _buildTopButton(
                        icon: Icons.vpn_key_rounded,
                        label: "Key Pool Station ✨",
                        onPressed: _showKeyPoolStation,
                      ),
                      const SizedBox(width: 12),
                      _buildTopButton(
                        icon: Icons.support_agent,
                        label: "Support",
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SupportTicketListPage())),
                      ),
                    ],
                  ),
                ),

                // Fluid Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSchoolsTab(provider),
                      const CourseListTab(),
                      const AdsPage(),
                      const _TestingReportsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Glowing Obsidian Floating Dock
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.08), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDockItem(0, Icons.business_rounded, "Schools"),
                        const SizedBox(width: 4),
                        _buildDockItem(1, Icons.school_rounded, "Courses"),
                        const SizedBox(width: 4),
                        _buildDockItem(2, Icons.video_library_rounded, "Ads"),
                        const SizedBox(width: 4),
                        _buildDockItem(3, Icons.bug_report_rounded, "Reports"),
                      ],
                    ),
                  ),
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
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildTopButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.1),
            blurRadius: 10,
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: const Color(0xFF38BDF8),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: const Color(0xFF38BDF8).withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF38BDF8).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFF38BDF8)
                    : Colors.white.withOpacity(0.35),
                size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF38BDF8)
                    : Colors.white.withOpacity(0.35),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolsTab(QubiqProvider provider) {
    return provider.isLoading && provider.confirmedSchools.isEmpty
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
        : RefreshIndicator(
            onRefresh: () => provider.loadConfirmedSchools(""),
            backgroundColor: const Color(0xFF1E293B),
            color: const Color(0xFF38BDF8),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "Schools",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        provider.confirmedSchools.length.toString(),
                        style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (_) => const SearchSchoolDialog());
                      },
                      icon: const Icon(Icons.add_circle_outline,
                          color: Color(0xFF38BDF8)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.globalStats.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          "Confirmed Schools", 
                          provider.confirmedSchools.length, 
                          const Color(0xFFF43F5E), 
                          Icons.verified_rounded,
                        ),
                        _buildMetricCard(
                          "Total Users", 
                          provider.globalStats['users'] ?? 0, 
                          const Color(0xFF38BDF8), 
                          Icons.people_rounded,
                          subMetrics: {
                            "Teachers": provider.globalStats['teachers'] ?? 0,
                            "Students": provider.globalStats['students'] ?? 0,
                          }
                        ),
                        _buildMetricCard("Assignments", provider.globalStats['assignments'] ?? 0, Colors.orange.shade400, Icons.assignment_rounded),
                        _buildMetricCard("Projects", provider.globalStats['projects'] ?? 0, Colors.purple.shade400, Icons.code_rounded),
                        _buildMetricCard("Submissions", provider.globalStats['submissions'] ?? 0, Colors.green.shade400, Icons.check_circle_rounded),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (provider.globalStats.isNotEmpty)
                  _buildGlobalCharts(provider.globalStats),
                const SizedBox(height: 16),
                _buildMapCard(provider.confirmedSchools, provider.loginLocations),
                const SizedBox(height: 24),

                // 🔍 Search & Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: TextField(
                          onChanged: (v) => provider.setSearchQuery(v),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            icon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 20),
                            hintText: "Search schools...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All", provider),
                      _buildFilterChip("Active", provider),
                      _buildFilterChip("Pending", provider),
                      _buildFilterChip("None", provider),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                provider.filteredSchools.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: provider.filteredSchools.length,
                        itemBuilder: (context, index) {
                              final school = provider.filteredSchools[index];
                              final isPending =
                                  school.adminId == 'PENDING_SETUP';
                              final hasAdmin = school.adminId != null &&
                                  school.adminId!.isNotEmpty &&
                                  !isPending;

                              Color statusColor = Colors.red.shade400;
                              if (hasAdmin) statusColor = Colors.green.shade400;
                              if (isPending)
                                statusColor = Colors.orange.shade400;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 25,
                                      offset: const Offset(0, 12),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: InkWell(
                                      onTap: () => showDialog(context: context, builder: (_) => SchoolDetailDialog(school: school)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                // 🏫 SCHOOL AVATAR
                                                Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.05)],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: statusColor.withOpacity(0.2)),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      school.schoolProfile.name.isNotEmpty ? school.schoolProfile.name[0].toUpperCase() : "?",
                                                      style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.w900),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        school.schoolProfile.name,
                                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      Text(
                                                        "${school.schoolProfile.city}, ${school.schoolProfile.state}",
                                                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Icon(Icons.tag_rounded, size: 12, color: const Color(0xFF38BDF8).withOpacity(0.7)),
                                                          const SizedBox(width: 4),
                                                          Text("ID: ${school.id?.substring(school.id!.length - 4).toUpperCase() ?? '0000'}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
                                                          const SizedBox(width: 12),
                                                          Icon(Icons.vpn_key_rounded, size: 12, color: Colors.orangeAccent.withOpacity(0.7)),
                                                          const SizedBox(width: 4),
                                                          Text("PIN: ${school.schoolCode ?? 'N/A'}", style: TextStyle(color: Colors.orangeAccent.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
                                                          const SizedBox(width: 12),
                                                          Icon(Icons.person_outline_rounded, size: 12, color: Colors.white.withOpacity(0.4)),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              school.adminName ?? 'No Admin',
                                                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                _StatusBadgeMini(hasAdmin: hasAdmin, isPending: isPending, color: statusColor),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            const Divider(color: Colors.white10, height: 1),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                _buildMiniStat(Icons.people_alt_rounded, provider.schoolStats[school.schoolCode]?['users'] ?? 0, "Users"),
                                                _buildMiniStat(Icons.assignment_turned_in_rounded, provider.schoolStats[school.schoolCode]?['assignments'] ?? 0, "Tasks"),
                                                _buildMiniStat(Icons.rocket_launch_rounded, provider.schoolStats[school.schoolCode]?['projects'] ?? 0, "Proj"),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isPending) ...[
                                                      _buildSmallButton(
                                                        "Verify", 
                                                        Colors.orange.shade400, 
                                                        () => _showManualCompleteDialog(context, school)
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    _buildSmallButton(
                                                      hasAdmin ? "Manage" : (isPending ? "Keys/Resend" : "Setup"), 
                                                      const Color(0xFF38BDF8), 
                                                      () => showDialog(context: context, builder: (_) => hasAdmin ? ManageKeysDialog(school: school) : CreateAdminDialog(school: school))
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                      ),
              ],
            ),
          ),
        );
  }

  Widget _buildSmallButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  void _showRemoveAdminDialog(BuildContext context, SchoolVisit school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Admin?"),
        content: Text(
            "Are you sure you want to remove the admin for ${school.schoolProfile.name}? This will reset the configuration."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<QubiqProvider>().removeAdminForSchool(school);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  void _showManualCompleteDialog(BuildContext context, SchoolVisit school) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manual Complete"),
        content: Text(
            "Mark ${school.schoolProfile.name} as setup complete? This bypasses the automated link verification."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<QubiqProvider>()
                  .manualMarkAsAdminCreated(school, null);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("School marked as Admin Created!")),
                );
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, int value, Color color, IconData icon, {Map<String, int>? subMetrics}) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (subMetrics != null)
                Row(
                  children: subMetrics.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(e.value.toString(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(e.key[0], style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8)),
                      ],
                    ),
                  )).toList(),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, QubiqProvider provider) {
    final isSelected = provider.statusFilter == label;
    return GestureDetector(
      onTap: () => provider.setStatusFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, int value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF38BDF8).withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined,
              size: 50, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            "No confirmed schools found",
            style:
                TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalCharts(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildChartCard(
            "User Composition",
            PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 20,
                sections: [
                  PieChartSectionData(
                    value: (stats['students'] ?? 0).toDouble(),
                    title: 'Students',
                    color: const Color(0xFF38BDF8),
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: (stats['teachers'] ?? 0).toDouble(),
                    title: 'Teachers',
                    color: Colors.orange.shade400,
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildChartCard(
            "Login Origins",
            PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 20,
                sections: [
                  PieChartSectionData(
                    value: (stats['schoolLogins'] ?? 0).toDouble() == 0 && (stats['homeLogins'] ?? 0).toDouble() == 0 ? 1 : (stats['schoolLogins'] ?? 0).toDouble(),
                    title: 'School',
                    color: Colors.purple.shade400,
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: (stats['homeLogins'] ?? 0).toDouble(),
                    title: 'Home',
                    color: Colors.pink.shade400,
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: _buildChartCard(
            "Activity Overview",
            BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Tasks', 'Proj', 'Subs'];
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Text(labels[value.toInt()], style: const TextStyle(color: Colors.white24, fontSize: 10));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: (stats['assignments'] ?? 0).toDouble(), color: Colors.orange.shade400, width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: (stats['projects'] ?? 0).toDouble(), color: Colors.purple.shade400, width: 16, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: (stats['submissions'] ?? 0).toDouble(), color: Colors.green.shade400, width: 16, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildMapCard(List<SchoolVisit> schools, List<Map<String, dynamic>> loginLocations) {
    int teacherCount = 0;
    int studentSchoolCount = 0;
    int studentHomeCount = 0;

    for (var login in loginLocations) {
      final String userRole = (login['userRole'] ?? 'student').toString().toLowerCase();
      final String loginType = login['loginType'] ?? 'unknown';
      if (userRole == 'teacher' || userRole == 'admin') teacherCount++;
      else if (loginType == 'school') studentSchoolCount++;
      else studentHomeCount++;
    }

    return GestureDetector(
      onTap: () => _showFullMap(schools, loginLocations),
      child: Container(
        height: 280, // Made it more compact
        width: 420,  // Fixed width to make it a "Small Widget"
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Stack(
          children: [
            // 1. The Map Preview (Locked & Focused on India)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: IgnorePointer(
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(22.0, 78.9629),
                    initialZoom: 3.8,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    MarkerLayer(markers: _buildMarkers(schools, loginLocations, isFullView: false)),
                  ],
                ),
              ),
            ),

            // 2. Click to Zoom Label
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text("EXPAND MAP", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),

            // 3. Floating Counts Overlay
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapStatBadge("👨‍🏫", "$teacherCount", "T"),
                    const SizedBox(width: 4),
                    _buildMapStatBadge("🏫", "$studentSchoolCount", "S"),
                    const SizedBox(width: 4),
                    _buildMapStatBadge("🏠", "$studentHomeCount", "H"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(List<SchoolVisit> schools, List<Map<String, dynamic>> loginLocations, {required bool isFullView}) {
    List<Marker> markers = [];
    
    // Schools (Red Location Pins)
    for (var school in schools) {
      final coord = _getCoord(school.schoolProfile.city, school.schoolProfile.state);
      if (coord != null) {
        markers.add(
          Marker(
            point: coord,
            width: isFullView ? 40 : 24,
            height: isFullView ? 40 : 24,
            child: Icon(Icons.location_on_rounded, color: const Color(0xFFF43F5E), size: isFullView ? 30 : 16),
          ),
        );
      }
    }

    // User Logins (Emoji Markers)
    for (var login in loginLocations) {
      final double lat = (login['lat'] ?? 0.0).toDouble();
      final double lng = (login['lng'] ?? 0.0).toDouble();
      if (lat < 6 || lat > 38 || lng < 68 || lng > 98) continue;

      final String userRole = (login['userRole'] ?? 'student').toString().toLowerCase();
      final bool isTeacher = userRole == 'teacher' || userRole == 'admin';
      final bool isSchool = login['loginType'] == 'school';
      final bool isActive = login['sessionActive'] == true;

      final String emoji = isTeacher ? '👨‍🏫' : (isSchool ? '🏫' : '🏠');
      
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: isFullView ? 40 : 22,
          height: isFullView ? 40 : 22,
          child: Tooltip(
            message: '${login['userName']} (${isTeacher ? 'Teacher' : 'Student'})\n${isSchool ? '🏫 School' : '🏠 Home'}',
            child: Container(
              alignment: Alignment.center,
              decoration: isActive ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: (isTeacher ? Colors.cyan : (isSchool ? Colors.purple : Colors.pink)).withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                ],
              ) : null,
              child: Text(
                emoji,
                style: TextStyle(fontSize: isFullView ? 28 : 14),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  void _showFullMap(List<SchoolVisit> schools, List<Map<String, dynamic>> loginLocations) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("India Login Map", style: TextStyle(color: Colors.white)),
            leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(21.5, 78.9629),
              initialZoom: 5.0,
              minZoom: 4.5,
              maxZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(markers: _buildMarkers(schools, loginLocations, isFullView: true)),
            ],
          ),
        ),
      ),
    );
  }

  LatLng? _getCoord(String? city, String? state) {
    final Map<String, LatLng> cityCoords = {
      'Jaipur': const LatLng(26.9124, 75.7873), 'Delhi': const LatLng(28.6139, 77.2090),
      'Mumbai': const LatLng(19.0760, 72.8777), 'Bangalore': const LatLng(12.9716, 77.5946),
      'Kochi': const LatLng(9.9312, 76.2673), 'Chennai': const LatLng(13.0827, 80.2707),
      'Kolkata': const LatLng(22.5726, 88.3639), 'Hyderabad': const LatLng(17.3850, 78.4867),
      'Pune': const LatLng(18.5204, 73.8567), 'Ahmedabad': const LatLng(23.0225, 72.5714),
      'Lucknow': const LatLng(26.8467, 80.9462), 'Bhopal': const LatLng(23.2599, 77.4126),
      'Chandigarh': const LatLng(30.7333, 76.7794), 'Patna': const LatLng(25.6093, 85.1376),
      'Guwahati': const LatLng(26.1445, 91.7362), 'Bhubaneswar': const LatLng(20.2961, 85.8245),
      'Ranchi': const LatLng(23.3441, 85.3096), 'Raipur': const LatLng(21.2514, 81.6296),
      'Dehradun': const LatLng(30.3165, 78.0322), 'Visakhapatnam': const LatLng(17.6868, 83.2185),
    };
    return cityCoords[city] ?? cityCoords[state];
  }

  Widget _buildMapLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
      ],
    );
  }

  Widget _buildMapStatBadge(String emoji, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ],
      ),
    );
  }

  void _showKeyPoolStation() {
    showDialog(
      context: context,
      builder: (context) => const _KeyPoolStationDialog(),
    );
  }
}

class _StatusBadgeMini extends StatelessWidget {
  final bool hasAdmin;
  final bool isPending;
  final Color color;

  const _StatusBadgeMini({required this.hasAdmin, required this.isPending, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(
        hasAdmin ? Icons.verified_rounded : isPending ? Icons.timer_rounded : Icons.warning_amber_rounded,
        size: 16,
        color: color,
      ),
    );
  }
}

class _TestingReportsSection extends StatefulWidget {
  const _TestingReportsSection();

  @override
  State<_TestingReportsSection> createState() => _TestingReportsSectionState();
}

class _TestingReportsSectionState extends State<_TestingReportsSection> {
  final TestingRepository _repository = TestingRepository();
  bool _isLoading = true;
  List<TestingFeedback> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _repository.getAllFeedback();
    if (!mounted) return;
    setState(() {
      _feedbackList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }
    if (_feedbackList.isEmpty) {
      return Center(
          child: Text("No testing feedback found.",
              style: TextStyle(color: Colors.white.withOpacity(0.3))));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: _feedbackList.length,
      itemBuilder: (context, index) {
        final fb = _feedbackList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    const Color(0xFF38BDF8).withOpacity(0.2)),
                          ),
                          child: Text(
                            fb.section.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Color(0xFF38BDF8),
                                letterSpacing: 0.5),
                          ),
                        ),
                        Text(
                          "${fb.createdAt.day}/${fb.createdAt.month}/${fb.createdAt.year}",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              const Color(0xFF38BDF8).withOpacity(0.1),
                          child: const Icon(Icons.person,
                              size: 12, color: Color(0xFF38BDF8)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          fb.createdByName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Colors.white10),
                    ),
                    if (fb.errorText.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 6),
                          Text("ERROR REPORT",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade400,
                                  fontSize: 10,
                                  letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(fb.errorText,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                              fontSize: 14)),
                      const SizedBox(height: 16),
                    ],
                    if (fb.updateText.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 14, color: Colors.green.shade400),
                          const SizedBox(width: 6),
                          Text("SUGGESTED UPDATE",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade400,
                                  fontSize: 10,
                                  letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(fb.updateText,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                              fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KeyPoolStationDialog extends StatefulWidget {
  const _KeyPoolStationDialog();

  @override
  State<_KeyPoolStationDialog> createState() => _KeyPoolStationDialogState();
}

class _KeyPoolStationDialogState extends State<_KeyPoolStationDialog> {
  final _keyCtrl = TextEditingController();
  final _awsAccessCtrl = TextEditingController();
  final _awsSecretCtrl = TextEditingController();
  final _awsRegionCtrl = TextEditingController();
  String _selectedProvider = 'openrouter';
  bool _isImporting = false;
  bool _isSavingAws = false;

  @override
  void initState() {
    super.initState();
    _loadAwsConfig();
  }

  void _loadAwsConfig() async {
    final config = await KeyPoolRepository.getAwsConfig().first;
    _awsAccessCtrl.text = config['accessKey'] ?? '';
    _awsSecretCtrl.text = config['secretKey'] ?? '';
    _awsRegionCtrl.text = config['region'] ?? 'ap-south-1';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.vpn_key_rounded, color: Colors.purpleAccent),
          SizedBox(width: 12),
          Text("Key Pool Station", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView( // 👈 Added scrolling to fix overflow
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Map<String, int>>(
                stream: KeyPoolRepository.getPoolStats(),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {'openrouter': 0, 'gemini': 0, 'grok': 0};
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("OR", stats['openrouter'] ?? 0, Colors.purpleAccent),
                        _buildStat("GEM", stats['gemini'] ?? 0, Colors.blueAccent),
                        _buildStat("GROK", stats['grok'] ?? 0, Colors.orangeAccent),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text("Add to Pool:", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProvider,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: ['openrouter', 'gemini', 'grok']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedProvider = v!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keyCtrl,
                maxLines: 4, // Reduced maxLines slightly for space
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Paste keys here (one per line)...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white38, size: 14),
                  SizedBox(width: 8),
                  Text("Paste all keys at once, then hit Import.", style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
              const Divider(color: Colors.white10, height: 40),
              const Row(
                children: [
                  Icon(Icons.cloud_queue_rounded, color: Colors.blueAccent, size: 18),
                  SizedBox(width: 12),
                  Text("AWS S3 Setup", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              _awsField("Access Key", _awsAccessCtrl),
              _awsField("Secret Key", _awsSecretCtrl, obscure: true),
              Row(
                children: [
                  Expanded(child: _awsField("Region", _awsRegionCtrl)),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ElevatedButton(
                      onPressed: _isSavingAws ? null : _saveAws,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSavingAws ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Save AWS", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Colors.white60)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isImporting ? null : _import,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isImporting 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Text("Import Keys", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _awsField(String label, TextEditingController ctrl, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  void _saveAws() async {
    setState(() => _isSavingAws = true);
    try {
      await KeyPoolRepository.saveAwsConfig({
        'accessKey': _awsAccessCtrl.text.trim(),
        'secretKey': _awsSecretCtrl.text.trim(),
        'region': _awsRegionCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ AWS Config Saved")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAws = false);
    }
  }

  Widget _buildStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
      ],
    );
  }

  void _import() async {
    if (_keyCtrl.text.trim().isEmpty) return;
    setState(() => _isImporting = true);
    try {
      final keys = _keyCtrl.text.split('\n').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
      await KeyPoolRepository.importKeys(_selectedProvider, keys);
      _keyCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Imported ${keys.length} keys into $_selectedProvider pool"),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}

