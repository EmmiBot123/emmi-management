import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../Model/Marketing/school_visit_model.dart';
import '../../../../Model/Marketing/InstallationChecklistItem.dart';
import '../../../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../../../Resources/theme_constants.dart';

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
  bool get canAdd => widget.role == "INSTALLATION" || widget.role == "ADMIN";
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

  Future<void> saveToServer() async {
    widget.visit.installationChecklist = items;
    await context.read<SchoolVisitProvider>().updateVisit(widget.visit);
    if (mounted) setState(() {});
  }

  void showAddSheet() {
    final temp = List<bool>.filled(defaultTasks.length, false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, s) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Add Mission Tasks",
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  
                  // Default Tasks List
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: ListView.builder(
                      itemCount: defaultTasks.length,
                      itemBuilder: (c, i) {
                        return CheckboxListTile(
                          value: temp[i],
                          activeColor: AppColors.accent,
                          checkColor: Colors.white,
                          title: Text(defaultTasks[i], style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          onChanged: (v) => s(() => temp[i] = v!),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: customCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: "Custom Task Description",
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        for (int i = 0; i < temp.length; i++) {
                          if (temp[i]) {
                            items.add(InstallationChecklistItem(title: defaultTasks[i], completed: false));
                          }
                        }

                        if (customCtrl.text.trim().isNotEmpty) {
                          items.add(InstallationChecklistItem(title: customCtrl.text.trim(), completed: false));
                        }

                        customCtrl.clear();
                        saveToServer();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Add to Checklist", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Mission Checklist"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: showAddSheet,
              backgroundColor: AppColors.accent,
              label: const Text("Add Task", style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.add_task, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // ── Progress Header ──
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Completion Progress", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    Text("${(progress * 100).toStringAsFixed(0)}%", style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.bg,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist_rtl_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text("No tasks added for this mission.", style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: item.completed ? AppColors.accent.withOpacity(0.3) : AppColors.surfaceLight),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Checkbox(
                            value: item.completed,
                            activeColor: AppColors.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                              color: item.completed ? AppColors.textMuted : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              decoration: item.completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          trailing: canAdd
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
