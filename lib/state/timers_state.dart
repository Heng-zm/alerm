// lib/state/timers_state.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

enum TimerStatus { initial, running, paused, finished }

// A simple class to hold recent timer data
class RecentTimer {
  final Duration duration;
  final String label;
  RecentTimer({required this.duration, required this.label});

  Map<String, dynamic> toJson() =>
      {'duration': duration.inSeconds, 'label': label};
  factory RecentTimer.fromJson(Map<String, dynamic> json) => RecentTimer(
        duration: Duration(seconds: json['duration']),
        label: json['label'],
      );
}

class TimersState extends ChangeNotifier {
  final NotificationService _notificationService;
  Timer? _timer;

  // Current Timer Properties
  Duration _initialDuration = const Duration(minutes: 5);
  Duration _remainingTime = const Duration(minutes: 5);
  TimerStatus _status = TimerStatus.initial;
  DateTime? _endTime;
  String _label = 'Timer';
  String _sound = 'sounds/radar.mp3';

  // Recents List
  List<RecentTimer> _recents = [];

  // Getters
  Duration get initialDuration => _initialDuration;
  Duration get remainingTime => _remainingTime;
  TimerStatus get status => _status;
  DateTime? get endTime => _endTime;
  String get label => _label;
  String get sound => _sound;
  List<RecentTimer> get recents => _recents;

  TimersState(this._notificationService) {
    loadRecents();
  }

  // --- State Modification Methods ---

  void setDuration(Duration duration) {
    if (duration > Duration.zero) {
      _initialDuration = duration;
      _remainingTime = duration;
      notifyListeners();
    }
  }

  void setLabel(String newLabel) {
    _label = newLabel;
    notifyListeners();
  }

  void setSound(String newSound) {
    _sound = newSound;
    notifyListeners();
  }

  void start() {
    if (_status == TimerStatus.initial || _status == TimerStatus.finished) {
      _remainingTime = _initialDuration;
      _addToRecents(RecentTimer(duration: _initialDuration, label: _label));
    }

    _status = TimerStatus.running;
    _endTime = DateTime.now().add(_remainingTime);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > const Duration(seconds: 1)) {
        _remainingTime -= const Duration(seconds: 1);
      } else {
        _remainingTime = Duration.zero;
        _status = TimerStatus.finished;
        _timer?.cancel();
        _notificationService.showTimerDoneNotification(
            _label, "Time's up!", _sound);
      }
      notifyListeners();
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

  void startRecent(RecentTimer recent) {
    setDuration(recent.duration);
    setLabel(recent.label);
    start();
  }

  // --- Persistence for Recents ---

  void _addToRecents(RecentTimer recent) {
    _recents.removeWhere(
        (r) => r.duration == recent.duration && r.label == recent.label);
    _recents.insert(0, recent);
    if (_recents.length > 5) {
      // Keep only the last 5 recents
      _recents.removeLast();
    }
    saveRecents();
  }

  Future<void> saveRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> recentsJson =
        _recents.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('recent_timers', recentsJson);
    notifyListeners();
  }

  Future<void> loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? recentsJson = prefs.getStringList('recent_timers');
    if (recentsJson != null) {
      _recents = recentsJson
          .map((json) => RecentTimer.fromJson(jsonDecode(json)))
          .toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
