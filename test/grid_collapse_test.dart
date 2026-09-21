import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_master/theme/tactile_tokens.dart';
import 'package:grid_master/widgets/effects/grid_collapse.dart';

const _board = 300.0;
const _tone = TactileTone(Color(0xFFE5484D), Color(0xFF8C1D22));
const _well = TactileTone(Color(0xFF1B2030), Color(0xFF10131C));

/// 3x3 board with a colored diagonal
GridCollapseScene _scene(GridCollapseKind kind) {
  const cell = 88.0;
  const step = 96.0;
  return GridCollapseScene.build(
    kind: kind,
    boardSize: _board,
    radius: 12,
    socketTone: _well,
    random: Random(7),
    cells: [
      for (int i = 0; i < 9; i++)
        GridCollapseCell(
          index: i,
          rect: Rect.fromLTWH(
            10 + (i % 3) * step,
            10 + (i ~/ 3) * step,
            cell,
            cell,
          ),
          tone: i % 4 == 0 ? _tone : _well,
          filled: i % 4 == 0,
        ),
    ],
  );
}

void main() {
  test('only an explosion takes the empty sockets with it', () {
    for (final kind in GridCollapseKind.values) {
      final scene = _scene(kind);
      expect(scene.hides(0), isTrue);
      expect(scene.hides(1), kind == GridCollapseKind.explode);
      scene.dispose();
    }
  });

  test('tiles break inside the sequence, falling tiles never do', () {
    for (final kind in GridCollapseKind.values) {
      final scene = _scene(kind);
      final impacts = scene.impacts;
      if (kind == GridCollapseKind.fallThrough) {
        expect(impacts, isEmpty);
      } else {
        expect(impacts.keys, unorderedEquals([0, 4, 8]));
        expect(impacts.values.every((t) => t > 0 && t < 1), isTrue);
      }
      scene.dispose();
    }
  });

  test('only an explosion rattles the tray, and it settles again', () {
    final explode = _scene(GridCollapseKind.explode);
    expect(explode.trayJolt(0.3).scale, greaterThan(1));
    expect(explode.trayJolt(1).scale, 1);
    expect(explode.trayJolt(1).offset, Offset.zero);
    explode.dispose();

    final shatter = _scene(GridCollapseKind.shatter);
    expect(shatter.trayJolt(0.3).scale, 1);
    shatter.dispose();
  });

  for (final kind in GridCollapseKind.values) {
    testWidgets('${kind.name} paints every frame of the sequence', (
      tester,
    ) async {
      final scene = _scene(kind);
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 1),
      );
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: _board,
            height: _board,
            child: GridCollapseLayer(scene: scene, animation: controller),
          ),
        ),
      );

      controller.forward();
      for (int frame = 0; frame < 24; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }
      expect(controller.isCompleted, isTrue);

      // The layer lets go of the controller before it is disposed
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      scene.dispose();
    });
  }
}
