import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/game_constants.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/audio_provider.dart';
import '../dialogs/settings_dialog.dart';
import 'shop_screen.dart';
import 'mode_selection_screen.dart';

/// Start screen matching the React implementation
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _gridTileController;
  late AnimationController _playButtonController;
  int _activeTileIndex = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    // Grid tile pop animation - cycles through tiles
    _gridTileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _startGridTileAnimation();

    // Play button pulse animation
    _playButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    // Start background music when entering start screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().playBackgroundMusic();
    });
  }

  void _startGridTileAnimation() async {
    // Start the glow animation
    _glowController.repeat();

    _gridTileController.forward(from: 0).then((_) {
      if (mounted) {
        final nextIndex = (_activeTileIndex + 1) % 4;
        setState(() {
          _activeTileIndex = nextIndex;
        });

        // If we completed a full cycle (back to tile 0), pause for 2 seconds
        if (nextIndex == 0) {
          // Stop glow during pause
          _glowController.stop();
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) _startGridTileAnimation();
          });
        } else {
          _startGridTileAnimation();
        }
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _gridTileController.dispose();
    _playButtonController.dispose();
    super.dispose();
  }

  void _openShop(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ShopScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        barrierDismissible: false,
      ),
    );
  }

  void _startClassicMode(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final creditProvider = context.read<CreditProvider>();

    gameProvider.setGameMode(GameMode.classic);
    creditProvider.resetThreshold();
    gameProvider.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final highScore = gameProvider.score.highScore;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final isSmallScreen = screenHeight < 667.0;

          // Responsive sizes
          final titleSpacing = isSmallScreen ? 16.0 : 32.0;
          final gridSpacing = isSmallScreen ? 16.0 : 32.0;

          final buttonSize = isSmallScreen ? 40.0 : 48.0;
          final coinSize = isSmallScreen ? 20.0 : 24.0;
          final titleFontSize = isSmallScreen ? 32.0 : 48.0;
          final subtitleFontSize = isSmallScreen ? 10.0 : 14.0;
          final gridSize = isSmallScreen ? 200.0 : 220.0;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isSmallScreen ? 8 : 24,
            ),
            child: Column(
              children: [
                // Top row with credits and settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Credits display
                    _buildCreditsDisplay(context, coinSize: coinSize),
                    // Settings button
                    _buildSettingsButton(context, size: buttonSize),
                  ],
                ),

                // Spacer to center the middle content
                const Spacer(),

                // Centered content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title with rotating glow
                    _buildTitle(
                      titleFontSize: titleFontSize,
                      subtitleFontSize: subtitleFontSize,
                      highScore: highScore,
                    ),

                    SizedBox(height: titleSpacing),

                    // Decorative 2x2 grid
                    _buildDecorativeGrid(size: gridSize),

                    SizedBox(height: gridSpacing),

                    // Start button and high score
                    _buildStartSection(context, isSmallScreen: isSmallScreen),
                  ],
                ),

                // Spacer to push ad banner to the bottom
                const Spacer(),

                // Banner Ad
                _buildBannerAd(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, {required double size}) {
    return GestureDetector(
      onTap: () {
        context.read<AudioProvider>().playUiTapSound();
        _showSettings(context);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: GameColors.slate800.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: GameColors.slate700),
        ),
        child: Icon(
          Icons.settings,
          color: GameColors.slate400,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildCreditsDisplay(
    BuildContext context, {
    required double coinSize,
  }) {
    final creditProvider = context.watch<CreditProvider>();
    final credits = creditProvider.credits;
    final isLoaded = creditProvider.isLoaded;

    final fontSize = coinSize * 0.833; // Proportional to coin size

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GameColors.slate800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameColors.amber400.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/img/coin.png', width: coinSize, height: coinSize),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: isLoaded
                ? Text(
                    credits.toString(),
                    style: GoogleFonts.fredoka(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: GameColors.amber400,
                      shadows: [
                        Shadow(
                          color: GameColors.amber400.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: fontSize * 0.8,
                    height: fontSize * 0.8,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        GameColors.amber400,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopButton(BuildContext context, {required double size}) {
    return GestureDetector(
      onTap: () {
        context.read<AudioProvider>().playUiTapSound();
        _openShop(context);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: GameColors.slate800.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: GameColors.slate700),
        ),
        child: Icon(
          Icons.storefront,
          color: GameColors.slate400,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildTitle({
    required double titleFontSize,
    required double subtitleFontSize,
    required int highScore,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title with glow effect
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.white],
          ).createShader(bounds),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  fontFamily: 'Outfit',
                ),
                children: [
                  TextSpan(
                    text: 'GRID',
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: -5,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                  TextSpan(
                    text: 'MASTER',
                    style: TextStyle(
                      color: GameColors.emerald400,
                      letterSpacing: -5,
                      shadows: [
                        Shadow(
                          color: GameColors.emerald400.withValues(alpha: 0.6),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: GameColors.emerald400.withValues(alpha: 0.4),
                          blurRadius: 40,
                        ),
                        Shadow(
                          color: GameColors.emerald400.withValues(alpha: 0.2),
                          blurRadius: 60,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
          'app_subtitle'.tr().toUpperCase(),
          style: TextStyle(
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w500,
            color: GameColors.slate400,
            letterSpacing: 3,
          ),
        ),
        if (highScore > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'your_record'.tr().toUpperCase(),
                style: TextStyle(
                  fontSize: subtitleFontSize * 0.85,
                  fontWeight: FontWeight.w600,
                  color: GameColors.slate500,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                highScore.toString(),
                style: TextStyle(
                  fontSize: subtitleFontSize * 1.2,
                  fontWeight: FontWeight.w900,
                  color: GameColors.emerald400,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDecorativeGrid({required double size}) {
    return GestureDetector(
      onTap: () {
        context.read<AudioProvider>().playUiTapSound();
        _startClassicMode(context);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle glow behind grid
            Container(
              width: size * 0.91, // 200/220
              height: size * 0.91,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.18), // 40/220
                boxShadow: [
                  BoxShadow(
                    color: GameColors.blue.withValues(alpha: 0.15),
                    blurRadius: size * 0.27, // 60/220
                    spreadRadius: size * 0.045, // 10/220
                  ),
                  BoxShadow(
                    color: GameColors.purple.withValues(alpha: 0.1),
                    blurRadius: size * 0.36, // 80/220
                    spreadRadius: size * 0.09, // 20/220
                  ),
                ],
              ),
            ),
            // The fancy 2x2 grid
            _build3DGrid(),
            // Animated Play Button overlay
            _buildPlayButton(size),
          ],
        ),
      ),
    );
  }

  Widget _build3DGrid() {
    // Define tile colors and positions
    final tiles = [
      {
        'top': GameColors.red,
        'bottom': const Color(0xFFBE1E4E),
        'row': 0,
        'col': 0,
      },
      {
        'top': GameColors.blue,
        'bottom': const Color(0xFF0284C7),
        'row': 0,
        'col': 1,
      },
      {
        'top': GameColors.orange,
        'bottom': const Color(0xFFEA580C),
        'row': 1,
        'col': 0,
      },
      {
        'top': GameColors.purple,
        'bottom': const Color(0xFF7C3AED),
        'row': 1,
        'col': 1,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - 10) / 2;
        final cellHeight = (constraints.maxHeight - 10) / 2;

        // Build tiles with proper z-ordering (active tile on top)
        final orderedTiles = <int>[];
        for (int i = 0; i < 4; i++) {
          if (i != _activeTileIndex) orderedTiles.add(i);
        }
        orderedTiles.add(_activeTileIndex); // Active tile last (on top)

        return Stack(
          clipBehavior: Clip.none,
          children: orderedTiles.map((index) {
            final tile = tiles[index];
            final row = tile['row'] as int;
            final col = tile['col'] as int;
            final isActive = index == _activeTileIndex;

            final left = col * (cellSize + 10);
            final top = row * (cellHeight + 10);

            return AnimatedBuilder(
              animation: _gridTileController,
              builder: (context, child) {
                double scale = 1.0;
                double elevation = 0.0;

                if (isActive) {
                  // Pop up and down animation
                  final progress = _gridTileController.value;
                  if (progress < 0.5) {
                    // Going up
                    scale = 1.0 + (0.15 * (progress * 2));
                    elevation = 20 * (progress * 2);
                  } else {
                    // Going down
                    scale = 1.15 - (0.15 * ((progress - 0.5) * 2));
                    elevation = 20 * (1 - ((progress - 0.5) * 2));
                  }
                }

                return Positioned(
                  left: left,
                  top: top - (isActive ? elevation * 0.3 : 0),
                  width: cellSize,
                  height: cellHeight,
                  child: Transform.scale(
                    scale: scale,
                    child: _build3DCell(
                      tile['top'] as Color,
                      tile['bottom'] as Color,
                      isActive: isActive,
                      elevation: elevation,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _build3DCell(
    Color topColor,
    Color bottomColor, {
    bool isActive = false,
    double elevation = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, Color.lerp(topColor, bottomColor, 0.5)!],
        ),
        boxShadow: [
          // Bottom shadow for 3D depth
          BoxShadow(
            color: bottomColor.withValues(alpha: 0.8),
            offset: Offset(0, 4 + elevation * 0.2),
            blurRadius: elevation * 0.5,
            spreadRadius: 0,
          ),
          // Outer glow - enhanced when active
          BoxShadow(
            color: topColor.withValues(alpha: isActive ? 0.6 : 0.3),
            blurRadius: 12 + elevation,
            spreadRadius: isActive ? 4 : 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 1.0],
            colors: [
              Colors.white.withValues(alpha: isActive ? 0.35 : 0.25),
              Colors.white.withValues(alpha: isActive ? 0.1 : 0.05),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(double gridSize) {
    return AnimatedBuilder(
      animation: _playButtonController,
      builder: (context, child) {
        final scale = 1.0 + (_playButtonController.value * 0.2);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: gridSize * 0.32,
            height: gridSize * 0.32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GameColors.emerald400.withValues(alpha: 0.7),
                  GameColors.emerald500.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: GameColors.emerald400.withValues(alpha: 0.4),
                  blurRadius: 20 + (_playButtonController.value * 15),
                  spreadRadius: 3 + (_playButtonController.value * 4),
                ),
                BoxShadow(
                  color: GameColors.emerald400.withValues(alpha: 0.2),
                  blurRadius: 40 + (_playButtonController.value * 20),
                  spreadRadius: 5 + (_playButtonController.value * 5),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: gridSize * 0.26,
                  height: gridSize * 0.26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                ),
                // Inner icon - play arrow
                Icon(
                  Icons.play_arrow_rounded,
                  size: gridSize * 0.16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartSection(
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    final adsProvider = context.watch<AdsProvider>();
    final hasRewardedAd = adsProvider.isRewardedAdLoaded;
    final buttonSize = isSmallScreen ? 40.0 : 48.0;

    return Column(
      children: [
        // Game Modes Button
        _buildGameModesButton(context, isSmallScreen: isSmallScreen),

        // x2 Bonus with Ad + Shop Button
        SizedBox(height: isSmallScreen ? 12 : 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBonusButton(
              context,
              icon: const Icon(
                Icons.play_circle_filled_rounded,
                size: 24,
                color: Colors.white,
              ),
              isEnabled: hasRewardedAd,
              onTap: () => _activateBonusWithAd(context),
            ),
            const SizedBox(width: 12),
            _buildShopButton(context, size: buttonSize),
          ],
        ),
      ],
    );
  }

  Widget _buildBonusButton(
    BuildContext context, {
    required Widget icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GameColors.amber400.withValues(alpha: 0.9),
                GameColors.orange500.withValues(alpha: 0.9),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: GameColors.amber400.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }

  Widget _buildGameModesButton(
    BuildContext context, {
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: () {
        context.read<AudioProvider>().playUiTapSound();
        _openModeSelection(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 10 : 12,
          horizontal: isSmallScreen ? 20 : 28,
        ),
        decoration: BoxDecoration(
          color: GameColors.slate800.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GameColors.slate600, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.grid_view_rounded,
              color: GameColors.slate300,
              size: isSmallScreen ? 18 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              'game_modes'.tr().toUpperCase(),
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w700,
                color: GameColors.slate300,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openModeSelection(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModeSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        barrierDismissible: false,
      ),
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

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SettingsDialog(isFromStartScreen: true),
    );
  }
}
