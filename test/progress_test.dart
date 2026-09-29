import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_master/constants/game_constants.dart';
import 'package:grid_master/models/game_models.dart';
import 'package:grid_master/models/progress_models.dart';
import 'package:grid_master/providers/credit_provider.dart';

/// Random that returns fixed doubles and ints
class _FixedRandom implements Random {
  _FixedRandom(this.d, [this.i = 0]);
  final double d;
  final int i;
  @override
  double nextDouble() => d;
  @override
  int nextInt(int max) => i % max;
  @override
  bool nextBool() => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('lootbox roll', () {
    final locked = allCosmetics.where((c) => c.cosmeticCost > 0).toList();

    test('low rolls unlock a cosmetic the player does not own', () {
      final r = LootboxReward.roll(_FixedRandom(0.05, 3), locked);
      expect(r.type, LootboxRewardType.cosmetic);
      expect(r.cosmetic, locked[3]);
    });

    test('with everything owned the cosmetic share pays coins', () {
      final r = LootboxReward.roll(_FixedRandom(0.05), const []);
      expect(r.type, LootboxRewardType.coins);
      expect(r.amount, 40);
    });

    test('middle rolls pay coins, high rolls Blockpunkte', () {
      final coins = LootboxReward.roll(_FixedRandom(0.3, 2), locked);
      expect(coins.type, LootboxRewardType.coins);
      expect(coins.amount, 15);
      final points = LootboxReward.roll(_FixedRandom(0.9, 4), locked);
      expect(points.type, LootboxRewardType.blockPoints);
      expect(points.amount, 5000);
    });
  });

  group('review request', () {
    final start = DateTime(2026, 1, 1);

    test('needs enough games and days', () {
      final fresh = PlayerStats(gamesPlayed: 20, firstPlayed: start);
      expect(
        fresh.shouldRequestReview(start.add(const Duration(days: 1))),
        isFalse,
      );
      final few = PlayerStats(gamesPlayed: 2, firstPlayed: start);
      expect(
        few.shouldRequestReview(start.add(const Duration(days: 10))),
        isFalse,
      );
      final ready = PlayerStats(gamesPlayed: 8, firstPlayed: start);
      expect(
        ready.shouldRequestReview(start.add(const Duration(days: 3))),
        isTrue,
      );
    });

    test('asks again only after the pause', () {
      final asked = PlayerStats(
        gamesPlayed: 50,
        firstPlayed: start,
        lastReviewRequest: start.add(const Duration(days: 5)),
      );
      expect(
        asked.shouldRequestReview(start.add(const Duration(days: 60))),
        isFalse,
      );
      expect(
        asked.shouldRequestReview(start.add(const Duration(days: 96))),
        isTrue,
      );
    });

    test('stats survive a json round trip', () {
      final stats = PlayerStats(
        gamesPlayed: 3,
        totalBlockPoints: 4200,
        firstPlayed: start,
      );
      final copy = PlayerStats.fromJson(stats.toJson());
      expect(copy.gamesPlayed, 3);
      expect(copy.totalBlockPoints, 4200);
      expect(copy.firstPlayed, start);
      expect(copy.averageScore, 1400);
    });
  });

  test('old saves get the free frame and sprite', () {
    final state = CosmeticState.fromJson({
      'unlockedCosmetics': ['default_theme', 'zen_calm_theme'],
    });
    expect(state.isUnlocked('default_frame'), isTrue);
    expect(state.isUnlocked('default_sprite'), isTrue);
    expect(state.isUnlocked('zen_calm_theme'), isTrue);
    expect(state.equippedIn(CosmeticCategory.gridFrame), 'default_frame');
    expect(state.equippedIn(CosmeticCategory.cellSprite), 'default_sprite');
  });

  group('Blockpunkte', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .allMessagesHandler = (channel, handler, message) async {
        if (channel.contains('flutter_secure_storage')) {
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

    Future<CreditProvider> create(WidgetTester tester) async {
      final credits = CreditProvider();
      await tester.pump();
      return credits;
    }

    testWidgets('scored points fill the balance and bring lootboxes', (
      tester,
    ) async {
      final credits = await create(tester);
      expect(credits.addBlockPoints(blockPointsPerLootbox - 1), 0);
      expect(credits.lootboxes, 0);
      expect(credits.addBlockPoints(1), 1);
      expect(credits.lootboxes, 1);
      expect(credits.blockPoints, blockPointsPerLootbox);
      // Two thresholds in one go
      expect(credits.addBlockPoints(blockPointsPerLootbox * 2), 2);
      expect(credits.lootboxes, 3);
    });

    testWidgets('cosmetics can be bought with Blockpunkte', (tester) async {
      final credits = await create(tester);
      final item = allCosmetics.firstWhere((c) => c.id == 'gold_frame');
      final cost = blockPointCost(item);
      credits.addBlockPoints(cost - 1);
      expect(credits.purchaseCosmeticWithBlockPoints(item), isFalse);
      credits.addBlockPoints(1);
      expect(credits.purchaseCosmeticWithBlockPoints(item), isTrue);
      expect(credits.blockPoints, 0);
      expect(credits.cosmeticState.isUnlocked('gold_frame'), isTrue);
      // Owned items are not sold twice
      credits.addBlockPoints(cost);
      expect(credits.purchaseCosmeticWithBlockPoints(item), isFalse);
      // Spending does not lower the lifetime total
      expect(credits.blockPointsLifetime, cost * 2);
    });

    testWidgets('opening a lootbox pays out and uses it up', (tester) async {
      final credits = await create(tester);
      expect(credits.openLootbox(), isNull);
      credits.addBlockPoints(blockPointsPerLootbox);
      final coins = credits.credits;
      final points = credits.blockPoints;
      final unlocked = credits.cosmeticState.unlockedCosmetics.length;
      final reward = credits.openLootbox()!;
      expect(credits.lootboxes, 0);
      switch (reward.type) {
        case LootboxRewardType.coins:
          expect(credits.credits, coins + reward.amount);
          break;
        case LootboxRewardType.blockPoints:
          expect(credits.blockPoints, points + reward.amount);
          break;
        case LootboxRewardType.cosmetic:
          expect(credits.cosmeticState.unlockedCosmetics.length, unlocked + 1);
          break;
      }
    });

    testWidgets('frames and sprites can be equipped', (tester) async {
      final credits = await create(tester);
      credits.unlockCosmeticByLevel('wood_frame');
      credits.unlockCosmeticByLevel('star_sprite');
      credits.equipCosmetic(
        allCosmetics.firstWhere((c) => c.id == 'wood_frame'),
      );
      credits.equipCosmetic(
        allCosmetics.firstWhere((c) => c.id == 'star_sprite'),
      );
      expect(credits.cosmeticState.equippedFrameId, 'wood_frame');
      expect(credits.cosmeticState.equippedSpriteId, 'star_sprite');
    });
  });
}
