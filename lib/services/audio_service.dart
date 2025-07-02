import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _crescendoTimer;

  Future<void> playCrescendo(String soundAsset) async {
    // Stop any currently playing audio first
    await stop();

    // Set initial volume low
    await _audioPlayer.setVolume(0.1);
    await _audioPlayer.play(AssetSource(soundAsset));

    // Start a timer to gradually increase the volume
    _crescendoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_audioPlayer.volume < 1.0) {
        final newVolume = _audioPlayer.volume + 0.1;
        _audioPlayer.setVolume(newVolume > 1.0 ? 1.0 : newVolume);
      } else {
        // Volume is at max, stop the timer
        timer.cancel();
      }
    });
  }

  Future<void> playPreview(String soundAsset) async {
    await _audioPlayer.play(AssetSource(soundAsset));
    // Stop the preview after a few seconds
    Future.delayed(const Duration(seconds: 3), () => stop());
  }

  Future<void> stop() async {
    _crescendoTimer?.cancel();
    await _audioPlayer.stop();
  }

  void dispose() {
    _crescendoTimer?.cancel();
    _audioPlayer.dispose();
  }
}
