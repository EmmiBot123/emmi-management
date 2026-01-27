import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../Providers/User_provider.dart';
import '../../../Providers/AuthProvider.dart';

import '../../Model/User_model.dart';
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
      appBar: AppBar(title: const Text('Admins & Telemarketing Teams')),
      body: prov.admin.isEmpty
          ? const Center(child: Text("No Admins Found"))
          : ListView.builder(
              itemCount: prov.admin.length,
              itemBuilder: (_, i) {
                final UserModel admin = prov.admin[i];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(admin.name ?? "N/A"),
                    subtitle: Text(admin.email ?? ""),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                    /// 👉 NAVIGATE TO TELE MARKETING PAGE
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeleMarketingPage(admin: admin),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
