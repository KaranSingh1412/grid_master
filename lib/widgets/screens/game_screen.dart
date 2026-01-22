import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../constants/game_constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/ads_provider.dart';
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
  bool _hasPlayedGlassSound = false;
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

    // Play background music when entering game screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().playBackgroundMusic();
    });
  }

  @override
  void dispose() {
    _timerAnimController.dispose();
    super.dispose();
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

    // Play glass sound when showing solution (only once per game over)
    if (gameProvider.isShowSolution && !_hasPlayedGlassSound) {
      _hasPlayedGlassSound = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AudioProvider>().playGlassSound();
      });
    }

    // Reset flag when not in showSolution state
    if (!gameProvider.isShowSolution && !gameProvider.isGameOver) {
      _hasPlayedGlassSound = false;
    }

    // Update animation when progress changes
    final currentProgress = gameProvider.timerProgress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateTimerAnimation(currentProgress);
      }
    });

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final isSmallScreen = screenHeight < 600;
          final spacing = isSmallScreen ? 6.0 : 12.0;

          return Stack(
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
                    child: _buildTimerBar(gameProvider),
                  ),

                  SizedBox(height: spacing * 0.5),

                  // Info row with label, timer, and buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoRow(context, gameProvider, isSmallScreen),
                  ),

                  SizedBox(height: spacing),

                  // Grid
                  Flexible(child: GameGrid(isSmallScreen: isSmallScreen)),

                  SizedBox(height: spacing),

                  // Controls area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildControls(context, gameProvider, isSmallScreen),
                  ),

                  SizedBox(height: spacing),

                  // Ad Banner at the bottom
                  _buildAdBanner(context),
                ],
              ),

              // Overlays
              if (gameProvider.isPaused) const PauseOverlay(),
              if (gameProvider.isGameOver) const FeedbackOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdBanner(BuildContext context) {
    final adsProvider = context.watch<AdsProvider>();

    if (!adsProvider.isGameBannerAdLoaded || adsProvider.gameBannerAd == null) {
      _cachedAdWidget = null;
      _cachedBannerAd = null;
      return const SizedBox.shrink();
    }

    // Cache AdWidget to prevent "already in Widget tree" error
    if (_cachedBannerAd != adsProvider.gameBannerAd) {
      _cachedBannerAd = adsProvider.gameBannerAd;
      _cachedAdWidget = AdWidget(ad: adsProvider.gameBannerAd!);
    }

    return Container(
      width: double.infinity,
      height: 60,
      color: GameColors.slate950,
      alignment: Alignment.center,
      child: _cachedAdWidget!,
    );
  }

  Widget _buildTimerBar(GameProvider gameProvider) {
    final isPreview = gameProvider.isPreview;

    return AnimatedBuilder(
      animation: _timerAnimation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final animatedWidth =
                constraints.maxWidth * _timerAnimation.value.clamp(0.0, 1.0);
            return Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: GameColors.slate800.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: GameColors.slate700),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.linear,
                    width: animatedWidth,
                    decoration: BoxDecoration(
                      color: isPreview
                          ? GameColors.amber400
                          : GameColors.emerald400,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isPreview
                                      ? GameColors.amber400
                                      : GameColors.emerald400)
                                  .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    GameProvider gameProvider,
    bool isSmallScreen,
  ) {
    final isPreview = gameProvider.isPreview;
    final isRebuild = gameProvider.isRebuild;
    final isPaused = gameProvider.isPaused;
    final isLevelUp = gameProvider.isLevelUp;
    final isShowSolution = gameProvider.isShowSolution;
    final timer = gameProvider.timer;
    final patternSize = gameProvider.currentLevel.patternSize;

    // Timer color and animation
    final timerColor = isPreview
        ? GameColors.amber400
        : (isRebuild && timer < 2)
        ? GameColors.rose500
        : GameColors.emerald400;

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
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10.0 : 12.0,
                    fontWeight: FontWeight.w600,
                    color: isShowSolution
                        ? GameColors.rose500
                        : Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 1.0 : 2.0),
                Row(
                  children: [
                    Text(
                      '${'fields'.tr().toUpperCase()}:',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 8.0 : 10.0,
                        fontWeight: FontWeight.w700,
                        color: GameColors.slate400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      patternSize.toString(),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12.0 : 14.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSmallScreen ? 24.0 : 30.0,
                  fontWeight: FontWeight.w900,
                  color: timerColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                child: Text(isLevelUp ? ' ' : '${timer.ceil()}s'),
              ),
            ),
          ),

          // Right: Pause button
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconButton(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  () => gameProvider.togglePause(),
                  isSmallScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onTap, [
    bool isSmallScreen = false,
  ]) {
    final size = isSmallScreen ? 36.0 : 40.0;
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: GameColors.slate800,
          shape: BoxShape.circle,
          border: Border.all(color: GameColors.slate700),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: GameColors.slate400, size: iconSize),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    GameProvider gameProvider,
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
            child: _buildSkipButton(gameProvider, isSmallScreen),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSkipButton(GameProvider gameProvider, bool isSmallScreen) {
    return GestureDetector(
      onTap: () => gameProvider.skipPreview(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12.0 : 16.0),
        decoration: BoxDecoration(
          color: GameColors.amber400.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GameColors.amber400.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: GameColors.amber400.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'skip'.tr(),
            style: TextStyle(
              fontSize: isSmallScreen ? 14.0 : 16.0,
              fontWeight: FontWeight.w700,
              color: GameColors.amber400,
            ),
          ),
        ),
      ),
    );
  }
}
