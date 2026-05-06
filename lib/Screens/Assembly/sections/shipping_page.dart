import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../Model/Marketing/ShippingDetails.dart';
import '../../../../Model/Marketing/school_visit_model.dart';
import '../../../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../../../Resources/api_endpoints.dart';
import '../../markerting/Resusable/date_picker_field.dart';

class ShippingPage extends StatefulWidget {
  final SchoolVisit visit;
  final bool readOnly;
  final bool isInstallationView;

  const ShippingPage({
    super.key,
    required this.visit,
    this.readOnly = false,
    this.isInstallationView = false,
  });

  @override
  State<ShippingPage> createState() => _ShippingPageState();
}

class _ShippingPageState extends State<ShippingPage> {
  bool isEditMode = false;

  // ─── Theme Constants ───
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surfaceLight = Color(0xFF242836);
  static const accent = Color(0xFF6C63FF);
  static const textSecondary = Color(0xFF8B8FA3);

  late TextEditingController shippingNumberCtrl;
  late TextEditingController shippingContactCtrl;
  late TextEditingController shippingAddressCtrl;
  late TextEditingController shippingCityCtrl;
  late TextEditingController shippingStateCtrl;
  late TextEditingController shippingCountryCtrl;
  late TextEditingController shippingPinCtrl;

  /// NEW
  bool passedToNextRole = false;
  bool arrived = false;
  late TextEditingController arrivedDateCtrl;

  String? shippingUploadedUrl;
  XFile? shippingPendingFile;
  bool shippingUploading = false;

  bool get hasShippingServerImage =>
      shippingUploadedUrl != null &&
      shippingUploadedUrl!.isNotEmpty &&
      shippingUploadedUrl != "null";

  @override
  void initState() {
    super.initState();
    final s = widget.visit.shippingDetails;

    shippingNumberCtrl = TextEditingController(text: s.shippingNumber);
    shippingContactCtrl = TextEditingController(text: s.contactNumber);
    shippingAddressCtrl = TextEditingController(text: s.address);
    shippingCityCtrl = TextEditingController(text: s.city);
    shippingStateCtrl = TextEditingController(text: s.state);
    shippingCountryCtrl = TextEditingController(text: s.country);
    shippingPinCtrl = TextEditingController(text: s.pinCode);

    passedToNextRole = s.passedToInstallation;
    arrived = s.arrived;
    arrivedDateCtrl = TextEditingController(text: s.arrivedDate);

    shippingUploadedUrl = s.photoUrl;
  }

  /// ================= IMAGE PICK =================
  Future<void> pickShippingImage() async {
    if (hasShippingServerImage || shippingPendingFile != null) return;

    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take Photo"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choose from Gallery"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      final _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        setState(() {
          shippingPendingFile = image;
        });
        await uploadShippingImage();
      }
    }
  }

  /// ================= UPLOAD =================
  Future<void> uploadShippingImage() async {
    if (shippingPendingFile == null || shippingUploading) return;

    shippingUploading = true;
    if (mounted) setState(() {});

    try {
      final url = await context.read<SchoolVisitProvider>().uploadVisitImage(
            visitId: widget.visit.id!,
            filePath: shippingPendingFile!.path,
            pickedFile: shippingPendingFile!,
          );

      if (url != null) {
        widget.visit.shippingDetails = widget.visit.shippingDetails.copyWith(photoUrl: url);
        await context.read<SchoolVisitProvider>().updateVisit(widget.visit);
        if (mounted) {
          setState(() {
            shippingUploadedUrl = url;
            shippingPendingFile = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mission Logistics Synchronized")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sync Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => shippingUploading = false);
      }
    }
  }

  /// ================= DELETE IMAGE =================
  Future<void> removeShippingImage() async {
    if (shippingUploadedUrl != null &&
        shippingUploadedUrl!.startsWith("/files")) {
      final fileName = shippingUploadedUrl!.split("/").last;

      final ok = await context.read<SchoolVisitProvider>().deleteVisitImage(
            visitId: widget.visit.id!,
            fileName: fileName,
          );

      if (!ok) return;
      shippingUploadedUrl = null;
    }

    setState(() {
      shippingUploadedUrl = null;
      shippingPendingFile = null;
    });
  }

  /// ================= UI HELPERS =================
  Widget editableField(String label, TextEditingController c, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          readOnly: !isEditMode,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isEditMode ? accent : textSecondary, size: 20),
            filled: true,
            fillColor: isEditMode ? Colors.white.withValues(alpha: 0.05) : surface,
            hintStyle: const TextStyle(color: Colors.white24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isEditMode ? accent.withValues(alpha: 0.5) : Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isEditMode ? accent.withValues(alpha: 0.3) : Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: accent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _noPhotoBox() {
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "No Photo",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildShippingTile(dynamic img) {
    final isNetwork = img is String;

    if (isNetwork && (img.isEmpty || img == "null")) {
      return _noPhotoBox();
    }

    final imageUrl = isNetwork ? '${ApiEndpoints.baseUrl}$img' : null;
    final localPath = !isNetwork ? img.path : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isNetwork
                ? Image.network(imageUrl!, width: 120, height: 120, fit: BoxFit.cover)
                : Image.file(File(localPath!), width: 120, height: 120, fit: BoxFit.cover),
          ),
        ),
        if (isEditMode)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: removeShippingImage,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  /// ================= SAVE FULL MODEL =================
  Future<void> save() async {
    final provider = context.read<SchoolVisitProvider>();

    widget.visit.shippingDetails = ShippingDetails(
      address: shippingAddressCtrl.text,
      city: shippingCityCtrl.text,
      state: shippingStateCtrl.text,
      country: shippingCountryCtrl.text,
      pinCode: shippingPinCtrl.text,
      shippingNumber: shippingNumberCtrl.text,
      contactNumber: shippingContactCtrl.text,
      photoUrl: shippingUploadedUrl ?? "",
      passedToInstallation: passedToNextRole,
      arrived: arrived,
      arrivedDate: arrived ? arrivedDateCtrl.text : "",
    );

    await provider.updateVisit(widget.visit);

    setState(() => isEditMode = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shipping updated successfully")),
    );

    Navigator.pop(context, true);
  }

  /// ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          if (widget.isInstallationView) ...[
            Positioned(top: -100, right: -100, child: _buildGlowBlob(accent.withValues(alpha: 0.15), 300)),
            Positioned(bottom: -50, left: -50, child: _buildGlowBlob(Colors.blueAccent.withValues(alpha: 0.1), 250)),
          ],
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.isInstallationView) ...[
                        _buildLogisticsCard(),
                        const SizedBox(height: 24),
                        _buildAddressCard(),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildQuickActionCard(),
                        const SizedBox(height: 32),
                      ],
                      _buildSupportSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: isEditMode
          ? FloatingActionButton.extended(
              onPressed: save,
              backgroundColor: accent,
              label: const Text("COMMIT CHANGES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              icon: const Icon(Icons.check_rounded),
            )
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: bg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!widget.readOnly && !widget.isInstallationView)
          IconButton(
            icon: Icon(isEditMode ? Icons.close : Icons.edit_note_rounded, color: Colors.white),
            onPressed: () => setState(() => isEditMode = !isEditMode),
          )
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "MISSION LOGISTICS",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: [Shadow(color: accent.withValues(alpha: 0.5), blurRadius: 10)],
          ),
        ),
        centerTitle: true,
        background: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [accent.withValues(alpha: 0.2), Colors.transparent]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("SHIPPING DETAILS", Icons.local_shipping_outlined),
          const SizedBox(height: 24),
          editableField("Shipping Number", shippingNumberCtrl, Icons.inventory_2_outlined),
          editableField("Contact Number", shippingContactCtrl, Icons.phone_android_rounded),
          const SizedBox(height: 8),
          _buildModernToggle("Passed to Installation", passedToNextRole, (v) => setState(() => passedToNextRole = v)),
          _buildModernToggle("Package Arrived", arrived, (v) {
            setState(() {
              arrived = v;
              if (!v) arrivedDateCtrl.text = "";
            });
          }),
          if (arrived) ...[
            const SizedBox(height: 16),
            const Text(
              "ARRIVAL DATE",
              style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            DatePickerField(
              label: "",
              controller: arrivedDateCtrl,
              editable: isEditMode,
              allowPastDates: true,
              showDate: true,
              showTime: false,
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            "SITE PHOTOS",
            style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (hasShippingServerImage) _buildShippingTile(shippingUploadedUrl),
              if (shippingPendingFile != null) _buildShippingTile(shippingPendingFile),
              if (isEditMode && !hasShippingServerImage && shippingPendingFile == null)
                GestureDetector(
                  onTap: pickShippingImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withValues(alpha: 0.3), style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: accent, size: 28),
                        SizedBox(height: 8),
                        Text("UPLOAD", style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              if (!isEditMode && !hasShippingServerImage && shippingPendingFile == null) _noPhotoBox(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("DESTINATION ADDRESS", Icons.location_on_outlined),
          const SizedBox(height: 24),
          editableField("Full Address", shippingAddressCtrl, Icons.map_rounded),
          Row(
            children: [
              Expanded(child: editableField("City", shippingCityCtrl, Icons.location_city_rounded)),
              const SizedBox(width: 16),
              Expanded(child: editableField("State", shippingStateCtrl, Icons.explore_outlined)),
            ],
          ),
          Row(
            children: [
              Expanded(child: editableField("Country", shippingCountryCtrl, Icons.public_rounded)),
              const SizedBox(width: 16),
              Expanded(child: editableField("Pincode", shippingPinCtrl, Icons.pin_drop_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernToggle(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            activeThumbColor: accent,
            activeTrackColor: accent.withValues(alpha: 0.3),
            onChanged: isEditMode ? onChanged : null,
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

  Widget _buildQuickActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem_outlined, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                "Hardware Issue?",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Found a defect during installation? Raise a ticket instantly for rapid replacement.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showComplaintDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text("REPORT DEFECT NOW", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isInstallationView ? "ACTIVE TRACKING" : "HARDWARE SUPPORT",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
                ),
                const Text("Monitor replacement lifecycle", style: TextStyle(color: textSecondary, fontSize: 11)),
              ],
            ),
            if (isEditMode && !widget.isInstallationView)
              TextButton.icon(
                onPressed: _showComplaintDialog,
                icon: const Icon(Icons.add_circle_outline, color: accent),
                label: const Text("REPORT ISSUE", style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (widget.visit.serviceOrders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
            decoration: BoxDecoration(
              color: surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.greenAccent.withValues(alpha: 0.5), size: 48),
                const SizedBox(height: 16),
                const Text("SYSTEMS STABLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text("No active hardware issues found", style: TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.visit.serviceOrders.length,
            itemBuilder: (context, index) => _buildServiceOrderTile(widget.visit.serviceOrders[index]),
          ),
      ],
    );
  }


  Widget _buildServiceOrderTile(ServiceOrder order) {
    Color statusColor;
    IconData itemIcon;

    switch (order.item.toUpperCase()) {
      case "BOT": itemIcon = Icons.smart_toy_outlined; break;
      case "MOBILE": itemIcon = Icons.phone_android_rounded; break;
      case "CHARGER": itemIcon = Icons.electrical_services_rounded; break;
      case "TABLET": itemIcon = Icons.tablet_mac_rounded; break;
      default: itemIcon = Icons.device_hub_rounded;
    }

    switch (order.status) {
      case "Order Placed": statusColor = Colors.blue; break;
      case "Confirmed": statusColor = Colors.orange; break;
      case "Shipped": statusColor = Colors.purple; break;
      case "Resolved": statusColor = Colors.green; break;
      default: statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(itemIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.item.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                    ),
                    Text(
                      "Order #${(order.createdAt?.millisecondsSinceEpoch ?? 0).toString().substring(7)}",
                      style: const TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            order.description,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildStatusTracker(order.status, statusColor),
        ],
      ),
    );
  }

  Widget _buildStatusTracker(String currentStatus, Color color) {
    final stages = ["Order Placed", "Confirmed", "Shipped", "Resolved"];
    final currentIndex = stages.indexOf(currentStatus);

    return Row(
      children: List.generate(stages.length, (index) {
        final isActive = index <= currentIndex;
        final isLast = index == stages.length - 1;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.white10,
                  shape: BoxShape.circle,
                  boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)] : [],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isActive ? color.withValues(alpha: 0.3) : Colors.white10,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _showComplaintDialog() {
    String selectedItem = "BOT";
    final descCtrl = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("RAISE DEFECT", style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          SizedBox(height: 4),
                          Text("Hardware Support", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: textSecondary, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "SELECT IMPACTED ITEM",
                    style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["BOT", "MOBILE", "CHARGER", "TABLET", "OTHER"].map((s) {
                        final isSelected = selectedItem == s;
                        IconData icon;
                        switch (s) {
                          case "BOT": icon = Icons.smart_toy_outlined; break;
                          case "MOBILE": icon = Icons.phone_android_rounded; break;
                          case "CHARGER": icon = Icons.electrical_services_rounded; break;
                          case "TABLET": icon = Icons.tablet_mac_rounded; break;
                          default: icon = Icons.device_hub_rounded;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedItem = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? accent : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? accent : Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Icon(icon, color: isSelected ? Colors.white : textSecondary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    s,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "DEFECT DESCRIPTION",
                    style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Explain what is broken or malfunctioning...",
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: accent)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("CANCEL", style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [accent, Color(0xFF8E8AFF)]),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: accent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (descCtrl.text.trim().isEmpty) return;
                              setState(() {
                                widget.visit.serviceOrders.add(ServiceOrder(
                                  item: selectedItem,
                                  description: descCtrl.text,
                                  createdAt: DateTime.now(),
                                ));
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Text("RAISE TICKET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }
}
