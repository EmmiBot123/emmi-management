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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.visit.schoolProfile.name,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Section (School Summary) ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mission Overview",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.visit.schoolProfile.name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.visit.schoolProfile.address,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildHeaderBadge("Installer: ${widget.visit.assignedUserName ?? 'N/A'}"),
                      const SizedBox(width: 8),
                      _buildHeaderBadge("ID: #${widget.visit.id!.substring(0, 5)}"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              "WORKFLOW MODULES",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 16),

            // ── Bento Grid ──
            _buildBentoGrid(),

            const SizedBox(height: 32),

            // ── Guided Walkthrough Button ──
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: ListTile(
                  onTap: () {
                    // Placeholder for Guided Walkthrough
                  },
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                  ),
                  title: const Text(
                    "Start Guided Installation",
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Step-by-step visual assistant",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBentoGrid() {
    return Column(
      children: [
        // Row 1: Primary Mission Data
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildBentoBox(
                "Device Handover",
                "IMEI & Hardware",
                Icons.phone_android_outlined,
                const Color(0xFF4DFFDF),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => InstallationImeiPage(visit: widget.visit))),
                height: 180,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildBentoBox(
                "School",
                "Info & Map",
                Icons.school_outlined,
                const Color(0xFFFF6B6B),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => SchoolInfoPage(
                  schoolCtrl: schoolCtrl, addressCtrl: addressCtrl, stateCtrl: stateCtrl, cityCtrl: cityCtrl, pinCtrl: pinCodeCtrl, lat: latValue, long: longValue,
                ))),
                height: 180,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 2: Media & Signature
        Row(
          children: [
            Expanded(
              child: _buildBentoBox(
                "Site Photos",
                "Upload & Preview",
                Icons.camera_enhance_outlined,
                const Color(0xFF6C63FF),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotosPage(uploadedUrls: uploadedUrls))),
                height: 160,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBentoBox(
                "Digital Sign-off",
                "Admin Signature",
                Icons.draw_outlined,
                AppColors.accent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalSignOffPage())),
                height: 160,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Row 3: Logistics & Training
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildBentoBox(
                "Shipping",
                "Track Status",
                Icons.local_shipping_outlined,
                const Color(0xFF6BCBFF),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShippingPage(visit: widget.visit))),
                height: 160,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _buildBentoBox(
                "Training & Feedback",
                "Modules & Issues",
                Icons.forum_outlined,
                const Color(0xFFA29BFE),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingAndIssuesPage(visit: widget.visit))),
                height: 160,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoBox(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {double height = 150}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
