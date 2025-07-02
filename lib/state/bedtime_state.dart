// lib/state/bedtime_state.dart
import 'package:flutter/material.dart';
import 'alarm_state.dart';
import '../models/alarm.dart';

class BedtimeState extends ChangeNotifier {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 0);
  Set<int> _activeDays = {1, 2, 3, 4, 5};
  bool _isBedtimeEnabled = true;
  AlarmState? _alarmState;

  TimeOfDay get bedtime => _bedtime;
  TimeOfDay get wakeTime => _wakeTime;
  Set<int> get activeDays => _activeDays;
  bool get isBedtimeEnabled => _isBedtimeEnabled;

  void setAlarmState(AlarmState alarmState) {
    _alarmState = alarmState;
    _updateBedtimeAlarm(); // Initial sync when state is set
  }

  Duration get sleepDuration {
    final bedtimeMinutes = _bedtime.hour * 60 + _bedtime.minute;
    final wakeTimeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    if (wakeTimeMinutes >= bedtimeMinutes) {
      return Duration(minutes: wakeTimeMinutes - bedtimeMinutes);
    } else {
      return Duration(minutes: (24 * 60 - bedtimeMinutes) + wakeTimeMinutes);
    }
  }

  void setBedtime(TimeOfDay newTime) {
    _bedtime = newTime;
    _updateBedtimeAlarm();
    notifyListeners();
  }

  void setWakeTime(TimeOfDay newTime) {
    _wakeTime = newTime;
    _updateBedtimeAlarm();
    notifyListeners();
  }

  void toggleDay(int day) {
    if (_activeDays.contains(day)) {
      _activeDays.remove(day);
    } else {
      _activeDays.add(day);
    }
    _updateBedtimeAlarm();
    notifyListeners();
  }

  void toggleBedtimeEnabled(bool isEnabled) {
    _isBedtimeEnabled = isEnabled;
    _updateBedtimeAlarm();
    notifyListeners();
  }

  Future<void> _updateBedtimeAlarm() async {
    if (_alarmState == null) return;

    const bedtimeAlarmId = 'bedtime-wake-up-alarm';

    // Always attempt to delete the old bedtime alarm first.
    // This handles cases where days change, time changes, or it's disabled.
    await _alarmState!.deleteAlarm(bedtimeAlarmId);

    // If the feature is enabled and has active days, create a new alarm.
    if (_isBedtimeEnabled && _activeDays.isNotEmpty) {
      final now = DateTime.now();
      final wakeDateTime = DateTime(
          now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);

      await _alarmState!.addAlarm(
        id: bedtimeAlarmId, // Use the specific, predictable ID
        time: wakeDateTime,
        label: 'Wake Up',
        days: _activeDays.toList(),
        sound: 'sounds/chimes.mp3', // A default gentle sound for bedtime
      );
    }
  }
}
