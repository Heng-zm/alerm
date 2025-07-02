// lib/state/alarm_state.dart
// --- FULLY CORRECTED FILE ---

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/weather.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';

class AlarmState extends ChangeNotifier {
  final NotificationService _notificationService;
  final AudioService _audioService;
  final WeatherService _weatherService;
  final Uuid _uuid = const Uuid();

  List<Alarm> _alarms = [];
  List<Weather> _hourlyForecast = [];
  bool _isWeatherLoading = false;
  bool _isEditMode = false;

  List<Alarm> get alarms => _alarms;
  List<Weather> get hourlyForecast => _hourlyForecast;
  bool get isWeatherLoading => _isWeatherLoading;
  bool get isEditMode => _isEditMode;
  AudioService get audioService => _audioService;

  AlarmState(
      this._notificationService, this._audioService, this._weatherService) {
    loadAlarms();
    fetchWeather();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  Future<void> fetchWeather() async {
    _isWeatherLoading = true;
    notifyListeners();
    _hourlyForecast = await _weatherService.getHourlyForecast();
    _isWeatherLoading = false;
    notifyListeners();
  }

  Future<void> addAlarm({
    required DateTime time,
    required String label,
    required List<int> days,
    required String sound,
    String? id,
  }) async {
    final newAlarm = Alarm(
      id: id ?? _uuid.v4(),
      label: label,
      time: time,
      isActive: true,
      days: days,
      sound: sound,
    );
    _alarms.removeWhere((alarm) => alarm.id == newAlarm.id);
    _alarms.add(newAlarm);
    await _notificationService.scheduleAlarm(newAlarm);
    await _saveAndSortAlarms();
  }

  // --- FIX: Changed to named parameters for consistency ---
  Future<void> updateAlarm({
    required String id,
    required DateTime newTime,
    required String newLabel,
    required List<int> newDays,
    required String newSound,
  }) async {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      final oldAlarm = _alarms[index];
      if (oldAlarm.isActive) {
        await _notificationService.cancelAlarm(oldAlarm);
      }

      final updatedAlarm = Alarm(
        id: oldAlarm.id,
        label: newLabel,
        time: newTime,
        isActive: oldAlarm.isActive,
        days: newDays,
        sound: newSound,
      );

      _alarms[index] = updatedAlarm;
      if (updatedAlarm.isActive) {
        await _notificationService.scheduleAlarm(updatedAlarm);
      }
      await _saveAndSortAlarms();
    }
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      final oldAlarm = _alarms[index];
      final newAlarm = Alarm(
        id: oldAlarm.id,
        label: oldAlarm.label,
        time: oldAlarm.time,
        isActive: !oldAlarm.isActive,
        days: oldAlarm.days,
        sound: oldAlarm.sound,
      );
      _alarms[index] = newAlarm;
      if (newAlarm.isActive) {
        await _notificationService.scheduleAlarm(newAlarm);
      } else {
        await _notificationService.cancelAlarm(newAlarm);
      }
      await _saveAndSortAlarms();
    }
  }

  Future<void> deleteAlarm(String id) async {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      final alarmToDelete = _alarms[index];
      if (alarmToDelete.isActive) {
        await _notificationService.cancelAlarm(alarmToDelete);
      }
      _alarms.removeAt(index);
      await _saveAndSortAlarms();
    }
  }

  Future<void> _saveAndSortAlarms() async {
    _alarms.sort((a, b) => a.time.hour.compareTo(b.time.hour) == 0
        ? a.time.minute.compareTo(b.time.minute)
        : a.time.hour.compareTo(b.time.hour));
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmJsonList =
        _alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
    await prefs.setStringList('alarms', alarmJsonList);
    notifyListeners();
  }

  Future<void> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? alarmJsonList = prefs.getStringList('alarms');
    if (alarmJsonList != null) {
      _alarms = alarmJsonList
          .map((jsonString) => Alarm.fromJson(jsonDecode(jsonString)))
          .toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
