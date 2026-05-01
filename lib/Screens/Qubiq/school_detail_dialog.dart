import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Qubiq/QubiqProvider.dart';

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
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 800),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF020617).withOpacity(0.85), // Deep Obsidian
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Column(
                children: [
                  // ════════════ HEADER ════════════
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF0F172A), const Color(0xFF0F172A).withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.business_rounded, color: Color(0xFF38BDF8), size: 32),
                        ),
                        const SizedBox(width: 24),
                        // Titles
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.4), size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.address.isNotEmpty ? profile.address : "Address Unknown",
                                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                                  ),
                                  const SizedBox(width: 16),
                                  if (profile.city.isNotEmpty && profile.city != "Unknown") ...[
                                    Icon(Icons.map_rounded, color: Colors.white.withOpacity(0.4), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${profile.city}, ${profile.state}",
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Right Side Code & Close
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tag_rounded, color: Color(0xFF38BDF8), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  // ════════════ BENTO GRID BODY ════════════
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          // Top Row: Quick Stats
                          _BentoCard(
                            width: 245,
                            title: "Deal Status",
                            icon: Icons.insights_rounded,
                            iconColor: Colors.purple.shade400,
                            child: _StatusBadge(
                              text: visit.status,
                              color: visit.status.toLowerCase().contains("won") ? Colors.green.shade400 : Colors.orange.shade400,
                            ),
                          ),
                          _BentoCard(
                            width: 245,
                            title: "Admin Account",
                            icon: Icons.admin_panel_settings_rounded,
                            iconColor: Colors.blue.shade400,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatusBadge(
                                  text: hasAdmin ? "Active" : "Not Setup",
                                  color: hasAdmin ? Colors.green.shade400 : Colors.red.shade400,
                                ),
                                if (hasAdmin) ...[
                                  const SizedBox(height: 12),
                                  _InfoRow("Name", school.adminName ?? 'Unknown'),
                                  _InfoRow("ID", school.adminId!),
                                ]
                              ],
                            ),
                          ),
                          _BentoCard(
                            width: 245,
                            title: "Financials",
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: Colors.teal.shade400,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow("Advance", pay.advanceTransferred ? "Paid" : "Pending"),
                                const SizedBox(height: 8),
                                _InfoRow("Amount", "₹${pay.amount.toStringAsFixed(0)}", isHighlight: true),
                                const SizedBox(height: 8),
                                _InfoRow("Status", pay.paymentConfirmed ? "Confirmed" : "Awaiting"),
                              ],
                            ),
                          ),

                          // Lab Info & Purchase Order
                          _BentoCard(
                            width: 382,
                            title: "Lab Configuration",
                            icon: Icons.dns_rounded,
                            iconColor: Colors.indigo.shade400,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _TechSpec(icon: Icons.memory_rounded, label: "CPU", value: lab.pcConfig.processor),
                                _TechSpec(icon: Icons.sd_storage_rounded, label: "RAM", value: lab.pcConfig.ram),
                                _TechSpec(icon: Icons.storage_rounded, label: "Storage", value: "${lab.pcConfig.storageSize} ${lab.pcConfig.storageType}"),
                              ],
                            ),
                          ),
                          _BentoCard(
                            width: 382,
                            title: "Purchase Order",
                            icon: Icons.assignment_rounded,
                            iconColor: Colors.orange.shade400,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatusBadge(
                                  text: po.poReceived ? "Received" : "Pending PO",
                                  color: po.poReceived ? Colors.green.shade400 : Colors.white.withOpacity(0.3),
                                ),
                                if (po.poReceived) ...[
                                  const SizedBox(height: 12),
                                  _InfoRow("PO #", po.poNumber.isNotEmpty ? po.poNumber : "N/A"),
                                  const SizedBox(height: 8),
                                  _InfoRow("Date", po.poDate ?? "N/A"),
                                ]
                              ],
                            ),
                          ),

                          // Contacts
                          if (school.contactPersons.isNotEmpty)
                            _BentoCard(
                              width: double.infinity,
                              title: "Contact Persons",
                              icon: Icons.contacts_rounded,
                              iconColor: Colors.pink.shade400,
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: school.contactPersons.map((c) {
                                  return Container(
                                    width: 240,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.pink.withOpacity(0.1),
                                          foregroundColor: Colors.pink.shade300,
                                          child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                              if (c.designation.isNotEmpty)
                                                Text(c.designation, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                                              const SizedBox(height: 4),
                                              if (c.phone.isNotEmpty)
                                                Text(c.phone, style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          // Shipping & System Info
                          _BentoCard(
                            width: 382,
                            title: "Shipping Status",
                            icon: Icons.local_shipping_rounded,
                            iconColor: Colors.amber.shade600,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatusBadge(
                                  text: ship.arrived ? "Arrived" : "In Transit",
                                  color: ship.arrived ? Colors.green.shade400 : Colors.amber.shade600,
                                ),
                                const SizedBox(height: 12),
                                if (ship.shippingNumber.isNotEmpty) _InfoRow("Tracking", ship.shippingNumber, isHighlight: true),
                                if (ship.address.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _InfoRow("Destination", "${ship.city}, ${ship.address}"),
                                ]
                              ],
                            ),
                          ),
                          _BentoCard(
                            width: 382,
                            title: "System Records",
                            icon: Icons.dataset_rounded,
                            iconColor: Colors.blueGrey.shade400,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow("Created By", school.createdByUserName),
                                const SizedBox(height: 8),
                                _InfoRow("Assigned", school.assignedUserName?.isNotEmpty == true ? school.assignedUserName! : "None"),
                                const SizedBox(height: 8),
                                _InfoRow("ID", school.id ?? "N/A"),
                              ],
                            ),
                          ),

                          // Training & Issues
                          _BentoCard(
                            width: 382,
                            title: "Training Log",
                            icon: Icons.model_training_rounded,
                            iconColor: Colors.teal.shade400,
                            child: school.itemsTaught.isEmpty
                                ? Text("No records found.", style: TextStyle(color: Colors.white.withOpacity(0.2), fontStyle: FontStyle.italic, fontSize: 13))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: school.itemsTaught.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(item, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)))),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          _BentoCard(
                            width: 382,
                            title: "Field Issues",
                            icon: Icons.bug_report_rounded,
                            iconColor: Colors.red.shade400,
                            child: school.installationIssues.isEmpty
                                ? Text("All systems clear.", style: TextStyle(color: Colors.white.withOpacity(0.2), fontStyle: FontStyle.italic, fontSize: 13))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: school.installationIssues.map((issue) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8.0),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning_rounded, color: Colors.red.shade400, size: 14),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(issue, style: TextStyle(fontSize: 12, color: Colors.red.shade200))),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),

                          // Danger Zone
                          _BentoCard(
                            width: double.infinity,
                            title: "Danger Zone",
                            icon: Icons.dangerous_rounded,
                            iconColor: Colors.red.shade700,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Permanently delete this school and all associated records. This action is irreversible.",
                                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4)),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    foregroundColor: Colors.red.shade400,
                                    elevation: 0,
                                    side: BorderSide(color: Colors.red.withOpacity(0.2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  onPressed: () => _confirmDelete(context),
                                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                                  label: const Text("Delete School", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Delete School?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete ${school.schoolProfile.name} completely?", style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete Permanently"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<QubiqProvider>();
      final success = await provider.deleteSchool(school.id!);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("School deleted successfully.")));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: ${provider.errorMessage}")));
        }
      }
    }
  }
}

class _BentoCard extends StatelessWidget {
  final double width;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _BentoCard({required this.width, required this.title, required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.3),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoRow(this.label, this.value, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }
}

class _TechSpec extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TechSpec({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.2), size: 18),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value.isNotEmpty ? value : "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
      ],
    );
  }
}
