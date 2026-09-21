import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../tactile/tactile.dart';

/// Timer bar that drains continuously. The provider only ticks every 100 ms,
/// so the bar runs its own linear animation over the remaining time and
/// resyncs when it drifts from the real timer.
class TimerBar extends StatefulWidget {
  final TactilePalette palette;

  const TimerBar({super.key, required this.palette});

  @override
  State<TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar> with TickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    value: 1,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final GameProvider _game;
  GameState? _syncedState;
  double _syncedMax = 0;
  bool _reduceMotion = false;

  static const double _warningSeconds = 2;

  @override
  void initState() {
    super.initState();
    _game = context.read<GameProvider>();
    _game.addListener(_onGameChanged);
    _game.timerListenable.addListener(_onTick);
    _progress.addListener(_updatePulse);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_syncedState == null) _onGameChanged();
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.timerListenable.removeListener(_onTick);
    _progress.dispose();
    _pulse.dispose();
    super.dispose();
  }

  bool get _clockRuns => _game.isPreview || _game.isRebuild;

  /// Only a new phase restarts the drain; taps and hints must not nudge it
  void _onGameChanged() {
    final state = _game.gameState;
    if (state == _syncedState && _game.maxTimer == _syncedMax) return;
    _syncedState = state;
    _syncedMax = _game.maxTimer;
    _sync();
  }

  /// Restart the drain from the provider's real values
  void _sync() {
    if (_clockRuns) {
      _progress.value = _game.timerProgress.clamp(0.0, 1.0);
      _progress.animateTo(
        0,
        duration: Duration(milliseconds: (_game.timer * 1000).round()),
        curve: Curves.linear,
      );
    } else {
      _progress.stop();
    }
  }

  void _onTick() {
    if (!_clockRuns) return;
    final shown = _progress.value * _game.maxTimer;
    if (!_progress.isAnimating || (shown - _game.timer).abs() > 0.25) _sync();
  }

  void _updatePulse() {
    final remaining = _progress.value * _game.maxTimer;
    final warn =
        _clockRuns &&
        remaining < _warningSeconds &&
        remaining > 0 &&
        !_reduceMotion;
    if (warn && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!warn && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final isPreview = context.select<GameProvider, bool>((g) => g.isPreview);
    final calm = isPreview ? palette.cta : palette.primary;
    final urgent = isPreview ? TactileColors.orange : palette.danger;

    return RepaintBoundary(
      child: TactileWell(
        color: palette.backgroundDeep,
        radius: TactileRadii.pill,
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          width: double.infinity,
          height: 10,
          child: AnimatedBuilder(
            animation: Listenable.merge([_progress, _pulse]),
            builder: (context, _) {
              final value = _progress.value.clamp(0.0, 1.0);
              final remaining = value * _game.maxTimer;
              // Blend into the warning color over the last half second
              // before the 2 s mark
              final heat = _clockRuns
                  ? ((_warningSeconds + 0.5 - remaining) / 0.5).clamp(0.0, 1.0)
                  : 0.0;
              final face = Color.lerp(calm.face, urgent.face, heat)!;
              final lip = Color.lerp(calm.lip, urgent.lip, heat)!;
              final swell = 1 + 0.35 * sin(_pulse.value * pi / 2);

              return Transform.scale(
                scaleY: swell,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TactileRadii.pill),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(face, Colors.white, 0.2)!,
                          face,
                          lip,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
