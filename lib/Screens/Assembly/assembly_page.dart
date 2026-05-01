import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../Model/Marketing/ProductRequest.dart';
import '../../../../Model/Marketing/school_visit_model.dart';
import '../../../Model/productDetails/SerialAssignment.dart';
import '../../../Model/productDetails/SerialEntry.dart';
import '../../../Model/productDetails/SerialProduct.dart';

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
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          const Text("Sections",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              sectionGridBox("Photos", Icons.photo, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotosPage(uploadedUrls: uploadedUrls),
                  ),
                );
              }),
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
              sectionGridBox("Serial Generator", Icons.qr_code, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SerialGeneratorPage(
                      products: products,
                      formatControllers: formatControllers,
                      productSerialMap: productSerialMap,
                      serialSaved: serialSaved,
                      onSave: saveSerials,
                      normalizeKey: normalizeProductKey,
                    ),
                  ),
                );
              }),
              sectionGridBox("Shipping", Icons.local_shipping, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShippingPage(visit: widget.visit),
                  ),
                );
              }),
              sectionGridBox("Check List", Icons.edit_note, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InstallationChecklistPage(
                      visit: widget.visit,
                      role: 'ADMIN',
                    ),
                  ),
                );
              }),
              sectionGridBox(
                "Update Stock",
                Icons.inventory_2,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssemblyStockUpdatePage(
                        visitProducts: widget.visit.requiredProducts,
                        schoolId: widget.visit.id!,
                      ),
                    ),
                  );
                },
              ),
              sectionGridBox("IMEI Upload", Icons.qr_code_scanner, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImeiUploadPage(
                      visit: widget.visit,
                    ),
                  ),
                );
              }),
            ],
          ),

          /// ---------- QC ----------
          sectionGridBox("QC Check", Icons.check_circle, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QcPage(
                  assignment:
                      existingAssignment ?? buildAssignmentModel(), // ⭐ FIX
                ),
              ),
            ).then((_) => loadExistingSerials());
          }),
        ],
      ),
    );
  }
}
