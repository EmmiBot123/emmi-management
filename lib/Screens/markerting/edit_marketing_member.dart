import 'package:qubiq_os/Model/User_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Model/Marketing_member.dart';
import '../../../Providers/User_provider.dart';

void showEditMarketingMemberDialog(BuildContext context, UserModel member) {
  final TextEditingController nameCtrl =
      TextEditingController(text: member.name);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Edit Marketing Member"),
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(
          labelText: "Member Name",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isNotEmpty) {
              // await context
              //     .read<MarketingProvider>()
              //     .editMember(member.id, nameCtrl.text.trim());
            }
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
