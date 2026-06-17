import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/CourseProvider.dart';
import '../../Providers/ProjectProvider.dart';
import '../../Providers/Ads/AdsProvider.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Model/Ads/user_ad_model.dart';
import 'create_course_dialog.dart';
import 'create_project_dialog.dart';
import '../Ads/add_ad_dialog.dart';

// ─── Color Palette ───
class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFFF43F5E); // Neon Rose
  static const accentAlt = Color(0xFFF59E0B); // Sunset Orange
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
}

class DigitalMarketingSeoPage extends StatefulWidget {
  const DigitalMarketingSeoPage({super.key});

  @override
  State<DigitalMarketingSeoPage> createState() => _DigitalMarketingSeoPageState();
}

class _DigitalMarketingSeoPageState extends State<DigitalMarketingSeoPage> with TickerProviderStateMixin {
  int _seoViewType = 0; // 0 for Courses, 1 for Projects

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
      context.read<ProjectProvider>().fetchProjects();
      context.read<SchoolVisitProvider>().loadPaymentVisits();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showAddAdDialog() {
    showDialog(context: context, builder: (_) => const AddAdDialog());
  }

  void _confirmDeleteAd(String adId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _C.surface,
        title: const Text("Delete Campaign?", style: TextStyle(color: Colors.white)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: _C.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: _C.textMuted)),
          ),
          TextButton(
            onPressed: () {
              context.read<AdsProvider>().deleteAd(adId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: _C.danger),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final projectProvider = context.watch<ProjectProvider>();
    final visitProvider = context.watch<SchoolVisitProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 1000;
    final isMedium = width > 650;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            left: -100,
            child: _buildBlob(400, _C.accent.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _buildBlob(400, _C.accentAlt.withValues(alpha: 0.15)),
          ),

          if (courseProvider.isLoading || projectProvider.isLoading)
            _buildLoader()
          else
            FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: EdgeInsets.only(
                  left: isWide ? 32 : 16,
                  right: isWide ? 32 : 16,
                  top: MediaQuery.of(context).padding.top + 32,
                  bottom: 40,
                ),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  _buildMetricStrip(courseProvider, projectProvider, isWide, isMedium),
                  const SizedBox(height: 32),
                  _buildContentDistributionSection(courseProvider, projectProvider),
                  const SizedBox(height: 32),
                  _buildRecentActivitySection(courseProvider, projectProvider, visitProvider),
                  const SizedBox(height: 32),
                  _buildActiveCampaignsSection(),
                  const SizedBox(height: 32),
                  _buildSeoManagementSection(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════ COMPONENTS ═══════════════════

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(_C.accent)),
          ),
          const SizedBox(height: 20),
          Text("Syncing Analytics...", style: TextStyle(color: _C.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(color: _C.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader() {
    return _glassCard(
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Marketing Command Center",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.accent.withValues(alpha: 0.3)),
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
                              color: _C.accent.withValues(alpha: 0.6 + 0.4 * _pulseController.value),
                              boxShadow: [BoxShadow(color: _C.accent.withValues(alpha: 0.4 * _pulseController.value), blurRadius: 6)],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Live Analytics",
                        style: TextStyle(color: _C.accent.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                      ),
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

  // ═══════════════════ METRICS ═══════════════════
  Widget _buildMetricStrip(CourseProvider cp, ProjectProvider pp, bool isWide, bool isMedium) {
    final publishedCount = cp.courses.where((c) => c.status == "Published").length + pp.projects.where((p) => p.status == "Published").length;
    final pendingSeoCount = cp.courses.where((c) => c.status == "Pending SEO").length + pp.projects.where((p) => p.status == "Pending SEO").length;

    return StreamBuilder<List<AdModel>>(
      stream: context.read<AdsProvider>().adsStream,
      builder: (context, snapshot) {
        final adsCount = snapshot.data?.length ?? 0;
        
        final List<Map<String, dynamic>> metrics = [
          {"title": "Published Content", "value": publishedCount, "icon": Icons.public, "color": _C.success, "badge": "content"},
          {"title": "Pending SEO", "value": pendingSeoCount, "icon": Icons.warning_amber_rounded, "color": _C.accentAlt, "badge": "action"},
          {"title": "Active Campaigns", "value": adsCount, "icon": Icons.campaign, "color": _C.accent, "badge": "ads"},
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : (isMedium ? 3 : 1),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isWide ? 2.2 : (isMedium ? 1.5 : 2.5),
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
                        decoration: BoxDecoration(color: (m["color"] as Color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(m["icon"] as IconData, color: m["color"] as Color, size: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: (m["color"] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          m["badge"] as String,
                          style: TextStyle(color: m["color"] as Color, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(m["value"].toString(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text((m["title"] as String).toUpperCase(), style: const TextStyle(color: _C.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════ CONTENT DISTRIBUTION ═══════════════════
  Widget _buildContentDistributionSection(CourseProvider cp, ProjectProvider pp) {
    final published = cp.courses.where((c) => c.status == "Published").length + pp.projects.where((p) => p.status == "Published").length;
    final pendingSeo = cp.courses.where((c) => c.status == "Pending SEO").length + pp.projects.where((p) => p.status == "Pending SEO").length;
    final draft = cp.courses.where((c) => c.status == "Draft").length + pp.projects.where((p) => p.status == "Draft").length;
    final total = published + pendingSeo + draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("CONTENT DISTRIBUTION"),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildBreakdownBar("Optimized & Published", published, total, _C.success),
              const SizedBox(height: 16),
              _buildBreakdownBar("Pending SEO Optimization", pendingSeo, total, _C.accentAlt),
              const SizedBox(height: 16),
              _buildBreakdownBar("Drafts / Internal", draft, total, _C.textMuted),
            ],
          ),
        ),
      ],
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
            Text(label, style: const TextStyle(color: _C.textSecondary, fontSize: 12)),
            Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4))),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════ ACTIVE CAMPAIGNS ═══════════════════
  Widget _buildActiveCampaignsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel("ACTIVE CAMPAIGNS"),
          ],
        ),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: StreamBuilder<List<AdModel>>(
            stream: context.read<AdsProvider>().adsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator(color: _C.accent)));
              }
              final ads = snapshot.data ?? [];
              if (ads.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("No active campaigns running.", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                  ),
                );
              }
              return Column(
                children: ads.map((ad) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ad.thumbnailUrl.isNotEmpty
                              ? Image.network(ad.thumbnailUrl, width: 90, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackThumb())
                              : _fallbackThumb(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ad.title ?? "Untitled Ad", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(ad.youtubeUrl ?? "No URL provided", style: const TextStyle(color: _C.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: _C.danger, size: 20),
                          onPressed: () => _confirmDeleteAd(ad.id!),
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

  Widget _fallbackThumb() {
    return Container(
      width: 90,
      height: 60,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(Icons.video_library, color: _C.textMuted, size: 24),
    );
  }

  // ═══════════════════ QUICK ACTIONS ═══════════════════
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            "New Ad Campaign",
            Icons.campaign,
            _C.accent,
            _showAddAdDialog,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionButton(
            "Refresh Analytics",
            Icons.sync,
            _C.accentAlt,
            () {
              context.read<CourseProvider>().fetchCourses();
              context.read<ProjectProvider>().fetchProjects();
              context.read<SchoolVisitProvider>().loadPaymentVisits();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analytics updated!")));
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

  // ═══════════════════ RECENT ACTIVITY TIMELINE ═══════════════════
  Widget _buildRecentActivitySection(CourseProvider cp, ProjectProvider pp, SchoolVisitProvider vp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("MARKETING ACTIVITY"),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: StreamBuilder<List<AdModel>>(
            stream: context.read<AdsProvider>().adsStream,
            builder: (context, snapshot) {
              final ads = snapshot.data ?? [];
              List<Map<String, dynamic>> activity = [];

              for (var c in cp.courses) {
                if (c.status == "Published") {
                  activity.add({"title": "SEO Optimized", "subtitle": "Course: ${c.name}", "time": c.createdAt ?? DateTime.now(), "icon": Icons.check_circle, "color": _C.success});
                }
              }
              for (var p in pp.projects) {
                if (p.status == "Published") {
                  activity.add({"title": "SEO Optimized", "subtitle": "Project: ${p.title}", "time": p.createdAt ?? DateTime.now(), "icon": Icons.check_circle, "color": _C.success});
                }
              }
              for (var v in vp.paymentVisits) {
                if (v.payment.paymentConfirmed) {
                  activity.add({"title": "Lead Converted", "subtitle": v.schoolProfile.name, "time": v.createdAt ?? DateTime.now(), "icon": Icons.school, "color": _C.accentAlt});
                }
              }
              for (var ad in ads) {
                activity.add({"title": "Campaign Started", "subtitle": ad.title ?? "Untitled Ad", "time": ad.createdAt ?? DateTime.now(), "icon": Icons.campaign, "color": _C.accent});
              }

              activity.sort((a, b) => (b["time"] as DateTime).compareTo(a["time"] as DateTime));
              final recent = activity.take(5).toList();

              if (recent.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text("No recent activity.", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                  ),
                );
              }

              return Column(
                children: recent.map((act) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(act["icon"] as IconData, color: act["color"] as Color, size: 20),
                    title: Text(act["title"] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text(act["subtitle"] as String, style: const TextStyle(color: _C.textSecondary, fontSize: 11)),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════ SEO MANAGEMENT ═══════════════════
  Widget _buildSeoManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel("SEO WORKSPACE"),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggle(0, "Courses"),
                  _buildToggle(1, "Projects"),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _glassCard(
          padding: const EdgeInsets.all(24),
          child: _seoViewType == 0 ? _buildCoursesList() : _buildProjectsList(),
        ),
      ],
    );
  }

  Widget _buildToggle(int type, String label) {
    final isSelected = _seoViewType == type;
    return GestureDetector(
      onTap: () => setState(() => _seoViewType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _C.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _C.accent : _C.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    final provider = context.watch<CourseProvider>();
    final courses = provider.courses.where((c) => c.status == "Pending SEO" || c.status == "Published").toList();

    if (courses.isEmpty) return _emptySeoState("courses");

    return Column(
      children: courses.map((course) {
        return _buildSeoListItem(
          title: course.name,
          subtitle: "${course.category} • ${course.duration}",
          isPending: course.status == "Pending SEO",
          icon: Icons.school,
          onEdit: () async {
            final result = await showDialog(context: context, builder: (_) => CreateCourseDialog(course: course, isDigitalMarketer: true));
            if (!context.mounted) return;
            if (result != null) {
              final success = await provider.updateCourse(result);
              if (success) {
                if (result.status == "Published") await provider.syncCourseToQubiq(result);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course updated and synced!")));
              }
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildProjectsList() {
    final provider = context.watch<ProjectProvider>();
    final projects = provider.projects.where((p) => p.status == "Pending SEO" || p.status == "Published").toList();

    if (projects.isEmpty) return _emptySeoState("projects");

    return Column(
      children: projects.map((project) {
        return _buildSeoListItem(
          title: project.title,
          subtitle: "${project.difficulty} • ${project.tags.join(', ')}",
          isPending: project.status == "Pending SEO",
          icon: Icons.rocket_launch,
          onEdit: () async {
            final result = await showDialog(context: context, builder: (_) => CreateProjectDialog(project: project, isDigitalMarketer: true));
            if (!context.mounted) return;
            if (result != null) {
              final success = await provider.updateProject(result);
              if (success) {
                if (result.status == "Published") await provider.syncProjectToQubiq(result);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project updated and synced!")));
              }
            }
          },
        );
      }).toList(),
    );
  }

  Widget _emptySeoState(String item) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text("No $item found for SEO review.", style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
      ),
    );
  }

  Widget _buildSeoListItem({required String title, required String subtitle, required bool isPending, required IconData icon, required VoidCallback onEdit}) {
    final color = isPending ? _C.accentAlt : _C.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: isPending ? 0.3 : 0.1)),
        boxShadow: isPending ? [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1)] : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: _C.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(
                isPending ? "ACTION REQUIRED" : "OPTIMIZED",
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit_note, color: _C.accent, size: 28),
          onPressed: onEdit,
        ),
      ),
    );
  }
}
