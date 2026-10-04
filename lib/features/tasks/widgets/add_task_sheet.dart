import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/recurrence_rule.dart';
import '../../categories/providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../../../widgets/wallpaper_picker_tile.dart';
import '../../../services/media_import_service.dart';
import '../utils/task_ui_helpers.dart';

void showAddTaskSheet(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDueDate;
    DateTime? selectedReminderTime;
    int selectedPriority = 0; // Low
    RecurrenceFrequency selectedFrequency = RecurrenceFrequency.none;
    String? selectedCategoryId;
    String? pickedWallpaperPath;
    String? pickedSoundPath;

    final categories = ref.read(categoryListProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
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
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Create New Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'What needs to be done?',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Notes / Description',
                        hintText: 'Add some details...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priority selector chips
                    const Text('Priority Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        final isSelected = selectedPriority == index;
                        return ChoiceChip(
                          label: Text(priorityLabel(index), style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedPriority = index);
                            }
                          },
                          selectedColor: priorityBgColor(index),
                          labelStyle: TextStyle(
                            color: isSelected ? priorityTextColor(index) : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Category assignment dropdown
                    if (categories.isNotEmpty) ...[
                      const Text('Assign Category Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: selectedCategoryId,
                        hint: const Text('Select a category', style: TextStyle(fontSize: 13)),
                        items: categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.uuid,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: Color(c.colorValue), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(c.name, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() => selectedCategoryId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Timing Row (Due Date & Reminder)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                if (!context.mounted) return;
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setSheetState(() {
                                    selectedDueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0058BE)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedDueDate != null ? formatDate(selectedDueDate!) : 'Set Due Date',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                if (!context.mounted) return;
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setSheetState(() {
                                    selectedReminderTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.notifications_active_rounded, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedReminderTime != null ? formatDate(selectedReminderTime!) : 'Set Reminder',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Recurrence selector
                    const Text('Repeat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<RecurrenceFrequency>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: selectedFrequency,
                      items: RecurrenceFrequency.values.map((f) {
                        return DropdownMenuItem<RecurrenceFrequency>(
                          value: f,
                          child: Text(recurrenceLabel(f), style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedFrequency = val);
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // Custom Wallpaper Import widget
                    WallpaperPickerTile(
                      currentWallpaperPath: pickedWallpaperPath,
                      onPicked: (path) {
                        setSheetState(() {
                          pickedWallpaperPath = path;
                        });
                      },
                      label: 'Custom Banner Wallpaper',
                    ),
                    const SizedBox(height: 10),

                    // Custom Alarm Audio Import widget
                    Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final path = await MediaImportService.pickAndSaveAudio();
                          if (path != null) {
                            setSheetState(() {
                              pickedSoundPath = path;
                            });
                          }
                        },
                        child: Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.audiotrack_rounded, color: Colors.orange, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Task Specific Sound', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                      pickedSoundPath != null ? 'Sound imported successfully' : 'Tap to pick custom notification ringtone',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isNotEmpty) {
                            ref.read(taskListProvider.notifier).addTask(
                                  title: title,
                                  notes: notesController.text.trim(),
                                  dueDate: selectedDueDate,
                                  reminderAt: selectedReminderTime,
                                  priority: selectedPriority,
                                  categoryIds: selectedCategoryId != null ? [selectedCategoryId!] : const [],
                                  wallpaperPath: pickedWallpaperPath,
                                  soundPath: pickedSoundPath,
                                  recurrence: selectedFrequency == RecurrenceFrequency.none
                                      ? null
                                      : RecurrenceRule(frequency: selectedFrequency),
                                );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0058BE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Add Task To Flow', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
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
