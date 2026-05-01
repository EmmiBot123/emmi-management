import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../Model/Marketing/ProductRequest.dart';
import '../../../../Model/Marketing/school_visit_model.dart';
import '../../../Model/productDetails/SerialAssignment.dart';
import '../../../Model/productDetails/SerialEntry.dart';
import '../../../Model/productDetails/SerialProduct.dart';
import '../../../Resources/theme_constants.dart';

import '../../Providers/Marketing/SchoolVisitProvider.dart';
import 'sections/ImeiUploadPage.dart';
import 'sections/InstallationChecklistPage.dart';
import 'sections/assembly_stock_update_page.dart';
import 'sections/photos_page.dart';
import 'sections/qc_page.dart';
import 'sections/school_info_page.dart';
import 'sections/serial_generator_page.dart';
import 'sections/shipping_page.dart';

class VisitDetailsPage extends StatefulWidget {
  final SchoolVisit visit;

  const VisitDetailsPage({
    super.key,
    required this.visit,
  });

  @override
  State<VisitDetailsPage> createState() => _VisitDetailsPageState();
}

class _VisitDetailsPageState extends State<VisitDetailsPage> {
  late TextEditingController schoolCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController pinCodeCtrl;

  late List<String> uploadedUrls;
  List<XFile> pendingUpload = [];
  late List<ProductRequest> products;

  double? latValue;
  double? longValue;

  Map<String, List<String>> productSerialMap = {};
  Map<String, TextEditingController> formatControllers = {};

  bool serialSaved = false;
  SerialAssignment? existingAssignment;
  Map<String, Set<String>> qcCompleted = {};

  /// ---------- UTIL ----------
  String normalizeProductKey(String name) => name.trim().toUpperCase();

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

    products = List.from(v.requiredProducts);

    for (var p in products) {
      final k = normalizeProductKey(p.name);
      productSerialMap[k] = [];
      formatControllers[k] = TextEditingController();
      qcCompleted[k] = {};
    }

    loadExistingSerials();
  }

  Future<void> loadExistingSerials() async {
    final data = await context
        .read<SchoolVisitProvider>()
        .getSerialAssignmentByVisit(widget.visit.id!);

    if (data == null) return;

    existingAssignment = data;
    serialSaved = true;

    for (var p in data.products) {
      final key = normalizeProductKey(p.productName);
      productSerialMap[key] = p.serials.map((e) => e.serial).toList();
      formatControllers[key] ??= TextEditingController();

      if (productSerialMap[key]!.isNotEmpty) {
        formatControllers[key]!.text = productSerialMap[key]!.first;
      }
    }

    setState(() {});
  }

  Future<void> saveSerials() async {
    final hasAny = productSerialMap.values.any((list) => list.isNotEmpty);

    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Generate serials first")));
      return;
    }

    final assignment = SerialAssignment(
      id: existingAssignment?.id,
      visitId: widget.visit.id!,
      schoolId: existingAssignment?.schoolId,
      createdBy: existingAssignment?.createdBy ?? "USER",
      createdDate: existingAssignment?.createdDate ?? DateTime.now(),
      products: products.map((p) {
        final key = normalizeProductKey(p.name);
        return SerialProduct(
          productName: p.name,
          versionCode: "E1",
          quantity: '',
          serials: (productSerialMap[key] ?? [])
              .map((s) => SerialEntry(serial: s))
              .toList(),
        );
      }).toList(),
    );

    final ok = await context
        .read<SchoolVisitProvider>()
        .saveSerialAssignment(assignment);

    if (ok) {
      existingAssignment = assignment;
      serialSaved = true;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Saved")));
      setState(() {});
    }
  }

  SerialAssignment buildAssignmentModel() {
    return SerialAssignment(
      id: existingAssignment?.id,
      visitId: widget.visit.id!,
      schoolId: existingAssignment?.schoolId,
      createdBy: existingAssignment?.createdBy ?? "USER",
      createdDate: existingAssignment?.createdDate ?? DateTime.now(),
      products: products.map((p) {
        final key = normalizeProductKey(p.name);
        return SerialProduct(
          productName: p.name,
          versionCode: "E1",
          quantity: p.quantity.toString(),
          serials: (productSerialMap[key] ?? [])
              .map((s) => SerialEntry(serial: s))
              .toList(),
        );
      }).toList(),
    );
  }

  /// ---------- GRID TILE ----------
  Widget sectionGridBox(String title, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceLight),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "ASSEMBLY WORKFLOW",
            style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              sectionGridBox("Photos", Icons.photo_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PhotosPage(uploadedUrls: uploadedUrls)));
              }, Colors.blue),
              sectionGridBox("School Info", Icons.school_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SchoolInfoPage(
                  schoolCtrl: schoolCtrl, addressCtrl: addressCtrl, stateCtrl: stateCtrl, cityCtrl: cityCtrl, pinCtrl: pinCodeCtrl, lat: latValue, long: longValue,
                )));
              }, Colors.orange),
              sectionGridBox("Serial Gen", Icons.qr_code_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SerialGeneratorPage(
                  products: products, formatControllers: formatControllers, productSerialMap: productSerialMap, serialSaved: serialSaved, onSave: saveSerials, normalizeKey: normalizeProductKey,
                )));
              }, Colors.purple),
              sectionGridBox("Shipping", Icons.local_shipping_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ShippingPage(visit: widget.visit)));
              }, Colors.cyan),
              sectionGridBox("Checklist", Icons.edit_note_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => InstallationChecklistPage(visit: widget.visit, role: 'ADMIN')));
              }, Colors.green),
              sectionGridBox("Stock Update", Icons.inventory_2_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AssemblyStockUpdatePage(visitProducts: widget.visit.requiredProducts, schoolId: widget.visit.id!)));
              }, Colors.amber),
              sectionGridBox("IMEI Upload", Icons.qr_code_scanner_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ImeiUploadPage(visit: widget.visit)));
              }, Colors.indigo),
              sectionGridBox("QC Check", Icons.check_circle_outline, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => QcPage(assignment: existingAssignment ?? buildAssignmentModel()))).then((_) => loadExistingSerials());
              }, Colors.teal),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // ── Send to Installation Button ──
          if (widget.visit.shippingDetails.passedToInstallation != true)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmSendToInstallation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded),
                  SizedBox(width: 12),
                  Text("Send to Installation Team", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          if (widget.visit.shippingDetails.passedToInstallation == true)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text("Sent to Installation", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmSendToInstallation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Pass to Installation?", style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          "This will move the school to the Installation Team's active missions. Make sure assembly and shipping details are correct.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<SchoolVisitProvider>().sendToInstallation(widget.visit);
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("School sent to Installation Team!"), backgroundColor: Colors.green),
                );
                Navigator.pop(context); // Go back to list
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
