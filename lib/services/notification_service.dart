// lib/services/notification_service.dart
// --- CORRECTED FILE ---

import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm.dart';
import 'audio_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioService _audioService;

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

  void onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      final alarm = Alarm.fromJson(json.decode(response.payload!));
      _audioService.playCrescendo(alarm.sound);
    }
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    const androidDetails = AndroidNotificationDetails('alarm_channel', 'Alarms',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('silence'),
        playSound: true);
    const iosDetails =
        DarwinNotificationDetails(sound: 'silence.aiff', presentSound: true);
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
          payload: payload);
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
            payload: payload);
      }
    }
  }

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
        payload: jsonEncode(alarm.toJson()));
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

  // --- NEW: Corrected method ---
  Future<void> showTimerDoneNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
        'timer_done_channel', 'Timer Notifications',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('chimes'),
        playSound: true);
    const iosDetails =
        DarwinNotificationDetails(sound: 'chimes.aiff', presentSound: true);
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _flutterLocalNotificationsPlugin.show(
        999, title, body, notificationDetails);
    _audioService.playCrescendo('sounds/chimes.mp3');
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // --- FIX: Corrected logic ---
  tz.TZDateTime _nextInstanceOfDay(int day, DateTime time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
