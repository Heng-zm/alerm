// lib/state/timers_state.dart
// --- CORRECTED FILE ---

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

enum TimerStatus { initial, running, paused, finished }

class TimersState extends ChangeNotifier {
  final NotificationService _notificationService; // FIX: This is now used
  Timer? _timer;
  Duration _initialDuration = const Duration(minutes: 5);
  Duration _remainingTime = const Duration(minutes: 5);
  TimerStatus _status = TimerStatus.initial;
  DateTime? _endTime;

  Duration get initialDuration => _initialDuration;
  Duration get remainingTime => _remainingTime;
  TimerStatus get status => _status;
  DateTime? get endTime => _endTime;

  TimersState(this._notificationService);

  void setDuration(Duration duration) {
    if (duration > Duration.zero) {
      _initialDuration = duration;
      _remainingTime = duration;
      notifyListeners();
    }
  }

  void start() {
    if (_status == TimerStatus.initial || _status == TimerStatus.finished) {
      _remainingTime = _initialDuration;
    }

    _status = TimerStatus.running;
    _endTime = DateTime.now().add(_remainingTime);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > const Duration(seconds: 1)) {
        _remainingTime -= const Duration(seconds: 1);
        notifyListeners();
      } else {
        _remainingTime = Duration.zero; // Make sure it hits zero
        _status = TimerStatus.finished;
        _timer?.cancel();
        // FIX: Now calls the notification service correctly
        _notificationService.showTimerDoneNotification("Timer", "Time's up!");
        notifyListeners();
      }
    });
  }

  void pause() {
    if (_status == TimerStatus.running) {
      _status = TimerStatus.paused;
      _timer?.cancel();
      notifyListeners();
    }
  }

  void cancel() {
    _status = TimerStatus.initial;
    _timer?.cancel();
    _remainingTime = _initialDuration;
    _endTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
