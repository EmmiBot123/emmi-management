import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../Providers/BillProvider.dart';
import 'package:intl/intl.dart';

class AllBillsPage extends StatefulWidget {
  const AllBillsPage({super.key});

  @override
  State<AllBillsPage> createState() => _AllBillsPageState();
}

class _AllBillsPageState extends State<AllBillsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<BillProvider>().loadAllBills(),
    );
  }

  Future<void> _updateStatus(String billId, String status) async {
    await context.read<BillProvider>().updateBillStatus(billId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Marked as $status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();

    // Calculate pending
    double totalPending = 0;
    for (var bill in provider.allBills) {
      if (bill.status == 'Pending') {
        totalPending += bill.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Staff Claims")),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.allBills.isEmpty
              ? const Center(child: Text("No bills found"))
              : Column(
                  children: [
                    // Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.orange.withOpacity(0.3)),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Total Pending Claims",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${totalPending.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.allBills.length,
                        itemBuilder: (context, index) {
                          final bill = provider.allBills[index];
                          return ExpansionTile(
                            leading: CircleAvatar(
                              child: Text(bill.userName[0].toUpperCase()),
                            ),
                            title: Text("${bill.userName} - ₹${bill.amount}"),
                            subtitle: Text("${bill.type} • ${bill.status}"),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Description: ${bill.description}"),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Date: ${DateFormat.yMMMd().add_jm().format(bill.createdAt)}",
                                    ),
                                    if (bill.imageUrl != null &&
                                        bill.imageUrl!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text("Receipt:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              child:
                                                  Image.network(bill.imageUrl!),
                                            ),
                                          );
                                        },
                                        child: Image.network(
                                          bill.imageUrl!,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Text(
                                                      "Failed to load image"),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    if (bill.status == 'Pending')
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () => _updateStatus(
                                                bill.id!, 'Rejected'),
                                            child: const Text("Reject",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _updateStatus(bill.id!, 'Paid'),
                                            child: const Text("Pay"),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
