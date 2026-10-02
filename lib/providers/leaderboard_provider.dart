import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';

/// High score leaderboard through Google Play Games (Android) and
/// Game Center (iOS). The leaderboard ids come from .env:
/// LEADERBOARD_ID_ANDROID and LEADERBOARD_ID_IOS.
class LeaderboardProvider extends ChangeNotifier {
  bool _isSignedIn = false;
  bool _isSigningIn = false;

  bool get isSignedIn => _isSignedIn;

  String get _androidId => _env('LEADERBOARD_ID_ANDROID');
  String get _iosId => _env('LEADERBOARD_ID_IOS');

  static String _env(String key) =>
      dotenv.isInitialized ? dotenv.env[key] ?? '' : '';

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Whether a leaderboard is configured for this platform
  bool get isAvailable {
    if (!_isMobile) return false;
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidId.isNotEmpty
        : _iosId.isNotEmpty;
  }

  /// Signs in to the platform's game service; silent when the player is
  /// already signed in on the device
  Future<bool> signIn() async {
    if (!isAvailable) return false;
    if (_isSignedIn) return true;
    if (_isSigningIn) return false;
    _isSigningIn = true;
    try {
      await GamesServices.signIn();
      _isSignedIn = await GamesServices.isSignedIn;
    } catch (e) {
      debugPrint('Game services sign in failed: $e');
      _isSignedIn = false;
    }
    _isSigningIn = false;
    notifyListeners();
    return _isSignedIn;
  }

  /// Sends the score of a finished run. The services keep the best one.
  Future<void> submitScore(int score) async {
    if (score <= 0 || !isAvailable || !_isSignedIn) return;
    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: _androidId,
          iOSLeaderboardID: _iosId,
          value: score,
        ),
      );
    } catch (e) {
      debugPrint('Submitting score failed: $e');
    }
  }

  /// Opens the platform's own leaderboard screen
  Future<bool> show() async {
    if (!await signIn()) return false;
    try {
      await GamesServices.showLeaderboards(
        androidLeaderboardID: _androidId,
        iOSLeaderboardID: _iosId,
      );
      return true;
    } catch (e) {
      debugPrint('Showing leaderboard failed: $e');
      return false;
    }
  }
}
