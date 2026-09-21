import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_master/constants/game_constants.dart';
import 'package:grid_master/models/game_models.dart';
import 'package:grid_master/providers/game_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stand-in for CreditProvider (GameProvider.usePaidHint takes a dynamic).
class _FakeCredits {
  _FakeCredits({required this.allow});

  final bool allow;
  final List<int> spent = [];

  bool spendCreditsForHint(int amount) {
    if (!allow) return false;
    spent.add(amount);
    return true;
  }
}

/// Expected points, written out independently of the implementation.
int _expectedPoints(LevelConfig level, double timer, {bool doubled = false}) {
  final multiplier = (level.gridSize * level.colorCount) / 10;
  final speedBonus = (timer * 20).round();
  final points = ((level.patternSize * 20 + 100 + speedBonus) * multiplier)
      .round();
  return doubled ? points * 2 : points;
}

/// Rebuilds the target pattern through the public API only.
void _solve(GameProvider gp) {
  final target = gp.targetPattern.map((c) => c.color).toList();
  for (int i = 0; i < target.length; i++) {
    if (target[i] == ColorType.none) continue;
    if (gp.userPattern[i].color == target[i]) continue;
    gp.selectColor(target[i]);
    gp.onCellTap(i);
  }
}

int _filled(List<GridCell> cells) =>
    cells.where((c) => c.color != ColorType.none).length;

/// Long enough for the auto-advance after a solved level, short enough that
/// the following preview (>= 2.5 s) is still running.
const _afterLevelUp = Duration(milliseconds: 1500);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Audio plugins have no platform side in unit tests; answer their
    // channels with an empty success so they stay silent.
    TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .allMessagesHandler = (channel, handler, message) async {
      if (channel.startsWith('xyz.luan/audioplayers')) {
        return const StandardMethodCodec().encodeSuccessEnvelope(null);
      }
      return handler?.call(message);
    };
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .allMessagesHandler =
        null;
  });

  Future<GameProvider> create(WidgetTester tester) async {
    final gp = GameProvider();
    await tester.pump();
    return gp;
  }

  /// Cancels timers so the test can end cleanly.
  Future<void> finish(WidgetTester tester, GameProvider gp) async {
    gp.goToHome();
    await tester.pump();
    gp.dispose();
  }

  group('start', () {
    testWidgets('initial state', (tester) async {
      final gp = await create(tester);
      expect(gp.gameState, GameState.start);
      expect(gp.isStart, isTrue);
      expect(gp.hints, 3);
      expect(gp.score.points, 0);
      expect(gp.score.combo, 0);
      expect(gp.hasDoubleBonus, isFalse);
      expect(gp.hasUsedContinueThisRound, isFalse);
      await finish(tester, gp);
    });

    testWidgets('loads the stored high score', (tester) async {
      SharedPreferences.setMockInitialValues({'highScore': 4321});
      final gp = await create(tester);
      expect(gp.score.highScore, 4321);
      await finish(tester, gp);
    });

    testWidgets('startGame enters preview of level 1', (tester) async {
      final gp = await create(tester);
      gp.startGame();

      expect(gp.gameState, GameState.preview);
      expect(gp.currentLevelIdx, 0);
      expect(gp.currentLevel.id, 1);
      expect(gp.timer, levels[0].previewSeconds);
      expect(gp.maxTimer, levels[0].previewSeconds);
      expect(gp.timerProgress, 1.0);
      expect(gp.selectedColor, ColorType.red);
      expect(gp.targetPattern.length, 9);
      expect(gp.userPattern.length, 9);
      expect(_filled(gp.targetPattern), levels[0].patternSize);
      expect(_filled(gp.userPattern), 0);

      final allowed = colorOptions.take(levels[0].colorCount).toSet();
      for (final cell in gp.targetPattern) {
        if (cell.color != ColorType.none) {
          expect(allowed, contains(cell.color));
        }
      }
      await finish(tester, gp);
    });
  });

  group('phases', () {
    testWidgets('preview runs out into rebuild', (tester) async {
      final gp = await create(tester);
      gp.startGame();

      await tester.pump(const Duration(seconds: 1));
      expect(gp.isPreview, isTrue);
      expect(gp.timer, closeTo(4.5, 0.11));

      await tester.pump(const Duration(seconds: 5));
      expect(gp.isRebuild, isTrue);
      expect(gp.maxTimer, 7);
      await finish(tester, gp);
    });

    testWidgets('skipPreview jumps to rebuild with full time', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();

      expect(gp.isRebuild, isTrue);
      expect(gp.timer, 7);
      expect(gp.maxTimer, 7);
      expect(gp.rebuildTimeLimit, 7);
      await finish(tester, gp);
    });

    testWidgets('skipPreview does nothing outside preview', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      await tester.pump(const Duration(seconds: 1));
      final before = gp.timer;
      gp.skipPreview();
      expect(gp.isRebuild, isTrue);
      expect(gp.timer, before);
      await finish(tester, gp);
    });

    testWidgets('cells only react during rebuild', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.onCellTap(0);
      expect(_filled(gp.userPattern), 0);
      await finish(tester, gp);
    });

    testWidgets('tapping a cell places and toggles the selected color', (
      tester,
    ) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();

      final empty = gp.targetPattern.indexWhere(
        (c) => c.color == ColorType.none,
      );
      gp.selectColor(ColorType.blue);
      expect(gp.selectedColor, ColorType.blue);

      gp.onCellTap(empty);
      expect(gp.userPattern[empty].color, ColorType.blue);

      gp.selectColor(ColorType.red);
      gp.onCellTap(empty);
      expect(gp.userPattern[empty].color, ColorType.red);

      gp.onCellTap(empty);
      expect(gp.userPattern[empty].color, ColorType.none);
      await finish(tester, gp);
    });

    testWidgets('pause freezes the timer, resume continues', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      await tester.pump(const Duration(seconds: 1));

      gp.togglePause();
      expect(gp.isPaused, isTrue);
      expect(gp.lastActiveState, GameState.rebuild);
      final frozen = gp.timer;
      await tester.pump(const Duration(seconds: 3));
      expect(gp.timer, frozen);
      expect(gp.pausedCells.length, 9);
      expect(_filled(gp.pausedCells), 0);

      gp.resume();
      expect(gp.isRebuild, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(gp.timer, lessThan(frozen));
      await finish(tester, gp);
    });
  });

  group('scoring', () {
    testWidgets('solving level 1 without delay scores 288', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      _solve(gp);

      expect(gp.gameState, GameState.levelUp);
      // (4 * 20 + 100 + 7 * 20) * (3 * 3 / 10) = 288
      expect(gp.score.points, 288);
      expect(gp.score.points, _expectedPoints(levels[0], 7));
      expect(gp.score.combo, 1);
      expect(gp.score.bestCombo, 1);
      expect(gp.score.level, 2);
      expect(gp.score.highScore, 288);
      await tester.pump(_afterLevelUp);
      await finish(tester, gp);
    });

    testWidgets('speed bonus shrinks with the remaining time', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      await tester.pump(const Duration(seconds: 3));

      final timer = gp.timer;
      expect(timer, closeTo(4.0, 0.11));
      _solve(gp);

      expect(gp.score.points, _expectedPoints(levels[0], timer));
      expect(gp.score.points, lessThan(288));
      await tester.pump(_afterLevelUp);
      await finish(tester, gp);
    });

    testWidgets('double bonus doubles the gain', (tester) async {
      final gp = await create(tester);
      gp.activateDoubleBonus();
      expect(gp.hasDoubleBonus, isTrue);
      gp.startGame();
      expect(gp.hasDoubleBonus, isTrue);
      gp.skipPreview();
      _solve(gp);

      expect(gp.score.points, 576);
      expect(
        gp.score.points,
        _expectedPoints(levels[0], 7, doubled: true),
      );
      await tester.pump(_afterLevelUp);
      await finish(tester, gp);
    });

    testWidgets('double bonus ends with the first failure', (tester) async {
      final gp = await create(tester);
      gp.activateDoubleBonus();
      gp.startGame();
      gp.skipPreview();
      gp.validatePattern();

      expect(gp.isShowSolution, isTrue);
      expect(gp.hasDoubleBonus, isFalse);
      await tester.pump(const Duration(seconds: 3));
      await finish(tester, gp);
    });

    testWidgets('advances to the next level and builds a combo', (
      tester,
    ) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      _solve(gp);
      await tester.pump(_afterLevelUp);

      expect(gp.isPreview, isTrue);
      expect(gp.currentLevelIdx, 1);
      expect(gp.currentLevel.id, 2);
      expect(_filled(gp.userPattern), 0);

      gp.skipPreview();
      final timer = gp.timer;
      _solve(gp);

      expect(gp.score.combo, 2);
      expect(gp.score.bestCombo, 2);
      expect(gp.score.level, 3);
      expect(gp.score.points, 288 + _expectedPoints(levels[1], timer));
      await tester.pump(_afterLevelUp);
      expect(gp.currentLevelIdx, 2);
      await finish(tester, gp);
    });

    testWidgets('new high score is persisted', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      _solve(gp);
      await tester.pump(_afterLevelUp);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('highScore'), 288);
      await finish(tester, gp);
    });

    testWidgets('lower score keeps the existing high score', (tester) async {
      SharedPreferences.setMockInitialValues({'highScore': 9999});
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      _solve(gp);
      await tester.pump(_afterLevelUp);

      expect(gp.score.highScore, 9999);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('highScore'), 9999);
      await finish(tester, gp);
    });

    testWidgets('restart resets run state but keeps the high score', (
      tester,
    ) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      _solve(gp);
      await tester.pump(_afterLevelUp);
      gp.skipPreview();
      gp.useHint();

      gp.restart();
      expect(gp.isPreview, isTrue);
      expect(gp.currentLevelIdx, 0);
      expect(gp.score.points, 0);
      expect(gp.score.combo, 0);
      expect(gp.score.highScore, 288);
      expect(gp.hints, 3);
      expect(gp.hasUsedContinueThisRound, isFalse);
      await finish(tester, gp);
    });

    testWidgets('goToHome returns to start and clears the pattern', (
      tester,
    ) async {
      final gp = await create(tester);
      gp.startGame();
      gp.goToHome();
      expect(gp.isStart, isTrue);
      expect(gp.targetPattern, isEmpty);
      expect(gp.currentLevelIdx, 0);
      expect(gp.hints, 3);
      await tester.pump(const Duration(seconds: 10));
      expect(gp.isStart, isTrue);
      gp.dispose();
    });
  });

  group('failure', () {
    testWidgets('timeout shows the solution for 2 s, then game over', (
      tester,
    ) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();

      await tester.pump(const Duration(milliseconds: 7300));
      expect(gp.gameState, GameState.showSolution);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(gp.gameState, GameState.showSolution);

      await tester.pump(const Duration(milliseconds: 700));
      expect(gp.gameState, GameState.gameOver);
      expect(gp.isGameOver, isTrue);
      await finish(tester, gp);
    });

    testWidgets('wrong pattern on validate fails without scoring', (
      tester,
    ) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      gp.validatePattern();

      expect(gp.gameState, GameState.showSolution);
      expect(gp.score.points, 0);
      expect(gp.score.combo, 0);
      await tester.pump(const Duration(milliseconds: 2100));
      expect(gp.gameState, GameState.gameOver);
      await finish(tester, gp);
    });
  });

  group('hints', () {
    testWidgets('free hint fills one correct cell and costs one hint', (
      tester,
    ) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();

      gp.useHint();
      expect(gp.hints, 2);
      expect(_filled(gp.userPattern), 1);
      final idx = gp.userPattern.indexWhere((c) => c.color != ColorType.none);
      expect(gp.userPattern[idx].color, gp.targetPattern[idx].color);
      await finish(tester, gp);
    });

    testWidgets('hint removes wrong placements first', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();

      // Color on a cell that must stay empty
      final mustBeEmpty = gp.targetPattern.indexWhere(
        (c) => c.color == ColorType.none,
      );
      gp.selectColor(ColorType.red);
      gp.onCellTap(mustBeEmpty);

      // Wrong color on a cell that belongs to the pattern
      final patternCell = gp.targetPattern.indexWhere(
        (c) => c.color != ColorType.none,
      );
      final wrongColor = colorOptions
          .take(gp.currentLevel.colorCount)
          .firstWhere((c) => c != gp.targetPattern[patternCell].color);
      gp.selectColor(wrongColor);
      gp.onCellTap(patternCell);
      expect(_filled(gp.userPattern), 2);

      gp.useHint();

      expect(gp.userPattern[mustBeEmpty].color, ColorType.none);
      for (int i = 0; i < gp.userPattern.length; i++) {
        final placed = gp.userPattern[i].color;
        if (placed != ColorType.none) {
          expect(placed, gp.targetPattern[i].color);
        }
      }
      expect(_filled(gp.userPattern), 1);
      expect(gp.hints, 2);
      await finish(tester, gp);
    });

    testWidgets('hints are limited to three', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();

      gp.useHint();
      gp.useHint();
      gp.useHint();
      expect(gp.hints, 0);
      expect(_filled(gp.userPattern), 3);

      gp.useHint();
      expect(gp.hints, 0);
      expect(_filled(gp.userPattern), 3);
      await finish(tester, gp);
    });

    testWidgets('hint is ignored outside rebuild', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.useHint();
      expect(gp.hints, 3);
      expect(_filled(gp.userPattern), 0);
      await finish(tester, gp);
    });

    testWidgets('hint that completes the pattern wins the level', (
      tester,
    ) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();

      // Place everything except one cell, the hint delivers the last one.
      final target = gp.targetPattern.map((c) => c.color).toList();
      final patternIdx = [
        for (int i = 0; i < target.length; i++)
          if (target[i] != ColorType.none) i,
      ];
      for (final i in patternIdx.skip(1)) {
        gp.selectColor(target[i]);
        gp.onCellTap(i);
      }
      expect(gp.isRebuild, isTrue);

      gp.useHint();
      expect(gp.gameState, GameState.levelUp);
      expect(gp.score.points, 288);
      expect(gp.hints, 2);
      await tester.pump(_afterLevelUp);
      await finish(tester, gp);
    });

    testWidgets('hints carry over to the next level', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      gp.useHint();
      _solve(gp);
      await tester.pump(_afterLevelUp);
      expect(gp.hints, 2);
      await finish(tester, gp);
    });

    testWidgets('paid hint spends 5 credits and fills a cell', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      final credits = _FakeCredits(allow: true);

      expect(gp.usePaidHint(credits), isTrue);
      expect(credits.spent, [5]);
      expect(_filled(gp.userPattern), 1);
      expect(gp.hints, 3, reason: 'paid hints do not consume free hints');
      await finish(tester, gp);
    });

    testWidgets('paid hint fails without credits', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      final credits = _FakeCredits(allow: false);

      expect(gp.usePaidHint(credits), isFalse);
      expect(_filled(gp.userPattern), 0);
      await finish(tester, gp);
    });

    testWidgets('paid hint is refused outside rebuild', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      final credits = _FakeCredits(allow: true);

      expect(gp.usePaidHint(credits), isFalse);
      expect(credits.spent, isEmpty);
      await finish(tester, gp);
    });
  });

  group('continueAfterAd', () {
    testWidgets('replays the same pattern from preview', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      _solve(gp);
      await tester.pump(_afterLevelUp);

      // Fail on level 2
      gp.skipPreview();
      gp.selectColor(ColorType.red);
      gp.onCellTap(
        gp.targetPattern.indexWhere((c) => c.color == ColorType.none),
      );
      gp.validatePattern();
      await tester.pump(const Duration(milliseconds: 2100));
      expect(gp.isGameOver, isTrue);

      final pattern = gp.targetPattern.map((c) => c.color).toList();
      final pointsBefore = gp.score.points;
      final comboBefore = gp.score.combo;

      gp.continueAfterAd();

      expect(gp.isPreview, isTrue);
      expect(gp.hasUsedContinueThisRound, isTrue);
      expect(gp.currentLevelIdx, 1);
      expect(gp.timer, levels[1].previewSeconds);
      expect(gp.maxTimer, levels[1].previewSeconds);
      expect(gp.targetPattern.map((c) => c.color).toList(), pattern);
      expect(_filled(gp.userPattern), 0);
      expect(gp.score.points, pointsBefore);
      expect(gp.score.combo, comboBefore);

      // The run really continues
      gp.skipPreview();
      _solve(gp);
      expect(gp.gameState, GameState.levelUp);
      expect(gp.score.points, greaterThan(pointsBefore));
      await tester.pump(_afterLevelUp);
      await finish(tester, gp);
    });

    testWidgets('is ignored unless the game is over', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      gp.continueAfterAd();

      expect(gp.isRebuild, isTrue);
      expect(gp.hasUsedContinueThisRound, isFalse);
      await finish(tester, gp);
    });

    testWidgets('startGame clears the continue flag', (tester) async {
      final gp = await create(tester);
      gp.startGame();
      gp.skipPreview();
      gp.validatePattern();
      await tester.pump(const Duration(milliseconds: 2100));
      gp.continueAfterAd();
      expect(gp.hasUsedContinueThisRound, isTrue);

      gp.goToHome();
      gp.startGame();
      expect(gp.hasUsedContinueThisRound, isFalse);
      await finish(tester, gp);
    });
  });
}
