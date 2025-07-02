// lib/screens/alarm_list_page.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../models/weather.dart';
import '../state/alarm_state.dart';
import '../widgets/custom_list_tile.dart';
import 'add_edit_alarm_page.dart';

class AlarmListPage extends StatelessWidget {
  const AlarmListPage({super.key});

  String _formatRepeatDays(List<int> days) {
    if (days.isEmpty) {
      return 'Never';
    }
    if (days.length == 7) {
      return 'Every day';
    }
    if (days.length == 5 && days.toSet().containsAll({1, 2, 3, 4, 5})) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.toSet().containsAll({6, 7})) {
      return 'Weekends';
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(days)..sort();
    return sortedDays.map((day) => dayNames[day - 1]).join(', ');
  }

  Widget _buildWeatherInfo(BuildContext context, Alarm alarm) {
    final alarmState = Provider.of<AlarmState>(context);
    if (alarmState.isWeatherLoading) {
      return const CupertinoActivityIndicator(radius: 8);
    }

    final now = DateTime.now();
    DateTime alarmTimeToday;

    // Check if the alarm time for today has already passed. If so, check for tomorrow.
    if (alarm.time.hour < now.hour ||
        (alarm.time.hour == now.hour && alarm.time.minute <= now.minute)) {
      alarmTimeToday = DateTime(
          now.year, now.month, now.day + 1, alarm.time.hour, alarm.time.minute);
    } else {
      alarmTimeToday = DateTime(
          now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);
    }

    Weather? forecast;
    for (var f in alarmState.hourlyForecast) {
      if (f.time.toLocal().hour == alarmTimeToday.hour &&
          f.time.toLocal().day == alarmTimeToday.day) {
        forecast = f;
        break;
      }
    }

    if (forecast == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
            'assets/images/weather/${_getWeatherIcon(forecast.icon)}.png',
            width: 18,
            height: 18),
        const SizedBox(width: 4),
        Text('${forecast.temperature}°C',
            style: const TextStyle(
                color: CupertinoColors.systemGrey, fontSize: 13)),
      ],
    );
  }

  String _getWeatherIcon(String iconCode) {
    if (iconCode.contains('01')) return 'sun.png';
    if (iconCode.contains('02') ||
        iconCode.contains('03') ||
        iconCode.contains('04')) return 'cloud.png';
    if (iconCode.contains('09') || iconCode.contains('10')) return 'rain.png';
    if (iconCode.contains('11')) return 'storm.png';
    if (iconCode.contains('13')) return 'snow.png';
    if (iconCode.contains('50')) return 'mist.png';
    return 'sun.png'; // Default
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Alarms'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const AddEditAlarmPage()),
          ),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: Consumer<AlarmState>(
        builder: (context, alarmState, child) {
          if (alarmState.alarms.isEmpty) {
            return const Center(child: Text("No Alarms"));
          }
          return ListView.separated(
            itemCount: alarmState.alarms.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: CupertinoColors.separator.withOpacity(0.2),
              margin: const EdgeInsets.only(left: 16),
            ),
            itemBuilder: (context, index) {
              final alarm = alarmState.alarms[index];
              return Dismissible(
                key: Key(alarm.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  alarmState.deleteAlarm(alarm.id);
                },
                background: Container(
                  color: CupertinoColors.systemRed,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(CupertinoIcons.delete_solid,
                      color: CupertinoColors.white),
                ),
                child: CustomCupertinoListTile(
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => AddEditAlarmPage(alarm: alarm)),
                  ),
                  title: Text(
                    DateFormat('h:mm').format(alarm.time),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: alarm.isActive
                          ? CupertinoColors.white
                          : CupertinoColors.inactiveGray,
                    ),
                  ),
                  leading: Text(
                    DateFormat('a').format(alarm.time),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: alarm.isActive
                          ? CupertinoColors.white
                          : CupertinoColors.inactiveGray,
                      height: 2.7,
                    ),
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${alarm.label}, ${_formatRepeatDays(alarm.days)}',
                        style: TextStyle(
                            color: alarm.isActive
                                ? CupertinoColors.white
                                : CupertinoColors.inactiveGray),
                      ),
                      if (alarm.isActive) _buildWeatherInfo(context, alarm),
                    ],
                  ),
                  trailing: CupertinoSwitch(
                    value: alarm.isActive,
                    onChanged: (value) => alarmState.toggleAlarm(alarm.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
