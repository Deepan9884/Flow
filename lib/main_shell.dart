import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme/theme_provider.dart';
import 'features/tasks/screens/home_screen.dart';
import 'features/tasks/screens/kanban_screen.dart';
import 'features/calendar/screens/calendar_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'services/notification_service.dart';

class MainShell extends HookConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark;

    final lifecycleState = useAppLifecycleState();

    useEffect(() {
      if (lifecycleState == AppLifecycleState.resumed || lifecycleState == null) {
        // App is in foreground: check once for any active alerts
        NotificationService.checkActiveAlerts();
      } else if (lifecycleState == AppLifecycleState.paused ||
          lifecycleState == AppLifecycleState.inactive ||
          lifecycleState == AppLifecycleState.detached) {
        // App is in background/paused: immediately release audio hardware to enter deep sleep
        NotificationService.onAppBackgrounded();
      }
      return null;
    }, [lifecycleState]);

    const screens = [
      HomeScreen(),
      KanbanScreen(),
      CalendarScreen(),
      ProfileScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex.value,
            children: screens,
          ),
          ValueListenableBuilder<String?>(
            valueListenable: NotificationService.activeAlertTitle,
            builder: (context, alertTitle, _) {
              if (alertTitle == null) return const SizedBox.shrink();
              return Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? const Color(0xFF261D1D) : const Color(0xFFFFF5F5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                alertTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF191C1D),
                                ),
                              ),
                              Text(
                                'Alert sound is currently playing',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            await NotificationService.stopActiveSoundNotifications();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.stop_rounded, size: 16),
                          label: const Text(
                            'Stop Sound',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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
