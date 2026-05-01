import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Qubiq/QubiqProvider.dart';
import '../../Model/Qubiq/user_api_keys_model.dart';

class ManageKeysDialog extends StatefulWidget {
  final SchoolVisit school;
  const ManageKeysDialog({super.key, required this.school});

  @override
  State<ManageKeysDialog> createState() => _ManageKeysDialogState();
}

class _ManageKeysDialogState extends State<ManageKeysDialog> {
  final _formKey = GlobalKey<FormState>();
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
  bool _isLoadingKeys = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  void _loadKeys() async {
    final adminId = widget.school.adminId;
    if (adminId == null) return;

    final keys = await context.read<QubiqProvider>().getSchoolApiKeys(adminId);

    if (mounted && keys != null) {
      _neuralCtrl.text = keys.neuralChat ?? "";
      _helpBotCtrl.text = keys.helpBot ?? "";
      _imageCtrl.text = keys.imageGeneration ?? "";
      _translateCtrl.text = keys.emmiTranslate ?? "";
      _emmiLiteCtrl.text = keys.emmiLite ?? "";
      _blocklyCtrl.text = keys.blockly ?? "";
      _pyvibeCtrl.text = keys.pyvibe ?? "";
      _pptCtrl.text = keys.ppt ?? "";
      _excelCtrl.text = keys.excel ?? "";
      _wordCtrl.text = keys.word ?? "";
      _bucketNameCtrl.text = keys.bucketName ?? "";
    }

    if (mounted) {
      setState(() => _isLoadingKeys = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QubiqProvider>();

    return AlertDialog(
      title: Text("Manage API Keys for ${widget.school.schoolProfile.name}"),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: _isLoadingKeys
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
          onPressed: provider.isLoading || _isLoadingKeys ? null : _submit,
          child: const Text("Update Keys"),
        ),
      ],
    );
  }

  Widget _textField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.school.adminId == null) return;

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

    final success = await context.read<QubiqProvider>().updateSchoolApiKeys(
          widget.school.adminId!,
          keys,
        );

    // Refresh keys local display just in case
    if (success && mounted) {
      // Optional: could reload checks here if needed, but we are popping.
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("API Keys Updated")),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Update failed: ${context.read<QubiqProvider>().errorMessage ?? 'Unknown error'}")),
      );
    }
  }
}
