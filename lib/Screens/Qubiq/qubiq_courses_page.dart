import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/CourseProvider.dart';
import 'create_course_dialog.dart';

class CourseListTab extends StatefulWidget {
  const CourseListTab({super.key});

  @override
  State<CourseListTab> createState() => _CourseListTabState();
}

class _CourseListTabState extends State<CourseListTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Courses"),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Available Courses (${provider.courses.length})",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (_) => const CreateCourseDialog(),
                  );
                  if (result != null) {
                    final success = await provider.addCourse(result);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Course created successfully")),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text("Create Course"),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.courses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: provider.courses.length,
                      itemBuilder: (context, index) {
                        final course = provider.courses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading:
                                const CircleAvatar(child: Icon(Icons.book)),
                            title: Text(course.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "${course.category} • ${course.duration} • ₹${course.price}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () =>
                                  _confirmDelete(context, provider, course.id),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined,
              size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No courses found",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, CourseProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Course?"),
        content: const Text("Are you sure you want to remove this course?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              provider.deleteCourse(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
