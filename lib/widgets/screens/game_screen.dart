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
import '../overlays/feedback_overlay.dart';
import '../overlays/pause_overlay.dart';

/// Main game screen with timer, grid, palette and controls
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerAnimController;
  late Animation<double> _timerAnimation;
  double _lastProgress = 1.0;
  bool _isInitialized = false;
  late final GameProvider _gameProvider;
  late GameState _lastGameState;
  Widget? _cachedAdWidget;
  BannerAd? _cachedBannerAd;

  @override
  void initState() {
    super.initState();
    _timerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _timerAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _timerAnimController, curve: Curves.linear),
    );

    _gameProvider = context.read<GameProvider>();
    _lastGameState = _gameProvider.gameState;
    _gameProvider.addListener(_onGameChanged);
    _gameProvider.timerListenable.addListener(_onTimerTick);

    // Play background music when entering game screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().playBackgroundMusic();
    });
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_onGameChanged);
    _gameProvider.timerListenable.removeListener(_onTimerTick);
    _timerAnimController.dispose();
    super.dispose();
  }

  void _onTimerTick() {
    _updateTimerAnimation(_gameProvider.timerProgress);
  }

  /// Haptics on state transitions: success is a medium bump, failure a heavy one
  void _onGameChanged() {
    final state = _gameProvider.gameState;
    if (state != _lastGameState) {
      if (state == GameState.levelUp) {
        HapticFeedback.mediumImpact();
      } else if (state == GameState.showSolution) {
        HapticFeedback.heavyImpact();
      }
      _lastGameState = state;
    }
    _updateTimerAnimation(_gameProvider.timerProgress);
  }

  void _updateTimerAnimation(double newProgress) {
    if (!_isInitialized) {
      _lastProgress = newProgress;
      _isInitialized = true;
      return;
    }

    if ((newProgress - _lastProgress).abs() > 0.001) {
      _timerAnimation = Tween<double>(begin: _lastProgress, end: newProgress)
          .animate(
            CurvedAnimation(parent: _timerAnimController, curve: Curves.linear),
          );
      _timerAnimController.forward(from: 0);
      _lastProgress = newProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
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
                    children: [
                      // Main game content
                      Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GameHeader(isSmallScreen: isSmallScreen),
                          ),

                          SizedBox(height: spacing * 0.5),

                          // Timer progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildTimerBar(gameProvider, palette),
                          ),

                          SizedBox(height: spacing * 0.5),

                          // Info row with label, timer, and buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            child: GameGrid(isSmallScreen: isSmallScreen),
                          ),

                          SizedBox(height: spacing),

                          // Controls area
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildControls(
                              context,
                              gameProvider,
                              palette,
                              isSmallScreen,
                            ),
                          ),
                        ],
                      ),

                      // Overlays
                      if (gameProvider.isPaused)
                        const Positioned.fill(child: PauseOverlay()),
                      if (gameProvider.isGameOver)
                        const Positioned.fill(child: FeedbackOverlay()),
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

  Widget _buildTimerBar(GameProvider gameProvider, TactilePalette palette) {
    final fill = gameProvider.isPreview ? palette.cta : palette.primary;

    return AnimatedBuilder(
      animation: _timerAnimation,
      builder: (context, child) {
        return TactileWell(
          color: palette.backgroundDeep,
          radius: TactileRadii.pill,
          padding: const EdgeInsets.all(3),
          child: SizedBox(
            height: 10,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _timerAnimation.value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TactileRadii.pill),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(fill.face, Colors.white, 0.2)!,
                      fill.face,
                      fill.lip,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

    // Determine label text
    String labelText;
    if (isShowSolution) {
      labelText = 'solution'.tr().toUpperCase();
    } else if (isPreview) {
      labelText = 'memorize_pattern'.tr().toUpperCase();
    } else {
      labelText = 'rebuild_pattern'.tr().toUpperCase();
    }

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
                Text(
                  labelText,
                  style: text.label.copyWith(
                    fontSize: isSmallScreen ? 10.0 : 12.0,
                    color: isShowSolution
                        ? palette.danger.face
                        : palette.textSecondary,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 1.0 : 2.0),
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
