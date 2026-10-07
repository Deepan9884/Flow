import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/recurrence_rule.dart';
import '../../categories/providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../../../widgets/wallpaper_picker_tile.dart';
import '../../../services/media_import_service.dart';
import 'package:intl/intl.dart';
import '../utils/task_ui_helpers.dart';

void showAddTaskSheet(BuildContext context, WidgetRef ref, {int initialPriority = 0}) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool hasSelectedDate = false;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedCompletionTime;
    int selectedPriority = initialPriority;
    RecurrenceFrequency selectedFrequency = RecurrenceFrequency.none;
    String? selectedCategoryId;
    String? pickedWallpaperPath;
    double pickedWallpaperOffsetY = 0.0;
    String? pickedSoundPath;

    final categories = ref.read(categoryListProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
              builder: (context, setSheetState) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final borderColor = isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.1);
                const focusedBorderColor = Color(0xFF0058BE);

                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
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
                        const SizedBox(height: 18),
                        Text(
                          'Create New Task',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: titleController,
                          onChanged: (_) => setSheetState(() {}),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Task Title',
                            hintText: 'What needs to be done?',
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: focusedBorderColor, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Notes / Description',
                            hintText: 'Add some details...',
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: focusedBorderColor, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Priority selector chips
                        Text(
                          'Priority Level',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white60 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(4, (index) {
                            final isSelected = selectedPriority == index;
                            final color = priorityTextColor(index);
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 0 : 3.5,
                                  right: index == 3 ? 0 : 3.5,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() => selectedPriority = index);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark ? color.withOpacity(0.22) : priorityBgColor(index))
                                          : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : borderColor,
                                        width: isSelected ? 1.5 : 0.9,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      priorityLabel(index),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected
                                            ? (isDark ? Colors.white : color)
                                            : (isDark ? Colors.white60 : Colors.black54),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Category assignment dropdown
                        if (categories.isNotEmpty) ...[
                          Text(
                            'Assign Category Tag',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: focusedBorderColor, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            dropdownColor: isDark
                                ? const Color(0xFF242424)
                                : Colors.white,
                            value: selectedCategoryId,
                            hint: const Text('Select a category',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 13)),
                            items: categories.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.uuid,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                          color: Color(c.colorValue),
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
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

                    // Schedule & Timings Section
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF0058BE)),
                        const SizedBox(width: 6),
                        const Text(
                          'Schedule & Timings',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0058BE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Auto 5m/10m Alerts',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0058BE),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 1. Task Date Selector Card
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedDate = picked;
                            hasSelectedDate = true;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: hasSelectedDate
                                ? const Color(0xFF0058BE).withOpacity(0.5)
                                : Colors.grey.withOpacity(0.25),
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: hasSelectedDate
                              ? const Color(0xFF0058BE).withOpacity(0.04)
                              : null,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF0058BE)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Task Date',
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _formatDateDisplay(selectedDate, hasSelectedDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(Icons.edit_calendar_rounded, size: 16, color: Colors.grey[500]),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 2. Start Time & Completion Time Pickers Side-by-Side
                    Row(
                      children: [
                        // Start Time Card (Reminds 5m before)
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedStartTime ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                setSheetState(() {
                                  selectedStartTime = time;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedStartTime != null
                                      ? const Color(0xFF0058BE).withOpacity(0.6)
                                      : Colors.grey.withOpacity(0.25),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: selectedStartTime != null
                                    ? const Color(0xFF0058BE).withOpacity(0.05)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.play_circle_outline_rounded, size: 15, color: Color(0xFF0058BE)),
                                      const SizedBox(width: 5),
                                      const Expanded(
                                        child: Text(
                                          'Start Time',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (selectedStartTime != null)
                                        GestureDetector(
                                          onTap: () => setSheetState(() => selectedStartTime = null),
                                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    selectedStartTime != null
                                        ? selectedStartTime!.format(context)
                                        : 'Set Start',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selectedStartTime != null ? FontWeight.bold : FontWeight.normal,
                                      color: selectedStartTime != null ? null : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Reminds 5m before',
                                    style: TextStyle(fontSize: 9.5, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Completion Time Card (Checks in 10m before)
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedCompletionTime ?? TimeOfDay.now(),
                              );
                              if (time != null) {
                                setSheetState(() {
                                  selectedCompletionTime = time;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedCompletionTime != null
                                      ? const Color(0xFFF59E0B).withOpacity(0.7)
                                      : Colors.grey.withOpacity(0.25),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: selectedCompletionTime != null
                                    ? const Color(0xFFF59E0B).withOpacity(0.06)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.flag_outlined, size: 15, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 5),
                                      const Expanded(
                                        child: Text(
                                          'Completion Time',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (selectedCompletionTime != null)
                                        GestureDetector(
                                          onTap: () => setSheetState(() => selectedCompletionTime = null),
                                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    selectedCompletionTime != null
                                        ? selectedCompletionTime!.format(context)
                                        : 'Set Finish',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selectedCompletionTime != null ? FontWeight.bold : FontWeight.normal,
                                      color: selectedCompletionTime != null ? null : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Checks in 10m before',
                                    style: TextStyle(fontSize: 9.5, color: Colors.grey),
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
                    Text(
                      'Repeat',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<RecurrenceFrequency>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: focusedBorderColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      dropdownColor:
                          isDark ? const Color(0xFF242424) : Colors.white,
                      value: selectedFrequency,
                      items: RecurrenceFrequency.values.map((f) {
                        return DropdownMenuItem<RecurrenceFrequency>(
                          value: f,
                          child: Text(
                            recurrenceLabel(f),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedFrequency = val);
                        }
                      },
                    ),
                    const SizedBox(height: 18),

                    // Custom Wallpaper Import with Live Overlay Preview & Cropping
                    WallpaperPickerTile(
                      currentWallpaperPath: pickedWallpaperPath,
                      currentOffsetY: pickedWallpaperOffsetY,
                      previewTitle: titleController.text,
                      onPicked: (path) {
                        setSheetState(() {
                          pickedWallpaperPath = path;
                        });
                      },
                      onOffsetChanged: (v) {
                        setSheetState(() {
                          pickedWallpaperOffsetY = v;
                        });
                      },
                      label: 'Custom Banner Wallpaper',
                    ),
                    const SizedBox(height: 12),

                    // Custom Alarm Audio Import widget
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final path = await MediaImportService.pickAndSaveAudio();
                          if (path != null) {
                            setSheetState(() {
                              pickedSoundPath = path;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.audiotrack_rounded,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Task Specific Sound',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      pickedSoundPath != null
                                          ? 'Sound configured for this task'
                                          : 'Tap to pick custom notification ringtone',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (pickedSoundPath != null)
                                InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      pickedSoundPath = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark ? Colors.white38 : Colors.black26,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isNotEmpty) {
                            DateTime? finalStartTime;
                            if (selectedStartTime != null) {
                              finalStartTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedStartTime!.hour,
                                selectedStartTime!.minute,
                              );
                            }

                            DateTime? finalDueDate;
                            if (selectedCompletionTime != null) {
                              finalDueDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedCompletionTime!.hour,
                                selectedCompletionTime!.minute,
                              );
                            } else if (hasSelectedDate) {
                              finalDueDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                23,
                                59,
                              );
                            }

                            ref.read(taskListProvider.notifier).addTask(
                                  title: title,
                                  notes: notesController.text.trim(),
                                  dueDate: finalDueDate,
                                  reminderAt: finalStartTime,
                                  priority: selectedPriority,
                                  categoryIds: selectedCategoryId != null ? [selectedCategoryId!] : const [],
                                  wallpaperPath: pickedWallpaperPath,
                                  wallpaperOffsetY: pickedWallpaperOffsetY,
                                  soundPath: pickedSoundPath,
                                  recurrence: selectedFrequency == RecurrenceFrequency.none
                                      ? null
                                      : RecurrenceRule(frequency: selectedFrequency),
                                );
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.add_task_rounded, size: 20),
                        label: const Text(
                          'Add Task To Flow',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0058BE),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

String _formatDateDisplay(DateTime dt, bool hasCustom) {
  final now = DateTime.now();
  final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final tomorrow = now.add(const Duration(days: 1));
  final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;

  if (isToday) {
    return 'Today (${DateFormat('MMM d').format(dt)})';
  } else if (isTomorrow) {
    return 'Tomorrow (${DateFormat('MMM d').format(dt)})';
  } else {
    return DateFormat('EEE, MMM d, y').format(dt);
  }
}
