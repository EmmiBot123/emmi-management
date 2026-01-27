import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/User_provider.dart';
import '../../../Providers/AuthProvider.dart';
import 'new_admin.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadAdmins();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Team')),
      body: prov.admin.isEmpty
          ? const Center(child: Text("No Admins Found"))
          : ListView.builder(
              itemCount: prov.admin.length,
              itemBuilder: (_, i) {
                final admin = prov.admin[i];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(admin.name ?? "N/A"),
                    subtitle: Text(admin.email ?? ""),
                    trailing: const Icon(Icons.info_outline),
                    onTap: () => _showAdminInfo(context, admin),
                  ),
                );
              },
            ),

      /// ✅ KEEP ADD ADMIN OPTION
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddAdminDialog(context),
        backgroundColor: const Color(0xFFF7F2FA),
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text("Add Admin"),
      ),
    );
  }

  /// ---------------- Admin Info Bottom Sheet ----------------
  void _showAdminInfo(BuildContext context, admin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Admin Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _infoRow("Name", admin.name),
              _infoRow("Email", admin.email),
              _infoRow("Phone", admin.phone),
              _infoRow("Role", "ADMIN"),
              _infoRow("User ID", admin.id),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value ?? "N/A")),
        ],
      ),
    );
  }
}
