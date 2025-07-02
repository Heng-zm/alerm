// lib/services/notification_service.dart
// --- CORRECTED FILE ---

import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:loginform/services/sound_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm.dart';
import 'audio_service.dart';

// A top-level function is required for the background isolate callback.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // This is a placeholder for background actions. For our crescendo implementation,
  // the main app isolate handles the response via `onDidReceiveNotificationResponse`.
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioService _audioService;

  // AudioService is injected via the constructor to play sounds.
  NotificationService(this._audioService);

  /// Initializes the notification service, setting up timezones, permissions,
  /// and the callback for when a notification is tapped.
  Future<void> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Platform-specific initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin with the settings and response handlers.
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  /// This is the primary callback when a notification is tapped or arrives
  /// while the app is in the foreground. It triggers the audio service.
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final alarm = Alarm.fromJson(json.decode(response.payload!));
      _audioService.playCrescendo(alarm.sound as Sound);
    }
  }

  /// Schedules a silent, repeating notification trigger for a given alarm.
  Future<void> scheduleAlarm(Alarm alarm) async {
    // This notification plays a silent sound file. Its only purpose is to
    // wake the app and trigger onDidReceiveNotificationResponse.
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Channel for alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(
          'silence'), // Assumes 'silence.mp3' in res/raw
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      sound: 'silence.aiff', // Assumes 'silence.aiff' in Xcode project
      presentSound: true,
    );
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // The alarm data is passed as a JSON string in the payload.
    final payload = jsonEncode(alarm.toJson());

    if (alarm.days.isEmpty) {
      // Schedule a daily repeating alarm for a specific time.
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        int.parse(alarm.id.substring(0, 8), radix: 16),
        alarm.label,
        'Your alarm is ringing!',
        _nextInstanceOfTime(alarm.time),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } else {
      // Schedule a weekly repeating alarm for each selected day.
      for (int day in alarm.days) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          int.parse(alarm.id.substring(0, 8), radix: 16) + day,
          alarm.label,
          'Your alarm is ringing!',
          _nextInstanceOfDay(day, alarm.time),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
    }
  }

  /// Stops the currently playing audio and schedules a new silent trigger
  /// for 9 minutes in the future.
  Future<void> snooze(Alarm alarm) async {
    await _audioService.stop();

    final tz.TZDateTime snoozeTime =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 9));
    // Create a unique ID for the snooze notification to prevent collisions.
    final int snoozeId =
        alarm.id.hashCode + DateTime.now().millisecondsSinceEpoch % 10000;

    const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails('snooze_channel', 'Snooze'),
        iOS: DarwinNotificationDetails(sound: 'silence.aiff'));

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      snoozeId,
      'Snooze: ${alarm.label}',
      'Ringing again in 9 minutes...',
      snoozeTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload:
          jsonEncode(alarm.toJson()), // Pass payload again for multiple snoozes
    );
  }

  /// Stops the audio and cancels all scheduled notifications for a given alarm.
  Future<void> cancelAlarm(Alarm alarm) async {
    await _audioService.stop();
    if (alarm.days.isEmpty) {
      await _flutterLocalNotificationsPlugin
          .cancel(int.parse(alarm.id.substring(0, 8), radix: 16));
    } else {
      for (int day in alarm.days) {
        await _flutterLocalNotificationsPlugin
            .cancel(int.parse(alarm.id.substring(0, 8), radix: 16) + day);
      }
    }
  }

  /// Shows an immediate notification for when a countdown timer finishes.
  /// This method plays a real sound, not a silent trigger.
  Future<void> showTimerDoneNotification(
      String title, String body, String soundAsset) async {
    final soundFileName = soundAsset.split('/').last; // e.g., "radar.mp3"
    final androidSound =
        RawResourceAndroidNotificationSound(soundFileName.split('.').first);
    final iosSound = soundFileName.replaceAll('.mp3', '.aiff');

    final androidDetails = AndroidNotificationDetails(
      'timer_done_channel',
      'Timer Notifications',
      channelDescription: 'Channel for timer completion notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: androidSound,
      playSound: true,
    );
    final iosDetails =
        DarwinNotificationDetails(sound: iosSound, presentSound: true);
    final notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Show an immediate notification with a static ID.
    await _flutterLocalNotificationsPlugin.show(
        999, title, body, notificationDetails);

    // Also trigger the AudioService to play the sound with a crescendo.
    _audioService.playCrescendo(soundAsset as Sound);
  }

  // --- Helper Methods ---

  /// Calculates the next occurrence of a given time (e.g., next 7:30 AM).
  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      // FIX: Corrected the variable name here
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Calculates the next occurrence of a specific day of the week and time
  /// (e.g., next Tuesday at 8:00 AM).
  tz.TZDateTime _nextInstanceOfDay(int day, DateTime time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
