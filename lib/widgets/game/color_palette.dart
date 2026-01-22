import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/game_constants.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/credit_provider.dart';

/// Color palette for selecting colors in rebuild mode
class ColorPalette extends StatelessWidget {
  final bool isSmallScreen;

  const ColorPalette({super.key, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final creditProvider = context.watch<CreditProvider>();

    final colorCount = gameProvider.currentLevel.colorCount;
    final availableColors = colorOptions.take(colorCount).toList();
    final selectedColor = gameProvider.selectedColor;
    final buttonSpacing = isSmallScreen ? 6.0 : 8.0;
    final containerPadding = isSmallScreen ? 8.0 : 12.0;

    final hints = gameProvider.hints;
    final hasFreeHints = hints > 0;
    final canBuyHint =
        creditProvider.credits >= 5 && creditProvider.canBuyHintToday;
    final paidHintsRemaining = creditProvider.paidHintsRemaining;

    Widget palette = Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: GameColors.slate800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameColors.slate700.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color buttons
          ...availableColors.map((color) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: buttonSpacing),
              child: _PaletteButton(
                color: color,
                isSelected: selectedColor == color,
                onTap: () => gameProvider.selectColor(color),
                isSmallScreen: isSmallScreen,
              ),
            );
          }),

          // Spacer
          SizedBox(width: buttonSpacing * 1),

          // Hint button with badge
          _HintButton(
            hints: hints,
            hasFreeHints: hasFreeHints,
            canBuyHint: canBuyHint,
            paidHintsRemaining: paidHintsRemaining,
            isSmallScreen: isSmallScreen,
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

    return palette;
  }
}

class _PaletteButton extends StatefulWidget {
  final ColorType color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _PaletteButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.isSmallScreen = false,
  });

  @override
  State<_PaletteButton> createState() => _PaletteButtonState();
}

class _PaletteButtonState extends State<_PaletteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = GameColors.getColor(widget.color);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * (widget.isSelected ? 1.1 : 0.9),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.isSmallScreen ? 40.0 : 48.0,
          height: widget.isSmallScreen ? 40.0 : 48.0,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(
              widget.isSmallScreen ? 12.0 : 16.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Selection ring
              if (widget.isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        widget.isSmallScreen ? 12.0 : 16.0,
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: widget.isSmallScreen ? 3.0 : 4.0,
                      ),
                    ),
                  ),
                ),

              // Selection indicator dot
              if (widget.isSelected)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: widget.isSmallScreen ? 14.0 : 16.0,
                    height: widget.isSmallScreen ? 14.0 : 16.0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: widget.isSmallScreen ? 6.0 : 8.0,
                        height: widget.isSmallScreen ? 6.0 : 8.0,
                        decoration: const BoxDecoration(
                          color: GameColors.slate900,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

              // Opacity overlay for unselected
              if (!widget.isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(
                        widget.isSmallScreen ? 12.0 : 16.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintButton extends StatelessWidget {
  final int hints;
  final bool hasFreeHints;
  final bool canBuyHint;
  final int paidHintsRemaining;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _HintButton({
    required this.hints,
    required this.hasFreeHints,
    required this.canBuyHint,
    required this.paidHintsRemaining,
    required this.isSmallScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = hasFreeHints || canBuyHint;
    final buttonSize = isSmallScreen ? 40.0 : 48.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main button
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: hasFreeHints
                  ? GameColors.indigo600
                  : (canBuyHint ? GameColors.amber500 : GameColors.slate700),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color:
                            (hasFreeHints
                                    ? GameColors.indigo600
                                    : GameColors.amber500)
                                .withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.lightbulb,
              color: isEnabled ? Colors.white : GameColors.slate500,
              size: iconSize,
            ),
          ),

          // Badge
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasFreeHints
                    ? GameColors.indigo500
                    : GameColors.amber700,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GameColors.slate900, width: 2),
              ),
              child: hasFreeHints
                  ? Text(
                      hints.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
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
                        const Text(
                          '5',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
