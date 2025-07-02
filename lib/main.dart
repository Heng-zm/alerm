// lib/main.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/home_page.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/weather_service.dart';
import 'state/alarm_state.dart';
import 'state/stopwatch_state.dart';
import 'state/timers_state.dart';
import 'state/world_clock_state.dart';

void main() async {
  // Ensure that Flutter bindings are initialized before calling async code.
  // This is required for plugins to work before runApp() is called.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Create singleton instances of all our services.
  // These will be created once and shared across the entire app.
  final audioService = AudioService();
  final notificationService = NotificationService(
      audioService); // Pass AudioService to NotificationService
  final weatherService = WeatherService();

  // 2. Initialize the notification service before the app starts.
  // This sets up timezones, permissions, and notification channels.
  await notificationService.init();

  runApp(
    // 3. Use MultiProvider to make all services and state managers available.
    // This is the recommended way to handle multiple providers for a clean architecture.
    MultiProvider(
      providers: [
        // --- SERVICES ---
        // Use Provider.value for existing objects (our services).
        // This ensures the same instance is used everywhere without re-creating it.
        Provider.value(value: audioService),
        Provider.value(value: notificationService),

        // --- STATE MANAGERS ---
        // Use ChangeNotifierProvider for state management classes.
        // It creates the state object and provides it to its descendants.
        // It automatically listens for changes and rebuilds widgets that depend on it.
        ChangeNotifierProvider(
          create: (context) => AlarmState(
            notificationService,
            audioService,
            weatherService,
          ),
        ),
        ChangeNotifierProvider(create: (context) => WorldClockState()),
        ChangeNotifierProvider(create: (context) => StopwatchState()),
        ChangeNotifierProvider(
            create: (context) => TimersState(notificationService)),
      ],
      // The child of MultiProvider is the root of our application.
      child: const AlarmApp(),
    ),
  );
}

// This is the root widget of the application.
class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    // CupertinoApp is used to create an app with an iOS look and feel.
    return const CupertinoApp(
      title: 'iOS Alarm App',
      // Define the app-wide theme to match the native iOS dark mode look.
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
        scaffoldBackgroundColor: CupertinoColors.black,
        barBackgroundColor: CupertinoColors.black,
      ),
      // Set the home page to our HomePage which contains the tab bar.
      home: HomePage(),
      // Hides the "debug" banner in the top-right corner.
      debugShowCheckedModeBanner: false,
    );
  }
}
