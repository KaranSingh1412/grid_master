import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/game_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../tactile/tactile.dart';

/// Game header with level, score, and combo display
class GameHeader extends StatefulWidget {
  final bool isSmallScreen;

  const GameHeader({super.key, this.isSmallScreen = false});

  @override
  State<GameHeader> createState() => _GameHeaderState();
}

class _GameHeaderState extends State<GameHeader> with TickerProviderStateMixin {
  late final AnimationController _scoreBump = AnimationController(
    vsync: this,
    duration: TactileDurations.bump,
  );
  late final AnimationController _creditBump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _bonusPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  int _previousScore = 0;
  int _previousCredits = 0;
  bool _showCreditEarned = false;

  @override
  void initState() {
    super.initState();
    _creditBump.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showCreditEarned = false);
      }
    });
  }

  @override
  void dispose() {
    _scoreBump.dispose();
    _creditBump.dispose();
    _bonusPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final creditProvider = context.watch<CreditProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final text = TactileText(palette);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final score = gameProvider.score;
    final level = gameProvider.currentLevel;
    final currentCredits = creditProvider.credits;
    final hasDoubleBonus = gameProvider.hasDoubleBonus;

    // Start/stop bonus pulse animation based on bonus state
    if (hasDoubleBonus && !reduceMotion && !_bonusPulse.isAnimating) {
      _bonusPulse.repeat(reverse: true);
    } else if ((!hasDoubleBonus || reduceMotion) && _bonusPulse.isAnimating) {
      _bonusPulse.stop();
    }

    // Trigger animation when score changes
    if (score.points != _previousScore && score.points > _previousScore) {
      if (!reduceMotion) _scoreBump.forward(from: 0);
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
      _creditBump.forward(from: 0);
      _showCreditEarned = true;
    }
    _previousCredits = currentCredits;

    final headerPadding = widget.isSmallScreen ? 8.0 : 12.0;
    final spacing = widget.isSmallScreen ? 6.0 : 10.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: headerPadding),
      child: Column(
        children: [
          // Credits and phase hint row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCreditsPill(palette, text, currentCredits),
              if (gameProvider.isPreview || gameProvider.isRebuild)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildPhaseBadge(
                      palette,
                      text,
                      isPreview: gameProvider.isPreview,
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
                  Text(level.difficulty.tr().toUpperCase(), style: text.label),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${'lvl'.tr()} ${score.level}',
                        style: text.number(widget.isSmallScreen ? 24.0 : 30.0),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${'best'.tr()}: ${score.highScore}',
                        style: text.number(
                          widget.isSmallScreen ? 12.0 : 14.0,
                          color: palette.textMuted,
                          weight: FontWeight.w500,
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
                      if (hasDoubleBonus) _buildBonusBadge(palette, text),
                      Text('points'.tr().toUpperCase(), style: text.label),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AnimatedBuilder(
                    animation: _scoreBump,
                    builder: (context, child) {
                      final t = _scoreBump.isAnimating ? _scoreBump.value : 1.0;
                      final scale = 1.0 + 0.25 * (1 - (2 * t - 1).abs());
                      return Transform.scale(
                        scale: scale,
                        alignment: Alignment.centerRight,
                        child: child,
                      );
                    },
                    child: Text(
                      _formatNumber(score.points),
                      style: text.number(
                        30,
                        color: hasDoubleBonus
                            ? palette.cta.face
                            : palette.textPrimary,
                      ),
                    ),
                  ),

                  // Combo badge
                  if (score.combo > 1) ...[
                    const SizedBox(height: 4),
                    _buildComboBadge(palette, text, score.combo),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseBadge(
    TactilePalette palette,
    TactileText text, {
    required bool isPreview,
  }) {
    final tone = isPreview ? palette.raised : palette.primary;
    return TactileSurface(
      tone: tone,
      radius: TactileRadii.sm,
      depth: TactileDepth.small,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPreview ? Icons.visibility : Icons.edit,
            color: tone.ink,
            size: 18,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isPreview
                  ? 'memorize_pattern'.tr().toUpperCase()
                  : 'rebuild_pattern'.tr().toUpperCase(),
              style: text.label.copyWith(
                fontSize: widget.isSmallScreen ? 12.0 : 14.0,
                color: tone.ink,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusBadge(TactilePalette palette, TactileText text) {
    return AnimatedBuilder(
      animation: _bonusPulse,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + 0.1 * Curves.easeInOut.transform(_bonusPulse.value),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TactileSurface(
          tone: palette.cta,
          radius: TactileRadii.xs,
          depth: TactileDepth.small,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: Text('x2', style: text.number(12, color: palette.cta.ink)),
        ),
      ),
    );
  }

  Widget _buildCreditsPill(
    TactilePalette palette,
    TactileText text,
    int credits,
  ) {
    return AnimatedBuilder(
      animation: _creditBump,
      builder: (context, child) {
        final t = _creditBump.value;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: _showCreditEarned
                  ? 1.0 + 0.25 * Curves.elasticOut.transform(t) * (1 - t)
                  : 1.0,
              child: child,
            ),
            // +1 floating indicator
            if (_showCreditEarned)
              Positioned(
                right: -22,
                top: -10,
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -20 * t),
                    child: Text(
                      '+1',
                      style: text.number(18, color: palette.cta.face),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: TactileSurface(
        tone: palette.surface,
        radius: TactileRadii.pill,
        depth: TactileDepth.small,
        padding: const EdgeInsets.fromLTRB(10, 5, 14, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/coin.png', width: 20, height: 20),
            const SizedBox(width: 6),
            Text(
              credits.toString(),
              style: text.number(
                18,
                color: palette.cta.face,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboBadge(TactilePalette palette, TactileText text, int combo) {
    final tone = TactileColors.orange;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TactileSurface(
          tone: tone,
          radius: 6,
          depth: TactileDepth.small,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Text(
            'combo'.tr().toUpperCase(),
            style: text.label.copyWith(fontSize: 10, color: tone.ink),
          ),
        ),
        const SizedBox(width: 4),
        Text('x$combo', style: text.number(14, color: tone.face)),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
}
