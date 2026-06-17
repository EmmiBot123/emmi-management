import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Marketing/school_visit_model.dart';
import '../../Model/Marketing/School_profile_model.dart';
import '../../Model/Marketing/ContactPerson.dart';
import '../../Model/Marketing/VisitDetails.dart';
import '../../Model/Marketing/Payment.dart';
import '../../Model/Marketing/ProposalChecklist.dart';
import '../../Model/Marketing/PurchaseOrder.dart';
import '../../Model/Marketing/ShippingDetails.dart';
import '../../Model/Marketing/LabInformation.dart';
import '../../Providers/AuthProvider.dart';
import '../../Repository/school_visit_repository.dart';

class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF8B5CF6);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

class DirectSchoolAddDialog extends StatefulWidget {
  const DirectSchoolAddDialog({super.key});

  @override
  State<DirectSchoolAddDialog> createState() => _DirectSchoolAddDialogState();
}

class _DirectSchoolAddDialogState extends State<DirectSchoolAddDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _principalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _principalController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      
      // Construct the base defaults
      final schoolProfile = SchoolProfile(
        name: _nameController.text.trim(),
        address: "",
        state: "",
        city: _cityController.text.trim(),
        pinCode: "",
        photoUrl: [],
        latitude: 0,
        longitude: 0,
        googleMapLink: "",
      );

      final contact = ContactPerson(
        name: _principalController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        designation: "Principal",
      );

      final visitDetails = VisitDetails(
        status: "Confirmed", // Bypass marketing
        statusNotes: "Direct QubiQ Setup",
      );

      final payment = Payment(
        advanceTransferred: false,
        amount: 0,
        paymentConfirmed: true, // Bypass accounts
      );

      // Other required empty models
      final proposal = ProposalChecklist(
        sent: false,
        whatsapp: false,
        email: false,
        approved: true,
        remarks: "Direct setup",
      );
      final po = PurchaseOrder(poReceived: true, poNumber: "DIRECT-QUBIQ");
      final shipping = ShippingDetails(status: "Direct Add");
      final labInfo = LabInformation(
        setupType: "Direct",
        pcConfig: PCConfig(processor: "", ram: "", storageType: "", storageSize: ""),
      );

      final visit = SchoolVisit(
        createdByUserId: auth.userId ?? "qubiq_sys",
        createdByUserName: auth.name ?? "QubiQ System",
        schoolProfile: schoolProfile,
        contactPersons: [contact],
        visitDetails: visitDetails,
        payment: payment,
        proposalChecklist: proposal,
        purchaseOrder: po,
        shippingDetails: shipping,
        labInformation: labInfo,
        installationChecklist: [],
        requiredProducts: [],
      );

      final repo = SchoolVisitRepository();
      await repo.createVisit(visit);

      if (mounted) {
        Navigator.pop(context, true); // Return true on success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("School successfully added and confirmed for setup!")),
        );
      }
    } catch (e) {
      debugPrint("Direct Add Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add school: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _C.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.add_business, color: _C.accent),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Direct Add School", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Bypass marketing. School will be instantly confirmed.", style: TextStyle(color: _C.warning, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _C.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField("School Name", "e.g., Delhi Public School", _nameController, Icons.school),
                      const SizedBox(height: 24),
                      _buildTextField("City / Location", "e.g., Bangalore", _cityController, Icons.location_city),
                      const SizedBox(height: 24),
                      const Text("Contact Person", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildTextField("Name", "Principal / Coordinator name", _principalController, Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField("Phone Number", "10-digit mobile", _phoneController, Icons.phone),
                      const SizedBox(height: 16),
                      _buildTextField("Email Address", "school@example.com", _emailController, Icons.email),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: _C.textSecondary)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Create & Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _C.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (v) => v!.trim().isEmpty ? "Required field" : null,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _C.textMuted),
            prefixIcon: Icon(icon, color: _C.textMuted, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _C.accent)),
          ),
        ),
      ],
    );
  }
}
