import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/tactile_tokens.dart';
import '../tactile/tactile_surface.dart';

/// The ways a lost board falls apart
enum GridCollapseKind {
  /// The whole field is blown out of the tray
  explode,

  /// Tiles crack like glass and the shards drop
  shatter,

  /// The floor gives way and the tiles fall through the grid
  fallThrough;

  /// Kind behind an equipped lose animation, null for the plain default
  static GridCollapseKind? ofCosmetic(String cosmeticId) {
    switch (cosmeticId) {
      case 'explode_lose':
        return GridCollapseKind.explode;
      case 'shatter_lose':
        return GridCollapseKind.shatter;
      case 'fall_lose':
        return GridCollapseKind.fallThrough;
      default:
        return null;
    }
  }
}

/// One cell as the collapse layer has to draw it
class GridCollapseCell {
  final int index;
  final Rect rect;
  final TactileTone tone;
  final bool filled;

  const GridCollapseCell({
    required this.index,
    required this.rect,
    required this.tone,
    required this.filled,
  });
}

class _Shard {
  _Shard(this.path, this.centroid, this.velocity, this.spin, this.delay);

  final Path path;
  final Offset centroid;

  /// In tile sizes per unit of fall time
  final Offset velocity;
  final double spin;
  final double delay;
}

class _Piece {
  _Piece(this.cell, this.picture);

  final GridCollapseCell cell;
  final ui.Picture picture;

  /// Start within the sequence, 0..1
  double delay = 0;
  Offset direction = Offset.zero;
  double reach = 0;
  double spin = 0;
  double depth = 1;
  double phase = 0;

  // Shatter only
  Offset impact = Offset.zero;
  List<Offset> rim = const [];
  List<_Shard> shards = const [];
}

/// Everything random about one collapse, rolled once so every frame of the
/// sequence paints the same pieces. Tiles are recorded into pictures up
/// front; a frame only moves and clips them.
class GridCollapseScene {
  GridCollapseScene._(this.kind, this.boardSize, this.radius, this._pieces);

  final GridCollapseKind kind;
  final double boardSize;
  final double radius;
  final List<_Piece> _pieces;
  final Map<int, ui.Picture> _sockets = {};

  /// Part of the explosion spent pulling together before the blast
  static const double charge = 0.14;

  /// Longest start delay and the share of a tile's own time spent cracking
  static const double _shatterSpread = 0.3;
  static const double _crack = 0.22;
  static const double _fallSpread = 0.45;
  static const double _wobble = 0.25;

  factory GridCollapseScene.build({
    required GridCollapseKind kind,
    required List<GridCollapseCell> cells,
    required double boardSize,
    required double radius,
    required TactileTone socketTone,
    Color? ringColor,
    double ringWidth = 0,
    Random? random,
  }) {
    final rng = random ?? Random();
    final center = Offset(boardSize / 2, boardSize / 2);
    final pieces = <_Piece>[];

    for (final cell in cells) {
      // Only an explosion takes the empty sockets with it
      if (!cell.filled && kind != GridCollapseKind.explode) continue;

      final piece = _Piece(
        cell,
        _record(
          cell.rect.size,
          cell.tone,
          radius,
          filled: cell.filled,
          ringColor: cell.filled ? ringColor : null,
          ringWidth: ringWidth,
        ),
      )..phase = rng.nextDouble() * 2 * pi;

      switch (kind) {
        case GridCollapseKind.explode:
          final away = cell.rect.center - center;
          final angle = away.distance < 1
              ? rng.nextDouble() * 2 * pi
              : away.direction + (rng.nextDouble() - 0.5) * 0.7;
          piece
            ..direction = Offset(cos(angle), sin(angle))
            ..reach = boardSize * (0.9 + rng.nextDouble() * 0.9)
            ..spin = (rng.nextDouble() - 0.5) * 9
            ..depth = 0.65 + rng.nextDouble() * 0.85;
          break;
        case GridCollapseKind.shatter:
          piece.delay = rng.nextDouble() * _shatterSpread;
          _crackPiece(piece, rng);
          break;
        case GridCollapseKind.fallThrough:
          piece
            ..delay = rng.nextDouble() * _fallSpread
            ..spin = (rng.nextBool() ? 1 : -1) * (0.5 + rng.nextDouble() * 0.7);
          break;
      }
      pieces.add(piece);
    }

    final scene = GridCollapseScene._(kind, boardSize, radius, pieces);
    if (kind == GridCollapseKind.shatter) {
      // The socket a broken tile leaves behind
      for (final piece in pieces) {
        scene._sockets[piece.cell.index] = _record(
          piece.cell.rect.size,
          socketTone,
          radius,
          filled: false,
        );
      }
    }
    return scene;
  }

  static ui.Picture _record(
    Size size,
    TactileTone tone,
    double radius, {
    required bool filled,
    Color? ringColor,
    double ringWidth = 0,
  }) {
    final recorder = ui.PictureRecorder();
    TactilePainter(
      tone: tone,
      radius: radius,
      depth: filled ? TactileDepth.regular : TactileDepth.small,
      sheen: filled,
      ringColor: ringColor,
      ringWidth: ringWidth,
    ).paint(Canvas(recorder), size);
    return recorder.endRecording();
  }

  /// Breaks a tile into shards that radiate from one impact point
  static void _crackPiece(_Piece piece, Random rng) {
    final w = piece.cell.rect.width;
    final h = piece.cell.rect.height;
    final impact = Offset(
      w * (0.3 + rng.nextDouble() * 0.4),
      h * (0.3 + rng.nextDouble() * 0.4),
    );

    // Corners plus one or two breaks per edge, clockwise
    final corners = [Offset.zero, Offset(w, 0), Offset(w, h), Offset(0, h)];
    final rim = <Offset>[];
    for (int e = 0; e < 4; e++) {
      final a = corners[e];
      final b = corners[(e + 1) % 4];
      rim.add(a);
      final cuts = rng.nextBool() ? [0.5] : [0.33, 0.68];
      for (final cut in cuts) {
        rim.add(Offset.lerp(a, b, cut + (rng.nextDouble() - 0.5) * 0.2)!);
      }
    }

    final shards = <_Shard>[];
    void add(List<Offset> points) {
      final path = Path()..addPolygon(points, true);
      final centroid =
          points.reduce((a, b) => a + b) / points.length.toDouble();
      final away = centroid - impact;
      final push = away.distance < 1 ? Offset.zero : away / away.distance;
      shards.add(
        _Shard(
          path,
          centroid,
          Offset(
            push.dx * (0.25 + rng.nextDouble() * 0.5),
            push.dy * 0.25 - rng.nextDouble() * 0.35,
          ),
          (rng.nextDouble() - 0.5) * 7,
          rng.nextDouble() * 0.18,
        ),
      );
    }

    for (int i = 0; i < rim.length; i++) {
      final a = rim[i];
      final b = rim[(i + 1) % rim.length];
      if (rng.nextDouble() < 0.55) {
        // A second ring of cracks splits the wedge in two
        final f = 0.35 + rng.nextDouble() * 0.25;
        final a2 = Offset.lerp(impact, a, f)!;
        final b2 = Offset.lerp(impact, b, f)!;
        add([impact, a2, b2]);
        add([a2, a, b, b2]);
      } else {
        add([impact, a, b]);
      }
    }

    piece
      ..impact = impact
      ..rim = rim
      ..shards = shards;
  }

  late final Set<int> _taken = {for (final p in _pieces) p.cell.index};

  /// Whether the scene draws this cell in place of the grid
  bool hides(int index) => _taken.contains(index);

  /// Moment in the sequence (0..1) at which each colored tile breaks, for
  /// particles and haptics. Falling tiles leave without one.
  Map<int, double> get impacts => {
    for (final piece in _pieces)
      if (piece.cell.filled && kind != GridCollapseKind.fallThrough)
        piece.cell.index: kind == GridCollapseKind.explode
            ? charge
            : piece.delay + _crack * (1 - _shatterSpread),
  };

  /// Scale and offset of the tray itself: it braces, then takes the blast
  ({double scale, Offset offset}) trayJolt(double t) {
    if (kind != GridCollapseKind.explode || t >= 1) {
      return (scale: 1.0, offset: Offset.zero);
    }
    if (t < charge) {
      final c = Curves.easeIn.transform(t / charge);
      return (scale: 1 - 0.035 * c, offset: Offset.zero);
    }
    final b = (t - charge) / (1 - charge);
    final decay = pow(1 - b, 3).toDouble();
    return (
      scale: 1 + 0.06 * decay,
      offset: Offset(sin(b * pi * 11) * 9 * decay, cos(b * pi * 8) * 4 * decay),
    );
  }

  void dispose() {
    for (final piece in _pieces) {
      piece.picture.dispose();
    }
    for (final socket in _sockets.values) {
      socket.dispose();
    }
  }
}

/// Paints a [GridCollapseScene] over the board while [animation] runs from
/// 0 to 1. The grid leaves out the cells the scene has taken over.
class GridCollapseLayer extends StatelessWidget {
  final GridCollapseScene scene;
  final Animation<double> animation;

  const GridCollapseLayer({
    super.key,
    required this.scene,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _CollapsePainter(scene, animation),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CollapsePainter extends CustomPainter {
  _CollapsePainter(this.scene, this.animation) : super(repaint: animation);

  final GridCollapseScene scene;
  final Animation<double> animation;

  final Paint _flash = Paint();
  final Paint _wave = Paint()..style = PaintingStyle.stroke;
  final Paint _shade = Paint();
  final Paint _crackLine = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.85);
  final Paint _fracture = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _shardEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = Colors.white.withValues(alpha: 0.4);

  static const Color _blast = Color(0xFFFFE9C4);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    switch (scene.kind) {
      case GridCollapseKind.explode:
        _paintExplode(canvas, t);
        break;
      case GridCollapseKind.shatter:
        _paintShatter(canvas, t);
        break;
      case GridCollapseKind.fallThrough:
        _paintFallThrough(canvas, t);
        break;
    }
  }

  /// Leaving pieces shrink away instead of fading, which needs no layer
  double _vanish(double t, double from) =>
      t < from ? 1.0 : (1 - (t - from) / (1 - from)).clamp(0.0, 1.0);

  void _drawPiece(
    Canvas canvas,
    _Piece piece,
    Offset center, {
    double rotation = 0,
    double scale = 1,
  }) {
    if (scale <= 0) return;
    final size = piece.cell.rect.size;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (rotation != 0) canvas.rotate(rotation);
    if (scale != 1) canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawPicture(piece.picture);
    canvas.restore();
  }

  /// Fireball: white-hot core that thins out towards the rim
  void _drawFlash(Canvas canvas, Offset center, double radius, double alpha) {
    if (radius <= 0) return;
    _flash.shader = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.white.withValues(alpha: alpha),
        _blast.withValues(alpha: 0.75 * alpha),
        _blast.withValues(alpha: 0),
      ],
      const [0.0, 0.45, 1.0],
    );
    canvas.drawCircle(center, radius, _flash);
  }

  void _paintExplode(Canvas canvas, double t) {
    const charge = GridCollapseScene.charge;
    final board = scene.boardSize;
    final center = Offset(board / 2, board / 2);

    if (t < charge) {
      // The field pulls together and trembles
      final c = Curves.easeIn.transform(t / charge);
      for (final piece in scene._pieces) {
        final home = piece.cell.rect.center;
        final jitter = Offset(
          sin(t * 140 + piece.phase),
          cos(t * 120 + piece.phase),
        );
        _drawPiece(
          canvas,
          piece,
          Offset.lerp(home, center, 0.07 * c)! + jitter * 1.6 * c,
          scale: 1 - 0.08 * c,
        );
      }
      _drawFlash(canvas, center, board * 0.2 * c, 0.7 * c);
      return;
    }

    final b = (t - charge) / (1 - charge);
    final out = Curves.easeOutCubic.transform(b);
    final vanish = _vanish(b, 0.72);

    // Empty sockets first, so the colored tiles fly in front of them
    for (final filled in const [false, true]) {
      for (final piece in scene._pieces) {
        if (piece.cell.filled != filled) continue;
        final pos =
            piece.cell.rect.center +
            piece.direction * (piece.reach * out) +
            Offset(0, board * 0.85 * b * b);
        _drawPiece(
          canvas,
          piece,
          pos,
          rotation: piece.spin * (0.7 * out + 0.3 * b),
          scale: (1 + (piece.depth - 1) * out) * vanish,
        );
      }
    }

    final flashAlpha = (1 - b * 3.2).clamp(0.0, 1.0);
    if (flashAlpha > 0) {
      _drawFlash(canvas, center, board * (0.2 + 0.8 * out), flashAlpha);
    }
    final waveAlpha = (1 - b * 1.7).clamp(0.0, 1.0);
    if (waveAlpha > 0) {
      _wave
        ..strokeWidth = 10 * waveAlpha + 1
        ..color = Colors.white.withValues(alpha: 0.75 * waveAlpha);
      canvas.drawCircle(center, board * (0.2 + 0.95 * out), _wave);
    }
  }

  void _paintShatter(Canvas canvas, double t) {
    const span = 1 - GridCollapseScene._shatterSpread;
    const crack = GridCollapseScene._crack;

    for (final piece in scene._pieces) {
      final origin = piece.cell.rect.topLeft;
      final socket = scene._sockets[piece.cell.index];
      if (socket != null) {
        canvas.save();
        canvas.translate(origin.dx, origin.dy);
        canvas.drawPicture(socket);
        canvas.restore();
      }
    }

    for (final piece in scene._pieces) {
      final rect = piece.cell.rect;
      final local = ((t - piece.delay) / span).clamp(0.0, 1.0);

      if (local < crack) {
        // Still whole: cracks run from the impact point to the rim
        final k = Curves.easeOut.transform(local / crack);
        final jitter = local <= 0
            ? Offset.zero
            : Offset(sin(t * 160 + piece.phase), cos(t * 130 + piece.phase)) *
                  1.2;
        _drawPiece(canvas, piece, rect.center + jitter);
        if (k > 0) {
          final origin = rect.topLeft + jitter;
          canvas.save();
          canvas.clipRRect(
            RRect.fromRectAndRadius(
              origin & rect.size,
              Radius.circular(scene.radius),
            ),
          );
          final from = origin + piece.impact;
          for (final point in piece.rim) {
            canvas.drawLine(
              from,
              from + (point - piece.impact) * k,
              _crackLine,
            );
          }
          // The cross cracks follow once the long ones are through
          if (k > 0.5) {
            _fracture.color = Colors.white.withValues(alpha: (k - 0.5) * 1.3);
            canvas.translate(origin.dx, origin.dy);
            for (final shard in piece.shards) {
              canvas.drawPath(shard.path, _fracture);
            }
          }
          canvas.restore();
        }
        continue;
      }

      final s = (local - crack) / (1 - crack);
      for (final shard in piece.shards) {
        final fall = ((s - shard.delay) / (1 - shard.delay)).clamp(0.0, 1.0);
        final scale = _vanish(fall, 0.78);
        if (scale <= 0) continue;
        final offset =
            shard.velocity * (rect.width * fall) +
            Offset(0, scene.boardSize * 1.35 * fall * fall);

        canvas.save();
        canvas.translate(
          rect.left + shard.centroid.dx + offset.dx,
          rect.top + shard.centroid.dy + offset.dy,
        );
        canvas.rotate(shard.spin * fall);
        canvas.scale(scale);
        canvas.translate(-shard.centroid.dx, -shard.centroid.dy);
        canvas.save();
        canvas.clipPath(shard.path);
        canvas.drawPicture(piece.picture);
        canvas.restore();
        canvas.drawPath(shard.path, _shardEdge);
        canvas.restore();
      }
    }
  }

  void _paintFallThrough(Canvas canvas, double t) {
    const span = 1 - GridCollapseScene._fallSpread;
    const wobble = GridCollapseScene._wobble;
    final r = Radius.circular(scene.radius);

    for (final piece in scene._pieces) {
      final rect = piece.cell.rect;
      final local = ((t - piece.delay) / span).clamp(0.0, 1.0);

      if (local < wobble) {
        // The tile loses its footing
        final k = local / wobble;
        _drawPiece(
          canvas,
          piece,
          rect.center + Offset(0, 1.5 * k),
          rotation: sin(k * pi * 3) * 0.07 * k,
        );
        continue;
      }

      final f = (local - wobble) / (1 - wobble);
      final drop = Curves.easeInCubic.transform(f);

      // The floor is gone: a dark shaft where the tile sat
      final shaft = RRect.fromRectAndRadius(rect.deflate(1.5), r);
      _shade.color = Colors.black.withValues(
        alpha: 0.9 * (f * 5).clamp(0.0, 1.0),
      );
      canvas.drawRRect(shaft, _shade);

      final scale = 1 - drop;
      if (scale <= 0.01) continue;

      canvas.save();
      canvas.clipRRect(shaft);
      canvas.translate(
        rect.center.dx,
        rect.center.dy + rect.height * 0.12 * drop,
      );
      canvas.rotate(piece.spin * drop);
      canvas.scale(scale);
      canvas.translate(-rect.width / 2, -rect.height / 2);
      canvas.drawPicture(piece.picture);
      // Swallowed by the dark on the way down
      _shade.color = Colors.black.withValues(alpha: 0.8 * f);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & rect.size, r),
        _shade,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CollapsePainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.animation != animation;
}
