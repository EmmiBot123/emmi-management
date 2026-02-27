import 'package:flutter/material.dart';
import '../../Model/Testing/feedback_model.dart';
import '../../Repository/Testing/testing_repository.dart';

class TestingFeedbackListPage extends StatefulWidget {
  const TestingFeedbackListPage({super.key});

  @override
  State<TestingFeedbackListPage> createState() =>
      _TestingFeedbackListPageState();
}

class _TestingFeedbackListPageState extends State<TestingFeedbackListPage> {
  final TestingRepository _repository = TestingRepository();
  bool _isLoading = true;
  List<TestingFeedback> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    setState(() => _isLoading = true);
    final data = await _repository.getAllFeedback();
    setState(() {
      _feedbackList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Testing Feedback"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFeedback,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedbackList.isEmpty
              ? const Center(child: Text("No testing feedback found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _feedbackList.length,
                  itemBuilder: (context, index) {
                    final fb = _feedbackList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  fb.section,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "${fb.createdAt.day}/${fb.createdAt.month}/${fb.createdAt.year} ${fb.createdAt.hour}:${fb.createdAt.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Submitted by: ${fb.createdByName}",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Divider(),
                            if (fb.errorText.isNotEmpty) ...[
                              const Text(
                                "Reported Error:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(fb.errorText),
                              const SizedBox(height: 8),
                            ],
                            if (fb.updateText.isNotEmpty) ...[
                              const Text(
                                "Suggested Update:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(fb.updateText),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
