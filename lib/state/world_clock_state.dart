// lib/state/world_clock_state.dart
// --- CORRECTED FILE ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Note: 'package:timezone/timezone.dart' is not needed here as it's used in the UI file.

class WorldClockState extends ChangeNotifier {
  List<String> _selectedCities = [];
  Timer? _timer;
  bool _isEditMode = false; // --- NEW: Flag for edit mode ---

  List<String> get selectedCities => _selectedCities;
  bool get isEditMode => _isEditMode; // --- NEW: Getter for the UI to read ---

  WorldClockState() {
    loadCities();
    // Update the clock display every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
    });
  }

  // --- NEW: Method to toggle edit mode ---
  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  Future<void> loadCities() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCities = prefs.getStringList('world_clocks') ??
        ['America/New_York', 'Europe/London', 'Asia/Tokyo'];
    notifyListeners();
  }

  Future<void> _saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('world_clocks', _selectedCities);
  }

  void addCity(String timezone) {
    if (!_selectedCities.contains(timezone)) {
      _selectedCities.add(timezone);
      _saveCities();
      notifyListeners();
    }
  }

  // This method is now used by the "Edit" mode's delete button
  void removeCity(String timezone) {
    _selectedCities.remove(timezone);
    _saveCities();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
