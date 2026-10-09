import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/recurrence_rule.dart';
import '../providers/task_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../../widgets/task_banner_card.dart';
import '../../../services/media_import_service.dart';
import 'sound_selection_modal.dart';
import '../utils/task_ui_helpers.dart';

void showTaskDetailSheet(BuildContext context, WidgetRef ref, Task task) {
  final subtaskController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDetailState) {
          // Re-fetch current state of task to ensure fresh data
          final currentTasks = ref.watch(taskListProvider);
          final currentTaskIndex = currentTasks.indexWhere((t) => t.uuid == task.uuid);
          if (currentTaskIndex == -1) return const SizedBox.shrink();
          final liveTask = currentTasks[currentTaskIndex];
          final categories = ref.watch(categoryListProvider);
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Top Banner Preview with parallax/tilt
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: TaskBannerCard(
                      task: liveTask,
                      onTap: () {},
                      categoryLabel: resolveCategoryLabel(categories, liveTask),
                    ),
                  ),
                  if (liveTask.wallpaperPath != null && liveTask.wallpaperPath!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.crop_rounded, size: 14, color: Color(0xFF0058BE)),
                              const SizedBox(width: 6),
                              const Text(
                                'Crop & Position',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              _detailPresetChip('Top', -1.0, liveTask.wallpaperOffsetY, (v) {
                                ref.read(taskListProvider.notifier).updateTaskWallpaperOffset(liveTask.uuid, v);
                              }, isDark),
                              const SizedBox(width: 4),
                              _detailPresetChip('Center', 0.0, liveTask.wallpaperOffsetY, (v) {
                                ref.read(taskListProvider.notifier).updateTaskWallpaperOffset(liveTask.uuid, v);
                              }, isDark),
                              const SizedBox(width: 4),
                              _detailPresetChip('Bottom', 1.0, liveTask.wallpaperOffsetY, (v) {
                                ref.read(taskListProvider.notifier).updateTaskWallpaperOffset(liveTask.uuid, v);
                              }, isDark),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              activeTrackColor: const Color(0xFF0058BE),
                              inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                              thumbColor: const Color(0xFF0058BE),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: liveTask.wallpaperOffsetY.clamp(-1.0, 1.0),
                              min: -1.0,
                              max: 1.0,
                              onChanged: (v) {
                                ref.read(taskListProvider.notifier).updateTaskWallpaperOffset(liveTask.uuid, v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          liveTask.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Quick Completion status toggle
                      IconButton(
                        icon: Icon(
                          liveTask.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: liveTask.isCompleted ? const Color(0xFF0058BE) : Colors.grey,
                          size: 28,
                        ),
                        onPressed: () {
                          ref.read(taskListProvider.notifier).toggleTask(liveTask.uuid);
                        },
                      ),
                    ],
                  ),

                  if (liveTask.notes != null && liveTask.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      liveTask.notes!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Subtasks checklist engine
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SUBTASKS CHECKLIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                        '${liveTask.subtasks.where((s) => s.isDone).length}/${liveTask.subtasks.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0058BE)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Subtasks List
                  if (liveTask.subtasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No subtasks yet. Break it down below!', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                    )
                  else
                    Column(
                      children: liveTask.subtasks.map((sub) {
                        return CheckboxListTile(
                          value: sub.isDone,
                          onChanged: (val) {
                            ref.read(taskListProvider.notifier).toggleSubtask(liveTask.uuid, sub.uuid);
                          },
                          title: Text(
                            sub.title,
                            style: TextStyle(
                              fontSize: 13,
                              decoration: sub.isDone ? TextDecoration.lineThrough : null,
                              color: sub.isDone ? Colors.grey : Colors.black87,
                            ),
                          ),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),

                  // Subtask Add Input Line
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subtaskController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Add a subtask...',
                            isDense: true,
                            border: UnderlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0058BE)),
                        onPressed: () {
                          final text = subtaskController.text.trim();
                          if (text.isNotEmpty) {
                            ref.read(taskListProvider.notifier).addSubtask(liveTask.uuid, text);
                            subtaskController.clear();
                            setDetailState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // At Leisure Status Banner
                  if (liveTask.reminderAt == null && liveTask.dueDate == null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF065F46).withOpacity(0.22) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF059669).withOpacity(0.4) : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            size: 20,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'At Leisure Task',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No start, end, or deadlines. Complete whenever you have free time.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : const Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // If task currently has timers, provide a quick one-tap button to convert to At Leisure
                  if (liveTask.reminderAt != null || liveTask.dueDate != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          Icons.spa_rounded,
                          size: 14,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        ),
                        label: Text(
                          'Convert to At Leisure (Clear all limits & timers)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          ),
                        ),
                        onPressed: () async {
                          await ref.read(taskListProvider.notifier).updateTaskTiming(
                                liveTask.uuid,
                                startTime: null,
                                dueDate: null,
                              );
                          setDetailState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Timing Info displays
                  // 1. Start Time (Auto-reminds 5m before)
                  if (liveTask.reminderAt != null) ...[
                    InkWell(
                      onTap: () async {
                        final currentStart = liveTask.reminderAt ?? DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: currentStart,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(currentStart),
                          );
                          if (time != null) {
                            final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            // If new start time is after existing completion target, adjust target!
                            if (liveTask.dueDate != null && newStart.isAfter(liveTask.dueDate!)) {
                              final newDue = newStart.add(const Duration(hours: 1));
                              await ref.read(taskListProvider.notifier).updateTaskTiming(
                                    liveTask.uuid,
                                    startTime: newStart,
                                    dueDate: newDue,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Start time updated. Completion target moved to ${DateFormat('MMM d, h:mm a').format(newDue)}.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              await ref.read(taskListProvider.notifier).updateTaskReminder(
                                    liveTask.uuid,
                                    newStart,
                                  );
                            }
                            setDetailState(() {});
                          }
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, size: 16, color: Color(0xFF0058BE)),
                          const SizedBox(width: 8),
                          const Text('Start Time: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              '${formatDate(liveTask.reminderAt!)} (Alerts 5m before)',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            tooltip: 'Clear start time',
                            onPressed: () async {
                              await ref.read(taskListProvider.notifier).updateTaskReminder(liveTask.uuid, null);
                              setDetailState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else ...[
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            if (liveTask.dueDate != null && newStart.isAfter(liveTask.dueDate!)) {
                              final newDue = newStart.add(const Duration(hours: 1));
                              await ref.read(taskListProvider.notifier).updateTaskTiming(
                                    liveTask.uuid,
                                    startTime: newStart,
                                    dueDate: newDue,
                                  );
                            } else {
                              await ref.read(taskListProvider.notifier).updateTaskReminder(
                                    liveTask.uuid,
                                    newStart,
                                  );
                            }
                            setDetailState(() {});
                          }
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_outline_rounded, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('+ Add Start Time (Alerts 5m before)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // 2. Completion Time / Due Date (Auto-checks in 10m before)
                  if (liveTask.dueDate != null) ...[
                    InkWell(
                      onTap: () async {
                        final currentDue = liveTask.dueDate ?? DateTime.now();
                        final earliestDate = liveTask.reminderAt != null
                            ? DateTime(liveTask.reminderAt!.year, liveTask.reminderAt!.month, liveTask.reminderAt!.day)
                            : DateTime.now().subtract(const Duration(days: 365));
                        final initialPickerDate = currentDue.isBefore(earliestDate) ? earliestDate : currentDue;

                        final date = await showDatePicker(
                          context: context,
                          initialDate: initialPickerDate,
                          firstDate: earliestDate, // Cannot pick dates before start time date
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(currentDue),
                          );
                          if (time != null) {
                            final newDue = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            if (liveTask.reminderAt != null && newDue.isBefore(liveTask.reminderAt!)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Completion target cannot be earlier than start time (${DateFormat('MMM d, h:mm a').format(liveTask.reminderAt!)}).',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              return;
                            }
                            await ref.read(taskListProvider.notifier).updateTaskDueDate(
                                  liveTask.uuid,
                                  newDue,
                                );
                            setDetailState(() {});
                          }
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          const Text('Completion Target: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              '${formatDate(liveTask.dueDate!)} (Checks in 10m before)',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            tooltip: 'Clear completion time',
                            onPressed: () async {
                              await ref.read(taskListProvider.notifier).updateTaskDueDate(liveTask.uuid, null);
                              setDetailState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ] else ...[
                    InkWell(
                      onTap: () async {
                        final earliestDate = liveTask.reminderAt != null
                            ? DateTime(liveTask.reminderAt!.year, liveTask.reminderAt!.month, liveTask.reminderAt!.day)
                            : DateTime.now().subtract(const Duration(days: 365));
                        final initialDate = liveTask.reminderAt ?? DateTime.now();
                        final initialPickerDate = initialDate.isBefore(earliestDate) ? earliestDate : initialDate;

                        final date = await showDatePicker(
                          context: context,
                          initialDate: initialPickerDate,
                          firstDate: earliestDate,
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final newDue = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            if (liveTask.reminderAt != null && newDue.isBefore(liveTask.reminderAt!)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Completion target cannot be earlier than start time (${DateFormat('MMM d, h:mm a').format(liveTask.reminderAt!)}).',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              return;
                            }
                            await ref.read(taskListProvider.notifier).updateTaskDueDate(
                                  liveTask.uuid,
                                  newDue,
                                );
                            setDetailState(() {});
                          }
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('+ Add Completion Time (Checks in 10m before)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Recurrence Selector Card
                  InkWell(
                    onTap: () {
                      _showEditRecurrenceSheet(context, ref, liveTask, () {
                        setDetailState(() {});
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (liveTask.recurrence != null &&
                                  liveTask.recurrence!.frequency != RecurrenceFrequency.none)
                              ? const Color(0xFF0058BE).withOpacity(0.5)
                              : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.repeat_rounded, size: 18, color: Color(0xFF0058BE)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Repeat / Recurrence',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatRecurrenceRule(liveTask.recurrence),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: (liveTask.recurrence != null &&
                                            liveTask.recurrence!.frequency != RecurrenceFrequency.none)
                                        ? const Color(0xFF0058BE)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_rounded, size: 15, color: Colors.grey[500]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Danger / Action Row (Modify Media files & Delete)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Edit/Replace wallpaper or custom sound buttons
                      TextButton.icon(
                        onPressed: () async {
                          final path = await MediaImportService.pickAndSaveImage();
                          if (path != null) {
                            await ref.read(taskListProvider.notifier).updateTaskWallpaper(liveTask.uuid, path);
                            setDetailState(() {});
                          }
                        },
                        icon: const Icon(Icons.image_search, size: 16),
                        label: const Text('Wallpaper', style: TextStyle(fontSize: 11)),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await showSoundSelectionModal(
                            context: context,
                            currentSoundPath: liveTask.soundPath,
                            onSoundSelected: (newPath) async {
                              await ref.read(taskListProvider.notifier).updateTaskSound(liveTask.uuid, newPath);
                              setDetailState(() {});
                            },
                          );
                        },
                        icon: const Icon(Icons.notifications_active_rounded, size: 16),
                        label: const Text('Alert Sound', style: TextStyle(fontSize: 11)),
                      ),
                      // Delete Button
                      TextButton.icon(
                        onPressed: () {
                          ref.read(taskListProvider.notifier).deleteTask(liveTask.uuid);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
                        label: const Text('Delete Task', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _detailPresetChip(
  String title,
  double targetValue,
  double currentValue,
  ValueChanged<double> onSelect,
  bool isDark,
) {
  final bool isSelected = (currentValue - targetValue).abs() < 0.15;

  return GestureDetector(
    onTap: () => onSelect(targetValue),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0058BE)
            : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0058BE)
              : (isDark ? Colors.white12 : Colors.black12),
          width: 0.8,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    ),
  );
}

void _showEditRecurrenceSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
  VoidCallback onUpdated,
) {
  final currentRule = task.recurrence;
  RecurrenceFrequency selectedFrequency = currentRule?.frequency ?? RecurrenceFrequency.none;
  List<int> selectedWeekdays = currentRule != null && currentRule.daysOfWeek.isNotEmpty
      ? List<int>.from(currentRule.daysOfWeek)
      : [task.reminderAt?.weekday ?? task.dueDate?.weekday ?? DateTime.now().weekday];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          const primaryColor = Color(0xFF0058BE);

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.repeat_rounded, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Customize Task Repeat',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Frequency Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _recurrenceChip('None', RecurrenceFrequency.none, selectedFrequency, () {
                        setModalState(() => selectedFrequency = RecurrenceFrequency.none);
                      }, isDark),
                      const SizedBox(width: 6),
                      _recurrenceChip('Daily', RecurrenceFrequency.daily, selectedFrequency, () {
                        setModalState(() => selectedFrequency = RecurrenceFrequency.daily);
                      }, isDark),
                      const SizedBox(width: 6),
                      _recurrenceChip('Weekly', RecurrenceFrequency.weekly, selectedFrequency, () {
                        setModalState(() {
                          selectedFrequency = RecurrenceFrequency.weekly;
                          if (selectedWeekdays.isEmpty) {
                            selectedWeekdays = [task.reminderAt?.weekday ?? DateTime.now().weekday];
                          }
                        });
                      }, isDark),
                      const SizedBox(width: 6),
                      _recurrenceChip('Monthly', RecurrenceFrequency.monthly, selectedFrequency, () {
                        setModalState(() => selectedFrequency = RecurrenceFrequency.monthly);
                      }, isDark),
                    ],
                  ),
                ),
                if (selectedFrequency == RecurrenceFrequency.weekly) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Choose Days of the Week',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            Text(
                              '${selectedWeekdays.length} selected',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final dayNum = index + 1; // 1 = Mon .. 7 = Sun
                            final isSelected = selectedWeekdays.contains(dayNum);
                            const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    if (selectedWeekdays.length > 1) {
                                      selectedWeekdays.remove(dayNum);
                                    }
                                  } else {
                                    selectedWeekdays.add(dayNum);
                                    selectedWeekdays.sort();
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dayNames[index],
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _recurrencePresetPill(
                              'Weekdays',
                              () => setModalState(() => selectedWeekdays = [1, 2, 3, 4, 5]),
                              selectedWeekdays.length == 5 &&
                                  !selectedWeekdays.contains(6) &&
                                  !selectedWeekdays.contains(7),
                              isDark,
                            ),
                            const SizedBox(width: 6),
                            _recurrencePresetPill(
                              'Weekends',
                              () => setModalState(() => selectedWeekdays = [6, 7]),
                              selectedWeekdays.length == 2 &&
                                  selectedWeekdays.contains(6) &&
                                  selectedWeekdays.contains(7),
                              isDark,
                            ),
                            const SizedBox(width: 6),
                            _recurrencePresetPill(
                              'All 7 Days',
                              () => setModalState(() => selectedWeekdays = [1, 2, 3, 4, 5, 6, 7]),
                              selectedWeekdays.length == 7,
                              isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      RecurrenceRule? newRule;
                      if (selectedFrequency != RecurrenceFrequency.none) {
                        if (selectedFrequency == RecurrenceFrequency.weekly) {
                          newRule = RecurrenceRuleExtension.weeklyWithDays(selectedWeekdays);
                        } else {
                          newRule = RecurrenceRule(frequency: selectedFrequency);
                        }
                      }
                      await ref.read(taskListProvider.notifier).updateTaskRecurrence(task.uuid, newRule);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      onUpdated();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Recurrence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _recurrenceChip(
  String label,
  RecurrenceFrequency value,
  RecurrenceFrequency selectedValue,
  VoidCallback onTap,
  bool isDark,
) {
  final isSelected = value == selectedValue;
  const primaryColor = Color(0xFF0058BE);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor
            : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    ),
  );
}

Widget _recurrencePresetPill(
  String label,
  VoidCallback onTap,
  bool isSelected,
  bool isDark,
) {
  const primaryColor = Color(0xFF0058BE);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor.withOpacity(0.15)
            : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.white24 : Colors.grey[400]!),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
      ),
    ),
  );
}
