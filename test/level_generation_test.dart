import 'package:flutter_test/flutter_test.dart';
import 'package:grid_master/constants/game_constants.dart';
import 'package:grid_master/models/game_models.dart';

void main() {
  group('generateLevels', () {
    final generated = generateLevels();

    LevelConfig level(int id) => generated[id - 1];

    void expectLevel(
      int id, {
      required int gridSize,
      required int colorCount,
      required int patternSize,
      required double previewSeconds,
      required String difficulty,
    }) {
      final l = level(id);
      expect(l.id, id);
      expect(l.gridSize, gridSize, reason: 'gridSize of level $id');
      expect(l.colorCount, colorCount, reason: 'colorCount of level $id');
      expect(l.patternSize, patternSize, reason: 'patternSize of level $id');
      expect(
        l.previewSeconds,
        previewSeconds,
        reason: 'previewSeconds of level $id',
      );
      expect(l.difficulty, difficulty, reason: 'difficulty of level $id');
    }

    test('generates exactly 200 levels with sequential ids', () {
      expect(generated.length, 200);
      for (int i = 0; i < generated.length; i++) {
        expect(generated[i].id, i + 1);
      }
      expect(levels.length, 200);
    });

    test('level 1', () {
      expectLevel(
        1,
        gridSize: 3,
        colorCount: 3,
        patternSize: 4,
        previewSeconds: 5.5,
        difficulty: 'difficulty_beginner',
      );
    });

    test('level 10', () {
      expectLevel(
        10,
        gridSize: 3,
        colorCount: 3,
        patternSize: 7,
        previewSeconds: 5.2,
        difficulty: 'difficulty_beginner',
      );
    });

    test('level 30', () {
      expectLevel(
        30,
        gridSize: 5,
        colorCount: 5,
        patternSize: 17,
        previewSeconds: 4.6,
        difficulty: 'difficulty_advanced',
      );
    });

    test('level 60', () {
      expectLevel(
        60,
        gridSize: 5,
        colorCount: 5,
        patternSize: 25,
        previewSeconds: 3.7,
        difficulty: 'difficulty_legend',
      );
    });

    test('level 200', () {
      expectLevel(
        200,
        gridSize: 5,
        colorCount: 5,
        patternSize: 25,
        previewSeconds: 2.5,
        difficulty: 'difficulty_legend',
      );
    });

    test('pattern always fits the grid and stays within bounds', () {
      for (final l in generated) {
        expect(l.patternSize, lessThanOrEqualTo(l.gridSize * l.gridSize));
        expect(l.patternSize, inInclusiveRange(4, 25));
        expect(l.gridSize, inInclusiveRange(3, 5));
        expect(l.colorCount, inInclusiveRange(3, 5));
        expect(l.previewSeconds, inInclusiveRange(2.5, 5.5));
      }
    });

    test('difficulty never decreases in pattern size', () {
      for (int i = 1; i < generated.length; i++) {
        expect(
          generated[i].patternSize,
          greaterThanOrEqualTo(generated[i - 1].patternSize),
        );
      }
    });

    test('colorOptions order is stable', () {
      expect(colorOptions, [
        ColorType.red,
        ColorType.blue,
        ColorType.green,
        ColorType.yellow,
        ColorType.purple,
        ColorType.orange,
        ColorType.pink,
      ]);
    });
  });
}
