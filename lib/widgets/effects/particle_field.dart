import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../theme/tactile_tokens.dart';

enum ParticleShape { chip, star }

/// Fixed pool of particles plus expanding rings. Nothing is allocated while
/// the game runs; a burst just reuses free slots.
class ParticleController extends ChangeNotifier {
  ParticleController({this.capacity = 220, this.ringCapacity = 12})
    : _x = Float32List(capacity),
      _y = Float32List(capacity),
      _dx = Float32List(capacity),
      _dy = Float32List(capacity),
      _size = Float32List(capacity),
      _spin = Float32List(capacity),
      _age = Float32List(capacity),
      _life = Float32List(capacity),
      _color = Int32List(capacity),
      _shape = Uint8List(capacity),
      _alive = Uint8List(capacity),
      _rx = Float32List(ringCapacity),
      _ry = Float32List(ringCapacity),
      _rSize = Float32List(ringCapacity),
      _rRadius = Float32List(ringCapacity),
      _rAge = Float32List(ringCapacity),
      _rColor = Int32List(ringCapacity),
      _rAlive = Uint8List(ringCapacity);

  final int capacity;
  final int ringCapacity;

  final Float32List _x, _y, _dx, _dy, _size, _spin, _age, _life;
  final Int32List _color;
  final Uint8List _shape, _alive;

  final Float32List _rx, _ry, _rSize, _rRadius, _rAge;
  final Int32List _rColor;
  final Uint8List _rAlive;

  final Random _random = Random();
  int _cursor = 0;
  int _liveCount = 0;
  VoidCallback? _onWake;

  bool get hasLive => _liveCount > 0;

  static final double _lifeSeconds =
      TactileDurations.particles.inMilliseconds / 1000.0;

  /// Throws [count] particles outwards from [center]
  void burst(
    Offset center,
    Color color, {
    int count = 10,
    double distance = 46,
    double size = 7,
    ParticleShape shape = ParticleShape.chip,
  }) {
    final light = Color.lerp(color, Colors.white, 0.35)!.toARGB32();
    final base = color.toARGB32();
    for (int n = 0; n < count; n++) {
      final i = _freeSlot();
      final angle =
          (n / count) * 2 * pi + (_random.nextDouble() - 0.5) * (pi / count);
      final reach = distance * (0.55 + _random.nextDouble() * 0.6);
      _x[i] = center.dx;
      _y[i] = center.dy;
      _dx[i] = cos(angle) * reach;
      _dy[i] = sin(angle) * reach;
      _size[i] = size * (0.6 + _random.nextDouble() * 0.7);
      _spin[i] = (_random.nextDouble() - 0.5) * 6;
      _age[i] = 0;
      _life[i] = _lifeSeconds * (0.8 + _random.nextDouble() * 0.35);
      _color[i] = n.isEven ? base : light;
      _shape[i] = shape.index;
      if (_alive[i] == 0) {
        _alive[i] = 1;
        _liveCount++;
      }
    }
    _onWake?.call();
  }

  /// Expanding outline that starts at the size of a tile
  void ring(Offset center, Color color, {double size = 40, double radius = 8}) {
    int slot = 0;
    for (int i = 0; i < ringCapacity; i++) {
      if (_rAlive[i] == 0) {
        slot = i;
        break;
      }
      if (_rAge[i] > _rAge[slot]) slot = i;
    }
    _rx[slot] = center.dx;
    _ry[slot] = center.dy;
    _rSize[slot] = size;
    _rRadius[slot] = radius;
    _rAge[slot] = 0;
    _rColor[slot] = color.toARGB32();
    if (_rAlive[slot] == 0) {
      _rAlive[slot] = 1;
      _liveCount++;
    }
    _onWake?.call();
  }

  int _freeSlot() {
    for (int n = 0; n < capacity; n++) {
      final i = (_cursor + n) % capacity;
      if (_alive[i] == 0) {
        _cursor = (i + 1) % capacity;
        return i;
      }
    }
    // Pool exhausted: recycle the next slot in line
    final i = _cursor;
    _cursor = (i + 1) % capacity;
    return i;
  }

  void _advance(double dt) {
    for (int i = 0; i < capacity; i++) {
      if (_alive[i] == 0) continue;
      _age[i] += dt;
      if (_age[i] >= _life[i]) {
        _alive[i] = 0;
        _liveCount--;
      }
    }
    for (int i = 0; i < ringCapacity; i++) {
      if (_rAlive[i] == 0) continue;
      _rAge[i] += dt;
      if (_rAge[i] >= _lifeSeconds) {
        _rAlive[i] = 0;
        _liveCount--;
      }
    }
    notifyListeners();
  }

  void clear() {
    _alive.fillRange(0, capacity, 0);
    _rAlive.fillRange(0, ringCapacity, 0);
    _liveCount = 0;
    notifyListeners();
  }
}

/// Paint layer for a [ParticleController]. Its ticker only runs while
/// something is alive.
class ParticleField extends StatefulWidget {
  final ParticleController controller;

  const ParticleField({super.key, required this.controller});

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller._onWake = _wake;
  }

  @override
  void didUpdateWidget(ParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._onWake = null;
      widget.controller._onWake = _wake;
    }
  }

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    widget.controller._advance(dt.clamp(0.0, 0.05));
    if (!widget.controller.hasLive) _ticker.stop();
  }

  @override
  void dispose() {
    widget.controller._onWake = null;
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ParticlePainter(widget.controller),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.c) : super(repaint: c);

  final ParticleController c;
  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;
  static final Path _star = _buildStar();

  static Path _buildStar() {
    // Four-point sparkle in a unit box
    final path = Path();
    for (int k = 0; k < 8; k++) {
      final r = k.isEven ? 1.0 : 0.32;
      final a = k * pi / 4 - pi / 2;
      final p = Offset(cos(a) * r, sin(a) * r);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!c.hasLive) return;

    for (int i = 0; i < c.ringCapacity; i++) {
      if (c._rAlive[i] == 0) continue;
      final t = (c._rAge[i] / ParticleController._lifeSeconds).clamp(0.0, 1.0);
      final e = TactileCurves.particles.transform(t);
      final grow = c._rSize[i] * (1 + e * 0.9);
      _stroke
        ..strokeWidth = 4 * (1 - e) + 1
        ..color = Color(c._rColor[i]).withValues(alpha: (1 - t) * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c._rx[i], c._ry[i]),
            width: grow,
            height: grow,
          ),
          Radius.circular(c._rRadius[i] * (1 + e)),
        ),
        _stroke,
      );
    }

    for (int i = 0; i < c.capacity; i++) {
      if (c._alive[i] == 0) continue;
      final t = (c._age[i] / c._life[i]).clamp(0.0, 1.0);
      final e = TactileCurves.particles.transform(t);
      final x = c._x[i] + c._dx[i] * e;
      // A little gravity so the chips fall out of the burst
      final y = c._y[i] + c._dy[i] * e + 26 * t * t;
      final s = c._size[i] * (1 - t * 0.55);
      _fill.color = Color(c._color[i]).withValues(alpha: 1 - t * t);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c._spin[i] * e);
      if (c._shape[i] == ParticleShape.star.index) {
        canvas.scale(s * 0.95);
        canvas.drawPath(_star, _fill);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s, height: s),
            Radius.circular(s * 0.3),
          ),
          _fill,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => oldDelegate.c != c;
}
