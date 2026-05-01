import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Providers/User_provider.dart';
import '../Providers/AuthProvider.dart';
import '../Resources/theme_constants.dart';
import '../Model/User_model.dart';
import 'markerting/SchoolVisit/school_visit_list_page.dart';
import 'markerting/add_marketing_member.dart';

class GenericTeamPage extends StatefulWidget {
  final UserModel? admin;
  final String role;
  final String title;

  const GenericTeamPage({
    super.key,
    this.admin,
    required this.role,
    required this.title,
  });

  @override
  State<GenericTeamPage> createState() => _GenericTeamPageState();
}

class _GenericTeamPageState extends State<GenericTeamPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();

      final String id = widget.admin?.id ?? auth.userId ?? "";

      if (id.isNotEmpty) {
        context.read<UserProvider>().loadMembers(id);
      }
    });
  }

  List<UserModel> _getMembers(UserProvider prov) {
    switch (widget.role) {
      case "ASSEMBLY_TEAM":
        return prov.assembly;
      case "INSTALLATION_TEAM":
        return prov.installation;
      case "QUBIQ":
        return prov.qubiq;
      case "ADS":
        return prov.ads;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();
    final members = _getMembers(prov);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : members.isEmpty
              ? Center(child: Text("No members found in ${widget.title}", style: const TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: members.length,
                  itemBuilder: (_, i) {
                    final m = members[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceLight),
                      ),
                      child: ListTile(
                        title: Text(m.name ?? "N/A", style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        subtitle: Text(m.email ?? "", style: const TextStyle(color: AppColors.textMuted)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    title: const Text("Delete User", style: TextStyle(color: AppColors.textPrimary)),
                                    content: Text(
                                        "Are you sure you want to delete ${m.name}? This action cannot be undone.",
                                        style: const TextStyle(color: AppColors.textSecondary)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await context
                                              .read<UserProvider>()
                                              .deleteUser(m.id!);
                                        },
                                        child: const Text("Delete",
                                            style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SchoolVisitListPage(
                                userId: m.id ?? "",
                                name: m.name ?? "",
                                role: widget.role,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTeamMemberDialog(
          context,
          widget.admin,
          role: widget.role,
        ),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text("Add Member", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
