// lib/state/stopwatch_state.dart
// --- CORRECTED FILE ---

import 'dart:async';
import 'package:flutter/material.dart';

enum StopwatchStatus { initial, running, paused }

class StopwatchState extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final List<Duration> _laps = []; // FIX: Make the list final
  StopwatchStatus _status = StopwatchStatus.initial;

  Duration get elapsed => _elapsed;
  List<Duration> get laps => _laps;
  StopwatchStatus get status => _status;

  void start() {
    _stopwatch.start();
    _status = StopwatchStatus.running;
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      _elapsed = _stopwatch.elapsed;
      notifyListeners();
    });
  }

  void pause() {
    _stopwatch.stop();
    _status = StopwatchStatus.paused;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _stopwatch.stop();
    _stopwatch.reset();
    _status = StopwatchStatus.initial;
    _elapsed = Duration.zero;
    _laps.clear();
    _timer?.cancel();
    notifyListeners();
  }

  void lap() {
    if (_status == StopwatchStatus.running) {
      _laps.insert(0, _stopwatch.elapsed);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
