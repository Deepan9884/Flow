import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static StreamSubscription<PlayerState>? _foregroundPlayerSub;

  static bool _isInitialized = false;

  static const String _defaultChannelId = 'flow_task_reminders_v5';
  static const String _defaultChannelName = 'Task Reminders';
  static const String _defaultChannelDescription =
      'High-priority task alerts with sound and vibration';

  static final List<Future<void> Function()> _stopAudioCallbacks = [];

  static void registerAudioStopCallback(Future<void> Function() callback) {
    if (!_stopAudioCallbacks.contains(callback)) {
      _stopAudioCallbacks.add(callback);
    }
  }

  static final ValueNotifier<String?> activeAlertTitle = ValueNotifier<String?>(null);

  static const AndroidNotificationAction _stopSoundAction = AndroidNotificationAction(
    'stop_sound',
    'Stop Sound',
    cancelNotification: true,
    showsUserInterface: false,
  );

  /// Returns active notifications currently shown in the system status bar
  static Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.getActiveNotifications();
      }
      return await _notificationsPlugin.getActiveNotifications();
    } catch (_) {
      return [];
    }
  }

  /// Checks active notifications once when app is opened or resumed
  static Future<void> checkActiveAlerts() async {
    try {
      final active = await getActiveNotifications();
      if (active.isNotEmpty) {
        final first = active.first;
        activeAlertTitle.value = first.title ?? 'Task Reminder Alert';
      } else if (activeAlertTitle.value != null) {
        activeAlertTitle.value = null;
      }
    } catch (_) {}
  }

  /// Cancels all currently displayed active notifications and stops all sound players
  static Future<void> stopActiveSoundNotifications() async {
    try {
      await _foregroundPlayerSub?.cancel();
      if (_foregroundPlayer != null) {
        await _foregroundPlayer!.stop();
      }
      for (final cb in _stopAudioCallbacks) {
        try {
          await cb();
        } catch (_) {}
      }
      final active = await getActiveNotifications();
      for (final notif in active) {
        if (notif.id != null) {
          await _notificationsPlugin.cancel(notif.id!);
        }
      }
      activeAlertTitle.value = null;
    } catch (e) {
      debugPrint('Flow: stopActiveSoundNotifications error: $e');
    }
  }

  /// Called when the app moves to background or paused state.
  /// Releases audio hardware completely so the device SoC can enter deep sleep.
  static Future<void> onAppBackgrounded() async {
    try {
      await _foregroundPlayerSub?.cancel();
      if (_foregroundPlayer != null) {
        await _foregroundPlayer!.stop();
      }
      for (final cb in _stopAudioCallbacks) {
        try {
          await cb();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Flow: onAppBackgrounded error: $e');
    }
  }

  /// Initializes the local notifications plugin and creates high-priority channels
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      // 1. Initialize timezone database and set device local timezone
      tz.initializeTimeZones();
      try {
        final now = DateTime.now();
        final offsetMs = now.timeZoneOffset.inMilliseconds;
        tz.Location? matchedLocation;

        // The timezone package stores currentTimeZone.offset in MILLISECONDS
        for (final loc in tz.timeZoneDatabase.locations.values) {
          if (loc.currentTimeZone.offset == offsetMs) {
            matchedLocation = loc;
            break;
          }
        }

        // Fallback: try well-known timezone names for common regions
        if (matchedLocation == null) {
          final knownNames = [
            'Asia/Kolkata',   // IST +5:30
            'Asia/Calcutta',
            'Asia/Colombo',
            'America/New_York',
            'America/Los_Angeles',
            'Europe/London',
            'Europe/Paris',
            'Asia/Tokyo',
            'Asia/Shanghai',
            'Australia/Sydney',
          ];
          for (final name in knownNames) {
            try {
              final loc = tz.getLocation(name);
              if (loc.currentTimeZone.offset == offsetMs) {
                matchedLocation = loc;
                break;
              }
            } catch (_) {}
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
        onDidReceiveNotificationResponse: (NotificationResponse details) async {
          if (details.id != null) {
            try {
              await _notificationsPlugin.cancel(details.id!);
            } catch (_) {}
          }
          await stopActiveSoundNotifications();
        },
      );

      // 2. Explicitly create high-importance Android Notification Channel
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Clean up legacy channel IDs so system applies fresh high-priority settings
        try {
          await androidImplementation.deleteNotificationChannel('default_reminders_channel');
          await androidImplementation.deleteNotificationChannel('flow_task_reminders_v2');
          await androidImplementation.deleteNotificationChannel('flow_task_reminders_v3');
          await androidImplementation.deleteNotificationChannel('flow_task_reminders_v4');
        } catch (_) {}

        const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
          _defaultChannelId,
          _defaultChannelName,
          description: _defaultChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        await androidImplementation.createNotificationChannel(defaultChannel);
        await androidImplementation.requestNotificationsPermission();
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Checks whether exact alarms are permitted.
  static Future<bool> canScheduleExactAlarms() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return (await androidPlugin.canScheduleExactNotifications()) ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system permission setting for exact alarms.
  static Future<bool> requestExactAlarmsPermission() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final result = await androidPlugin.requestExactAlarmsPermission();
        return result ?? false;
      }
      return false;
    } catch (_) {
      try {
        return await openAppSettings();
      } catch (_) {
        return false;
      }
    }
  }

  /// Checks whether exact alarms are permitted and prompts the user if not.
  static Future<bool> checkAndRequestExactAlarms() async {
    try {
      final allowed = await canScheduleExactAlarms();
      if (!allowed) {
        return await requestExactAlarmsPermission();
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Displays an instant test notification immediately with sound and banner.
  static Future<void> showTestNotification({String? customSoundPath}) async {
    try {
      await init();
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      if (customSoundPath != null && customSoundPath.isNotEmpty) {
        await playForegroundSound(customSoundPath);
      }

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannelId,
          _defaultChannelName,
          channelDescription: _defaultChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          autoCancel: true,
          actions: <AndroidNotificationAction>[_stopSoundAction],
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      await _notificationsPlugin.show(
        999999,
        'Flow Todo: Notifications Active',
        'Your alert and notification sound are working perfectly.',
        details,
      );
    } catch (e) {
      debugPrint('showTestNotification error: $e');
    }
  }

  /// Schedules a test reminder [seconds] into the future.
  /// Returns a map with success status, error details, and whether exact alarms are enabled.
  static Future<Map<String, dynamic>> scheduleTestReminderInSeconds(int seconds) async {
    try {
      await init();

      final canExact = await canScheduleExactAlarms();
      if (!canExact) {
        // Request permission immediately
        await requestExactAlarmsPermission();
        return {
          'success': false,
          'needsPermission': true,
          'message': 'Exact Alarms permission is NOT granted. Please enable "Allow setting alarms and reminders" in settings.',
        };
      }

      final triggerAt = DateTime.now().add(Duration(seconds: seconds));
      final details = _buildFallbackDetails();

      final scheduled = await _scheduleZonedNotification(
        id: 888888,
        title: 'Flow Todo: Scheduled Alert',
        body: 'Exact background scheduling is working perfectly on your device!',
        triggerAt: triggerAt,
        primaryDetails: details,
        fallbackDetails: details,
      );

      // Verify whether the alarm is currently stored in the system's pending list
      bool isPending = false;
      try {
        final pending = await _notificationsPlugin.pendingNotificationRequests();
        isPending = pending.any((r) => r.id == 888888);
      } catch (e) {
        debugPrint('Flow: pending check skipped: $e');
      }

      // Rely on the system AlarmManager exclusively

      return {
        'success': scheduled,
        'needsPermission': false,
        'isPending': isPending,
        'message': isPending
            ? 'Alarm scheduled for $seconds seconds from now! Lock screen to verify.'
            : 'Scheduled via system AlarmManager. Lock screen to verify.',
      };
    } catch (e) {
      return {
        'success': false,
        'needsPermission': false,
        'message': 'Failed to schedule alarm: $e',
      };
    }
  }

  /// Schedules personalized reminders for a specific task:
  /// 1. 5 minutes before Start Time (task.reminderAt) to begin the task.
  /// 2. At exact Start Time (task.reminderAt).
  /// 3. 10 minutes before Completion Time (task.dueDate) to check if finished.
  /// 4. At exact Completion Time (task.dueDate).
  ///
  /// Short-notice tasks (starting in < 5 mins or ending in < 10 mins) trigger
  /// an immediate heads-up so the user is never left without an alert.
  static Future<void> scheduleTaskReminder(Task task) async {
    try {
      if (task.isCompleted) return;
      if (task.reminderAt == null && task.dueDate == null) return;

      await init();

      // Ensure notification permissions are requested on Android 13+ and iOS
      await Permission.notification.request();

      // Check and request exact alarm permission if needed
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        try {
          final canExact = await androidPlugin.canScheduleExactNotifications() ?? false;
          if (!canExact) {
            await androidPlugin.requestExactAlarmsPermission();
          }
        } catch (_) {}
      }

      // Cancel previous reminders for this task before re-scheduling
      await cancelTaskReminder(task.uuid);

      final now = DateTime.now();

      // Prepare Android & iOS Notification Details
      final String? stagedSound = (task.soundPath != null && task.soundPath!.isNotEmpty)
          ? await _stageSoundForDelivery(task.soundPath!)
          : null;

      final NotificationDetails notificationDetails =
          await _buildNotificationDetails(task, stagedSound);
      final NotificationDetails fallbackDetails = _buildFallbackDetails();

      // --- Notification 1: Start Time (5m pre-alert + start alert) ---
      if (task.reminderAt != null) {
        final startAt = task.reminderAt!;
        final notifyStartAt = startAt.subtract(const Duration(minutes: 5));
        final timeStr = DateFormat('h:mm a').format(startAt.toLocal());
        final int preStartId = '${task.uuid}_pre_start'.hashCode & 0x7FFFFFFF;
        final int startId = '${task.uuid}_start'.hashCode & 0x7FFFFFFF;

        // 1A. 5 minutes before Start Time (or immediate heads-up if starting shortly)
        if (notifyStartAt.isAfter(now.add(const Duration(seconds: 5)))) {
          await _scheduleZonedNotification(
            id: preStartId,
            title: 'Ready for ${task.title}?',
            body: 'Starting in 5 mins ($timeStr). Let\'s get focused and crush this!',
            triggerAt: notifyStartAt,
            primaryDetails: notificationDetails,
            fallbackDetails: fallbackDetails,
          );
        } else if (startAt.isAfter(now)) {
          // Starting in less than 5 minutes: alert immediately!
          final mins = startAt.difference(now).inMinutes;
          final label = mins <= 1 ? 'under 1 min' : '$mins mins';
          activeAlertTitle.value = task.title;
          try {
            await _notificationsPlugin.show(
              preStartId,
              'Ready for ${task.title}?',
              'Starting in $label ($timeStr). Let\'s get focused and crush this!',
              notificationDetails,
            );
          } catch (_) {
            await _notificationsPlugin.show(
              preStartId,
              'Ready for ${task.title}?',
              'Starting in $label ($timeStr). Let\'s get focused and crush this!',
              fallbackDetails,
            );
          }
        }

        // 1B. Start Time alert (only if in the future)
        if (startAt.isAfter(now.add(const Duration(seconds: 5)))) {
          await _scheduleZonedNotification(
            id: startId,
            title: 'Time for ${task.title}!',
            body: 'Scheduled to begin now ($timeStr). Let\'s dive in!',
            triggerAt: startAt,
            primaryDetails: notificationDetails,
            fallbackDetails: fallbackDetails,
          );
        }
      }

      // --- Notification 2: Completion Time (10m pre-alert + target reached) ---
      if (task.dueDate != null) {
        final dueAt = task.dueDate!;
        // Do not schedule completion alarms for 23:59 end-of-day date markers
        final isSpecificTime = dueAt.hour != 23 || dueAt.minute != 59;

        if (isSpecificTime) {
          final notifyDueAt = dueAt.subtract(const Duration(minutes: 10));
          final timeStr = DateFormat('h:mm a').format(dueAt.toLocal());
          final int preFinishId = '${task.uuid}_pre_finish'.hashCode & 0x7FFFFFFF;
          final int finishId = '${task.uuid}_finish'.hashCode & 0x7FFFFFFF;

          // 2A. 10 minutes before Completion Time (or immediate heads-up if deadline is soon)
          if (notifyDueAt.isAfter(now.add(const Duration(seconds: 5)))) {
            await _scheduleZonedNotification(
              id: preFinishId,
              title: 'Checking in on ${task.title}!',
              body: '10 mins left until $timeStr. Are you almost finished? Take a moment to wrap it up!',
              triggerAt: notifyDueAt,
              primaryDetails: notificationDetails,
              fallbackDetails: fallbackDetails,
            );
          } else if (dueAt.isAfter(now)) {
            // Target is in less than 10 minutes: alert immediately!
            final mins = dueAt.difference(now).inMinutes;
            final label = mins <= 1 ? 'under 1 min' : '$mins mins';
            activeAlertTitle.value = task.title;
            try {
              await _notificationsPlugin.show(
                preFinishId,
                'Checking in on ${task.title}!',
                'Only $label left until $timeStr. Take a moment to wrap it up!',
                notificationDetails,
              );
            } catch (_) {
              await _notificationsPlugin.show(
                preFinishId,
                'Checking in on ${task.title}!',
                'Only $label left until $timeStr. Take a moment to wrap it up!',
                fallbackDetails,
              );
            }
          }

          // 2B. Exact Completion Time alert
          if (dueAt.isAfter(now.add(const Duration(seconds: 5)))) {
            await _scheduleZonedNotification(
              id: finishId,
              title: 'Target reached for ${task.title}!',
              body: 'Scheduled completion target was $timeStr. Mark it done if completed!',
              triggerAt: dueAt,
              primaryDetails: notificationDetails,
              fallbackDetails: fallbackDetails,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('scheduleTaskReminder error: $e');
    }
  }

  static Future<NotificationDetails> _buildNotificationDetails(Task task, String? stagedSound) async {
    AndroidNotificationDetails androidDetails;
    if (stagedSound != null) {
      final String channelId = 'flow_sound_${stagedSound.hashCode & 0x7FFFFFFF}';
      final UriAndroidNotificationSound customSound =
          UriAndroidNotificationSound('content://flow_todo_fileprovider/app_cache/sounds/$stagedSound');

      try {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final customChannel = AndroidNotificationChannel(
            channelId,
            'Task Reminder (${task.title})',
            description: 'Custom sound alert for tasks',
            importance: Importance.max,
            playSound: true,
            sound: customSound,
            enableVibration: true,
            showBadge: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          );
          await androidImplementation.createNotificationChannel(customChannel);
        }
      } catch (_) {}

      androidDetails = AndroidNotificationDetails(
        channelId,
        'Task Reminder (${task.title})',
        channelDescription: 'Custom sound alert for tasks',
        sound: customSound,
        playSound: true,
        enableVibration: true,
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        autoCancel: true,
        actions: const <AndroidNotificationAction>[_stopSoundAction],
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        _defaultChannelId,
        _defaultChannelName,
        channelDescription: _defaultChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        autoCancel: true,
        actions: <AndroidNotificationAction>[_stopSoundAction],
      );
    }

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  static NotificationDetails _buildFallbackDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannelId,
        _defaultChannelName,
        channelDescription: _defaultChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        autoCancel: true,
        actions: <AndroidNotificationAction>[_stopSoundAction],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  static Future<bool> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime triggerAt,
    required NotificationDetails primaryDetails,
    required NotificationDetails fallbackDetails,
  }) async {
    final now = DateTime.now();

    // STRICT: Only schedule future notifications!
    if (!triggerAt.isAfter(now.add(const Duration(seconds: 3)))) {
      debugPrint('Flow: triggerAt $triggerAt is not at least 3 seconds in the future (now: $now)');
      return false;
    }

    tz.TZDateTime scheduledDate = tz.TZDateTime.from(triggerAt, tz.local);

    final tzNow = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(tzNow)) {
      debugPrint('Flow: scheduledDate $scheduledDate is not after tzNow $tzNow');
      return false;
    }

    try {
      // Tier 1: exactAllowWhileIdle — standard, reliable exact alarm mode on Android
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
      debugPrint('Flow: Successfully scheduled notification $id for $scheduledDate (exactAllowWhileIdle)');
      return true;
    } catch (e) {
      debugPrint('Flow: exactAllowWhileIdle failed: $e, trying alarmClock');
      try {
        // Tier 2: alarmClock fallback
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          fallbackDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('Flow: Successfully scheduled notification $id for $scheduledDate (alarmClock)');
        return true;
      } catch (e2) {
        debugPrint('Flow: alarmClock failed: $e2, trying inexactAllowWhileIdle');
        try {
          // Tier 3: inexactAllowWhileIdle as absolute fallback
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
          debugPrint('Flow: Scheduled notification $id for $scheduledDate (inexactAllowWhileIdle)');
          return true;
        } catch (e3) {
          debugPrint('Flow: All zonedSchedule modes failed: $e3');
          return false;
        }
      }
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
      final active = await getActiveNotifications();
      if (active.isEmpty) {
        activeAlertTitle.value = null;
      }
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
      await _foregroundPlayerSub?.cancel();
      if (_foregroundPlayer != null) {
        await _foregroundPlayer!.stop();
      } else {
        _foregroundPlayer = AudioPlayer();
      }
      _foregroundPlayerSub = _foregroundPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _foregroundPlayer?.stop();
        }
      });
      await _foregroundPlayer!.setFilePath(soundPath);
      await _foregroundPlayer!.play();
    } catch (e) {
      // Gracefully catch playback failures (e.g. invalid file format or missing audio hardware)
    }
  }
}
