// lib/main.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/alarm_list_page.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/weather_service.dart';
import 'state/alarm_state.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Create instances of our new services
  final audioService = AudioService();
  final notificationService = NotificationService(
      audioService); // Pass AudioService to NotificationService
  final weatherService = WeatherService();

  // 2. Initialize the notification service
  await notificationService.init();

  runApp(
    // 3. Use MultiProvider to make all services and state available to the app
    MultiProvider(
      providers: [
        // Provide the single instances of our services
        Provider.value(value: audioService),
        Provider.value(value: notificationService),

        // Create the main app state, giving it the services it needs
        ChangeNotifierProvider(
          create: (context) => AlarmState(
            notificationService,
            audioService,
            weatherService,
          ),
        ),
      ],
      child: const AlarmApp(),
    ),
  );
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'iOS Alarm App',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
        scaffoldBackgroundColor: CupertinoColors.black,
        barBackgroundColor: CupertinoColors.black,
      ),
      home: AlarmListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
