import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../Model/Task_model.dart';
import '../../Providers/AuthProvider.dart';
import '../../Providers/TaskProvider.dart';
import '../CEO/task_work_thread_sheet.dart';
import '../CEO/assign_task_dialog.dart';

// ─── Modern Dark Slate & Obsidian Theme ───
class _C {
  static const surface = Color(0xFF18181B);
  static const surfaceLight = Color(0xFF242836);

  static const accent = Color(0xFF8B5CF6); // Royal Violet
  static const accentAlt = Color(0xFF38BDF8); // Cyan
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);

  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const info = Color(0xFF0EA5E9);
}

class StaffTasksSheet extends StatefulWidget {
  const StaffTasksSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StaffTasksSheet(),
    );
  }

  @override
  State<StaffTasksSheet> createState() => _StaffTasksSheetState();
}

class _StaffTasksSheetState extends State<StaffTasksSheet> {
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  bool _viewAllOrgTasks = false; // For SuperAdmin/CEO to see all tasks

  final List<String> _statuses = ['ALL', 'Pending', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final userId = auth.userId ?? '';
    final userRole = auth.role ?? 'STAFF';

    final isSuperOrCeo = userRole.toUpperCase().contains('SUPER_ADMIN') ||
        userRole.toUpperCase().contains('CEO') ||
        userRole.toUpperCase().contains('ADMIN');

    final screenHeight = MediaQuery.of(context).size.height;

    // Select the appropriate stream based on toggle
    final Stream<List<TaskModel>> taskStream = (_viewAllOrgTasks && isSuperOrCeo)
        ? taskProvider.tasksStream
        : taskProvider.getTasksForUserStream(userId, userRole);

    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: _C.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tasks & Work Updates",
                        style: TextStyle(
                          color: _C.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _viewAllOrgTasks
                            ? "All organization tasks & work threads"
                            : "Tasks assigned to you & your department",
                        style: const TextStyle(
                          color: _C.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSuperOrCeo) ...[
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: _C.accentAlt, size: 24),
                    tooltip: "Delegate New Task",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AssignTaskDialog(),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.close, color: _C.textMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Admin / CEO Toggle Tab
          if (isSuperOrCeo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _C.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewAllOrgTasks = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_viewAllOrgTasks ? _C.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Assigned To Me",
                            style: TextStyle(
                              color: !_viewAllOrgTasks ? Colors.white : _C.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewAllOrgTasks = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewAllOrgTasks ? _C.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "All Organization Tasks",
                            style: TextStyle(
                              color: _viewAllOrgTasks ? Colors.white : _C.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: _C.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: "Search tasks or assignees...",
                        hintStyle: TextStyle(color: _C.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: _C.textMuted, size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStatus = status),
                    selectedColor: _C.accent.withValues(alpha: 0.25),
                    backgroundColor: _C.surfaceLight,
                    labelStyle: TextStyle(
                      color: isSelected ? _C.accentAlt : _C.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? _C.accentAlt : Colors.transparent,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Task Stream List
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: taskStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _C.accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Error loading tasks: ${snapshot.error}",
                        style: const TextStyle(color: _C.danger, fontSize: 13),
                      ),
                    ),
                  );
                }

                var tasks = snapshot.data ?? [];

                // Filter by status
                if (_selectedStatus != 'ALL') {
                  tasks = tasks.where((t) => t.status == _selectedStatus).toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  tasks = tasks.where((t) {
                    final matchTitle = t.title.toLowerCase().contains(_searchQuery);
                    final matchDesc = t.description.toLowerCase().contains(_searchQuery);
                    final matchAssignee = t.assignedToName.toLowerCase().contains(_searchQuery);
                    return matchTitle || matchDesc || matchAssignee;
                  }).toList();
                }

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_outlined,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedStatus == 'ALL'
                              ? "No tasks assigned."
                              : "No $_selectedStatus tasks.",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Tasks assigned by leadership will appear here.",
                          style: TextStyle(color: _C.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(context, task, isSuperOrCeo);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, bool isSuperOrCeo) {
    Color priorityColor;
    switch (task.priority) {
      case 'High':
        priorityColor = _C.danger;
        break;
      case 'Low':
        priorityColor = _C.success;
        break;
      default:
        priorityColor = _C.warning;
    }

    Color statusColor;
    switch (task.status) {
      case 'Completed':
        statusColor = _C.success;
        break;
      case 'In Progress':
        statusColor = _C.info;
        break;
      default:
        statusColor = _C.warning;
    }

    final dateStr = task.createdAt != null
        ? DateFormat('MMM d, yyyy').format(task.createdAt!)
        : 'Recently';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          TaskWorkThreadSheet.show(context, task);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              left: BorderSide(color: priorityColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title + Priority & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: task.assigneeType == 'Department'
                          ? _C.accentAlt.withValues(alpha: 0.12)
                          : _C.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      task.assigneeType == 'Department' ? Icons.business_rounded : Icons.person_rounded,
                      color: task.assigneeType == 'Department' ? _C.accentAlt : _C.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Assigned to: ${task.assignedToName} (${task.assigneeType})",
                          style: const TextStyle(color: _C.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${task.priority} Priority",
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  task.description,
                  style: const TextStyle(color: _C.textMuted, fontSize: 12, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 10),

              // Bottom Action Row: Date + Chat Prompt Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: _C.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(color: _C.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.accentAlt.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _C.accentAlt.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 13, color: _C.accentAlt),
                            SizedBox(width: 5),
                            Text(
                              "Work Updates & Discussion",
                              style: TextStyle(
                                color: _C.accentAlt,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSuperOrCeo) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, color: _C.danger, size: 18),
                          tooltip: "Delete Task",
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: _C.surface,
                                title: const Text("Delete Task?", style: TextStyle(color: Colors.white)),
                                content: const Text(
                                  "This will permanently delete the task and its entire update thread.",
                                  style: TextStyle(color: _C.textSecondary, fontSize: 13),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text("Cancel", style: TextStyle(color: _C.textMuted)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: _C.danger),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && task.id != null) {
                              if (context.mounted) {
                                await context.read<TaskProvider>().deleteTask(task.id!);
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
