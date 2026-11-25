import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../Model/Task_model.dart';
import '../../Model/TaskMessageModel.dart';
import '../../Providers/TaskProvider.dart';
import '../../Providers/AuthProvider.dart';

class TaskWorkThreadSheet extends StatefulWidget {
  final TaskModel task;

  const TaskWorkThreadSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TaskModel task) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskWorkThreadSheet(task: task),
    );
  }

  @override
  State<TaskWorkThreadSheet> createState() => _TaskWorkThreadSheetState();
}

class _TaskWorkThreadSheetState extends State<TaskWorkThreadSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final senderId = authProvider.userId ?? '';
    final senderName = authProvider.name ?? authProvider.email ?? 'Staff Member';
    final senderRole = authProvider.role ?? 'STAFF';

    setState(() => _isSending = true);

    final message = TaskMessageModel(
      taskId: widget.task.id ?? '',
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: text,
      createdAt: DateTime.now(),
    );

    final success = await taskProvider.sendTaskMessage(widget.task.id!, message);

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _textController.clear();
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to post update. Please try again."),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleDeleteMessage(TaskMessageModel msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 8),
            Text("Delete Update?", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this work update message?",
          style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFFA1A1AA))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && msg.id != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.deleteTaskMessage(widget.task.id!, msg.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Update message deleted"),
            backgroundColor: Color(0xFF18181B),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleStatusChange(String newStatus) async {
    if (newStatus == _currentStatus) return;

    setState(() => _currentStatus = newStatus);

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await taskProvider.updateTaskStatus(widget.task.id!, newStatus);

    // Auto-post status change update in thread
    final senderName = authProvider.name ?? authProvider.email ?? 'Staff Member';
    final senderRole = authProvider.role ?? 'STAFF';

    await taskProvider.sendTaskMessage(
      widget.task.id!,
      TaskMessageModel(
        taskId: widget.task.id!,
        senderId: authProvider.userId ?? '',
        senderName: senderName,
        senderRole: senderRole,
        text: "📌 Status updated to: $newStatus",
        createdAt: DateTime.now(),
      ),
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.userId ?? '';
    final currentUserRole = auth.role ?? 'STAFF';

    Color priorityColor;
    switch (widget.task.priority) {
      case 'High':
        priorityColor = const Color(0xFFEF4444);
        break;
      case 'Low':
        priorityColor = const Color(0xFF10B981);
        break;
      default:
        priorityColor = const Color(0xFFF59E0B);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  // Handle Bar
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

                  // ════════════ HEADER ════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.assignment_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.task.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Assignee
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.task.assigneeType == 'Department'
                                              ? Icons.business_rounded
                                              : Icons.person_rounded,
                                          size: 13,
                                          color: const Color(0xFFA1A1AA),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.task.assignedToName,
                                          style: const TextStyle(
                                            color: Color(0xFFA1A1AA),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Priority
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: priorityColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      "${widget.task.priority} Priority",
                                      style: TextStyle(
                                        color: priorityColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status Switcher Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _currentStatus,
                              dropdownColor: const Color(0xFF18181B),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Pending',
                                  child: Text('Pending', style: TextStyle(color: Color(0xFFF59E0B))),
                                ),
                                DropdownMenuItem(
                                  value: 'In Progress',
                                  child: Text('In Progress', style: TextStyle(color: Color(0xFF38BDF8))),
                                ),
                                DropdownMenuItem(
                                  value: 'Completed',
                                  child: Text('Completed', style: TextStyle(color: Color(0xFF10B981))),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) _handleStatusChange(val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Description callout
                  if (widget.task.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Text(
                          widget.task.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 6),
                  Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

                  // ════════════ LIVE UPDATE MESSAGES STREAM ════════════
                  Expanded(
                    child: StreamBuilder<List<TaskMessageModel>>(
                      stream: context
                          .read<TaskProvider>()
                          .getTaskMessagesStream(widget.task.id ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 40,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No work updates posted yet.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Staff can post progress notes below to keep the team updated.",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId == currentUserId;
                            final canDelete = msg.canDelete(currentUserId, currentUserRole);

                            final isStatusNotice = msg.text.startsWith('📌 Status updated to:');

                            if (isStatusNotice) {
                              return Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF18181B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                  ),
                                  child: Text(
                                    "${msg.senderName} (${msg.senderRole}): ${msg.text.replaceAll('📌 Status updated to: ', '')} • ${DateFormat('hh:mm a').format(msg.createdAt)}",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  if (!isMe) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                      child: Text(
                                        msg.senderName.isNotEmpty
                                            ? msg.senderName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Color(0xFF8B5CF6),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                                            : const Color(0xFF18181B),
                                        borderRadius: BorderRadius.circular(16).copyWith(
                                          topLeft: isMe
                                              ? const Radius.circular(16)
                                              : const Radius.circular(4),
                                          topRight: isMe
                                              ? const Radius.circular(4)
                                              : const Radius.circular(16),
                                        ),
                                        border: Border.all(
                                          color: isMe
                                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                                              : Colors.white.withValues(alpha: 0.08),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isMe ? "You" : msg.senderName,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? const Color(0xFFC4B5FD)
                                                      : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  msg.senderRole,
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                DateFormat('hh:mm a').format(msg.createdAt),
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.35),
                                                  fontSize: 10,
                                                ),
                                              ),
                                              if (canDelete) ...[
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () => _handleDeleteMessage(msg),
                                                  child: Icon(
                                                    Icons.delete_outline_rounded,
                                                    size: 14,
                                                    color: Colors.white.withValues(alpha: 0.35),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          SelectableText(
                                            msg.text,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 10),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                      child: Text(
                                        msg.senderName.isNotEmpty
                                            ? msg.senderName[0].toUpperCase()
                                            : 'Y',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ════════════ TEXT INPUT BAR ════════════
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF09090B),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: TextField(
                                controller: _textController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _handleSendMessage(),
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: "Type work update...",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              onPressed: _isSending ? null : _handleSendMessage,
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
