// lib/screens/add_edit_alarm_page.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../state/alarm_state.dart';
import '../widgets/custom_list_tile.dart';
import 'sound_selection_page.dart'; // Import the new sound selection page

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
      _selectedSound = 'sounds/radar.mp3'; // Default sound
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
      alarmState.updateAlarm(widget.alarm!.id, _selectedTime,
          _labelController.text, _selectedDays, _selectedSound);
    } else {
      alarmState.addAlarm(
          _selectedTime, _labelController.text, _selectedDays, _selectedSound);
    }
    Navigator.pop(context);
  }

  String _buildRepeatText() {
    if (_selectedDays.isEmpty) return 'Never';
    if (_selectedDays.length == 7) return 'Every Day';
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<int>.from(_selectedDays)..sort();
    return sortedDays.map((day) => dayNames[day - 1]).join(', ');
  }

  void _showDayPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => CupertinoActionSheet(
        title: const Text('Repeat'),
        actions: List.generate(7, (index) {
          final day = index + 1;
          final isSelected = _selectedDays.contains(day);
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                if (isSelected) {
                  _selectedDays.remove(day);
                } else {
                  _selectedDays.add(day);
                }
              });
              Navigator.pop(modalContext);
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
    // Navigate to the sound selection page and wait for a result
    final result = await Navigator.push<String>(
      context,
      CupertinoPageRoute(builder: (context) => const SoundSelectionPage()),
    );
    if (result != null) {
      setState(() {
        _selectedSound = result;
      });
    }
  }

  String _formatSoundName(String soundPath) {
    String name = soundPath.split('/').last.split('.').first;
    return name.replaceFirst(name[0], name[0].toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(isEditing ? 'Edit Alarm' : 'Add Alarm'),
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
                onDateTimeChanged: (newTime) =>
                    setState(() => _selectedTime = newTime),
              ),
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CustomCupertinoListTile(
                  title: const Text('Repeat'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_buildRepeatText(),
                          style: const TextStyle(
                              color: CupertinoColors.inactiveGray)),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.right_chevron,
                          color: CupertinoColors.inactiveGray, size: 20),
                    ],
                  ),
                  onTap: _showDayPicker,
                ),
                CustomCupertinoListTile(
                  title: const Text('Label'),
                  trailing: Expanded(
                    child: CupertinoTextField(
                      controller: _labelController,
                      placeholder: 'Alarm',
                      decoration: const BoxDecoration(),
                      textAlign: TextAlign.right,
                      style:
                          const TextStyle(color: CupertinoColors.inactiveGray),
                    ),
                  ),
                ),
                CustomCupertinoListTile(
                  title: const Text('Sound'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatSoundName(_selectedSound),
                          style: const TextStyle(
                              color: CupertinoColors.inactiveGray)),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.right_chevron,
                          color: CupertinoColors.inactiveGray, size: 20),
                    ],
                  ),
                  onTap: _selectSound,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
