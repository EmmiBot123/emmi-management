import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Marketing/school_visit_model.dart';
import '../../Providers/Marketing/SchoolVisitProvider.dart';
import '../../Resources/theme_constants.dart';

class TrainingAndIssuesPage extends StatefulWidget {
  final SchoolVisit visit;

  const TrainingAndIssuesPage({super.key, required this.visit});

  @override
  State<TrainingAndIssuesPage> createState() => _TrainingAndIssuesPageState();
}

class _TrainingAndIssuesPageState extends State<TrainingAndIssuesPage> {
  late List<String> itemsTaught;
  late List<String> installationIssues;
  
  final TextEditingController _itemCtrl = TextEditingController();
  final TextEditingController _issueCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    itemsTaught = List.from(widget.visit.itemsTaught);
    installationIssues = List.from(widget.visit.installationIssues);
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _issueCtrl.dispose();
    super.dispose();
  }

  void _addItemTaught() {
    final text = _itemCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (!itemsTaught.contains(text)) {
          itemsTaught.add(text);
        }
        _itemCtrl.clear();
      });
    }
  }

  void _addIssue() {
    final text = _issueCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        installationIssues.add(text);
        _issueCtrl.clear();
      });
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    
    widget.visit.itemsTaught = itemsTaught;
    widget.visit.installationIssues = installationIssues;

    final success = await context.read<SchoolVisitProvider>().updateVisit(widget.visit);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Training records updated"), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save changes"), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Training & Issues"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
          else
            IconButton(icon: const Icon(Icons.done_all, color: AppColors.accent), onPressed: _saveData),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Training Checklist ──
          _buildSectionHeader("TRAINING CURRICULUM", "Items taught to teachers"),
          const SizedBox(height: 16),
          _buildInputRow(_itemCtrl, "Add topic (e.g. Basic Bot Ops)", _addItemTaught, AppColors.accent),
          const SizedBox(height: 20),
          if (itemsTaught.isEmpty)
            _buildEmptyState("No training items recorded yet.")
          else
            Column(
              children: itemsTaught.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return _buildChecklistItem(item, () {
                  setState(() => itemsTaught.removeAt(idx));
                });
              }).toList(),
            ),

          const SizedBox(height: 48),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 32),

          // ── Issues Reporting ──
          _buildSectionHeader("TECHNICAL ISSUES", "Hardware or software problems reported", color: Colors.redAccent),
          const SizedBox(height: 16),
          _buildInputRow(_issueCtrl, "Describe issue (e.g. Broken motor)", _addIssue, Colors.redAccent),
          const SizedBox(height: 20),
          if (installationIssues.isEmpty)
            _buildEmptyState("No issues reported.")
          else
            Column(
              children: installationIssues.asMap().entries.map((entry) {
                final idx = entry.key;
                final issue = entry.value;
                return _buildIssueItem(issue, () {
                  setState(() => installationIssues.removeAt(idx));
                });
              }).toList(),
            ),
          
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.surfaceLight)),
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveData,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("SAVE TRAINING LOG", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, {Color color = AppColors.accent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildInputRow(TextEditingController ctrl, String hint, VoidCallback onAdd, Color color) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: onAdd,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String text, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.check_box, color: Colors.greenAccent, size: 24),
        title: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Widget _buildIssueItem(String text, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
        title: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic)),
      ),
    );
  }
}
