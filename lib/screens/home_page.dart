// lib/screens/home_page.dart
import 'package:flutter/cupertino.dart';
import 'alarm_list_page.dart';
import 'stopwatch_page.dart';
import 'timers_page.dart';
import 'world_clock_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        inactiveColor: CupertinoColors.inactiveGray,
        activeColor: CupertinoColors.systemOrange,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.globe), label: 'World Clock'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.alarm_fill), label: 'Alarms'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.stopwatch_fill), label: 'Stopwatch'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.timer_fill), label: 'Timers'),
        ],
        currentIndex: 1,
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            return const WorldClockPage(); // NEW
          case 1:
            return const AlarmListPage();
          case 2:
            return const StopwatchPage(); // NEW
          case 3:
            return const TimersPage(); // NEW
          default:
            return const AlarmListPage();
        }
      },
    );
  }
}
