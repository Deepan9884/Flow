import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../../categories/models/category.dart';
import '../providers/task_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../../widgets/task_banner_card.dart';
import '../../../widgets/wallpaper_picker_tile.dart';
import '../../../services/media_import_service.dart';
import '../../../services/notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final categories = ref.watch(categoryListProvider);

    // Filter tasks based on selected category and search query
    final filteredTasks = tasks.where((task) {
      final matchesCategory = _selectedCategoryId == 'all' || task.categoryIds.contains(_selectedCategoryId);
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (task.notes != null && task.notes!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();

    // Priority tasks for the top slider (Uncompleted & High/Critical priority)
    final priorityTasks = tasks.where((t) => !t.isCompleted && t.priority >= 2).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom App Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flow Task',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF191C1D),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stay centered. Get things done.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: const Color(0xFF191C1D).withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        // Add Category Button
                        IconButton(
                          onPressed: () => _showAddCategoryDialog(context),
                          icon: const Icon(Icons.style_rounded, color: Color(0xFF0058BE), size: 26),
                          tooltip: 'Manage Categories',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Elegant Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search tasks or notes...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Priority Tasks Carousel (Interactive Tilt Banners)
            if (priorityTasks.isNotEmpty && _searchQuery.isEmpty && _selectedCategoryId == 'all')
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'HIGH PRIORITY REMINDERS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0058BE),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 156,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: priorityTasks.length,
                        itemBuilder: (context, index) {
                          final task = priorityTasks[index];
                          return Container(
                            width: 300,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: TaskBannerCard(
                              task: task,
                              onTap: () => _showTaskDetailSheet(context, task),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

            // Category Horizontal Filters
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'CATEGORIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final categoryId = isAll ? 'all' : categories[index - 1].uuid;
                        final categoryName = isAll ? 'All Tasks' : categories[index - 1].name;
                        final isSelected = _selectedCategoryId == categoryId;
                        final Color tagColor = isAll
                            ? const Color(0xFF0058BE)
                            : Color(categories[index - 1].colorValue);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              categoryName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = categoryId;
                              });
                            },
                            selectedColor: tagColor,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Task List Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TASKS (${filteredTasks.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (filteredTasks.isNotEmpty)
                      const Text(
                        'Tap for Details',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Actual Task List
            if (filteredTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No Tasks Found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a task to kickstart your productivity workflow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = filteredTasks[index];
                      // Find category color if exists
                      Color bulletColor = const Color(0xFF0058BE);
                      if (task.categoryIds.isNotEmpty) {
                        final matchedCat = categories.firstWhere(
                          (c) => c.uuid == task.categoryIds.first,
                          orElse: () => const Category(uuid: '', name: '', colorValue: 0xFF0058BE),
                        );
                        if (matchedCat.uuid.isNotEmpty) {
                          bulletColor = Color(matchedCat.colorValue);
                        }
                      }

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.withOpacity(0.12), width: 1),
                        ),
                        child: ListTile(
                          onTap: () => _showTaskDetailSheet(context, task),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: GestureDetector(
                            onTap: () => ref.read(taskListProvider.notifier).toggleTask(task.uuid),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: task.isCompleted ? const Color(0xFF0058BE) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: task.isCompleted ? const Color(0xFF0058BE) : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: task.isCompleted
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: task.isCompleted ? Colors.grey : const Color(0xFF191C1D),
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.notes != null && task.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  task.notes!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Category dot tag
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: bulletColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Due date indicator
                                  if (task.dueDate != null) ...[
                                    Icon(Icons.event_outlined, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(task.dueDate!),
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  // Subtask count helper
                                  if (task.subtasks.isNotEmpty) ...[
                                    Icon(Icons.playlist_add_check_rounded, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityBgColor(task.priority),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getPriorityLabel(task.priority),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityTextColor(task.priority),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredTasks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: const Color(0xFF0058BE),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // --- Date Formatter Helper ---
  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  // --- Priority Helpers ---
  Color _getPriorityBgColor(int priority) {
    switch (priority) {
      case 3:
        return const Color(0xFFFEE2E2); // Critical
      case 2:
        return const Color(0xFFFEF3C7); // High
      case 1:
        return const Color(0xFFDBEAFE); // Medium
      default:
        return const Color(0xFFF3F4F6); // Low
    }
  }

  Color _getPriorityTextColor(int priority) {
    switch (priority) {
      case 3:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFD97706);
      case 1:
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF4B5563);
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 3:
        return 'CRITICAL';
      case 2:
        return 'HIGH';
      case 1:
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }

  // --- Dialog & Sheets ---
  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedColorValue = 0xFF0058BE;

    final colorPresets = [
      0xFF0058BE, // Vivid Blue
      0xFF10B981, // Teal
      0xFFF59E0B, // Gold
      0xFFEF4444, // Red
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFF14B8A6, // Turquoise
      0xFF6B7280, // Charcoal
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Custom Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g., Coding Tasks',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Select Tag Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.maxFinite,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colorPresets.map((hexValue) {
                        final isSelected = selectedColorValue == hexValue;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColorValue = hexValue;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(hexValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      ref.read(categoryListProvider.notifier).addCategory(
                            name: name,
                            colorValue: selectedColorValue,
                          );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0058BE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDueDate;
    DateTime? selectedReminderTime;
    int selectedPriority = 0; // Low
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
                          label: Text(_getPriorityLabel(index), style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedPriority = index);
                            }
                          },
                          selectedColor: _getPriorityBgColor(index),
                          labelStyle: TextStyle(
                            color: isSelected ? _getPriorityTextColor(index) : Colors.black87,
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
                                      selectedDueDate != null ? _formatDate(selectedDueDate!) : 'Set Due Date',
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
                                      selectedReminderTime != null ? _formatDate(selectedReminderTime!) : 'Set Reminder',
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

                    // Custom Wallpaper Import widget
                    WallpaperPickerTile(
                      currentWallpaperPath: pickedWallpaperPath,
                      onPicked: (path) {
                        setSheetState(() {
                          pickedWallpaperPath = path;
                        });
                      },
                      label: "Custom Banner Wallpaper",
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
                                      pickedSoundPath != null ? "Sound imported successfully" : "Tap to pick custom notification ringtone",
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

  void _showTaskDetailSheet(BuildContext context, Task task) {
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

            final hasWallpaper = liveTask.wallpaperPath != null && liveTask.wallpaperPath!.isNotEmpty;
            final File? wallpaperFile = hasWallpaper ? File(liveTask.wallpaperPath!) : null;

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
                      ),
                    ),
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
                    if (liveTask.dueDate != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.event_note_rounded, size: 16, color: Color(0xFF0058BE)),
                          const SizedBox(width: 8),
                          Text('Due Date: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(_formatDate(liveTask.dueDate!), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (liveTask.reminderAt != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.alarm_on_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text('Reminder Scheduled: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(_formatDate(liveTask.reminderAt!), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),
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
}
