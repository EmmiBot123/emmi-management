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

  const ShippingPage({
    super.key,
    required this.visit,
  });

  @override
  State<ShippingPage> createState() => _ShippingPageState();
}

class _ShippingPageState extends State<ShippingPage> {
  bool isEditMode = false;

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

    if (source == null) return;

    final file = await picker.pickImage(source: source);
    if (file == null) return;

    setState(() => shippingPendingFile = file);
    await uploadShippingImage();
  }

  /// ================= UPLOAD =================
  Future<void> uploadShippingImage() async {
    if (shippingPendingFile == null || shippingUploading) return;

    shippingUploading = true;
    setState(() {});

    final url = await context.read<SchoolVisitProvider>().uploadVisitImage(
          visitId: widget.visit.id!,
          filePath: shippingPendingFile!.path,
          pickedFile: shippingPendingFile!,
        );

    if (url != null) {
      setState(() {
        shippingUploadedUrl = url;
        shippingPendingFile = null;
      });
    } else {
      shippingUploadedUrl = null;
      shippingPendingFile = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shipping upload failed")),
      );
    }

    shippingUploading = false;
    setState(() {});
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          readOnly: !isEditMode,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: isEditMode ? Colors.white : Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isNetwork
              ? Image.network(
                  imageUrl!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(localPath!),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
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
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
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
      appBar: AppBar(
        title: const Text("Shipping Details"),
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.close : Icons.edit),
            onPressed: () => setState(() => isEditMode = !isEditMode),
          )
        ],
      ),
      floatingActionButton: isEditMode
          ? FloatingActionButton.extended(
              onPressed: save,
              label: const Text("Save"),
              icon: const Icon(Icons.save),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          editableField(
              "Shipping Number", shippingNumberCtrl, Icons.local_shipping),
          editableField("Contact Number", shippingContactCtrl, Icons.phone),
          SwitchListTile(
            title: const Text("Passed To Installation"),
            value: passedToNextRole,
            onChanged:
                isEditMode ? (v) => setState(() => passedToNextRole = v) : null,
          ),
          SwitchListTile(
            title: const Text("Arrived"),
            value: arrived,
            onChanged: isEditMode
                ? (v) {
                    setState(() {
                      arrived = v;
                      if (!v) arrivedDateCtrl.text = "";
                    });
                  }
                : null,
          ),
          if (arrived)
            DatePickerField(
              label: "Arrived Date",
              controller: arrivedDateCtrl,
              editable: isEditMode,
              allowPastDates: true,
              showDate: true,
              showTime: false,
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (hasShippingServerImage)
                _buildShippingTile(shippingUploadedUrl),
              if (shippingPendingFile != null)
                _buildShippingTile(shippingPendingFile),
              if (!isEditMode &&
                  !hasShippingServerImage &&
                  shippingPendingFile == null)
                _noPhotoBox(),
              if (isEditMode &&
                  !hasShippingServerImage &&
                  shippingPendingFile == null)
                GestureDetector(
                  onTap: pickShippingImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_a_photo, size: 30),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          editableField("Address", shippingAddressCtrl, Icons.location_on),
          editableField("City", shippingCityCtrl, Icons.location_city),
          editableField("State", shippingStateCtrl, Icons.map),
          editableField("Country", shippingCountryCtrl, Icons.public),
          editableField("Pincode", shippingPinCtrl, Icons.pin_drop),
        ],
      ),
    );
  }
}
