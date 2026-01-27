import 'package:emmi_management/Resources/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Model/Marketing/ContactPerson.dart';
import '../../../../Model/Marketing/LabInformation.dart';
import '../../../../Model/Marketing/Payment.dart';
import '../../../../Model/Marketing/ProductRequest.dart';
import '../../../../Model/Marketing/ProposalChecklist.dart';
import '../../../../Model/Marketing/PurchaseOrder.dart';
import '../../../../Model/Marketing/School_profile_model.dart';
import '../../../../Model/Marketing/ShippingDetails.dart';
import '../../../../Model/Marketing/VisitDetails.dart';
import '../../../../Model/Marketing/school_visit_model.dart';
import '../../../../Model/productDetails/ProductOption.dart';
import '../../../../Providers/Marketing/SchoolVisitProvider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../Providers/User_provider.dart';
import '../../../Model/Marketing/shared_user_note.dart';
import '../Resusable/date_picker_field.dart';
import 'MapPicker.dart';

class VisitDetailsPage extends StatefulWidget {
  final SchoolVisit visit;
  final String userId;
  final String role;

  const VisitDetailsPage({
    super.key,
    required this.visit,
    required this.userId,
    required this.role,
  });

  @override
  State<VisitDetailsPage> createState() => _VisitDetailsPageState();
}

class _VisitDetailsPageState extends State<VisitDetailsPage> {
  bool isEditMode = false;

  /// ---------------------- CONTROLLERS -----------------------
  late TextEditingController schoolCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController pinCodeCtrl;
  late TextEditingController statusCtrl;
  late TextEditingController revisitCtrl;
  late TextEditingController visitDateTimeCtrl;
  late TextEditingController notesCtrl;
  late TextEditingController proposalRemarksCtrl;
  late TextEditingController poNumberCtrl;
  late TextEditingController poDateCtrl;
  late TextEditingController processorCtrl;
  late TextEditingController ramCtrl;
  late TextEditingController storageTypeCtrl;
  late TextEditingController storageSizeCtrl;
  late TextEditingController setupTypeCtrl;
  late TextEditingController shippingNumberCtrl;
  late TextEditingController shippingContactCtrl;
  late TextEditingController shippingAddressCtrl;
  late TextEditingController shippingCityCtrl;
  late TextEditingController shippingStateCtrl;
  late TextEditingController shippingCountryCtrl;
  late TextEditingController shippingPinCtrl;
  late TextEditingController paymentAmountCtrl;
  late TextEditingController paymentTxnCtrl;
  late TextEditingController otherRequirementsCtrl;
  late TextEditingController assignedNoteCtrl;
  late bool whatsappSent;
  late bool emailSent;

  bool passedToNextRole = false;
  bool arrived = false;
  late TextEditingController arrivedDateCtrl;

  /// Lists
  late List<ContactPerson> contacts;
  late List<ProductRequest> products;

  /// Temporary fields for inline form
  final newContactName = TextEditingController();
  final newContactRole = TextEditingController();
  final newContactPhone = TextEditingController();
  final newContactEmail = TextEditingController();

  final newProductName = TextEditingController();
  final newProductQty = TextEditingController();

  bool addingContact = false;
  bool addingProduct = false;

  int editingContactIndex = -1;
  int editingProductIndex = -1;

  /// ---------------------- IMAGE LOGIC -----------------------
  List<String> uploadedUrls = [];
  List<XFile> pendingUpload = [];
  int uploadIndex = 0;
  final int maxImages = 6;
  bool uploading = false;

  bool proposalSent = false;
  bool proposalApproved = false;
  bool poReceived = false;
  bool advanceTransferred = false;

  double? latValue;
  double? longValue;
  String? googleUrl;

  final List<String> statusOptions = [
    "PLANNED",
    "PENDING",
    "APPROVED",
    "REJECTED",
    "VISITED",
    "FOLLOW_UP_REQUIRED",
    "PROPOSAL_SENT",
    "NEGOTIATION",
    "CLOSED_WON",
    "CLOSED_LOST",
  ];

  String? selectedAssignedUserId;
  String? selectedAssignedUserName;
  late bool paymentConfirmed;
  List<ProductOption> availableProducts = [];
  Map<String, List<String>> productTypeMap = {};

  String? selectedEditProduct;
  String? selectedEditType;

  String? selectedNewProduct;
  String? selectedNewType;

  String? shippingUploadedUrl; // server url
  XFile? shippingPendingFile; // local not uploaded
  bool shippingUploading = false;
  bool get hasShippingServerImage =>
      shippingUploadedUrl != null &&
      shippingUploadedUrl!.isNotEmpty &&
      shippingUploadedUrl != "null";

  @override
  void initState() {
    super.initState();
    final v = widget.visit;
    final s = widget.visit.shippingDetails;

    assignedNoteCtrl = TextEditingController(text: v.assignedNote);
    selectedAssignedUserId = v.assignedUserId;
    selectedAssignedUserName = v.assignedUserName;
    latValue = v.schoolProfile.latitude;
    longValue = v.schoolProfile.longitude;
    googleUrl = v.schoolProfile.googleMapLink;

    schoolCtrl = TextEditingController(text: v.schoolProfile.name);
    addressCtrl = TextEditingController(text: v.schoolProfile.address);
    stateCtrl = TextEditingController(text: v.schoolProfile.state);
    cityCtrl = TextEditingController(text: v.schoolProfile.city);
    pinCodeCtrl = TextEditingController(text: v.schoolProfile.pinCode);

    statusCtrl = TextEditingController(text: v.visitDetails.status);
    revisitCtrl = TextEditingController(text: v.visitDetails.revisitDate ?? "");
    visitDateTimeCtrl =
        TextEditingController(text: v.visitDetails.visitDate ?? "");
    notesCtrl = TextEditingController(text: v.visitDetails.statusNotes);

    proposalSent = v.proposalChecklist.sent;
    proposalApproved = v.proposalChecklist.approved;
    whatsappSent = v.proposalChecklist.whatsapp;
    emailSent = v.proposalChecklist.email;
    proposalRemarksCtrl =
        TextEditingController(text: v.proposalChecklist.remarks);

    poReceived = v.purchaseOrder.poReceived;
    poNumberCtrl = TextEditingController(text: v.purchaseOrder.poNumber);
    poDateCtrl = TextEditingController(text: v.purchaseOrder.poDate ?? "");

    processorCtrl =
        TextEditingController(text: v.labInformation.pcConfig.processor);
    ramCtrl = TextEditingController(text: v.labInformation.pcConfig.ram);
    storageTypeCtrl =
        TextEditingController(text: v.labInformation.pcConfig.storageType);
    storageSizeCtrl =
        TextEditingController(text: v.labInformation.pcConfig.storageSize);
    setupTypeCtrl = TextEditingController(text: v.labInformation.setupType);
    shippingNumberCtrl =
        TextEditingController(text: v.shippingDetails.shippingNumber);
    shippingContactCtrl =
        TextEditingController(text: v.shippingDetails.contactNumber);
    shippingUploadedUrl = v.shippingDetails.photoUrl;
    shippingAddressCtrl =
        TextEditingController(text: v.shippingDetails.address);
    shippingCityCtrl = TextEditingController(text: v.shippingDetails.city);
    shippingStateCtrl = TextEditingController(text: v.shippingDetails.state);
    shippingCountryCtrl =
        TextEditingController(text: v.shippingDetails.country);
    shippingPinCtrl = TextEditingController(text: v.shippingDetails.pinCode);
    passedToNextRole = s.passedToInstallation;
    arrived = s.arrived;
    arrivedDateCtrl = TextEditingController(text: s.arrivedDate);

    paymentConfirmed = widget.visit.payment.paymentConfirmed;
    advanceTransferred = v.payment.advanceTransferred;
    paymentAmountCtrl =
        TextEditingController(text: v.payment.amount.toString());
    paymentTxnCtrl = TextEditingController(text: v.payment.transactionId ?? "");

    otherRequirementsCtrl = TextEditingController(text: v.otherRequirements);

    contacts = List.from(v.contactPersons);
    products = List.from(v.requiredProducts);

    uploadedUrls = List.from(v.schoolProfile.photoUrl);
    loadProductOptions();
  }

  Future<void> loadProductOptions() async {
    final list =
        await context.read<SchoolVisitProvider>().fetchAvailableProducts();

    availableProducts = list;
    productTypeMap.clear();

    for (var p in list) {
      productTypeMap[p.name] = p.types;
    }

    setState(() {});
  }

  Widget paymentStatusReadOnly() {
    return SwitchListTile(
      title: const Text(
        "Payment Confirmation",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        paymentConfirmed
            ? "Confirmed by Accounts"
            : "Not Confirmed by Accounts",
        style: TextStyle(
          color: paymentConfirmed ? Colors.green : Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),

      value: paymentConfirmed,

      // ❌ READ ONLY
      onChanged: null,
    );
  }

  ///-------------------------phone redirect-----------------------------------------//////
  void _showCallOptions(String phone) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Text("Contact Options",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ListTile(
            leading: Icon(Icons.call),
            title: Text("Call"),
            onTap: () async {
              Navigator.pop(context);
              final Uri uri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.copy),
            title: Text("Copy Number"),
            onTap: () {
              Clipboard.setData(ClipboardData(text: phone));
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Phone number copied")),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _openWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), ''); // remove spaces/dash

    final whatsappUrl = Uri.parse("whatsapp://send?phone=+91$cleaned");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      // Fallback to browser link
      final webUrl = Uri.parse("https://wa.me/$cleaned");
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _openEmail(String email) async {
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    // Try default email handler first
    if (await canLaunchUrl(mailtoUri)) {
      await launchUrl(
        mailtoUri,
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    // Gmail deep link fallback
    final gmailUri = Uri.parse("googlegmail://co?to=$email");

    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(
        gmailUri,
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No email app available")),
    );
  }

  /// ---------------------- FIXED IMAGE PICK + UPLOAD  MAIN----------------------

  Future<void> pickImages() async {
    final picker = ImagePicker();

    // --- Show choice dialog ---
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text("Take Photo"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text("Choose from Gallery"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    // ----- Capacity check: How many can still be uploaded -----
    final availableSlots =
        maxImages - (uploadedUrls.length + pendingUpload.length);
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Max images limit ($maxImages) reached")),
      );
      return;
    }

    if (source == ImageSource.camera) {
      // --- Single camera image ---
      final photo = await picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;

      setState(() => pendingUpload.add(photo));
    } else {
      // --- Multi-gallery selection ---
      final files = await picker.pickMultiImage();
      if (files.isEmpty) return;

      setState(() {
        pendingUpload.addAll(files.take(availableSlots));
      });
    }

    // ---- Start upload pipeline ----
    _startUploadProcess();
  }

  void _startUploadProcess() async {
    if (uploading || uploadIndex >= pendingUpload.length) return;

    uploading = true;
    setState(() {});

    final file = pendingUpload[uploadIndex];

    final fileUrl = await context.read<SchoolVisitProvider>().uploadVisitImage(
          visitId: widget.visit.id!,
          filePath: file.path,
          pickedFile: file,
        );

    if (fileUrl != null) {
      setState(() {
        uploadedUrls.add(fileUrl);

        // Remove successfully uploaded file from pending list
        pendingUpload.removeAt(uploadIndex);

        // After removal, uploadIndex should not increment
        // because next item shifts into current index.
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed. Try again.")),
      );
      uploading = false;
      return;
    }

    uploading = false;
    _startUploadProcess();
  }

  Future<void> removeImage(dynamic img) async {
    /// Server image
    if (img is String && img.startsWith("/files")) {
      final filename = img.split("/").last;

      final ok = await context.read<SchoolVisitProvider>().deleteVisitImage(
            visitId: widget.visit.id!,
            fileName: filename,
          );

      if (!ok) return;

      setState(() => uploadedUrls.remove(img));
      return;
    }

    /// Local but not uploaded
    if (img is XFile) {
      setState(() {
        pendingUpload.remove(img);

        if (uploadIndex > pendingUpload.length) {
          uploadIndex = pendingUpload.length;
        }
      });
    }
  }

  /// ---------------------- FIXED IMAGE PICK + UPLOAD  SHIPPING ----------------------

  Future<void> pickShippingImage() async {
    if (hasShippingServerImage || shippingPendingFile != null) return;

    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text("Take Photo"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text("Choose from Gallery"),
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
      setState(() {
        shippingPendingFile = null;
        shippingUploadedUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Shipping upload failed")),
      );
    }

    shippingUploading = false;
    setState(() {});
  }

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

  /// ---------------------- UI HELPERS ----------------------

  Widget editableField(
    String label,
    TextEditingController controller, {
    int lines = 1,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: lines,
          readOnly: !isEditMode,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            filled: true,
            fillColor: isEditMode ? Colors.white : Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget dropdownField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        IgnorePointer(
          ignoring: !isEditMode,
          child: DropdownButtonFormField<String>(
            value: controller.text.isEmpty ? null : controller.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: statusOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => controller.text = v ?? ""),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget toggleTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: isEditMode ? (v) => setState(() => onChanged(v)) : null,
    );
  }

  Widget sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget checkBoxIconTile({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required Widget icon,
  }) {
    return Opacity(
      opacity: isEditMode ? 1.0 : 0.6, // visual cue for disabled state
      child: IgnorePointer(
        ignoring: !isEditMode, // <-- disables interaction
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: isEditMode
                  ? (v) => setState(() => onChanged(v!))
                  : null, // <-- checkbox becomes read-only
            ),
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------------- IMAGE TILE UI ----------------------

  Widget _buildImageTile(dynamic img) {
    final isNetwork = img is String;
    final imageUrl = isNetwork ? '${ApiEndpoints.baseUrl}$img' : null;
    final localPath = !isNetwork ? img.path : null;

    return GestureDetector(
      onTap: () {
        // Only allow enlarge when NOT editing and image exists as URL
        if (!isEditMode && isNetwork) {
          _showFullscreenImage(imageUrl!);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetwork
                ? Image.network(imageUrl!,
                    width: 100, height: 100, fit: BoxFit.cover)
                : (kIsWeb
                    ? Image.network(localPath!,
                        width: 100, height: 100, fit: BoxFit.cover)
                    : Image.file(File(localPath!),
                        width: 100, height: 100, fit: BoxFit.cover)),
          ),

          // Delete button visible only in edit mode
          if (isEditMode)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => removeImage(img),
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
      ),
    );
  }

  Widget _buildShippingTile(dynamic img) {
    final isNetwork = img is String;

    // ⭐ If network image but value is empty/null → DO NOT call HTTP
    if (isNetwork && (img.isEmpty || img == "null")) {
      return _noPhotoBox();
    }

    final imageUrl = isNetwork ? '${ApiEndpoints.baseUrl}$img' : null;
    final localPath = !isNetwork ? img.path : null;

    return GestureDetector(
      onTap: () {
        if (!isEditMode && isNetwork) {
          _showFullscreenImage(imageUrl!);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetwork
                ? Image.network(
                    imageUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : (kIsWeb
                    ? Image.network(
                        localPath!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(localPath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )),
          ),

          // ❌ delete only in edit mode
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
      ),
    );
  }

  Widget _noPhotoBox() {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "No Photo",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// ---------------------- MAIN UI ----------------------
  void _showFullscreenImage(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 30,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Icon(Icons.close, size: 32, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final Map<String, TextEditingController> sharedNoteCtrls = {};
  bool savingSharedNotes = false;

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final user = context.read<UserProvider>();
    final userList = user.marketing;
    return Scaffold(
      appBar: AppBar(
        title: Text(visit.schoolProfile.name),
        actions: [
          if (context.read<SchoolVisitProvider>().currentFilter != "SHARED")
            IconButton(
              icon: Icon(isEditMode ? Icons.close : Icons.edit),
              onPressed: () => setState(() => isEditMode = !isEditMode),
            )
        ],
      ),
      floatingActionButton: isEditMode
          ? FloatingActionButton.extended(
              onPressed: save,
              label: Text("Save"),
              icon: Icon(Icons.save),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.role == "TELE_MARKETING")
            sectionCard(title: "Assign Visit To", children: [
              AbsorbPointer(
                absorbing: !isEditMode, // <-- disables tap
                child: Opacity(
                  opacity: !isEditMode ? 0.8 : 1.0, // <-- visual feedback
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Assign To",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedAssignedUserId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text("Not assigned"),
                          ),
                          ...userList.map((u) => DropdownMenuItem<String>(
                                value: u.id,
                                child: Text(u.name!),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedAssignedUserId = value;
                            selectedAssignedUserName = value == null
                                ? null
                                : userList
                                    .firstWhere((u) => u.id == value)
                                    .name!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: assignedNoteCtrl,
                        maxLines: 3,
                        readOnly: !isEditMode, // <-- blocks typing
                        decoration: const InputDecoration(
                          labelText: "Instructions / Message",
                          hintText:
                              "Write any note or instructions for assigned person",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),

          /// ---------- PHOTOS ----------
          sectionCard(title: "Photos", children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...uploadedUrls.map((url) => _buildImageTile(url)),
                ...pendingUpload.map((file) => _buildImageTile(file)),
                if (isEditMode &&
                    uploadedUrls.length + pendingUpload.length < maxImages)
                  GestureDetector(
                    onTap: pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add_a_photo, size: 30),
                    ),
                  )
              ],
            ),
          ]),

          if (visit.sharedUsers.isNotEmpty)
            sectionCard(
              title: "Shared Notes",
              children: [
                ...visit.sharedNotes.map((note) {
                  final isOwner = note.userId == widget.userId;
                  final ctrl = TextEditingController(text: note.note);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Header
                        Row(
                          children: [
                            const Icon(Icons.person, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                note.userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              note.userId,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        /// Note field
                        TextField(
                          controller: ctrl,
                          maxLines: 3,
                          readOnly: !isOwner,
                          decoration: InputDecoration(
                            hintText: "Write your note",
                            filled: true,
                            fillColor:
                                isOwner ? Colors.white : Colors.grey.shade200,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (v) {
                            if (isOwner) {
                              note.note = v;
                              note.updatedAt = DateTime.now();
                            }
                          },
                        ),

                        /// Delete (only owner)
                        if (isOwner)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text("Delete"),
                              onPressed: () {
                                setState(() {
                                  visit.sharedNotes.remove(note);
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                /// ➕ ADD NEW NOTE (ONLY IF USER DOES NOT ALREADY HAVE ONE)
                if (!visit.sharedNotes.any((n) => n.userId == widget.userId))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add My Note"),
                      onPressed: () {
                        final sharedUsers = visit.sharedUsers ?? {};

                        if (sharedUsers.containsKey(widget.userId)) {
                          final userName = sharedUsers[widget.userId]!;

                          setState(() {
                            visit.sharedNotes.add(
                              SharedUserNote(
                                userId: widget.userId,
                                userName:
                                    userName, // ✅ name from sharedUsers map
                                note: "",
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            );
                          });
                        }
                      },
                    ),
                  ),

                /// 💾 SAVE BUTTON — sends ENTIRE VISIT
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Save Shared Notes"),
                    onPressed: () async {
                      final provider = context.read<SchoolVisitProvider>();

                      await provider.addVisit(visit); // ENTIRE MODEL

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Shared notes saved successfully"),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          /// ---------- SCHOOL INFO ----------
          sectionCard(title: "School Info", children: [
            editableField("School Name", schoolCtrl, icon: Icons.school),
            editableField("Address", addressCtrl, icon: Icons.location_on),
            editableField("State", stateCtrl, icon: Icons.map),
            editableField("City", cityCtrl, icon: Icons.location_city),
            editableField("Pincode", pinCodeCtrl, icon: Icons.pin_drop),
            MiniLocationPicker(
              editable: isEditMode,
              initialLat: latValue,
              initialLong: longValue,
              onLocationPicked: (lat, long, url) async {
                latValue = lat;
                longValue = long;
                googleUrl = url;
                final parsedAddress = await context
                    .read<SchoolVisitProvider>()
                    .getAddressFromOSM(lat, long);
                addressCtrl.text = parsedAddress?.fullAddress ?? "";
                stateCtrl.text = parsedAddress?.state ?? "";
                cityCtrl.text = parsedAddress?.city ?? "";
                pinCodeCtrl.text = parsedAddress?.pinCode ?? "";
              },
            )
          ]),

          /// ---------- VISIT DETAILS ----------
          sectionCard(title: "Visit Details", children: [
            dropdownField("Status", statusCtrl, Icons.flag),
            DatePickerField(
              label: "Visit DateTime",
              controller: visitDateTimeCtrl,
              editable: isEditMode,
              showTime: true,
            ),
            DatePickerField(
              label: "Revisit DateTime",
              controller: revisitCtrl,
              editable: isEditMode,
              showTime: true,
            ),
            editableField("Notes", notesCtrl, lines: 3, icon: Icons.note),
          ]),

          /// ---------- CONTACT PERSONS ----------
          sectionCard(title: "Contact Persons", children: [
            ...contacts.asMap().entries.map((entry) {
              int index = entry.key;
              ContactPerson c = entry.value;

              // If this contact is being edited inline
              if (editingContactIndex == index) {
                newContactName.text = c.name;
                newContactRole.text = c.designation;
                newContactPhone.text = c.phone;
                newContactEmail.text = c.email;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    editableField("Name", newContactName, icon: Icons.person),
                    editableField("Designation", newContactRole,
                        icon: Icons.badge),
                    editableField("Phone", newContactPhone, icon: Icons.phone),
                    editableField("Email", newContactEmail, icon: Icons.email),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => editingContactIndex = -1),
                          child: Text("Cancel"),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.check),
                          label: Text("Update"),
                          onPressed: () {
                            setState(() {
                              contacts[index] = ContactPerson(
                                name: newContactName.text,
                                designation: newContactRole.text,
                                phone: newContactPhone.text,
                                email: newContactEmail.text,
                              );
                              editingContactIndex = -1;
                            });
                          },
                        ),
                      ],
                    )
                  ],
                );
              }

              // Display normal list item
              return ListTile(
                leading: Icon(Icons.person),
                title: Text(c.name),
                subtitle: Text("${c.designation} • ${c.phone} • ${c.email}"),
                trailing: isEditMode
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                setState(() => editingContactIndex = index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => contacts.removeAt(index)),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.phone, color: Colors.green),
                            onPressed: () => _showCallOptions(c.phone),
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.whatsapp,
                                color: Colors.green),
                            onPressed: () => _openWhatsApp(c.phone),
                          ),
                          IconButton(
                            icon: Icon(Icons.email, color: Colors.red),
                            onPressed: () => _openEmail(c.email),
                          ),
                        ],
                      ),
              );
            }),

            // ---------- Inline Add Form ----------
            if (isEditMode && addingContact) ...[
              Divider(),
              editableField("Name", newContactName, icon: Icons.person),
              editableField("Designation", newContactRole, icon: Icons.badge),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Phone",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newContactPhone,
                    keyboardType: TextInputType.phone,
                    readOnly: !isEditMode,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone),
                      filled: true,
                      fillColor:
                          isEditMode ? Colors.white : Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              editableField("Email", newContactEmail, icon: Icons.email),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      addingContact = false;
                      newContactName.clear();
                      newContactRole.clear();
                      newContactPhone.clear();
                      newContactEmail.clear();
                      setState(() {});
                    },
                    child: Text("Cancel"),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.check),
                    label: Text("Save"),
                    onPressed: () {
                      contacts.add(ContactPerson(
                        name: newContactName.text,
                        designation: newContactRole.text,
                        phone: newContactPhone.text,
                        email: newContactEmail.text,
                      ));

                      addingContact = false;
                      newContactName.clear();
                      newContactRole.clear();
                      newContactPhone.clear();
                      newContactEmail.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],

            if (isEditMode && !addingContact)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Add Contact"),
                  onPressed: () {
                    editingContactIndex = -1; // Prevent edit + add conflict
                    setState(() => addingContact = true);
                  },
                ),
              ),
          ]),

          /// ---------- REQUIRED PRODUCTS ----------
          sectionCard(title: "Required Products", children: [
            ...products.asMap().entries.map((entry) {
              int index = entry.key;
              ProductRequest p = entry.value;

              // -------- Inline edit mode --------
              if (editingProductIndex == index && isEditMode) {
                selectedEditProduct = p.name;
                selectedEditType = null;
                newProductQty.text = p.quantity.toString();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Product",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),

                    /// PRODUCT DROPDOWN
                    DropdownButtonFormField<String>(
                      value: selectedEditProduct,
                      items: availableProducts
                          .map((e) => DropdownMenuItem(
                              value: e.name, child: Text(e.name)))
                          .toList(),
                      onChanged: (v) {
                        selectedEditProduct = v;
                        selectedEditType = null;
                        setState(() {});
                      },
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 10),

                    /// TYPE DROPDOWN
                    const Text("Type",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedEditType,
                      items: (selectedEditProduct != null
                              ? productTypeMap[selectedEditProduct] ?? []
                              : [])
                          .map<DropdownMenuItem<String>>(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(t),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedEditType = v),
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 10),

                    /// QTY
                    editableField("Quantity", newProductQty,
                        icon: Icons.format_list_numbered),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => editingProductIndex = -1),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text("Update"),
                          onPressed: () {
                            if (selectedEditProduct == null ||
                                selectedEditType == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Select product & type")),
                              );
                              return;
                            }

                            setState(() {
                              products[index] = ProductRequest(
                                productId: p.productId,
                                name:
                                    selectedEditProduct!, // <-- keep clean name
                                quantity: int.tryParse(newProductQty.text) ?? 1,
                              );
                              editingProductIndex = -1;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }

              // -------- Display normal tile --------
              return ListTile(
                leading: const Icon(Icons.inventory_outlined),
                title: Text(p.name),
                subtitle: Text("Qty: ${p.quantity}"),
                trailing: isEditMode
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                setState(() => editingProductIndex = index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => products.removeAt(index)),
                          )
                        ],
                      )
                    : null,
              );
            }),

            // ---------- Inline new product entry ----------
            if (addingProduct && isEditMode) ...[
              const Divider(),

              /// Product Dropdown
              DropdownButtonFormField<String>(
                value: selectedNewProduct,
                decoration: const InputDecoration(
                  labelText: "Select Product",
                  border: OutlineInputBorder(),
                ),
                items: availableProducts
                    .map((p) => DropdownMenuItem<String>(
                          value: p.name,
                          child: Text(p.name),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedNewProduct = v;
                    selectedNewType = null; // reset type when product changes
                  });
                },
              ),

              const SizedBox(height: 10),

              /// Type Dropdown
              DropdownButtonFormField<String>(
                value: selectedNewType,
                decoration: const InputDecoration(
                  labelText: "Select Type",
                  border: OutlineInputBorder(),
                ),
                items: (selectedNewProduct != null
                        ? (availableProducts
                                .firstWhere(
                                  (e) => e.name == selectedNewProduct,
                                  orElse: () => ProductOption(
                                      name: "", types: [], id: ''),
                                )
                                .types ??
                            [])
                        : [])
                    .map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedNewType = v),
              ),

              const SizedBox(height: 10),

              /// Quantity
              TextField(
                controller: newProductQty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      addingProduct = false;
                      selectedNewProduct = null;
                      selectedNewType = null;
                      newProductQty.clear();
                      setState(() {});
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Save"),
                    onPressed: () {
                      if (selectedNewProduct == null ||
                          selectedNewType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Select product & type")),
                        );
                        return;
                      }

                      products.add(
                        ProductRequest(
                          productId:
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          name: "$selectedNewProduct ($selectedNewType)",
                          quantity: int.tryParse(newProductQty.text) ?? 1,
                        ),
                      );

                      addingProduct = false;
                      selectedNewProduct = null;
                      selectedNewType = null;
                      newProductQty.clear();

                      setState(() {});
                    },
                  ),
                ],
              ),
            ],

            // ---------- Add button ----------
            if (isEditMode && !addingProduct)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Product"),
                  onPressed: () {
                    editingProductIndex = -1; // prevent conflict
                    setState(() => addingProduct = true);
                  },
                ),
              )
          ]),

          /// ---------- PROPOSAL ----------
          sectionCard(title: "Proposal Checklist", children: [
            toggleTile("Proposal Sent", proposalSent, (v) => proposalSent = v),
            toggleTile(
                "Approved", proposalApproved, (v) => proposalApproved = v),
            checkBoxIconTile(
              label: "Email Sent",
              value: emailSent,
              onChanged: (v) => emailSent = v,
              icon: const Icon(
                Icons.email,
                color: Colors.blue,
              ),
            ),
            checkBoxIconTile(
              label: "WhatsApp Sent",
              value: whatsappSent,
              onChanged: (v) => whatsappSent = v,
              icon: FaIcon(FontAwesomeIcons.whatsapp,
                  color: Colors.green), // OR FontAwesomeIcons.whatsapp
            ),
            editableField("Remarks", proposalRemarksCtrl,
                lines: 2, icon: Icons.comment),
          ]),

          /// ---------- PO ----------
          sectionCard(title: "Purchase Order", children: [
            toggleTile("PO Received", poReceived, (v) => poReceived = v),
            editableField("PO Number", poNumberCtrl, icon: Icons.numbers),
            DatePickerField(
              label: "PO Date",
              controller: poDateCtrl,
              editable: isEditMode,
            ),
          ]),

          /// ---------- LAB INFO ----------
          sectionCard(title: "Lab Information", children: [
            editableField("Setup Type", setupTypeCtrl, icon: Icons.memory),
            editableField("Processor", processorCtrl, icon: Icons.computer),
            editableField("RAM", ramCtrl, icon: Icons.memory),
            editableField("Storage Type", storageTypeCtrl,
                icon: Icons.sd_storage),
            editableField("Storage Size", storageSizeCtrl, icon: Icons.storage),
          ]),

          /// ---------- SHIPPING ----------
          sectionCard(title: "Shipping Details", children: [
            /// NEW
            editableField("Shipping Number", shippingNumberCtrl,
                icon: Icons.local_shipping),
            editableField("Contact Number", shippingContactCtrl,
                icon: Icons.phone),
            SwitchListTile(
              title: const Text("Passed To Installation"),
              value: passedToNextRole,
              onChanged: isEditMode
                  ? (v) => setState(() => passedToNextRole = v)
                  : null,
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

            /// ⭐ OPTIONAL — If you will show shipping photo thumbnail
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                /// SERVER PHOTO (only when actually valid)
                if (hasShippingServerImage)
                  _buildShippingTile(shippingUploadedUrl),

                /// LOCAL PENDING FILE
                if (shippingPendingFile != null)
                  _buildShippingTile(shippingPendingFile),

                /// VIEW MODE → Show NO PHOTO
                if (!isEditMode &&
                    !hasShippingServerImage &&
                    shippingPendingFile == null)
                  _noPhotoBox(),

                /// EDIT MODE → Show ADD BUTTON
                if (isEditMode &&
                    !hasShippingServerImage &&
                    shippingPendingFile == null)
                  GestureDetector(
                    onTap: pickShippingImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_a_photo, size: 30),
                    ),
                  ),
              ],
            ),

            editableField("Address", shippingAddressCtrl,
                icon: Icons.location_on),
            editableField("City", shippingCityCtrl, icon: Icons.location_city),
            editableField("State", shippingStateCtrl, icon: Icons.map),
            editableField("Country", shippingCountryCtrl, icon: Icons.public),
            editableField("Pincode", shippingPinCtrl, icon: Icons.pin_drop),
          ]),

          /// ---------- PAYMENT ----------
          sectionCard(title: "Payment", children: [
            toggleTile("Advance Transferred", advanceTransferred,
                (v) => advanceTransferred = v),
            editableField("Amount", paymentAmountCtrl,
                icon: Icons.currency_rupee),
            editableField("Transaction ID", paymentTxnCtrl,
                icon: Icons.receipt),
            paymentStatusReadOnly(),
            if (widget.visit.payment.transferDate != null &&
                widget.visit.payment.transferDate!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "Received On: ${widget.visit.payment.transferDate}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ]),

          sectionCard(title: "Other Requirements", children: [
            editableField("Notes", otherRequirementsCtrl,
                lines: 3, icon: Icons.notes),
          ]),
        ],
      ),
    );
  }

  /// ---------------------- SAVE ----------------------
  Future<void> save() async {
    final provider = context.read<SchoolVisitProvider>();
    final old = widget.visit;

    final updatedVisit = SchoolVisit(
      id: old.id,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      createdByUserId: old.createdByUserId,
      createdByUserName: old.createdByUserName,
      adminName: old.adminName,
      adminId: old.adminId,
      assignedUserId: selectedAssignedUserId,
      assignedUserName: selectedAssignedUserName,
      schoolProfile: SchoolProfile(
        name: schoolCtrl.text,
        googleMapLink: googleUrl ?? "",
        photoUrl: uploadedUrls,
        latitude: latValue!,
        longitude: longValue!,
        address: addressCtrl.text,
        state: stateCtrl.text,
        city: cityCtrl.text,
        pinCode: pinCodeCtrl.text,
      ),
      visitDetails: VisitDetails(
        status: statusCtrl.text,
        visitDate: old.visitDetails.visitDate,
        revisitDate: revisitCtrl.text,
        statusNotes: notesCtrl.text,
      ),
      proposalChecklist: ProposalChecklist(
        sent: proposalSent,
        approved: proposalApproved,
        whatsapp: whatsappSent,
        email: emailSent,
        remarks: proposalRemarksCtrl.text,
      ),
      purchaseOrder: PurchaseOrder(
        poReceived: poReceived,
        poNumber: poNumberCtrl.text,
        poDate: poDateCtrl.text,
      ),
      requiredProducts: products,
      labInformation: LabInformation(
        setupType: setupTypeCtrl.text,
        pcConfig: PCConfig(
          processor: processorCtrl.text,
          ram: ramCtrl.text,
          storageType: storageTypeCtrl.text,
          storageSize: storageSizeCtrl.text,
        ),
      ),
      shippingDetails: ShippingDetails(
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
      ),
      payment: Payment(
        advanceTransferred: advanceTransferred,
        amount: double.tryParse(paymentAmountCtrl.text) ?? 0,
        transactionId: paymentTxnCtrl.text,
        transferDate: old.payment.transferDate,
        paymentConfirmed: paymentConfirmed,
      ),
      contactPersons: contacts,
      otherRequirements: otherRequirementsCtrl.text,
      installationChecklist: old.installationChecklist,
    );

    await provider.updateVisit(updatedVisit);

    setState(() => isEditMode = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Updated Successfully")),
    );
  }
}
