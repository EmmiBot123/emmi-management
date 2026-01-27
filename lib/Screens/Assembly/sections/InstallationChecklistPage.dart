import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../Model/Marketing/school_visit_model.dart';
import '../../../../Model/Marketing/InstallationChecklistItem.dart';
import '../../../../Providers/Marketing/SchoolVisitProvider.dart';

class InstallationChecklistPage extends StatefulWidget {
  final SchoolVisit visit;
  final String role; // INSTALLATION / VIEW / ADMIN

  const InstallationChecklistPage({
    super.key,
    required this.visit,
    required this.role,
  });

  @override
  State<InstallationChecklistPage> createState() =>
      _InstallationChecklistPageState();
}

class _InstallationChecklistPageState extends State<InstallationChecklistPage> {
  late List<InstallationChecklistItem> items;

  final List<String> defaultTasks = [
    "Unboxing & Physical Inspection",
    "Verify Serial Numbers",
    "Power On & Basic Boot Test",
    "OS / Software Installation",
    "Network Configuration",
    "QC Checklist Verification",
    "Demo to School Staff",
    "Installation Photos Captured",
    "Installation Report Completed",
    "Client Signature Collected",
  ];

  final TextEditingController customCtrl = TextEditingController();

  bool get canCheck => widget.role == "INSTALLATION" || widget.role == "ADMIN";

  bool get isAdmin => widget.role == "ADMIN";

  @override
  void initState() {
    super.initState();
    items = List.from(widget.visit.installationChecklist);
  }

  double get progress {
    if (items.isEmpty) return 0;
    int done = items.where((e) => e.completed).length;
    return done / items.length;
  }

  /// ================= SAVE TO SERVER =================
  Future<void> saveToServer() async {
    widget.visit.installationChecklist = items;
    await context.read<SchoolVisitProvider>().updateVisit(widget.visit);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Checklist updated successfully")),
    );

    setState(() {});
  }

  void showAddSheet() {
    if (!isAdmin) return;

    final temp = List<bool>.filled(defaultTasks.length, false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,

          /// 👇 IMPORTANT FIX FOR KEYBOARD OVERFLOW
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, s) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Add Installation Checklist",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 350,
                    child: ListView.builder(
                      itemCount: defaultTasks.length,
                      itemBuilder: (c, i) {
                        return CheckboxListTile(
                          value: temp[i],
                          title: Text(defaultTasks[i]),
                          onChanged: (v) => s(() => temp[i] = v!),
                        );
                      },
                    ),
                  ),
                  TextField(
                    controller: customCtrl,
                    decoration: const InputDecoration(
                      labelText: "Add Custom Task",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            for (int i = 0; i < temp.length; i++) {
                              if (temp[i]) {
                                items.add(
                                  InstallationChecklistItem(
                                    title: defaultTasks[i],
                                    completed: false,
                                  ),
                                );
                              }
                            }

                            if (customCtrl.text.trim().isNotEmpty) {
                              items.add(
                                InstallationChecklistItem(
                                  title: customCtrl.text.trim(),
                                  completed: false,
                                ),
                              );
                            }

                            customCtrl.clear();
                            saveToServer();
                            Navigator.pop(context);
                          },
                          child: const Text("Add"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Installation Checklist"),
      ),

      /// ADMIN ONLY CAN ADD
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: showAddSheet,
              label: const Text("Add Checklist"),
              icon: const Icon(Icons.playlist_add_check),
            )
          : null,

      body: Column(
        children: [
          const SizedBox(height: 10),

          /// PROGRESS BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 6),
                Text(
                  "Progress: ${(progress * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      "No checklist added",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.completed,
                            onChanged: canCheck
                                ? (v) {
                                    setState(() {
                                      item.completed = v ?? false;
                                    });
                                    saveToServer();
                                  }
                                : null,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: item.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),

                          /// DELETE ONLY FOR ADMIN
                          trailing: isAdmin
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() => items.removeAt(index));
                                    saveToServer();
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
