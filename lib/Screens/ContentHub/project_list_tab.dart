import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/ProjectProvider.dart';
import 'create_project_dialog.dart';

class ProjectListTab extends StatefulWidget {
  const ProjectListTab({super.key});

  @override
  State<ProjectListTab> createState() => _ProjectListTabState();
}

class _ProjectListTabState extends State<ProjectListTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Projects",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final result = await showDialog(context: context, builder: (_) => const CreateProjectDialog());
                  if (result != null) {
                    final success = await provider.addProject(result);
                    if (success) {
                      if (result.status == "Published") {
                        await provider.syncProjectToQubiq(result);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project created successfully")));
                      }
                    }
                  }
                },
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF9333EA)), // Purple color
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF9333EA)))
              : provider.projects.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      physics: const BouncingScrollPhysics(),
                      itemCount: provider.projects.length,
                      itemBuilder: (context, index) {
                        final project = provider.projects[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9333EA).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF9333EA), size: 20),
                            ),
                            title: Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildStatusBadge(project.status, project.scheduledPublishDate),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        project.description,
                                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () async {
                              final result = await showDialog(context: context, builder: (_) => CreateProjectDialog(project: project));
                              if (result != null) {
                                final success = await provider.updateProject(result);
                                if (success) {
                                  if (result.status == "Published") {
                                    await provider.syncProjectToQubiq(result);
                                  }
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project updated successfully")));
                                }
                              }
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                  onPressed: () async {
                                    final result = await showDialog(context: context, builder: (_) => CreateProjectDialog(project: project));
                                    if (result != null) {
                                      final success = await provider.updateProject(result);
                                      if (success) {
                                        if (result.status == "Published") {
                                          await provider.syncProjectToQubiq(result);
                                        }
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project updated successfully")));
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                                  onPressed: () => _confirmDelete(context, provider, project.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code_off_rounded,
              size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No projects found",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, DateTime? scheduledDate) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status) {
      case 'Published':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade400;
        break;
      case 'Scheduled':
        bgColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue.shade400;
        icon = Icons.access_time_rounded;
        break;
      case 'Archived':
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey.shade400;
        break;
      default: // Draft
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ProjectProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Project?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to permanently delete this project?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteProject(id);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project deleted successfully")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete project. Please check your backend connection.")));
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
