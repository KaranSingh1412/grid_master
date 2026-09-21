import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/game_constants.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/theme_provider.dart';

/// Game grid component matching the React implementation
class GameGrid extends StatelessWidget {
  final bool isSmallScreen;

  const GameGrid({super.key, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final creditProvider = context.watch<CreditProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    // Get the equipped theme and grid style from ThemeProvider
    final themeColors = themeProvider.colors;
    final gridStyleId = creditProvider.cosmeticState.equippedGridStyleId;
    final animationId = creditProvider.cosmeticState.equippedCellAnimationId;

    final size = gameProvider.currentLevel.gridSize;
    final isShowSolution = gameProvider.isShowSolution;
    final cells = gameProvider.isPaused
        ? gameProvider.pausedCells
        : (gameProvider.isPreview || gameProvider.isLevelUp || isShowSolution
              ? gameProvider.targetPattern
              : gameProvider.userPattern);
    final isInteractive = gameProvider.isRebuild;

    // Get user pattern for error comparison during solution display
    final userPattern = gameProvider.userPattern;

    // Consistent spacing in all modes
    final cellSpacing = isSmallScreen ? 6.0 : 8.0;
    final containerPadding = isSmallScreen ? 6.0 : 8.0;

    // Get grid style properties
    final gridBorderRadius = _getGridBorderRadius(gridStyleId);
    final gridBorderColor = _getGridBorderColor(gridStyleId, themeColors);
    final gridGlow = _getGridGlow(gridStyleId, themeColors);

    // Use LayoutBuilder to get available space and calculate grid size
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate grid size based on available space
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Grid should be square, so take the minimum of width and height
        final maxGridSize = availableWidth < availableHeight
            ? availableWidth * 0.95
            : availableHeight * 0.95;
        final gridSize = (screenWidth * 0.92)
            .clamp(0.0, maxGridSize)
            .clamp(0.0, 420.0);

        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: gridSize,
            height: gridSize,
            decoration: BoxDecoration(
              color: themeColors.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(gridBorderRadius),
              border: Border.all(color: gridBorderColor, width: 4),
              boxShadow: gridGlow,
            ),
            padding: EdgeInsets.all(containerPadding),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size,
                crossAxisSpacing: cellSpacing,
                mainAxisSpacing: cellSpacing,
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                // Check if this cell was wrong (only during solution display)
                final isErrorCell =
                    isShowSolution &&
                    userPattern[index].color != cells[index].color;

                return _GridCell(
                  key: ValueKey('cell_$index'),
                  cell: cells[index],
                  isInteractive: isInteractive,
                  isErrorCell: isErrorCell,
                  themeColors: themeColors,
                  gridStyleId: gridStyleId,
                  animationId: animationId,
                  onTap: () {
                    context.read<AudioProvider>().playPlaceSound();
                    gameProvider.onCellTap(index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  double _getGridBorderRadius(String gridStyleId) {
    switch (gridStyleId) {
      case 'rounded_grid':
        return 24.0;
      case 'glow_grid':
        return 20.0;
      case 'neon_border_grid':
        return 12.0;
      case 'sharp_grid':
        return 3.0;
      default:
        return 16.0;
    }
  }

  Color _getGridBorderColor(
    String gridStyleId,
    CosmeticThemeColors themeColors,
  ) {
    switch (gridStyleId) {
      case 'glow_grid':
        return themeColors.primary.withValues(alpha: 0.6);
      case 'neon_border_grid':
        return themeColors.accent;
      default:
        return themeColors.surface.withValues(alpha: 0.5);
    }
  }

  List<BoxShadow>? _getGridGlow(
    String gridStyleId,
    CosmeticThemeColors themeColors,
  ) {
    switch (gridStyleId) {
      case 'glow_grid':
        return [
          BoxShadow(
            color: themeColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ];
      case 'neon_border_grid':
        return [
          BoxShadow(
            color: themeColors.accent.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: themeColors.accent.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 3,
          ),
        ];
      default:
        return null;
    }
  }
}

class _GridCell extends StatefulWidget {
  final GridCell cell;
  final bool isInteractive;
  final bool isErrorCell;
  final CosmeticThemeColors themeColors;
  final String gridStyleId;
  final String animationId;
  final VoidCallback onTap;

  const _GridCell({
    super.key,
    required this.cell,
    required this.isInteractive,
    this.isErrorCell = false,
    required this.themeColors,
    required this.gridStyleId,
    required this.animationId,
    required this.onTap,
  });

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late AnimationController _errorGlowController;
  late Animation<double> _errorGlowAnimation;
  late AnimationController _cosmeticAnimController;
  bool _errorGlowShown = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _errorGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _errorGlowAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _errorGlowController, curve: Curves.easeOut),
    );

    // Cosmetic animation controller for pulse/bounce/sparkle
    _cosmeticAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startCosmeticAnimation();
  }

  void _startCosmeticAnimation() {
    if (widget.animationId == 'pulse_animation' ||
        widget.animationId == 'sparkle_animation' ||
        widget.animationId == 'bounce_animation') {
      _cosmeticAnimController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_GridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error glow state when isErrorCell becomes false
    if (!widget.isErrorCell && _errorGlowShown) {
      _errorGlowShown = false;
      _errorGlowController.reset();
    }
    // Trigger error glow animation when isErrorCell becomes true
    if (widget.isErrorCell && !_errorGlowShown) {
      _errorGlowShown = true;
      _errorGlowController.forward();
    }
    // Restart cosmetic animation if animationId changed
    if (oldWidget.animationId != widget.animationId) {
      _cosmeticAnimController.stop();
      _cosmeticAnimController.reset();
      _startCosmeticAnimation();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _errorGlowController.dispose();
    _cosmeticAnimController.dispose();
    super.dispose();
  }

  Color _getCellColor() {
    if (widget.cell.color == ColorType.none) {
      return widget.themeColors.surface.withValues(alpha: 0.2);
    }

    // Check if theme has custom game colors
    if (widget.themeColors.gameColors.isNotEmpty) {
      final colorIndex = widget.cell.color.index;
      if (colorIndex < widget.themeColors.gameColors.length) {
        return widget.themeColors.gameColors[colorIndex];
      }
    }

    // Fall back to default game colors
    return GameColors.getColor(widget.cell.color);
  }

  double _getCellBorderRadius() {
    switch (widget.gridStyleId) {
      case 'rounded_grid':
        return 12.0;
      case 'glow_grid':
        return 10.0;
      case 'neon_border_grid':
        return 4.0;
      case 'sharp_grid':
        return 3.0;
      default:
        return 6.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCellColor();
    final isEmpty = widget.cell.color == ColorType.none;
    final borderRadius = _getCellBorderRadius();

    return GestureDetector(
      onTapDown: widget.isInteractive
          ? (_) {
              _animController.forward();
              HapticFeedback.selectionClick();
            }
          : null,
      onTapUp: widget.isInteractive
          ? (_) {
              _animController.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: widget.isInteractive
          ? () => _animController.reverse()
          : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _animController,
          _errorGlowController,
          _cosmeticAnimController,
        ]),
        builder: (context, child) {
          final glowIntensity = widget.isErrorCell
              ? _errorGlowAnimation.value
              : 0.0;

          // Cosmetic animation effects
          double cosmeticScale = 1.0;
          double cosmeticGlow = 0.0;

          if (!isEmpty) {
            switch (widget.animationId) {
              case 'pulse_animation':
                // Deutlicheres Pulsieren: 8% Skalierung
                cosmeticScale = 1.0 + (_cosmeticAnimController.value * 0.08);
                cosmeticGlow = _cosmeticAnimController.value * 0.5;
                break;
              case 'bounce_animation':
                // Bounce-Effekt: deutliche Hüpf-Bewegung
                final bounceValue = _cosmeticAnimController.value;
                // Easing für natürlicheren Bounce
                final bounce = bounceValue < 0.5
                    ? (bounceValue * 2) *
                          (bounceValue * 2) // Hoch
                    : 1.0 -
                          ((bounceValue - 0.5) * 2) *
                              ((bounceValue - 0.5) * 2); // Runter
                cosmeticScale = 1.0 + (bounce * 0.12);
                break;
              case 'sparkle_animation':
                // Stärkeres Funkeln mit Helligkeitsänderung
                cosmeticGlow = 0.3 + (_cosmeticAnimController.value * 0.7);
                break;
            }
          }

          return Transform.scale(
            scale:
                (widget.isInteractive
                    ? _scaleAnimation.value
                    : (isEmpty ? 0.96 : 1.0)) *
                cosmeticScale,
            child: Container(
              decoration: BoxDecoration(
                color: isEmpty
                    ? widget.themeColors.surface.withValues(alpha: 0.2)
                    : color,
                borderRadius: BorderRadius.circular(borderRadius),
                border: glowIntensity > 0
                    ? Border.all(
                        color: GameColors.rose500.withValues(
                          alpha: glowIntensity,
                        ),
                        width: 3,
                      )
                    : (widget.gridStyleId == 'neon_border_grid' && !isEmpty
                          ? Border.all(
                              color: widget.themeColors.accent.withValues(
                                alpha: 0.6,
                              ),
                              width: 1,
                            )
                          : null),
                boxShadow: _buildCellShadows(
                  isEmpty,
                  color,
                  glowIntensity,
                  cosmeticGlow,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<BoxShadow>? _buildCellShadows(
    bool isEmpty,
    Color color,
    double glowIntensity,
    double cosmeticGlow,
  ) {
    if (glowIntensity > 0) {
      return [
        BoxShadow(
          color: GameColors.rose500.withValues(alpha: 0.8 * glowIntensity),
          blurRadius: 12,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: GameColors.rose500.withValues(alpha: 0.4 * glowIntensity),
          blurRadius: 20,
          spreadRadius: 4,
        ),
      ];
    }

    if (isEmpty) return null;

    final shadows = <BoxShadow>[];

    // Base glow for glow grid style
    if (widget.gridStyleId == 'glow_grid') {
      shadows.add(
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      );
    }

    // Cosmetic animation glow
    if (cosmeticGlow > 0) {
      shadows.add(
        BoxShadow(
          color: color.withValues(alpha: cosmeticGlow),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      );
    }

    // Default subtle glow
    if (shadows.isEmpty) {
      shadows.add(
        BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 10),
      );
    }

    return shadows;
  }
}
