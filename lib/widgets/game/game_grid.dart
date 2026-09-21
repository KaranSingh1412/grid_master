import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/theme_provider.dart';
import '../tactile/tactile.dart';
import 'grid_style.dart';

/// The board: a sunken tray holding tactile tiles
class GameGrid extends StatelessWidget {
  final bool isSmallScreen;

  const GameGrid({super.key, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final gridStyleId = context.select<CreditProvider, String>(
      (c) => c.cosmeticState.equippedGridStyleId,
    );
    final animationId = context.select<CreditProvider, String>(
      (c) => c.cosmeticState.equippedCellAnimationId,
    );

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

    final cellSpacing = isSmallScreen ? 6.0 : 8.0;
    final trayPadding = isSmallScreen ? 8.0 : 10.0;
    final style = GridStyleSpec.of(gridStyleId, palette);

    return LayoutBuilder(
      builder: (context, constraints) {
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
          child: SizedBox(
            width: gridSize,
            height: gridSize,
            child: RepaintBoundary(
              child: TactileWell(
                color: palette.backgroundDeep,
                radius: style.trayRadius,
                borderColor: style.trayBorder,
                borderWidth: style.trayBorderWidth,
                glow: style.trayGlow,
                padding: EdgeInsets.all(trayPadding),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
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
                      color: cells[index].color,
                      tone: palette.toneOf(cells[index].color),
                      errorColor: palette.danger.face,
                      isInteractive: isInteractive,
                      isErrorCell: isErrorCell,
                      style: style,
                      animationId: animationId,
                      onTap: () {
                        context.read<AudioProvider>().playPlaceSound();
                        gameProvider.onCellTap(index);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridCell extends StatefulWidget {
  final ColorType color;
  final TactileTone tone;
  final Color errorColor;
  final bool isInteractive;
  final bool isErrorCell;
  final GridStyleSpec style;
  final String animationId;
  final VoidCallback onTap;

  const _GridCell({
    super.key,
    required this.color,
    required this.tone,
    required this.errorColor,
    required this.isInteractive,
    this.isErrorCell = false,
    required this.style,
    required this.animationId,
    required this.onTap,
  });

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: TactileDurations.press,
    reverseDuration: TactileDurations.release,
  );
  late final AnimationController _errorRing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final AnimationController _cosmetic = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _startCosmeticAnimation();
  }

  void _startCosmeticAnimation() {
    if (widget.animationId == 'pulse_animation' ||
        widget.animationId == 'sparkle_animation' ||
        widget.animationId == 'bounce_animation') {
      _cosmetic.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_GridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isErrorCell && _errorShown) {
      _errorShown = false;
      _errorRing.reset();
    }
    if (widget.isErrorCell && !_errorShown) {
      _errorShown = true;
      _errorRing.forward();
    }
    if (oldWidget.animationId != widget.animationId) {
      _cosmetic.stop();
      _cosmetic.reset();
      _startCosmeticAnimation();
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _errorRing.dispose();
    _cosmetic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.color == ColorType.none;
    final style = widget.style;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.isInteractive
          ? (_) {
              _press.forward();
              HapticFeedback.selectionClick();
            }
          : null,
      onTapUp: widget.isInteractive
          ? (_) {
              _press.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: widget.isInteractive ? () => _press.reverse() : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, _errorRing, _cosmetic]),
        builder: (context, child) {
          final errorAlpha = widget.isErrorCell ? 1.0 - _errorRing.value : 0.0;

          // Cosmetic animation effects
          double cosmeticScale = 1.0;
          double cosmeticGlow = 0.0;

          if (!isEmpty) {
            switch (widget.animationId) {
              case 'pulse_animation':
                cosmeticScale = 1.0 + (_cosmetic.value * 0.08);
                cosmeticGlow = _cosmetic.value * 0.5;
                break;
              case 'bounce_animation':
                final v = _cosmetic.value;
                final bounce = v < 0.5
                    ? (v * 2) * (v * 2)
                    : 1.0 - ((v - 0.5) * 2) * ((v - 0.5) * 2);
                cosmeticScale = 1.0 + (bounce * 0.12);
                break;
              case 'sparkle_animation':
                cosmeticGlow = 0.3 + (_cosmetic.value * 0.7);
                break;
            }
          }

          final haloAlpha = isEmpty
              ? 0.0
              : (style.cellHaloAlpha + cosmeticGlow * 0.45).clamp(0.0, 0.7);

          return Transform.scale(
            scale: cosmeticScale,
            child: TactileCell(
              tone: widget.tone,
              radius: style.cellRadius,
              filled: !isEmpty,
              press: Curves.easeOut.transform(_press.value),
              ringColor: errorAlpha > 0
                  ? widget.errorColor.withValues(alpha: errorAlpha)
                  : (isEmpty ? null : style.cellRing),
              ringWidth: errorAlpha > 0 ? 3 : style.cellRingWidth,
              haloColor: haloAlpha > 0
                  ? widget.tone.face.withValues(alpha: haloAlpha)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
