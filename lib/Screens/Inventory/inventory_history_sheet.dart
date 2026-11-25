import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Model/Inventory/InventoryComponent.dart';
import '../../Model/Inventory/InventoryLog.dart';
import '../../Providers/Inventory/InventoryProvider.dart';
import '../../Resources/theme_constants.dart';

class InventoryHistorySheet extends StatefulWidget {
  final InventoryComponent? targetComponent;

  const InventoryHistorySheet({
    super.key,
    this.targetComponent,
  });

  static void show(BuildContext context, {InventoryComponent? targetComponent}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => InventoryHistorySheet(targetComponent: targetComponent),
    );
  }

  @override
  State<InventoryHistorySheet> createState() => _InventoryHistorySheetState();
}

class _InventoryHistorySheetState extends State<InventoryHistorySheet> {
  String _searchQuery = '';
  String _actionFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isSpecificComponent = widget.targetComponent != null;

    final rawLogs = isSpecificComponent
        ? provider.getLogsForComponent(widget.targetComponent!.id)
        : provider.logs;

    final filteredLogs = rawLogs.where((log) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchComp = log.componentName.toLowerCase().contains(q);
        final matchUser = log.performedBy.toLowerCase().contains(q);
        final matchNote = log.note.toLowerCase().contains(q);
        final matchShelf = (log.newShelf ?? '').toLowerCase().contains(q) ||
            (log.previousShelf ?? '').toLowerCase().contains(q);
        if (!matchComp && !matchUser && !matchNote && !matchShelf) {
          return false;
        }
      }

      if (_actionFilter == 'SHELF' &&
          log.actionType != InventoryActionType.shelfMoved) {
        return false;
      }
      if (_actionFilter == 'QTY' &&
          log.actionType != InventoryActionType.qtyAdjusted &&
          log.actionType != InventoryActionType.qtySet) {
        return false;
      }
      if (_actionFilter == 'ADD_DEL' &&
          log.actionType != InventoryActionType.created &&
          log.actionType != InventoryActionType.deleted) {
        return false;
      }

      return true;
    }).toList();

    final width = MediaQuery.of(context).size.width.clamp(340.0, 720.0);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: width,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              children: [
                // ── Header ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 18),
                  decoration: BoxDecoration(
                    color: AppColors.bg.withValues(alpha: 0.6),
                    border: Border(
                      bottom: BorderSide(color: AppColors.surfaceLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF38BDF8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSpecificComponent
                                  ? "History: ${widget.targetComponent!.name}"
                                  : "Stock Movement & Audit Trail",
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSpecificComponent
                                  ? "Shelf ${widget.targetComponent!.shelfNumber} • ${widget.targetComponent!.displayQuantity}"
                                  : "Real-time log of shelf changes, stock movements, and additions",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),

                // ── Search & Filter Controls ──
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search input
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: isSpecificComponent
                              ? "Search note, reason, or staff member..."
                              : "Search component, shelf, user, or note...",
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.bg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.surfaceLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.surfaceLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("ALL", "All Activity"),
                            const SizedBox(width: 6),
                            _buildFilterChip("SHELF", "Shelf Moves"),
                            const SizedBox(width: 6),
                            _buildFilterChip("QTY", "Stock Adjustments"),
                            const SizedBox(width: 6),
                            _buildFilterChip("ADD_DEL", "Created / Deleted"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Timeline List ──
                Expanded(
                  child: provider.isLoadingLogs && rawLogs.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        )
                      : filteredLogs.isEmpty
                          ? _buildEmptyState(rawLogs.isEmpty)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                              itemCount: filteredLogs.length,
                              itemBuilder: (context, index) {
                                final log = filteredLogs[index];
                                final isLast = index == filteredLogs.length - 1;
                                return _buildTimelineItem(log, isLast, isMobile);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _actionFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _actionFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(InventoryLog log, bool isLast, bool isMobile) {
    final timeStr = DateFormat('MMM d, yyyy • h:mm a').format(log.timestamp);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Vertical Line & Icon ──
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: log.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: log.color, width: 1.5),
              ),
              child: Icon(log.icon, size: 16, color: log.color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 64,
                color: AppColors.surfaceLight,
              ),
          ],
        ),
        const SizedBox(width: 14),

        // ── Details Content ──
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Action Title + Timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.actionTitle,
                      style: TextStyle(
                        color: log.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Component Name & Change Description
                Text(
                  log.componentName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  log.actionDescription,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                // Highlighted pills (Shelf pill or Quantity change pill)
                if (log.previousShelf != null && log.newShelf != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.previousShelf!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF38BDF8),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          log.newShelf!,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Note & Performed By Footer
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (log.note.isNotEmpty)
                      Expanded(
                        child: Text(
                          "“${log.note}”",
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            log.performedBy,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isLogEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isLogEmpty
                  ? "No Activity Recorded Yet"
                  : "No Logs Match Your Filter",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isLogEmpty
                  ? "Changes such as shelf relocations, stock adjustments, and component additions will appear here automatically."
                  : "Try clearing search keywords or choosing 'All Activity'.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
