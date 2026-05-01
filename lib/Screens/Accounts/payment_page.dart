import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qubiq_os/Resources/api_endpoints.dart';
import '../../../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../../../Model/Marketing/school_visit_model.dart';
import '../../../Model/Marketing/Payment.dart';

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
  late TextEditingController amountCtrl;
  late TextEditingController txnCtrl;

  bool paymentConfirmed = false;

  @override
  void initState() {
    super.initState();

    amountCtrl =
        TextEditingController(text: widget.visit.payment.amount.toString());

    txnCtrl =
        TextEditingController(text: widget.visit.payment.transactionId ?? "");

    paymentConfirmed = widget.visit.payment.paymentConfirmed;
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget confirmPaymentToggle() {
    return SwitchListTile(
      title: const Text(
        "Confirm Payment Received",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        paymentConfirmed
            ? "Payment has been confirmed and received."
            : "Payment not received / not verified yet.",
        style: TextStyle(
          color: paymentConfirmed ? Colors.green : Colors.red,
        ),
      ),
      value: paymentConfirmed,
      onChanged: widget.visit.payment.advanceTransferred
          ? (value) {
              setState(() {
                paymentConfirmed = value;
              });
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;

    return Scaffold(
      appBar: AppBar(
        title: Text(v.schoolProfile.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: savePayment,
        icon: const Icon(Icons.save),
        label: const Text("Save Payment"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ---------------- PHOTOS ----------------
          sectionCard(title: "Photos", children: [
            if (v.schoolProfile.photoUrl.isEmpty)
              const Text("No Photos Available"),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: v.schoolProfile.photoUrl.map((url) {
                final fullUrl = "${ApiEndpoints.baseUrl}$url";
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    fullUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
          ]),

          /// ---------------- SCHOOL DETAILS ----------------
          sectionCard(title: "School Details", children: [
            Text("School: ${v.schoolProfile.name}"),
            Text("Address: ${v.schoolProfile.address}"),
            Text("City: ${v.schoolProfile.city}"),
            Text("State: ${v.schoolProfile.state}"),
            Text("Pincode: ${v.schoolProfile.pinCode}"),
          ]),

          /// ---------------- PAYMENT ----------------
          sectionCard(title: "Payment", children: [
            Text(
              "Advance Marked By Other Role: "
              "${v.payment.advanceTransferred ? "YES" : "NO"}",
              style: TextStyle(
                color: v.payment.advanceTransferred ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            confirmPaymentToggle(),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: txnCtrl,
              decoration: const InputDecoration(
                labelText: "Transaction ID",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  /// ---------------- SAVE PAYMENT ----------------
  Future<void> savePayment() async {
    final provider = context.read<SchoolVisitProvider>();
    final old = widget.visit;
    final formatter = DateFormat('dd-MM-yyyy, HH:mm:ss');

    final updatedVisit = SchoolVisit(
      id: old.id,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      createdByUserId: old.createdByUserId,
      createdByUserName: old.createdByUserName,
      adminName: old.adminName,
      adminId: old.adminId,
      assignedUserId: old.assignedUserId,
      assignedUserName: old.assignedUserName,
      schoolProfile: old.schoolProfile,
      visitDetails: old.visitDetails,
      proposalChecklist: old.proposalChecklist,
      purchaseOrder: old.purchaseOrder,
      requiredProducts: old.requiredProducts,
      labInformation: old.labInformation,
      shippingDetails: old.shippingDetails,
      contactPersons: old.contactPersons,
      otherRequirements: old.otherRequirements,

      /// ONLY PAYMENT UPDATED
      payment: Payment(
        advanceTransferred: old.payment.advanceTransferred,
        amount: double.tryParse(amountCtrl.text) ?? old.payment.amount,
        transactionId: txnCtrl.text,
        paymentConfirmed: paymentConfirmed,
        transferDate: paymentConfirmed
            ? (old.payment.transferDate ?? formatter.format(DateTime.now()))
            : null,
      ),
      installationChecklist: old.installationChecklist,
    );

    await provider.updateVisit(updatedVisit);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Updated Successfully")),
    );
  }
}
