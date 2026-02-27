import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../../Providers/AuthProvider.dart';
import '../../../Providers/User_provider.dart';

import 'add_visit_page.dart';
import 'visit_details_page.dart';
import '../Bills/my_bills_page.dart';
import '../../../../../Services/migration_service.dart';
import '../../../../../Services/excel_service.dart';
import '../../../Model/Marketing/school_visit_model.dart';

class SchoolVisitListPage extends StatefulWidget {
  final String userId;
  final String name;
  final String role;

  const SchoolVisitListPage({
    super.key,
    required this.userId,
    required this.name,
    required this.role,
  });

  @override
  State<SchoolVisitListPage> createState() => _SchoolVisitListPageState();
}

class _SchoolVisitListPageState extends State<SchoolVisitListPage> {
  bool selectionMode = false;
  final Set<String> selectedVisitIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<SchoolVisitProvider>().loadVisits(widget.userId),
    );
  }

  late SchoolVisitProvider _visitProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visitProvider = context.read<SchoolVisitProvider>();
  }

  @override
  void dispose() {
    _visitProvider.disableNearbyMode(notify: false);
    super.dispose();
  }

  // ================= NEARBY BUTTON =================
  Widget _nearbyAppBarButton(BuildContext context) {
    final provider = context.watch<SchoolVisitProvider>();

    return IconButton(
      tooltip: "Nearby schools",
      icon: Icon(
        Icons.near_me,
        color: provider.isNearbyMode ? Colors.blue : Colors.grey,
      ),
      onPressed: () => _showRadiusDialog(provider),
    );
  }

  void _showRadiusDialog(SchoolVisitProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        double tempRadius = provider.nearbyRadiusKm;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Nearby Schools"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${tempRadius.toInt()} km radius"),
                  Slider(
                    value: tempRadius,
                    min: 1,
                    max: 600,
                    divisions: 60,
                    label: "${tempRadius.toInt()} km",
                    onChanged: (value) => setState(() => tempRadius = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    provider.disableNearbyMode();
                    Navigator.pop(context);
                  },
                  child: const Text("CLEAR"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await provider.enableNearbyMode(tempRadius);
                  },
                  child: const Text("APPLY"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= SHARE USER SELECTION =================
  void _showUserSelectionDialog() {
    final userProv = context.read<UserProvider>();
    final selectedUsers = <String>{};

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Assign To Marketing"),
              content: SizedBox(
                width: 400,
                child: ListView(
                  shrinkWrap: true,
                  children: userProv.marketing.map((user) {
                    return CheckboxListTile(
                      title: Text(user.name ?? ""),
                      value: selectedUsers.contains(user.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedUsers.add(user.id!);
                          } else {
                            selectedUsers.remove(user.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: selectedUsers.isEmpty
                      ? null
                      : () async {
                          await _applySharing(selectedUsers.toList());
                          Navigator.pop(context);
                        },
                  child: const Text("ASSIGN"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _applySharing(List<String> userIds) async {
    final userProv = context.read<UserProvider>();
    final visitProv = context.read<SchoolVisitProvider>();

    for (final visitId in selectedVisitIds) {
      final visit = visitProv.visits.firstWhere((v) => v.id == visitId);

      for (final uid in userIds) {
        final user = userProv.marketing.firstWhere((u) => u.id == uid);

        // ✅ Map-based sharing (auto de-duplicate)
        visit.sharedUsers[user.id!] = user.name ?? "";
      }

      // ⚠️ IMPORTANT:
      // This should be an UPDATE, not ADD (addVisit = creates new visit)
      await visitProv.addVisit(visit);
    }

    setState(() {
      selectionMode = false;
      selectedVisitIds.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Visits shared successfully")),
    );
  }

  // ================= MIGRATION =================
  Future<void> _showMigrationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sync Legacy Data"),
        content: const Text(
            "This will look for your old account using your email address and migrate your school visits to this new app.\n\nContinue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("SYNC NOW"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final auth = context.read<AuthProvider>();
      // Email is available via auth.email
      // If AuthProvider doesn't have email easily accessible, we might need to fetch it or pass it.
      // Looking at MarketingPage, it passes userId/name/role.
      // UserProvider might have it.

      // Let's assume we can get it from AuthProvider or UserProvider.
      // If not, we might need to update AuthProvider to expose email.
      // Checking AuthProvider usage in other files...

      final service = MigrationService();
      // Use email from AuthProvider
      final userEmail = auth.email ?? "";

      final result = await service.runMigration(userEmail, widget.userId);

      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pop(); // Close loading dialog correctly

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );

        // Reload visits
        context.read<SchoolVisitProvider>().loadVisits(widget.userId);
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolVisitProvider>();
    final auth = context.read<AuthProvider>();
    final authRole = auth.role ?? "";

    return WillPopScope(
      onWillPop: () async {
        provider.clear();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("School Visits"),
          centerTitle: true,
          actions: [
            _nearbyAppBarButton(context),
            if (authRole == "ADMIN" || authRole == "SUPER_ADMIN")
              IconButton(
                tooltip: "Share visits",
                icon: Icon(
                  Icons.people_alt,
                  color: selectionMode ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    selectionMode = !selectionMode;
                    selectedVisitIds.clear();
                  });
                },
              ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: "My Expenses",
              icon: const Icon(Icons.receipt_long),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyBillsPage(
                      userId: widget.userId,
                      userName: widget.name,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: "Sync Legacy Data",
              icon: const Icon(Icons.sync),
              onPressed: () => _showMigrationDialog(),
            ),
            IconButton(
              tooltip: "Export to Excel",
              icon: const Icon(Icons.download),
              onPressed: () async {
                final provider = context.read<SchoolVisitProvider>();
                if (provider.filteredVisits.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No visits to export")),
                  );
                  return;
                }

                // Show date range picker dialog
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (ctx) {
                    DateTime? startDate;
                    DateTime? endDate;

                    return StatefulBuilder(
                      builder: (ctx, setState) {
                        return AlertDialog(
                          title: const Text("Export to Excel"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Select a date range to filter visits, or export all.",
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: Text(startDate != null
                                    ? "From: ${startDate!.day}/${startDate!.month}/${startDate!.year}"
                                    : "Select Start Date"),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => startDate = picked);
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.calendar_today),
                                title: Text(endDate != null
                                    ? "To: ${endDate!.day}/${endDate!.month}/${endDate!.year}"
                                    : "Select End Date"),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => endDate = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, {
                                'all': true,
                              }),
                              child: const Text("Export All"),
                            ),
                            ElevatedButton(
                              onPressed: (startDate != null && endDate != null)
                                  ? () => Navigator.pop(ctx, {
                                        'all': false,
                                        'start': startDate,
                                        'end': endDate,
                                      })
                                  : null,
                              child: const Text("Export Range"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (result == null) return;

                List<SchoolVisit> visitsToExport;
                if (result['all'] == true) {
                  visitsToExport = provider.filteredVisits;
                } else {
                  final start = result['start'] as DateTime;
                  final end = (result['end'] as DateTime)
                      .add(const Duration(days: 1)); // inclusive end date
                  visitsToExport = provider.filteredVisits.where((v) {
                    final created = v.createdAt;
                    if (created == null) return false;
                    return created.isAfter(start) && created.isBefore(end);
                  }).toList();
                }

                if (visitsToExport.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("No visits found in the selected range")),
                    );
                  }
                  return;
                }

                try {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Generating Excel...")),
                    );
                  }

                  await ExcelService().exportVisits(visitsToExport);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Export failed: $e")),
                    );
                  }
                }
              },
            ),
          ],
          bottom: kIsWeb
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(65),
                  child: _buildFilters(provider),
                )
              : null,
        ),
        bottomNavigationBar: selectionMode
            ? _selectionBottomBar()
            : (!kIsWeb ? _filterBottomBar(provider) : null),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text("Add Visit"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddVisitPage(
                  userId: widget.userId,
                  name: widget.name,
                  role: widget.role,
                ),
              ),
            );
          },
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.filteredVisits.isEmpty
                ? const Center(
                    child: Text(
                      "No school visits recorded yet.\nClick + to add one.",
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.filteredVisits.length,
                    itemBuilder: (_, index) {
                      final visit = provider.filteredVisits[index];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: selectionMode
                              ? Checkbox(
                                  value: selectedVisitIds.contains(visit.id),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedVisitIds.add(visit.id!);
                                      } else {
                                        selectedVisitIds.remove(visit.id);
                                      }
                                    });
                                  },
                                )
                              : null,
                          title: Text(
                            visit.schoolProfile.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            "Status: ${visit.visitDetails.status}\n"
                            "Revisit: ${visit.visitDetails.revisitDate ?? "Not Scheduled"}"
                            "${widget.role == "TELE_MARKETING" ? "\nAssigned To: ${visit.assignedUserName ?? "Not Assigned"}" : ""}"
                            "${widget.role == "MARKETING" ? "\nAssigned By: ${visit.createdByUserName}" : ""}",
                          ),
                          trailing: selectionMode ||
                                  provider.currentFilter == "SHARED"
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Delete Entry"),
                                        content:
                                            const Text("Delete this entry?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () => Navigator.of(
                                                    context,
                                                    rootNavigator: true)
                                                .pop(),
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await provider.deleteVisit(visit.id!);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text("Deleted Successfully"),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                          onTap: selectionMode
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VisitDetailsPage(
                                        visit: visit,
                                        userId: widget.userId,
                                        role: widget.role,
                                      ),
                                    ),
                                  );
                                },
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  // ================= FILTERS =================
  Widget _buildFilters(SchoolVisitProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _filterChip("ALL", Icons.list, provider),
        _filterChip("PENDING", Icons.pending_actions, provider),
        _filterChip("REVISIT", Icons.reviews_sharp, provider),
        _filterChip("APPROVED", Icons.check_circle, provider),
        _filterChip("SHARED", Icons.share, provider),
      ],
    );
  }

  Widget _filterChip(
      String label, IconData icon, SchoolVisitProvider provider) {
    final isSelected = provider.currentFilter == label;

    return GestureDetector(
      onTap: () {
        if (label == "SHARED") {
          provider.filterSharedVisits(widget.userId);
        } else {
          provider.filterByStatus(label);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: isSelected ? Colors.blue : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionBottomBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                selectionMode = false;
                selectedVisitIds.clear();
              });
            },
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed:
                selectedVisitIds.isEmpty ? null : _showUserSelectionDialog,
            child: const Text("CONTINUE"),
          ),
        ],
      ),
    );
  }

  Widget _filterBottomBar(SchoolVisitProvider provider) {
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: _buildFilters(provider),
    );
  }
}
