import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/game_constants.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../tactile/tactile.dart';

/// Color palette for selecting colors in rebuild mode
class ColorPalette extends StatelessWidget {
  final bool isSmallScreen;

  const ColorPalette({super.key, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final creditProvider = context.watch<CreditProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );

    final colorCount = gameProvider.currentLevel.colorCount;
    final availableColors = colorOptions.take(colorCount).toList();
    final selectedColor = gameProvider.selectedColor;
    final buttonSpacing = isSmallScreen ? 4.0 : 6.0;

    final hints = gameProvider.hints;
    final hasFreeHints = hints > 0;
    final canBuyHint =
        creditProvider.credits >= 5 && creditProvider.canBuyHintToday;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keys shrink so five colors plus the hint key always fit the row
        final sidePadding = isSmallScreen ? 8.0 : 12.0;
        final keys = availableColors.length + 1;
        final gaps = keys * buttonSpacing * 2 + buttonSpacing * 2;
        final fit = (constraints.maxWidth - sidePadding * 2 - gaps) / keys;
        final keySize = fit.clamp(36.0, isSmallScreen ? 44.0 : 52.0);

        return _buildTray(
          palette,
          gameProvider,
          creditProvider,
          availableColors,
          selectedColor,
          buttonSpacing,
          keySize,
          hints,
          hasFreeHints,
          canBuyHint,
        );
      },
    );
  }

  Widget _buildTray(
    TactilePalette palette,
    GameProvider gameProvider,
    CreditProvider creditProvider,
    List<ColorType> availableColors,
    ColorType selectedColor,
    double buttonSpacing,
    double keySize,
    int hints,
    bool hasFreeHints,
    bool canBuyHint,
  ) {
    return TactileSurface(
      tone: palette.surface,
      radius: TactileRadii.xl,
      softShadow: true,
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 8 : 12,
        // Head room for the lifted selection
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 8 : 12,
        isSmallScreen ? 8 : 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...availableColors.map((color) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: buttonSpacing),
              child: _PaletteKey(
                tone: palette.toneOf(color),
                ringColor: palette.textPrimary,
                isSelected: selectedColor == color,
                onTap: () => gameProvider.selectColor(color),
                size: keySize,
              ),
            );
          }),

          SizedBox(width: buttonSpacing * 2),

          _HintKey(
            palette: palette,
            hints: hints,
            hasFreeHints: hasFreeHints,
            canBuyHint: canBuyHint,
            size: keySize,
            onTap: () {
              if (hasFreeHints) {
                gameProvider.useHint();
              } else if (canBuyHint) {
                gameProvider.usePaidHint(creditProvider);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PaletteKey extends StatelessWidget {
  final TactileTone tone;
  final Color ringColor;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const _PaletteKey({
    required this.tone,
    required this.ringColor,
    required this.isSelected,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // The chosen key lifts out of the row and gets a ring
    return TweenAnimationBuilder<double>(
      tween: Tween(end: isSelected ? 1.0 : 0.0),
      duration: reduceMotion ? Duration.zero : TactileDurations.select,
      curve: TactileCurves.release,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, -6 * t),
          child: Transform.scale(scale: 1.0 + 0.08 * t, child: child),
        );
      },
      child: Semantics(
        selected: isSelected,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            TactileButton(
              tone: tone,
              onTap: onTap,
              width: size,
              height: size,
              radius: size * 0.32,
              padding: EdgeInsets.zero,
              child: const SizedBox.shrink(),
            ),
            if (isSelected)
              Positioned(
                left: -4,
                right: -4,
                top: -4,
                bottom: -4,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.32 + 4),
                      border: Border.all(color: ringColor, width: 3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HintKey extends StatelessWidget {
  final TactilePalette palette;
  final int hints;
  final bool hasFreeHints;
  final bool canBuyHint;
  final double size;
  final VoidCallback onTap;

  const _HintKey({
    required this.palette,
    required this.hints,
    required this.hasFreeHints,
    required this.canBuyHint,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = hasFreeHints || canBuyHint;
    // Neutral key: it must never read as one of the pattern colors
    final tone = hasFreeHints ? palette.raised : palette.cta;
    final text = TactileText(palette);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TactileButton(
          tone: tone,
          disabledTone: palette.raised.muted(palette.surface.face),
          onTap: isEnabled ? onTap : null,
          width: size,
          height: size,
          radius: size * 0.32,
          padding: EdgeInsets.zero,
          semanticLabel: 'a11y_hint'.tr(),
          child: Icon(
            Icons.lightbulb,
            size: size * 0.48,
            color: !isEnabled
                ? palette.textMuted
                : (hasFreeHints ? palette.cta.face : null),
          ),
        ),

        // Badge
        Positioned(
          top: -8,
          right: -8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: hasFreeHints ? tone.lip : palette.cta.lip,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.surface.face, width: 2),
              ),
              child: hasFreeHints
                  ? Text(
                      hints.toString(),
                      style: text.number(12, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/img/coin.png',
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 2),
                        Text('5', style: text.number(10, color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
