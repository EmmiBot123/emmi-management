import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/Marketing/SchoolVisitProvider.dart';
import 'payment_page.dart';

class SchoolVisitListPageAccounts extends StatefulWidget {
  const SchoolVisitListPageAccounts({
    super.key,
  });

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
      child: Scaffold(
        appBar: AppBar(
          title: const Text("School Visits"),
          centerTitle: true,
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.paymentVisits.isEmpty
                ? const Center(
                    child: Text(
                      "No school visits recorded.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.paymentVisits.length,
                    itemBuilder: (_, index) {
                      final visit = provider.paymentVisits[index];
                      String marketingInfo;
                      if (visit.assignedUserName != null &&
                          visit.assignedUserName!.isNotEmpty) {
                        marketingInfo =
                            "Marketing Person: ${visit.assignedUserName}\nTele/Created By: ${visit.createdByUserName ?? 'Not Available'}";
                      } else {
                        marketingInfo =
                            "Marketing Person: ${visit.createdByUserName ?? 'Not Available'}";
                      }
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VisitDetailsPage(
                                visit: visit,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              visit.schoolProfile.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "Marketing Person: ${visit.assignedUserName?.isNotEmpty == true ? visit.assignedUserName : visit.createdByUserName ?? 'Not Available'}\n"
                              "${visit.assignedUserName?.isNotEmpty == true ? 'Tele Marketing : ${visit.createdByUserName ?? 'Not Available'}\n' : ''}"
                              "Admin: ${visit.adminName ?? 'Not Available'}",
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
