import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/tactile_palette.dart';
import '../../theme/tactile_tokens.dart';
import 'grid_collapse.dart';

/// Mini board that plays a lose animation in a loop, for the shop
class GridCollapsePreview extends StatefulWidget {
  final GridCollapseKind kind;
  final TactilePalette palette;
  final double size;

  const GridCollapsePreview({
    super.key,
    required this.kind,
    required this.palette,
    this.size = 52,
  });

  @override
  State<GridCollapsePreview> createState() => _GridCollapsePreviewState();
}

class _GridCollapsePreviewState extends State<GridCollapsePreview>
    with SingleTickerProviderStateMixin {
  // Whole board, the collapse, then a beat of empty tray
  static const double _holdMs = 600;
  static const double _playMs = 1000;
  static const double _restMs = 500;

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_holdMs + _playMs + _restMs).round()),
  );
  late final Animation<double> _progress = _loop.drive(_LoopProgress());

  GridCollapseScene? _scene;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _loop.stop();
      _loop.value = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void didUpdateWidget(GridCollapsePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind ||
        oldWidget.palette != widget.palette ||
        oldWidget.size != widget.size) {
      _scene?.dispose();
      _scene = null;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _scene?.dispose();
    super.dispose();
  }

  GridCollapseScene _buildScene() {
    final palette = widget.palette;
    const pad = 5.0;
    const gap = 3.0;
    final cell = (widget.size - 2 * pad - gap) / 2;
    return GridCollapseScene.build(
      kind: widget.kind,
      boardSize: widget.size,
      radius: 5,
      socketTone: palette.well,
      random: Random(widget.kind.index + 1),
      cells: [
        for (int i = 0; i < 4; i++)
          GridCollapseCell(
            index: i,
            rect: Rect.fromLTWH(
              pad + (i % 2) * (cell + gap),
              pad + (i ~/ 2) * (cell + gap),
              cell,
              cell,
            ),
            tone: palette.gameTones[i % palette.gameTones.length],
            filled: true,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene ??= _buildScene();
    return ClipRRect(
      borderRadius: BorderRadius.circular(TactileRadii.sm),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: widget.palette.backgroundDeep,
        child: GridCollapseLayer(scene: scene, animation: _progress),
      ),
    );
  }
}

/// Maps one loop to the collapse: 0 while the board holds, 0..1 while it
/// plays, 1 while the tray rests empty
class _LoopProgress extends Animatable<double> {
  static const double _total =
      _GridCollapsePreviewState._holdMs +
      _GridCollapsePreviewState._playMs +
      _GridCollapsePreviewState._restMs;

  @override
  double transform(double t) =>
      ((t * _total - _GridCollapsePreviewState._holdMs) /
              _GridCollapsePreviewState._playMs)
          .clamp(0.0, 1.0);
}
