import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../Model/Marketing/school_visit_model.dart';
import '../../Model/Marketing/School_profile_model.dart';
import '../../Model/Marketing/VisitDetails.dart';
import '../../Model/Marketing/ContactPerson.dart';
import '../../Model/Marketing/LabInformation.dart';
import '../../Model/Marketing/Payment.dart';
import '../../Model/Marketing/ProposalChecklist.dart';
import '../../Model/Marketing/PurchaseOrder.dart';
import '../../Model/Marketing/ShippingDetails.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Resources/theme_constants.dart';
import '../markerting/SchoolVisit/MapPicker.dart';

class AddInstallationVisitPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AddInstallationVisitPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AddInstallationVisitPage> createState() => _AddInstallationVisitPageState();
}

class _AddInstallationVisitPageState extends State<AddInstallationVisitPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Controllers
  final schoolNameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final pinCodeCtrl = TextEditingController();
  final visitDateCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final contactNameCtrl = TextEditingController();
  final contactPhoneCtrl = TextEditingController();
  final contactEmailCtrl = TextEditingController();
  final contactDesignationCtrl = TextEditingController(text: "Principal");

  String status = "PLANNED";
  double? latitude;
  double? longitude;
  String? mapLink;

  List<XFile> selectedImages = [];
  List<String> uploadedUrls = [];
  bool isUploading = false;
  bool isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _saveMission();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  _buildIdentityStep(),
                  _buildMissionStep(),
                  _buildContactStep(),
                  _buildEvidenceStep(),
                ],
              ),
            ),
          ),
          _buildNavigation()
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false, // Remove default drawer/back icon
      title: const Text(
        "Plan New Mission",
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
      ),
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
        onPressed: _prevPage,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive ? [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 8)] : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIdentityStep() {
    return _buildStepLayout(
      title: "School Identity",
      subtitle: "Where are we heading?",
      children: [
        _buildTextField("SCHOOL NAME", schoolNameCtrl, Icons.school_outlined),
        const SizedBox(height: 20),
        _buildTextField("FULL ADDRESS", addressCtrl, Icons.location_on_outlined, maxLines: 3),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField("CITY", cityCtrl, Icons.map_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField("STATE", stateCtrl, Icons.explore_outlined)),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField("PIN CODE", pinCodeCtrl, Icons.pin_drop_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        _buildMapAction(),
      ],
    );
  }

  Widget _buildMissionStep() {
    return _buildStepLayout(
      title: "Mission Details",
      subtitle: "Set the schedule and status",
      children: [
        _buildDatePicker("VISIT DATE", visitDateCtrl),
        const SizedBox(height: 24),
        _buildLabel("MISSION STATUS"),
        const SizedBox(height: 12),
        _buildStatusSelector(),
        const SizedBox(height: 24),
        _buildTextField("INTERNAL NOTES", notesCtrl, Icons.note_alt_outlined, maxLines: 4),
      ],
    );
  }

  Widget _buildContactStep() {
    return _buildStepLayout(
      title: "Field Contact",
      subtitle: "Who will assist on site?",
      children: [
        _buildTextField("CONTACT PERSON NAME", contactNameCtrl, Icons.person_outline),
        const SizedBox(height: 20),
        _buildTextField("DESIGNATION", contactDesignationCtrl, Icons.badge_outlined),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField("PHONE", contactPhoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField("EMAIL", contactEmailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.accent, size: 20),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Ensure the contact person is aware of the installation schedule.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceStep() {
    return _buildStepLayout(
      title: "Site Evidence",
      subtitle: "Initial photos or location proof",
      children: [
        _buildImagePicker(),
        const SizedBox(height: 24),
        if (selectedImages.isNotEmpty)
          _buildImageGrid(),
      ],
    );
  }

  Widget _buildStepLayout({required String title, required String subtitle, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.surfaceLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.surfaceLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent)),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController ctrl) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          ctrl.text = date.toString().split(' ')[0];
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(label, ctrl, Icons.calendar_month_outlined),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final options = ["PLANNED", "PENDING", "CLOSED_WON"];
    return Row(
      children: options.map((opt) {
        final isSelected = status == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => status = opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: opt == options.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : AppColors.surfaceLight),
              ),
              child: Center(
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapAction() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          builder: (c) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Pick Location", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                Expanded(
                  child: MiniLocationPicker(
                    onLocationPicked: (lat, long, url) {
                      setState(() {
                        latitude = lat;
                        longitude = long;
                        mapLink = url;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("CONFIRM LOCATION", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.map_outlined, color: AppColors.accent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pin Location", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  Text(
                    mapLink != null ? "Location Pinned ✅" : "Select coordinate on map",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight, style: BorderStyle.none),
        ),
        child: Column(
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 16),
            const Text("Upload Site Photos", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const Text("Minimum 1 photo required", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: selectedImages.length,
      itemBuilder: (context, index) {
        final img = selectedImages[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              kIsWeb ? Image.network(img.path, fit: BoxFit.cover) : Image.file(File(img.path), fit: BoxFit.cover),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => selectedImages.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _prevPage,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.surfaceLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _currentStep == 0 ? "CANCEL" : "BACK",
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isSaving ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _currentStep < 3 ? "CONTINUE" : "CREATE MISSION",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() => selectedImages.addAll(files));
    }
  }

  Future<void> _saveMission() async {
    if (schoolNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter school name")));
      return;
    }

    setState(() => isSaving = true);
    final provider = context.read<SchoolVisitProvider>();
    final uuid = const Uuid();
    final visitId = uuid.v4();

    // 1. Upload Images
    for (var img in selectedImages) {
      final url = await provider.uploadVisitImage(visitId: visitId, filePath: img.path, pickedFile: img);
      if (url != null) uploadedUrls.add(url);
    }

    // 2. Create Object
    final visit = SchoolVisit(
      id: visitId,
      createdAt: DateTime.now(),
      createdByUserId: widget.userId,
      createdByUserName: widget.userName,
      schoolProfile: SchoolProfile(
        name: schoolNameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        pinCode: pinCodeCtrl.text.trim(),
        googleMapLink: mapLink ?? "N/A",
        latitude: latitude ?? 0,
        longitude: longitude ?? 0,
        photoUrl: uploadedUrls,
      ),
      visitDetails: VisitDetails(
        status: status,
        visitDate: visitDateCtrl.text.trim(),
        statusNotes: notesCtrl.text.trim(),
      ),
      contactPersons: [
        ContactPerson(
          name: contactNameCtrl.text.trim(),
          designation: contactDesignationCtrl.text.trim(),
          phone: contactPhoneCtrl.text.trim(),
          email: contactEmailCtrl.text.trim(),
        ),
      ],
      // Placeholders for other fields required by model
      proposalChecklist: ProposalChecklist(sent: false, approved: false, whatsapp: false, email: false, remarks: ""),
      purchaseOrder: PurchaseOrder(poReceived: false, poNumber: "", poDate: ""),
      payment: Payment(advanceTransferred: false, amount: 0, transactionId: "", paymentConfirmed: false),
      shippingDetails: ShippingDetails(address: "", city: "", state: "", country: "", pinCode: "", shippingNumber: "", contactNumber: "", photoUrl: ""),
      labInformation: LabInformation(setupType: "", pcConfig: PCConfig(processor: "", ram: "", storageSize: "", storageType: "")),
      requiredProducts: [],
      otherRequirements: "",
      installationChecklist: [],
    );

    final ok = await provider.addVisit(visit);
    if (mounted) {
      setState(() => isSaving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mission created successfully!")));
      }
    }
  }
}
