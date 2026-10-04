import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../../services/backup_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark;
    final tasks = ref.watch(taskListProvider);

    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final open = total - completed;
    final rate = total == 0 ? 0.0 : completed / total;
    final now = DateTime.now();
    final dueToday = tasks
        .where((t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day)
        .length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF191C1D),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF0058BE),
              child: Icon(Icons.person_rounded, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Flow User',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$open open · $completed done · $dueToday due today',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8EAED),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0058BE)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total == 0 ? 'Add your first task to get started' : '${(rate * 100).round()}% complete',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildProfileMenu(Icons.bar_chart_rounded, 'Productivity Stats', isDark,
                () => _showStatsSheet(context, isDark, total, open, completed, dueToday, rate)),
            _buildProfileMenu(Icons.workspace_premium_rounded, 'Go Premium', isDark,
                () => _showInfo(context, 'Flow Premium', 'Flow is free while in development. Premium workspaces arrive with cloud sync.')),
            _buildProfileMenu(Icons.cloud_sync_rounded, 'Backup & Sync', isDark, () async {
              try {
                final path = await BackupService.exportToFile();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup saved to $path')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup failed. Please try again.')),
                  );
                }
              }
            }),
            _buildProfileMenu(Icons.help_outline_rounded, 'Help & Support', isDark,
                () => _showInfo(context, 'Help & Support',
                    'Create tasks from the + button, drag cards between Kanban columns, and tap the calendar to plan by day.')),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(body, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatsSheet(
    BuildContext context,
    bool isDark,
    int total,
    int open,
    int completed,
    int dueToday,
    double rate,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration:
                    BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Productivity Stats',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1D),
              ),
            ),
            const SizedBox(height: 16),
            _statRow('Total tasks', '$total', isDark),
            _statRow('Open', '$open', isDark),
            _statRow('Completed', '$completed', isDark),
            _statRow('Due today', '$dueToday', isDark),
            _statRow('Completion rate', '${(rate * 100).round()}%', isDark),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF191C1D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(IconData icon, String title, bool isDark, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF0058BE)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF191C1D),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
