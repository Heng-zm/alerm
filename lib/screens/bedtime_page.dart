// lib/screens/bedtime_page.dart
// --- FULLY CORRECTED FILE ---

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_haptic_feedback/flutter_haptic_feedback.dart';
import 'package:provider/provider.dart';
import '../state/bedtime_state.dart';
import '../widgets/bedtime_slider.dart';

class BedtimePage extends StatelessWidget {
  const BedtimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bedtimeState = Provider.of<BedtimeState>(context);
    final duration = bedtimeState.sleepDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Bedtime'),
            trailing: CupertinoSwitch(
              value: bedtimeState.isBedtimeEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact(); // FIX: Added haptic feedback
                bedtimeState.toggleBedtimeEnabled(value);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Opacity(
              opacity: bedtimeState.isBedtimeEnabled ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !bedtimeState.isBedtimeEnabled,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Set a regular wake-up time and bedtime to improve your sleep.',
                        textAlign: TextAlign.center,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(color: CupertinoColors.systemGrey),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        '${hours}h ${minutes}m of sleep',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      const BedtimeSlider(),
                      const SizedBox(height: 50),
                      _buildSchedule(context, bedtimeState),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule(BuildContext context, BedtimeState state) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Column(
      children: [
        Text(
          'Active on these days:',
          style: CupertinoTheme.of(context)
              .textTheme
              .textStyle
              .copyWith(color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final dayIndex = index + 1;
            final isActive = state.activeDays.contains(dayIndex);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact(); // FIX: Added haptic feedback
                state.toggleDay(dayIndex);
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: isActive
                    ? CupertinoColors.systemOrange
                    : CupertinoColors.darkBackgroundGray,
                child: Text(days[index],
                    style: TextStyle(
                        color: isActive
                            ? CupertinoColors.white
                            : CupertinoColors.inactiveGray,
                        fontWeight: FontWeight.bold)),
              ),
            );
          }),
        )
      ],
    );
  }
}
