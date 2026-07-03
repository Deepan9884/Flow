import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../../../widgets/task_banner_card.dart';

enum KanbanColumn { todo, important, done }

class KanbanScreen extends ConsumerWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);

    final todoTasks = tasks.where((t) => !t.isCompleted && t.priority == 0).toList();
    final importantTasks = tasks.where((t) => !t.isCompleted && t.priority > 0).toList();
    final doneTasks = tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Kanban Board',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1D),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDragTargetColumn(context, ref, 'To Do', KanbanColumn.todo, todoTasks),
            const SizedBox(width: 16),
            _buildDragTargetColumn(context, ref, 'Important', KanbanColumn.important, importantTasks),
            const SizedBox(width: 16),
            _buildDragTargetColumn(context, ref, 'Done', KanbanColumn.done, doneTasks),
          ],
        ),
      ),
    );
  }

  Widget _buildDragTargetColumn(BuildContext context, WidgetRef ref, String title, KanbanColumn columnType, List<Task> tasks) {
    return DragTarget<Task>(
      onAcceptWithDetails: (details) {
        final task = details.data;
        bool isCompleted = task.isCompleted;
        int priority = task.priority;

        if (columnType == KanbanColumn.todo) {
          isCompleted = false;
          priority = 0;
        } else if (columnType == KanbanColumn.important) {
          isCompleted = false;
          priority = 1;
        } else if (columnType == KanbanColumn.done) {
          isCompleted = true;
        }
        
        ref.read(taskListProvider.notifier).updateTaskStatusAndPriority(task.uuid, isCompleted, priority);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? const Color(0xFF0058BE).withOpacity(0.1) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(16),
            border: candidateData.isNotEmpty ? Border.all(color: const Color(0xFF0058BE), width: 2) : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1D),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return LongPressDraggable<Task>(
                      data: task,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.8,
                          child: SizedBox(
                            width: 248,
                            child: TaskBannerCard(
                              task: task,
                              onToggle: () {},
                              onDelete: () {},
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: TaskBannerCard(
                          task: task,
                          onToggle: () {},
                          onDelete: () {},
                        ),
                      ),
                      child: TaskBannerCard(
                        task: task,
                        onToggle: () => ref.read(taskListProvider.notifier).toggleTask(task.uuid),
                        onDelete: () => ref.read(taskListProvider.notifier).deleteTask(task.uuid),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
