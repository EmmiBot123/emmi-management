import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  List<TextEditingController> _imeiControllers = [];
  List<TextEditingController> _defectControllers = [];
  List<String> _defects = [];

  @override
  void initState() {
    super.initState();
    if (widget.visit.requiredProducts.isNotEmpty) {
      _selectedModel = widget.visit.requiredProducts.first.name;
      _modelCtrl.text = _selectedModel;
    }
    _loadData();
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _modelCtrl.dispose();
    for (var controller in _imeiControllers) {
      controller.dispose();
    }
    for (var controller in _defectControllers) {
      controller.dispose();
    }
    super.dispose();
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
          _quantityCtrl.text = _quantity == 0 ? "" : _quantity.toString();
          _selectedModel = data['model'] ?? _selectedModel;
          _modelCtrl.text = _selectedModel;
          _imeis = List<String>.from(data['imeis'] ?? []);
          _defects = List<String>.from(data['defects'] ?? List.generate(_imeis.length, (_) => ""));
          
          // Initialize controllers
          _imeiControllers = _imeis.map((imei) => TextEditingController(text: imei)).toList();
          _defectControllers = _defects.map((defect) => TextEditingController(text: defect)).toList();
          
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
      // Adjust IMEI list size and controllers
      if (_imeis.length < _quantity) {
        final diff = _quantity - _imeis.length;
        _imeis.addAll(List.generate(diff, (_) => ""));
        _imeiControllers.addAll(List.generate(diff, (_) => TextEditingController()));
        _defects.addAll(List.generate(diff, (_) => ""));
        _defectControllers.addAll(List.generate(diff, (_) => TextEditingController()));
      } else if (_imeis.length > _quantity) {
        // Dispose removed controllers
        for (int i = _quantity; i < _imeiControllers.length; i++) {
          _imeiControllers[i].dispose();
          _defectControllers[i].dispose();
        }
        _imeis = _imeis.sublist(0, _quantity);
        _imeiControllers = _imeiControllers.sublist(0, _quantity);
        _defects = _defects.sublist(0, _quantity);
        _defectControllers = _defectControllers.sublist(0, _quantity);
      }
    });
  }

  Future<void> _scanImei(int index) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ScannerDialogContent(),
    );

    if (result != null && mounted) {
      setState(() {
        _imeis[index] = result.trim();
        _imeiControllers[index].text = result.trim();
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
        'defects': _defects,
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
        title: const Text("Device Handover", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          if (_phonesReceived && _quantity > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _bulkScan,
                icon: const Icon(Icons.bolt, color: Colors.amberAccent, size: 18),
                label: const Text("BURST SCAN", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amberAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (_isSaving)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ))
          else
            IconButton(
              icon: const Icon(Icons.save_outlined, color: AppColors.accent),
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
                  // ── Dashboard Header ──
                  if (_phonesReceived) ...[
                    _buildStatsDashboard(),
                    const SizedBox(height: 24),
                  ],

                  // ── Configuration Card ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.surfaceLight),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Phones Received?", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                                Text("Verify hardware arrival", style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Switch(
                              value: _phonesReceived,
                              onChanged: (val) {
                                HapticFeedback.mediumImpact();
                                setState(() => _phonesReceived = val);
                              },
                              activeThumbColor: AppColors.accent,
                              activeTrackColor: AppColors.accent.withOpacity(0.3),
                            ),
                          ],
                        ),
                        if (_phonesReceived) ...[
                          const SizedBox(height: 28),
                          if (widget.visit.requiredProducts.isNotEmpty)
                            DropdownButtonFormField<String>(
                              initialValue: _selectedModel.isEmpty ? null : _selectedModel,
                              dropdownColor: AppColors.surface,
                              decoration: InputDecoration(
                                labelText: "Device Model",
                                labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                filled: true,
                                fillColor: AppColors.bg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.accent, size: 20),
                              ),
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                              items: widget.visit.requiredProducts.map((p) => DropdownMenuItem(
                                value: p.name,
                                child: Text(p.name),
                              )).toList(),
                              onChanged: (val) => setState(() => _selectedModel = val ?? ""),
                            )
                          else
                            TextField(
                              decoration: InputDecoration(
                                labelText: "Device Model",
                                hintText: "Enter model name manually",
                                labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                filled: true,
                                fillColor: AppColors.bg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.accent, size: 20),
                              ),
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                              onChanged: (val) => setState(() => _selectedModel = val),
                              controller: _modelCtrl,
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Quantity Received",
                              labelStyle: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              filled: true,
                              fillColor: AppColors.bg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 20),
                            ),
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            onChanged: _updateQuantity,
                            controller: _quantityCtrl,
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                      onChanged: (val) => _imeis[index] = val,
                                      controller: _imeiControllers[index],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 20),
                                    onPressed: () => _scanImei(index),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 20),
                              Row(
                                children: [
                                  Icon(Icons.report_problem_outlined, size: 16, color: _defects[index].isNotEmpty ? Colors.orangeAccent : AppColors.textMuted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        hintText: "Note any defects (optional)...",
                                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      onChanged: (val) {
                                        setState(() {
                                          _defects[index] = val;
                                        });
                                      },
                                      controller: _defectControllers[index],
                                    ),
                                  ),
                                ],
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
  Widget _buildStatsDashboard() {
    int scannedCount = _imeis.where((e) => e.isNotEmpty).length;
    double progress = _quantity > 0 ? scannedCount / _quantity : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SCAN PROGRESS", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text("$scannedCount / $_quantity", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkScan() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BulkScannerContent(
        onScan: (val) {
          HapticFeedback.lightImpact();
          // Find first empty IMEI slot
          int emptyIdx = _imeis.indexWhere((e) => e.isEmpty);
          if (emptyIdx != -1) {
            setState(() {
              _imeis[emptyIdx] = val;
              _imeiControllers[emptyIdx].text = val;
            });
            return true; // Success
          }
          return false; // Full
        },
        maxCount: _quantity,
        currentCount: _imeis.where((e) => e.isNotEmpty).length,
      ),
    );
  }
}

class _ScannerDialogContent extends StatefulWidget {
  const _ScannerDialogContent();

  @override
  State<_ScannerDialogContent> createState() => _ScannerDialogContentState();
}

class _ScannerDialogContentState extends State<_ScannerDialogContent> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan IMEI", style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto:
                    return const Icon(Icons.flash_auto, color: Colors.blueAccent);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.redAccent);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  default:
                    return const Icon(Icons.camera);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
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
          // Scanner Overlay
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Align IMEI barcode within the frame",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkScannerContent extends StatefulWidget {
  final bool Function(String) onScan;
  final int maxCount;
  final int currentCount;

  const _BulkScannerContent({required this.onScan, required this.maxCount, required this.currentCount});

  @override
  State<_BulkScannerContent> createState() => _BulkScannerContentState();
}

class _BulkScannerContentState extends State<_BulkScannerContent> {
  final MobileScannerController controller = MobileScannerController();
  int count = 0;
  String lastScanned = "";

  @override
  void initState() {
    super.initState();
    count = widget.currentCount;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final val = barcodes.first.displayValue;
                if (val != null && val != lastScanned) {
                  lastScanned = val;
                  if (widget.onScan(val)) {
                    setState(() => count++);
                    if (count >= widget.maxCount) {
                      Navigator.pop(context);
                    }
                  }
                }
              }
            },
          ),
          // HUD Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                        child: Text("Burst Mode: $count / ${widget.maxCount}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Scanning Frame
                  Center(
                    child: Container(
                      width: 280,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Container(
                          width: 260,
                          height: 2,
                          color: Colors.redAccent.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (lastScanned.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                      child: Text("Last Scanned: $lastScanned", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

