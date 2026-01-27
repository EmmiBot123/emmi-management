import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/AuthProvider.dart';
import '../../../Providers/User_provider.dart';

void showAddAdminDialog(BuildContext context) {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Consumer<UserProvider>(
        builder: (context, userProv, _) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              "Add Admin",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SizedBox(
              width: 350,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      enabled: !userProv.isLoadingAdd,
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
                      enabled: !userProv.isLoadingAdd,
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
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            actions: [
              SizedBox(
                height: 42,
                child: TextButton(
                  onPressed: userProv.isLoadingAdd
                      ? null
                      : () => Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text("Cancel"),
                ),
              ),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: userProv.isLoadingAdd
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              emailCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please fill all fields")),
                            );
                            return;
                          }

                          final auth = context.read<AuthProvider>();

                          final msg =
                              await context.read<UserProvider>().addUser(
                                    nameCtrl.text.trim(),
                                    emailCtrl.text.trim(),
                                    "ADMIN",
                                    auth.userId!,
                                    auth.name!,
                                  );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(msg)));

                          Navigator.of(context, rootNavigator: true).pop();
                        },
                  child: userProv.isLoadingAdd
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Add"),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
