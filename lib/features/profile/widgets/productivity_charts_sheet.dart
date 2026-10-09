import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../tasks/models/task.dart';

/// Opens the rich Productivity Analytics & Charts bottom sheet.
void showProductivityChartsSheet(
  BuildContext context,
  List<Task> tasks,
  bool isDark,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProductivityChartsSheet(tasks: tasks, isDark: isDark),
  );
}

class ProductivityChartsSheet extends StatefulWidget {
  final List<Task> tasks;
  final bool isDark;

  const ProductivityChartsSheet({
    super.key,
    required this.tasks,
    required this.isDark,
  });

  @override
  State<ProductivityChartsSheet> createState() => _ProductivityChartsSheetState();
}

class _ProductivityChartsSheetState extends State<ProductivityChartsSheet> {
  bool _isAllTimeActivity = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final tasks = widget.tasks;

    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final open = total - completed;
    final now = DateTime.now();

    final dueToday = tasks
        .where((t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day)
        .length;

    final overdue = tasks
        .where((t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            t.dueDate!.isBefore(DateTime(now.year, now.month, now.day)))
        .length;

    final rate = total == 0 ? 0.0 : completed / total;

    // Subtasks calculations
    int totalSubtasks = 0;
    int completedSubtasks = 0;
    for (final t in tasks) {
      totalSubtasks += t.subtasks.length;
      completedSubtasks += t.subtasks.where((s) => s.isDone).length;
    }

    // Priority breakdown
    final pCritical = tasks.where((t) => t.priority == 3).length;
    final pHigh = tasks.where((t) => t.priority == 2).length;
    final pMedium = tasks.where((t) => t.priority == 1).length;
    final pLow = tasks.where((t) => t.priority == 0).length;

    // Weekly activity data
    final weeklyCounts = _getWeeklyActivity(tasks, _isAllTimeActivity);

    // Productivity score (0 - 100)
    final int productivityScore = total == 0
        ? 100
        : ((rate * 100) - (overdue > 0 ? (overdue / total * 25) : 0))
            .clamp(0, 100)
            .round();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productivity Analytics',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF191C1D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Performance metrics, charts & trends',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 1),

          // Scrollable Charts & Stats
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Productivity Score & Momentum Banner
                _buildScoreBanner(productivityScore, rate, isDark),
                const SizedBox(height: 18),

                // 2. Metric Grid (4 Cards)
                _buildMetricGrid(completed, open, dueToday, overdue, isDark),
                const SizedBox(height: 22),

                // 3. Status Donut / Ring Chart
                _buildDonutChartCard(
                  total: total,
                  completed: completed,
                  open: open,
                  overdue: overdue,
                  rate: rate,
                  isDark: isDark,
                ),
                const SizedBox(height: 22),

                // 4. 7-Day Weekly Activity Bar Chart
                _buildWeeklyBarChartCard(weeklyCounts, isDark),
                const SizedBox(height: 22),

                // 5. Priority Distribution Breakdown
                _buildPriorityBreakdownCard(
                  total: total,
                  critical: pCritical,
                  high: pHigh,
                  medium: pMedium,
                  low: pLow,
                  isDark: isDark,
                ),

                // 6. Subtask Checklist Mastery (if subtasks exist)
                if (totalSubtasks > 0) ...[
                  const SizedBox(height: 22),
                  _buildSubtaskCard(totalSubtasks, completedSubtasks, isDark),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Score & Momentum Banner ---
  Widget _buildScoreBanner(int score, double rate, bool isDark) {
    String message = 'Excellent focus! Keep this momentum going.';
    if (score == 100) {
      message = 'Peak productivity! All your tasks are fully conquered.';
    } else if (score >= 80) {
      message = 'High velocity! You are staying right on schedule.';
    } else if (score >= 50) {
      message = 'Making steady progress. Tackle open tasks today!';
    } else {
      message = 'Time to refocus. Prioritize high-impact tasks.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF003D82), const Color(0xFF1E293B)]
              : [const Color(0xFF0058BE), const Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0058BE).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Productivity Score',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        score >= 80 ? 'Optimal' : (score >= 50 ? 'Active' : 'Needs Focus'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. 4 Metric Cards Grid ---
  Widget _buildMetricGrid(int completed, int open, int dueToday, int overdue, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _metricTile(
                title: 'Completed',
                value: '$completed',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _metricTile(
                title: 'Due Today',
                value: '$dueToday',
                icon: Icons.today_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _metricTile(
                title: 'In Progress',
                value: '$open',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFF0058BE),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _metricTile(
                title: 'Overdue',
                value: '$overdue',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202020) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF191C1D),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Status Donut / Ring Chart Card ---
  Widget _buildDonutChartCard({
    required int total,
    required int completed,
    required int open,
    required int overdue,
    required double rate,
    required bool isDark,
  }) {
    final double compFrac = total == 0 ? 0.0 : completed / total;
    final double openFrac = total == 0 ? 0.0 : open / total;
    final double overFrac = total == 0 ? 0.0 : overdue / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202020) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Status Distribution',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1D),
                ),
              ),
              Text(
                '$total Total Tasks',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0058BE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Custom Donut Ring
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    completedFraction: compFrac,
                    openFraction: openFrac,
                    overdueFraction: overFrac,
                    completedColor: const Color(0xFF10B981),
                    openColor: const Color(0xFF0058BE),
                    overdueColor: const Color(0xFFEF4444),
                    trackColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    strokeWidth: 14,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(rate * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF191C1D),
                          ),
                        ),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(
                      label: 'Completed',
                      count: completed,
                      percentage: total == 0 ? 0 : (compFrac * 100).round(),
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _legendItem(
                      label: 'In Progress',
                      count: open,
                      percentage: total == 0 ? 0 : (openFrac * 100).round(),
                      color: const Color(0xFF0058BE),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _legendItem(
                      label: 'Overdue',
                      count: overdue,
                      percentage: total == 0 ? 0 : (overFrac * 100).round(),
                      color: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required String label,
    required int count,
    required int percentage,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Text(
          '$count ($percentage%)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF191C1D),
          ),
        ),
      ],
    );
  }

  // --- 4. 7-Day Weekly Activity Bar Chart ---
  Widget _buildWeeklyBarChartCard(Map<int, int> counts, bool isDark) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayWeekday = DateTime.now().weekday; // 1 = Mon .. 7 = Sun

    int maxCount = 1;
    for (final c in counts.values) {
      if (c > maxCount) maxCount = c;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202020) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Completion Activity',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1D),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isAllTimeActivity = !_isAllTimeActivity;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0058BE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isAllTimeActivity ? 'All-Time Days' : 'This Week',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0058BE),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isAllTimeActivity
                ? 'Tasks completed across days of the week'
                : 'Tasks completed Monday through Sunday this week',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),

          // 7 Day Bars
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final weekday = index + 1; // 1 = Mon .. 7 = Sun
                final count = counts[weekday] ?? 0;
                final isToday = weekday == todayWeekday;
                final double barRatio = count / maxCount;
                final double barHeight = (barRatio * 85).clamp(8.0, 85.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Count label
                        Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: count > 0
                                ? (isDark ? Colors.white : const Color(0xFF191C1D))
                                : (isDark ? Colors.white30 : Colors.black26),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Animated Bar
                        Container(
                          height: barHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: count > 0
                                ? LinearGradient(
                                    colors: isToday
                                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                        : [const Color(0xFF0058BE), const Color(0xFF3B82F6)],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  )
                                : null,
                            color: count == 0
                                ? (isDark ? Colors.white10 : const Color(0xFFE2E8F0))
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            border: isToday
                                ? Border.all(
                                    color: const Color(0xFF10B981),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Day label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: isToday
                              ? BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                )
                              : null,
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isToday
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Priority Distribution Breakdown ---
  Widget _buildPriorityBreakdownCard({
    required int total,
    required int critical,
    required int high,
    required int medium,
    required int low,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202020) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks by Priority Level',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF191C1D),
            ),
          ),
          const SizedBox(height: 14),
          _priorityBar(
            label: 'Critical Priority',
            count: critical,
            total: total,
            color: const Color(0xFFEF4444),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _priorityBar(
            label: 'High Priority',
            count: high,
            total: total,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _priorityBar(
            label: 'Medium Priority',
            count: medium,
            total: total,
            color: const Color(0xFF0058BE),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _priorityBar(
            label: 'Low Priority',
            count: low,
            total: total,
            color: const Color(0xFF64748B),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _priorityBar({
    required String label,
    required int count,
    required int total,
    required Color color,
    required bool isDark,
  }) {
    final double fraction = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              '$count (${(fraction * 100).round()}%)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6.5,
            backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // --- 6. Subtask Checklist Mastery ---
  Widget _buildSubtaskCard(int totalSubtasks, int completedSubtasks, bool isDark) {
    final double subtaskRate = totalSubtasks == 0 ? 0.0 : completedSubtasks / totalSubtasks;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202020) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtask & Checklist Mastery',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1D),
                ),
              ),
              Text(
                '$completedSubtasks / $totalSubtasks',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: subtaskRate,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(subtaskRate * 100).round()}% of checklist micro-actions achieved',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to compute weekday completion counts
  Map<int, int> _getWeeklyActivity(List<Task> tasks, bool allTime) {
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    for (final task in tasks) {
      if (task.isCompleted) {
        final date = task.updatedAt.toLocal();
        if (allTime) {
          final w = date.weekday;
          counts[w] = (counts[w] ?? 0) + 1;
        } else {
          final taskDay = DateTime(date.year, date.month, date.day);
          final diff = taskDay.difference(monday).inDays;
          if (diff >= 0 && diff < 7) {
            final w = date.weekday;
            counts[w] = (counts[w] ?? 0) + 1;
          }
        }
      }
    }
    return counts;
  }
}

/// Custom Donut Ring Painter with smooth rounded arcs
class DonutChartPainter extends CustomPainter {
  final double completedFraction;
  final double openFraction;
  final double overdueFraction;
  final Color completedColor;
  final Color openColor;
  final Color overdueColor;
  final Color trackColor;
  final double strokeWidth;

  DonutChartPainter({
    required this.completedFraction,
    required this.openFraction,
    required this.overdueFraction,
    required this.completedColor,
    required this.openColor,
    required this.overdueColor,
    required this.trackColor,
    this.strokeWidth = 14,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final total = completedFraction + openFraction + overdueFraction;
    if (total <= 0) return;

    double startAngle = -math.pi / 2;

    void drawSegment(double fraction, Color color) {
      if (fraction <= 0) return;
      final sweepAngle = fraction * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final gap = total > fraction ? 0.04 : 0.0;
      canvas.drawArc(
        rect,
        startAngle + gap,
        (sweepAngle - gap * 2).clamp(0.01, 2 * math.pi),
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawSegment(completedFraction, completedColor);
    drawSegment(openFraction, openColor);
    drawSegment(overdueFraction, overdueColor);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.completedFraction != completedFraction ||
        oldDelegate.openFraction != openFraction ||
        oldDelegate.overdueFraction != overdueFraction ||
        oldDelegate.completedColor != completedColor;
  }
}
