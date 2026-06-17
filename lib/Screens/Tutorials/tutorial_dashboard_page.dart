import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Tutorial_model.dart';
import '../../Providers/TutorialProvider.dart';

class _C {
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const accent = Color(0xFF10B981); // Emerald for learning
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const danger = Color(0xFFEF4444);
}

class TutorialDashboardPage extends StatefulWidget {
  const TutorialDashboardPage({super.key});

  @override
  State<TutorialDashboardPage> createState() => _TutorialDashboardPageState();
}

class _TutorialDashboardPageState extends State<TutorialDashboardPage> with SingleTickerProviderStateMixin {
  final List<String> _categories = [
    "All", "Login", "Dashboard", "QubiQ Studio", "LogicLogic", 
    "Python Workbench", "Content Hub", "Operations", "Accounts"
  ];
  
  String _selectedCategory = "All";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showAddTutorialDialog() {
    showDialog(context: context, builder: (_) => const _AddTutorialDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCategoryTabs(),
              const SizedBox(height: 32),
              Expanded(child: _buildTutorialsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tutorials Hub",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage platform help and app tutorials",
              style: TextStyle(color: _C.textSecondary, fontSize: 14),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showAddTutorialDialog,
          icon: const Icon(Icons.add, size: 20),
          label: const Text("Add Tutorial", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _C.accent.withValues(alpha: 0.2) : _C.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _C.accent : Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? _C.accent : _C.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTutorialsList() {
    return StreamBuilder<List<TutorialModel>>(
      stream: context.read<TutorialProvider>().tutorialsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _C.accent));
        }
        
        var tutorials = snapshot.data ?? [];
        if (_selectedCategory != "All") {
          tutorials = tutorials.where((t) => t.category == _selectedCategory).toList();
        }

        if (tutorials.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_library_outlined, size: 64, color: _C.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text("No tutorials found", style: TextStyle(color: _C.textMuted, fontSize: 16)),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.1,
          ),
          itemCount: tutorials.length,
          itemBuilder: (context, index) {
            final t = tutorials[index];
            return Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: t.thumbnailUrl.isNotEmpty
                          ? Image.network(t.thumbnailUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackThumb())
                          : _fallbackThumb(),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _C.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(t.category, style: const TextStyle(color: _C.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Expanded(child: Text(t.description, style: const TextStyle(color: _C.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t.createdAt != null ? "${t.createdAt!.day}/${t.createdAt!.month}/${t.createdAt!.year}" : "", style: const TextStyle(color: _C.textMuted, fontSize: 11)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: _C.danger, size: 20),
                                onPressed: () {
                                  context.read<TutorialProvider>().deleteTutorial(t.id!);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _fallbackThumb() {
    return Container(
      color: Colors.white.withValues(alpha: 0.02),
      child: const Icon(Icons.play_circle_outline, color: _C.textMuted, size: 48),
    );
  }
}

// ═══════════════════ ADD TUTORIAL DIALOG ═══════════════════

class _AddTutorialDialog extends StatefulWidget {
  const _AddTutorialDialog();

  @override
  State<_AddTutorialDialog> createState() => _AddTutorialDialogState();
}

class _AddTutorialDialogState extends State<_AddTutorialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  
  String? _selectedCategory;
  bool _isSaving = false;

  final List<String> _categories = [
    "Login", "Dashboard", "QubiQ Studio", "LogicLogic", 
    "Python Workbench", "Content Hub", "Operations", "Accounts"
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a category")));
      return;
    }

    setState(() => _isSaving = true);
    
    final t = TutorialModel(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _selectedCategory!,
      youtubeUrl: _urlCtrl.text.trim(),
    );

    final success = await context.read<TutorialProvider>().addTutorial(t);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tutorial added!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add tutorial")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _C.bg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _C.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.video_library, color: _C.accent),
                        ),
                        const SizedBox(width: 16),
                        const Text("New Tutorial", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: _C.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    _buildTextField(_titleCtrl, "Tutorial Title", Icons.title),
                    const SizedBox(height: 16),
                    _buildTextField(_descCtrl, "Description", Icons.description, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField(_urlCtrl, "YouTube Link (e.g. https://youtube.com/...)", Icons.link),
                    const SizedBox(height: 24),
                    
                    const Text("Category", style: TextStyle(color: _C.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          value: _selectedCategory,
                          hint: const Text("Select Category", style: TextStyle(color: _C.textMuted)),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v as String),
                          isExpanded: true,
                          dropdownColor: _C.surface,
                          icon: const Icon(Icons.keyboard_arrow_down, color: _C.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                            : const Text("Save Tutorial", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.textMuted),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
          child: Icon(icon, color: _C.textSecondary, size: 20),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
