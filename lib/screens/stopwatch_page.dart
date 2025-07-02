// lib/screens/stopwatch_page.dart
// --- CORRECTED FILE ---

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../state/stopwatch_state.dart';

class StopwatchPage extends StatelessWidget {
  const StopwatchPage({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds =
        (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StopwatchState>(
      builder: (context, state, child) {
        return CupertinoPageScaffold(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      _formatDuration(state.elapsed),
                      style: const TextStyle(
                          fontSize: 72, fontWeight: FontWeight.w200),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: (state.status == StopwatchStatus.running ||
                                state.status == StopwatchStatus.paused)
                            ? (state.status == StopwatchStatus.running
                                ? state.lap
                                : state.reset)
                            : null,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: CupertinoColors.darkBackgroundGray,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(state.status == StopwatchStatus.running
                                ? 'Lap'
                                : 'Reset'),
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: state.status == StopwatchStatus.running
                            ? state.pause
                            : state.start,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: state.status == StopwatchStatus.running
                                ? const Color(0x33FF3B30)
                                : const Color(0x3334C759),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              state.status == StopwatchStatus.running
                                  ? 'Stop'
                                  : 'Start',
                              style: TextStyle(
                                  color: state.status == StopwatchStatus.running
                                      ? CupertinoColors.systemRed
                                      : CupertinoColors.systemGreen),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // --- START OF FIX ---
                Expanded(
                  flex: 3,
                  child: ListView.separated(
                    itemCount: state.laps.length,
                    separatorBuilder: (context, index) => Container(
                        height: 1,
                        color: CupertinoColors.separator.withOpacity(0.5),
                        margin: const EdgeInsets.only(left: 16)),
                    itemBuilder: (context, index) {
                      // Logic to calculate the time for THIS specific lap
                      final currentLapTime = state.laps[index];
                      final previousLapTime = index < state.laps.length - 1
                          ? state.laps[index + 1]
                          : Duration.zero;
                      final lapDuration = currentLapTime - previousLapTime;

                      // Find the best and worst lap times
                      final sortedLaps = state.laps.map((lap) {
                        final prevLap =
                            state.laps.indexOf(lap) < state.laps.length - 1
                                ? state.laps[state.laps.indexOf(lap) + 1]
                                : Duration.zero;
                        return lap - prevLap;
                      }).toList()
                        ..sort();

                      final bestLap = sortedLaps.first;
                      final worstLap = sortedLaps.last;

                      Color lapColor = CupertinoColors.white;
                      if (state.laps.length > 2) {
                        if (lapDuration == bestLap) {
                          lapColor = CupertinoColors.systemGreen;
                        } else if (lapDuration == worstLap) {
                          lapColor = CupertinoColors.systemRed;
                        }
                      }

                      return CupertinoListTile(
                        leading: Text('Lap ${state.laps.length - index}',
                            style: TextStyle(color: lapColor)),
                        // FIX: The `title` parameter is now provided, and it uses the `lapDuration` variable.
                        title: Text(_formatDuration(lapDuration),
                            style: TextStyle(color: lapColor)),
                        trailing: Text(_formatDuration(currentLapTime)),
                      );
                    },
                  ),
                ),
                // --- END OF FIX ---
              ],
            ),
          ),
        );
      },
    );
  }
}
