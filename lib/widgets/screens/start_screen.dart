import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/game_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../effects/bump.dart';
import '../effects/count_up_text.dart';
import '../tactile/tactile.dart';

/// Start screen: wordmark, a 2x2 tile board with the play key, shop and bonus
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  /// One tile at a time gets pressed and pops back
  late final AnimationController _tilePress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// Slow breathing of the play key
  late final AnimationController _playPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  int _activeTileIndex = 0;
  Timer? _tileTimer;
  bool _motionStarted = false;

  @override
  void initState() {
    super.initState();

    // Start background music when entering start screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().playBackgroundMusic();
    });

    // One-time rating request once the player is back from enough rounds
    ReviewService.maybeRequestReview();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _tileTimer?.cancel();
      _tilePress.stop();
      _playPulse.stop();
      _motionStarted = false;
    } else if (!_motionStarted) {
      _motionStarted = true;
      _playPulse.repeat(reverse: true);
      _scheduleTile(const Duration(milliseconds: 600));
    }
  }

  void _scheduleTile(Duration delay) {
    _tileTimer?.cancel();
    _tileTimer = Timer(delay, () {
      if (!mounted) return;
      _tilePress.forward(from: 0).whenComplete(() {
        if (!mounted || !_motionStarted) return;
        final next = (_activeTileIndex + 1) % 4;
        setState(() => _activeTileIndex = next);
        // After a full round the board rests for a while
        _scheduleTile(
          next == 0
              ? const Duration(seconds: 4)
              : const Duration(milliseconds: 120),
        );
      });
    });
  }

  @override
  void dispose() {
    _tileTimer?.cancel();
    _tilePress.dispose();
    _playPulse.dispose();
    super.dispose();
  }

  void _openShop(BuildContext context) {
    context.push(AppRoutes.shop);
  }

  void _startClassicMode(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final creditProvider = context.read<CreditProvider>();
    creditProvider.resetThreshold();
    gameProvider.startGame();
    context.go(AppRoutes.game);
  }

  @override
  Widget build(BuildContext context) {
    final highScore = context.select<GameProvider, int>(
      (g) => g.score.highScore,
    );
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 667.0;

            final titleSpacing = isSmallScreen ? 20.0 : 36.0;
            final buttonSize = isSmallScreen ? 44.0 : 48.0;
            final coinSize = isSmallScreen ? 20.0 : 24.0;
            final titleFontSize = isSmallScreen ? 38.0 : 52.0;
            final subtitleFontSize = isSmallScreen ? 11.0 : 14.0;
            final boardSize = isSmallScreen ? 200.0 : 232.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                isSmallScreen ? 8 : 24,
                24,
                isSmallScreen ? 8 : 16,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCreditsDisplay(palette, coinSize: coinSize),
                      TactileIconButton(
                        icon: Icons.settings,
                        semanticLabel: 'settings'.tr(),
                        tone: palette.raised,
                        iconColor: palette.textPrimary,
                        size: buttonSize,
                        onTap: () {
                          context.read<AudioProvider>().playUiTapSound();
                          context.push(AppRoutes.settings);
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildTitle(
                    palette,
                    titleFontSize: titleFontSize,
                    subtitleFontSize: subtitleFontSize,
                    highScore: highScore,
                  ),
                  SizedBox(height: titleSpacing),
                  _buildBoard(palette, size: boardSize),
                  SizedBox(height: titleSpacing),
                  _buildSideKeys(context, palette, isSmallScreen),
                  const Spacer(),
                  // Quiet strip above the banner: nothing moves next to the ad
                  const SizedBox(height: 24),
                  _buildBannerAd(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCreditsDisplay(
    TactilePalette palette, {
    required double coinSize,
  }) {
    final creditProvider = context.watch<CreditProvider>();
    final fontSize = coinSize * 0.85;

    return Bump(
      trigger: creditProvider.credits,
      scale: 1.2,
      rotate: 0.05,
      alignment: Alignment.centerLeft,
      child: _buildCreditsPill(palette, creditProvider, coinSize, fontSize),
    );
  }

  Widget _buildCreditsPill(
    TactilePalette palette,
    CreditProvider creditProvider,
    double coinSize,
    double fontSize,
  ) {
    // The balance is a key too: tapping it opens the shop
    return TactileButton(
      tone: palette.surface,
      radius: TactileRadii.pill,
      depth: TactileDepth.small,
      padding: const EdgeInsets.fromLTRB(10, 6, 16, 6),
      semanticLabel: 'shop_title'.tr(),
      onTap: () {
        context.read<AudioProvider>().playUiTapSound();
        _openShop(context);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/img/coin.png', width: coinSize, height: coinSize),
          const SizedBox(width: 8),
          creditProvider.isLoaded
              ? CountUpText(
                  value: creditProvider.credits,
                  style: TactileText(palette).number(
                    fontSize,
                    color: palette.cta.face,
                    weight: FontWeight.w600,
                  ),
                )
              : SizedBox(
                  width: fontSize * 0.8,
                  height: fontSize * 0.8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.cta.face),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTitle(
    TactilePalette palette, {
    required double titleFontSize,
    required double subtitleFontSize,
    required int highScore,
  }) {
    final text = TactileText(palette);

    // Letters get the same lip as every other piece
    TextStyle extruded(Color face, Color lip) => text.wordmark.copyWith(
      fontSize: titleFontSize,
      color: face,
      shadows: [Shadow(color: lip, offset: Offset(0, titleFontSize * 0.085))],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'GRID',
                  style: extruded(
                    palette.textPrimary,
                    Color.lerp(palette.textPrimary, palette.background, 0.62)!,
                  ),
                ),
                TextSpan(
                  text: 'MASTER',
                  style: extruded(palette.primary.face, palette.primary.lip),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: titleFontSize * 0.22),
        Text(
          'app_subtitle'.tr().toUpperCase(),
          textAlign: TextAlign.center,
          style: text.label.copyWith(
            fontSize: subtitleFontSize,
            color: palette.textSecondary,
            letterSpacing: 2.4,
          ),
        ),
        if (highScore > 0) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'your_record'.tr().toUpperCase(),
                style: text.label.copyWith(fontSize: subtitleFontSize * 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                highScore.toString(),
                style: text.number(
                  subtitleFontSize * 1.4,
                  color: palette.accent,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBoard(TactilePalette palette, {required double size}) {
    // red, blue, orange, purple
    final tones = [
      palette.gameTones[0],
      palette.gameTones[1],
      palette.gameTones[5],
      palette.gameTones[4],
    ];
    const gap = 10.0;
    const pad = 12.0;

    void start() {
      context.read<AudioProvider>().playUiTapSound();
      _startClassicMode(context);
    }

    return GestureDetector(
      onTap: start,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: TactileWell(
                  color: palette.backgroundDeep,
                  radius: TactileRadii.xl + 4,
                  padding: const EdgeInsets.all(pad),
                  child: AnimatedBuilder(
                    animation: _tilePress,
                    builder: (context, _) {
                      return GridView.count(
                        padding: EdgeInsets.zero,
                        crossAxisCount: 2,
                        crossAxisSpacing: gap,
                        mainAxisSpacing: gap,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (int i = 0; i < 4; i++)
                            _buildBoardTile(tones[i], i == _activeTileIndex),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            _buildPlayKey(palette, size, start),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardTile(TactileTone tone, bool isActive) {
    double press = 0;
    double scale = 1;
    if (isActive && _tilePress.isAnimating) {
      final t = _tilePress.value;
      // Down for the first third, then the overshoot pop
      if (t < 0.3) {
        press = Curves.easeOut.transform(t / 0.3);
      } else {
        final p = (t - 0.3) / 0.7;
        press = 1 - Curves.easeOut.transform((p * 3).clamp(0.0, 1.0));
        scale = 0.94 + (TactileCurves.popScale.transform(p) - 0.6) * 0.15;
      }
    }
    return Transform.scale(
      scale: scale,
      child: TactileCell(tone: tone, radius: TactileRadii.lg, press: press),
    );
  }

  Widget _buildPlayKey(
    TactilePalette palette,
    double boardSize,
    VoidCallback onTap,
  ) {
    final keySize = boardSize * 0.4;
    return AnimatedBuilder(
      animation: _playPulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + 0.06 * Curves.easeInOut.transform(_playPulse.value),
          child: child,
        );
      },
      child: TactileButton(
        tone: palette.cta,
        onTap: onTap,
        width: keySize,
        height: keySize,
        radius: keySize / 2,
        semanticLabel: 'a11y_play'.tr(),
        softShadow: true,
        padding: EdgeInsets.zero,
        child: Icon(Icons.play_arrow_rounded, size: keySize * 0.62),
      ),
    );
  }

  Widget _buildSideKeys(
    BuildContext context,
    TactilePalette palette,
    bool isSmallScreen,
  ) {
    final hasRewardedAd = context.select<AdsProvider, bool>(
      (a) => a.isRewardedAdLoaded,
    );
    final canWatchAdToday = context.select<CreditProvider, bool>(
      (c) => c.canWatchAdToday,
    );
    final size = isSmallScreen ? 52.0 : 58.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // x2 bonus through a rewarded ad: the key says what you get (x2
          // points) and how (the video badge)
          _buildBonusKey(context, palette, size, hasRewardedAd),
          const SizedBox(width: 14),
          // Free coins once a day, also through a rewarded ad
          _buildCoinRewardKey(
            context,
            palette,
            size,
            hasRewardedAd && canWatchAdToday,
          ),
          const SizedBox(width: 14),
          TactileIconButton(
            icon: Icons.storefront,
            semanticLabel: 'shop_title'.tr(),
            tone: palette.gameTones[4],
            size: size,
            onTap: () {
              context.read<AudioProvider>().playUiTapSound();
              _openShop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBonusKey(
    BuildContext context,
    TactilePalette palette,
    double height,
    bool enabled,
  ) {
    final text = TactileText(palette);
    final tone = TactileColors.orange;
    final ink = enabled ? tone.ink : palette.textMuted;

    return _buildAdKey(
      palette,
      tone: tone,
      height: height,
      enabled: enabled,
      semanticLabel: 'a11y_bonus_ad'.tr(),
      onTap: () => _activateBonusWithAd(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('x2', style: text.number(height * 0.5, color: ink)),
          const SizedBox(width: 8),
          Text(
            'points'.tr().toUpperCase(),
            style: text.label.copyWith(
              fontSize: height * 0.24,
              color: ink,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinRewardKey(
    BuildContext context,
    TactilePalette palette,
    double height,
    bool enabled,
  ) {
    final text = TactileText(palette);
    final tone = palette.primary;

    return _buildAdKey(
      palette,
      tone: tone,
      height: height,
      enabled: enabled,
      semanticLabel: 'shop_free_credits'.tr(),
      onTap: () => _watchAdForCredits(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+$_adRewardCredits',
            style: text.number(
              height * 0.46,
              color: enabled ? tone.ink : palette.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Image.asset(
              'assets/img/coin.png',
              width: height * 0.44,
              height: height * 0.44,
            ),
          ),
        ],
      ),
    );
  }

  /// Key for something a rewarded ad pays for. The video badge in the corner
  /// says how you get it.
  Widget _buildAdKey(
    TactilePalette palette, {
    required TactileTone tone,
    required double height,
    required bool enabled,
    required String semanticLabel,
    required VoidCallback onTap,
    required Widget child,
  }) {
    final muted = palette.raised.muted(palette.background);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TactileButton(
          tone: tone,
          disabledTone: muted,
          semanticLabel: semanticLabel,
          height: height,
          radius: height * 0.34,
          depth: TactileDepth.small,
          padding: const EdgeInsets.fromLTRB(16, 0, 18, 0),
          onTap: enabled ? onTap : null,
          child: child,
        ),
        Positioned(
          top: -9,
          right: -9,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: enabled ? palette.cta.face : muted.face,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.background, width: 2),
              ),
              child: Icon(
                Icons.smart_display_rounded,
                size: 16,
                color: enabled ? palette.cta.ink : palette.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const int _adRewardCredits = 5;

  /// Once a day: watch a rewarded ad, get coins. The coin pill counts up.
  void _watchAdForCredits(BuildContext context) {
    final creditProvider = context.read<CreditProvider>();
    if (!creditProvider.canWatchAdToday) return;

    context.read<AdsProvider>().showRewardedAd(
      onRewarded: () {
        creditProvider.addCredits(_adRewardCredits);
        creditProvider.recordAdWatch();
      },
    );
  }

  void _activateBonusWithAd(BuildContext context) {
    final adsProvider = context.read<AdsProvider>();
    final gameProvider = context.read<GameProvider>();
    final creditProvider = context.read<CreditProvider>();
    final audioProvider = context.read<AudioProvider>();

    adsProvider.showRewardedAd(
      onRewarded: () {
        audioProvider.playMouseSound();
        creditProvider.resetThreshold();
        gameProvider.activateDoubleBonus();
        gameProvider.startGame();
        context.go(AppRoutes.game);
      },
    );
  }

  Widget _buildBannerAd() {
    final adsProvider = context.watch<AdsProvider>();

    if (!adsProvider.isBannerAdLoaded || adsProvider.bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return Container(
      alignment: Alignment.center,
      width: adsProvider.bannerAd!.size.width.toDouble(),
      height: adsProvider.bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: adsProvider.bannerAd!),
    );
  }
}
