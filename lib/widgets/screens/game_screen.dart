import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../tactile/tactile.dart';
import '../game/game_header.dart';
import '../game/game_grid.dart';
import '../game/color_palette.dart';
import '../game/timer_bar.dart';
import '../effects/screen_shake.dart';
import '../overlays/feedback_overlay.dart';
import '../overlays/pause_overlay.dart';

/// Main game screen with timer, grid, palette and controls
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  /// "+points" that rises from the board after a solved level
  late final AnimationController _gainFloat = AnimationController(
    vsync: this,
    duration: TactileDurations.floatUp,
    value: 1,
  );

  /// Short bold cue in the middle of the board when a phase begins
  late final AnimationController _cue = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    value: 1,
  );
  String _cueKey = 'cue_memorize';
  bool _didInitialCue = false;

  final GlobalKey<ScreenShakeState> _shakeKey = GlobalKey<ScreenShakeState>();

  late final GameProvider _gameProvider;
  late GameState _lastGameState;
  int _lastPoints = 0;
  int _gain = 0;
  Widget? _cachedAdWidget;
  BannerAd? _cachedBannerAd;

  @override
  void initState() {
    super.initState();
    _gameProvider = context.read<GameProvider>();
    _lastGameState = _gameProvider.gameState;
    _lastPoints = _gameProvider.score.points;
    _gameProvider.addListener(_onGameChanged);

    // No background music during a round, it picks up again on the start screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().stopBackgroundMusic();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Entering the screen straight into the first preview
    if (!_didInitialCue) {
      _didInitialCue = true;
      if (_gameProvider.isPreview) _showCue('cue_memorize');
    }
  }

  void _showCue(String key) {
    _cueKey = key;
    _cue.forward(from: 0);
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_onGameChanged);
    _cue.dispose();
    _gainFloat.dispose();
    super.dispose();
  }

  /// Feedback on state transitions: success is a medium bump with the gain
  /// flying up, failure a heavy one with a screen shake
  void _onGameChanged() {
    final state = _gameProvider.gameState;
    final points = _gameProvider.score.points;

    if (state != _lastGameState) {
      if (state == GameState.levelUp) {
        HapticFeedback.mediumImpact();
        _gain = points - _lastPoints;
        if (_gain > 0 && !MediaQuery.of(context).disableAnimations) {
          _gainFloat.forward(from: 0);
        }
      } else if (state == GameState.showSolution) {
        HapticFeedback.heavyImpact();
        _shakeKey.currentState?.shake();
      } else if (state == GameState.preview &&
          _lastGameState != GameState.paused) {
        _showCue('cue_memorize');
      } else if (state == GameState.rebuild &&
          _lastGameState == GameState.preview) {
        _showCue('cue_rebuild');
      }
      _lastGameState = state;
    }
    _lastPoints = points;
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );

    final insets = MediaQuery.of(context).padding;
    final bannerVisible = context.select<AdsProvider, bool>(
      (a) => a.isGameBannerAdLoaded && a.gameBannerAd != null,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 600;
            final spacing = isSmallScreen ? 6.0 : 12.0;

            // Overlays cover the play area only, never the banner below it
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main game content
                      // Particles stop at the edge of the play area and
                      // never reach the banner lane
                      ClipRect(
                        child: ScreenShake(
                          key: _shakeKey,
                          child: Column(
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: GameHeader(isSmallScreen: isSmallScreen),
                              ),

                              SizedBox(height: spacing * 0.5),

                              // Timer progress bar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TimerBar(palette: palette),
                              ),

                              SizedBox(height: spacing * 0.5),

                              // Info row with label, timer, and buttons
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildInfoRow(
                                  context,
                                  gameProvider,
                                  palette,
                                  isSmallScreen,
                                ),
                              ),

                              SizedBox(height: spacing),

                              // Grid
                              Flexible(
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  clipBehavior: Clip.none,
                                  children: [
                                    GameGrid(isSmallScreen: isSmallScreen),
                                    _buildGainFloat(palette),
                                    Positioned.fill(child: _buildCue(palette)),
                                  ],
                                ),
                              ),

                              SizedBox(height: spacing),

                              // Controls area
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildControls(
                                  context,
                                  gameProvider,
                                  palette,
                                  isSmallScreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Overlays reach under the status bar, and down to the
                      // screen edge only while no banner sits there
                      if (gameProvider.isPaused)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: -insets.top,
                          bottom: bannerVisible ? 0 : -(insets.bottom + 12),
                          child: const PauseOverlay(),
                        ),
                      if (gameProvider.isGameOver)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: -insets.top,
                          bottom: bannerVisible ? 0 : -(insets.bottom + 12),
                          child: const FeedbackOverlay(),
                        ),
                    ],
                  ),
                ),

                // Ad Banner at the bottom, clearly separated from controls
                _buildAdBanner(context, palette, isSmallScreen),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdBanner(
    BuildContext context,
    TactilePalette palette,
    bool isSmallScreen,
  ) {
    final adsProvider = context.watch<AdsProvider>();

    if (!adsProvider.isGameBannerAdLoaded || adsProvider.gameBannerAd == null) {
      _cachedAdWidget = null;
      _cachedBannerAd = null;
      return SizedBox(height: isSmallScreen ? 6.0 : 12.0);
    }

    // Cache AdWidget to prevent "already in Widget tree" error
    if (_cachedBannerAd != adsProvider.gameBannerAd) {
      _cachedBannerAd = adsProvider.gameBannerAd;
      _cachedAdWidget = AdWidget(ad: adsProvider.gameBannerAd!);
    }

    // Dead zone plus divider keep palette taps away from the banner
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: isSmallScreen ? 20.0 : 28.0),
        Container(height: 2, color: palette.surface.lip),
        Container(
          width: double.infinity,
          height: 60,
          color: palette.backgroundDeep,
          alignment: Alignment.center,
          child: _cachedAdWidget!,
        ),
      ],
    );
  }

  Widget _buildCue(TactilePalette palette) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _cue,
        builder: (context, _) {
          final t = _cue.value;
          if (t >= 1) return const SizedBox.shrink();
          final reduceMotion = MediaQuery.of(context).disableAnimations;
          final isRebuild = _cueKey == 'cue_rebuild';
          final tone = isRebuild ? palette.primary : palette.cta;

          // Quick in, short hold, fade out while drifting up a little
          final fadeIn = (t / 0.12).clamp(0.0, 1.0);
          final fadeOut = t < 0.55 ? 1.0 : 1 - (t - 0.55) / 0.45;
          final pop = reduceMotion
              ? 1.0
              : TactileCurves.popScale.transform((t / 0.4).clamp(0.0, 1.0)) +
                    0.12 * Curves.easeIn.transform(t);

          return Center(
            child: Opacity(
              opacity: (fadeIn * fadeOut).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: pop,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _cueKey.tr().toUpperCase(),
                    style: TactileText(palette)
                        .number(64, color: tone.face)
                        .copyWith(
                          letterSpacing: 1,
                          shadows: [
                            Shadow(color: tone.lip, offset: const Offset(0, 6)),
                            Shadow(
                              color: palette.backgroundDeep.withValues(
                                alpha: 0.85,
                              ),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGainFloat(TactilePalette palette) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _gainFloat,
        builder: (context, _) {
          final t = _gainFloat.value;
          if (t >= 1 || _gain <= 0) return const SizedBox.shrink();
          final rise = Curves.easeOutCubic.transform(t);
          final fade = t < 0.65 ? 1.0 : 1 - (t - 0.65) / 0.35;
          final pop = TactileCurves.popScale.transform((t * 2.4).clamp(0, 1));

          return Transform.translate(
            offset: Offset(0, 70 - 90 * rise),
            child: Opacity(
              opacity: fade.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: pop,
                child: Text(
                  '+$_gain',
                  style: TactileText(palette)
                      .number(44, color: palette.cta.face)
                      .copyWith(
                        shadows: [
                          Shadow(
                            color: palette.cta.lip,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    GameProvider gameProvider,
    TactilePalette palette,
    bool isSmallScreen,
  ) {
    final text = TactileText(palette);
    final isPreview = gameProvider.isPreview;
    final isRebuild = gameProvider.isRebuild;
    final isPaused = gameProvider.isPaused;
    final isLevelUp = gameProvider.isLevelUp;
    final isShowSolution = gameProvider.isShowSolution;
    final patternSize = gameProvider.currentLevel.patternSize;

    return SizedBox(
      height: isSmallScreen ? 44.0 : 56.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Label and field count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The phase itself lives in the header badge
                if (isShowSolution) ...[
                  Text(
                    'solution'.tr().toUpperCase(),
                    maxLines: 1,
                    style: text.label.copyWith(
                      fontSize: isSmallScreen ? 11.0 : 13.0,
                      color: palette.danger.face,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 1.0 : 2.0),
                ],
                Row(
                  children: [
                    Text(
                      '${'fields'.tr().toUpperCase()}:',
                      style: text.label.copyWith(
                        fontSize: isSmallScreen ? 10.0 : 11.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      patternSize.toString(),
                      style: text.number(isSmallScreen ? 12.0 : 14.0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Center: Timer
          SizedBox(
            width: isSmallScreen ? 60.0 : 80.0,
            child: Center(
              child: ValueListenableBuilder<double>(
                valueListenable: gameProvider.timerListenable,
                builder: (context, timer, _) {
                  final timerColor = isPreview
                      ? palette.cta.face
                      : (isRebuild && timer < 2)
                      ? palette.danger.face
                      : palette.primary.face;
                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: text.number(
                      isSmallScreen ? 24.0 : 30.0,
                      color: timerColor,
                    ),
                    child: Text(isLevelUp ? ' ' : '${timer.ceil()}s'),
                  );
                },
              ),
            ),
          ),

          // Right: Pause button
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TactileIconButton(
                  icon: isPaused ? Icons.play_arrow : Icons.pause,
                  semanticLabel: isPaused ? 'continue_game'.tr() : 'pause'.tr(),
                  tone: palette.raised,
                  iconColor: palette.textPrimary,
                  size: isSmallScreen ? 44.0 : 48.0,
                  onTap: () => gameProvider.togglePause(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    GameProvider gameProvider,
    TactilePalette palette,
    bool isSmallScreen,
  ) {
    final isPreview = gameProvider.isPreview;
    final isRebuild = gameProvider.isRebuild;

    if (isRebuild) {
      return ColorPalette(isSmallScreen: isSmallScreen);
    }

    if (isPreview) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8.0 : 16.0,
            ),
            child: _buildSkipButton(gameProvider, palette, isSmallScreen),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSkipButton(
    GameProvider gameProvider,
    TactilePalette palette,
    bool isSmallScreen,
  ) {
    return TactileButton(
      tone: palette.cta,
      expand: true,
      softShadow: true,
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.0 : 14.0),
      onTap: () => gameProvider.skipPreview(),
      child: Text(
        'skip'.tr(),
        style: TactileText(
          palette,
        ).button.copyWith(fontSize: isSmallScreen ? 16.0 : 18.0),
      ),
    );
  }
}
