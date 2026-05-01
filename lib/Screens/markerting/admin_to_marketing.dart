import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/User_provider.dart';
import '../../Providers/AuthProvider.dart';
import '../../Model/User_model.dart';
import 'SchoolVisit/school_visit_list_page.dart';
import 'marketing_page.dart'; // adjust path

class AdminToMarketing extends StatefulWidget {
  const AdminToMarketing({super.key});

  @override
  State<AdminToMarketing> createState() => _AdminToMarketingState();
}

class _AdminToMarketingState extends State<AdminToMarketing> {
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

    final List<UserModel> allMarketingUsers = [...prov.admin, ...prov.marketing];

    return Scaffold(
      appBar: AppBar(title: const Text('Admins & Marketing Teams')),
      body: allMarketingUsers.isEmpty
          ? const Center(child: Text("No Marketing Members Found"))
          : ListView.builder(
              itemCount: allMarketingUsers.length,
              itemBuilder: (_, i) {
                final UserModel user = allMarketingUsers[i];
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
                            builder: (_) => MarketingPage(admin: user),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchoolVisitListPage(
                              userId: user.id ?? "",
                              name: user.name ?? "",
                              role: user.role ?? "MARKETING",
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
