// lib/screens/add_edit_alarm_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_haptic_feedback/flutter_haptic_feedback.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../services/sound_service.dart';
import '../state/alarm_state.dart';
import '../widgets/custom_list_tile.dart';
import 'sound_selection_page.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class AddEditAlarmPage extends StatefulWidget {
  final Alarm? alarm;
  const AddEditAlarmPage({super.key, this.alarm});

  @override
  State<AddEditAlarmPage> createState() => _AddEditAlarmPageState();
}

class _AddEditAlarmPageState extends State<AddEditAlarmPage> {
  late DateTime _selectedTime;
  late TextEditingController _labelController;
  late List<int> _selectedDays;
  late String _selectedSound;

  bool get isEditing => widget.alarm != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _selectedTime = widget.alarm!.time;
      _labelController = TextEditingController(text: widget.alarm!.label);
      _selectedDays = List<int>.from(widget.alarm!.days);
      _selectedSound = widget.alarm!.sound;
    } else {
      _selectedTime = DateTime.now();
      _labelController = TextEditingController(text: 'Alarm');
      _selectedDays = [];
      _selectedSound = 'sounds/radar.mp3';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _onSave() {
    final alarmState = Provider.of<AlarmState>(context, listen: false);
    if (isEditing) {
      alarmState.updateAlarm(
        id: widget.alarm!.id,
        newTime: _selectedTime,
        newLabel: _labelController.text,
        newDays: _selectedDays,
        newSound: _selectedSound,
      );
    } else {
      alarmState.addAlarm(
        time: _selectedTime,
        label: _labelController.text,
        days: _selectedDays,
        sound: _selectedSound,
      );
    }
    Navigator.pop(context);
  }

  String _buildRepeatText() {
    if (_selectedDays.isEmpty) return 'Never';
    if (_selectedDays.length == 7) return 'Every Day';
    final daySet = _selectedDays.toSet();
    if (daySet.length == 5 && daySet.containsAll({1, 2, 3, 4, 5}))
      return 'Weekdays';
    if (daySet.length == 2 && daySet.containsAll({6, 7})) return 'Weekends';

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(_selectedDays)..sort();
    return sortedDays.map((day) => dayNames[day - 1]).join(', ');
  }

  void _showDayPicker() {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => CupertinoActionSheet(
        title: const Text('Repeat'),
        actions: List.generate(7, (index) {
          final day = index + 1;
          final isSelected = _selectedDays.contains(day);
          return CupertinoActionSheetAction(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isSelected) {
                  _selectedDays.remove(day);
                } else {
                  _selectedDays.add(day);
                }
              });
              Navigator.pop(modalContext);
              _showDayPicker();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Every ${const [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday'
                ][index]}'),
                if (isSelected)
                  const Icon(CupertinoIcons.check_mark,
                      color: CupertinoColors.systemOrange),
              ],
            ),
          );
        }),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(modalContext),
          child: const Text('Done'),
        ),
      ),
    );
  }

  void _selectSound() async {
    HapticFeedback.lightImpact();
    // Navigate and wait for a Sound object to be returned
    final result = await Navigator.push<Sound>(
      context,
      CupertinoPageRoute(
          builder: (context) =>
              SoundSelectionPage(currentSoundPath: _selectedSound)),
    );

    // After returning, if a sound was selected, update the state.
    if (result != null && mounted) {
      setState(() {
        _selectedSound = result.path;
      });
    }
  }

  String _formatSoundName(String soundPath) {
    // Use the SoundService to find the display name for a given path.
    final soundService = Provider.of<SoundService>(context, listen: false);
    final sound = soundService.allSounds.firstWhere(
      (s) => s.path == soundPath,
      orElse: () => Sound(name: 'Default', path: '', isCustom: true),
    );
    return sound.name;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(isEditing ? 'Edit Alarm' : 'Add Alarm'),
        previousPageTitle: 'Alarms',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _onSave,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedTime,
                onDateTimeChanged: (newTime) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTime = newTime);
                },
              ),
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CustomCupertinoListTile(
                    title: const Text('Repeat'),
                    onTap: _showDayPicker,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_buildRepeatText(),
                          style: const TextStyle(
                              color: CupertinoColors.inactiveGray)),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.right_chevron,
                          color: CupertinoColors.inactiveGray, size: 20)
                    ])),
                CustomCupertinoListTile(
                    title: const Text('Label'),
                    trailing: Expanded(
                        child: CupertinoTextField(
                            controller: _labelController,
                            placeholder: 'Alarm',
                            decoration: const BoxDecoration(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: CupertinoColors.inactiveGray)))),
                CustomCupertinoListTile(
                    title: const Text('Sound'),
                    onTap: _selectSound,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_formatSoundName(_selectedSound),
                          style: const TextStyle(
                              color: CupertinoColors.inactiveGray)),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.right_chevron,
                          color: CupertinoColors.inactiveGray, size: 20)
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
