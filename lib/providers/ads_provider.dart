import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Provider for managing AdMob advertisements
class AdsProvider extends ChangeNotifier {
  // Test Ad Unit IDs (used in debug mode)
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIOS = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIOS = 'ca-app-pub-3940256099942544/1712485313';

  // Ad Unit IDs - uses test IDs in debug mode, production IDs from .env in release
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? _testBannerAndroid
          : (dotenv.env['ADMOB_BANNER_ANDROID'] ?? _testBannerAndroid);
    } else if (Platform.isIOS) {
      return kDebugMode
          ? _testBannerIOS
          : (dotenv.env['ADMOB_BANNER_IOS'] ?? _testBannerIOS);
    }
    return '';
  }

  static String get gameBannerAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? _testBannerAndroid
          : (dotenv.env['ADMOB_BANNER_GAME_ANDROID'] ?? _testBannerAndroid);
    } else if (Platform.isIOS) {
      return kDebugMode
          ? _testBannerIOS
          : (dotenv.env['ADMOB_BANNER_GAME_IOS'] ?? _testBannerIOS);
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? _testInterstitialAndroid
          : (dotenv.env['ADMOB_INTERSTITIAL_ANDROID'] ??
                _testInterstitialAndroid);
    } else if (Platform.isIOS) {
      return kDebugMode
          ? _testInterstitialIOS
          : (dotenv.env['ADMOB_INTERSTITIAL_IOS'] ?? _testInterstitialIOS);
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? _testRewardedAndroid
          : (dotenv.env['ADMOB_REWARDED_ANDROID'] ?? _testRewardedAndroid);
    } else if (Platform.isIOS) {
      return kDebugMode
          ? _testRewardedIOS
          : (dotenv.env['ADMOB_REWARDED_IOS'] ?? _testRewardedIOS);
    }
    return '';
  }

  BannerAd? _bannerAd;
  BannerAd? _gameBannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerAdLoaded = false;
  bool _isGameBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isAdFree = false;

  /// Hooks around interstitial and rewarded ads, used to pause the music
  VoidCallback? onFullScreenAdOpened;
  VoidCallback? onFullScreenAdClosed;

  int _lossCount = 0;

  bool get isBannerAdLoaded => _isBannerAdLoaded && !_isAdFree;
  bool get isGameBannerAdLoaded => _isGameBannerAdLoaded && !_isAdFree;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded && !_isAdFree;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get isAdFree => _isAdFree;
  BannerAd? get bannerAd => _isAdFree ? null : _bannerAd;
  BannerAd? get gameBannerAd => _isAdFree ? null : _gameBannerAd;

  /// Initialize the ads SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    if (!_isAdFree) {
      loadBannerAd();
      loadGameBannerAd();
      loadInterstitialAd();
    }
    loadRewardedAd();
  }

  /// Set ad-free status (from purchases)
  void setAdFree(bool value) {
    if (_isAdFree != value) {
      _isAdFree = value;
      if (_isAdFree) {
        // Dispose banner and interstitial ads if now ad-free
        _bannerAd?.dispose();
        _bannerAd = null;
        _isBannerAdLoaded = false;
        _gameBannerAd?.dispose();
        _gameBannerAd = null;
        _isGameBannerAdLoaded = false;
        _interstitialAd?.dispose();
        _interstitialAd = null;
        _isInterstitialAdLoaded = false;
      }
      notifyListeners();
    }
  }

  /// Load a banner ad
  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _isBannerAdLoaded = false;
          notifyListeners();
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), loadBannerAd);
        },
      ),
    );
    _bannerAd!.load();
  }

  /// Load a game banner ad (separate instance for game screen)
  void loadGameBannerAd() {
    _gameBannerAd = BannerAd(
      adUnitId: gameBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isGameBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Game banner ad failed to load: $error');
          ad.dispose();
          _isGameBannerAdLoaded = false;
          notifyListeners();
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), loadGameBannerAd);
        },
      ),
    );
    _gameBannerAd!.load();
  }

  /// Load an interstitial ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          notifyListeners();

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _isInterstitialAdLoaded = false;
                  loadInterstitialAd();
                  onFullScreenAdClosed?.call();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _isInterstitialAdLoaded = false;
                  loadInterstitialAd();
                  onFullScreenAdClosed?.call();
                },
              );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialAdLoaded = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
        },
      ),
    );
  }

  /// Load a rewarded ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _isRewardedAdLoaded = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), loadRewardedAd);
        },
      ),
    );
  }

  /// Record a loss and potentially show interstitial
  void recordLoss() {
    if (_isAdFree) return;
    _lossCount++;
    if (_lossCount >= 3 && _isInterstitialAdLoaded) {
      showInterstitialAd();
      _lossCount = 0;
    }
  }

  /// Show interstitial ad
  void showInterstitialAd() {
    if (_isAdFree) return;
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      onFullScreenAdOpened?.call();
      _interstitialAd!.show();
      _isInterstitialAdLoaded = false;
      notifyListeners();
    }
  }

  /// Show rewarded ad and call callback on reward
  void showRewardedAd({required Function onRewarded}) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      bool hasRewarded = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
          notifyListeners();
          onFullScreenAdClosed?.call();
          // Call reward callback after ad is dismissed if reward was earned
          if (hasRewarded) {
            onRewarded();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
          notifyListeners();
          onFullScreenAdClosed?.call();
        },
      );

      onFullScreenAdOpened?.call();
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          hasRewarded = true;
        },
      );
      _isRewardedAdLoaded = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
