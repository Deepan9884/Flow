import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../features/tasks/models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static AudioPlayer? _foregroundPlayer;

  /// Initializes the local notifications plugin
  static Future<void> init() async {
    try {
      // Initialize timezone database for zoned reminders
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Tap handler logic
        },
      );
    } catch (_) {
      // Notification initialization must never prevent the app from launching.
    }
  }

  /// Schedules personalized reminders for a specific task:
  /// 1. 5 minutes before Start Time (task.reminderAt) to begin the task.
  /// 2. 10 minutes before Completion Time (task.dueDate) to check if finished.
  static Future<void> scheduleTaskReminder(Task task) async {
    try {
      if (task.isCompleted) return;
      if (task.reminderAt == null && task.dueDate == null) return;

      // 1. Request notification permissions (required runtime permissions on Android 13+ and iOS)
      final permissionStatus = await Permission.notification.request();
      if (!permissionStatus.isGranted) return;

      final now = DateTime.now();

      // 2. Prepare Android & iOS Notification Details
      final String? stagedSound = (task.soundPath != null && task.soundPath!.isNotEmpty)
          ? await _stageSoundForDelivery(task.soundPath!)
          : null;

      final NotificationDetails notificationDetails = _buildNotificationDetails(task, stagedSound);
      final NotificationDetails fallbackDetails = _buildFallbackDetails();

      // --- Notification 1: 5 minutes before Start Time ---
      if (task.reminderAt != null) {
        final startAt = task.reminderAt!;
        final notifyStartAt = startAt.subtract(const Duration(minutes: 5));
        
        DateTime? targetTrigger;
        String title = '';
        String body = '';
        final timeStr = DateFormat('h:mm a').format(startAt.toLocal());

        if (notifyStartAt.isAfter(now)) {
          targetTrigger = notifyStartAt;
          title = 'Ready for ${task.title}? 🚀';
          body = 'Starting in 5 mins ($timeStr). Let\'s get focused and crush this!';
        } else if (startAt.isAfter(now)) {
          // Less than 5 mins remaining before start; schedule at exact start time
          targetTrigger = startAt;
          title = 'Time for ${task.title}! 🚀';
          body = 'Scheduled to begin now ($timeStr). Let\'s dive in!';
        }

        if (targetTrigger != null) {
          final int startId = '${task.uuid}_start'.hashCode & 0x7FFFFFFF;
          await _scheduleZonedNotification(
            id: startId,
            title: title,
            body: body,
            triggerAt: targetTrigger,
            primaryDetails: notificationDetails,
            fallbackDetails: fallbackDetails,
          );
        }
      }

      // --- Notification 2: 10 minutes before Completion Time ---
      if (task.dueDate != null) {
        final dueAt = task.dueDate!;
        final notifyDueAt = dueAt.subtract(const Duration(minutes: 10));

        DateTime? targetTrigger;
        String title = '';
        String body = '';
        final timeStr = DateFormat('h:mm a').format(dueAt.toLocal());

        if (notifyDueAt.isAfter(now)) {
          targetTrigger = notifyDueAt;
          title = 'Checking in on ${task.title}! ⏱️';
          body = '10 mins left until $timeStr. Are you almost finished? Take a moment to wrap it up!';
        } else if (dueAt.isAfter(now)) {
          // Less than 10 mins remaining before completion; schedule at exact due time
          targetTrigger = dueAt;
          title = 'Target reached for ${task.title}! ⏱️';
          body = 'Scheduled completion target was $timeStr. Did you finish?';
        }

        if (targetTrigger != null) {
          final int finishId = '${task.uuid}_finish'.hashCode & 0x7FFFFFFF;
          await _scheduleZonedNotification(
            id: finishId,
            title: title,
            body: body,
            triggerAt: targetTrigger,
            primaryDetails: notificationDetails,
            fallbackDetails: fallbackDetails,
          );
        }
      }
    } catch (_) {
      // Scheduling is best-effort: permissions, alarms, or staging issues
      // must never crash the app. The task itself is already persisted.
    }
  }

  static NotificationDetails _buildNotificationDetails(Task task, String? stagedSound) {
    AndroidNotificationDetails androidDetails;
    if (stagedSound != null) {
      final String channelId = 'task_channel_${task.uuid}_${task.soundPath.hashCode}';
      final String channelName = 'Task Reminder: ${task.title}';
      final UriAndroidNotificationSound customSound =
          UriAndroidNotificationSound('content://flow_todo_fileprovider/app_cache/sounds/$stagedSound');

      androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Dynamic custom sound channel for task: ${task.title}',
        sound: customSound,
        playSound: true,
        importance: Importance.max,
        priority: Priority.high,
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        'default_reminders_channel',
        'Standard Reminders',
        channelDescription: 'Standard todo alerts with default sound',
        importance: Importance.max,
        priority: Priority.high,
      );
    }

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  static NotificationDetails _buildFallbackDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_reminders_channel',
        'Standard Reminders',
        channelDescription: 'Standard todo alerts with default sound',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  static Future<void> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime triggerAt,
    required NotificationDetails primaryDetails,
    required NotificationDetails fallbackDetails,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(triggerAt, tz.local),
        primaryDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(triggerAt, tz.local),
          fallbackDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Fallback scheduling failure gracefully swallowed
      }
    }
  }

  /// Cancels all scheduled reminders for a single task (start, finish, and legacy).
  static Future<void> cancelTaskReminder(String taskUuid) async {
    try {
      await _notificationsPlugin.cancel('${taskUuid}_start'.hashCode & 0x7FFFFFFF);
      await _notificationsPlugin.cancel('${taskUuid}_finish'.hashCode & 0x7FFFFFFF);
      await _notificationsPlugin.cancel(taskUuid.hashCode & 0x7FFFFFFF);
    } catch (_) {
      // Cancellation is best-effort; a missing id is not an error.
    }
  }

  /// Cancels every scheduled reminder (used on sign-out / data reset).
  static Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {
      // Best-effort.
    }
  }

  /// Copies a task sound into the cache `sounds/` directory so the
  /// FileProvider URI handed to the notification system always resolves.
  /// Returns the staged basename, or null when staging failed (caller falls
  /// back to the default channel).
  static Future<String?> _stageSoundForDelivery(String soundPath) async {
    try {
      final src = File(soundPath);
      if (!await src.exists()) return null;
      final cacheDir = await getTemporaryDirectory();
      final destDir = Directory('${cacheDir.path}/sounds');
      await destDir.create(recursive: true);
      final name = soundPath.split('/').last.split('\\').last;
      if (name.isEmpty) return null;
      await src.copy('${destDir.path}/$name');
      return name;
    } catch (_) {
      return null;
    }
  }

  /// Plays custom sound file directly using just_audio for full-fidelity active foreground playback
  static Future<void> playForegroundSound(String soundPath) async {
    try {
      if (_foregroundPlayer != null) {
        await _foregroundPlayer!.stop();
      } else {
        _foregroundPlayer = AudioPlayer();
      }
      await _foregroundPlayer!.setFilePath(soundPath);
      await _foregroundPlayer!.play();
    } catch (e) {
      // Gracefully catch playback failures (e.g. invalid file format or missing audio hardware)
    }
  }
}
