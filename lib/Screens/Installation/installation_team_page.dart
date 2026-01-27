import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/Marketing/SchoolVisitProvider.dart';
import 'installation_page.dart';

class InstallationTeamPage extends StatefulWidget {
  const InstallationTeamPage({super.key});

  @override
  State<InstallationTeamPage> createState() => _InstallationTeamPageState();
}

class _InstallationTeamPageState extends State<InstallationTeamPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<SchoolVisitProvider>().loadInstallationVisits(),
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
          title: const Text("Installation Team"),
          centerTitle: true,
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.installationVisits.isEmpty
                ? const Center(
                    child: Text(
                      "No installation visits recorded.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.installationVisits.length,
                    itemBuilder: (_, index) {
                      final visit = provider.installationVisits[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InstallationVisitDetailsPage(
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
                              "Installer: ${visit.assignedUserName ?? 'Not Assigned'}\n"
                              "Created By: ${visit.createdByUserName ?? 'Not Available'}\n"
                              "Admin: ${visit.adminName ?? 'Not Available'}",
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
