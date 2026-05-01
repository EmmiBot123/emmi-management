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

class QubiqPage extends StatefulWidget {
  const QubiqPage({super.key});

  @override
  State<QubiqPage> createState() => _QubiqPageState();
}

class _QubiqPageState extends State<QubiqPage> with SingleTickerProviderStateMixin {
  int _tabIndex = 0; // 0 = Schools, 1 = Courses, 2 = Ads
  late AnimationController _heroController;
  late Animation<double> _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroAnim = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );
    _heroController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QubiqProvider>().loadConfirmedSchools("");
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _tabIndex) return;
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final width = MediaQuery.of(context).size.width;
    final provider = context.watch<QubiqProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // ═══════════ HERO HEADER ═══════════
          FadeTransition(
            opacity: _heroAnim,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: topPad + 52,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Decorative tech lines/circles
                  Positioned(
                    right: -20,
                    top: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.05), width: 20),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF38BDF8).withOpacity(0.1),
                            width: 2),
                      ),
                    ),
                  ),

                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFF38BDF8)
                                      .withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.api,
                                color: Color(0xFF38BDF8), size: 22),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Qubiq Core",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "Infrastructure & Content",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Support Tickets Quick Action ──
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportTicketListPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.support_agent,
                                  color: Color(0xFF38BDF8), size: 18),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Manage Support Tickets",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 14),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Segmented Toggle ──
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            _buildSegment("Schools", Icons.business, 0, width),
                            _buildSegment("Courses", Icons.school, 1, width),
                            _buildSegment("Ads", Icons.video_library, 2, width),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ═══════════ CONTENT ═══════════
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_tabIndex),
                child: _getContent(provider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
      String label, IconData icon, int index, double screenWidth) {
    final isActive = _tabIndex == index;
    final isSmall = screenWidth < 400;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isSmall ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF38BDF8) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getContent(QubiqProvider provider) {
    if (_tabIndex == 0) {
      return _buildSchoolsTab(provider);
    } else if (_tabIndex == 1) {
      return const CourseListTab();
    } else {
      return const AdsPage();
    }
  }

  Widget _buildSchoolsTab(QubiqProvider provider) {
    return provider.isLoading && provider.confirmedSchools.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Confirmed Schools (${provider.confirmedSchools.length})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const SearchSchoolDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Manual Config"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadConfirmedSchools(""),
                    child: provider.confirmedSchools.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: provider.confirmedSchools.length,
                            itemBuilder: (context, index) {
                              final school = provider.confirmedSchools[index];
                              final isPending = school.adminId == 'PENDING_SETUP';
                              final hasAdmin = school.adminId != null &&
                                  school.adminId!.isNotEmpty &&
                                  !isPending;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                      color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          SchoolDetailDialog(school: school),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: hasAdmin
                                                    ? Colors.green.withOpacity(0.1)
                                                    : isPending
                                                        ? Colors.orange.withOpacity(0.1)
                                                        : Colors.red.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                hasAdmin
                                                    ? Icons.check_circle_outline
                                                    : isPending
                                                        ? Icons.schedule
                                                        : Icons.error_outline,
                                                color: hasAdmin
                                                    ? Colors.green
                                                    : isPending
                                                        ? Colors.orange
                                                        : Colors.red,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    school.schoolProfile.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (school.schoolProfile.city
                                                          .isNotEmpty &&
                                                      school.schoolProfile.state
                                                          .isNotEmpty &&
                                                      school.schoolProfile.city !=
                                                          "Unknown" &&
                                                      school.schoolProfile.state !=
                                                          "Unknown")
                                                    Text(
                                                      "${school.schoolProfile.city}, ${school.schoolProfile.state}",
                                                      style: TextStyle(
                                                        color: Colors.grey
                                                            .shade600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: hasAdmin
                                                    ? Text(
                                                        "Admin: ${school.adminName ?? 'Unknown'}",
                                                        style: const TextStyle(
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13),
                                                      )
                                                    : isPending
                                                        ? Text(
                                                            "Setup Link Sent to: ${school.adminName}",
                                                            style: TextStyle(
                                                                color: Colors.orange.shade800,
                                                                fontWeight:
                                                                    FontWeight.w500,
                                                                fontSize: 13),
                                                          )
                                                        : const Text(
                                                            "No Admin Account",
                                                            style: TextStyle(
                                                                color: Colors.red,
                                                                fontWeight:
                                                                    FontWeight.w500,
                                                                fontSize: 13),
                                                          ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (hasAdmin) ...[
                                              TextButton.icon(
                                                onPressed: () => _showRemoveAdminDialog(context, school),
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18),
                                                label: const Text("Remove"),
                                                style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        ManageKeysDialog(
                                                            school: school),
                                                  );
                                                },
                                                icon: const Icon(Icons.key,
                                                    size: 16),
                                                label: const Text("Manage Keys"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF38BDF8),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                              ),
                                            ] else ...[
                                              if (isPending)
                                                TextButton(
                                                  onPressed: () => _showManualCompleteDialog(context, school),
                                                  child: const Text(
                                                      "Manual Complete",
                                                      style: TextStyle(
                                                          fontSize: 13)),
                                                ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        CreateAdminDialog(
                                                            school: school),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isPending
                                                      ? Colors.orange.shade600
                                                      : const Color(0xFF0F172A),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                                child: Text(isPending
                                                    ? "Update/Resend"
                                                    : "Create Admin"),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
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
          Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No confirmed schools found",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
