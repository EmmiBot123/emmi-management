import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Qubiq/QubiqProvider.dart';
import '../../Repository/Support/support_repository.dart';
import 'package:fl_chart/fl_chart.dart';

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

    final displayCode =
        (school.schoolCode != null && school.schoolCode!.isNotEmpty)
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
            border:
                Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
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
                        colors: [
                          const Color(0xFF0F172A),
                          const Color(0xFF0F172A).withOpacity(0.0)
                        ],
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
                            border: Border.all(
                                color:
                                    const Color(0xFF38BDF8).withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.business_rounded,
                              color: Color(0xFF38BDF8), size: 32),
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
                                  Icon(Icons.location_on_rounded,
                                      color: Colors.white.withOpacity(0.4),
                                      size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.address.isNotEmpty
                                        ? profile.address
                                        : "Address Unknown",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 14),
                                  ),
                                  const SizedBox(width: 16),
                                  if (profile.city.isNotEmpty &&
                                      profile.city != "Unknown") ...[
                                    Icon(Icons.map_rounded,
                                        color: Colors.white.withOpacity(0.4),
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${profile.city}, ${profile.state}",
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 14),
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
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.5)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tag_rounded,
                                      color: Color(0xFF38BDF8), size: 14),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                           // 📈 Visual Analytics
                           _BentoCard(
                             width: 745,
                             title: "Visual Analytics",
                             icon: Icons.analytics_rounded,
                             iconColor: Colors.amber.shade400,
                             child: SizedBox(
                               height: 160,
                               child: Row(
                                 children: [
                                   Expanded(
                                     flex: 1,
                                     child: PieChart(
                                       PieChartData(
                                         sectionsSpace: 2,
                                         centerSpaceRadius: 20,
                                         sections: [
                                           PieChartSectionData(
                                             value: (context.watch<QubiqProvider>().schoolStats[displayCode]?['students'] ?? 0).toDouble(),
                                             title: 'Students',
                                             color: const Color(0xFF38BDF8),
                                             radius: 30,
                                             titleStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                                           ),
                                           PieChartSectionData(
                                             value: (context.watch<QubiqProvider>().schoolStats[displayCode]?['teachers'] ?? 0).toDouble(),
                                             title: 'Teachers',
                                             color: Colors.orange.shade400,
                                             radius: 30,
                                             titleStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ),
                                   const SizedBox(width: 24),
                                   Expanded(
                                     flex: 2,
                                     child: BarChart(
                                       BarChartData(
                                         gridData: FlGridData(show: false),
                                         titlesData: FlTitlesData(
                                           show: true,
                                           bottomTitles: AxisTitles(
                                             sideTitles: SideTitles(
                                               showTitles: true,
                                               getTitlesWidget: (value, meta) {
                                                 const labels = ['Tasks', 'Proj', 'Subs'];
                                                 if (value.toInt() >= 0 && value.toInt() < labels.length) {
                                                   return Text(labels[value.toInt()], style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9));
                                                 }
                                                 return const SizedBox();
                                               },
                                             ),
                                           ),
                                           leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                           topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                           rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                         ),
                                         borderData: FlBorderData(show: false),
                                         barGroups: [
                                           BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: (context.watch<QubiqProvider>().schoolStats[displayCode]?['assignments'] ?? 0).toDouble(), color: Colors.orange.shade400, width: 16, borderRadius: BorderRadius.circular(4))]),
                                           BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: (context.watch<QubiqProvider>().schoolStats[displayCode]?['projects'] ?? 0).toDouble(), color: Colors.purple.shade400, width: 16, borderRadius: BorderRadius.circular(4))]),
                                           BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: (context.watch<QubiqProvider>().schoolStats[displayCode]?['submissions'] ?? 0).toDouble(), color: Colors.green.shade400, width: 16, borderRadius: BorderRadius.circular(4))]),
                                         ],
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ),
                          // Top Row: Quick Stats
                          _BentoCard(
                            width: 245,
                            title: "Deal Status",
                            icon: Icons.insights_rounded,
                            iconColor: Colors.purple.shade400,
                            child: _StatusBadge(
                              text: visit.status,
                              color: visit.status.toLowerCase().contains("won")
                                  ? Colors.green.shade400
                                  : Colors.orange.shade400,
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
                                  color: hasAdmin
                                      ? Colors.green.shade400
                                      : Colors.red.shade400,
                                ),
                                if (hasAdmin) ...[
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                      "Name", school.adminName ?? 'Unknown'),
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
                                _InfoRow(
                                    "Advance",
                                    pay.advanceTransferred
                                        ? "Paid"
                                        : "Pending"),
                                const SizedBox(height: 8),
                                _InfoRow("Amount",
                                    "₹${pay.amount.toStringAsFixed(0)}",
                                    isHighlight: true),
                                const SizedBox(height: 8),
                                _InfoRow(
                                    "Status",
                                    pay.paymentConfirmed
                                        ? "Confirmed"
                                        : "Awaiting"),
                              ],
                            ),
                          ),
                          // 📊 Performance Metrics
                          _BentoCard(
                            width: 745,
                            title: "Performance Metrics",
                            icon: Icons.bar_chart_rounded,
                            iconColor: const Color(0xFF38BDF8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _MetricItem(
                                    "Accounts",
                                    context
                                                .watch<QubiqProvider>()
                                                .schoolStats[displayCode]
                                            ?['users'] ??
                                        0,
                                    Colors.blue,
                                    subLabel: "T: ${context.watch<QubiqProvider>().schoolStats[displayCode]?['teachers'] ?? 0} • S: ${context.watch<QubiqProvider>().schoolStats[displayCode]?['students'] ?? 0}"),
                                _MetricItem(
                                    "Assignments",
                                    context
                                                .watch<QubiqProvider>()
                                                .schoolStats[displayCode]
                                            ?['assignments'] ??
                                        0,
                                    Colors.orange),
                                _MetricItem(
                                    "Projects",
                                    context
                                                .watch<QubiqProvider>()
                                                .schoolStats[displayCode]
                                            ?['projects'] ??
                                        0,
                                    Colors.purple),
                                _MetricItem(
                                    "Submissions",
                                    context
                                                .watch<QubiqProvider>()
                                                .schoolStats[displayCode]
                                            ?['submissions'] ??
                                        0,
                                    Colors.green),
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
                                _TechSpec(
                                    icon: Icons.memory_rounded,
                                    label: "CPU",
                                    value: lab.pcConfig.processor),
                                _TechSpec(
                                    icon: Icons.sd_storage_rounded,
                                    label: "RAM",
                                    value: lab.pcConfig.ram),
                                _TechSpec(
                                    icon: Icons.storage_rounded,
                                    label: "Storage",
                                    value:
                                        "${lab.pcConfig.storageSize} ${lab.pcConfig.storageType}"),
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
                                  text:
                                      po.poReceived ? "Received" : "Pending PO",
                                  color: po.poReceived
                                      ? Colors.green.shade400
                                      : Colors.white.withOpacity(0.3),
                                ),
                                if (po.poReceived) ...[
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                      "PO #",
                                      po.poNumber.isNotEmpty
                                          ? po.poNumber
                                          : "N/A"),
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
                                      border: Border.all(
                                          color:
                                              Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor:
                                              Colors.pink.withOpacity(0.1),
                                          foregroundColor: Colors.pink.shade300,
                                          child: Text(
                                              c.name.isNotEmpty
                                                  ? c.name[0].toUpperCase()
                                                  : "?",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(c.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      color: Colors.white)),
                                              if (c.designation.isNotEmpty)
                                                Text(c.designation,
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white
                                                            .withOpacity(0.4))),
                                              const SizedBox(height: 4),
                                              if (c.phone.isNotEmpty)
                                                Text(c.phone,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF38BDF8),
                                                        fontWeight:
                                                            FontWeight.bold)),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _StatusBadge(
                                      text: ship.status.isNotEmpty 
                                          ? ship.status 
                                          : (ship.shippingNumber.isEmpty 
                                              ? "Not Shipped" 
                                              : (ship.arrived ? "Arrived" : "In Transit")),
                                      color: ship.status.isNotEmpty
                                          ? Colors.orange.shade400
                                          : (ship.shippingNumber.isEmpty
                                              ? Colors.white.withOpacity(0.3)
                                              : (ship.arrived ? Colors.green.shade400 : Colors.amber.shade600)),
                                    ),
                                    IconButton(
                                      onPressed: () => _showShippingUpdateDialog(context, school),
                                      icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 20),
                                      tooltip: "Update Status",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (ship.shippingNumber.isNotEmpty)
                                  _InfoRow("AWB Code", ship.shippingNumber, isHighlight: true),
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
                                _InfoRow(
                                    "Created By", school.createdByUserName),
                                const SizedBox(height: 8),
                                _InfoRow(
                                    "Assigned",
                                    school.assignedUserName?.isNotEmpty == true
                                        ? school.assignedUserName!
                                        : "None"),
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
                                ? Text("No records found.",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13))
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: school.itemsTaught.map((item) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.green,
                                                size: 14),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Text(item,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.white
                                                            .withOpacity(
                                                                0.7)))),
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
                                ? Text("All systems clear.",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13))
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        school.installationIssues.map((issue) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8.0),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color:
                                                  Colors.red.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning_rounded,
                                                color: Colors.red.shade400,
                                                size: 14),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Text(issue,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .red.shade200))),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),

                          _BentoCard(
                            width: 382,
                            title: "Support Actions",
                            icon: Icons.support_agent_rounded,
                            iconColor: const Color(0xFF38BDF8),
                            child: Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showRaiseTicketDialog(context),
                                  icon: const Icon(Icons.add_comment_rounded,
                                      size: 18),
                                  label: const Text("Raise Support Ticket"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF38BDF8)
                                        .withOpacity(0.1),
                                    foregroundColor: const Color(0xFF38BDF8),
                                    elevation: 0,
                                    side: BorderSide(
                                        color: const Color(0xFF38BDF8)
                                            .withOpacity(0.2)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ],
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
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.4)),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.red.withOpacity(0.1),
                                    foregroundColor: Colors.red.shade400,
                                    elevation: 0,
                                    side: BorderSide(
                                        color: Colors.red.withOpacity(0.2)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                  ),
                                  onPressed: () => _confirmDelete(context),
                                  icon: const Icon(Icons.delete_forever_rounded,
                                      size: 18),
                                  label: const Text("Delete School",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
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
        title:
            const Text("Delete School?", style: TextStyle(color: Colors.white)),
        content: Text(
            "Are you sure you want to delete ${school.schoolProfile.name} completely?",
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
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
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("School deleted successfully.")));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Delete failed: ${provider.errorMessage}")));
        }
      }
    }
  }

  void _showRaiseTicketDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _RaiseTicketDialog(school: school),
    );
  }

  void _showShippingUpdateDialog(BuildContext context, SchoolVisit school) {
    final provider = context.read<QubiqProvider>();
    final ship = school.shippingDetails;
    
    String currentStatus = ship.status.isNotEmpty ? ship.status : (ship.shippingNumber.isEmpty ? "Yet to be picked up" : (ship.arrived ? "Arrived" : "In Transit"));
    final awbController = TextEditingController(text: ship.shippingNumber);
    final statusController = TextEditingController(text: currentStatus);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: const Text("Update Shipping", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: awbController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("AWB Code / Tracking #", Icons.numbers),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: ["Yet to be picked up", "In Transit", "Arrived", "Custom"].contains(currentStatus) ? currentStatus : "Custom",
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Shipping Status", Icons.local_shipping),
              items: ["Yet to be picked up", "In Transit", "Arrived", "Custom"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != "Custom") statusController.text = v!;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: statusController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Custom Status (Optional)", Icons.edit),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newDetails = ship.copyWith(
                shippingNumber: awbController.text,
                status: statusController.text,
                arrived: statusController.text == "Arrived",
              );
              final success = await provider.updateShippingStatus(school, newDetails);
              if (success && context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context); // Close detail dialog too to refresh
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shipping status updated!")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

class _RaiseTicketDialog extends StatefulWidget {
  final SchoolVisit school;
  const _RaiseTicketDialog({required this.school});

  @override
  State<_RaiseTicketDialog> createState() => _RaiseTicketDialogState();
}

class _RaiseTicketDialogState extends State<_RaiseTicketDialog> {
  final _messageController = TextEditingController();
  bool _isHardware = false;
  bool _isLoading = false;
  final _repository = SupportRepository();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    // Use admin email or a generic school email
    final email = widget.school.adminId != null &&
            widget.school.adminId!.contains('@')
        ? widget.school.adminId!
        : "school_${widget.school.schoolCode ?? widget.school.id}@qubiq.com";

    final success = await _repository.createTicket(
      email: email,
      message: _messageController.text.trim(),
      isHardware: _isHardware,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Support ticket raised successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to raise ticket. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: const Text("Raise Support Ticket",
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Describe the issue...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("Hardware Complaint?",
                  style: TextStyle(color: Colors.white)),
              const Spacer(),
              Switch(
                value: _isHardware,
                onChanged: (val) => setState(() => _isHardware = val),
                activeColor: const Color(0xFF38BDF8),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38BDF8),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text("Raise Ticket"),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final double width;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _BentoCard(
      {required this.width,
      required this.title,
      required this.icon,
      required this.iconColor,
      required this.child});

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
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight
                    ? const Color(0xFF38BDF8)
                    : Colors.white.withOpacity(0.8),
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
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final String? subLabel;

  const _MetricItem(this.label, this.value, this.color, {this.subLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
              color: color, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (subLabel != null)
          Text(
            subLabel!,
            style: TextStyle(color: color.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
        ),
      ],
    );
  }
}

class _TechSpec extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TechSpec(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.2), size: 18),
        const SizedBox(height: 8),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value.isNotEmpty ? value : "N/A",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white)),
      ],
    );
  }
}
