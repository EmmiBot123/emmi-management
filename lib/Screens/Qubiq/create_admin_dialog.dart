import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Qubiq/QubiqProvider.dart';
import '../../Model/Qubiq/user_api_keys_model.dart';

class CreateAdminDialog extends StatefulWidget {
  final SchoolVisit school;
  const CreateAdminDialog({super.key, required this.school});

  @override
  State<CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // API Keys
  final _neuralCtrl = TextEditingController();
  final _helpBotCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _translateCtrl = TextEditingController();
  final _emmiLiteCtrl = TextEditingController();
  final _blocklyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = widget.school.schoolProfile;
    _nameCtrl.text = "Admin - ${profile.name}";
    // Try to find a contact person to pre-fill
    if (widget.school.contactPersons.isNotEmpty) {
      final contact = widget.school.contactPersons.first;
      _phoneCtrl.text = contact.phone;
      _emailCtrl.text = contact.email;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QubiqProvider>();

    return AlertDialog(
      title: Text("Create Admin for ${widget.school.schoolProfile.name}"),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField("Email", _emailCtrl),
                _textField("Password", _passwordCtrl, obscure: true),
                _textField("Admin Name", _nameCtrl),
                _textField("Phone", _phoneCtrl),
                const Divider(height: 30, thickness: 2),
                const Text("Initial API Keys",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _textField("Neural Chat Key", _neuralCtrl),
                _textField("Help Bot Key", _helpBotCtrl),
                _textField("Image Generation Key", _imageCtrl),
                _textField("Emmi Translate Key", _translateCtrl),
                _textField("Emmi Lite Key", _emmiLiteCtrl),
                _textField("Blockly Key", _blocklyCtrl),
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(provider.errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: provider.isLoading ? null : _submit,
          child: const Text("Create Admin"),
        ),
      ],
    );
  }

  Widget _textField(String label, TextEditingController ctrl,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final keys = UserApiKeys(
      neuralChat: _neuralCtrl.text,
      helpBot: _helpBotCtrl.text,
      imageGeneration: _imageCtrl.text,
      emmiTranslate: _translateCtrl.text,
      emmiLite: _emmiLiteCtrl.text,
      blockly: _blocklyCtrl.text,
    );

    final success = await context.read<QubiqProvider>().createAdminForSchool(
          visit: widget.school,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          apiKeys: keys,
        );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin Created Successfully")),
      );
    }
  }
}
