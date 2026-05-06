import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Resources/theme_constants.dart';
import '../Assembly/sections/InstallationChecklistPage.dart';
import '../Assembly/sections/photos_page.dart';
import '../Assembly/sections/school_info_page.dart';
import '../Assembly/sections/shipping_page.dart';
import 'sections/digital_sign_off_page.dart';
import 'sections/installation_imei_page.dart';
import 'sections/technical_setup_page.dart';
import 'training_and_issues_page.dart';

class InstallationVisitDetailsPage extends StatefulWidget {
  final SchoolVisit visit;

  const InstallationVisitDetailsPage({
    super.key,
    required this.visit,
  });

  @override
  State<InstallationVisitDetailsPage> createState() =>
      _InstallationVisitDetailsPageState();
}

class _InstallationVisitDetailsPageState
    extends State<InstallationVisitDetailsPage> {
  late TextEditingController schoolCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController pinCodeCtrl;

  late List<String> uploadedUrls;
  List<XFile> pendingUpload = [];

  double? latValue;
  double? longValue;

  @override
  void initState() {
    super.initState();
    final v = widget.visit;

    uploadedUrls = List.from(v.schoolProfile.photoUrl);

    schoolCtrl = TextEditingController(text: v.schoolProfile.name);
    addressCtrl = TextEditingController(text: v.schoolProfile.address);
    stateCtrl = TextEditingController(text: v.schoolProfile.state);
    cityCtrl = TextEditingController(text: v.schoolProfile.city);
    pinCodeCtrl = TextEditingController(text: v.schoolProfile.pinCode);

    latValue = v.schoolProfile.latitude;
    longValue = v.schoolProfile.longitude;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Deep Background Glows ──
          Positioned(top: -150, right: -100, child: _buildGlowBlob(AppColors.accent.withValues(alpha: 0.1), 400)),
          Positioned(bottom: -100, left: -100, child: _buildGlowBlob(Colors.blueAccent.withValues(alpha: 0.08), 350)),
          Positioned(top: 400, left: -50, child: _buildGlowBlob(Colors.purpleAccent.withValues(alpha: 0.05), 200)),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 120,
                collapsedHeight: 80,
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: _buildExitButton(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "MISSION CONTROL",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: [Shadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMissionHeader(),
                      const SizedBox(height: 40),
                      Text(
                        "OPERATIONAL WORKFLOW",
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildBentoGrid(),
                      const SizedBox(height: 40),
                      _buildGuidedAction(),
                      const SizedBox(height: 100),
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

  Widget _buildGlowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }

  Widget _buildExitButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text("EXIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildMissionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)), // Increased corner visibility
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.rocket_launch_rounded, color: AppColors.accent, size: 12),
                        SizedBox(width: 8),
                        Text("ACTIVE DEPLOYMENT", style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  _buildLiveIndicator(),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                widget.visit.schoolProfile.name,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    "${widget.visit.schoolProfile.city}, ${widget.visit.schoolProfile.state}",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildHeaderInfo("INSTALLER", widget.visit.assignedUserName?.toUpperCase() ?? 'N/A'),
                  const SizedBox(width: 24),
                  _buildHeaderInfo("SCHOOL ID", widget.visit.id?.substring(widget.visit.id!.length - 4).toUpperCase() ?? '0000'),
                  const SizedBox(width: 24),
                  if (widget.visit.setupToken != null)
                    _buildHeaderInfo("QUBIQ PIN", widget.visit.setupToken!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildLiveIndicator() {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        const Text("ONLINE", style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildBentoBox(
                "Device Handover",
                "IMEI & Hardware",
                Icons.qr_code_scanner_rounded,
                const Color(0xFF4DFFDF),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstallationImeiPage(visit: widget.visit))),
                height: 200,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildBentoBox(
                "Technical",
                "S3 & Keys",
                Icons.settings_suggest_rounded,
                Colors.orangeAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => TechnicalSetupPage(visit: widget.visit))),
                height: 200,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBentoBox(
                "Site Photos",
                "Evidence Gallery",
                Icons.camera_rounded,
                const Color(0xFF6C63FF),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotosPage(visit: widget.visit))),
                height: 180,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoBox(
                "Sign-off",
                "Admin Signature",
                Icons.draw_rounded,
                AppColors.accent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => DigitalSignOffPage(visit: widget.visit))),
                height: 180,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildBentoBox(
                "Logistics",
                "Shipping",
                Icons.local_shipping_rounded,
                const Color(0xFF6BCBFF),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShippingPage(visit: widget.visit, isInstallationView: true))),
                height: 180,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildBentoBox(
                "Training",
                "Modules & Issues",
                Icons.forum_rounded,
                const Color(0xFFA29BFE),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingAndIssuesPage(visit: widget.visit))),
                height: 180,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoBox(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {double height = 150}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidedAction() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF6E6AFF)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: ListTile(
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
        ),
        title: const Text("START GUIDED INSTALLATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
        subtitle: Text("STEP-BY-STEP VISUAL ASSISTANT", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}
