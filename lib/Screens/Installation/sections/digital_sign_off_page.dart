import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../../Model/Marketing/school_visit_model.dart';
import '../../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../../Resources/theme_constants.dart';
import 'package:http/http.dart' as http;

class DigitalSignOffPage extends StatefulWidget {
  final SchoolVisit visit;
  const DigitalSignOffPage({super.key, required this.visit});

  @override
  State<DigitalSignOffPage> createState() => _DigitalSignOffPageState();
}

class _DigitalSignOffPageState extends State<DigitalSignOffPage> {
  final TextEditingController _contactNameCtrl = TextEditingController();
  final TextEditingController _contactPhoneCtrl = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black, // Changed from AppColors.textPrimary to Black
    exportBackgroundColor: Colors.white,
  );

  File? _signatureImage;
  bool _isSubmitting = false;
  bool _isConfirmed = false;

  @override
  void dispose() {
    _signatureController.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSignatureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _signatureImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takeSignaturePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _signatureImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadToImageKit(Uint8List bytes) async {
    try {
      const String publicKey = "public_n3Wfvoi+8E8mYkDx0DrC/PFTpaM=";
      const String privateKey = "private_ZwBLXR4gbIT71ZMAX02y0fiSXac=";
      const String urlEndpoint = "https://ik.imagekit.io/uwodghqce";

      final String token = const Uuid().v4();
      final String expire = (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1800).toString(); // 30 mins expiry
      
      // Generate Signature
      final hmac = Hmac(sha1, utf8.encode(privateKey));
      final signature = hmac.convert(utf8.encode(token + expire)).toString();

      var request = http.MultipartRequest("POST", Uri.parse("https://upload.imagekit.io/api/v1/files/upload"));
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'sig_${DateTime.now().millisecondsSinceEpoch}.png',
      ));

      request.fields.addAll({
        "publicKey": publicKey,
        "signature": signature,
        "expire": expire,
        "token": token,
        "fileName": 'sig_${DateTime.now().millisecondsSinceEpoch}.png',
        "folder": "/signatures/${widget.visit.id}",
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        return json["url"];
      } else {
        debugPrint("ImageKit Error: $responseBody");
        return null;
      }
    } catch (e) {
      debugPrint("ImageKit Upload Error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Digital Sign-off"),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── School Contact Section ──
            const Text(
              "SCHOOL CONTACT PERSON",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _contactNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: "Contact Name",
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contactPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: "Mobile Number",
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Signature Section ──
            const Text(
              "COMPLETION SIGN-OFF",
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Column(
                children: [
                  if (_signatureImage == null) ...[
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white, // Changed from AppColors.bg
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceLight, style: BorderStyle.solid),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Signature(
                          controller: _signatureController,
                          height: 200,
                          backgroundColor: Colors.white, // Changed from AppColors.bg
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => _signatureController.clear(),
                          icon: const Icon(Icons.clear, size: 16, color: Colors.redAccent),
                          label: const Text("Clear Signature", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                        const Text(
                          "Draw your signature above",
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _takeSignaturePhoto,
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text("Take Photo", style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.surfaceLight),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickSignatureImage,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: const Text("Upload", style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.surfaceLight),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_signatureImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            onPressed: () => setState(() => _signatureImage = null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text("Signature Captured Successfully", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Confirmation Section ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isConfirmed ? AppColors.accent.withValues(alpha: 0.5) : AppColors.surfaceLight),
              ),
              child: Theme(
                data: ThemeData(unselectedWidgetColor: AppColors.textMuted),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isConfirmed,
                  onChanged: (val) => setState(() => _isConfirmed = val ?? false),
                  title: const Text(
                    "I confirm that the installation agent has taught me everything and installed everything perfectly.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  activeColor: AppColors.accent,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  if (_signatureController.isEmpty && _signatureImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please provide a signature")),
                    );
                    return;
                  }
                  if (!_isConfirmed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please confirm the installation checklist")),
                    );
                    return;
                  }

                  setState(() => _isSubmitting = true);
                  
                  try {
                    String? finalSignatureUrl;
                    
                    if (_signatureImage != null) {
                      // 1. Upload picked/photo image
                      final bytes = await _signatureImage!.readAsBytes();
                      finalSignatureUrl = await _uploadToImageKit(bytes);
                    } else if (!_signatureController.isEmpty) {
                      // 2. Export drawn signature and upload
                      final signatureBytes = await _signatureController.toPngBytes();
                      if (signatureBytes != null) {
                        finalSignatureUrl = await _uploadToImageKit(signatureBytes);
                      }
                    }

                    if (finalSignatureUrl == null) {
                      throw Exception("Failed to upload signature image");
                    }

                    // 3. Update the visit model
                    final updatedVisit = widget.visit.copyWith(
                      shippingDetails: widget.visit.shippingDetails.copyWith(
                        isInstalled: true,
                        handoverName: _contactNameCtrl.text.trim(),
                        handoverPhone: _contactPhoneCtrl.text.trim(),
                        signatureUrl: finalSignatureUrl,
                      ),
                    );

                    // 4. Save to repository
                    final success = await context.read<SchoolVisitProvider>().updateVisit(updatedVisit);
                    
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Mission Completion Recorded Successfully!")),
                      );
                      Navigator.pop(context);
                    } else {
                      throw Exception("Failed to update visit record");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.toString()}")),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SUBMIT COMPLETION CERTIFICATE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
