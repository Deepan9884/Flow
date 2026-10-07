import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/task.dart';
import '../models/recurrence_rule.dart';
import '../providers/task_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../../widgets/task_banner_card.dart';
import '../../../services/media_import_service.dart';
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
                              await ref.read(taskListProvider.notifier).updateTaskReminder(
                                    liveTask.uuid,
                                    DateTime(date.year, date.month, date.day, time.hour, time.minute),
                                  );
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
                              await ref.read(taskListProvider.notifier).updateTaskReminder(
                                    liveTask.uuid,
                                    DateTime(date.year, date.month, date.day, time.hour, time.minute),
                                  );
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
                          final date = await showDatePicker(
                            context: context,
                            initialDate: currentDue,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (date != null) {
                            if (!context.mounted) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(currentDue),
                            );
                            if (time != null) {
                              await ref.read(taskListProvider.notifier).updateTaskDueDate(
                                    liveTask.uuid,
                                    DateTime(date.year, date.month, date.day, time.hour, time.minute),
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
                              await ref.read(taskListProvider.notifier).updateTaskDueDate(
                                    liveTask.uuid,
                                    DateTime(date.year, date.month, date.day, time.hour, time.minute),
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

                    // Recurrence
                    if (liveTask.recurrence != null &&
                        liveTask.recurrence!.frequency != RecurrenceFrequency.none) ...[
                      Row(
                        children: [
                          const Icon(Icons.repeat_rounded, size: 16, color: Color(0xFF0058BE)),
                          const SizedBox(width: 8),
                          const Text('Repeats: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(recurrenceLabel(liveTask.recurrence!.frequency),
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

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
                            final path = await MediaImportService.pickAndSaveAudio();
                            if (path != null) {
                              await ref.read(taskListProvider.notifier).updateTaskSound(liveTask.uuid, path);
                              setDetailState(() {});
                            }
                          },
                          icon: const Icon(Icons.music_note_rounded, size: 16),
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

