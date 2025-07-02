// lib/services/audio_service.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'sound_service.dart'; // Import the new Sound class

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _crescendoTimer;

  /// Private helper method to handle playback from different sources.
  /// It now accepts a `Sound` object instead of just a String path.
  Future<void> _play(Sound sound, {double volume = 1.0}) async {
    // Stop any audio that is currently playing before starting a new one.
    await stop();
    await _audioPlayer.setVolume(volume);

    Source source;
    if (sound.isCustom) {
      // If the sound is custom, it's stored on the device.
      // We use DeviceFileSource to play it from its absolute path.
      source = DeviceFileSource(sound.path);
    } else {
      // If it's a default sound, it's part of the app's assets.
      // We use AssetSource to play it from the 'assets/sounds/' folder.
      source = AssetSource(sound.path);
    }

    // Set the release mode to loop for continuous playback until stopped.
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(source);
  }

  /// Plays a sound with a gradual volume increase (crescendo effect).
  Future<void> playCrescendo(Sound sound) async {
    // Start playback at a very low volume.
    await _play(sound, volume: 0.1);

    // Start a periodic timer that fires every 2 seconds to increase the volume.
    _crescendoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_audioPlayer.volume < 1.0) {
        final newVolume = _audioPlayer.volume + 0.1;
        // Ensure the volume doesn't exceed the maximum of 1.0.
        _audioPlayer.setVolume(newVolume > 1.0 ? 1.0 : newVolume);
      } else {
        // Once the volume is at max, cancel the timer.
        timer.cancel();
      }
    });
  }

  /// Plays a short preview of a sound (e.g., in the sound selection list).
  Future<void> playPreview(Sound sound) async {
    // Play the sound at full volume.
    await _play(sound);
    // Automatically stop the preview after 3 seconds.
    Future.delayed(const Duration(seconds: 3), () => stop());
  }

  /// Stops all audio playback and cancels any active crescendo timer.
  Future<void> stop() async {
    _crescendoTimer?.cancel();
    await _audioPlayer.stop();
  }

  /// Releases all resources used by the AudioPlayer.
  /// This should be called when the app state is disposed.
  void dispose() {
    _crescendoTimer?.cancel();
    _audioPlayer.dispose();
  }
}
