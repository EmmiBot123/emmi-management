import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Providers/AuthProvider.dart';
import '../../Providers/Ads/AdsProvider.dart';
import '../../Providers/CourseProvider.dart';
import '../../Providers/ProjectProvider.dart';
import '../../Providers/TaskProvider.dart';
import '../../Model/Ads/user_ad_model.dart';
import '../../Model/Task_model.dart';
import '../Ads/add_ad_dialog.dart';
import '../CEO/task_work_thread_sheet.dart';

// ─── Modern Cyberpunk Cyan & Neon Rose Theme ───
class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const surfaceLight = Color(0xFF242836);
  static const cyan = Color(0xFF00D4AA); // Cyberpunk Cyan
  static const rose = Color(0xFFF43F5E); // Neon Rose
  static const amber = Color(0xFFF59E0B);
  static const purple = Color(0xFF8B5CF6);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const danger = Color(0xFFEF4444);
}

class DigitalMarketingDashboardPage extends StatefulWidget {
  const DigitalMarketingDashboardPage({super.key});

  @override
  State<DigitalMarketingDashboardPage> createState() => _DigitalMarketingDashboardPageState();
}

class _DigitalMarketingDashboardPageState extends State<DigitalMarketingDashboardPage> {
  // UTM Builder controllers
  final _urlCtrl = TextEditingController(text: "https://qubiq.emmi.in");
  final _sourceCtrl = TextEditingController();
  final _mediumCtrl = TextEditingController();
  final _campaignCtrl = TextEditingController();
  String _generatedUtm = '';

  // Creative Ideas List
  final List<Map<String, String>> _ideas = [
    {
      "title": "School Robotics Workshop Reel",
      "platform": "Instagram",
      "status": "In Production",
      "hook": "Students building their first robot with QubiQ board",
    },
    {
      "title": "Principal Testimonial Ad Copy",
      "platform": "Meta Ads",
      "status": "Testing",
      "hook": "How 10+ schools automated STEM curriculum effortlessly",
    },
    {
      "title": "Google Search PPC - AI Lab for Schools",
      "platform": "Google Ads",
      "status": "Live",
      "hook": "Best AI and robotics education lab setup for CBSE & ICSE",
    },
    {
      "title": "Monthly STEM Insights Newsletter",
      "platform": "Email",
      "status": "Draft",
      "hook": "New Python course launch + hardware order discounts",
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateUtm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
      context.read<ProjectProvider>().fetchProjects();
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _sourceCtrl.dispose();
    _mediumCtrl.dispose();
    _campaignCtrl.dispose();
    super.dispose();
  }

  void _generateUtm() {
    final base = _urlCtrl.text.trim();
    if (base.isEmpty) {
      setState(() => _generatedUtm = '');
      return;
    }

    final uri = Uri.tryParse(base);
    if (uri == null) return;

    Map<String, String> params = {};
    if (uri.hasQuery) {
      params.addAll(uri.queryParameters);
    }

    if (_sourceCtrl.text.trim().isNotEmpty) params['utm_source'] = _sourceCtrl.text.trim();
    if (_mediumCtrl.text.trim().isNotEmpty) params['utm_medium'] = _mediumCtrl.text.trim();
    if (_campaignCtrl.text.trim().isNotEmpty) params['utm_campaign'] = _campaignCtrl.text.trim();

    final newUri = uri.replace(queryParameters: params.isNotEmpty ? params : null);
    setState(() {
      _generatedUtm = newUri.toString();
    });
  }

  void _applyPreset(String source, String medium, String campaign) {
    _sourceCtrl.text = source;
    _mediumCtrl.text = medium;
    _campaignCtrl.text = campaign;
    _generateUtm();
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: _C.cyan, size: 18),
            SizedBox(width: 10),
            Text("Campaign UTM link copied to clipboard!"),
          ],
        ),
        backgroundColor: _C.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddCampaignDialog() {
    showDialog(context: context, builder: (_) => const AddAdDialog());
  }

  void _confirmDeleteAd(String adId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        title: const Text("Delete Campaign?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This will remove the campaign record from the live system.",
          style: TextStyle(color: _C.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: _C.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () {
              context.read<AdsProvider>().deleteAd(adId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adsProvider = context.watch<AdsProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final projectProvider = context.watch<ProjectProvider>();
    final taskProvider = context.watch<TaskProvider>();

    final userId = auth.userId ?? '';
    final userName = auth.name ?? 'Growth Marketer';
    final userRole = auth.role ?? 'DIGITAL_MARKETING';

    final totalCourses = courseProvider.courses.length;
    final totalProjects = projectProvider.projects.length;
    final totalModules = totalCourses + totalProjects;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 32 : 16,
          MediaQuery.of(context).padding.top + 20,
          isDesktop ? 32 : 16,
          40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header & Growth Persona Banner
            _buildHeader(userName),
            const SizedBox(height: 24),

            // 2. Metric Hero Strip
            StreamBuilder<List<AdModel>>(
              stream: adsProvider.adsStream,
              builder: (context, snapshot) {
                final adsCount = (snapshot.data ?? []).length;
                return _buildMetricStrip(
                  activeAds: adsCount,
                  totalModules: totalModules,
                  totalCourses: totalCourses,
                  totalProjects: totalProjects,
                  isDesktop: isDesktop,
                );
              },
            ),
            const SizedBox(height: 28),

            // 3. Two-Column Bento Layout
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildAdsManagerCard(adsProvider),
                        const SizedBox(height: 20),
                        _buildUtmBuilderCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildSeoDiscoveryCard(totalCourses, totalProjects),
                        const SizedBox(height: 20),
                        _buildCreativePipelineCard(),
                        const SizedBox(height: 20),
                        _buildDigitalMarketingTasksCard(taskProvider, userId, userRole),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              _buildAdsManagerCard(adsProvider),
              const SizedBox(height: 20),
              _buildUtmBuilderCard(),
              const SizedBox(height: 20),
              _buildSeoDiscoveryCard(totalCourses, totalProjects),
              const SizedBox(height: 20),
              _buildCreativePipelineCard(),
              const SizedBox(height: 20),
              _buildDigitalMarketingTasksCard(taskProvider, userId, userRole),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════ HEADER ═══════════════════
  Widget _buildHeader(String userName) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _C.cyan.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.rocket_launch_rounded, color: Colors.black, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "Digital Marketing & Growth HQ",
                      style: const TextStyle(
                        color: _C.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.cyan.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      "CAMPAIGNS & SEO",
                      style: TextStyle(
                        color: _C.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Welcome, $userName • Manage ads, search indexing, and track links",
                style: const TextStyle(color: _C.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.cyan,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _showAddCampaignDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Launch Ad", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ═══════════════════ METRICS ═══════════════════
  Widget _buildMetricStrip({
    required int activeAds,
    required int totalModules,
    required int totalCourses,
    required int totalProjects,
    required bool isDesktop,
  }) {
    final items = [
      _MetricData(
        title: "Active Campaigns",
        value: "$activeAds",
        subtext: "Live online ads",
        icon: Icons.campaign_rounded,
        color: _C.cyan,
      ),
      _MetricData(
        title: "SEO Modules",
        value: "$totalModules",
        subtext: "$totalCourses courses • $totalProjects projects",
        icon: Icons.travel_explore_rounded,
        color: _C.rose,
      ),
      _MetricData(
        title: "Active Channels",
        value: "4",
        subtext: "YouTube, Meta, Google, Email",
        icon: Icons.hub_rounded,
        color: _C.purple,
      ),
      _MetricData(
        title: "Growth Funnel",
        value: "Healthy",
        subtext: "Attribution active",
        icon: Icons.show_chart_rounded,
        color: _C.amber,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: items.map((m) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildMetricCard(m),
        ))).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: items.map((m) => _buildMetricCard(m)).toList(),
    );
  }

  Widget _buildMetricCard(_MetricData m) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.title,
                style: const TextStyle(
                  color: _C.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, color: m.color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.value,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.subtext,
                style: TextStyle(color: m.color, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════ AD CAMPAIGNS CARD ═══════════════════
  Widget _buildAdsManagerCard(AdsProvider adsProvider) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.video_library_rounded, color: _C.cyan, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Active Ad Campaigns",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAddCampaignDialog,
                icon: const Icon(Icons.add_circle_outline, color: _C.cyan, size: 18),
                label: const Text("New Campaign", style: TextStyle(color: _C.cyan, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<List<AdModel>>(
            stream: adsProvider.adsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: _C.cyan),
                  ),
                );
              }

              final ads = snapshot.data ?? [];
              if (ads.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.campaign_outlined, size: 40, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 10),
                        const Text("No active ad campaigns launched.", style: TextStyle(color: _C.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.cyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _showAddCampaignDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Launch First Campaign", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ads.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 16),
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  final isYouTube = (ad.youtubeUrl ?? '').contains("youtu");

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _C.rose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isYouTube ? Icons.play_circle_fill_rounded : Icons.ad_units_rounded,
                          color: _C.rose,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ad.title ?? 'Ad Campaign',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ad.youtubeUrl ?? '',
                              style: const TextStyle(color: _C.textMuted, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _C.cyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _C.cyan.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          "Active",
                          style: TextStyle(
                            color: _C.cyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: _C.danger, size: 18),
                        tooltip: "Delete Campaign",
                        onPressed: () {
                          if (ad.id != null) {
                            _confirmDeleteAd(ad.id!);
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════ SMART UTM BUILDER CARD ═══════════════════
  Widget _buildUtmBuilderCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: _C.cyan, size: 20),
              SizedBox(width: 8),
              Text(
                "Smart Campaign UTM Builder",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Generate tracked URLs with source attribution for ads and social channels.",
            style: TextStyle(color: _C.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip("Instagram Story", () => _applyPreset("instagram", "story", "stem_pilot")),
              _buildPresetChip("Meta Feed Ad", () => _applyPreset("facebook", "cpc", "school_demo_2026")),
              _buildPresetChip("Google Search", () => _applyPreset("google", "cpc", "stem_lab_setup")),
              _buildPresetChip("Monthly Newsletter", () => _applyPreset("email", "newsletter", "monthly_brief")),
            ],
          ),
          const SizedBox(height: 16),

          // Input Row 1: Base URL
          _buildInput("Landing Page URL", _urlCtrl, "https://qubiq.emmi.in"),
          const SizedBox(height: 12),

          // Input Row 2: Source, Medium, Campaign
          Row(
            children: [
              Expanded(child: _buildInput("Source", _sourceCtrl, "e.g. instagram")),
              const SizedBox(width: 10),
              Expanded(child: _buildInput("Medium", _mediumCtrl, "e.g. cpc / story")),
              const SizedBox(width: 10),
              Expanded(child: _buildInput("Campaign", _campaignCtrl, "e.g. school_pilot")),
            ],
          ),
          const SizedBox(height: 16),

          // Output Box with Copy Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.cyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _generatedUtm.isNotEmpty ? _generatedUtm : "Fill in parameters above to generate tracked link",
                    style: TextStyle(
                      color: _generatedUtm.isNotEmpty ? _C.cyan : _C.textMuted,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: _generatedUtm.isNotEmpty ? () => _copyToClipboard(_generatedUtm) : null,
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text("Copy", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: _C.cyan)),
      backgroundColor: _C.cyan.withValues(alpha: 0.1),
      side: BorderSide(color: _C.cyan.withValues(alpha: 0.25)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: onTap,
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _C.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: _C.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            onChanged: (_) => _generateUtm(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _C.textMuted, fontSize: 11),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════ SEO DISCOVERY CARD ═══════════════════
  Widget _buildSeoDiscoveryCard(int totalCourses, int totalProjects) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.travel_explore_rounded, color: _C.rose, size: 20),
              SizedBox(width: 8),
              Text(
                "SEO & Organic Discovery",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSeoItem("Courses Meta-Indexed", "$totalCourses published", Icons.menu_book_rounded, _C.cyan),
          const SizedBox(height: 10),
          _buildSeoItem("Robotics Projects Indexed", "$totalProjects projects", Icons.code_rounded, _C.purple),
          const SizedBox(height: 10),
          _buildSeoItem("Search Sitemap Status", "Synchronized & Fresh", Icons.check_circle_outline_rounded, _C.cyan),
        ],
      ),
    );
  }

  Widget _buildSeoItem(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            status,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ═══════════════════ CREATIVE PIPELINE CARD ═══════════════════
  Widget _buildCreativePipelineCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: _C.amber, size: 20),
              SizedBox(width: 8),
              Text(
                "Growth Idea & Creative Pipeline",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ideas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final idea = _ideas[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          idea['title']!,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _C.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            idea['status']!,
                            style: const TextStyle(color: _C.amber, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea['hook']!,
                      style: const TextStyle(color: _C.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════ TASKS CARD ═══════════════════
  Widget _buildDigitalMarketingTasksCard(TaskProvider taskProvider, String userId, String userRole) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, color: _C.purple, size: 20),
              SizedBox(width: 8),
              Text(
                "Digital Marketing Directives",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<TaskModel>>(
            stream: taskProvider.getTasksForUserStream(userId, userRole),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: _C.purple),
                  ),
                );
              }

              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "No tasks assigned to Digital Marketing.",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.take(3).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => TaskWorkThreadSheet.show(context, task),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(left: BorderSide(color: _C.cyan, width: 3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Status: ${task.status} • Tap to update",
                                    style: const TextStyle(color: _C.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chat_bubble_outline_rounded, color: _C.cyan, size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;

  _MetricData({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
  });
}
