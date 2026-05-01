import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            child: _buildBlob(300, const Color(0xFF1E40AF).withOpacity(0.2)), // Blue
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: _buildBlob(400, const Color(0xFF701A75).withOpacity(0.15)), // Purple
          ),
          
          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.only(left: 64, right: 24, top: 16, bottom: 16),
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
                        icon: Icons.support_agent,
                        label: "Support",
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportTicketListPage())),
                      ),
                    ],
                  ),
                ),

                // Fluid Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
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

  Widget _buildTopButton({required IconData icon, required String label, required VoidCallback onPressed}) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: const Color(0xFF38BDF8).withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.35), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.35),
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
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
        : Padding(
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        provider.confirmedSchools.length.toString(),
                        style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        showDialog(context: context, builder: (_) => const SearchSchoolDialog());
                      },
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF38BDF8)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadConfirmedSchools(""),
                    backgroundColor: const Color(0xFF1E293B),
                    color: const Color(0xFF38BDF8),
                    child: provider.confirmedSchools.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            physics: const BouncingScrollPhysics(),
                            itemCount: provider.confirmedSchools.length,
                            itemBuilder: (context, index) {
                              final school = provider.confirmedSchools[index];
                              final isPending = school.adminId == 'PENDING_SETUP';
                              final hasAdmin = school.adminId != null && school.adminId!.isNotEmpty && !isPending;

                              Color statusColor = Colors.red.shade400;
                              if (hasAdmin) statusColor = Colors.green.shade400;
                              if (isPending) statusColor = Colors.orange.shade400;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: InkWell(
                                      onTap: () {
                                        showDialog(context: context, builder: (_) => SchoolDetailDialog(school: school));
                                      },
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Status Accent Bar
                                            Container(width: 6, color: statusColor),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(24.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            school.schoolProfile.name,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 0.2,
                                                            ),
                                                          ),
                                                        ),
                                                        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.5)),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          "${school.schoolProfile.city}, ${school.schoolProfile.state}",
                                                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                                                        ),
                                                      ],
                                                    ),
                                                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10)),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: statusColor.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: statusColor.withOpacity(0.2)),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                hasAdmin ? Icons.verified : isPending ? Icons.timer : Icons.warning_amber_rounded,
                                                                size: 14,
                                                                color: statusColor,
                                                               ),
                                                              const SizedBox(width: 6),
                                                              Text(
                                                                hasAdmin ? "Active" : isPending ? "Setup Pending" : "No Admin",
                                                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        if (hasAdmin)
                                                          _buildSmallButton(
                                                            "Manage Keys",
                                                            const Color(0xFF38BDF8),
                                                            () => showDialog(context: context, builder: (_) => ManageKeysDialog(school: school)),
                                                          )
                                                        else
                                                          _buildSmallButton(
                                                            isPending ? "Resend Link" : "Setup Admin",
                                                            isPending ? Colors.orange.shade400 : const Color(0xFF38BDF8),
                                                            () => showDialog(context: context, builder: (_) => CreateAdminDialog(school: school)),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                  ),
                ),
              ],
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
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 50, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            "No confirmed schools found",
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.3)),
          ),
        ],
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
    }
    if (_feedbackList.isEmpty) {
      return Center(child: Text("No testing feedback found.", style: TextStyle(color: Colors.white.withOpacity(0.3))));
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
                          ),
                          child: Text(
                            fb.section.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF38BDF8), letterSpacing: 0.5),
                          ),
                        ),
                        Text(
                          "${fb.createdAt.day}/${fb.createdAt.month}/${fb.createdAt.year}",
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF38BDF8).withOpacity(0.1),
                          child: const Icon(Icons.person, size: 12, color: Color(0xFF38BDF8)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          fb.createdByName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
                          Icon(Icons.error_outline, size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 6),
                          Text("ERROR REPORT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade400, fontSize: 10, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(fb.errorText, style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5, fontSize: 14)),
                      const SizedBox(height: 16),
                    ],
                    if (fb.updateText.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 14, color: Colors.green.shade400),
                          const SizedBox(width: 6),
                          Text("SUGGESTED UPDATE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade400, fontSize: 10, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(fb.updateText, style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5, fontSize: 14)),
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

