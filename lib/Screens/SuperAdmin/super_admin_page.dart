import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Model/User_model.dart';
import '../../Providers/AuthProvider.dart';
import '../../Repository/school_visit_repository.dart';
import '../../Repository/Support/support_repository.dart';
import '../../Repository/Testing/testing_repository.dart';
import 'package:qubiq_os/Repository/Statistics/statistics_repository.dart';
import 'package:qubiq_os/Repository/school_repository.dart';
import '../Testing/testing_feedback_list_page.dart';
import '../Support/support_ticket_list_page.dart';
import 'ProductManagementPage/ProductManagementPage.dart';

// ─── Color Palette ───
class _Palette {
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surfaceLight = Color(0xFF242836);
  static const accent = Color(0xFF6C63FF);
  static const accentAlt = Color(0xFF00D4AA);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B8FA3);
  static const textMuted = Color(0xFF565B73);
  static const danger = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFBB55);
  static const success = Color(0xFF00D4AA);
  static const info = Color(0xFF5B8DEF);
}

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key});

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;

  // --- Metrics ---
  int _confirmedSchools = 0;
  int _totalTickets = 0;
  int _openTickets = 0;
  int _resolvedTickets = 0;
  int _totalFeedback = 0;
  int _totalTeamMembers = 0;
  List<UserModel> _teamMembers = [];

  // --- Platform Stats ---
  int _totalAssignments = 0;
  int _totalAccounts = 0;
  int _totalProjects = 0;
  int _totalSubmissions = 0;
  
  // --- School Wise Stats ---
  String? _selectedSchoolId;
  Map<String, dynamic> _schoolStats = {};
  bool _isSchoolLoading = false;
  List<Map<String, dynamic>> _allSchools = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;

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
    _loadAllMetrics();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAllMetrics() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchSchoolMetrics(),
        _fetchTicketMetrics(),
        _fetchFeedbackMetrics(),
        _fetchTeamMetrics(),
        _fetchPlatformStats(),
        _fetchSchools(),
      ]);
    } catch (e) {
      debugPrint("Dashboard metrics error: $e");
    }
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward(from: 0);
    }
  }

  Future<void> _fetchSchoolMetrics() async {
    try {
      final repo = SchoolVisitRepository();
      final visits = await repo.getPaymentVisits();
      _confirmedSchools =
          visits.where((v) => v.payment.paymentConfirmed).length;
    } catch (e) {
      debugPrint("School metrics error: $e");
    }
  }

  Future<void> _fetchTicketMetrics() async {
    try {
      final repo = SupportRepository();
      final tickets = await repo.getAllTickets();
      _totalTickets = tickets.length;
      _openTickets = tickets.where((t) => t.status == 'open').length;
      _resolvedTickets = tickets.where((t) => t.status == 'resolved').length;
    } catch (e) {
      debugPrint("Ticket metrics error: $e");
    }
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

  Future<void> _fetchTeamMetrics() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _teamMembers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();
      _teamMembers.sort((a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
      _totalTeamMembers = _teamMembers.length;
    } catch (e) {
      debugPrint("Team metrics error: $e");
    }
  }

  Future<void> _fetchPlatformStats() async {
    try {
      final statsRepo = StatisticsRepository();
      final stats = await statsRepo.getGlobalStats();
      setState(() {
        _totalAccounts = stats['users'] ?? 0;
        _totalAssignments = stats['assignments'] ?? 0;
        _totalProjects = stats['projects'] ?? 0;
        _totalSubmissions = stats['submissions'] ?? 0;
      });
    } catch (e) {
      debugPrint("Platform stats error: $e");
    }
  }

  Future<void> _fetchSchools() async {
    try {
      final repo = SchoolRepository();
      final schools = await repo.getAllSchools();
      setState(() {
        _allSchools = schools;
      });
    } catch (e) {
      debugPrint("Schools fetch error: $e");
    }
  }

  Future<void> _loadSchoolStats(String schoolId) async {
    setState(() {
      _isSchoolLoading = true;
      _selectedSchoolId = schoolId;
    });
    try {
      final statsRepo = StatisticsRepository();
      _schoolStats = await statsRepo.getSchoolStats(schoolId);
    } catch (e) {
      debugPrint("School stats error: $e");
    } finally {
      if (mounted) setState(() => _isSchoolLoading = false);
    }
  }

  Future<void> _deleteTeamMember(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Team Member",
            style: TextStyle(color: _Palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text(
          "Are you sure you want to remove ${user.name ?? user.email ?? 'this user'}?",
          style: const TextStyle(color: _Palette.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: _Palette.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B6B)),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || user.id == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).delete();
      setState(() {
        _teamMembers.removeWhere((u) => u.id == user.id);
        _totalTeamMembers = _teamMembers.length;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${user.name ?? 'User'} removed"),
            backgroundColor: _Palette.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete user error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to delete user"),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;
    final isMedium = width > 650;

    return Container(
      color: _Palette.bg,
      child: _isLoading
          ? _buildLoader()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                color: _Palette.accent,
                backgroundColor: _Palette.surface,
                onRefresh: _loadAllMetrics,
                child: ListView(
                  padding: EdgeInsets.only(
                    left: isWide ? 32 : 16,
                    right: isWide ? 32 : 16,
                    top: MediaQuery.of(context).padding.top + 56,
                    bottom: 24,
                  ),
                  children: [
                    _buildHeader(auth),
                    const SizedBox(height: 28),
                    _buildMetricStrip(isWide, isMedium),
                    const SizedBox(height: 24),
                    _buildPlatformStatsSection(isWide),
                    const SizedBox(height: 24),
                    _buildMiddleRow(isWide),
                    const SizedBox(height: 24),
                    _buildSchoolStatsSection(),
                    const SizedBox(height: 24),
                    _buildQuickActions(isWide),
                    const SizedBox(height: 24),
                    _buildTeamSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
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
              valueColor:
                  AlwaysStoppedAnimation<Color>(_Palette.accent),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading dashboard…",
            style: TextStyle(
              color: _Palette.textSecondary,
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

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      auth.name ?? "Admin",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
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
                                  color: _Palette.accentAlt.withOpacity(
                                    0.6 + 0.4 * _pulseController.value,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _Palette.accentAlt.withOpacity(
                                        0.4 * _pulseController.value,
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
                            "EMMI Console • Live",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.read<AuthProvider>().logout(),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════ METRIC STRIP ═══════════════════
  Widget _buildMetricStrip(bool isWide, bool isMedium) {
    final crossAxisCount = isWide ? 3 : (isMedium ? 3 : 2);

    final metrics = [
      _MetricData(
        "Confirmed Schools",
        _confirmedSchools,
        Icons.school,
        _Palette.success,
        "schools",
      ),
      _MetricData(
        "Open Tickets",
        _openTickets,
        Icons.warning_amber,
        _Palette.warning,
        "pending",
      ),
      _MetricData(
        "Team Members",
        _totalTeamMembers,
        Icons.people_alt,
        _Palette.info,
        "active",
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isWide ? 2.2 : (isMedium ? 2.0 : 1.6),
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) => _buildGlassMetricCard(metrics[i], i),
    );
  }

  Widget _buildGlassMetricCard(_MetricData data, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 120)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: data.color.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: data.color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, size: 18, color: data.color),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.badge,
                    style: TextStyle(
                      color: data.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AnimatedCounter(
              value: data.value,
              color: _Palette.textPrimary,
            ),
            const SizedBox(height: 2),
            Text(
              data.title,
              style: const TextStyle(
                color: _Palette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ MIDDLE ROW: Tickets + Feedback ═══════════════════
  Widget _buildMiddleRow(bool isWide) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildTicketCard()),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildStatsColumn()),
        ],
      );
    }
    return Column(
      children: [
        _buildTicketCard(),
        const SizedBox(height: 16),
        _buildStatsColumn(),
      ],
    );
  }

  Widget _buildTicketCard() {
    final total = _totalTickets > 0 ? _totalTickets : 1;
    final resolvedPct = (_resolvedTickets / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.confirmation_number,
                    size: 18, color: _Palette.info),
              ),
              const SizedBox(width: 12),
              const Text(
                "Support Tickets",
                style: TextStyle(
                  color: _Palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (_) => const SupportTicketListPage()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _Palette.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "View All →",
                    style: TextStyle(
                      color: _Palette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stat row
          Row(
            children: [
              _ticketStat("Total", _totalTickets, _Palette.textPrimary),
              const SizedBox(width: 24),
              _ticketStat("Open", _openTickets, _Palette.warning),
              const SizedBox(width: 24),
              _ticketStat("Resolved", _resolvedTickets, _Palette.success),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Resolution Rate",
                    style: TextStyle(
                      color: _Palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "$resolvedPct%",
                    style: const TextStyle(
                      color: _Palette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _Palette.surfaceLight,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: resolvedPct / 100),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Container(
                            width: constraints.maxWidth * value,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [
                                  _Palette.accent,
                                  _Palette.accentAlt,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _Palette.accent.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

  Widget _ticketStat(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _Palette.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsColumn() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bug_report,
                    size: 18, color: _Palette.danger),
              ),
              const SizedBox(width: 12),
              const Text(
                "Testing Feedback",
                style: TextStyle(
                  color: _Palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _AnimatedCounter(
                value: _totalFeedback,
                color: _Palette.textPrimary,
                fontSize: 36,
              ),
              const SizedBox(width: 8),
              const Text(
                "reports",
                style: TextStyle(
                  color: _Palette.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                  builder: (_) => const TestingFeedbackListPage()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _Palette.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "View Reports →",
                  style: TextStyle(
                    color: _Palette.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ QUICK ACTIONS ═══════════════════
  Widget _buildQuickActions(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            "Quick Actions",
            style: TextStyle(
              color: _Palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 3 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: isWide ? 2.8 : 2.2,
          children: [
            _buildActionCard(
              title: "Products",
              subtitle: "Manage inventory",
              icon: Icons.precision_manufacturing,
              color: _Palette.accent,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const ProductManagementPage())),
            ),
            _buildActionCard(
              title: "Feedback",
              subtitle: "$_totalFeedback reports",
              icon: Icons.rate_review,
              color: _Palette.danger,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const TestingFeedbackListPage())),
            ),
            _buildActionCard(
              title: "Tickets",
              subtitle: "$_openTickets open",
              icon: Icons.headset_mic,
              color: _Palette.info,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const SupportTicketListPage())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _Palette.surfaceLight, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _Palette.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _Palette.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: _Palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════ TEAM MEMBERS ═══════════════════
  Widget _buildTeamSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt,
                    size: 18, color: _Palette.info),
              ),
              const SizedBox(width: 12),
              const Text(
                "Team Members",
                style: TextStyle(
                  color: _Palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _Palette.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_teamMembers.length} members",
                  style: const TextStyle(
                    color: _Palette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member list
          if (_teamMembers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No team members found",
                  style: TextStyle(color: _Palette.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _teamMembers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) =>
                  _buildMemberTile(_teamMembers[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(UserModel user) {
    final roleColor = _getRoleColor(user.role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _Palette.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (user.name ?? "?")[0].toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? "Unknown",
                  style: const TextStyle(
                    color: _Palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: const TextStyle(
                      color: _Palette.textMuted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
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
          const SizedBox(width: 8),

          // Delete button
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _deleteTeamMember(user),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline,
                  size: 16, color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'SUPER_ADMIN':
        return _Palette.accent;
      case 'ADMIN':
        return const Color(0xFF00D4AA);
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
        return const Color(0xFFFF6B6B);
      default:
        return _Palette.textSecondary;
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

  // ═══════════════════ PLATFORM STATS ═══════════════════
  Widget _buildPlatformStatsSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Global Platform Statistics",
          style: TextStyle(
            color: _Palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard("Total Accounts", _totalAccounts, Icons.person, Colors.blue),
            _buildStatCard("Assignments", _totalAssignments, Icons.assignment, Colors.orange),
            _buildStatCard("Projects", _totalProjects, Icons.code, Colors.purple),
            _buildStatCard("Submissions", _totalSubmissions, Icons.upload_file, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: _Palette.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(color: _Palette.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ SCHOOL STATS ═══════════════════
  Widget _buildSchoolStatsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "School-wise Performance",
            style: TextStyle(color: _Palette.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            dropdownColor: _Palette.surface,
            style: const TextStyle(color: _Palette.textPrimary),
            decoration: InputDecoration(
              labelText: "Select School",
              labelStyle: const TextStyle(color: _Palette.textSecondary),
              filled: true,
              fillColor: _Palette.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _allSchools.map((s) {
              return DropdownMenuItem<String>(
                value: s['schoolId'],
                child: Text(s['name'] ?? s['schoolId']),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) _loadSchoolStats(val);
            },
            value: _selectedSchoolId,
          ),
          if (_isSchoolLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_selectedSchoolId != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _schoolStatItem("Accounts", _schoolStats['users'] ?? 0),
                _schoolStatItem("Assignments", _schoolStats['assignments'] ?? 0),
                _schoolStatItem("Projects", _schoolStats['projects'] ?? 0),
                _schoolStatItem("Submissions", _schoolStats['submissions'] ?? 0),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _schoolStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(color: _Palette.accentAlt, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: _Palette.textMuted, fontSize: 11)),
      ],
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

// ═══════════════════ DATA MODEL ═══════════════════
class _MetricData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String badge;

  _MetricData(this.title, this.value, this.icon, this.color, this.badge);
}
