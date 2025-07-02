// lib/services/notification_service.dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm.dart';
import 'audio_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // This is a placeholder for background actions if needed in the future.
  // For our crescendo implementation, the main app isolate handles the response.
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioService _audioService;

  // AudioService is now injected via the constructor
  NotificationService(this._audioService);

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  // This is the key change: when a notification is tapped (or arrives),
  // we tell the AudioService to start playing the sound with a crescendo.
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final alarm = Alarm.fromJson(json.decode(response.payload!));
      _audioService.playCrescendo(alarm.sound);
    }
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    // IMPORTANT: The sound is now silent. It's just a trigger.
    // You MUST have 'silence.aiff' in Xcode and 'silence.mp3' in android/app/src/main/res/raw
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Channel for alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('silence'),
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      sound: 'silence.aiff',
      presentSound: true,
    );
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    final payload = jsonEncode(alarm.toJson());

    if (alarm.days.isEmpty) {
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

  // Snooze now stops the audio and schedules a new silent trigger
  Future<void> snooze(Alarm alarm) async {
    await _audioService.stop();

    final tz.TZDateTime snoozeTime =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 9));
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

  // --- Helper Methods ---
  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDay(int day, DateTime time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
