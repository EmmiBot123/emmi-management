import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../Providers/BillProvider.dart';
import 'add_bill_page.dart';
import 'package:intl/intl.dart';

class MyBillsPage extends StatefulWidget {
  final String userId;
  final String userName;

  const MyBillsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<MyBillsPage> createState() => _MyBillsPageState();
}

class _MyBillsPageState extends State<MyBillsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<BillProvider>().loadMyBills(widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("My Expenses")),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Bill"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddBillPage(
                userId: widget.userId,
                userName: widget.userName,
              ),
            ),
          );
        },
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.myBills.isEmpty
              ? const Center(child: Text("No bills added yet"))
              : ListView.builder(
                  itemCount: provider.myBills.length,
                  itemBuilder: (context, index) {
                    final bill = provider.myBills[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(bill.type[0]),
                        ),
                        title: Text("${bill.type} - ₹${bill.amount}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.description),
                            Text(
                              DateFormat.yMMMd().format(bill.createdAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bill.status == 'Paid' ||
                                    bill.status == 'Approved'
                                ? Colors.green.withOpacity(0.1)
                                : bill.status == 'Rejected'
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bill.status,
                            style: TextStyle(
                              color: bill.status == 'Paid' ||
                                      bill.status == 'Approved'
                                  ? Colors.green
                                  : bill.status == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
