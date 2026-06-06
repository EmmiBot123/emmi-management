import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Providers/AuthProvider.dart';

class DigitalMarketingDashboard extends StatefulWidget {
  const DigitalMarketingDashboard({super.key});

  @override
  State<DigitalMarketingDashboard> createState() => _DigitalMarketingDashboardState();
}

class _DigitalMarketingDashboardState extends State<DigitalMarketingDashboard> {
  // --- Dark Theme Palette ---
  static const Color _bg = Color(0xFF0F1117);
  static const Color _surface = Color(0xFF1A1D27);
  static const Color _surfaceLight = Color(0xFF242836);
  static const Color _accent = Color(0xFF00D4AA); // Cyberpunk Cyan
  static const Color _accentSecondary = Color(0xFFFF9FF3); // Neon Pink
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFF8B8FA3);
  static const Color _textMuted = Color(0xFF565B73);

  // --- UTM Builder State ---
  final _urlCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _mediumCtrl = TextEditingController();
  final _campaignCtrl = TextEditingController();
  String _generatedUtm = '';

  @override
  void dispose() {
    _urlCtrl.dispose();
    _sourceCtrl.dispose();
    _mediumCtrl.dispose();
    _campaignCtrl.dispose();
    super.dispose();
  }

  void _generateUtm() {
    if (_urlCtrl.text.isEmpty) return;
    
    final uri = Uri.tryParse(_urlCtrl.text.trim());
    if (uri == null) return;

    Map<String, String> params = {};
    if (uri.hasQuery) {
      params.addAll(uri.queryParameters);
    }
    
    if (_sourceCtrl.text.isNotEmpty) params['utm_source'] = _sourceCtrl.text.trim();
    if (_mediumCtrl.text.isNotEmpty) params['utm_medium'] = _mediumCtrl.text.trim();
    if (_campaignCtrl.text.isNotEmpty) params['utm_campaign'] = _campaignCtrl.text.trim();

    final newUri = uri.replace(queryParameters: params);
    setState(() {
      _generatedUtm = newUri.toString();
    });
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Copied to clipboard!"),
        backgroundColor: _surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(auth),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Functional Tools Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      return Flex(
                        direction: isDesktop ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isDesktop ? 3 : 0,
                            child: _buildUtmBuilder(),
                          ),
                          if (isDesktop) const SizedBox(width: 24),
                          if (!isDesktop) const SizedBox(height: 24),
                          Expanded(
                            flex: isDesktop ? 2 : 0,
                            child: Column(
                              children: [
                                _buildQuickLinks(),
                                const SizedBox(height: 24),
                                _buildIdeaBoard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
      backgroundColor: _bg,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentSecondary.withOpacity(0.15), _bg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentSecondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentSecondary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.rocket_launch, color: _accentSecondary, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Digital Marketing Workspace",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Welcome back, ${auth.name?.split(' ')[0] ?? 'Marketer'}",
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // UTM BUILDER WIDGET
  // ---------------------------------------------------------
  Widget _buildUtmBuilder() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _surfaceLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link, color: _accent, size: 20),
              ),
              const SizedBox(width: 16),
              const Text(
                "UTM Link Builder",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Generate tracking links for your ad campaigns instantly.",
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),
          
          _buildTextField("Website URL", "https://qubiqos.com", _urlCtrl, Icons.language),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Campaign Source", "google, facebook", _sourceCtrl, Icons.source)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("Campaign Medium", "cpc, banner, email", _mediumCtrl, Icons.category)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField("Campaign Name", "summer_sale, launch", _campaignCtrl, Icons.campaign),
          
          const SizedBox(height: 28),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _generateUtm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("Generate Link", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),

          if (_generatedUtm.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _generatedUtm,
                      style: const TextStyle(color: _accent, fontSize: 13, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: _textSecondary, size: 20),
                    onPressed: () => _copyToClipboard(_generatedUtm),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
            prefixIcon: Icon(icon, color: _textMuted, size: 18),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // QUICK LINKS WIDGET
  // ---------------------------------------------------------
  Widget _buildQuickLinks() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _surfaceLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Asset Hub",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickLinkItem("Brand Guidelines", Icons.book, Colors.blueAccent),
          _buildQuickLinkItem("Logo Assets", Icons.image, Colors.orangeAccent),
          _buildQuickLinkItem("Ad Templates", Icons.design_services, _accentSecondary),
        ],
      ),
    );
  }

  Widget _buildQuickLinkItem(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _surfaceLight),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: _textMuted, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // IDEA BOARD WIDGET
  // ---------------------------------------------------------
  Widget _buildIdeaBoard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_surface, _bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _surfaceLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Campaign Ideas",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add_circle, color: _accentSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildIdeaNote("Summer Sale", "Targeting ages 18-25 on Insta", Colors.amber),
          _buildIdeaNote("Retargeting B2B", "LinkedIn sponsored messages for Q3", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildIdeaNote(String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
