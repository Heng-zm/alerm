// lib/screens/world_clock_page.dart
// --- CORRECTED FILE ---

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../state/world_clock_state.dart';
import 'city_selection_page.dart';

class WorldClockPage extends StatelessWidget {
  const WorldClockPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We listen to the state to rebuild when edit mode changes.
    final worldClockState = Provider.of<WorldClockState>(context);
    final isEditMode = worldClockState.isEditMode;

    return CustomScrollView(
      slivers: <Widget>[
        CupertinoSliverNavigationBar(
          largeTitle: const Text('World Clock'),
          // --- FIX: The leading button is now dynamic ---
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            // Disable the button if the list is empty
            onPressed: worldClockState.selectedCities.isEmpty
                ? null
                : () => worldClockState.toggleEditMode(),
            child: Text(isEditMode ? 'Done' : 'Edit'),
          ),
          // --- FIX: The trailing button now disappears in edit mode ---
          trailing: isEditMode
              ? null
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.add),
                  onPressed: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const CitySelectionPage(),
                        fullscreenDialog: true),
                  ),
                ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final timezone = worldClockState.selectedCities[index];
              return _buildClockListItem(context, timezone, worldClockState);
            },
            childCount: worldClockState.selectedCities.length,
          ),
        ),
      ],
    );
  }

  // Helper method to build each item in the list
  Widget _buildClockListItem(
      BuildContext context, String timezone, WorldClockState state) {
    final isEditMode = state.isEditMode;
    final location = tz.getLocation(timezone);
    final now = tz.TZDateTime.now(location);
    final localNow = tz.TZDateTime.now(tz.local);

    final timeDifference = now.timeZoneOffset - localNow.timeZoneOffset;
    final hoursDifference = timeDifference.inHours;

    String differenceText;
    if (now.day > localNow.day) {
      differenceText = 'Tomorrow, ';
    } else if (now.day < localNow.day) {
      differenceText = 'Yesterday, ';
    } else {
      differenceText = 'Today, ';
    }

    if (hoursDifference == 0) {
      differenceText += 'Same time';
    } else if (hoursDifference > 0) {
      differenceText += '+$hoursDifference HRS';
    } else {
      differenceText += '$hoursDifference HRS';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: Row(
              children: [
                // --- FIX: Conditionally show the delete button ---
                if (isEditMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      // The button calls the removeCity method from our state
                      onPressed: () => state.removeCity(timezone),
                      child: const Icon(CupertinoIcons.minus_circle_fill,
                          color: CupertinoColors.systemRed),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(differenceText,
                          style: const TextStyle(
                              color: CupertinoColors.inactiveGray,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(timezone.split('/').last.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
                Text(DateFormat('h:mm a').format(now),
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w300)),
              ],
            ),
          ),
          Container(
              height: 1, color: CupertinoColors.separator.withOpacity(0.5)),
        ],
      ),
    );
  }
}
