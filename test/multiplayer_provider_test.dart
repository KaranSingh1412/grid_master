import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_master/models/game_models.dart';
import 'package:grid_master/providers/multiplayer_provider.dart';

/// Rebuilds [player]'s half of the target through the public API only.
void _solveHalf(MultiplayerProvider mp, int player) {
  const half = MultiplayerProvider.cellsPerHalf;
  for (int i = player * half; i < (player + 1) * half; i++) {
    final color = mp.target[i];
    if (color == ColorType.none || mp.user[i] == color) continue;
    mp.selectColor(player, color);
    mp.onCellTap(player, i);
  }
}

/// Waits out the preview so the rebuild phase begins.
Future<void> _toRebuild(WidgetTester tester, MultiplayerProvider mp) async {
  await tester.pump(
    Duration(milliseconds: (mp.previewSeconds * 1000).round() + 200),
  );
  expect(mp.phase, MultiplayerPhase.rebuild);
}

void main() {
  late MultiplayerProvider mp;

  setUp(() => mp = MultiplayerProvider(random: Random(7)));

  Future<void> finish(WidgetTester tester) async {
    mp.leave();
    await tester.pump();
    mp.dispose();
  }

  testWidgets('each half holds its own pattern cells', (tester) async {
    mp.startMatch();
    expect(mp.phase, MultiplayerPhase.preview);
    expect(mp.round, 1);
    for (int player = 0; player < 2; player++) {
      final start = player * MultiplayerProvider.cellsPerHalf;
      final filled = mp.target
          .sublist(start, start + MultiplayerProvider.cellsPerHalf)
          .where((c) => c != ColorType.none)
          .length;
      expect(filled, mp.filledPerHalf);
    }
    await finish(tester);
  });

  testWidgets('cells of the other half and taps in preview are ignored', (
    tester,
  ) async {
    mp.startMatch();
    mp.onCellTap(1, 12);
    expect(mp.user[12], ColorType.none);

    await _toRebuild(tester, mp);
    mp.onCellTap(0, 12);
    expect(mp.user[12], ColorType.none);
    mp.onCellTap(1, 12);
    expect(mp.user[12], mp.selectedColor(1));
    await finish(tester);
  });

  testWidgets('the first correct half wins the round', (tester) async {
    mp.startMatch();
    await _toRebuild(tester, mp);
    _solveHalf(mp, 1);
    expect(mp.phase, MultiplayerPhase.roundResult);
    expect(mp.roundWinner, 1);
    expect(mp.scores, [0, 1]);

    // The next round starts on its own
    await tester.pump(
      MultiplayerProvider.resultDuration + const Duration(milliseconds: 50),
    );
    expect(mp.phase, MultiplayerPhase.preview);
    expect(mp.round, 2);
    await finish(tester);
  });

  testWidgets('a timeout ends the round without a point', (tester) async {
    mp.startMatch();
    await _toRebuild(tester, mp);
    await tester.pump(
      Duration(
        milliseconds: (MultiplayerProvider.rebuildSeconds * 1000).round() + 200,
      ),
    );
    expect(mp.phase, MultiplayerPhase.roundResult);
    expect(mp.roundWinner, isNull);
    expect(mp.scores, [0, 0]);
    await finish(tester);
  });

  testWidgets('five rounds win the match', (tester) async {
    var finished = 0;
    mp.onMatchFinished = () => finished++;
    mp.startMatch();
    for (int r = 0; r < MultiplayerProvider.winningScore; r++) {
      await _toRebuild(tester, mp);
      _solveHalf(mp, 0);
      if (r < MultiplayerProvider.winningScore - 1) {
        await tester.pump(
          MultiplayerProvider.resultDuration + const Duration(milliseconds: 50),
        );
      }
    }
    expect(mp.phase, MultiplayerPhase.matchOver);
    expect(mp.matchWinner, 0);
    expect(finished, 1);
    await finish(tester);
  });

  test('the top half belongs to player 0, the bottom half to player 1', () {
    expect(MultiplayerProvider.ownerOf(0), 0);
    expect(MultiplayerProvider.ownerOf(7), 0);
    expect(MultiplayerProvider.ownerOf(8), 1);
    expect(MultiplayerProvider.ownerOf(15), 1);
  });
}
