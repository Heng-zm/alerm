// lib/screens/timers_page.dart
// --- CORRECTED FILE ---

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/timers_state.dart';

class TimersPage extends StatelessWidget {
  const TimersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimersState>(
      builder: (context, state, child) {
        return CupertinoPageScaffold(
          child: SafeArea(
            child: state.status == TimerStatus.initial
                ? _buildPickerView(context, state)
                : _buildRunningView(context, state),
          ),
        );
      },
    );
  }

  Widget _buildPickerView(BuildContext context, TimersState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hms,
            initialTimerDuration: state.initialDuration,
            onTimerDurationChanged: (duration) => state.setDuration(duration),
          ),
        ),
        const SizedBox(height: 30),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: state.start,
          child: Container(
            // FIX: Use a styled Container
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0x3334C759),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('Start',
                  style: TextStyle(color: CupertinoColors.systemGreen)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunningView(BuildContext context, TimersState state) {
    final progress = state.initialDuration.inSeconds > 0
        ? state.remainingTime.inSeconds / state.initialDuration.inSeconds
        : 0.0;
    final formattedRemaining = _formatDuration(state.remainingTime);

    return Column(
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
                        Text(DateFormat('h:mm a').format(state.endTime!),
                            style: const TextStyle(
                                color: CupertinoColors.inactiveGray,
                                fontSize: 16)),
                      ],
                    ),
                  Text(
                    formattedRemaining,
                    style: TextStyle(
                        fontSize: 64,
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
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: state.cancel,
                child: Container(
                  // FIX: Use a styled Container
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                      color: CupertinoColors.darkBackgroundGray,
                      shape: BoxShape.circle),
                  child: const Center(child: Text('Cancel')),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: state.status == TimerStatus.running
                    ? state.pause
                    : state.start,
                child: Container(
                  // FIX: Use a styled Container
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: state.status == TimerStatus.running
                          ? const Color(0x33FF9500)
                          : const Color(0x3334C759),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      state.status == TimerStatus.running ? 'Pause' : 'Resume',
                      style: TextStyle(
                          color: state.status == TimerStatus.running
                              ? CupertinoColors.systemOrange
                              : CupertinoColors.systemGreen),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
    const strokeWidth = 5.0; // FIX: Make this const

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
