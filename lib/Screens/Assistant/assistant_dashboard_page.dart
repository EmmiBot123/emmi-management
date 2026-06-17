import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/AuthProvider.dart';
import '../../Providers/CourseProvider.dart';
import '../../Providers/ProjectProvider.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../ContentHub/content_hub_page.dart';
import '../ContentHub/create_course_dialog.dart';
import '../ContentHub/create_project_dialog.dart';
import '../Accounts/accounts_dashboard.dart';

// ─── Color Palette ───
class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF0EA5E9); // Ocean Blue / Sky Blue for Assistant
  static const accentAlt = Color(0xFF14B8A6); // Teal
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
}

class AssistantDashboardPage extends StatefulWidget {
  const AssistantDashboardPage({super.key});

  @override
  State<AssistantDashboardPage> createState() => _AssistantDashboardPageState();
}

class _AssistantDashboardPageState extends State<AssistantDashboardPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;

  // ─── Content Metrics ───
  int _totalCourses = 0;
  int _totalProjects = 0;
  int _publishedContent = 0;
  int _pendingSeo = 0;
  int _draftContent = 0;

  // ─── Finance Metrics ───
  double _pendingAmount = 0;
  double _receivedAmount = 0;
  List<dynamic> _pendingClearances = [];

  // ─── Timeline & Drafts ───
  List<Map<String, dynamic>> _recentDrafts = [];
  List<Map<String, dynamic>> _recentActivity = [];

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

    _loadAllData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final courseProvider = context.read<CourseProvider>();
      final projectProvider = context.read<ProjectProvider>();
      final visitProvider = context.read<SchoolVisitProvider>();

      await Future.wait([
        courseProvider.fetchCourses(),
        projectProvider.fetchProjects(),
        visitProvider.loadPaymentVisits(),
      ]);

      // Calculate Content Metrics
      _totalCourses = courseProvider.courses.length;
      _totalProjects = projectProvider.projects.length;

      // Process Content Data
      _recentDrafts = [];
      _recentActivity = [];
      
      int published = 0, pendingSeo = 0, draft = 0;
      for (var c in courseProvider.courses) {
        if (c.status == "Published") {
          published++;
        } else if (c.status == "Pending SEO") {
          pendingSeo++;
        } else {
          draft++;
          _recentDrafts.add({"type": "Course", "title": c.name, "time": c.createdAt ?? DateTime.now(), "item": c});
        }
        
        if (c.status == "Published" || c.status == "Scheduled") {
          _recentActivity.add({"title": "Course ${c.status}", "subtitle": c.name, "time": c.createdAt ?? DateTime.now(), "icon": Icons.menu_book, "color": _C.accent});
        }
      }
      for (var p in projectProvider.projects) {
        if (p.status == "Published") {
          published++;
        } else if (p.status == "Pending SEO") {
          pendingSeo++;
        } else {
          draft++;
          _recentDrafts.add({"type": "Project", "title": p.title, "time": p.createdAt ?? DateTime.now(), "item": p});
        }
        
        if (p.status == "Published" || p.status == "Scheduled") {
          _recentActivity.add({"title": "Project ${p.status}", "subtitle": p.title, "time": p.createdAt ?? DateTime.now(), "icon": Icons.code, "color": _C.accentAlt});
        }
      }
      _publishedContent = published;
      _pendingSeo = pendingSeo;
      _draftContent = draft;
      
      _recentDrafts.sort((a, b) => (b["time"] as DateTime).compareTo(a["time"] as DateTime));

      // Calculate Finance Metrics
      _pendingAmount = 0;
      _receivedAmount = 0;
      _pendingClearances = [];
      
      for (var v in visitProvider.paymentVisits) {
        if (v.payment.paymentConfirmed) {
          _receivedAmount += v.payment.amount;
          _recentActivity.add({"title": "Payment Received", "subtitle": v.schoolProfile.name, "time": v.createdAt ?? DateTime.now(), "icon": Icons.check_circle, "color": _C.success});
        } else {
          _pendingAmount += v.payment.amount;
          _pendingClearances.add(v);
        }
      }
      
      _recentActivity.sort((a, b) => (b["time"] as DateTime).compareTo(a["time"] as DateTime));

      // Sort pending clearances by date (newest first) if they have a date, otherwise just take the first 5
      _pendingClearances.sort((a, b) {
         final dateA = a.createdAt ?? DateTime(2000);
         final dateB = b.createdAt ?? DateTime(2000);
         return dateB.compareTo(dateA);
      });

    } catch (e) {
      debugPrint("Assistant Dashboard error: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward(from: 0);
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
          // Background Gradient (subtle teal/blue)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -0.8),
                  radius: 1.5,
                  colors: [
                    _C.accent.withValues(alpha: 0.15),
                    _C.bg,
                  ],
                ),
              ),
            ),
          ),
          
          Positioned.fill(
            child: _isLoading
                ? _buildLoader()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      color: _C.accent,
                      backgroundColor: _C.surface,
                      onRefresh: _loadAllData,
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
                          _buildMetricStrip(isWide, isMedium),
                          const SizedBox(height: 28),
                          _buildQuickActions(),
                          const SizedBox(height: 28),
                          _buildContentOverviewSection(isWide),
                          const SizedBox(height: 28),
                          _buildDraftsSection(),
                          const SizedBox(height: 28),
                          _buildFinanceOverviewSection(isWide),
                          const SizedBox(height: 28),
                          _buildRecentActivitySection(),
                          const SizedBox(height: 32),
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
              valueColor: const AlwaysStoppedAnimation<Color>(_C.accent),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading assistant dashboard…",
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
    String greeting = hour < 12 ? "Good Morning" : hour < 17 ? "Good Afternoon" : "Good Evening";

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
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.name ?? "Assistant",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.accentAlt.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.accentAlt.withValues(alpha: 0.3)),
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
                              color: _C.accentAlt.withValues(
                                alpha: 0.6 + 0.4 * _pulseController.value,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.accentAlt.withValues(
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
                        "Assistant Console",
                        style: TextStyle(
                          color: _C.accentAlt.withValues(alpha: 0.9),
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
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.read<AuthProvider>().logout(),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.danger.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: _C.danger, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Logout",
                    style: TextStyle(
                      color: _C.danger,
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

  // ═══════════════════ METRICS STRIP ═══════════════════
  Widget _buildMetricStrip(bool isWide, bool isMedium) {
    final List<Map<String, dynamic>> metrics = [
      {
        "title": "Total Courses",
        "value": _totalCourses,
        "icon": Icons.library_books,
        "color": _C.accent,
        "badge": "content",
      },
      {
        "title": "Total Projects",
        "value": _totalProjects,
        "icon": Icons.code,
        "color": _C.accentAlt,
        "badge": "content",
      },
      {
        "title": "Pending Payments",
        "value": "₹${_pendingAmount.toStringAsFixed(0)}",
        "icon": Icons.pending_actions,
        "color": _C.warning,
        "badge": "finance",
      },
      {
        "title": "Received Payments",
        "value": "₹${_receivedAmount.toStringAsFixed(0)}",
        "icon": Icons.account_balance_wallet,
        "color": _C.success,
        "badge": "finance",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("OVERVIEW"),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : (isMedium ? 2 : 1),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide ? 1.8 : 2.5,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, i) {
            final m = metrics[i];
            return _glassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (m["color"] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m["icon"] as IconData, color: m["color"] as Color, size: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (m["color"] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          m["badge"] as String,
                          style: TextStyle(
                            color: m["color"] as Color,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    m["value"].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (m["title"] as String).toUpperCase(),
                    style: const TextStyle(
                      color: _C.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════ CONTENT OVERVIEW ═══════════════════
  Widget _buildContentOverviewSection(bool isWide) {
    final totalContent = _totalCourses + _totalProjects;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel("CONTENT STATUS"),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentHubPage())),
              icon: const Icon(Icons.arrow_forward, size: 14, color: _C.accent),
              label: const Text("Go to Content Hub", style: TextStyle(color: _C.accent, fontSize: 12)),
            )
          ],
        ),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildBreakdownBar("Published", _publishedContent, totalContent, _C.success)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildBreakdownBar("Pending SEO", _pendingSeo, totalContent, _C.warning)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildBreakdownBar("Drafts", _draftContent, totalContent, _C.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════ FINANCE OVERVIEW ═══════════════════
  Widget _buildFinanceOverviewSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel("FINANCE & ACCOUNTS"),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsDashboard())),
              icon: const Icon(Icons.arrow_forward, size: 14, color: _C.accent),
              label: const Text("Go to Accounts", style: TextStyle(color: _C.accent, fontSize: 12)),
            )
          ],
        ),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pending School Clearances",
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              if (_pendingClearances.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text("No pending payments found", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                  ),
                )
              else
                ..._pendingClearances.take(5).map((visit) => _buildPaymentCard(visit)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(dynamic visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long, color: _C.warning, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.schoolProfile.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "By: ${visit.assignedUserName ?? visit.createdByUserName ?? 'Staff'}",
                  style: const TextStyle(color: _C.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${visit.payment.amount.toStringAsFixed(0)}",
                style: const TextStyle(color: _C.warning, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("PENDING", style: TextStyle(color: _C.warning, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
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
            "Create Course",
            Icons.menu_book,
            _C.accent,
            () async {
              final result = await showDialog(context: context, builder: (_) => const CreateCourseDialog());
              if (!context.mounted) return;
              if (result != null) {
                await context.read<CourseProvider>().addCourse(result);
                _loadAllData();
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionButton(
            "Create Project",
            Icons.code,
            _C.accentAlt,
            () async {
              final result = await showDialog(context: context, builder: (_) => const CreateProjectDialog());
              if (!context.mounted) return;
              if (result != null) {
                await context.read<ProjectProvider>().addProject(result);
                _loadAllData();
              }
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
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════ DRAFTS & ACTION ITEMS ═══════════════════
  Widget _buildDraftsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("ACTION ITEMS (DRAFTS)"),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_recentDrafts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text("No drafts to review!", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                  ),
                )
              else
                ..._recentDrafts.take(4).map((draft) {
                  final isCourse = draft["type"] == "Course";
                  final color = isCourse ? _C.accent : _C.accentAlt;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(isCourse ? Icons.menu_book : Icons.code, color: color, size: 16),
                    ),
                    title: Text(draft["title"], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text("${draft["type"]} • Draft", style: const TextStyle(color: _C.textMuted, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: _C.textSecondary, size: 18),
                      onPressed: () async {
                        final provider = isCourse ? context.read<CourseProvider>() : context.read<ProjectProvider>();
                        final dialog = isCourse ? CreateCourseDialog(course: draft["item"]) : CreateProjectDialog(project: draft["item"]);
                        final result = await showDialog(context: context, builder: (_) => dialog);
                        if (!context.mounted) return;
                        if (result != null) {
                          isCourse ? await (provider as CourseProvider).updateCourse(result) : await (provider as ProjectProvider).updateProject(result);
                          _loadAllData();
                        }
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════ RECENT ACTIVITY ═══════════════════
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("RECENT ACTIVITY"),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: _recentActivity.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text("No recent activity", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                ),
              )
            : Column(
                children: _recentActivity.take(5).map((activity) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(activity["icon"] as IconData, color: activity["color"] as Color, size: 20),
                    title: Text(activity["title"] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text(activity["subtitle"] as String, style: const TextStyle(color: _C.textMuted, fontSize: 11)),
                  );
                }).toList(),
              ),
        ),
      ],
    );
  }

  // ═══════════════════ HELPERS ═══════════════════
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: _C.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBreakdownBar(String label, int value, int total, Color color) {
    final double pct = total == 0 ? 0 : (value / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: _C.textSecondary, fontSize: 11)),
            Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
