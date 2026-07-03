import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../features/tasks/models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static AudioPlayer? _foregroundPlayer;

  /// Initializes the local notifications plugin
  static Future<void> init() async {
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
  }

  /// Schedules a reminder for a specific task.
  /// First requests permission, then sets up standard or task-specific sound channels.
  static Future<void> scheduleTaskReminder(Task task) async {
    if (task.reminderAt == null) return;

    // 1. Request notification permissions (required runtime permissions on Android 13+ and iOS)
    final permissionStatus = await Permission.notification.request();
    if (!permissionStatus.isGranted) return;

    final scheduleTime = task.reminderAt!;
    if (scheduleTime.isBefore(DateTime.now())) return;

    final int notificationId = task.uuid.hashCode;
    
    // Check if the app is active in the foreground - if so, play via just_audio directly.
    // In a real app we'd query AppLifecycleState, but here we provide playForegroundSound
    // as a public helper so the active app handler can trigger it.

    AndroidNotificationDetails androidDetails;

    // 2. Android Task-specific Custom Sound configuration
    if (task.soundPath != null && task.soundPath!.isNotEmpty) {
      // Channels are immutable. If the sound changes, we generate a new channel ID.
      // We derive the channel ID from the task ID and sound path hash.
      final String channelId = 'task_channel_${task.uuid}_${task.soundPath.hashCode}';
      final String channelName = 'Task Reminder: ${task.title}';

      // Use a FileProvider URI on Android pointing to the stored sound file
      final UriAndroidNotificationSound customSound =
          UriAndroidNotificationSound('content://flow_todo_fileprovider/sounds/${task.uuid}');

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
      // Default channel
      androidDetails = const AndroidNotificationDetails(
        'default_reminders_channel',
        'Standard Reminders',
        channelDescription: 'Standard todo alerts with default sound',
        importance: Importance.max,
        priority: Priority.high,
      );
    }

    // 3. iOS Configuration - custom sound paths at runtime are not supported by iOS background notifications,
    // so we fall back to standard sounds.
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 4. Exact zoned scheduling trigger
    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(scheduleTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
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
