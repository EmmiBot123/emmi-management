import 'package:flutter/material.dart';
import '../../Model/Marketing/school_visit_model.dart';

class SchoolDetailDialog extends StatelessWidget {
  final SchoolVisit school;
  const SchoolDetailDialog({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    final profile = school.schoolProfile;
    final visit = school.visitDetails;
    final po = school.purchaseOrder;
    final pay = school.payment;
    final lab = school.labInformation;
    final ship = school.shippingDetails;
    final hasAdmin = school.adminId != null && school.adminId!.isNotEmpty;

    final displayCode = (school.schoolCode != null && school.schoolCode!.isNotEmpty)
        ? school.schoolCode!
        : (profile.name.toLowerCase().contains('abcd') ? '3991' : 'N/A');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profile.city.isNotEmpty && profile.city != "Unknown")
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${profile.city}, ${profile.state} - ${profile.pinCode}",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "CODE: $displayCode",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Profile
                    _section("School Profile", [
                      _row("System ID", school.id ?? "N/A"),
                      if (school.schoolCode != null &&
                          school.schoolCode!.isNotEmpty)
                        _row("School Code", school.schoolCode!),
                      _row("Address", profile.address),
                      _row("City", profile.city),
                      _row("State", profile.state),
                      _row("Pin Code", profile.pinCode),
                    ]),

                    // Admin Info
                    _section("Admin Info", [
                      if (hasAdmin) ...[
                        _row(
                            "Admin Name",
                            school.adminName == null ||
                                    school.adminName == 'null'
                                ? 'Unknown'
                                : school.adminName!),
                        _row("Admin ID", school.adminId!),
                      ] else
                        const Text("No admin account created",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500)),
                    ]),

                    // Contact Persons
                    if (school.contactPersons.isNotEmpty)
                      _section("Contact Persons", [
                        for (final c in school.contactPersons)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (c.designation.isNotEmpty)
                                  Text(c.designation,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13)),
                                const SizedBox(height: 4),
                                if (c.phone.isNotEmpty) _row("Phone", c.phone),
                                if (c.email.isNotEmpty) _row("Email", c.email),
                              ],
                            ),
                          ),
                      ]),

                    // Visit Details
                    _section("Visit Details", [
                      _row("Status", visit.status),
                      if (visit.visitDate != null &&
                          visit.visitDate!.isNotEmpty)
                        _row("Visit Date", visit.visitDate!),
                      if (visit.revisitDate != null &&
                          visit.revisitDate!.isNotEmpty)
                        _row("Revisit Date", visit.revisitDate!),
                      if (visit.statusNotes.isNotEmpty)
                        _row("Notes", visit.statusNotes),
                    ]),

                    // Purchase Order
                    _section("Purchase Order", [
                      _row("PO Received", po.poReceived ? "Yes" : "No"),
                      if (po.poNumber.isNotEmpty)
                        _row("PO Number", po.poNumber),
                      if (po.poDate != null && po.poDate!.isNotEmpty)
                        _row("PO Date", po.poDate!),
                    ]),

                    // Payment
                    _section("Payment", [
                      _row("Advance Transferred",
                          pay.advanceTransferred ? "Yes" : "No"),
                      _row("Amount", "₹${pay.amount.toStringAsFixed(2)}"),
                      if (pay.transactionId != null &&
                          pay.transactionId!.isNotEmpty)
                        _row("Transaction ID", pay.transactionId!),
                      if (pay.transferDate != null &&
                          pay.transferDate!.isNotEmpty)
                        _row("Transfer Date", pay.transferDate!),
                      _row("Payment Confirmed",
                          pay.paymentConfirmed ? "Yes" : "No"),
                    ]),

                    // Lab Information
                    _section("Lab Information", [
                      _row("Setup Type", lab.setupType),
                      _row("Processor", lab.pcConfig.processor),
                      _row("RAM", lab.pcConfig.ram),
                      _row("Storage",
                          "${lab.pcConfig.storageSize} ${lab.pcConfig.storageType}"),
                    ]),

                    // Shipping
                    _section("Shipping Details", [
                      if (ship.address.isNotEmpty)
                        _row("Address", ship.address),
                      if (ship.city.isNotEmpty)
                        _row("City", "${ship.city}, ${ship.state}"),
                      if (ship.shippingNumber.isNotEmpty)
                        _row("Shipping Number", ship.shippingNumber),
                      if (ship.contactNumber.isNotEmpty)
                        _row("Contact", ship.contactNumber),
                      _row("Arrived", ship.arrived ? "Yes" : "No"),
                      if (ship.arrivedDate.isNotEmpty)
                        _row("Arrived Date", ship.arrivedDate),
                    ]),

                    // Created By
                    _section("Other Info", [
                      _row("Created By", school.createdByUserName),
                      if (school.assignedUserName != null &&
                          school.assignedUserName!.isNotEmpty)
                        _row("Assigned To", school.assignedUserName!),
                      if (school.otherRequirements != null &&
                          school.otherRequirements!.isNotEmpty)
                        _row("Other Requirements", school.otherRequirements!),
                    ]),
                  ],
                ),
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
