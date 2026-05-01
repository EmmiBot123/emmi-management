import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../Model/Marketing/school_visit_model.dart';
import '../../../Resources/theme_constants.dart';

class InstallationImeiPage extends StatefulWidget {
  final SchoolVisit visit;

  const InstallationImeiPage({
    super.key,
    required this.visit,
  });

  @override
  State<InstallationImeiPage> createState() => _InstallationImeiPageState();
}

class _InstallationImeiPageState extends State<InstallationImeiPage> {
  bool _phonesReceived = false;
  int _quantity = 0;
  String _selectedModel = "";
  List<String> _imeis = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.visit.requiredProducts.isNotEmpty) {
      _selectedModel = widget.visit.requiredProducts.first.name;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('installation_imei_records')
          .doc(widget.visit.id)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _phonesReceived = data['received'] ?? false;
          _quantity = data['quantity'] ?? 0;
          _selectedModel = data['model'] ?? _selectedModel;
          _imeis = List<String>.from(data['imeis'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading IMEI data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _updateQuantity(String val) {
    final q = int.tryParse(val) ?? 0;
    setState(() {
      _quantity = q;
      // Adjust IMEI list size
      if (_imeis.length < _quantity) {
        _imeis.addAll(List.generate(_quantity - _imeis.length, (_) => ""));
      } else if (_imeis.length > _quantity) {
        _imeis = _imeis.sublist(0, _quantity);
      }
    });
  }

  Future<void> _scanImei(int index) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text("Scan IMEI"),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final val = barcodes.first.displayValue;
                if (val != null) {
                  Navigator.pop(context, val);
                }
              }
            },
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _imeis[index] = result.trim();
      });
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('installation_imei_records')
          .doc(widget.visit.id)
          .set({
        'visitId': widget.visit.id,
        'received': _phonesReceived,
        'quantity': _quantity,
        'model': _selectedModel,
        'imeis': _imeis,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Installation Device Data Saved")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Device Handover"),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ))
          else
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppColors.accent),
              onPressed: _saveData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status Card ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Phones Received?", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Verify hardware arrival", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                            Switch(
                              value: _phonesReceived,
                              onChanged: (val) => setState(() => _phonesReceived = val),
                              activeColor: AppColors.accent,
                            ),
                          ],
                        ),
                        if (_phonesReceived) ...[
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _selectedModel,
                            dropdownColor: AppColors.surface,
                            decoration: InputDecoration(
                              labelText: "Device Model",
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                              filled: true,
                              fillColor: AppColors.bg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            style: const TextStyle(color: AppColors.textPrimary),
                            items: widget.visit.requiredProducts.map((p) => DropdownMenuItem(
                              value: p.name,
                              child: Text(p.name),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedModel = val!),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Quantity Received",
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                              filled: true,
                              fillColor: AppColors.bg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textMuted),
                            ),
                            style: const TextStyle(color: AppColors.textPrimary),
                            onChanged: _updateQuantity,
                            controller: TextEditingController(text: _quantity == 0 ? "" : _quantity.toString())
                              ..selection = TextSelection.collapsed(
                                offset: (_quantity == 0 ? "" : _quantity.toString()).length,
                              ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_phonesReceived && _quantity > 0) ...[
                    const SizedBox(height: 32),
                    const Text(
                      "IMEI REGISTRY",
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quantity,
                      itemBuilder: (context, index) {
                        final imeiText = _imeis[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.bg,
                                child: Text("${index + 1}", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    hintText: "Enter or scan IMEI",
                                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                  onChanged: (val) => _imeis[index] = val,
                                  controller: TextEditingController(text: imeiText)
                                    ..selection = TextSelection.collapsed(offset: imeiText.length),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 20),
                                onPressed: () => _scanImei(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 40),
                  if (_phonesReceived)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("SAVE DEVICE RECORDS", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
