import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Testing/feedback_model.dart';
import '../../Repository/Testing/testing_repository.dart';
import '../../Providers/AuthProvider.dart';

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
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Student Section"),
              Tab(text: "Teacher Section"),
              Tab(text: "School Admin Section"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFeedbackForm("Student Section"),
                _buildFeedbackForm("Teacher Section"),
                _buildFeedbackForm("School Admin Section"),
              ],
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              "Enter Data - ${widget.sectionName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _errorController,
              decoration: const InputDecoration(
                labelText: 'Write Error',
                border: OutlineInputBorder(),
                hintText: 'Describe the error you encountered',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _updateController,
              decoration: const InputDecoration(
                labelText: 'Suggest an Update',
                border: OutlineInputBorder(),
                hintText: 'Provide your suggestions for an update',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitData,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Submitting...' : 'Submit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
