import 'package:flutter/material.dart';
import '../Testing/testing_feedback_list_page.dart';
import 'ProductManagementPage/ProductManagementPage.dart';

class SuperAdminPage extends StatelessWidget {
  const SuperAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _box(
            context,
            title: "Product Management",
            icon: Icons.precision_manufacturing,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProductManagementPage()),
              );
            },
          ),
          _box(
            context,
            title: "Testing Feedback",
            icon: Icons.bug_report,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TestingFeedbackListPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _box(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
