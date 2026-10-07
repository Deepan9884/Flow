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

  /// Initializes the local notifications plugin and creates high-priority channels
  static Future<void> init() async {
    try {
      // 1. Initialize timezone database and set device local timezone
      tz.initializeTimeZones();
      try {
        final now = DateTime.now();
        final offset = now.timeZoneOffset;
        tz.Location? matchedLocation;
        for (final loc in tz.timeZoneDatabase.locations.values) {
          if (loc.currentTimeZone.offset == offset.inMilliseconds) {
            matchedLocation = loc;
            break;
          }
        }
        if (matchedLocation != null) {
          tz.setLocalLocation(matchedLocation);
        }
      } catch (_) {}

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
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

      // 2. Explicitly create high-importance Android Notification Channel
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
          'default_reminders_channel',
          'Task Reminders',
          description: 'High-priority task alerts with sound and vibration',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

        await androidImplementation.createNotificationChannel(defaultChannel);
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    } catch (_) {
      // Notification initialization must never prevent the app from launching.
    }
  }

  /// Displays an instant test notification immediately with sound and banner,
  /// so the user can verify that notifications and sounds work on their phone.
  static Future<void> showTestNotification({String? customSoundPath}) async {
    try {
      await init();
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      // If custom sound provided, play through audio engine
      if (customSoundPath != null && customSoundPath.isNotEmpty) {
        unawaited(playForegroundSound(customSoundPath));
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'default_reminders_channel',
          'Task Reminders',
          channelDescription: 'High-priority task alerts with sound and vibration',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        999999,
        'Flow Todo: Notifications Active! 🔔',
        'Your alert and notification sound are working perfectly.',
        details,
      );
    } catch (_) {}
  }

  /// Schedules personalized reminders for a specific task:
  /// 1. 5 minutes before Start Time (task.reminderAt) to begin the task.
  /// 2. 10 minutes before Completion Time (task.dueDate) to check if finished.
  static Future<void> scheduleTaskReminder(Task task) async {
    try {
      if (task.isCompleted) return;
      if (task.reminderAt == null && task.dueDate == null) return;

      // Ensure notification permissions are requested on Android 13+ and iOS
      await Permission.notification.request();

      final now = DateTime.now();

      // Prepare Android & iOS Notification Details
      final String? stagedSound = (task.soundPath != null && task.soundPath!.isNotEmpty)
          ? await _stageSoundForDelivery(task.soundPath!)
          : null;

      final NotificationDetails notificationDetails = _buildNotificationDetails(task, stagedSound);
      final NotificationDetails fallbackDetails = _buildFallbackDetails();

      // --- Notification 1: Start Time (5m pre-alert + start alert) ---
      if (task.reminderAt != null) {
        final startAt = task.reminderAt!;
        final notifyStartAt = startAt.subtract(const Duration(minutes: 5));
        final timeStr = DateFormat('h:mm a').format(startAt.toLocal());
        final int preStartId = '${task.uuid}_pre_start'.hashCode & 0x7FFFFFFF;
        final int startId = '${task.uuid}_start'.hashCode & 0x7FFFFFFF;

        if (notifyStartAt.isAfter(now.add(const Duration(seconds: 5)))) {
          // Standard future case: Start is more than 5 minutes away
          await _scheduleZonedNotification(
            id: preStartId,
            title: 'Ready for ${task.title}? 🚀',
            body: 'Starting in 5 mins ($timeStr). Let\'s get focused and crush this!',
            triggerAt: notifyStartAt,
            primaryDetails: notificationDetails,
            fallbackDetails: fallbackDetails,
          );
        } else if (startAt.isAfter(now)) {
          // Starting within 5 minutes! Trigger pre-alert right now so the user receives notification!
          final minsLeft = startAt.difference(now).inMinutes;
          final minsLabel = minsLeft <= 1 ? '5 mins' : '$minsLeft mins';
          try {
            await _notificationsPlugin.show(
              preStartId,
              'Ready for ${task.title}? 🚀',
              'Starting in $minsLabel ($timeStr). Let\'s get focused and crush this!',
              notificationDetails,
            );
          } catch (_) {
            await _notificationsPlugin.show(
              preStartId,
              'Ready for ${task.title}? 🚀',
              'Starting in $minsLabel ($timeStr). Let\'s get focused and crush this!',
              fallbackDetails,
            );
          }
        }

        // Schedule the start notification for startAt
        if (startAt.isAfter(now.add(const Duration(seconds: 5)))) {
          await _scheduleZonedNotification(
            id: startId,
            title: 'Time for ${task.title}! 🚀',
            body: 'Scheduled to begin now ($timeStr). Let\'s dive in!',
            triggerAt: startAt,
            primaryDetails: notificationDetails,
            fallbackDetails: fallbackDetails,
          );
        } else if (now.difference(startAt).inMinutes.abs() <= 2) {
          // Scheduled right now! Show immediately
          try {
            await _notificationsPlugin.show(
              startId,
              'Time for ${task.title}! 🚀',
              'Scheduled to begin now ($timeStr). Let\'s dive in!',
              notificationDetails,
            );
          } catch (_) {
            await _notificationsPlugin.show(
              startId,
              'Time for ${task.title}! 🚀',
              'Scheduled to begin now ($timeStr). Let\'s dive in!',
              fallbackDetails,
            );
          }
        }
      }

      // --- Notification 2: Completion Time (10m pre-alert + target reached) ---
      if (task.dueDate != null) {
        final dueAt = task.dueDate!;
        final notifyDueAt = dueAt.subtract(const Duration(minutes: 10));
        final timeStr = DateFormat('h:mm a').format(dueAt.toLocal());
        final int preFinishId = '${task.uuid}_pre_finish'.hashCode & 0x7FFFFFFF;
        final int finishId = '${task.uuid}_finish'.hashCode & 0x7FFFFFFF;

        if (notifyDueAt.isAfter(now.add(const Duration(seconds: 5)))) {
          await _scheduleZonedNotification(
            id: preFinishId,
            title: 'Checking in on ${task.title}! ⏱️',
            body: '10 mins left until $timeStr. Are you almost finished? Take a moment to wrap it up!',
            triggerAt: notifyDueAt,
            primaryDetails: notificationDetails,
            fallbackDetails: fallbackDetails,
          );
        }

        if (dueAt.isAfter(now.add(const Duration(seconds: 5)))) {
          await _scheduleZonedNotification(
            id: finishId,
            title: 'Target reached for ${task.title}! 🎯',
            body: 'Scheduled completion target was $timeStr. Mark it done if completed!',
            triggerAt: dueAt,
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
        channelDescription: 'Custom sound alert for ${task.title}',
        sound: customSound,
        playSound: true,
        enableVibration: true,
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        'default_reminders_channel',
        'Task Reminders',
        channelDescription: 'High-priority task alerts with sound and vibration',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
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
        'Task Reminders',
        channelDescription: 'High-priority task alerts with sound and vibration',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
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
    final now = DateTime.now();

    // If trigger time is within 5 seconds or in the past, show immediately!
    if (triggerAt.isBefore(now.add(const Duration(seconds: 5)))) {
      try {
        await _notificationsPlugin.show(id, title, body, primaryDetails);
        return;
      } catch (_) {
        await _notificationsPlugin.show(id, title, body, fallbackDetails);
        return;
      }
    }

    tz.TZDateTime scheduledDate;
    try {
      scheduledDate = tz.TZDateTime.from(triggerAt, tz.local);
    } catch (_) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        triggerAt.year,
        triggerAt.month,
        triggerAt.day,
        triggerAt.hour,
        triggerAt.minute,
        triggerAt.second,
      );
    }

    final tzNow = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(tzNow)) {
      try {
        await _notificationsPlugin.show(id, title, body, primaryDetails);
        return;
      } catch (_) {
        await _notificationsPlugin.show(id, title, body, fallbackDetails);
        return;
      }
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        primaryDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Fallback: guaranteed inexactAllowWhileIdle with standard default details
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          fallbackDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  /// Cancels all scheduled reminders for a single task (start, finish, and legacy).
  static Future<void> cancelTaskReminder(String taskUuid) async {
    try {
      await _notificationsPlugin.cancel('${taskUuid}_pre_start'.hashCode & 0x7FFFFFFF);
      await _notificationsPlugin.cancel('${taskUuid}_start'.hashCode & 0x7FFFFFFF);
      await _notificationsPlugin.cancel('${taskUuid}_pre_finish'.hashCode & 0x7FFFFFFF);
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

void unawaited(Future<void> future) {}
