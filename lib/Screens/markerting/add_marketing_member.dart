import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/AuthProvider.dart';
import '../../../Providers/User_provider.dart';
import '../../Model/User_model.dart';

void showAddTeamMemberDialog(
  BuildContext context,
  UserModel? admin, {
  String role = "MARKETING",
}) {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        "Add $role Member",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: 350, // Works good for both web and mobile
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      actions: [
        SizedBox(
          height: 42,
          child: TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text("Cancel"),
          ),
        ),
        SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  emailCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }
              final auth = context.read<AuthProvider>();
              final String adminId = admin?.id ?? auth.userId!;
              final String adminName = admin?.name ?? auth.name!;
              await context.read<UserProvider>().addUser(
                    nameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    role,
                    adminId,
                    adminName,
                  );

              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text("Add"),
          ),
        ),
      ],
    ),
  );
}
