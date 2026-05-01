import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/User_provider.dart';
import '../../../Providers/AuthProvider.dart';

import '../../Model/User_model.dart';
import '../markerting/SchoolVisit/school_visit_list_page.dart';
import 'TeleMarketing.dart'; // adjust path

class AdminToTelemarketing extends StatefulWidget {
  const AdminToTelemarketing({super.key});

  @override
  State<AdminToTelemarketing> createState() => _AdminToTelemarketingState();
}

class _AdminToTelemarketingState extends State<AdminToTelemarketing> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final String id = auth.userId ?? "";
      if (id.isNotEmpty) {
        context.read<UserProvider>().loadMembers(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();

    if (prov.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<UserModel> allTeleMarketingUsers = [...prov.admin, ...prov.teleMarketing];

    return Scaffold(
      appBar: AppBar(title: const Text('Admins & Telemarketing Teams')),
      body: allTeleMarketingUsers.isEmpty
          ? const Center(child: Text("No Telemarketing Members Found"))
          : ListView.builder(
              itemCount: allTeleMarketingUsers.length,
              itemBuilder: (_, i) {
                final UserModel user = allTeleMarketingUsers[i];
                final bool isAdmin = user.role?.toUpperCase() == "ADMIN";

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(user.name ?? "N/A"),
                    subtitle: Text("${user.email ?? ""} (${user.role ?? ""})"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                    /// 👉 NAVIGATE BASED ON ROLE
                    onTap: () {
                      if (isAdmin) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeleMarketingPage(admin: user),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchoolVisitListPage(
                              userId: user.id ?? "",
                              name: user.name ?? "",
                              role: user.role ?? "TELE_MARKETING",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
