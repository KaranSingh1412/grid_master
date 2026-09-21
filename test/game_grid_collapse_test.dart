import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_master/models/game_models.dart';
import 'package:grid_master/providers/audio_provider.dart';
import 'package:grid_master/providers/credit_provider.dart';
import 'package:grid_master/providers/game_provider.dart';
import 'package:grid_master/providers/theme_provider.dart';
import 'package:grid_master/widgets/effects/grid_collapse.dart';
import 'package:grid_master/widgets/game/game_grid.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Audio and secure storage have no platform side in tests
    TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .allMessagesHandler = (channel, handler, message) async {
      if (channel.startsWith('xyz.luan/audioplayers') ||
          channel.contains('flutter_secure_storage')) {
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

  Future<GameProvider> pumpGrid(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    final game = GameProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: game),
          ChangeNotifierProvider(create: (_) => AudioProvider()),
          ChangeNotifierProvider(create: (_) => CreditProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            disableAnimations: reduceMotion,
          ),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: GameGrid(),
          ),
        ),
      ),
    );
    await tester.pump();
    return game;
  }

  /// Loses the first level and stops right as the board starts to collapse
  Future<void> lose(WidgetTester tester, GameProvider game) async {
    game.startGame();
    await tester.pump();
    game.skipPreview();
    await tester.pump();
    game.validatePattern();
    await tester.pump();
    expect(game.gameState, GameState.showSolution);
    await tester.pump(GameProvider.solutionDuration);
    expect(game.gameState, GameState.collapse);
    await tester.pump();
  }

  testWidgets('a lost board collapses and is whole again after a continue', (
    tester,
  ) async {
    final game = await pumpGrid(tester);
    await lose(tester, game);
    expect(find.byType(GridCollapseLayer), findsOneWidget);

    for (int frame = 0; frame < 22; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
    expect(game.gameState, GameState.gameOver);
    // What is left of the board stays behind the game over card
    expect(find.byType(GridCollapseLayer), findsOneWidget);

    game.continueAfterAd();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(GridCollapseLayer), findsNothing);
    expect(tester.takeException(), isNull);

    game.goToHome();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('successive losses never repeat the same animation', (
    tester,
  ) async {
    final game = await pumpGrid(tester);
    GridCollapseKind? last;
    for (int round = 0; round < 4; round++) {
      await lose(tester, game);
      final kind = tester
          .widget<GridCollapseLayer>(find.byType(GridCollapseLayer))
          .scene
          .kind;
      expect(kind, isNot(last));
      last = kind;
      await tester.pump(GameProvider.collapseDuration);
      await tester.pump();
    }

    game.goToHome();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('reduced motion keeps the solution on the board', (tester) async {
    final game = await pumpGrid(tester, reduceMotion: true);
    await lose(tester, game);
    expect(find.byType(GridCollapseLayer), findsNothing);

    await tester.pump(GameProvider.collapseDuration);
    expect(game.gameState, GameState.gameOver);

    game.goToHome();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
