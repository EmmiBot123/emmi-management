import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/Ads/AdsProvider.dart';

class AddAdDialog extends StatefulWidget {
  const AddAdDialog({super.key});

  @override
  State<AddAdDialog> createState() => _AddAdDialogState();
}

class _AddAdDialogState extends State<AddAdDialog> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AdsProvider>().addAd(
          _titleCtrl.text.trim(),
          _urlCtrl.text.trim(),
        );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad added successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdsProvider>().isLoading;

    return AlertDialog(
      title: const Text("Add New Ad"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Title (Optional)"),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: "YouTube URL",
                hintText: "https://youtu.be/...",
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return "URL is required";
                if (!val.contains("youtube.com") && !val.contains("youtu.be")) {
                  return "Must be a valid YouTube URL";
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Add"),
        ),
      ],
    );
  }
}
