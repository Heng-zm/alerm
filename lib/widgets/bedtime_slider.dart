// lib/widgets/bedtime_slider.dart
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_haptic_feedback/flutter_haptic_feedback.dart';
import 'package:provider/provider.dart';
import '../state/bedtime_state.dart';

enum _DragHandle { bedtime, wakeTime, none }

class BedtimeSlider extends StatefulWidget {
  const BedtimeSlider({super.key});

  @override
  State<BedtimeSlider> createState() => _BedtimeSliderState();
}

class _BedtimeSliderState extends State<BedtimeSlider> {
  _DragHandle _dragHandle = _DragHandle.none;

  double _timeToAngle(TimeOfDay time) {
    // 24-hour format for angle calculation
    final totalMinutes = time.hour * 60 + time.minute;
    return (totalMinutes / (24 * 60)) * 2 * pi;
  }

  TimeOfDay _angleToTime(double angle) {
    final totalMinutes = (angle / (2 * pi)) * (24 * 60);
    final snappedMinutes =
        (totalMinutes / 5).round() * 5; // Snap to 5-minute intervals
    final hour = (snappedMinutes ~/ 60) % 24;
    final minute = snappedMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  double _offsetToAngle(Offset offset, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // atan2 gives angle from -pi to pi. We adjust it to be 0 to 2*pi from the top.
    return (atan2(offset.dy - center.dy, offset.dx - center.dx) + pi / 2) %
        (2 * pi);
  }

  void _onPanStart(DragStartDetails details) {
    final size = context.size!;
    final bedtimeState = Provider.of<BedtimeState>(context, listen: false);

    final bedtimeAngle = _timeToAngle(bedtimeState.bedtime);
    final wakeTimeAngle = _timeToAngle(bedtimeState.wakeTime);
    final touchAngle = _offsetToAngle(details.localPosition, size);

    // Helper to calculate the shortest distance between two angles on a circle
    double angleDiff(double a1, double a2) {
      return min((a1 - a2).abs(), 2 * pi - (a1 - a2).abs());
    }

    const grabTolerance = pi / 8; // How close you need to be to grab a handle

    if (angleDiff(touchAngle, bedtimeAngle) < grabTolerance) {
      _dragHandle = _DragHandle.bedtime;
    } else if (angleDiff(touchAngle, wakeTimeAngle) < grabTolerance) {
      _dragHandle = _DragHandle.wakeTime;
    } else {
      _dragHandle = _DragHandle.none;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragHandle == _DragHandle.none) return;

    final bedtimeState = Provider.of<BedtimeState>(context, listen: false);
    final angle = _offsetToAngle(details.localPosition, context.size!);
    final newTime = _angleToTime(angle);

    HapticFeedback.selectionClick();

    if (_dragHandle == _DragHandle.bedtime) {
      if (newTime != bedtimeState.bedtime) bedtimeState.setBedtime(newTime);
    } else {
      if (newTime != bedtimeState.wakeTime) bedtimeState.setWakeTime(newTime);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _dragHandle = _DragHandle.none;
  }

  @override
  Widget build(BuildContext context) {
    final bedtimeState = Provider.of<BedtimeState>(context);

    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: _BedtimePainter(
            bedtime: bedtimeState.bedtime,
            wakeTime: bedtimeState.wakeTime,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimeDisplay(context, CupertinoIcons.bed_double_fill,
                    "Bedtime", bedtimeState.bedtime),
                const SizedBox(height: 40),
                _buildTimeDisplay(context, CupertinoIcons.sunrise_fill,
                    "Wake Up", bedtimeState.wakeTime),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(
      BuildContext context, IconData icon, String label, TimeOfDay time) {
    // Manual formatting for 12-hour clock with AM/PM
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final String formattedTime = '$hour:$minute $period';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: CupertinoColors.systemGrey),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: CupertinoColors.systemGrey)),
              Text(formattedTime,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }
}

class _BedtimePainter extends CustomPainter {
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;

  _BedtimePainter({required this.bedtime, required this.wakeTime});

  double _timeToAngle(TimeOfDay time) {
    final totalMinutes = time.hour * 60 + time.minute;
    return (totalMinutes / (24 * 60)) * 2 * pi -
        pi / 2; // Offset by -90 degrees to start at top
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;
    const strokeWidth = 30.0;

    final bedtimeAngle = _timeToAngle(bedtime);
    final wakeTimeAngle = _timeToAngle(wakeTime);

    final trackPaint = Paint()
      ..color = CupertinoColors.darkBackgroundGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = CupertinoColors.systemOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double sweepAngle = wakeTimeAngle - bedtimeAngle;
    if (sweepAngle < 0) {
      // Handles overnight case
      sweepAngle += 2 * pi;
    }

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        bedtimeAngle, sweepAngle, false, arcPaint);

    _drawHandle(
        canvas, center, radius, bedtimeAngle, CupertinoIcons.bed_double_fill);
    _drawHandle(
        canvas, center, radius, wakeTimeAngle, CupertinoIcons.sunrise_fill);
  }

  void _drawHandle(Canvas canvas, Offset center, double radius, double angle,
      IconData icon) {
    final handleX = center.dx + radius * cos(angle);
    final handleY = center.dy + radius * sin(angle);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
            fontSize: 24,
            fontFamily: icon.fontFamily,
            color: CupertinoColors.white),
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(
            handleX - textPainter.width / 2, handleY - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
