import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Testing/feedback_model.dart';
import '../../Repository/Testing/testing_repository.dart';
import '../../Providers/AuthProvider.dart';
import '../../Resources/theme_constants.dart';

class TestingPage extends StatefulWidget {
  const TestingPage({super.key});

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  Widget _buildFeedbackForm(String sectionName) {
    return _FeedbackForm(sectionName: sectionName);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text(
            "Quality Assurance",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Student", icon: Icon(Icons.school_outlined, size: 20)),
              Tab(text: "Teacher", icon: Icon(Icons.person_outline, size: 20)),
              Tab(text: "Admin", icon: Icon(Icons.admin_panel_settings_outlined, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFeedbackForm("Student Section"),
            _buildFeedbackForm("Teacher Section"),
            _buildFeedbackForm("School Admin Section"),
          ],
        ),
      ),
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  final String sectionName;

  const _FeedbackForm({required this.sectionName});

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _errorController = TextEditingController();
  final _updateController = TextEditingController();
  final TestingRepository _repository = TestingRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _errorController.dispose();
    _updateController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      final errorText = _errorController.text.trim();
      final updateText = _updateController.text.trim();

      if (errorText.isEmpty && updateText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter an error or suggest an update')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final auth = context.read<AuthProvider>();
      final userId = auth.userId ?? 'Unknown';

      final userName = auth.name ?? 'Unknown User';

      final feedback = TestingFeedback(
        section: widget.sectionName,
        errorText: errorText,
        updateText: updateText,
        createdAt: DateTime.now(),
        createdByUserId: userId,
        createdByName: userName,
      );

      final success = await _repository.submitFeedback(feedback);

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data submitted for ${widget.sectionName}')),
        );
        _errorController.clear();
        _updateController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to submit data. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bug_report_outlined, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Report - ${widget.sectionName}",
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel("DESCRIPTION OF ERROR"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _errorController,
                    hint: "What went wrong? Be specific...",
                    icon: Icons.error_outline,
                  ),
                  const SizedBox(height: 24),
                  _buildLabel("PROPOSED IMPROVEMENT"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _updateController,
                    hint: "How should it work instead?",
                    icon: Icons.auto_fix_high_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            "SUBMIT FEEDBACK",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: AppColors.bg,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
      ),
    );
  }
}
