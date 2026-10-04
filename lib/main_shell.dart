import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme/theme_provider.dart';
import 'features/tasks/screens/home_screen.dart';
import 'features/tasks/screens/kanban_screen.dart';
import 'features/calendar/screens/calendar_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/settings/screens/settings_screen.dart';

class MainShell extends HookConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark;

    const screens = [
      HomeScreen(),
      KanbanScreen(),
      CalendarScreen(),
      ProfileScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex.value,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.value,
        onDestinationSelected: (index) => currentIndex.value = index,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 10,
        shadowColor: Colors.black12,
        indicatorColor: const Color(0xFF0058BE).withOpacity(0.15),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded, color: isDark ? Colors.white70 : null),
            selectedIcon: const Icon(Icons.list_alt_rounded, color: Color(0xFF0058BE)),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_kanban_outlined, color: isDark ? Colors.white70 : null),
            selectedIcon: const Icon(Icons.view_kanban_rounded, color: Color(0xFF0058BE)),
            label: 'Kanban',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: isDark ? Colors.white70 : null),
            selectedIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0058BE)),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: isDark ? Colors.white70 : null),
            selectedIcon: const Icon(Icons.person_rounded, color: Color(0xFF0058BE)),
            label: 'Mine',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white70 : null),
            selectedIcon: const Icon(Icons.settings_rounded, color: Color(0xFF0058BE)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
