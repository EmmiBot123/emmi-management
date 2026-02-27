import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/Qubiq/QubiqProvider.dart';

import 'create_admin_dialog.dart';
import 'manage_keys_dialog.dart';
import 'school_detail_dialog.dart';
import 'search_school_dialog.dart';
import '../GenericTeamPage.dart';

class QubiqPage extends StatefulWidget {
  const QubiqPage({super.key});

  @override
  State<QubiqPage> createState() => _QubiqPageState();
}

class _QubiqPageState extends State<QubiqPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<QubiqProvider>()
            .loadConfirmedSchools(""); // ID ignored now
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensuring provider is available
    // If QubiqProvider is not provided at root, we might need to wrap this with ChangeNotifierProvider
    // But better to assume it's global or provided above.
    // If not, we should wrap this scaffold body or the page.
    // For safety, assuming it's available or user will fix dependency injection.

    final provider = context.watch<QubiqProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Qubiq School Configuration"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: "View Team Members",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GenericTeamPage(
                    role: "QUBIQ",
                    title: "Qubiq Team",
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading && provider.confirmedSchools.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueAccent),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Use this page to create admin accounts for confirmed schools and configure their API keys. Tap any school card to view full details.",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Confirmed Schools (${provider.confirmedSchools.length})",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const SearchSchoolDialog(),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Manual Config"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: provider.confirmedSchools.isEmpty
                        ? _emptyState()
                        : ListView.builder(
                            itemCount: provider.confirmedSchools.length,
                            itemBuilder: (context, index) {
                              final school = provider.confirmedSchools[index];
                              final hasAdmin = school.adminId != null &&
                                  school.adminId!.isNotEmpty;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          SchoolDetailDialog(school: school),
                                    );
                                  },
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: hasAdmin
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      child: Icon(
                                        hasAdmin
                                            ? Icons.check
                                            : Icons.priority_high,
                                        color: hasAdmin
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                    title: Text(
                                      school.schoolProfile.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (school.schoolProfile.city
                                                .isNotEmpty &&
                                            school
                                                .schoolProfile.state.isNotEmpty &&
                                            school.schoolProfile.city !=
                                                "Unknown" &&
                                            school.schoolProfile.state !=
                                                "Unknown")
                                          Text(
                                              "${school.schoolProfile.city}, ${school.schoolProfile.state}"),
                                        const SizedBox(height: 4),
                                        if (hasAdmin)
                                          Text(
                                              "Admin: ${school.adminName == null || school.adminName == 'null' ? 'Unknown' : school.adminName}",
                                              style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500))
                                        else
                                          const Text("No Admin Account",
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    trailing: hasAdmin
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        ManageKeysDialog(
                                                            school: school),
                                                  );
                                                },
                                                icon: const Icon(Icons.key,
                                                    size: 18),
                                                label: const Text("Keys"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue.shade50,
                                                  foregroundColor: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                          "Remove Admin?"),
                                                      content: Text(
                                                          "Are you sure you want to remove the admin for ${school.schoolProfile.name}? This will reset the configuration."),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                              "Cancel"),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                            context
                                                                .read<
                                                                    QubiqProvider>()
                                                                .removeAdminForSchool(
                                                                    school);
                                                          },
                                                          style: TextButton
                                                              .styleFrom(
                                                                  foregroundColor:
                                                                      Colors
                                                                          .red),
                                                          child: const Text(
                                                              "Remove"),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red),
                                                tooltip: "Remove Admin",
                                              ),
                                            ],
                                          )
                                        : ElevatedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    CreateAdminDialog(
                                                        school: school),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black87,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text("Create Admin"),
                                          ),
                                  ),
                                ), // InkWell
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No confirmed schools found",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
