import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../Providers/User_provider.dart';
import '../../../Providers/AuthProvider.dart';
import '../../Model/User_model.dart';
import 'SchoolVisit/school_visit_list_page.dart';
import 'add_marketing_member.dart';

class MarketingPage extends StatefulWidget {
  final UserModel? admin;

  const MarketingPage({super.key, this.admin});

  @override
  State<MarketingPage> createState() => _MarketingPageState();
}

class _MarketingPageState extends State<MarketingPage> {
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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();

    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Marketing Team')),
      body: ListView.builder(
        itemCount: prov.marketing.length,
        itemBuilder: (_, i) {
          final m = prov.marketing[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      role: "MARKETING",
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showAddTeamMemberDialog(context, widget.admin, role: "MARKETING"),
        backgroundColor: const Color(0xFFF7F2FA),
        icon: const Icon(Icons.person_add),
        label: const Text("Add Member"),
      ),
    );
  }
}
