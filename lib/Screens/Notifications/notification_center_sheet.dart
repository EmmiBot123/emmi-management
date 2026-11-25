import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/Notifications/SystemNotificationModel.dart';
import '../../Providers/AuthProvider.dart';
import '../../Providers/Notifications/NotificationProvider.dart';

// ─── Theme Colors ───
class _C {
  static const surface = Color(0xFF1A1D27);
  static const surfaceLight = Color(0xFF242836);
  static const accent = Color(0xFF6C63FF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B8FA3);
  static const textMuted = Color(0xFF565B73);
  static const danger = Color(0xFFFF4D4F);
  static const warning = Color(0xFFFAAD14);
  static const success = Color(0xFF52C41A);
}

class NotificationCenterSheet extends StatefulWidget {
  final void Function(String route)? onNavigate;

  const NotificationCenterSheet({super.key, this.onNavigate});

  static Future<void> show(BuildContext context, {void Function(String route)? onNavigate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationCenterSheet(onNavigate: onNavigate),
    );
  }

  @override
  State<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'INVENTORY',
    'OPERATIONS',
    'ACCOUNTS',
    'SYSTEM',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final userId = auth.userId ?? 'anonymous';
    final userRole = auth.role ?? 'USER';

    final allForRole = notificationProvider.getNotificationsForUser(
      userId,
      userRole,
      categoryFilter: _selectedCategory,
    );
    final unreadCount = notificationProvider.getUnreadCount(userId, userRole);
    final isStaffAdmin = userRole.toUpperCase().contains('ADMIN') ||
        userRole.toUpperCase().contains('SUPER_ADMIN');

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.textMuted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: _C.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Notifications & Alerts',
                            style: TextStyle(
                              color: _C.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _C.danger,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount new',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Workshop telemetry, inventory thresholds & team notices',
                        style: TextStyle(color: _C.textSecondary.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: _C.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark Read', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      notificationProvider.markAllAsRead(userId, userRole);
                    },
                  ),
                if (isStaffAdmin)
                  IconButton(
                    tooltip: 'Send Team Announcement',
                    icon: const Icon(Icons.add_alert_rounded, color: _C.textSecondary, size: 20),
                    onPressed: () => _showBroadcastDialog(context, notificationProvider, userRole),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _C.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Filter chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(
                    cat == 'ALL' ? 'All Alerts' : cat[0] + cat.substring(1).toLowerCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : _C.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _C.accent,
                  backgroundColor: _C.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),

          const Divider(color: _C.surfaceLight, height: 16),

          // Notification List
          Expanded(
            child: allForRole.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: allForRole.length,
                    itemBuilder: (context, idx) {
                      final item = allForRole[idx];
                      final isRead = item.isReadByUser(userId);

                      return _NotificationCard(
                        item: item,
                        isRead: isRead,
                        onTap: () {
                          if (!isRead) {
                            notificationProvider.markAsRead(item.id, userId);
                          }
                          if (item.actionRoute != null && widget.onNavigate != null) {
                            Navigator.pop(context);
                            widget.onNavigate!(item.actionRoute!);
                          }
                        },
                        onDismiss: () {
                          notificationProvider.deleteNotification(item.id);
                        },
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _C.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: _C.textMuted.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: _C.success,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              color: _C.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No notifications or alerts pending for your role.',
            style: TextStyle(color: _C.textSecondary.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(
    BuildContext context,
    NotificationProvider provider,
    String currentRole,
  ) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String category = 'GENERAL';
    String priority = 'MEDIUM';
    String targetRole = 'ALL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _C.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _C.surfaceLight),
          ),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: _C.accent),
              SizedBox(width: 10),
              Text('Broadcast Announcement', style: TextStyle(color: _C.textPrimary, fontSize: 17)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Alert Title',
                      labelStyle: const TextStyle(color: _C.textSecondary),
                      filled: true,
                      fillColor: _C.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Message Body',
                      labelStyle: const TextStyle(color: _C.textSecondary),
                      filled: true,
                      fillColor: _C.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          dropdownColor: _C.surface,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            labelStyle: const TextStyle(color: _C.textSecondary),
                            filled: true,
                            fillColor: _C.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'LOW', child: Text('Low')),
                            DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                            DropdownMenuItem(value: 'HIGH', child: Text('High')),
                            DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                          ],
                          onChanged: (val) => setDialogState(() => priority = val ?? 'MEDIUM'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          dropdownColor: _C.surface,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: const TextStyle(color: _C.textSecondary),
                            filled: true,
                            fillColor: _C.surfaceLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                            DropdownMenuItem(value: 'INVENTORY', child: Text('Inventory')),
                            DropdownMenuItem(value: 'OPERATIONS', child: Text('Operations')),
                            DropdownMenuItem(value: 'ACCOUNTS', child: Text('Accounts')),
                            DropdownMenuItem(value: 'SYSTEM', child: Text('System')),
                          ],
                          onChanged: (val) => setDialogState(() => category = val ?? 'GENERAL'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: targetRole,
                    dropdownColor: _C.surface,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Target Department',
                      labelStyle: const TextStyle(color: _C.textSecondary),
                      filled: true,
                      fillColor: _C.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Departments')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Administrators Only')),
                      DropdownMenuItem(value: 'ASSEMBLY_TEAM', child: Text('Assembly Team')),
                      DropdownMenuItem(value: 'INSTALLATION_TEAM', child: Text('Installation Team')),
                      DropdownMenuItem(value: 'ACCOUNTS', child: Text('Accounts & Finance')),
                      DropdownMenuItem(value: 'MARKETING', child: Text('Marketing & Sales')),
                    ],
                    onChanged: (val) => setDialogState(() => targetRole = val ?? 'ALL'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _C.textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Broadcast Alert'),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final body = msgCtrl.text.trim();
                if (title.isEmpty || body.isEmpty) return;

                Navigator.pop(ctx);
                await provider.sendNotification(
                  title: title,
                  message: body,
                  category: category,
                  priority: priority,
                  targetRole: targetRole,
                  createdBy: currentRole,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final SystemNotificationModel item;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.item,
    required this.isRead,
    required this.onTap,
    required this.onDismiss,
  });

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return _C.danger;
      case 'HIGH':
        return _C.warning;
      case 'MEDIUM':
        return _C.accent;
      case 'LOW':
      default:
        return _C.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'INVENTORY':
        return Icons.inventory_2_rounded;
      case 'OPERATIONS':
        return Icons.precision_manufacturing_outlined;
      case 'ACCOUNTS':
        return Icons.account_balance_wallet_rounded;
      case 'SYSTEM':
        return Icons.memory_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(item.priority);
    final isUrgent = item.priority.toUpperCase() == 'URGENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead ? _C.surfaceLight.withOpacity(0.5) : _C.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? _C.danger.withOpacity(0.5)
              : (isRead ? Colors.transparent : priorityColor.withOpacity(0.4)),
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category / Priority Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: priorityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!isRead)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: isRead ? _C.textSecondary : Colors.white,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(item.createdAt),
                            style: TextStyle(color: _C.textMuted.withOpacity(0.8), fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: TextStyle(
                          color: isRead ? _C.textMuted : _C.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      if (item.actionRoute != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _C.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Open in ${item.actionRoute}',
                                style: const TextStyle(
                                  color: _C.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 12, color: _C.accent),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                // Dismiss button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: _C.textMuted),
                  splashRadius: 18,
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
