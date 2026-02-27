import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/Marketing/SchoolVisitProvider.dart';
import 'payment_page.dart';
import 'all_bills_page.dart';

class SchoolVisitListPageAccounts extends StatefulWidget {
  const SchoolVisitListPageAccounts({super.key});

  @override
  State<SchoolVisitListPageAccounts> createState() =>
      _SchoolVisitListPageAccountsState();
}

class _SchoolVisitListPageAccountsState
    extends State<SchoolVisitListPageAccounts> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<SchoolVisitProvider>().loadPaymentVisits(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolVisitProvider>();

    return WillPopScope(
      onWillPop: () async {
        provider.clear();
        return true;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Accounts"),
            bottom: const TabBar(
              tabs: [
                Tab(text: "School Payments"),
                Tab(text: "Staff Bills"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildSchoolPaymentsTab(context, provider),
              const AllBillsPage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolPaymentsTab(
      BuildContext context, SchoolVisitProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.paymentVisits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "No Pending Payments Found",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Visits marked with 'Advance Transferred'\nwill appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SchoolVisitProvider>().loadPaymentVisits();
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      );
    }

    // Calculate total pending
    double totalPending = 0;
    for (var v in provider.paymentVisits) {
      if (!v.payment.paymentConfirmed) {
        totalPending += v.payment.amount;
      }
    }

    return Column(
      children: [
        // Simple Summary Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Column(
            children: [
              const Text(
                "Total Pending Payment",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${totalPending.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: provider.paymentVisits.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final visit = provider.paymentVisits[index];
              final isPending = !visit.payment.paymentConfirmed;

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisitDetailsPage(visit: visit),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: isPending ? Colors.orange : Colors.green,
                  child: Icon(
                    isPending ? Icons.priority_high : Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  visit.schoolProfile.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "By: ${visit.assignedUserName ?? visit.createdByUserName ?? 'Unknown'}",
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${visit.payment.amount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      isPending ? "Pending" : "Received",
                      style: TextStyle(
                        fontSize: 12,
                        color: isPending ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
