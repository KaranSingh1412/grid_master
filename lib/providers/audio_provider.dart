import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Sound pack types available
enum SoundPackType { defaultPack, zenPack, retroPack, fartPack }

/// Provider for managing game audio (music and sound effects)
class AudioProvider extends ChangeNotifier {
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  double _musicVolume = 1.0;
  double _soundVolume = 1.0;
  bool _isMusicPlaying = false;
  bool _pausedForAd = false;
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
      case 'fart_sound':
        return SoundPackType.fartPack;
      default:
        return SoundPackType.defaultPack;
    }
  }

  /// Get sound file path based on equipped sound pack
  String _getSoundPath(String soundName) {
    switch (_currentPack) {
      case SoundPackType.zenPack:
        return 'audio/zen/$soundName.mp3';
      case SoundPackType.retroPack:
        return 'audio/retro/$soundName.mp3';
      case SoundPackType.defaultPack:
        return 'audio/standard/$soundName.mp3';
      case SoundPackType.fartPack:
        return 'audio/fart/$soundName.mp3';
    }
  }

  /// Get music file path based on equipped sound pack
  String _getMusicPath() {
    switch (_currentPack) {
      case SoundPackType.zenPack:
        return 'audio/zen/background.mp3';
      case SoundPackType.retroPack:
        return 'audio/retro/background.mp3';
      case SoundPackType.defaultPack:
        return 'audio/standard/background.mp3';
      case SoundPackType.fartPack:
        return 'audio/standard/background.mp3';
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
        await _musicPlayer.play(AssetSource('audio/standard/background.mp3'));
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

  /// Silence the music while a full-screen ad plays
  Future<void> pauseForAd() async {
    if (!_isMusicPlaying || _pausedForAd) return;
    _pausedForAd = true;
    try {
      await _musicPlayer.pause();
    } catch (e) {
      debugPrint('Failed to pause background music: $e');
    }
  }

  /// Pick the music up again once the ad is closed
  Future<void> resumeAfterAd() async {
    if (!_pausedForAd) return;
    _pausedForAd = false;
    if (!_isMusicPlaying) return;
    try {
      await _musicPlayer.resume();
    } catch (e) {
      debugPrint('Failed to resume background music: $e');
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
        await player.play(AssetSource('audio/standard/place.mp3'));
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
      final soundPath = _getSoundPath('ui_tap');
      await _sfxPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Fallback to default sound
      try {
        await _sfxPlayer.play(AssetSource('audio/standard/ui_tap.mp3'));
      } catch (e2) {
        debugPrint('Failed to play mouse sound: $e2');
      }
    }
  }

  /// Play lose sound effect of the equipped sound pack (wrong / time up)
  Future<void> playLoseSound() async {
    if (!isSoundEnabled) return;

    try {
      final soundPath = _getSoundPath('lose');
      await _sfxPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Fallback to default sound
      try {
        await _sfxPlayer.play(AssetSource('audio/standard/lose.mp3'));
      } catch (e2) {
        debugPrint('Failed to play lose sound: $e2');
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
        await _sfxPlayer.play(AssetSource('audio/standard/win.mp3'));
      } catch (e2) {
        debugPrint('Failed to play win sound: $e2');
      }
    }
  }

  /// Play UI tap sound effect
  Future<void> playUiTapSound() async {
    if (!isSoundEnabled) return;

    try {
      final soundPath = _getSoundPath('ui_tap');
      await _sfxPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // Fallback to default sound
      try {
        await _sfxPlayer.play(AssetSource('audio/standard/ui_tap.mp3'));
      } catch (e2) {
        debugPrint('Failed to play UI tap sound: $e2');
      }
    }
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}
