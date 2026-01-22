import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Sound pack types available
enum SoundPackType { defaultPack, zenPack, retroPack }

/// Provider for managing game audio (music and sound effects)
class AudioProvider extends ChangeNotifier {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  double _musicVolume = 1.0;
  double _soundVolume = 1.0;
  bool _isMusicPlaying = false;
  String _equippedSoundPackId = 'default_sound';

  bool get isMusicPlaying => _isMusicPlaying;
  bool get isSoundEnabled => _soundVolume > 0.0;
  String get equippedSoundPackId => _equippedSoundPackId;

  /// Set the equipped sound pack
  void setEquippedSoundPack(String soundPackId) {
    _equippedSoundPackId = soundPackId;
    notifyListeners();
  }

  /// Get the sound pack type from the ID
  SoundPackType get _currentPack {
    switch (_equippedSoundPackId) {
      case 'zen_sound':
        return SoundPackType.zenPack;
      case 'retro_sound':
        return SoundPackType.retroPack;
      default:
        return SoundPackType.defaultPack;
    }
  }

  /// Get sound file path based on equipped sound pack
  String _getSoundPath(String soundName) {
    switch (_currentPack) {
      case SoundPackType.zenPack:
        return 'audio/zen_$soundName.mp3';
      case SoundPackType.retroPack:
        return 'audio/retro_$soundName.mp3';
      case SoundPackType.defaultPack:
        return 'audio/$soundName.mp3';
    }
  }

  /// Get music file path based on equipped sound pack
  String _getMusicPath() {
    switch (_currentPack) {
      case SoundPackType.zenPack:
        return 'audio/zen_background.mp3';
      case SoundPackType.retroPack:
        return 'audio/retro_background.mp3';
      case SoundPackType.defaultPack:
        return 'audio/background.mp3';
    }
  }

  /// Initialize audio settings
  void initialize({
    required bool musicEnabled,
    required bool soundEnabled,
    double musicVolume = 1.0,
    double soundVolume = 1.0,
    String? soundPackId,
  }) {
    _musicVolume = musicVolume;
    _soundVolume = soundVolume;
    if (soundPackId != null) {
      _equippedSoundPackId = soundPackId;
    }
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.setVolume(_musicVolume);
    _sfxPlayer.setVolume(_soundVolume);
  }

  /// Set music volume (0.0 to 1.0)
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _musicPlayer.setVolume(_musicVolume);
    notifyListeners();
  }

  /// Set sound volume (0.0 to 1.0)
  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
    _sfxPlayer.setVolume(_soundVolume);
    notifyListeners();
  }

  /// Play background music (loops)
  Future<void> playBackgroundMusic() async {
    if (_isMusicPlaying) return;

    try {
      final musicPath = _getMusicPath();
      await _musicPlayer.play(AssetSource(musicPath));
      _isMusicPlaying = true;
      notifyListeners();
    } catch (e) {
      // Fallback to default background music if pack music not found
      try {
        await _musicPlayer.play(AssetSource('audio/background.mp3'));
        _isMusicPlaying = true;
        notifyListeners();
      } catch (e2) {
        debugPrint('Failed to play background music: $e2');
      }
    }
  }

  /// Restart background music with new sound pack
  Future<void> restartBackgroundMusic() async {
    await stopBackgroundMusic();
    await playBackgroundMusic();
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      _isMusicPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to stop background music: $e');
    }
  }

  /// Play place sound effect
  Future<void> playPlaceSound() async {
    if (!isSoundEnabled) return;

    try {
      // Create a new player for each place sound so they can overlap
      final player = AudioPlayer();
      final soundPath = _getSoundPath('place');
      await player.play(AssetSource(soundPath));
      // Dispose player after sound finishes
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      // Fallback to default sound
      try {
        final player = AudioPlayer();
        await player.play(AssetSource('audio/place.mp3'));
        player.onPlayerComplete.listen((_) {
          player.dispose();
        });
      } catch (e2) {
        debugPrint('Failed to play place sound: $e2');
      }
    }
  }

  /// Play mouse click sound effect
  Future<void> playMouseSound() async {
    if (!isSoundEnabled) return;

    try {
      await _sfxPlayer.play(AssetSource('audio/mouse.mp3'));
    } catch (e) {
      debugPrint('Failed to play mouse sound: $e');
    }
  }

  /// Play glass break sound effect (game over)
  Future<void> playGlassSound() async {
    // Don't play if sound volume is 0
    if (_soundVolume <= 0.0) return;

    try {
      final soundPath = _getSoundPath('glass');
      await _sfxPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Fallback to default sound
      try {
        await _sfxPlayer.play(AssetSource('audio/glass.mp3'));
      } catch (e2) {
        debugPrint('Failed to play glass sound: $e2');
      }
    }
  }

  /// Play win sound effect (level completed)
  Future<void> playWinSound() async {
    if (!isSoundEnabled) return;

    try {
      final soundPath = _getSoundPath('win');
      await _sfxPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Fallback to default sound
      try {
        await _sfxPlayer.play(AssetSource('audio/win.mp3'));
      } catch (e2) {
        debugPrint('Failed to play win sound: $e2');
      }
    }
  }

  /// Play UI tap sound effect
  Future<void> playUiTapSound() async {
    if (!isSoundEnabled) return;

    try {
      await _sfxPlayer.play(AssetSource('audio/ui_tap.mp3'));
    } catch (e) {
      debugPrint('Failed to play UI tap sound: $e');
    }
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}
