import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../Assembly/sections/InstallationChecklistPage.dart';
import '../Assembly/sections/photos_page.dart';
import '../Assembly/sections/school_info_page.dart';
import '../Assembly/sections/shipping_page.dart';

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

  /// ---------- GRID TILE ----------
  Widget sectionGridBox(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.blue.shade50,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.visit.schoolProfile.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Installation Sections",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              /// 📸 Photos
              sectionGridBox("Photos", Icons.photo, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotosPage(
                      uploadedUrls: uploadedUrls,
                    ),
                  ),
                );
              }),

              /// 🏫 School Info
              sectionGridBox("School Info", Icons.school, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchoolInfoPage(
                      schoolCtrl: schoolCtrl,
                      addressCtrl: addressCtrl,
                      stateCtrl: stateCtrl,
                      cityCtrl: cityCtrl,
                      pinCtrl: pinCodeCtrl,
                      lat: latValue,
                      long: longValue,
                    ),
                  ),
                );
              }),

              /// 🚚 Shipping
              sectionGridBox("Shipping", Icons.local_shipping, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShippingPage(
                      visit: widget.visit,
                    ),
                  ),
                );
              }),

              /// ✅ Installation Checklist
              sectionGridBox("Installation Checklist", Icons.checklist, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InstallationChecklistPage(
                      visit: widget.visit,
                      role: 'INSTALLATION',
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
