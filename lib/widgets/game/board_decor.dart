import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/tactile_tokens.dart';

/// Symbol printed on every colored tile. The same symbol on every color, so
/// color alone still carries the pattern.
enum CellSprite {
  dot,
  gem,
  star,
  heart;

  static CellSprite? ofCosmetic(String id) {
    switch (id) {
      case 'dot_sprite':
        return CellSprite.dot;
      case 'gem_sprite':
        return CellSprite.gem;
      case 'star_sprite':
        return CellSprite.star;
      case 'heart_sprite':
        return CellSprite.heart;
      default:
        return null;
    }
  }

  /// Paints the sprite centered on [face] in a lighter shade of [tone]
  void paint(Canvas canvas, Rect face, TactileTone tone) {
    final side = min(face.width, face.height);
    if (side < 10) return;
    final c = face.center;
    final s = side * 0.26;
    final light = Paint()
      ..color = Color.lerp(
        tone.face,
        Colors.white,
        0.55,
      )!.withValues(alpha: 0.9);
    final dark = Paint()..color = tone.lip.withValues(alpha: 0.55);

    switch (this) {
      case CellSprite.dot:
        canvas.drawCircle(c.translate(0, s * 0.12), s * 0.62, dark);
        canvas.drawCircle(c, s * 0.62, light);
        break;
      case CellSprite.gem:
        final gem = Path()
          ..moveTo(c.dx, c.dy - s)
          ..lineTo(c.dx + s * 0.85, c.dy)
          ..lineTo(c.dx, c.dy + s)
          ..lineTo(c.dx - s * 0.85, c.dy)
          ..close();
        canvas.drawPath(gem.shift(Offset(0, s * 0.12)), dark);
        canvas.drawPath(gem, light);
        // Facet: the upper left quarter catches more light
        final facet = Path()
          ..moveTo(c.dx, c.dy - s)
          ..lineTo(c.dx, c.dy)
          ..lineTo(c.dx - s * 0.85, c.dy)
          ..close();
        canvas.drawPath(
          facet,
          Paint()..color = Colors.white.withValues(alpha: 0.45),
        );
        break;
      case CellSprite.star:
        final star = _starPath(c, s * 1.05, s * 0.45);
        canvas.drawPath(star.shift(Offset(0, s * 0.12)), dark);
        canvas.drawPath(star, light);
        break;
      case CellSprite.heart:
        final heart = _heartPath(c, s * 0.95);
        canvas.drawPath(heart.shift(Offset(0, s * 0.12)), dark);
        canvas.drawPath(heart, light);
        break;
    }
  }

  static Path _starPath(Offset c, double outer, double inner) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -pi / 2 + i * pi / 5;
      final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path _heartPath(Offset c, double s) {
    return Path()
      ..moveTo(c.dx, c.dy + s * 0.85)
      ..cubicTo(
        c.dx - s * 1.3,
        c.dy - s * 0.05,
        c.dx - s * 0.6,
        c.dy - s * 1.05,
        c.dx,
        c.dy - s * 0.35,
      )
      ..cubicTo(
        c.dx + s * 0.6,
        c.dy - s * 1.05,
        c.dx + s * 1.3,
        c.dy - s * 0.05,
        c.dx,
        c.dy + s * 0.85,
      )
      ..close();
  }
}

/// Decorative frame drawn over the rim of the board tray
enum BoardFrame {
  wood,
  candy,
  pixel,
  gold;

  static BoardFrame? ofCosmetic(String id) {
    switch (id) {
      case 'wood_frame':
        return BoardFrame.wood;
      case 'candy_frame':
        return BoardFrame.candy;
      case 'pixel_frame':
        return BoardFrame.pixel;
      case 'gold_frame':
        return BoardFrame.gold;
      default:
        return null;
    }
  }
}

/// Paints a [BoardFrame] inside the given size. The frame covers only the
/// tray padding, never a tile.
class BoardFramePainter extends CustomPainter {
  final BoardFrame frame;
  final double radius;
  final double width;

  const BoardFramePainter({
    required this.frame,
    required this.radius,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final band = outer.deflate(width / 2);

    switch (frame) {
      case BoardFrame.wood:
        _stroke(canvas, band, const Color(0xFF8A5A33), width);
        // Grain: thin darker and lighter rings along the band
        _stroke(
          canvas,
          band.deflate(width * 0.18),
          const Color(0xFF6E4424),
          width * 0.12,
        );
        _stroke(
          canvas,
          band.inflate(width * 0.22),
          const Color(0xFFB07A4A),
          width * 0.14,
        );
        _corners(canvas, size, const Color(0xFF4A2C16), width * 0.22);
        break;
      case BoardFrame.candy:
        canvas.save();
        canvas.clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRRect(outer)
            ..addRRect(outer.deflate(width)),
        );
        _stripes(canvas, size);
        canvas.restore();
        break;
      case BoardFrame.pixel:
        _pixels(canvas, size);
        break;
      case BoardFrame.gold:
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE9A3),
              Color(0xFFE0A93A),
              Color(0xFFFFF4C9),
              Color(0xFFB9791C),
            ],
            stops: [0.0, 0.4, 0.6, 1.0],
          ).createShader(Offset.zero & size);
        canvas.drawRRect(band, paint);
        _stroke(
          canvas,
          outer.deflate(width - 0.75),
          const Color(0xFF8C5A12),
          1.5,
        );
        _corners(canvas, size, const Color(0xFFFFF4C9), width * 0.3);
        break;
    }
  }

  void _stroke(Canvas canvas, RRect rrect, Color color, double strokeWidth) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  /// Studs in the four corners
  void _corners(Canvas canvas, Size size, Color color, double r) {
    final inset = width / 2 + radius * 0.3;
    for (final c in [
      Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      canvas.drawCircle(c, r, Paint()..color = color);
    }
  }

  void _stripes(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFF3F6),
    );
    final red = Paint()
      ..color = const Color(0xFFFF5A7A)
      ..strokeWidth = width * 0.9;
    final step = width * 1.8;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), red);
    }
  }

  /// Blocky border of alternating squares
  void _pixels(Canvas canvas, Size size) {
    final block = width;
    final a = Paint()..color = const Color(0xFF3BA3F5);
    final b = Paint()..color = const Color(0xFF9D7BFF);
    void square(double x, double y, int k) {
      canvas.drawRect(Rect.fromLTWH(x, y, block, block), k.isEven ? a : b);
    }

    final nx = (size.width / block).floor();
    final ny = (size.height / block).floor();
    final dx = (size.width - nx * block) / 2;
    final dy = (size.height - ny * block) / 2;
    for (int x = 0; x < nx; x++) {
      square(dx + x * block, 0, x);
      square(dx + x * block, size.height - block, x + ny - 1);
    }
    for (int y = 1; y < ny - 1; y++) {
      square(0, dy + y * block, y);
      square(size.width - block, dy + y * block, y + nx - 1);
    }
  }

  @override
  bool shouldRepaint(BoardFramePainter old) =>
      old.frame != frame || old.radius != radius || old.width != width;
}
