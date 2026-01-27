import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Model/productDetails/SerialAssignment.dart';
import '../../../../Providers/Marketing/SchoolVisitProvider.dart';

class QcPage extends StatefulWidget {
  final SerialAssignment assignment;

  const QcPage({
    super.key,
    required this.assignment,
  });

  @override
  State<QcPage> createState() => _QcPageState();
}

class _QcPageState extends State<QcPage> {
  @override
  void initState() {
    super.initState();

    debugPrint("========== QC PAGE INIT ==========");

    for (var product in widget.assignment.products) {
      debugPrint("PRODUCT: ${product.productName}");

      for (var entry in product.serials) {
        debugPrint("  SERIAL: ${entry.serial} | QC = ${entry.qc}");
      }
    }

    debugPrint("==================================");
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("---------- BUILDING QC UI ----------");

    return Scaffold(
      appBar: AppBar(title: const Text("QC Check List")),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          ...widget.assignment.products.map((product) {
            debugPrint("UI PRODUCT: ${product.productName}");

            final serialEntries = product.serials;

            final allSelected = serialEntries.isNotEmpty &&
                serialEntries.every((e) => e.qc == true);

            debugPrint("  ALL SELECTED = $allSelected");

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ---------- Header ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),

                      /// ---------- Select All ----------
                      Row(
                        children: [
                          Checkbox(
                            value: allSelected,
                            onChanged: (val) {
                              setState(() {
                                for (var entry in serialEntries) {
                                  entry.qc = val ?? false;
                                }

                                debugPrint(
                                    "SELECT ALL CHANGED TO: ${val ?? false}");

                                for (var entry in serialEntries) {
                                  debugPrint(
                                      " -> ${entry.serial} = ${entry.qc}");
                                }
                              });
                            },
                          ),
                          const Text("Select All"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (serialEntries.isEmpty)
                    const Text(
                      "No Serials Found",
                      style: TextStyle(color: Colors.red),
                    ),

                  /// ---------- Serial Items ----------
                  ...serialEntries.map((entry) {
                    debugPrint(
                        "  BUILD SERIAL: ${entry.serial} | qc=${entry.qc}");

                    return CheckboxListTile(
                      title: Text(
                        "${entry.serial}   (QC=${entry.qc})", // DEBUG VISUAL
                      ),
                      value: entry.qc,
                      onChanged: (val) {
                        setState(() {
                          entry.qc = val ?? false;

                          debugPrint(
                              "CLICKED ${entry.serial} -> QC=${entry.qc}");
                        });
                      },
                    );
                  }),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),

          /// ---------- SAVE ----------
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Done & Save"),
            onPressed: saveQcStatus,
          )
        ],
      ),
    );
  }

  Future<void> saveQcStatus() async {
    debugPrint("*********** SAVE PRESSED ***********");

    for (var p in widget.assignment.products) {
      debugPrint("PRODUCT SAVE: ${p.productName}");
      for (var e in p.serials) {
        debugPrint("  SERIAL ${e.serial} => QC=${e.qc}");
      }
    }

    final ok = await context
        .read<SchoolVisitProvider>()
        .saveSerialAssignment(widget.assignment);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("QC Updated Successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to Save QC")),
      );
    }
  }
}
