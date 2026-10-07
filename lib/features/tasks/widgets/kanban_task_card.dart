import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../../categories/models/category.dart';
import '../utils/task_ui_helpers.dart';
import '../screens/kanban_screen.dart';

class KanbanTaskCard extends StatelessWidget {
  final Task task;
  final List<Category> categories;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<KanbanColumn>? onMoveColumn;
  final bool isDraggingFeedback;

  const KanbanTaskCard({
    super.key,
    required this.task,
    required this.categories,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.onMoveColumn,
    this.isDraggingFeedback = false,
  });

  Category? _resolveCategory() {
    if (task.categoryIds.isEmpty) return null;
    final id = task.categoryIds.first;
    for (final c in categories) {
      if (c.uuid == id) return c;
    }
    return null;
  }

  Color _getPriorityAccentColor() {
    if (task.isCompleted) return const Color(0xFF10B981);
    switch (task.priority) {
      case 3:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 1:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = _resolveCategory();
    final accentColor = _getPriorityAccentColor();

    final hasWallpaper = task.wallpaperPath != null &&
        task.wallpaperPath!.isNotEmpty &&
        File(task.wallpaperPath!).existsSync();

    final completedSubtasks = task.subtasks.where((s) => s.isDone).length;
    final totalSubtasks = task.subtasks.length;

    // Due date calculation
    final now = DateTime.now();
    final isOverdue = task.dueDate != null &&
        !task.isCompleted &&
        task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));

    String? formattedDueDate;
    if (task.dueDate != null) {
      final due = task.dueDate!;
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(due.year, due.month, due.day);
      final hasTime = due.hour != 23 || due.minute != 59;
      final timeSuffix = hasTime ? ', ${DateFormat('h:mm a').format(due.toLocal())}' : '';
      if (dueDay == today) {
        formattedDueDate = 'Today$timeSuffix';
      } else if (dueDay == today.add(const Duration(days: 1))) {
        formattedDueDate = 'Tomorrow$timeSuffix';
      } else {
        formattedDueDate = DateFormat(hasTime ? 'MMM d, h:mm a' : 'MMM d').format(due);
      }
    }

    final cardBackgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDraggingFeedback
        ? const Color(0xFF0058BE)
        : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isDraggingFeedback ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDraggingFeedback
                    ? const Color(0xFF0058BE).withOpacity(0.25)
                    : (isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.04)),
                blurRadius: isDraggingFeedback ? 16 : 8,
                offset: isDraggingFeedback
                    ? const Offset(0, 8)
                    : const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent color strip
                  Container(
                    width: 5,
                    color: accentColor,
                  ),
                  // Main card body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Category chip, Priority chip, Quick menu
                          Row(
                            children: [
                              if (category != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(category.colorValue)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category.name.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(category.colorValue),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (task.priority > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priorityBgColor(task.priority),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.priority_high_rounded,
                                        size: 11,
                                        color: priorityTextColor(task.priority),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        priorityLabel(task.priority),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              priorityTextColor(task.priority),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const Spacer(),
                              // Quick action popup menu
                              if (!isDraggingFeedback)
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.more_horiz_rounded,
                                      size: 18,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black45,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'todo') {
                                        onMoveColumn?.call(KanbanColumn.todo);
                                      } else if (value == 'important') {
                                        onMoveColumn
                                            ?.call(KanbanColumn.important);
                                      } else if (value == 'done') {
                                        onMoveColumn?.call(KanbanColumn.done);
                                      } else if (value == 'delete') {
                                        onDelete();
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (task.priority != 0 || task.isCompleted)
                                        const PopupMenuItem(
                                          value: 'todo',
                                          height: 36,
                                          child: Row(
                                            children: [
                                              Icon(Icons.radio_button_unchecked,
                                                  size: 16,
                                                  color: Color(0xFF0058BE)),
                                              SizedBox(width: 8),
                                              Text('Move to To Do',
                                                  style: TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      if (task.priority == 0 || task.isCompleted)
                                        const PopupMenuItem(
                                          value: 'important',
                                          height: 36,
                                          child: Row(
                                            children: [
                                              Icon(Icons.star_rounded,
                                                  size: 16,
                                                  color: Color(0xFFF59E0B)),
                                              SizedBox(width: 8),
                                              Text('Move to Important',
                                                  style: TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      if (!task.isCompleted)
                                        const PopupMenuItem(
                                          value: 'done',
                                          height: 36,
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle_outline_rounded,
                                                  size: 16,
                                                  color: Color(0xFF10B981)),
                                              SizedBox(width: 8),
                                              Text('Move to Done',
                                                  style: TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      const PopupMenuDivider(height: 8),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        height: 36,
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded,
                                                size: 16,
                                                color: Colors.redAccent),
                                            SizedBox(width: 8),
                                            Text('Delete Task',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.redAccent)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Title and Notes preview + Compact Wallpaper Thumbnail
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Toggle Checkbox
                              Padding(
                                padding: const EdgeInsets.only(right: 10, top: 2),
                                child: GestureDetector(
                                  onTap: onToggle,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: task.isCompleted
                                          ? const Color(0xFF10B981)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: task.isCompleted
                                            ? const Color(0xFF10B981)
                                            : (isDark
                                                ? Colors.white38
                                                : Colors.black26),
                                        width: 1.8,
                                      ),
                                    ),
                                    child: task.isCompleted
                                        ? const Icon(
                                            Icons.check,
                                            size: 13,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              // Title and description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: task.isCompleted
                                            ? (isDark
                                                ? Colors.white38
                                                : Colors.black38)
                                            : (isDark
                                                ? Colors.white
                                                : const Color(0xFF191C1D)),
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    if (task.notes != null &&
                                        task.notes!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        task.notes!.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Compact Wallpaper Thumbnail if task has wallpaper
                              if (hasWallpaper) ...[
                                const SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white12
                                            : Colors.black12,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.file(
                                      File(task.wallpaperPath!),
                                      fit: BoxFit.cover,
                                      alignment: Alignment(
                                          0.0,
                                          task.wallpaperOffsetY.clamp(-1.0, 1.0)),
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Footer metadata: Subtasks count, Due date, Drag handle
                          if (totalSubtasks > 0 || formattedDueDate != null || task.soundPath != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (formattedDueDate != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOverdue
                                          ? (isDark
                                              ? const Color(0xFF7F1D1D).withOpacity(0.4)
                                              : const Color(0xFFFEE2E2))
                                          : (isDark
                                              ? Colors.white.withOpacity(0.06)
                                              : Colors.grey.withOpacity(0.1)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 11,
                                          color: isOverdue
                                              ? const Color(0xFFEF4444)
                                              : (isDark
                                                  ? Colors.white60
                                                  : Colors.black54),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          formattedDueDate,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10.5,
                                            fontWeight: isOverdue
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isOverdue
                                                ? const Color(0xFFEF4444)
                                                : (isDark
                                                    ? Colors.white60
                                                    : Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (totalSubtasks > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.checklist_rounded,
                                          size: 11,
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$completedSubtasks/$totalSubtasks',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (task.soundPath != null &&
                                    task.soundPath!.isNotEmpty) ...[
                                  Icon(
                                    Icons.volume_up_rounded,
                                    size: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ],
                                const Spacer(),
                                Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
