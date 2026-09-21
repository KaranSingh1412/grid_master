import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_master/constants/game_constants.dart';
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

  /// Grid with [loseAnimationId] unlocked and equipped, wired like main.dart
  Future<GameProvider> pumpGrid(
    WidgetTester tester, {
    String loseAnimationId = 'shatter_lose',
    bool reduceMotion = false,
  }) async {
    final game = GameProvider();
    final credits = CreditProvider();
    await tester.pump();
    credits.unlockCosmeticByLevel(loseAnimationId);
    credits.equipCosmetic(
      allCosmetics.firstWhere((c) => c.id == loseAnimationId),
    );
    game.setLoseAnimationEnabled(
      GridCollapseKind.ofCosmetic(loseAnimationId) != null,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: game),
          ChangeNotifierProvider(create: (_) => AudioProvider()),
          ChangeNotifierProvider.value(value: credits),
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

  /// Loses the first level and stops right after the solution
  Future<void> lose(
    WidgetTester tester,
    GameProvider game, {
    GameState then = GameState.collapse,
  }) async {
    game.startGame();
    await tester.pump();
    game.skipPreview();
    await tester.pump();
    game.validatePattern();
    await tester.pump();
    expect(game.gameState, GameState.showSolution);
    await tester.pump(GameProvider.solutionDuration);
    expect(game.gameState, then);
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

  for (final entry in const {
    'explode_lose': GridCollapseKind.explode,
    'shatter_lose': GridCollapseKind.shatter,
    'fall_lose': GridCollapseKind.fallThrough,
  }.entries) {
    testWidgets('${entry.key} plays its own animation', (tester) async {
      final game = await pumpGrid(tester, loseAnimationId: entry.key);
      await lose(tester, game);
      final layer = tester.widget<GridCollapseLayer>(
        find.byType(GridCollapseLayer),
      );
      expect(layer.scene.kind, entry.value);

      for (int frame = 0; frame < 22; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }

      game.goToHome();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('the free default goes straight to game over', (tester) async {
    final game = await pumpGrid(tester, loseAnimationId: 'default_lose');
    await lose(tester, game, then: GameState.gameOver);
    expect(find.byType(GridCollapseLayer), findsNothing);

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
