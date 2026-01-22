import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/game_constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/credit_provider.dart';

/// Game header with level, score, and combo display
class GameHeader extends StatefulWidget {
  final bool isSmallScreen;

  const GameHeader({super.key, this.isSmallScreen = false});

  @override
  State<GameHeader> createState() => _GameHeaderState();
}

class _GameHeaderState extends State<GameHeader> with TickerProviderStateMixin {
  late AnimationController _scoreAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  late AnimationController _creditAnimController;
  late Animation<double> _creditScaleAnimation;

  late AnimationController _bonusPulseController;
  late Animation<double> _bonusPulseAnimation;
  late Animation<Color?> _bonusColorAnimation;

  int _previousScore = 0;
  int _previousCredits = 0;
  bool _showCreditEarned = false;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _scoreAnimController,
            curve: Curves.easeInOut,
          ),
        );
    _colorAnimation =
        TweenSequence<Color?>([
          TweenSequenceItem(
            tween: ColorTween(begin: Colors.white, end: GameColors.emerald400),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: GameColors.emerald400, end: Colors.white),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _scoreAnimController,
            curve: Curves.easeInOut,
          ),
        );

    // Credit animation controller
    _creditAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _creditScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _creditAnimController, curve: Curves.elasticOut),
    );
    _creditAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showCreditEarned = false);
      }
    });

    // Bonus pulse animation (continuous)
    _bonusPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bonusPulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _bonusPulseController,
            curve: Curves.easeInOut,
          ),
        );
    _bonusColorAnimation =
        TweenSequence<Color?>([
          TweenSequenceItem(
            tween: ColorTween(
              begin: GameColors.amber400,
              end: GameColors.orange500,
            ),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: ColorTween(
              begin: GameColors.orange500,
              end: GameColors.amber400,
            ),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _bonusPulseController,
            curve: Curves.easeInOut,
          ),
        );

    // Set up listener to loop animation
    _bonusPulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _bonusPulseController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    _creditAnimController.dispose();
    _bonusPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final creditProvider = context.watch<CreditProvider>();
    final score = gameProvider.score;
    final level = gameProvider.currentLevel;
    final currentCredits = creditProvider.credits;
    final hasDoubleBonus = gameProvider.hasDoubleBonus;

    // Start/stop bonus pulse animation based on bonus state
    if (hasDoubleBonus && !_bonusPulseController.isAnimating) {
      _bonusPulseController.forward(from: 0);
    } else if (!hasDoubleBonus && _bonusPulseController.isAnimating) {
      _bonusPulseController.stop();
    }

    // Trigger animation when score changes
    if (score.points != _previousScore && score.points > _previousScore) {
      _scoreAnimController.forward(from: 0);
      // Check and award credits - schedule after build to avoid setState during build
      final pointsToCheck = score.points;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        creditProvider.checkAndAwardCredits(pointsToCheck);
      });
    }
    _previousScore = score.points;

    // Trigger credit animation when credits change (only during gameplay with 2000+ points)
    if (currentCredits != _previousCredits &&
        currentCredits > _previousCredits &&
        score.points >= 2000) {
      _creditAnimController.forward(from: 0);
      _showCreditEarned = true;
    }
    _previousCredits = currentCredits;

    final headerPadding = widget.isSmallScreen ? 12.0 : 16.0;
    final spacing = widget.isSmallScreen ? 6.0 : 8.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: headerPadding),
      child: Column(
        children: [
          // Credits and phase hint row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Credits on the left
              _buildCreditsRow(currentCredits),

              // Phase hint badge on the right
              if (gameProvider.isPreview || gameProvider.isRebuild)
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gameProvider.isPreview
                            ? [
                                const Color(0xFF6366F1).withValues(alpha: 0.3),
                                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                              ]
                            : [
                                const Color(0xFF10B981).withValues(alpha: 0.3),
                                const Color(0xFF059669).withValues(alpha: 0.3),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gameProvider.isPreview
                            ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                            : const Color(0xFF10B981).withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (gameProvider.isPreview
                                      ? const Color(0xFF6366F1)
                                      : const Color(0xFF10B981))
                                  .withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gameProvider.isPreview
                              ? Icons.visibility
                              : Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            gameProvider.isPreview
                                ? 'memorize_pattern'.tr().toUpperCase()
                                : 'rebuild_pattern'.tr().toUpperCase(),
                            style: TextStyle(
                              fontSize: widget.isSmallScreen ? 13.0 : 16.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing),

          // Main header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Level info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.difficulty.tr().toUpperCase(),
                    style: TextStyle(
                      fontSize: widget.isSmallScreen ? 10.0 : 12.0,
                      fontWeight: FontWeight.w700,
                      color: GameColors.slate400,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${'lvl'.tr()} ${score.level}',
                        style: TextStyle(
                          fontSize: widget.isSmallScreen ? 24.0 : 30.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${'best'.tr()}: ${score.highScore}',
                        style: TextStyle(
                          fontSize: widget.isSmallScreen ? 12.0 : 14.0,
                          color: GameColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Right side - Points and combo
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasDoubleBonus)
                        AnimatedBuilder(
                          animation: _bonusPulseController,
                          builder: (context, child) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _bonusColorAnimation.value ??
                                        GameColors.amber400,
                                    GameColors.orange500,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (_bonusColorAnimation.value ??
                                                GameColors.amber400)
                                            .withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Transform.scale(
                                scale: _bonusPulseAnimation.value,
                                child: const Text(
                                  'x2',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      Text(
                        'points'.tr().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: GameColors.slate400,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _scoreAnimController,
                      _bonusPulseController,
                    ]),
                    builder: (context, child) {
                      final baseScale = _scaleAnimation.value;
                      final bonusScale =
                          hasDoubleBonus && _bonusPulseController.isAnimating
                          ? _bonusPulseAnimation.value
                          : 1.0;
                      final bonusColor =
                          hasDoubleBonus && _bonusPulseController.isAnimating
                          ? _bonusColorAnimation.value
                          : _colorAnimation.value;

                      return Transform.scale(
                        scale: baseScale * (hasDoubleBonus ? bonusScale : 1.0),
                        child: Text(
                          _formatNumber(score.points),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: bonusColor ?? Colors.white,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            shadows: hasDoubleBonus
                                ? [
                                    Shadow(
                                      color: (bonusColor ?? GameColors.amber400)
                                          .withValues(alpha: 0.8),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),

                  // Combo badge
                  if (score.combo > 1) ...[
                    const SizedBox(height: 4),
                    _buildComboBadge(score.combo),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsRow(int credits) {
    return AnimatedBuilder(
      animation: _creditAnimController,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: _showCreditEarned ? _creditScaleAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: GameColors.slate800.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showCreditEarned
                        ? GameColors.amber400.withValues(alpha: 0.8)
                        : GameColors.amber400.withValues(alpha: 0.3),
                    width: _showCreditEarned ? 2 : 1,
                  ),
                  boxShadow: _showCreditEarned
                      ? [
                          BoxShadow(
                            color: GameColors.amber400.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/img/coin.png', width: 20, height: 20),
                    const SizedBox(width: 6),
                    Text(
                      credits.toString(),
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _showCreditEarned
                            ? Colors.white
                            : GameColors.amber400,
                        shadows: _showCreditEarned
                            ? [
                                Shadow(
                                  color: GameColors.amber400.withValues(
                                    alpha: 0.8,
                                  ),
                                  blurRadius: 12,
                                ),
                              ]
                            : [
                                Shadow(
                                  color: GameColors.amber400.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 6,
                                ),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // +1 floating indicator
            if (_showCreditEarned)
              Positioned(
                right: -20,
                top: -10,
                child: Opacity(
                  opacity: (1 - _creditAnimController.value).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -20 * _creditAnimController.value),
                    child: Text(
                      '+1',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: GameColors.amber400,
                        shadows: [
                          Shadow(
                            color: GameColors.amber400.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildComboBadge(int combo) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: GameColors.orange500,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'combo'.tr().toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'x$combo',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GameColors.orange500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
}
