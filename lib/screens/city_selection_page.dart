// lib/screens/city_selection_page.dart
// --- CORRECTED FILE ---

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
// import 'package:timezone/data/latest_all.dart' as tz; // FIX: Unused import
import 'package:timezone/timezone.dart' as tz;
import '../state/world_clock_state.dart';

class CitySelectionPage extends StatefulWidget {
  const CitySelectionPage({super.key});

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  late List<String> _allTimezones;
  List<String> _filteredTimezones = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // tz.initializeTimezones(); // FIX: This should not be here. It's initialized once in main.
    _allTimezones = tz.timeZoneDatabase.locations.keys.toList()..sort();
    _filteredTimezones = _allTimezones;
    _searchController.addListener(_filterTimezones);
  }

  void _filterTimezones() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTimezones = _allTimezones
          .where((tz) => tz.toLowerCase().replaceAll('_', ' ').contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Choose a City'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CupertinoSearchTextField(controller: _searchController),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTimezones.length,
              itemBuilder: (context, index) {
                final timezone = _filteredTimezones[index];
                return CupertinoListTile(
                  title: Text(timezone.replaceAll('_', ' ')),
                  onTap: () {
                    Provider.of<WorldClockState>(context, listen: false)
                        .addCity(timezone);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
