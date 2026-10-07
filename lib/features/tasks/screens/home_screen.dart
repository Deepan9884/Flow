import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../categories/models/category.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/task_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../../widgets/task_banner_card.dart';
import '../utils/task_ui_helpers.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/category_dialog.dart';

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
    final appWallpaperPath = ref.watch(themeProvider).appWallpaperPath;

    // Filter tasks based on selected category and search query
    final filteredTasks = tasks.where((task) {
      final matchesCategory = _selectedCategoryId == 'all' || task.categoryIds.contains(_selectedCategoryId);
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (task.notes != null && task.notes!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();

    // Priority & Custom Banner tasks for top carousel (Uncompleted & (High/Critical priority OR custom wallpaper banner))
    final featuredTasks = tasks.where((t) =>
        !t.isCompleted &&
        (t.priority >= 2 || (t.wallpaperPath != null && t.wallpaperPath!.isNotEmpty && File(t.wallpaperPath!).existsSync()))).toList();

    return Scaffold(
      body: Stack(
        children: [
          if (appWallpaperPath != null && appWallpaperPath.isNotEmpty) ...[
            Positioned.fill(
              child: Image.file(
                File(appWallpaperPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // Wash so list content stays readable in both themes.
            Positioned.fill(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.88),
              ),
            ),
          ],
          SafeArea(
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
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stay centered. Get things done.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        // Add Category Button
                        IconButton(
                          onPressed: () => showManageCategoriesDialog(context, ref),
                          icon: const Icon(Icons.style_rounded, color: Color(0xFF0058BE), size: 26),
                          tooltip: 'Manage Categories',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Elegant Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
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

            // Priority & Custom Banner Tasks Carousel (Interactive Tilt Banners)
            if (featuredTasks.isNotEmpty && _searchQuery.isEmpty && _selectedCategoryId == 'all')
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'FEATURED & PRIORITY TASKS',
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
                        itemCount: featuredTasks.length,
                        itemBuilder: (context, index) {
                          final task = featuredTasks[index];
                          return Container(
                            width: 300,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: TaskBannerCard(
                              task: task,
                              onTap: () => showTaskDetailSheet(context, ref, task),
                              onToggle: () => ref.read(taskListProvider.notifier).toggleTask(task.uuid),
                              categoryLabel: resolveCategoryLabel(categories, task),
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
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                            backgroundColor: Theme.of(context).colorScheme.surface,
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

                      final hasWallpaper = task.wallpaperPath != null &&
                          task.wallpaperPath!.isNotEmpty &&
                          File(task.wallpaperPath!).existsSync();

                      if (hasWallpaper) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: TaskBannerCard(
                            task: task,
                            enableTilt: false,
                            onTap: () => showTaskDetailSheet(context, ref, task),
                            onToggle: () => ref.read(taskListProvider.notifier).toggleTask(task.uuid),
                            onDelete: () => ref.read(taskListProvider.notifier).deleteTask(task.uuid),
                            categoryLabel: resolveCategoryLabel(categories, task),
                          ),
                        );
                      }

                      return Card(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.withOpacity(0.12), width: 1),
                        ),
                        child: ListTile(
                          onTap: () => showTaskDetailSheet(context, ref, task),
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
                              color: task.isCompleted
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.onSurface,
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
                                      formatDate(task.dueDate!),
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
                              color: priorityBgColor(task.priority),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              priorityLabel(task.priority),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityTextColor(task.priority),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTaskSheet(context, ref),
        backgroundColor: const Color(0xFF0058BE),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
