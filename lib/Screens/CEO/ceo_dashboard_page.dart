import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../Model/User_model.dart';
import '../../Providers/AuthProvider.dart';
import '../../Providers/CourseProvider.dart';
import '../../Providers/ProjectProvider.dart';
import '../../Providers/Ads/AdsProvider.dart';
import '../../Providers/TaskProvider.dart';
import '../../Model/Task_model.dart';
import 'assign_task_dialog.dart';
import '../../Repository/school_visit_repository.dart';
import '../../Repository/Support/support_repository.dart';
import '../../Repository/Testing/testing_repository.dart';
import '../../Repository/Statistics/statistics_repository.dart';
import '../../Model/Support/support_ticket_model.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../Support/support_ticket_list_page.dart';

// ─── Color Palette ───
class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);

  static const accent = Color(0xFF8B5CF6); // Regal Purple for CEO
  static const accentAlt = Color(0xFF38BDF8);
  static const gold = Color(0xFFD4A843);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const info = Color(0xFF0EA5E9);
}

class CeoDashboardPage extends StatefulWidget {
  const CeoDashboardPage({super.key});

  @override
  State<CeoDashboardPage> createState() => _CeoDashboardPageState();
}

class _CeoDashboardPageState extends State<CeoDashboardPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;

  // ─── Metrics ───
  int _confirmedSchools = 0;
  int _totalTeamMembers = 0;
  int _totalTeachers = 0;
  int _totalStudents = 0;
  int _totalCourses = 0;
  int _totalProjects = 0;

  // ─── Digital Marketing ───
  int _publishedContent = 0;
  int _pendingSeo = 0;
  int _draftContent = 0;

  // ─── QubiQ Overview ───
  int _activeSchools = 0;
  int _pendingSchools = 0;
  int _noAdminSchools = 0;
  int _totalPlatformUsers = 0;
  int _totalTickets = 0;
  int _openTickets = 0;
  int _resolvedTickets = 0;
  int _totalFeedback = 0;

  // ─── New Sections ───
  int _hardwareOrders = 0;
  int _pendingHardware = 0;
  int _shippedHardware = 0;
  List<Map<String, dynamic>> _growthData = [];
  List<Map<String, dynamic>> _recentActivity = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _loadAllMetrics();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMetrics() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchSchoolMetrics(),
        _fetchTeamMetrics(),
        _fetchPlatformStats(),
        _fetchCourseProjectStats(),
        _fetchTicketMetrics(),
        _fetchFeedbackMetrics(),
      ]);
    } catch (e) {
      debugPrint("CEO Dashboard error: $e");
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward(from: 0);
    }
  }

  // Store visits & tickets for reuse across methods
  List<SchoolVisit> _allConfirmedVisits = [];
  List<SupportTicket> _allTickets = [];

  Future<void> _fetchSchoolMetrics() async {
    try {
      final repo = SchoolVisitRepository();
      final visits = await repo.getPaymentVisits();
      final confirmed =
          visits.where((v) => v.payment.paymentConfirmed).toList();
      _confirmedSchools = confirmed.length;
      _activeSchools = confirmed.length; // All confirmed schools are active
      _pendingSchools = 0;
      _noAdminSchools = 0;
      _allConfirmedVisits = confirmed;

      // ── Growth Trend Data (schools per month) ──
      final Map<String, int> monthlyGrowth = {};
      for (var v in confirmed) {
        if (v.createdAt != null) {
          final key = DateFormat('MMM yy').format(v.createdAt!);
          monthlyGrowth[key] = (monthlyGrowth[key] ?? 0) + 1;
        }
      }
      // Sort by date and take last 6 months
      final sortedMonths = monthlyGrowth.entries.toList()
        ..sort((a, b) {
          final dateA = DateFormat('MMM yy').parse(a.key);
          final dateB = DateFormat('MMM yy').parse(b.key);
          return dateA.compareTo(dateB);
        });
      _growthData = sortedMonths
          .take(6)
          .map((e) => {'month': e.key, 'count': e.value})
          .toList();
    } catch (e) {
      debugPrint("School metrics error: $e");
    }
  }

  Future<void> _fetchTeamMetrics() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final teamMembers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).where((user) {
        final role = user.role?.toUpperCase() ?? '';
        final staffRoles = [
          'SUPER_ADMIN', 'ADMIN', 'MARKETING', 'TELE_MARKETING',
          'ACCOUNTS', 'ASSEMBLY_TEAM', 'INSTALLATION_TEAM',
          'QUBIQ', 'ADS', 'TESTING', 'CEO', 'DIGITAL_MARKETING',
        ];
        final isStaff = staffRoles.any((r) => role.contains(r));
        final isNotManual =
            !(user.name?.toLowerCase().contains('manually verified') ?? false);
        return isStaff && isNotManual;
      }).toList();
      _totalTeamMembers = teamMembers.length;
    } catch (e) {
      debugPrint("Team metrics error: $e");
    }
  }

  Future<void> _fetchPlatformStats() async {
    try {
      final statsRepo = StatisticsRepository();
      final stats = await statsRepo.getGlobalStats();
      _totalTeachers = stats['teachers'] ?? 0;
      _totalStudents = stats['students'] ?? 0;
      _totalPlatformUsers = _totalTeachers + _totalStudents;
    } catch (e) {
      debugPrint("Platform stats error: $e");
    }
  }

  Future<void> _fetchCourseProjectStats() async {
    try {
      final courseProvider = context.read<CourseProvider>();
      final projectProvider = context.read<ProjectProvider>();

      await Future.wait([
        courseProvider.fetchCourses(),
        projectProvider.fetchProjects(),
      ]);

      _totalCourses = courseProvider.courses.length;
      _totalProjects = projectProvider.projects.length;

      // Digital Marketing stats
      final publishedCourses =
          courseProvider.courses.where((c) => c.status == "Published").length;
      final publishedProjects =
          projectProvider.projects.where((p) => p.status == "Published").length;
      final pendingSeoCourses =
          courseProvider.courses.where((c) => c.status == "Pending SEO").length;
      final pendingSeoProjects = projectProvider.projects
          .where((p) => p.status == "Pending SEO")
          .length;
      final draftCourses =
          courseProvider.courses.where((c) => c.status == "Draft").length;
      final draftProjects =
          projectProvider.projects.where((p) => p.status == "Draft").length;

      _publishedContent = publishedCourses + publishedProjects;
      _pendingSeo = pendingSeoCourses + pendingSeoProjects;
      _draftContent = draftCourses + draftProjects;
    } catch (e) {
      debugPrint("Course/Project stats error: $e");
    }
  }

  Future<void> _fetchTicketMetrics() async {
    try {
      final repo = SupportRepository();
      final tickets = await repo.getAllTickets();
      _allTickets = tickets;
      _totalTickets = tickets.length;
      _openTickets = tickets.where((t) => t.status == 'open').length;
      _resolvedTickets = tickets.where((t) => t.status == 'resolved').length;

      // ── Hardware Orders ──
      final hardwareTickets = tickets.where((t) => t.isHardwareComplaint).toList();
      _hardwareOrders = hardwareTickets.length;
      _pendingHardware = hardwareTickets.where((t) => t.status == 'open').length;
      _shippedHardware = hardwareTickets
          .where((t) => t.manualTrackingStatus?.toLowerCase() == 'shipped' ||
                        t.trackingLink != null && t.trackingLink!.isNotEmpty)
          .length;

      // ── Recent Activity Feed ──
      _buildRecentActivity();
    } catch (e) {
      debugPrint("Ticket metrics error: $e");
    }
  }

  void _buildRecentActivity() {
    final List<Map<String, dynamic>> activity = [];

    // Add recent tickets
    final sortedTickets = List<SupportTicket>.from(_allTickets)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (var t in sortedTickets.take(5)) {
      activity.add({
        'icon': t.isHardwareComplaint ? Icons.build : Icons.confirmation_number,
        'color': t.status == 'open' ? _C.warning : _C.success,
        'title': t.isHardwareComplaint ? 'Hardware Complaint' : 'Support Ticket',
        'subtitle': t.email,
        'time': t.createdAt,
        'badge': t.status,
      });
    }

    // Add recent school sign-ups
    final sortedSchools = List<SchoolVisit>.from(_allConfirmedVisits)
      ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    for (var s in sortedSchools.take(5)) {
      activity.add({
        'icon': Icons.school,
        'color': _C.accent,
        'title': 'School Confirmed',
        'subtitle': s.schoolProfile.name,
        'time': s.createdAt ?? DateTime.now(),
        'badge': 'confirmed',
      });
    }

    // Sort all by time, newest first
    activity.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
    _recentActivity = activity.take(8).toList();
  }

  Future<void> _fetchFeedbackMetrics() async {
    try {
      final repo = TestingRepository();
      final feedback = await repo.getAllFeedback();
      _totalFeedback = feedback.length;
    } catch (e) {
      debugPrint("Feedback metrics error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;
    final isMedium = width > 650;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Animated Background ──
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CeoMeshPainter(_bgController.value),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          // ── Content ──
          Positioned.fill(
            child: _isLoading
                ? _buildLoader()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      color: _C.accent,
                      backgroundColor: _C.surface,
                      onRefresh: _loadAllMetrics,
                      child: ListView(
                        padding: EdgeInsets.only(
                          left: isWide ? 32 : 16,
                          right: isWide ? 32 : 16,
                          top: MediaQuery.of(context).padding.top + 56,
                          bottom: 40,
                        ),
                        children: [
                          _buildHeader(auth),
                          const SizedBox(height: 28),
                          _buildQuickActions(),
                          const SizedBox(height: 28),
                          _buildMetricStrip(isWide, isMedium),
                          const SizedBox(height: 28),
                          _buildDelegatedTasksSection(),
                          const SizedBox(height: 28),
                          _buildDigitalMarketingSection(isWide),
                          const SizedBox(height: 28),
                          _buildQubiqOverviewSection(isWide),
                          const SizedBox(height: 28),
                          _buildGrowthAndOrdersSection(isWide),
                          const SizedBox(height: 28),
                          _buildRecentActivitySection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ LOADER ═══════════════════
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_C.accent),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading executive dashboard…",
            style: TextStyle(
              color: _C.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader(AuthProvider auth) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }

    return _glassCard(
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.name ?? "CEO",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _C.accent.withValues(alpha: 0.2),
                        _C.gold.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _C.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _C.gold.withValues(
                                alpha: 0.6 + 0.4 * _pulseController.value,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.gold.withValues(
                                    alpha: 0.4 * _pulseController.value,
                                  ),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "CEO Console • Live",
                        style: TextStyle(
                          color: _C.gold.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Logout button
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.read<AuthProvider>().logout(),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: Color(0xFFFF6B6B), size: 20),
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
    );
  }

  // ═══════════════════ QUICK ACTIONS ═══════════════════
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            "Delegate Work",
            Icons.assignment_ind_outlined,
            _C.accentAlt,
            () {
              showDialog(context: context, builder: (_) => const AssignTaskDialog());
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ DELEGATED TASKS ═══════════════════
  Widget _buildDelegatedTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel("DELEGATED TASKS"),
          ],
        ),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: StreamBuilder<List<TaskModel>>(
            stream: context.read<TaskProvider>().tasksStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()));
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("No tasks currently delegated.", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                  ),
                );
              }

              return Column(
                children: tasks.take(5).map((task) {
                  Color priorityColor;
                  switch (task.priority) {
                    case 'High': priorityColor = _C.danger; break;
                    case 'Low': priorityColor = _C.success; break;
                    default: priorityColor = _C.warning;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                        left: BorderSide(color: priorityColor, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: task.assigneeType == 'Department' ? _C.accentAlt.withValues(alpha: 0.1) : _C.accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(task.assigneeType == 'Department' ? Icons.business : Icons.person, color: task.assigneeType == 'Department' ? _C.accentAlt : _C.accent, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text("To: ${task.assignedToName}", style: const TextStyle(color: _C.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text("${task.priority} Priority", style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(task.status, style: TextStyle(color: task.status == 'Completed' ? _C.success : _C.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: _C.danger, size: 20),
                          onPressed: () => context.read<TaskProvider>().deleteTask(task.id!),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════ METRIC STRIP (6 cards) ═══════════════════
  Widget _buildMetricStrip(bool isWide, bool isMedium) {
    final metrics = [
      _KPI("Schools Confirmed", _confirmedSchools, Icons.school, _C.success,
          "confirmed"),
      _KPI("Team Members", _totalTeamMembers, Icons.people_alt, _C.info,
          "active"),
      _KPI("Teacher Accounts", _totalTeachers, Icons.person, _C.warning,
          "platform"),
      _KPI("Student Accounts", _totalStudents, Icons.school_outlined,
          _C.accentAlt, "platform"),
      _KPI("Courses Created", _totalCourses, Icons.menu_book, _C.accent,
          "content"),
      _KPI("Projects Created", _totalProjects, Icons.code,
          const Color(0xFF10B981), "content"),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("BUSINESS OVERVIEW"),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 6 : (isMedium ? 3 : 2),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide ? 1.0 : (isMedium ? 1.1 : 1.2),
          ),
          itemCount: metrics.length,
          itemBuilder: (context, i) => _buildKpiCard(metrics[i], i),
        ),
      ],
    );
  }

  Widget _buildKpiCard(_KPI data, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(data.icon, color: data.color, size: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.badge,
                        style: TextStyle(
                          color: data.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _AnimatedCounter(
                    value: data.value, color: Colors.white, fontSize: 26),
                const SizedBox(height: 3),
                Text(
                  data.title.toUpperCase(),
                  style: const TextStyle(
                    color: _C.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════ DIGITAL MARKETING SECTION ═══════════════════
  Widget _buildDigitalMarketingSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("DIGITAL MARKETING"),
        const SizedBox(height: 14),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildDmStatsRow()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildContentPieChart()),
                ],
              )
            : Column(
                children: [
                  _buildDmStatsRow(),
                  const SizedBox(height: 16),
                  _buildContentPieChart(),
                ],
              ),
      ],
    );
  }

  Widget _buildDmStatsRow() {
    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9FF3).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign,
                    size: 18, color: Color(0xFFFF9FF3)),
              ),
              const SizedBox(width: 12),
              const Text(
                "Marketing Snapshot",
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDmStat(
                  "Published",
                  _publishedContent,
                  _C.success,
                  Icons.public,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDmStat(
                  "Pending SEO",
                  _pendingSeo,
                  _C.warning,
                  Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder(
                  stream: context.read<AdsProvider>().adsStream,
                  builder: (context, snapshot) {
                    final adsCount = snapshot.data?.length ?? 0;
                    return _buildDmStat(
                      "Active Ads",
                      adsCount,
                      _C.accentAlt,
                      Icons.play_circle_filled,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDmStat(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          _AnimatedCounter(value: value, color: Colors.white, fontSize: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _C.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPieChart() {
    final total = _publishedContent + _pendingSeo + _draftContent;
    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Content Distribution",
            style: TextStyle(
              color: _C.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 35,
                          sections: total == 0
                              ? [
                                  PieChartSectionData(
                                    value: 1,
                                    color: Colors.white.withValues(alpha: 0.1),
                                    radius: 18,
                                    showTitle: false,
                                  )
                                ]
                              : [
                                  PieChartSectionData(
                                    value: _publishedContent.toDouble(),
                                    color: _C.success,
                                    radius: 18,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: _pendingSeo.toDouble(),
                                    color: _C.warning,
                                    radius: 18,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: _draftContent.toDouble() == 0
                                        ? 0.1
                                        : _draftContent.toDouble(),
                                    color: _C.textMuted,
                                    radius: 18,
                                    showTitle: false,
                                  ),
                                ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            total.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Total",
                            style: TextStyle(
                              color: _C.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegend("Published", _publishedContent, _C.success),
                      const SizedBox(height: 14),
                      _buildLegend("Pending SEO", _pendingSeo, _C.warning),
                      const SizedBox(height: 14),
                      _buildLegend("Drafts", _draftContent, _C.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(color: _C.textSecondary, fontSize: 11),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ═══════════════════ QUBIQ OVERVIEW SECTION ═══════════════════
  Widget _buildQubiqOverviewSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("QUBIQ PLATFORM"),
        const SizedBox(height: 14),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildSchoolBreakdownCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildTicketsCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildPlatformActivityCard()),
                ],
              )
            : Column(
                children: [
                  _buildSchoolBreakdownCard(),
                  const SizedBox(height: 16),
                  _buildTicketsCard(),
                  const SizedBox(height: 16),
                  _buildPlatformActivityCard(),
                ],
              ),
      ],
    );
  }

  Widget _buildSchoolBreakdownCard() {
    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.business_rounded, size: 18, color: _C.accent),
              ),
              const SizedBox(width: 12),
              const Text(
                "Schools",
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$_confirmedSchools total",
                  style: const TextStyle(
                    color: _C.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildBreakdownBar(
            "Active",
            _activeSchools,
            _confirmedSchools,
            _C.success,
          ),
          const SizedBox(height: 14),
          _buildBreakdownBar(
            "Pending Setup",
            _pendingSchools,
            _confirmedSchools,
            _C.warning,
          ),
          const SizedBox(height: 14),
          _buildBreakdownBar(
            "No Admin",
            _noAdminSchools,
            _confirmedSchools,
            _C.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(
      String label, int value, int total, Color color) {
    final fraction = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: _C.textSecondary, fontSize: 12),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return LinearProgressIndicator(
                value: val,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsCard() {
    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.confirmation_number,
                    size: 18, color: _C.info),
              ),
              const SizedBox(width: 12),
              const Text(
                "Support Tickets",
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const SupportTicketListPage()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _C.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "View All →",
                    style: TextStyle(
                      color: _C.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 30,
                          sections: _totalTickets == 0
                              ? [
                                  PieChartSectionData(
                                    value: 1,
                                    color:
                                        Colors.white.withValues(alpha: 0.1),
                                    radius: 16,
                                    showTitle: false,
                                  )
                                ]
                              : [
                                  PieChartSectionData(
                                    value: _resolvedTickets.toDouble(),
                                    color: _C.success,
                                    radius: 16,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: _openTickets.toDouble(),
                                    color: _C.warning,
                                    radius: 16,
                                    showTitle: false,
                                  ),
                                ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _totalTickets.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            "Total",
                            style:
                                TextStyle(color: _C.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegend(
                          "Resolved", _resolvedTickets, _C.success),
                      const SizedBox(height: 14),
                      _buildLegend("Open", _openTickets, _C.warning),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformActivityCard() {
    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 18, color: Color(0xFF6C5CE7)),
              ),
              const SizedBox(width: 12),
              const Text(
                "Platform Activity",
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActivityRow(
            Icons.people_rounded,
            "Total Platform Users",
            _totalPlatformUsers.toString(),
            _C.accentAlt,
          ),
          const SizedBox(height: 16),
          _buildActivityRow(
            Icons.person,
            "Teachers",
            _totalTeachers.toString(),
            _C.warning,
          ),
          const SizedBox(height: 16),
          _buildActivityRow(
            Icons.school_outlined,
            "Students",
            _totalStudents.toString(),
            _C.info,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 16),
          _buildActivityRow(
            Icons.bug_report,
            "Testing Feedback",
            _totalFeedback.toString(),
            _C.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _C.textSecondary, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ═══════════════════ GROWTH TREND + HARDWARE ORDERS ═══════════════════
  Widget _buildGrowthAndOrdersSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("GROWTH & OPERATIONS"),
        const SizedBox(height: 14),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildGrowthTrendChart()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildHardwareOrdersCard()),
                ],
              )
            : Column(
                children: [
                  _buildGrowthTrendChart(),
                  const SizedBox(height: 16),
                  _buildHardwareOrdersCard(),
                ],
              ),
      ],
    );
  }

  Widget _buildGrowthTrendChart() {
    final maxY = _growthData.isEmpty
        ? 5.0
        : (_growthData.map((e) => (e['count'] as int).toDouble()).reduce(math.max) * 1.3).ceilToDouble();

    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up, size: 18, color: _C.success),
              ),
              const SizedBox(width: 12),
              const Text(
                "School Growth Trend",
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_growthData.length} months",
                  style: const TextStyle(
                    color: _C.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: _growthData.isEmpty
                ? Center(
                    child: Text(
                      "No data yet",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, gIdx, rod, rIdx) {
                            return BarTooltipItem(
                              '${_growthData[group.x.toInt()]['month']}\n${rod.toY.toInt()} schools',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _growthData.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _growthData[idx]['month'].toString().split(' ')[0],
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.04),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _growthData.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: (e.value['count'] as int).toDouble(),
                              gradient: LinearGradient(
                                colors: [
                                  _C.accent.withValues(alpha: 0.8),
                                  _C.accentAlt,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 18,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareOrdersCard() {
    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2, size: 18, color: _C.warning),
              ),
              const SizedBox(width: 12),
              const Text(
                "Hardware Orders",
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _AnimatedCounter(value: _hardwareOrders, color: Colors.white, fontSize: 40),
          const SizedBox(height: 4),
          const Text("Total Hardware Complaints",
              style: TextStyle(color: _C.textMuted, fontSize: 11)),
          const SizedBox(height: 28),
          _buildBreakdownBar("Pending", _pendingHardware, _hardwareOrders, _C.warning),
          const SizedBox(height: 14),
          _buildBreakdownBar("Shipped / Resolved", _shippedHardware, _hardwareOrders, _C.success),
          const SizedBox(height: 14),
          _buildBreakdownBar(
            "Processing",
            (_hardwareOrders - _pendingHardware - _shippedHardware).clamp(0, _hardwareOrders),
            _hardwareOrders,
            _C.accentAlt,
          ),
        ],
      ),
    );
  }

  // ═══════════════════ RECENT ACTIVITY FEED ═══════════════════
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("RECENT ACTIVITY"),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _C.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history, size: 18, color: _C.gold),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Activity Timeline",
                    style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Last ${_recentActivity.length} events",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_recentActivity.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      "No recent activity",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                )
              else
                ..._recentActivity.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final isLast = i == _recentActivity.length - 1;
                  return _buildActivityItem(
                    icon: item['icon'] as IconData,
                    color: item['color'] as Color,
                    title: item['title'] as String,
                    subtitle: item['subtitle'] as String,
                    time: item['time'] as DateTime,
                    badge: item['badge'] as String,
                    isLast: isLast,
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required DateTime time,
    required String badge,
    required bool isLast,
  }) {
    final timeAgo = _formatTimeAgo(time);
    final badgeColor = badge == 'open'
        ? _C.warning
        : badge == 'resolved'
            ? _C.success
            : _C.accent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.3),
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _C.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('MMM d').format(time);
  }

  // ═══════════════════ HELPERS ═══════════════════
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: _C.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════ ANIMATED COUNTER ═══════════════════
class _AnimatedCounter extends StatelessWidget {
  final int value;
  final Color color;
  final double fontSize;

  const _AnimatedCounter({
    required this.value,
    required this.color,
    this.fontSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(
          val.toString(),
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        );
      },
    );
  }
}

// ═══════════════════ KPI DATA ═══════════════════
class _KPI {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String badge;

  _KPI(this.title, this.value, this.icon, this.color, this.badge);
}

// ═══════════════════ CEO MESH GRADIENT BACKGROUND ═══════════════════
class _CeoMeshPainter extends CustomPainter {
  final double t;

  _CeoMeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF09090B));

    final cx1 = size.width * (0.15 + 0.25 * math.sin(t * math.pi * 2));
    final cy1 = size.height * (0.25 + 0.2 * math.cos(t * math.pi * 2));

    final cx2 =
        size.width * (0.75 + 0.2 * math.cos(t * math.pi * 2 + math.pi));
    final cy2 = size.height * (0.6 + 0.15 * math.sin(t * math.pi * 2));

    final cx3 =
        size.width * (0.5 + 0.3 * math.sin(t * math.pi * 2 + math.pi));
    final cy3 = size.height * (0.85 + 0.1 * math.cos(t * math.pi * 2));

    _drawOrb(canvas, Offset(cx1, cy1),
        const Color(0xFF7C3AED).withValues(alpha: 0.18), size.width * 0.4);
    _drawOrb(canvas, Offset(cx2, cy2),
        const Color(0xFF4338CA).withValues(alpha: 0.12), size.width * 0.45);
    _drawOrb(canvas, Offset(cx3, cy3),
        const Color(0xFFD4A843).withValues(alpha: 0.06), size.width * 0.3);

    // Subtle grid
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 50.0;
    final offsetX = (t * spacing) % spacing;
    final offsetY = (t * spacing * 0.5) % spacing;

    for (double i = -spacing; i < size.width + spacing; i += spacing) {
      canvas.drawLine(
          Offset(i + offsetX, 0), Offset(i + offsetX, size.height), paint);
    }
    for (double i = -spacing; i < size.height + spacing; i += spacing) {
      canvas.drawLine(
          Offset(0, i + offsetY), Offset(size.width, i + offsetY), paint);
    }
  }

  void _drawOrb(Canvas canvas, Offset center, Color color, double radius) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CeoMeshPainter old) => old.t != t;
}
