// lib/services/sound_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Represents a single sound, holding its user-friendly name, its path,
/// and a flag indicating if it's a custom user import.
class Sound {
  final String name;
  final String
      path; // Can be an asset path (e.g., 'sounds/radar.mp3') or a file path.
  final bool isCustom;

  Sound({required this.name, required this.path, this.isCustom = false});
}

/// Manages the collection of default and user-imported sounds.
/// Extends ChangeNotifier to notify the UI when the list of sounds changes.
class SoundService extends ChangeNotifier {
  // A hardcoded list of sounds bundled with the app.
  final List<Sound> _defaultSounds = [
    Sound(name: 'Radar', path: 'sounds/radar.mp3'),
    Sound(name: 'Crystals', path: 'sounds/crystals.mp3'),
    Sound(name: 'Chimes', path: 'sounds/chimes.mp3'),
  ];

  List<Sound> _customSounds = [];

  /// Exposes a combined, read-only list of default and custom sounds to the app.
  List<Sound> get allSounds => [..._defaultSounds, ..._customSounds];

  /// Scans the app's documents directory for any saved custom sounds.
  /// This should be called once at app startup.
  Future<void> loadCustomSounds() async {
    final appDocsDir = await getApplicationDocumentsDirectory();
    final soundsDir = Directory(p.join(appDocsDir.path, 'sounds'));

    if (!await soundsDir.exists()) {
      _customSounds = [];
      notifyListeners(); // Notify even if the directory doesn't exist (e.g., first run)
      return;
    }

    final files = await soundsDir.list().toList();
    _customSounds = files
        .where((file) =>
            file is File &&
            (file.path.endsWith('.mp3') || file.path.endsWith('.wav')))
        .map((file) {
      final fileName = p.basenameWithoutExtension(file.path);
      return Sound(name: fileName, path: file.path, isCustom: true);
    }).toList();

    // Notify any listening widgets that the list of sounds has changed.
    notifyListeners();
  }

  /// Opens the system file picker to allow the user to select an audio file.
  /// The selected file is then copied into the app's private directory.
  Future<void> importSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);

      final appDocsDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory(p.join(appDocsDir.path, 'sounds'));

      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }

      final fileName = p.basename(sourceFile.path);
      final destPath = p.join(soundsDir.path, fileName);
      await sourceFile.copy(destPath);

      // After copying, reload the list of custom sounds to update the UI.
      await loadCustomSounds();
    }
  }

  /// Deletes a custom sound file from the app's storage.
  Future<void> deleteCustomSound(Sound sound) async {
    if (!sound.isCustom) return; // Protect default sounds from being deleted.

    final file = File(sound.path);
    if (await file.exists()) {
      await file.delete();
    }

    // After deleting, reload the list to update the UI.
    await loadCustomSounds();
  }
}
