import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:minio/minio.dart';
import 'dart:typed_data';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Qubiq/QubiqProvider.dart';
import '../../Model/Qubiq/user_api_keys_model.dart';
import '../../Repository/Statistics/key_pool_repository.dart';

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
  final _devicePrefixCtrl = TextEditingController();
  final _rangeStartCtrl = TextEditingController();
  final _rangeEndCtrl = TextEditingController();
  bool _isLoadingKeys = true;
  bool _isServerPC = false;
  bool _isProvisioningS3 = false;

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
      _isServerPC = (keys.bucketName != null && keys.bucketName!.isNotEmpty);
    }

    if (mounted) {
      setState(() => _isLoadingKeys = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QubiqProvider>();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text("Manage API Keys for ${widget.school.schoolProfile.name}", style: const TextStyle(fontSize: 16))),
          TextButton.icon(
            onPressed: _autoProvision,
            icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.purpleAccent),
            label: const Text("Auto-Provision ✨", style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
          ),
        ],
      ),
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
                      const Divider(color: Colors.white10, height: 32),
                      SwitchListTile(
                        title: const Text("Is this a Server PC?", style: TextStyle(fontSize: 14)),
                        subtitle: Text(_isServerPC ? "Bucket assignment required" : "No bucket assigned", style: const TextStyle(fontSize: 11)),
                        value: _isServerPC,
                        activeColor: Colors.purpleAccent,
                        onChanged: (v) => setState(() => _isServerPC = v),
                      ),
                      if (_isServerPC) ...[
                        _textField("Cloud Bucket Name", _bucketNameCtrl),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _textField("Device Prefix", _devicePrefixCtrl)),
                            const SizedBox(width: 8),
                            SizedBox(width: 80, child: _textField("Start", _rangeStartCtrl)),
                            const SizedBox(width: 8),
                            SizedBox(width: 80, child: _textField("End", _rangeEndCtrl)),
                          ],
                        ),
                        if (_isProvisioningS3)
                          const LinearProgressIndicator(color: Colors.purpleAccent)
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _provisionS3,
                              icon: const Icon(Icons.cloud_upload_rounded),
                              label: const Text("Initialize S3 Bucket & Devices"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                            ),
                          ),
                      ],
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

  void _autoProvision() async {
    setState(() => _isLoadingKeys = true);
    try {
      final keys = await KeyPoolRepository.autoProvisionKeys(
        widget.school.adminId ?? 'unknown',
        widget.school.schoolProfile.name ?? 'unknown',
      );

      if (keys.isEmpty || (keys['openrouter'] == null && keys['gemini'] == null && keys['grok'] == null)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Key Pools are empty! Please refill in Settings.")),
          );
        }
        return;
      }

      setState(() {
        if (keys['openrouter'] != null) {
          _neuralCtrl.text = keys['openrouter']!;
          _helpBotCtrl.text = keys['openrouter']!;
          _imageCtrl.text = keys['openrouter']!;
          _translateCtrl.text = keys['openrouter']!;
          _emmiLiteCtrl.text = keys['openrouter']!;
          _blocklyCtrl.text = keys['openrouter']!;
          _pyvibeCtrl.text = keys['openrouter']!;
        }
        if (keys['grok'] != null) _pptCtrl.text = keys['grok']!;
        if (keys['gemini'] != null) {
          _excelCtrl.text = keys['gemini']!;
          _wordCtrl.text = keys['gemini']!;
        }
        
        // Auto-assign bucket name if it's a Server PC
        if (_isServerPC && _bucketNameCtrl.text.isEmpty) {
          final cleanName = widget.school.schoolProfile.name?.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-') ?? 'school';
          final shortId = widget.school.adminId?.substring(0, 5) ?? '000';
          _bucketNameCtrl.text = "qubiq-$cleanName-$shortId";
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✨ Keys Auto-Provisioned from Pools")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingKeys = false);
    }
  }

  void _provisionS3() async {
    if (_bucketNameCtrl.text.isEmpty || _devicePrefixCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Bucket Name and Device Prefix")),
      );
      return;
    }

    setState(() => _isProvisioningS3 = true);

    try {
      final awsConfig = await KeyPoolRepository.getAwsConfig().first;
      if (awsConfig['accessKey'] == null || awsConfig['secretKey'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ AWS Credentials missing! Set them in Key Pool Station.")),
          );
        }
        return;
      }

      final bucket = _bucketNameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '-');
      final prefix = _devicePrefixCtrl.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final start = int.tryParse(_rangeStartCtrl.text) ?? 1;
      final end = int.tryParse(_rangeEndCtrl.text) ?? 30;

      debugPrint("🚀 Requesting Backend S3 Provisioning for: $bucket");

      final result = await context.read<QubiqProvider>().provisionS3(
        accessKey: awsConfig['accessKey']!,
        secretKey: awsConfig['secretKey']!,
        region: awsConfig['region'] ?? 'us-east-1',
        bucketName: bucket,
        devicePrefix: prefix,
        rangeStart: start,
        rangeEnd: end,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade800,
              content: Text("🚀 ${result['message']}")
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("S3 Provisioning Failed"),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text("Error: ${result['error']}"),
                    if (result['details'] != null) ...[
                      const SizedBox(height: 10),
                      Text("Details: ${result['details']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("‼️ S3 Provisioning Trigger Failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text("❌ System Error: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProvisioningS3 = false);
    }
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
      bucketName: _isServerPC ? _bucketNameCtrl.text : null,
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
