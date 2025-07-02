import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../widgets/custom_list_tile.dart';

class SoundSelectionPage extends StatelessWidget {
  const SoundSelectionPage({super.key});

  // Define your bundled sounds here
  final List<String> soundAssets = const [
    'sounds/radar.mp3',
    'sounds/crystals.mp3',
    'sounds/chimes.mp3',
  ];

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioService>(context, listen: false);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sound'),
      ),
      child: SafeArea(
        child: ListView.separated(
          itemCount: soundAssets.length,
          separatorBuilder: (context, index) => Container(
            height: 1,
            color: CupertinoColors.separator.withOpacity(0.2),
          ),
          itemBuilder: (context, index) {
            final sound = soundAssets[index];
            final soundName = sound.split('/').last.split('.').first;

            return CustomCupertinoListTile(
              title: Text(soundName.replaceFirst(
                  soundName[0], soundName[0].toUpperCase())),
              onTap: () {
                // Play a preview
                audioService.playPreview(sound);
                // Select the sound and pop the screen
                Navigator.pop(context, sound);
              },
            );
          },
        ),
      ),
    );
  }
}
