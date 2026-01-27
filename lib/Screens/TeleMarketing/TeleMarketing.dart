import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/User_provider.dart';

import '../../../Providers/AuthProvider.dart';
import '../../Model/User_model.dart';
import 'add_telemarketing.dart';
import '../markerting/SchoolVisit/school_visit_list_page.dart';

class TeleMarketingPage extends StatefulWidget {
  final UserModel? admin;
  const TeleMarketingPage({
    super.key,
    this.admin,
  });

  @override
  State<TeleMarketingPage> createState() => _TeleMarketingPageState();
}

class _TeleMarketingPageState extends State<TeleMarketingPage> {
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
      appBar: AppBar(title: const Text('Tele Marketing Team')),
      body: ListView.builder(
        itemCount: prov.teleMarketing.length,
        itemBuilder: (_, i) {
          final m = prov.teleMarketing[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(m.name ?? "N/A"),
              subtitle: Text(m.email ?? ""),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchoolVisitListPage(
                      userId: m.id ?? "",
                      name: m.name ?? "",
                      role: "TELE_MARKETING", // 👈 passes user-specific id
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
            showAddTeleMarketingMemberDialog(context, widget.admin),
        backgroundColor: const Color(0xFFF7F2FA),
        icon: const Icon(Icons.person_add),
        label: const Text("Add Member"),
      ),
    );
  }
}
