import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Qubiq/QubiqProvider.dart';
import '../../Model/Qubiq/user_api_keys_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAdminDialog extends StatefulWidget {
  final SchoolVisit school;
  const CreateAdminDialog({super.key, required this.school});

  @override
  State<CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends State<CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  // final _passwordCtrl = TextEditingController(); // REMOVED
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _generatedLink;

  // API Keys
  final _neuralCtrl = TextEditingController();
  final _helpBotCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _translateCtrl = TextEditingController();
  final _emmiLiteCtrl = TextEditingController();
  final _blocklyCtrl = TextEditingController();
  final _pyvibeCtrl = TextEditingController();
  final _pptCtrl = TextEditingController();
  final _excelCtrl = TextEditingController();
  final _wordCtrl = TextEditingController();
  final _bucketNameCtrl = TextEditingController();

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

    // 🔑 Pre-fill existing keys if this is a re-setup
    if (widget.school.setupToken != null) {
      _fetchExistingKeys(widget.school.setupToken!);
    }
  }

  Future<void> _fetchExistingKeys(String token) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pending_setups')
          .doc(token)
          .get();
          
      if (doc.exists) {
        final data = doc.data()!;
        final keys = data['apiKeys'] as Map<String, dynamic>;

        _neuralCtrl.text = keys['neural'] ?? '';
        _helpBotCtrl.text = keys['helpBot'] ?? '';
        _imageCtrl.text = keys['image'] ?? '';
        _translateCtrl.text = keys['translate'] ?? '';
        _emmiLiteCtrl.text = keys['emmiLite'] ?? '';
        _blocklyCtrl.text = keys['blockly'] ?? '';
        _pyvibeCtrl.text = keys['pyvibe'] ?? '';
        _pptCtrl.text = keys['ppt'] ?? '';
        _excelCtrl.text = keys['excel'] ?? '';
        _wordCtrl.text = keys['word'] ?? '';
        _bucketNameCtrl.text = keys['bucketName'] ?? '';

        if (data['email'] != null) {
          _emailCtrl.text = data['email'];
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error fetching existing keys: $e");
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
                // _textField("Password", _passwordCtrl, obscure: true), // REMOVED
                _textField("Admin Name", _nameCtrl),
                _textField("Phone", _phoneCtrl),

                if (_generatedLink != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Setup Link Generated:",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 8),
                        SelectableText(_generatedLink!),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _generatedLink!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Link copied to clipboard")),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text("Copy Link"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                _textField("PyVibe Key", _pyvibeCtrl),
                _textField("PowerPoint API Key", _pptCtrl),
                _textField("Excel API Key", _excelCtrl),
                _textField("Word API Key", _wordCtrl),
                _textField("Cloud Bucket Name", _bucketNameCtrl),
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
          onPressed: provider.isLoading ? null : _generateLink,
          child: Text(_generatedLink == null ? "Generate Setup Link" : "Regenerate Link"),
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

  void _generateLink() async {
    if (!_formKey.currentState!.validate()) return;

    final keys = UserApiKeys(
      neuralChat: _neuralCtrl.text,
      helpBot: _helpBotCtrl.text,
      imageGeneration: _imageCtrl.text,
      emmiTranslate: _translateCtrl.text,
      emmiLite: _emmiLiteCtrl.text,
      blockly: _blocklyCtrl.text,
      pyvibe: _pyvibeCtrl.text,
      ppt: _pptCtrl.text,
      excel: _excelCtrl.text,
      word: _wordCtrl.text,
      bucketName: _bucketNameCtrl.text,
    );

    final link = await context.read<QubiqProvider>().generateSetupLink(
          visit: widget.school,
          email: _emailCtrl.text,
          apiKeys: keys,
        );

    if (link != null && mounted) {
      setState(() {
        _generatedLink = link;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Setup Link Generated")),
      );
    }
  }
}
