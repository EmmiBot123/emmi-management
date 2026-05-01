import 'dart:io';

import 'package:qubiq_os/Providers/User_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../Model/Marketing/LabInformation.dart';
import '../../../../Model/Marketing/Payment.dart';
import '../../../../Model/Marketing/ProposalChecklist.dart';
import '../../../../Model/Marketing/PurchaseOrder.dart';
import '../../../../Model/Marketing/School_profile_model.dart';
import '../../../../Model/Marketing/ShippingDetails.dart';
import '../../../../Model/Marketing/VisitDetails.dart';
import '../../../../Model/Marketing/school_visit_model.dart';
import '../../../../Model/Marketing/ProductRequest.dart';
import '../../../../Model/Marketing/ContactPerson.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../Model/User_model.dart';

import '../../../../Providers/Marketing/SchoolVisitProvider.dart';
import 'package:uuid/uuid.dart';

import '../../../Model/productDetails/ProductOption.dart';
import '../Resusable/date_picker_field.dart';
import 'MapPicker.dart';

class AddVisitPage extends StatefulWidget {
  final String userId;
  final String name;
  final String role; // <-- add this

  const AddVisitPage({
    super.key,
    required this.userId,
    required this.name,
    required this.role, // <-- add this
  });

  @override
  State<AddVisitPage> createState() => _AddVisitPageState();
}

class _AddVisitPageState extends State<AddVisitPage> {
  UserModel? admin;

  void _load() async {
    print("AddVisitPage: Loading admin profile for userId: ${widget.userId}");
    try {
      admin = await context.read<UserProvider>().loadAdmin(widget.userId);
    } catch (e) {
      print("Error loading admin: $e");
    } finally {
      if (mounted) {
        setState(() => loadingAdmin = false);
      }
    }
  }

  final _formKey = GlobalKey<FormState>();

  // ---------- Text Controllers ----------

  final schoolCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final pinCodeCtrl = TextEditingController();
  final statusCtrl = TextEditingController(text: "Planned");
  final revisitCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final proposalRemarksCtrl = TextEditingController();
  final poNumberCtrl = TextEditingController();
  final poDateCtrl = TextEditingController();
  final TextEditingController shippingNumberCtrl = TextEditingController();
  final TextEditingController shippingContactCtrl = TextEditingController();
  final TextEditingController shippingPhotoUrlCtrl = TextEditingController();

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

  final setupTypeCtrl = TextEditingController();
  final processorCtrl = TextEditingController();
  final ramCtrl = TextEditingController();
  final storageTypeCtrl = TextEditingController();
  final storageSizeCtrl = TextEditingController();

  final shippingAddressCtrl = TextEditingController();
  final shippingCityCtrl = TextEditingController();
  final shippingStateCtrl = TextEditingController();
  final shippingCountryCtrl = TextEditingController();
  final shippingPinCtrl = TextEditingController();
  final visitDateTimeCtrl = TextEditingController();
  final paymentAmountCtrl = TextEditingController();
  final paymentTxnCtrl = TextEditingController();

  final otherRequirementsCtrl = TextEditingController();

  // ---------- Dynamic Lists ----------

  List<ContactPerson> contacts = [];
  List<ProductRequest> products = [];

  List<XFile> selectedImages = [];
  List<String> uploadedUrls = [];
  int uploadedCount = 0;
  final int maxImages = 6;
  final int minImages = 1;
  bool uploading = false;

  List<ProductOption> availableProducts = [];
  Map<String, List<String>> productTypeMap = {};

  String? selectedNewProduct;
  String? selectedNewType;

  // ---------- Inline Form Controls ----------

  bool addingContact = false;
  bool addingProduct = false;

  int editingContactIndex = -1;
  int editingProductIndex = -1;

  final newContactName = TextEditingController();
  final newContactRole = TextEditingController();
  final newContactPhone = TextEditingController();
  final newContactEmail = TextEditingController();

  final newProductName = TextEditingController();
  final newProductQty = TextEditingController();

  final assignedNoteCtrl = TextEditingController();

  final uuid = Uuid();
  late String id;

  // ---------- Switches ----------

  bool proposalSent = false;
  bool proposalApproved = false;
  bool poReceived = false;
  bool advanceTransferred = false;
  bool paymentConfirmed = false;

  bool emailSent = false;
  bool whatsappSent = false;

  bool submitting = false;
  String? selectedLocation;
  String? selectedState;
  String? selectedCity;
  double? latitude;
  double? longitude;

  String? selectedAssignedUserId;
  String? selectedAssignedUserName;

  XFile? shippingImage;
  String? shippingUploadedUrl;
  bool shippingUploading = false;

  // ---------- SAVE ----------
  bool loadingAdmin = true;
  @override
  void initState() {
    super.initState();
    _load();
    loadProductOptions();

    id = uuid.v4(); // store the id once for this visit
    // Set default value from list
    statusCtrl.text = statusOptions[0];
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

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    if (loadingAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please wait, loading admin profile...")),
      );
      return;
    }

    /*
    if (admin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Failed to load admin profile. Please go back and try again.")),
      );
      // return;
    }
    */

    setState(() => submitting = true);
    final visit = SchoolVisit(
      id: id,
      createdAt: DateTime.now(),
      createdByUserId: widget.userId,
      createdByUserName: widget.name,
      adminId: admin?.createdById,
      adminName: admin?.createdByName,
      schoolProfile: SchoolProfile(
        name: schoolCtrl.text.trim(),
        googleMapLink: selectedLocation ?? "N/A",
        latitude: latitude ?? 0,
        longitude: longitude ?? 0,
        photoUrl: uploadedUrls,
        address: addressCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        pinCode: pinCodeCtrl.text.trim(),
      ),
      visitDetails: VisitDetails(
        status: statusCtrl.text.trim(),
        visitDate: visitDateTimeCtrl.text.trim(),
        revisitDate: revisitCtrl.text.trim(),
        statusNotes: notesCtrl.text.trim(),
      ),
      proposalChecklist: ProposalChecklist(
        sent: proposalSent,
        approved: proposalApproved,
        whatsapp: whatsappSent,
        email: emailSent,
        remarks: proposalRemarksCtrl.text.trim(),
      ),
      purchaseOrder: PurchaseOrder(
        poReceived: poReceived,
        poNumber: poNumberCtrl.text.trim(),
        poDate: poDateCtrl.text.trim(),
      ),
      payment: Payment(
        advanceTransferred: advanceTransferred,
        amount: double.tryParse(paymentAmountCtrl.text) ?? 0,
        transactionId: paymentTxnCtrl.text.trim(),
        paymentConfirmed: paymentConfirmed,
      ),
      shippingDetails: ShippingDetails(
        address: shippingAddressCtrl.text.trim(),
        city: shippingCityCtrl.text.trim(),
        state: shippingStateCtrl.text.trim(),
        country: shippingCountryCtrl.text.trim(),
        pinCode: shippingPinCtrl.text.trim(),
        shippingNumber: shippingNumberCtrl.text.trim(),
        contactNumber: shippingContactCtrl.text.trim(),
        photoUrl: shippingUploadedUrl ?? "",
      ),
      labInformation: LabInformation(
        setupType: setupTypeCtrl.text.trim(),
        pcConfig: PCConfig(
          processor: processorCtrl.text.trim(),
          ram: ramCtrl.text.trim(),
          storageSize: storageSizeCtrl.text.trim(),
          storageType: storageTypeCtrl.text.trim(),
        ),
      ),
      requiredProducts: products,
      contactPersons: contacts,
      otherRequirements: otherRequirementsCtrl.text.trim(),
      assignedUserId: selectedAssignedUserId,
      assignedUserName: selectedAssignedUserName,
      installationChecklist: [],
    );

    final ok = await context.read<SchoolVisitProvider>().addVisit(visit);

    if (!mounted) return;
    setState(() => submitting = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visit Added Successfully")),
      );
    }
  }

  Future<void> save2() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => submitting = true);

    final visit = SchoolVisit(
      id: id,
      createdAt: DateTime.now(),
      createdByUserId: widget.userId,
      createdByUserName: widget.name,
      adminId: admin!.id,
      adminName: admin!.name,
      schoolProfile: SchoolProfile(
        name: schoolCtrl.text.trim(),
        googleMapLink: selectedLocation ?? "N/A",
        latitude: latitude ?? 0,
        longitude: longitude ?? 0,
        photoUrl: uploadedUrls,
        address: addressCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        pinCode: pinCodeCtrl.text.trim(),
      ),
      visitDetails: VisitDetails(
        status: statusCtrl.text.trim(),
        visitDate: visitDateTimeCtrl.text.trim(),
        revisitDate: revisitCtrl.text.trim(),
        statusNotes: notesCtrl.text.trim(),
      ),
      proposalChecklist: ProposalChecklist(
        sent: proposalSent,
        approved: proposalApproved,
        whatsapp: whatsappSent,
        email: emailSent,
        remarks: proposalRemarksCtrl.text.trim(),
      ),
      purchaseOrder: PurchaseOrder(
        poReceived: poReceived,
        poNumber: poNumberCtrl.text.trim(),
        poDate: poDateCtrl.text.trim(),
      ),
      payment: Payment(
        advanceTransferred: advanceTransferred,
        amount: double.tryParse(paymentAmountCtrl.text) ?? 0,
        transactionId: paymentTxnCtrl.text.trim(),
        paymentConfirmed: paymentConfirmed,
      ),
      shippingDetails: ShippingDetails(
        address: shippingAddressCtrl.text.trim(),
        city: shippingCityCtrl.text.trim(),
        state: shippingStateCtrl.text.trim(),
        country: shippingCountryCtrl.text.trim(),
        pinCode: shippingPinCtrl.text.trim(),
        shippingNumber: shippingNumberCtrl.text.trim(),
        contactNumber: shippingContactCtrl.text.trim(),
        photoUrl: shippingUploadedUrl ?? "",
      ),
      labInformation: LabInformation(
        setupType: setupTypeCtrl.text.trim(),
        pcConfig: PCConfig(
          processor: processorCtrl.text.trim(),
          ram: ramCtrl.text.trim(),
          storageSize: storageSizeCtrl.text.trim(),
          storageType: storageTypeCtrl.text.trim(),
        ),
      ),
      requiredProducts: products,
      contactPersons: contacts,
      otherRequirements: otherRequirementsCtrl.text.trim(),
      installationChecklist: [],
    );

    final ok = await context.read<SchoolVisitProvider>().addVisit(visit);

    if (!mounted) return;
    setState(() => submitting = false);
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => SizedBox(
        height: 150,
        child: Column(
          children: [
            const SizedBox(height: 10),
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
      ),
    );

    if (source == null) return;

    if (source == ImageSource.camera) {
      final photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() => selectedImages.add(photo));
        uploadNext();
      }
    } else {
      final files = await picker.pickMultiImage();

      if (files.isEmpty) return;

      final allowedCount = maxImages - selectedImages.length;
      final newFiles = files.take(allowedCount).toList();

      setState(() => selectedImages.addAll(newFiles));

      uploadNext();
    }
  }

  Future<void> uploadNext() async {
    if (uploading) return;
    if (uploadedCount >= selectedImages.length) return;

    uploading = true;
    setState(() {});

    final img = selectedImages[uploadedCount];

    final fileUrl = await context.read<SchoolVisitProvider>().uploadVisitImage(
          visitId: id,
          filePath: img.path,
          pickedFile: img, // <-- important for web upload
        );

    if (fileUrl != null) {
      uploadedUrls.add(fileUrl); // <-- store URL
      uploadedCount++;
    } else {
      // ---- FAILURE ----

      // Clear saved URLs since process failed
      uploadedUrls.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Upload failed. All uploaded files discarded.")),
      );

      uploading = false;
      if (!mounted) return;
      setState(() {});
      return; // STOP UPLOADING
    }

    uploading = false;
    setState(() {});

    // Continue automatically if more images remain
    if (uploadedCount < selectedImages.length) {
      uploadNext();
    }
  }

  Future<void> pickShippingImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => SizedBox(
        height: 150,
        child: Column(
          children: [
            const SizedBox(height: 10),
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
      ),
    );

    if (source == null) return;

    final photo = await picker.pickImage(source: source);
    if (photo == null) return;

    setState(() {
      shippingImage = photo;
    });

    await uploadShippingImage();
  }

  Future<void> uploadShippingImage() async {
    if (shippingImage == null) return;
    if (shippingUploading) return;

    shippingUploading = true;
    setState(() {});

    final url = await context.read<SchoolVisitProvider>().uploadVisitImage(
          visitId: id,
          filePath: shippingImage!.path,
          pickedFile: shippingImage!, // web compatibility
        );

    if (url != null) {
      shippingUploadedUrl = url;
    } else {
      shippingUploadedUrl = null;
      shippingImage = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shipping image upload failed.")),
      );
    }

    shippingUploading = false;
    if (!mounted) return;
    setState(() {});
  }

  Widget buildUploadProgress() {
    if (selectedImages.isEmpty) {
      return const Text("Add at least 2 photos.");
    }

    final double progress =
        selectedImages.isEmpty ? 0 : uploadedCount / selectedImages.length;

    final showCheck =
        uploadedCount == selectedImages.length && uploadedCount >= minImages;

    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress == 0 ? null : progress, // null shows spinner
                strokeWidth: 7,
              ),
              showCheck
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 40)
                  : Text(
                      "${(progress * 100).floor()}%",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text("$uploadedCount / ${selectedImages.length} Uploaded"),
      ],
    );
  }

  // ---------- UI Helper Components ----------
  Widget dropdownField(
      String label, TextEditingController controller, IconData? icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonFormField<String>(
            value: controller.text.isEmpty ? null : controller.text,
            decoration: const InputDecoration(border: InputBorder.none),
            icon: const Icon(Icons.arrow_drop_down),
            hint: const Text("Select Status"),
            items: statusOptions.map((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (v) {
              setState(() => controller.text = v ?? "");
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget editableField(String label, TextEditingController ctrl,
      {IconData? icon, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: lines,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget sectionCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget toggleTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (v) => setState(() => onChanged(v)),
    );
  }

  Widget checkBoxIconTile({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required Widget icon, // <-- Updated: Widget instead of IconData
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => setState(() => onChanged(v!)),
        ),
        icon, // <-- Works with FaIcon, Image, Icon, anything
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  // ---------- BUILD UI ----------

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>();
    final userList = user.marketing;
    return Scaffold(
      appBar: AppBar(title: const Text("Add Visit")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submitting ? null : save,
        icon: const Icon(Icons.save),
        label: Text(submitting ? "Saving..." : "Save"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.role == "TELE_MARKETING")
              sectionCard("Assign Visit To", [
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
                          : userList.firstWhere((u) => u.id == value).name!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: assignedNoteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Instructions / Message",
                    hintText:
                        "Write any note or instructions for assigned person",
                    border: OutlineInputBorder(),
                  ),
                ),
              ]),

            sectionCard("Photos", [
              buildUploadProgress(),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ...selectedImages.map((img) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // IMAGE PREVIEW
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.network(
                                  img.path,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(img.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                        ),

                        // REMOVE BUTTON
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () async {
                              final originalName =
                                  img.name; // example: "sapce.png"

                              // Find matching stored filename from uploaded server URLs
                              final storedFileName = uploadedUrls
                                  .map((url) => url.split("/").last)
                                  .firstWhere(
                                    (name) => name.endsWith(originalName),
                                    orElse: () => "",
                                  );

                              if (storedFileName.isNotEmpty) {
                                // Call provider to delete from server
                                final ok = await context
                                    .read<SchoolVisitProvider>()
                                    .deleteVisitImage(
                                      visitId: id,
                                      fileName: storedFileName,
                                    );

                                if (!mounted) return;

                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Failed to delete $storedFileName from server")),
                                  );
                                  return; // STOP here if backend delete fails
                                }

                                // Remove from uploaded URL list
                                uploadedUrls.removeWhere(
                                    (url) => url.endsWith(originalName));

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Removed $storedFileName")),
                                );
                                uploadedCount = uploadedUrls.length;
                              }

                              // Always remove locally afterward
                              setState(() {
                                selectedImages.remove(img);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  // ADD IMAGE BUTTON (Only if below max limit)
                  if (selectedImages.length < maxImages)
                    GestureDetector(
                      onTap: pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Icon(Icons.add_a_photo, size: 32),
                      ),
                    ),
                ],
              ),
            ]),

            // ---------- SCHOOL INFORMATION ----------

            sectionCard("School Info", [
              editableField("School Name", schoolCtrl, icon: Icons.school),
              editableField("Address", addressCtrl,
                  icon: Icons.location_on_outlined),
              editableField("State", stateCtrl, icon: Icons.map_outlined),
              editableField("City", cityCtrl,
                  icon: Icons.location_city_outlined),
              editableField("Pin Code", pinCodeCtrl,
                  icon: Icons.pin_drop_outlined),
              MiniLocationPicker(
                editable: true,
                onLocationPicked: (lat, long, url) async {
                  latitude = lat;
                  longitude = long;
                  selectedLocation = url;
                  final parsedAddress = await context
                      .read<SchoolVisitProvider>()
                      .getAddressFromOSM(lat, long);
                  addressCtrl.text = parsedAddress?.fullAddress ?? "";
                  stateCtrl.text = parsedAddress?.state ?? "";
                  cityCtrl.text = parsedAddress?.city ?? "";
                  pinCodeCtrl.text = parsedAddress?.pinCode ?? "";
                  visitDateTimeCtrl.text =
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
                },
              ),
            ]),

            // ---------- VISIT DETAILS ----------
            sectionCard("Visit Details", [
              dropdownField("Status", statusCtrl, Icons.flag),
              DatePickerField(
                label: "Visit DateTime",
                controller: visitDateTimeCtrl,
                editable: true,
                showTime: true,
              ),
              DatePickerField(
                label: "Revisit DateTime",
                controller: revisitCtrl,
                editable: true,
                showTime: true,
              ),
              editableField("Notes", notesCtrl, icon: Icons.note_alt, lines: 3),
            ]),

            // ---------- CONTACT PERSONS ----------
            sectionCard("Contact Persons", [
              ...contacts.asMap().entries.map((entry) {
                int index = entry.key;
                ContactPerson c = entry.value;

                if (editingContactIndex == index) {
                  newContactName.text = c.name;
                  newContactRole.text = c.designation;
                  newContactPhone.text = c.phone;
                  newContactEmail.text = c.email;

                  return Column(
                    children: [
                      editableField("Name", newContactName, icon: Icons.person),
                      editableField("Designation", newContactRole,
                          icon: Icons.badge),
                      editableField("Phone", newContactPhone,
                          icon: Icons.phone),
                      editableField("Email", newContactEmail,
                          icon: Icons.email),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () =>
                                  setState(() => editingContactIndex = -1),
                              child: const Text("Cancel")),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Update"),
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

                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(c.name),
                  subtitle: Text("${c.designation} • ${c.phone} • ${c.email}",
                      maxLines: 2),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              setState(() => editingContactIndex = index)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => contacts.removeAt(index))),
                    ],
                  ),
                );
              }),
              if (addingContact) ...[
                const Divider(),
                editableField("Name", newContactName, icon: Icons.person),
                editableField("Designation", newContactRole, icon: Icons.badge),
                editableField("Phone", newContactPhone, icon: Icons.phone),
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
                        child: const Text("Cancel")),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Save"),
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
                        save2();
                        setState(() {});
                      },
                    ),
                  ],
                )
              ],
              if (!addingContact)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Contact"),
                      onPressed: () {
                        editingContactIndex = -1;
                        setState(() => addingContact = true);
                      }),
                ),
            ]),

            // ---------- REQUIRED PRODUCTS ----------
            sectionCard("Required Products", [
              ...products.asMap().entries.map((entry) {
                int index = entry.key;
                ProductRequest p = entry.value;

                if (editingProductIndex == index) {
                  newProductName.text = p.name;
                  newProductQty.text = p.quantity.toString();

                  return Column(
                    children: [
                      editableField("Quantity", newProductQty,
                          icon: Icons.format_list_numbered),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () =>
                                  setState(() => editingProductIndex = -1),
                              child: const Text("Cancel")),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text("Update"),
                            onPressed: () {
                              setState(() {
                                products[index] = ProductRequest(
                                  productId: p.productId,
                                  name: newProductName.text,
                                  quantity:
                                      int.tryParse(newProductQty.text) ?? 1,
                                );
                                editingProductIndex = -1;
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  );
                }

                return ListTile(
                  leading: const Icon(Icons.inventory_outlined),
                  title: Text(p.name),
                  subtitle: Text("Qty: ${p.quantity}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              setState(() => editingProductIndex = index)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => products.removeAt(index))),
                    ],
                  ),
                );
              }),
              if (addingProduct) ...[
                const Divider(),

                /// PRODUCT DROPDOWN
                const Text(
                  "Product",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedNewProduct,
                  decoration: const InputDecoration(
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

                /// TYPE DROPDOWN
                const Text(
                  "Type",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedNewType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: (selectedNewProduct != null
                          ? productTypeMap[selectedNewProduct] ?? []
                          : [])
                      .map<DropdownMenuItem<String>>(
                        (t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedNewType = v),
                ),

                const SizedBox(height: 10),

                /// QUANTITY
                editableField(
                  "Quantity",
                  newProductQty,
                  icon: Icons.format_list_numbered,
                ),

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
                              content: Text("Select product & type"),
                            ),
                          );
                          return;
                        }

                        products.add(
                          ProductRequest(
                            productId: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
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
              if (!addingProduct)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Product"),
                      onPressed: () {
                        editingProductIndex = -1;
                        setState(() => addingProduct = true);
                      }),
                ),
            ]),

            // ---------- OTHER SECTIONS ----------
            sectionCard("Proposal Checklist", [
              toggleTile(
                  "Proposal Sent", proposalSent, (v) => proposalSent = v),
              toggleTile(
                  "Approved", proposalApproved, (v) => proposalApproved = v),

              // --- Checkbox with Icons ---
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
                  icon: Icons.comment),
            ]),

            sectionCard("Purchase Order", [
              toggleTile("PO Received", poReceived, (v) => poReceived = v),
              editableField("PO Number", poNumberCtrl, icon: Icons.numbers),
              DatePickerField(
                label: "PO Date",
                controller: poDateCtrl,
                editable: true,
              ),
            ]),

            sectionCard("Lab Information", [
              editableField("Setup Type", setupTypeCtrl, icon: Icons.computer),
              editableField("Processor", processorCtrl, icon: Icons.memory),
              editableField("RAM", ramCtrl, icon: Icons.speed),
              editableField("Storage Type", storageTypeCtrl,
                  icon: Icons.storage),
              editableField("Storage Size", storageSizeCtrl,
                  icon: Icons.sd_storage),
            ]),

            sectionCard(
              "Shipping Details",
              [
                editableField("Shipping Number", shippingNumberCtrl,
                    icon: Icons.local_shipping),
                editableField("Contact Number", shippingContactCtrl,
                    icon: Icons.phone),
                if (shippingUploading) buildUploadProgress(),
                const SizedBox(height: 10),
                Wrap(
                  children: [
                    if (shippingImage != null)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    shippingImage!.path,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(shippingImage!.path),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () async {
                                // Optional: delete from server using filename
                                // await provider.deleteShippingPhoto(...);

                                setState(() {
                                  shippingImage = null;
                                  shippingUploadedUrl = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (shippingImage == null)
                      GestureDetector(
                        onTap: pickShippingImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.add_a_photo, size: 32),
                        ),
                      ),
                  ],
                ),
                editableField("Address", shippingAddressCtrl,
                    icon: Icons.location_on),
                editableField("City", shippingCityCtrl,
                    icon: Icons.location_city),
                editableField("State", shippingStateCtrl, icon: Icons.map),
                editableField("Country", shippingCountryCtrl,
                    icon: Icons.public),
                editableField("Pincode", shippingPinCtrl, icon: Icons.pin),
              ],
            ),

            sectionCard("Payment", [
              toggleTile("Advance Transferred", advanceTransferred,
                  (v) => advanceTransferred = v),
              editableField("Amount", paymentAmountCtrl,
                  icon: Icons.currency_rupee),
              editableField("Transaction ID", paymentTxnCtrl,
                  icon: Icons.receipt_long),
            ]),

            sectionCard("Other Requirements", [
              editableField("Notes", otherRequirementsCtrl,
                  icon: Icons.assignment, lines: 3),
            ]),
          ],
        ),
      ),
    );
  }
}
