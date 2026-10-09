import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/recurrence_rule.dart';
import '../../categories/providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../../../widgets/wallpaper_picker_tile.dart';
import 'sound_selection_modal.dart';
import 'package:intl/intl.dart';
import '../utils/task_ui_helpers.dart';

void showAddTaskSheet(BuildContext context, WidgetRef ref, {int initialPriority = 0}) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool hasSelectedDate = true;

    // Set intuitive default reminder: 5 minutes from now for immediate usability & testing!
    final now = DateTime.now();
    final defaultStart = now.add(const Duration(minutes: 5));
    final defaultFinish = now.add(const Duration(minutes: 35));

    TimeOfDay? selectedStartTime = TimeOfDay.fromDateTime(defaultStart);
    TimeOfDay? selectedCompletionTime = TimeOfDay.fromDateTime(defaultFinish);
    String selectedPreset = '5m'; // '2m', '5m', '15m', '1h', 'custom', 'none'

    int selectedPriority = initialPriority;
    RecurrenceFrequency selectedFrequency = RecurrenceFrequency.none;
    List<int> selectedWeekdays = [DateTime.now().weekday];
    String? selectedCategoryId;
    String? pickedWallpaperPath;
    double pickedWallpaperOffsetY = 0.0;
    String? pickedSoundPath;

    final categories = ref.read(categoryListProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final borderColor = isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.1);
                const focusedBorderColor = Color(0xFF0058BE);

                void applyPreset(String preset) {
                  final cur = DateTime.now();
                  setSheetState(() {
                    selectedPreset = preset;
                    if (preset == 'leisure') {
                      hasSelectedDate = false;
                      selectedStartTime = null;
                      selectedCompletionTime = null;
                      selectedFrequency = RecurrenceFrequency.none;
                    } else {
                      selectedDate = cur;
                      hasSelectedDate = true;
                      if (preset == '2m') {
                        selectedStartTime = TimeOfDay.fromDateTime(cur.add(const Duration(minutes: 2)));
                        selectedCompletionTime = TimeOfDay.fromDateTime(cur.add(const Duration(minutes: 15)));
                      } else if (preset == '5m') {
                        selectedStartTime = TimeOfDay.fromDateTime(cur.add(const Duration(minutes: 5)));
                        selectedCompletionTime = TimeOfDay.fromDateTime(cur.add(const Duration(minutes: 35)));
                      } else if (preset == '15m') {
                        selectedStartTime = TimeOfDay.fromDateTime(cur.add(const Duration(minutes: 15)));
                        selectedCompletionTime = TimeOfDay.fromDateTime(cur.add(const Duration(minutes: 45)));
                      } else if (preset == '1h') {
                        selectedStartTime = TimeOfDay.fromDateTime(cur.add(const Duration(hours: 1)));
                        selectedCompletionTime = TimeOfDay.fromDateTime(cur.add(const Duration(hours: 2)));
                      } else if (preset == 'none') {
                        selectedStartTime = null;
                        selectedCompletionTime = null;
                      }
                    }
                  });
                }

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
                    bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
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

                    // Schedule & Reminders Section Header
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFF0058BE)),
                        SizedBox(width: 6),
                        Text(
                          'Schedule & Reminders',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick Preset Chips for Reminders & Leisure
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip('At Leisure', 'leisure', selectedPreset, () => applyPreset('leisure'), isDark, icon: Icons.spa_rounded),
                          const SizedBox(width: 6),
                          _buildPresetChip('In 5m', '5m', selectedPreset, () => applyPreset('5m'), isDark),
                          const SizedBox(width: 6),
                          _buildPresetChip('In 15m', '15m', selectedPreset, () => applyPreset('15m'), isDark),
                          const SizedBox(width: 6),
                          _buildPresetChip('In 1h', '1h', selectedPreset, () => applyPreset('1h'), isDark),
                          const SizedBox(width: 6),
                          _buildPresetChip('Custom', 'custom', selectedPreset, () {
                            setSheetState(() => selectedPreset = 'custom');
                          }, isDark),
                          const SizedBox(width: 6),
                          _buildPresetChip('No Alert', 'none', selectedPreset, () => applyPreset('none'), isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Task Date Selector Card
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: hasSelectedDate ? selectedDate : DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedDate = picked;
                            hasSelectedDate = true;
                            if (selectedPreset == 'leisure') {
                              selectedPreset = 'custom';
                            }
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
                                : (isDark ? const Color(0xFF059669).withOpacity(0.4) : const Color(0xFFA7F3D0)),
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: hasSelectedDate
                              ? const Color(0xFF0058BE).withOpacity(0.04)
                              : (isDark ? const Color(0xFF065F46).withOpacity(0.18) : const Color(0xFFECFDF5)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasSelectedDate ? Icons.calendar_month_rounded : Icons.spa_rounded,
                              size: 18,
                              color: hasSelectedDate
                                  ? const Color(0xFF0058BE)
                                  : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasSelectedDate ? 'Task Date' : 'At Leisure Mode',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: hasSelectedDate ? Colors.grey : (isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _formatDateDisplay(selectedDate, hasSelectedDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: hasSelectedDate
                                          ? null
                                          : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasSelectedDate)
                              InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    hasSelectedDate = false;
                                    selectedStartTime = null;
                                    selectedCompletionTime = null;
                                    selectedPreset = 'leisure';
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Clear',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(Icons.close_rounded, size: 14, color: Colors.grey[500]),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Text(
                                '+ Set Date',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                ),
                              ),
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
                                  hasSelectedDate = true;
                                  selectedPreset = 'custom';
                                  // If completion time is now before or equal to start time, auto-advance it
                                  if (selectedCompletionTime != null) {
                                    final startM = time.hour * 60 + time.minute;
                                    final compM = selectedCompletionTime!.hour * 60 + selectedCompletionTime!.minute;
                                    if (compM <= startM) {
                                      final newCompM = startM + 30;
                                      selectedCompletionTime = TimeOfDay(
                                        hour: (newCompM ~/ 60) % 24,
                                        minute: newCompM % 60,
                                      );
                                    }
                                  }
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
                                          onTap: () => setSheetState(() {
                                            selectedStartTime = null;
                                            selectedPreset = 'custom';
                                          }),
                                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    selectedStartTime != null
                                        ? selectedStartTime!.format(context)
                                        : (!hasSelectedDate ? 'None (Leisure)' : 'Set Start'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selectedStartTime != null ? FontWeight.bold : FontWeight.normal,
                                      color: selectedStartTime != null ? null : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedStartTime != null ? 'Reminds 5m before' : 'Optional timer',
                                    style: const TextStyle(fontSize: 9.5, color: Colors.grey),
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
                                initialTime: selectedCompletionTime ??
                                    (selectedStartTime != null
                                        ? TimeOfDay(
                                            hour: (selectedStartTime!.hour + 1) % 24,
                                            minute: selectedStartTime!.minute,
                                          )
                                        : TimeOfDay.now()),
                              );
                              if (time != null) {
                                if (selectedStartTime != null) {
                                  final startM = selectedStartTime!.hour * 60 + selectedStartTime!.minute;
                                  final compM = time.hour * 60 + time.minute;
                                  if (compM <= startM) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Completion time must be after start time (${selectedStartTime!.format(context)}).',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                }
                                setSheetState(() {
                                  selectedCompletionTime = time;
                                  hasSelectedDate = true;
                                  selectedPreset = 'custom';
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
                                          onTap: () => setSheetState(() {
                                            selectedCompletionTime = null;
                                            selectedPreset = 'custom';
                                          }),
                                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    selectedCompletionTime != null
                                        ? selectedCompletionTime!.format(context)
                                        : (!hasSelectedDate ? 'None (No Limit)' : 'Set Finish'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selectedCompletionTime != null ? FontWeight.bold : FontWeight.normal,
                                      color: selectedCompletionTime != null ? null : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedCompletionTime != null ? 'Checks in 10m before' : 'Optional deadline',
                                    style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Recurrence customization section
                    Row(
                      children: [
                        const Icon(Icons.repeat_rounded, size: 16, color: Color(0xFF0058BE)),
                        const SizedBox(width: 6),
                        const Text(
                          'Repeat',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (selectedFrequency != RecurrenceFrequency.none)
                          Text(
                            selectedFrequency == RecurrenceFrequency.weekly
                                ? _formatWeekdaySummary(selectedWeekdays)
                                : recurrenceLabel(selectedFrequency),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0058BE),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Frequency selector pills: None, Daily, Weekly, Monthly
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFrequencyChip('None', RecurrenceFrequency.none, selectedFrequency, () {
                            setSheetState(() => selectedFrequency = RecurrenceFrequency.none);
                          }, isDark),
                          const SizedBox(width: 6),
                          _buildFrequencyChip('Daily', RecurrenceFrequency.daily, selectedFrequency, () {
                            setSheetState(() => selectedFrequency = RecurrenceFrequency.daily);
                          }, isDark),
                          const SizedBox(width: 6),
                          _buildFrequencyChip('Weekly', RecurrenceFrequency.weekly, selectedFrequency, () {
                            setSheetState(() {
                              selectedFrequency = RecurrenceFrequency.weekly;
                              if (selectedWeekdays.isEmpty) {
                                selectedWeekdays = [selectedDate.weekday];
                              }
                            });
                          }, isDark),
                          const SizedBox(width: 6),
                          _buildFrequencyChip('Monthly', RecurrenceFrequency.monthly, selectedFrequency, () {
                            setSheetState(() => selectedFrequency = RecurrenceFrequency.monthly);
                          }, isDark),
                        ],
                      ),
                    ),

                    // If Weekly selected: Show Mon-Sun interactive multi-selection
                    if (selectedFrequency == RecurrenceFrequency.weekly) ...[
                      const SizedBox(height: 12),
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
                                    color: Color(0xFF0058BE),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // 7 day circular chips: Mon..Sun
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (index) {
                                final dayNum = index + 1; // 1 = Mon .. 7 = Sun
                                final isSelected = selectedWeekdays.contains(dayNum);
                                const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
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
                                          ? const Color(0xFF0058BE)
                                          : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0058BE)
                                            : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF0058BE).withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
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

                            // Multi-select presets: Weekdays | Weekends | Every Day
                            Row(
                              children: [
                                _buildWeekdayPresetPill(
                                  'Weekdays',
                                  () {
                                    setSheetState(() => selectedWeekdays = [1, 2, 3, 4, 5]);
                                  },
                                  selectedWeekdays.length == 5 &&
                                      !selectedWeekdays.contains(6) &&
                                      !selectedWeekdays.contains(7),
                                  isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildWeekdayPresetPill(
                                  'Weekends',
                                  () {
                                    setSheetState(() => selectedWeekdays = [6, 7]);
                                  },
                                  selectedWeekdays.length == 2 &&
                                      selectedWeekdays.contains(6) &&
                                      selectedWeekdays.contains(7),
                                  isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildWeekdayPresetPill(
                                  'All 7 Days',
                                  () {
                                    setSheetState(() => selectedWeekdays = [1, 2, 3, 4, 5, 6, 7]);
                                  },
                                  selectedWeekdays.length == 7,
                                  isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

                    // Notification Sound & Testing Card
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await showSoundSelectionModal(
                            context: context,
                            currentSoundPath: pickedSoundPath,
                            onSoundSelected: (newPath) {
                              setSheetState(() {
                                pickedSoundPath = newPath;
                              });
                            },
                          );
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
                              color: pickedSoundPath != null
                                  ? Colors.orange.withOpacity(0.5)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.black.withOpacity(0.08)),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (pickedSoundPath != null ? Colors.orange : const Color(0xFF0058BE))
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  pickedSoundPath != null ? Icons.music_note_rounded : Icons.notifications_active_rounded,
                                  color: pickedSoundPath != null ? Colors.orange : const Color(0xFF0058BE),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Notification Ringtone & Sound',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pickedSoundPath != null
                                          ? 'Custom Audio: ${pickedSoundPath!.split("/").last.split("\\").last}'
                                          : 'Default System Chime • Tap to change',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? Colors.white38 : Colors.black26,
                                size: 20,
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
                            if (hasSelectedDate && selectedStartTime != null) {
                              finalStartTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedStartTime!.hour,
                                selectedStartTime!.minute,
                              );
                            }

                            DateTime? finalDueDate;
                            if (hasSelectedDate) {
                              if (selectedCompletionTime != null) {
                                finalDueDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedCompletionTime!.hour,
                                  selectedCompletionTime!.minute,
                                );
                              } else {
                                finalDueDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  23,
                                  59,
                                );
                              }
                            }

                            // Safeguard: Ensure completion deadline is not earlier than start time
                            if (finalStartTime != null && finalDueDate != null && finalDueDate.isBefore(finalStartTime)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Completion time cannot be earlier than start time.'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
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
                                      : (selectedFrequency == RecurrenceFrequency.weekly
                                          ? RecurrenceRuleExtension.weeklyWithDays(selectedWeekdays)
                                          : RecurrenceRule(frequency: selectedFrequency)),
                                );

                            Navigator.pop(context);

                            if (finalStartTime != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Task added! Reminder set for ${DateFormat('h:mm a').format(finalStartTime)}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (!hasSelectedDate) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.spa_rounded, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'At Leisure task added! Complete whenever you are free.',
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
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

Widget _buildPresetChip(
  String label,
  String value,
  String currentPreset,
  VoidCallback onTap,
  bool isDark, {
  IconData? icon,
}) {
  final isSelected = currentPreset == value;
  final primaryColor = value == 'leisure'
      ? (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
      : const Color(0xFF0058BE);

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryColor
            : (value == 'leisure'
                ? (isDark ? const Color(0xFF065F46).withOpacity(0.25) : const Color(0xFFECFDF5))
                : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9))),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (value == 'leisure'
                  ? (isDark ? const Color(0xFF059669).withOpacity(0.4) : const Color(0xFFA7F3D0))
                  : (isDark ? Colors.white12 : Colors.black12)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (value == 'leisure'
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                      : (isDark ? Colors.white70 : Colors.black87)),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (value == 'leisure'
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                      : (isDark ? Colors.white70 : Colors.black87)),
            ),
          ),
        ],
      ),
    ),
  );
}

String _formatDateDisplay(DateTime dt, bool hasCustom) {
  if (!hasCustom) {
    return 'At Leisure • Complete anytime';
  }
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

Widget _buildFrequencyChip(
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

Widget _buildWeekdayPresetPill(
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

String _formatWeekdaySummary(List<int> days) {
  if (days.isEmpty) return 'Repeats every week';
  if (days.length == 7) return 'Every single day (Mon–Sun)';
  if (days.length == 5 &&
      days.contains(1) &&
      days.contains(2) &&
      days.contains(3) &&
      days.contains(4) &&
      days.contains(5)) {
    return 'Every weekday (Mon–Fri)';
  }
  if (days.length == 2 && days.contains(6) && days.contains(7)) {
    return 'Every weekend (Sat & Sun)';
  }
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final names = days.map((d) => dayNames[d - 1]).join(', ');
  return 'Every $names';
}

