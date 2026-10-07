import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/task_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/models/category.dart';
import '../models/task.dart';
import '../widgets/kanban_task_card.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/add_task_sheet.dart';
import '../../../core/theme/theme_provider.dart';

enum KanbanColumn { todo, important, done }

class KanbanScreen extends ConsumerStatefulWidget {
  const KanbanScreen({super.key});

  @override
  ConsumerState<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends ConsumerState<KanbanScreen> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _moveTaskToColumn(Task task, KanbanColumn column) {
    bool isCompleted = task.isCompleted;
    int priority = task.priority;

    if (column == KanbanColumn.todo) {
      isCompleted = false;
      priority = 0;
    } else if (column == KanbanColumn.important) {
      isCompleted = false;
      priority = task.priority > 0 ? task.priority : 2;
    } else if (column == KanbanColumn.done) {
      isCompleted = true;
    }

    ref.read(taskListProvider.notifier).updateTaskStatusAndPriority(
          task.uuid,
          isCompleted,
          priority,
        );
  }

  void _navigateToPage(int index) {
    if (_currentPageIndex == index) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    final categories = ref.watch(categoryListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appWallpaperPath = ref.watch(themeProvider).appWallpaperPath;

    final todoTasks = tasks.where((t) => !t.isCompleted && t.priority == 0).toList();
    final importantTasks = tasks.where((t) => !t.isCompleted && t.priority > 0).toList();
    final doneTasks = tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Optional Background wallpaper with wash
          if (appWallpaperPath != null && appWallpaperPath.isNotEmpty) ...[
            Positioned.fill(
              child: Image.file(
                File(appWallpaperPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor.withOpacity(0.90),
              ),
            ),
          ],

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kanban Board',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${tasks.length} total • ${doneTasks.length} done',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // "+ New Task" Quick Action Button
                      FilledButton.icon(
                        onPressed: () {
                          final initialPriority = _currentPageIndex == 1 ? 2 : 0;
                          showAddTaskSheet(context, ref, initialPriority: initialPriority);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0058BE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'New',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Top Segmented Tabs (Also act as Drag Targets)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E).withOpacity(0.9)
                          : const Color(0xFFE2E8F0).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentTab(
                            title: 'To Do',
                            count: todoTasks.length,
                            index: 0,
                            column: KanbanColumn.todo,
                            accentColor: const Color(0xFF0058BE),
                            icon: Icons.radio_button_unchecked_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildSegmentTab(
                            title: 'Important',
                            count: importantTasks.length,
                            index: 1,
                            column: KanbanColumn.important,
                            accentColor: const Color(0xFFF59E0B),
                            icon: Icons.star_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildSegmentTab(
                            title: 'Done',
                            count: doneTasks.length,
                            index: 2,
                            column: KanbanColumn.done,
                            accentColor: const Color(0xFF10B981),
                            icon: Icons.check_circle_rounded,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Swipeable PageView Columns
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    children: [
                      _buildColumnPage(
                        context: context,
                        title: 'To Do',
                        subtitle: 'Tasks to get started on',
                        column: KanbanColumn.todo,
                        tasks: todoTasks,
                        categories: categories,
                        accentColor: const Color(0xFF0058BE),
                        icon: Icons.radio_button_unchecked_rounded,
                        isDark: isDark,
                      ),
                      _buildColumnPage(
                        context: context,
                        title: 'Important',
                        subtitle: 'High & critical priority items',
                        column: KanbanColumn.important,
                        tasks: importantTasks,
                        categories: categories,
                        accentColor: const Color(0xFFF59E0B),
                        icon: Icons.star_rounded,
                        isDark: isDark,
                      ),
                      _buildColumnPage(
                        context: context,
                        title: 'Done',
                        subtitle: 'Completed tasks and achievements',
                        column: KanbanColumn.done,
                        tasks: doneTasks,
                        categories: categories,
                        accentColor: const Color(0xFF10B981),
                        icon: Icons.check_circle_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String title,
    required int count,
    required int index,
    required KanbanColumn column,
    required Color accentColor,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _currentPageIndex == index;

    return DragTarget<Task>(
      onAcceptWithDetails: (details) {
        _moveTaskToColumn(details.data, column);
        _navigateToPage(index);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => _navigateToPage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              color: isHovered
                  ? accentColor.withOpacity(0.25)
                  : (isSelected
                      ? (isDark ? const Color(0xFF2C2C2C) : Colors.white)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isHovered
                  ? Border.all(color: accentColor, width: 2)
                  : (isSelected
                      ? Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.06),
                          width: 1,
                        )
                      : null),
              boxShadow: isSelected && !isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isHovered || isSelected
                      ? accentColor
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isHovered || isSelected
                          ? (isDark ? Colors.white : const Color(0xFF191C1D))
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isHovered || isSelected
                        ? accentColor.withOpacity(0.18)
                        : (isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isHovered || isSelected
                          ? accentColor
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColumnPage({
    required BuildContext context,
    required String title,
    required String subtitle,
    required KanbanColumn column,
    required List<Task> tasks,
    required List<Category> categories,
    required Color accentColor,
    required IconData icon,
    required bool isDark,
  }) {
    return DragTarget<Task>(
      onAcceptWithDetails: (details) {
        _moveTaskToColumn(details.data, column);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Info Bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const Spacer(),
                    // Column specific add button
                    InkWell(
                      onTap: () {
                        final initialPriority = column == KanbanColumn.important ? 2 : 0;
                        showAddTaskSheet(context, ref, initialPriority: initialPriority);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, size: 15, color: accentColor),
                            const SizedBox(width: 2),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Drop zone container and card list
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? accentColor.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isHovered
                        ? Border.all(color: accentColor, width: 2)
                        : null,
                  ),
                  child: tasks.isEmpty
                      ? _buildEmptyState(
                          title: title,
                          column: column,
                          accentColor: accentColor,
                          icon: icon,
                          isDark: isDark,
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
                          itemCount: tasks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final cardWidth = MediaQuery.of(context).size.width - 32;

                            return LongPressDraggable<Task>(
                              data: task,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Transform.rotate(
                                  angle: -0.02,
                                  child: SizedBox(
                                    width: cardWidth,
                                    child: KanbanTaskCard(
                                      task: task,
                                      categories: categories,
                                      isDraggingFeedback: true,
                                      onTap: () {},
                                      onToggle: () {},
                                      onDelete: () {},
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.25,
                                child: KanbanTaskCard(
                                  task: task,
                                  categories: categories,
                                  onTap: () {},
                                  onToggle: () {},
                                  onDelete: () {},
                                ),
                              ),
                              child: KanbanTaskCard(
                                task: task,
                                categories: categories,
                                onTap: () => showTaskDetailSheet(context, ref, task),
                                onToggle: () => ref.read(taskListProvider.notifier).toggleTask(task.uuid),
                                onDelete: () => ref.read(taskListProvider.notifier).deleteTask(task.uuid),
                                onMoveColumn: (targetCol) => _moveTaskToColumn(task, targetCol),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required String title,
    required KanbanColumn column,
    required Color accentColor,
    required IconData icon,
    required bool isDark,
  }) {
    String emptyMessage;
    String subMessage;

    if (column == KanbanColumn.todo) {
      emptyMessage = 'No tasks in To Do';
      subMessage = 'Create a new task or move tasks from other columns.';
    } else if (column == KanbanColumn.important) {
      emptyMessage = 'No important tasks';
      subMessage = 'Tasks with high priority will appear here.\nDrag any card here to mark as important.';
    } else {
      emptyMessage = 'No completed tasks yet';
      subMessage = 'Complete tasks or drag finished cards here.';
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.12),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  final initialPriority = column == KanbanColumn.important ? 2 : 0;
                  showAddTaskSheet(context, ref, initialPriority: initialPriority);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Add to $title',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
