import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../Model/productDetails/ImeiEntry.dart';
import '../../../Model/Marketing/school_visit_model.dart';

class ImeiUploadPage extends StatefulWidget {
  final SchoolVisit visit;

  const ImeiUploadPage({
    super.key,
    required this.visit,
  });

  @override
  State<ImeiUploadPage> createState() => _ImeiUploadPageState();
}

class _ImeiUploadPageState extends State<ImeiUploadPage> {
  List<ImeiEntry> _entries = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingEntries();
  }

  Future<void> _loadExistingEntries() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('imei_records')
          .where('visitId', isEqualTo: widget.visit.id)
          .get();

      setState(() {
        _entries = snapshot.docs
            .map((doc) => ImeiEntry.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading IMEI records: $e");
      setState(() => _isLoading = false);
    }
  }

  void _addNewEntry() {
    setState(() {
      _entries.add(ImeiEntry(
        visitId: widget.visit.id!,
        productName: widget.visit.requiredProducts.isNotEmpty 
            ? widget.visit.requiredProducts.first.name 
            : "Unknown Product",
      ));
    });
  }

  void _removeEntry(int index) {
     setState(() {
       _entries.removeAt(index);
     });
  }

  Future<void> _showScanner(int index, int fieldNumber) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final double scanWindowWidth = 320.0;
        final double scanWindowHeight = 120.0;
        String? currentDetection;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                title: Text("Scan IMEI $fieldNumber Barcode"),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Stack(
                children: [
                  MobileScanner(
                    scanWindow: Rect.fromCenter(
                      center: Offset(
                        MediaQuery.of(context).size.width / 2,
                        MediaQuery.of(context).size.height / 2,
                      ),
                      width: scanWindowWidth,
                      height: scanWindowHeight,
                    ),
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final val = barcodes.first.displayValue;
                        if (val != null && val != currentDetection) {
                          setDialogState(() => currentDetection = val);
                        }
                      }
                    },
                  ),
                  // Visual Overlay
                  Center(
                    child: Container(
                      width: scanWindowWidth,
                      height: scanWindowHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        children: [
                          const Text("Detected Value:", style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              currentDetection ?? "Scanning...",
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (currentDetection != null)
                    Positioned(
                      bottom: 40,
                      left: 50,
                      right: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () => Navigator.pop(context, currentDetection),
                        child: const Text("CONFIRM & USE", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            );
          }
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        final cleaned = result.trim().replaceAll(RegExp(r'[^0-9]'), '');
        final imeiRegex = RegExp(r'\d{14,16}');
        final finalVal = imeiRegex.stringMatch(cleaned) ?? cleaned;

        if (fieldNumber == 1) {
          _entries[index].imei1 = finalVal;
        } else {
          _entries[index].imei2 = finalVal;
        }
        _entries[index].barcodeBase64 = "SCANNED";
      });
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final oldDocs = await FirebaseFirestore.instance
          .collection('imei_records')
          .where('visitId', isEqualTo: widget.visit.id)
          .get();
      
      for (var doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }

      for (var entry in _entries) {
        if (entry.imei1.isNotEmpty || entry.imei2.isNotEmpty) {
           final docRef = FirebaseFirestore.instance.collection('imei_records').doc();
           batch.set(docRef, entry.toJson());
        }
      }

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dual IMEI Records Saved Successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Failed to save: $e")),
         );
       }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dual IMEI Scanning (1 & 2)"),
        actions: [
          if (_isSaving)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ))
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveAll),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: entry.productName,
                              decoration: const InputDecoration(labelText: "Product Model", border: InputBorder.none),
                              items: widget.visit.requiredProducts.map((p) => DropdownMenuItem(
                                value: p.name,
                                child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => entry.productName = val);
                              },
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => _removeEntry(index)),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      // IMEI 1
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: "IMEI 1", border: OutlineInputBorder(), isDense: true),
                              controller: TextEditingController(text: entry.imei1)..selection = TextSelection.collapsed(offset: entry.imei1.length),
                              onChanged: (val) => entry.imei1 = val,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.qr_code_scanner, color: entry.imei1.isNotEmpty ? Colors.green : Colors.blue),
                            onPressed: () => _showScanner(index, 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // IMEI 2
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: "IMEI 2", border: OutlineInputBorder(), isDense: true),
                              controller: TextEditingController(text: entry.imei2)..selection = TextSelection.collapsed(offset: entry.imei2.length),
                              onChanged: (val) => entry.imei2 = val,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.qr_code_scanner, color: entry.imei2.isNotEmpty ? Colors.green : Colors.blue),
                            onPressed: () => _showScanner(index, 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewEntry,
        label: const Text("Add New Phone"),
        icon: const Icon(Icons.add_circle_outline),
      ),
      bottomNavigationBar: _entries.isNotEmpty 
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAll,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)),
              child: const Text("SAVE DUAL IMEI DATA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        : null,
    );
  }
}
