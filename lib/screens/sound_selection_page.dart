// lib/screens/sound_selection_page.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/sound_service.dart';
import '../widgets/custom_list_tile.dart';

class SoundSelectionPage extends StatelessWidget {
  final String currentSoundPath;
  const SoundSelectionPage({super.key, required this.currentSoundPath});

  @override
  Widget build(BuildContext context) {
    // By using a Consumer, this whole build method will re-run automatically
    // whenever notifyListeners() is called in SoundService.
    return Consumer<SoundService>(
      builder: (context, soundService, child) {
        final audioService = Provider.of<AudioService>(context, listen: false);
        final allSounds = soundService.allSounds;

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Sound'),
            previousPageTitle: 'Back', // Improves navigation feel
          ),
          child: SafeArea(
            child: ListView.separated(
              itemCount: allSounds.length + 1, // +1 for the Import button
              separatorBuilder: (context, index) => Container(
                height: 1,
                color: CupertinoColors.separator.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                // The first item in the list is always the "Import" button.
                if (index == 0) {
                  return CustomCupertinoListTile(
                    title: const Text('Import a Sound',
                        style: TextStyle(color: CupertinoColors.systemBlue)),
                    leading: const Icon(CupertinoIcons.add,
                        color: CupertinoColors.systemBlue),
                    onTap: () async {
                      await soundService.importSound();
                      // No need for setState() because the Consumer handles the rebuild.
                    },
                  );
                }

                // Adjust index to account for the import button at the top.
                final sound = allSounds[index - 1];
                final isSelected = sound.path == currentSoundPath;

                Widget? trailing;
                if (isSelected) {
                  trailing = const Icon(CupertinoIcons.check_mark,
                      color: CupertinoColors.systemBlue);
                } else if (sound.isCustom) {
                  // Only show a delete button for custom sounds.
                  trailing = CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.minus_circle_fill,
                        color: CupertinoColors.systemRed),
                    onPressed: () async {
                      await soundService.deleteCustomSound(sound);
                    },
                  );
                }

                return CustomCupertinoListTile(
                  title: Text(sound.name),
                  trailing: trailing,
                  onTap: () {
                    audioService.playPreview(sound);
                    // Pop the page and return the selected Sound object.
                    Navigator.pop(context, sound);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
