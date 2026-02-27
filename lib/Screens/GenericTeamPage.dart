import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Providers/User_provider.dart';
import '../../Providers/AuthProvider.dart';
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

    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: members.isEmpty
          ? Center(child: Text("No members found in ${widget.title}"))
          : ListView.builder(
              itemCount: members.length,
              itemBuilder: (_, i) {
                final m = members[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(m.name ?? "N/A"),
                    subtitle: Text(m.email ?? ""),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Delete User"),
                                content: Text(
                                    "Are you sure you want to delete ${m.name}? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await context
                                          .read<UserProvider>()
                                          .deleteUser(m.id!);
                                    },
                                    child: const Text("Delete",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Only show visit arrow if relevant? Assuming yes.
                        const Icon(Icons.arrow_forward_ios, size: 16),
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
        backgroundColor: const Color(0xFFF7F2FA),
        icon: const Icon(Icons.person_add),
        label: const Text("Add Member"),
      ),
    );
  }
}
