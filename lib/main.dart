// lib/main.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/home_page.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'services/weather_service.dart';
import 'state/alarm_state.dart';
import 'state/bedtime_state.dart';
import 'state/stopwatch_state.dart';
import 'state/timers_state.dart';
import 'state/world_clock_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create instances of all services.
  final audioService = AudioService();
  final notificationService = NotificationService(audioService);
  final weatherService = WeatherService();
  final soundService = SoundService();

  // Perform async initializations.
  await notificationService.init();
  await soundService.loadCustomSounds(); // Load custom sounds at startup.

  runApp(
    MultiProvider(
      providers: [
        // Provide services.
        Provider.value(value: audioService),
        Provider.value(value: notificationService),

        // Provide SoundService as a ChangeNotifier so widgets can listen to it.
        ChangeNotifierProvider.value(value: soundService),

        // Provide state managers.
        ChangeNotifierProvider(
          create: (context) =>
              AlarmState(notificationService, audioService, weatherService),
        ),
        ChangeNotifierProvider(create: (context) => WorldClockState()),
        ChangeNotifierProvider(create: (context) => StopwatchState()),
        ChangeNotifierProvider(
            create: (context) => TimersState(notificationService)),
        ChangeNotifierProvider(create: (context) => BedtimeState()),
      ],
      child: Builder(builder: (context) {
        // Link BedtimeState to AlarmState.
        final alarmState = Provider.of<AlarmState>(context, listen: false);
        Provider.of<BedtimeState>(context, listen: false)
            .setAlarmState(alarmState);

        return const AlarmApp();
      }),
    ),
  );
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'iOS Clock App',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
        scaffoldBackgroundColor: CupertinoColors.black,
        barBackgroundColor: CupertinoColors.black,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
