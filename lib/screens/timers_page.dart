// lib/screens/timers_page.dart
// --- FULLY CORRECTED FILE ---

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_haptic_feedback/flutter_haptic_feedback.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/timers_state.dart';
import 'timer_sound_page.dart';
import '../widgets/custom_list_tile.dart';

class TimersPage extends StatelessWidget {
  const TimersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimersState>(
      builder: (context, state, child) {
        if (state.status == TimerStatus.running ||
            state.status == TimerStatus.paused ||
            state.status == TimerStatus.finished) {
          return const _RunningTimerView();
        } else {
          return const _InitialTimerView();
        }
      },
    );
  }
}

// --- WIDGET FOR THE INITIAL "SET TIMER" VIEW ---
class _InitialTimerView extends StatelessWidget {
  const _InitialTimerView();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<TimersState>(context);
    final soundName = state.sound.split('/').last.split('.').first.capitalize();

    return CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Timers'),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              Container(
                height: 216,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: state.initialDuration,
                  onTimerDurationChanged: (duration) {
                    HapticFeedback.selectionClick();
                    state.setDuration(duration);
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(
                        text: 'Cancel',
                        color: CupertinoColors.darkBackgroundGray,
                        textColor: CupertinoColors.white,
                        onPressed: () {}),
                    _buildActionButton(
                        text: 'Start',
                        color: const Color(0x3334C759),
                        textColor: CupertinoColors.systemGreen,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          state.start();
                        }),
                  ],
                ),
              ),
              CupertinoListSection.insetGrouped(
                children: [
                  CustomCupertinoListTile(
                    title: const Text('Label'),
                    trailing: Expanded(
                      child: CupertinoTextField(
                        placeholder: 'Timer',
                        controller: TextEditingController(text: state.label),
                        decoration: const BoxDecoration(),
                        textAlign: TextAlign.right,
                        onChanged: (value) => state.setLabel(value),
                        style: const TextStyle(
                            color: CupertinoColors.inactiveGray),
                      ),
                    ),
                  ),
                  CustomCupertinoListTile(
                    title: const Text('When Timer Ends'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(soundName,
                            style: const TextStyle(
                                color: CupertinoColors.inactiveGray)),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.right_chevron,
                            color: CupertinoColors.inactiveGray, size: 20),
                      ],
                    ),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final newSound = await Navigator.push<String>(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => const TimerSoundPage()));
                      if (newSound != null) {
                        state.setSound(newSound);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (state.recents.isNotEmpty) _buildRecentsSection(context, state),
      ],
    );
  }

  Widget _buildActionButton(
      {required String text,
      required Color color,
      required Color textColor,
      required VoidCallback onPressed}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
            child:
                Text(text, style: TextStyle(color: textColor, fontSize: 18))),
      ),
    );
  }

  Widget _buildRecentsSection(BuildContext context, TimersState state) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const Padding(
          padding: EdgeInsets.only(left: 32.0, bottom: 8.0),
          child: Text('Recents',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        CupertinoListSection.insetGrouped(
          children: state.recents.map((recent) {
            final durationText = _formatRecentDuration(recent.duration);
            return CustomCupertinoListTile(
              title: Text(durationText),
              subtitle: Text(recent.label),
              trailing: CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  state.startRecent(recent);
                },
                child: const Icon(CupertinoIcons.play_arrow_solid,
                    color: CupertinoColors.systemGreen),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  String _formatRecentDuration(Duration d) {
    if (d.inHours > 0)
      return '${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    if (d.inMinutes > 0)
      return '${d.inMinutes.remainder(60)}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return '${d.inSeconds} sec';
  }
}

// --- WIDGET FOR THE RUNNING/PAUSED TIMER VIEW ---
class _RunningTimerView extends StatelessWidget {
  const _RunningTimerView();
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<TimersState>(context);
    final progress = state.initialDuration.inSeconds > 0
        ? state.remainingTime.inSeconds / state.initialDuration.inSeconds
        : 0.0;
    final formattedRemaining = _formatDuration(state.remainingTime);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: TimerPainter(
                    progress: progress,
                    isFinished: state.status == TimerStatus.finished),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.endTime != null &&
                          state.status != TimerStatus.finished)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.bell_fill,
                                size: 16, color: CupertinoColors.inactiveGray),
                            const SizedBox(width: 4),
                            // --- FIX: Corrected CupertinoIcons to CupertinoColors ---
                            Text(DateFormat('h:mm a').format(state.endTime!),
                                style: const TextStyle(
                                    color: CupertinoColors.inactiveGray,
                                    fontSize: 16)),
                          ],
                        ),
                      Text(
                        formattedRemaining,
                        style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                            color: state.status == TimerStatus.finished
                                ? CupertinoColors.systemOrange
                                : CupertinoColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                      text: 'Cancel',
                      color: CupertinoColors.darkBackgroundGray,
                      textColor: CupertinoColors.white,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        state.cancel();
                      }),
                  _buildActionButton(
                      text: state.status == TimerStatus.running
                          ? 'Pause'
                          : 'Resume',
                      color: state.status == TimerStatus.running
                          ? const Color(0x33FF9500)
                          : const Color(0x3334C759),
                      textColor: state.status == TimerStatus.running
                          ? CupertinoColors.systemOrange
                          : CupertinoColors.systemGreen,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        state.status == TimerStatus.running
                            ? state.pause()
                            : state.start();
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required String text,
      required Color color,
      required Color textColor,
      required VoidCallback onPressed}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(
            child:
                Text(text, style: TextStyle(color: textColor, fontSize: 18))),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final bool isFinished;
  TimerPainter({required this.progress, required this.isFinished});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 5.0;

    final backgroundPaint = Paint()
      ..color = CupertinoColors.darkBackgroundGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = isFinished
          ? CupertinoColors.systemOrange.withOpacity(0.5)
          : CupertinoColors.systemOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressAngle = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        -progressAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper extension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
