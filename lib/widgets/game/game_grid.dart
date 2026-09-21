import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/theme_provider.dart';
import '../effects/particle_field.dart';
import '../tactile/tactile.dart';
import 'grid_style.dart';

/// Board-wide sequences. One controller per sequence; every tile derives its
/// own progress from a per-index delay, so there are no timers per tile.
class _GridMotion {
  _GridMotion(TickerProvider vsync)
    : entrance = AnimationController(vsync: vsync, value: 1),
      wave = AnimationController(vsync: vsync, value: 1),
      wiggle = AnimationController(
        vsync: vsync,
        duration: TactileDurations.wiggle,
        value: 1,
      ),
      pulse = AnimationController(
        vsync: vsync,
        duration: TactileDurations.gridPulse,
        value: 1,
      ),
      cosmetic = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 1600),
      );

  final AnimationController entrance;
  final AnimationController wave;
  final AnimationController wiggle;
  final AnimationController pulse;
  final AnimationController cosmetic;

  /// Delay in ms per cell index, -1 when the cell takes no part
  List<double> entranceDelays = const [];
  List<double> waveDelays = const [];

  static final double popMs = TactileDurations.pop.inMilliseconds.toDouble();
  static const double hopMs = 420;

  /// Null while idle, <= 0 before the tile's turn, then 0..1
  double? entranceProgress(int index) =>
      _progress(entrance, entranceDelays, index, popMs);

  double? waveProgress(int index) => _progress(wave, waveDelays, index, hopMs);

  double? _progress(
    AnimationController c,
    List<double> delays,
    int index,
    double length,
  ) {
    if (!c.isAnimating || index >= delays.length) return null;
    final delay = delays[index];
    if (delay < 0) return null;
    final elapsed = c.value * c.duration!.inMilliseconds;
    return ((elapsed - delay) / length).clamp(-1.0, 1.0);
  }

  void dispose() {
    entrance.dispose();
    wave.dispose();
    wiggle.dispose();
    pulse.dispose();
    cosmetic.dispose();
  }
}

/// The board: a sunken tray holding tactile tiles
class GameGrid extends StatefulWidget {
  final bool isSmallScreen;

  const GameGrid({super.key, this.isSmallScreen = false});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> with TickerProviderStateMixin {
  late final _GridMotion _motion = _GridMotion(this);
  final ParticleController _particles = ParticleController();
  final Random _random = Random();

  late final GameProvider _game;
  late GameState _lastState;
  List<GridCell>? _lastPattern;

  List<bool> _waveFired = const [];
  double _lastCosmeticValue = 0;
  String _animationId = 'default_animation';
  bool _reduceMotion = false;
  bool _didInitialEntrance = false;

  // Geometry of the last layout, used to place particles
  double _cellSize = 0;
  double _cellStep = 0;
  double _trayPadding = 0;

  @override
  void initState() {
    super.initState();
    _game = context.read<GameProvider>();
    _lastState = _game.gameState;
    _lastPattern = _game.targetPattern;
    _game.addListener(_onGameChanged);
    _motion.wave.addListener(_onWaveTick);
    _motion.cosmetic.addListener(_onCosmeticTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    _syncCosmetic();

    // Entering the screen straight into a preview
    if (!_didInitialEntrance) {
      _didInitialEntrance = true;
      if (_game.isPreview) _startEntrance();
    }
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _motion.dispose();
    _particles.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    final state = _game.gameState;
    final pattern = _game.targetPattern;
    final newPattern = !identical(pattern, _lastPattern);

    if (state != _lastState || newPattern) {
      if (state == GameState.preview &&
          (_lastState != GameState.paused || newPattern)) {
        _startEntrance();
      } else if (state == GameState.rebuild &&
          _lastState == GameState.preview) {
        if (!_reduceMotion) _motion.pulse.forward(from: 0);
      } else if (state == GameState.levelUp) {
        _startWave();
      } else if (state == GameState.showSolution) {
        if (!_reduceMotion) _motion.wiggle.forward(from: 0);
      }
      _lastState = state;
      _lastPattern = pattern;
    }
  }

  /// Pattern tiles pop in one after the other
  void _startEntrance() {
    if (_reduceMotion) return;
    final pattern = _game.targetPattern;
    final filled = pattern.where((c) => c.color != ColorType.none).length;
    if (filled == 0) return;

    // 70 ms apart, but the whole cascade never eats more than 450 ms of
    // the preview
    final step = min(
      TactileDurations.stagger.inMilliseconds.toDouble(),
      450 / filled,
    );
    int order = 0;
    _motion.entranceDelays = [
      for (final cell in pattern)
        cell.color == ColorType.none ? -1.0 : step * order++,
    ];
    _motion.entrance.duration = Duration(
      milliseconds: (step * (filled - 1) + _GridMotion.popMs).ceil(),
    );
    _motion.entrance.forward(from: 0);
  }

  /// Diagonal wave across the board after a solved level
  void _startWave() {
    if (_reduceMotion) return;
    final size = _game.currentLevel.gridSize;
    final step = TactileDurations.stagger.inMilliseconds.toDouble();
    _motion.waveDelays = [
      for (int i = 0; i < size * size; i++) ((i ~/ size) + (i % size)) * step,
    ];
    _waveFired = List<bool>.filled(size * size, false);
    _motion.wave.duration = Duration(
      milliseconds: ((size - 1) * 2 * step + _GridMotion.hopMs).ceil(),
    );
    _motion.wave.forward(from: 0);
  }

  void _onWaveTick() {
    if (!_motion.wave.isAnimating) return;
    final pattern = _game.targetPattern;
    for (int i = 0; i < _waveFired.length && i < pattern.length; i++) {
      if (_waveFired[i]) continue;
      final t = _motion.waveProgress(i);
      if (t == null || t <= 0) continue;
      _waveFired[i] = true;
      final color = pattern[i].color;
      if (color != ColorType.none) _emit(i, color, celebration: true);
    }
  }

  void _syncCosmetic() {
    final wants =
        !_reduceMotion &&
        (_animationId == 'pulse_animation' ||
            _animationId == 'bounce_animation' ||
            _animationId == 'sparkle_animation');
    if (wants && !_motion.cosmetic.isAnimating) {
      _motion.cosmetic.repeat();
    } else if (!wants && _motion.cosmetic.isAnimating) {
      _motion.cosmetic.stop();
      _motion.cosmetic.value = 0;
    }
  }

  /// Sparkle: a few stars twinkle on colored tiles once per cycle
  void _onCosmeticTick() {
    final v = _motion.cosmetic.value;
    final wrapped = v < _lastCosmeticValue;
    _lastCosmeticValue = v;
    if (!wrapped || _animationId != 'sparkle_animation') return;
    if (!(_game.isPreview || _game.isRebuild)) return;

    final cells = _game.isPreview ? _game.targetPattern : _game.userPattern;
    final colored = [
      for (int i = 0; i < cells.length; i++)
        if (cells[i].color != ColorType.none) i,
    ];
    if (colored.isEmpty) return;
    for (int n = 0; n < min(2, colored.length); n++) {
      final i = colored[_random.nextInt(colored.length)];
      _particles.burst(
        _centerOf(i),
        Colors.white,
        count: 3,
        distance: _cellSize * 0.45,
        size: _cellSize * 0.16,
        shape: ParticleShape.star,
      );
    }
  }

  Offset _centerOf(int index) {
    final size = _game.currentLevel.gridSize;
    return Offset(
      _trayPadding + (index % size) * _cellStep + _cellSize / 2,
      _trayPadding + (index ~/ size) * _cellStep + _cellSize / 2,
    );
  }

  /// Particles for a tile. Purchased animations throw more than the default.
  void _emit(int index, ColorType color, {bool celebration = false}) {
    if (_reduceMotion || _cellSize == 0) return;
    final tone = context.read<ThemeProvider>().palette.toneOf(color);
    final center = _centerOf(index);
    final base = celebration ? 6 : 10;

    switch (_animationId) {
      case 'sparkle_animation':
        _particles.burst(
          center,
          tone.face,
          count: base + 4,
          distance: _cellSize * 0.95,
          size: _cellSize * 0.2,
          shape: ParticleShape.star,
        );
        _particles.burst(
          center,
          Colors.white,
          count: 4,
          distance: _cellSize * 0.6,
          size: _cellSize * 0.13,
          shape: ParticleShape.star,
        );
        break;
      case 'pulse_animation':
        _particles.ring(
          center,
          tone.face,
          size: _cellSize,
          radius: _cellSize * 0.2,
        );
        _particles.burst(
          center,
          tone.face,
          count: base,
          distance: _cellSize * 0.8,
          size: _cellSize * 0.13,
        );
        break;
      case 'bounce_animation':
        _particles.burst(
          center,
          tone.face,
          count: base + 2,
          distance: _cellSize * 1.05,
          size: _cellSize * 0.15,
        );
        break;
      default:
        _particles.burst(
          center,
          tone.face,
          count: base,
          distance: _cellSize * 0.8,
          size: _cellSize * 0.13,
        );
    }
  }

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
    if (animationId != _animationId) {
      _animationId = animationId;
      _syncCosmetic();
    }

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

    final cellSpacing = widget.isSmallScreen ? 6.0 : 8.0;
    final trayPadding = widget.isSmallScreen ? 8.0 : 10.0;
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

        _trayPadding = trayPadding;
        _cellSize =
            (gridSize - 2 * trayPadding - (size - 1) * cellSpacing) / size;
        _cellStep = _cellSize + cellSpacing;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridSize,
            height: gridSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _motion.pulse,
                      builder: (context, child) {
                        final t = _motion.pulse.value;
                        // One short dip to 0.97 when the pattern disappears
                        final dip = t >= 1 ? 0.0 : sin(t * pi);
                        return Transform.scale(
                          scale: 1 - 0.03 * dip,
                          child: child,
                        );
                      },
                      child: TactileWell(
                        color: palette.backgroundDeep,
                        radius: style.trayRadius,
                        borderColor: style.trayBorder,
                        borderWidth: style.trayBorderWidth,
                        glow: style.trayGlow,
                        padding: EdgeInsets.all(trayPadding),
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          clipBehavior: Clip.none,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                            final color = cells[index].color;

                            return _GridCell(
                              key: ValueKey('cell_$index'),
                              index: index,
                              gridSize: size,
                              color: color,
                              tone: palette.toneOf(color),
                              errorColor: palette.danger.face,
                              isInteractive: isInteractive,
                              isErrorCell: isErrorCell,
                              style: style,
                              animationId: animationId,
                              motion: _motion,
                              reduceMotion: _reduceMotion,
                              onPlaced: () => _emit(index, color),
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
                ),
                Positioned.fill(child: ParticleField(controller: _particles)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridCell extends StatefulWidget {
  final int index;
  final int gridSize;
  final ColorType color;
  final TactileTone tone;
  final Color errorColor;
  final bool isInteractive;
  final bool isErrorCell;
  final GridStyleSpec style;
  final String animationId;
  final _GridMotion motion;
  final bool reduceMotion;
  final VoidCallback onPlaced;
  final VoidCallback onTap;

  const _GridCell({
    super.key,
    required this.index,
    required this.gridSize,
    required this.color,
    required this.tone,
    required this.errorColor,
    required this.isInteractive,
    this.isErrorCell = false,
    required this.style,
    required this.animationId,
    required this.motion,
    required this.reduceMotion,
    required this.onPlaced,
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
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: TactileDurations.pop,
    value: 1,
  );
  late final AnimationController _clear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
    value: 1,
  );
  late final AnimationController _errorRing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Listenable _listenable = Listenable.merge([
    _press,
    _pop,
    _clear,
    _errorRing,
    widget.motion.entrance,
    widget.motion.wave,
    widget.motion.wiggle,
    widget.motion.cosmetic,
  ]);

  TactileTone? _clearedTone;
  bool _errorShown = false;

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

    if (oldWidget.color != widget.color && !widget.reduceMotion) {
      if (widget.color == ColorType.none) {
        // Tile leaves: the old color shrinks away over the empty well
        _clearedTone = oldWidget.tone;
        _clear.forward(from: 0);
      } else if (widget.isInteractive) {
        // Placed by a tap or a hint
        _pop.forward(from: 0);
        widget.onPlaced();
      }
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _pop.dispose();
    _clear.dispose();
    _errorRing.dispose();
    super.dispose();
  }

  /// 0..1 wave for the looping cosmetic animations, offset per diagonal
  double _cosmeticWave() {
    final diagonal =
        (widget.index ~/ widget.gridSize) + (widget.index % widget.gridSize);
    final v = widget.motion.cosmetic.value - diagonal * 0.09;
    return 0.5 - 0.5 * cos(v * 2 * pi);
  }

  @override
  Widget build(BuildContext context) {
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
        animation: _listenable,
        builder: (context, child) {
          final motion = widget.motion;
          final entranceT = motion.entranceProgress(widget.index);
          // Before its turn in the cascade a pattern tile still shows empty
          final waiting = entranceT != null && entranceT <= 0;
          final isEmpty = widget.color == ColorType.none || waiting;

          double scale = 1;
          double dx = 0;
          double dy = 0;

          if (entranceT != null && entranceT > 0) {
            scale *= TactileCurves.popScale.transform(entranceT);
          }
          if (_pop.isAnimating) {
            final pop = TactileCurves.popScale.transform(_pop.value);
            // Bounce pack: a much springier landing
            scale *= widget.animationId == 'bounce_animation'
                ? 1 + (pop - 1) * 2.2
                : pop;
          }

          final hopT = motion.waveProgress(widget.index);
          if (hopT != null && hopT > 0 && !isEmpty) {
            final hop = TactileCurves.hop.transform(hopT);
            dy -= hop * 14;
            scale *= 1 + hop * 0.08;
          }

          if (widget.isErrorCell && motion.wiggle.isAnimating) {
            final t = motion.wiggle.value;
            dx += sin(t * pi * 6) * 6 * (1 - t);
          }

          // Looping cosmetic animations, on top of everything above
          double cosmeticGlow = 0;
          if (!isEmpty && motion.cosmetic.isAnimating) {
            final wave = _cosmeticWave();
            switch (widget.animationId) {
              case 'pulse_animation':
                scale *= 1.0 + wave * 0.07;
                cosmeticGlow = wave * 0.5;
                break;
              case 'bounce_animation':
                // Hop with a squash on landing
                final up = Curves.easeOut.transform(wave);
                dy -= up * 7;
                scale *= 1.0 + up * 0.05;
                break;
              case 'sparkle_animation':
                cosmeticGlow = 0.2 + wave * 0.6;
                break;
            }
          }

          final errorAlpha = widget.isErrorCell ? 1.0 - _errorRing.value : 0.0;
          final haloAlpha = isEmpty
              ? 0.0
              : (style.cellHaloAlpha + cosmeticGlow * 0.45).clamp(0.0, 0.7);
          final tone = waiting ? _wellTone(context) : widget.tone;

          Widget tile = TactileCell(
            tone: tone,
            radius: style.cellRadius,
            filled: !isEmpty,
            press: Curves.easeOut.transform(_press.value),
            ringColor: errorAlpha > 0
                ? widget.errorColor.withValues(alpha: errorAlpha)
                : (isEmpty ? null : style.cellRing),
            ringWidth: errorAlpha > 0 ? 3 : style.cellRingWidth,
            haloColor: haloAlpha > 0
                ? tone.face.withValues(alpha: haloAlpha)
                : null,
          );

          if (_clear.isAnimating && _clearedTone != null) {
            final t = Curves.easeIn.transform(_clear.value);
            tile = Stack(
              fit: StackFit.expand,
              children: [
                tile,
                Transform.scale(
                  scale: 1 - t,
                  child: TactileCell(
                    tone: _clearedTone!,
                    radius: style.cellRadius,
                  ),
                ),
              ],
            );
          }

          if (scale == 1 && dx == 0 && dy == 0) return tile;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(scale: scale, child: tile),
          );
        },
      ),
    );
  }

  TactileTone _wellTone(BuildContext context) =>
      context.read<ThemeProvider>().palette.well;
}
