import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Model/Marketing/school_visit_model.dart';
import '../../../Model/Qubiq/user_api_keys_model.dart';
import '../../../Providers/Qubiq/QubiqProvider.dart';
import '../../../Repository/Statistics/key_pool_repository.dart';
import '../../../Resources/theme_constants.dart';

class TechnicalSetupPage extends StatefulWidget {
  final SchoolVisit visit;
  const TechnicalSetupPage({super.key, required this.visit});

  @override
  State<TechnicalSetupPage> createState() => _TechnicalSetupPageState();
}

class _TechnicalSetupPageState extends State<TechnicalSetupPage> {
  final _neuralCtrl = TextEditingController();
  final _pptCtrl = TextEditingController();
  final _excelCtrl = TextEditingController();
  final _bucketNameCtrl = TextEditingController();
  final _devicePrefixCtrl = TextEditingController();
  final _rangeStartCtrl = TextEditingController(text: "1");
  final _rangeEndCtrl = TextEditingController(text: "30");

  bool _isLoadingKeys = true;
  bool _isServerPC = false;
  bool _isProvisioningS3 = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  void _loadKeys() async {
    final adminId = widget.visit.adminId;
    if (adminId == null || adminId == 'PENDING_SETUP') {
      setState(() => _isLoadingKeys = false);
      return;
    }

    final keys = await context.read<QubiqProvider>().getSchoolApiKeys(adminId);

    if (mounted && keys != null) {
      _neuralCtrl.text = keys.neuralChat ?? "";
      _pptCtrl.text = keys.ppt ?? "";
      _excelCtrl.text = keys.excel ?? "";
      _bucketNameCtrl.text = keys.bucketName ?? "";
      _isServerPC = (keys.bucketName != null && keys.bucketName!.isNotEmpty);
    }

    if (mounted) {
      setState(() => _isLoadingKeys = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Background Glow Blobs ──
          Positioned(top: -100, right: -100, child: _buildGlowBlob(Colors.orangeAccent.withOpacity(0.1), 300)),
          Positioned(bottom: -50, left: -50, child: _buildGlowBlob(AppColors.accent.withOpacity(0.1), 250)),

          _isLoadingKeys
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      pinned: true,
                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 16),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: Text(
                        "TECHNICAL CONFIG",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          shadows: [Shadow(color: Colors.orangeAccent.withOpacity(0.5), blurRadius: 10)],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader("API KEY PROVISIONING", Icons.vpn_key_outlined),
                          const SizedBox(height: 16),
                          _buildKeySection(),
                          const SizedBox(height: 40),
                          _buildHeader("S3 CLOUD INFRASTRUCTURE", Icons.cloud_done_outlined),
                          const SizedBox(height: 16),
                          _buildS3Section(),
                          const SizedBox(height: 48),
                          _buildSaveButton(),
                          const SizedBox(height: 60),
                        ]),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildGlowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildKeySection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _buildTextField("OpenRouter Key (Chat/AI)", _neuralCtrl, Icons.chat_bubble_outline),
          const SizedBox(height: 20),
          _buildTextField("Grok Key (PPT)", _pptCtrl, Icons.slideshow),
          const SizedBox(height: 20),
          _buildTextField("Gemini Key (Docs/Excel)", _excelCtrl, Icons.description_outlined),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _autoProvision,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text("AUTO-FILL FROM KEY POOL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purpleAccent,
                side: const BorderSide(color: Colors.purpleAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildS3Section() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Server PC Deployment", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text(_isServerPC ? "Required for local cloud sync" : "Standalone installation", style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            value: _isServerPC,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _isServerPC = v),
          ),
          if (_isServerPC) ...[
            const SizedBox(height: 32),
            _buildTextField("Bucket Name", _bucketNameCtrl, Icons.storage),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTextField("Device Prefix", _devicePrefixCtrl, Icons.devices)),
                const SizedBox(width: 16),
                SizedBox(width: 100, child: _buildTextField("Start", _rangeStartCtrl, null)),
                const SizedBox(width: 12),
                SizedBox(width: 100, child: _buildTextField("End", _rangeEndCtrl, null)),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ElevatedButton.icon(
                onPressed: _isProvisioningS3 ? null : _provisionS3,
                icon: _isProvisioningS3 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch, size: 20),
                label: Text(_isProvisioningS3 ? "INITIALIZING..." : "INITIALIZE S3 BUCKET & DEVICES", style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData? icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.textMuted, size: 18) : null,
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF6E6AFF)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAll,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("SAVE TECHNICAL CONFIGURATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13)),
      ),
    );
  }

  void _autoProvision() async {
    setState(() => _isLoadingKeys = true);
    try {
      final keys = await KeyPoolRepository.autoProvisionKeys(
        widget.visit.adminId ?? 'unknown',
        widget.visit.schoolProfile.name ?? 'unknown',
      );

      if (keys.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("⚠️ Key Pools are empty! Please refill.")),
          );
        }
        return;
      }

      setState(() {
        if (keys['openrouter'] != null) _neuralCtrl.text = keys['openrouter']!;
        if (keys['grok'] != null) _pptCtrl.text = keys['grok']!;
        if (keys['gemini'] != null) _excelCtrl.text = keys['gemini']!;
        
        if (_isServerPC && _bucketNameCtrl.text.isEmpty) {
          final cleanName = widget.visit.schoolProfile.name?.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-') ?? 'school';
          final shortId = widget.visit.adminId?.substring(0, 5) ?? '000';
          _bucketNameCtrl.text = "qubiq-$cleanName-$shortId";
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingKeys = false);
    }
  }

  void _provisionS3() async {
    if (_bucketNameCtrl.text.isEmpty || _devicePrefixCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bucket Name and Prefix required")));
      return;
    }

    setState(() => _isProvisioningS3 = true);

    try {
      final awsConfig = await KeyPoolRepository.getAwsConfig().first;
      final result = await context.read<QubiqProvider>().provisionS3(
        accessKey: awsConfig['accessKey']!,
        secretKey: awsConfig['secretKey']!,
        region: awsConfig['region'] ?? 'us-east-1',
        bucketName: _bucketNameCtrl.text.trim(),
        devicePrefix: _devicePrefixCtrl.text.trim(),
        rangeStart: int.parse(_rangeStartCtrl.text),
        rangeEnd: int.parse(_rangeEndCtrl.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? result['error'])));
      }
    } finally {
      if (mounted) setState(() => _isProvisioningS3 = false);
    }
  }

  void _saveAll() async {
    if (widget.visit.adminId == null || widget.visit.adminId == 'PENDING_SETUP') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin not yet created for this school")));
      return;
    }

    setState(() => _isSaving = true);
    
    final keys = UserApiKeys(
      neuralChat: _neuralCtrl.text,
      helpBot: _neuralCtrl.text,
      imageGeneration: _neuralCtrl.text,
      emmiTranslate: _neuralCtrl.text,
      emmiLite: _neuralCtrl.text,
      blockly: _neuralCtrl.text,
      pyvibe: _neuralCtrl.text,
      ppt: _pptCtrl.text,
      excel: _excelCtrl.text,
      word: _excelCtrl.text,
      bucketName: _isServerPC ? _bucketNameCtrl.text : null,
    );

    final success = await context.read<QubiqProvider>().updateSchoolApiKeys(
      widget.visit.adminId!,
      keys,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Technical configuration saved!")));
        Navigator.pop(context);
      }
    }
  }
}
