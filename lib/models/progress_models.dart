import 'dart:math';
import 'game_models.dart';

/// What a lootbox holds
enum LootboxRewardType { coins, blockPoints, cosmetic }

/// Content of one opened lootbox
class LootboxReward {
  final LootboxRewardType type;
  final int amount;
  final CosmeticItem? cosmetic;

  const LootboxReward.coins(this.amount)
    : type = LootboxRewardType.coins,
      cosmetic = null;

  const LootboxReward.blockPoints(this.amount)
    : type = LootboxRewardType.blockPoints,
      cosmetic = null;

  const LootboxReward.cosmetic(CosmeticItem this.cosmetic)
    : type = LootboxRewardType.cosmetic,
      amount = 0;

  /// Rolls a reward: mostly coins or Blockpunkte, now and then a cosmetic
  /// the player does not own yet. With nothing left to unlock the cosmetic
  /// share turns into a big coin reward.
  static LootboxReward roll(Random random, List<CosmeticItem> lockedCosmetics) {
    final r = random.nextDouble();
    if (r < 0.12) {
      final buyable = lockedCosmetics.where((c) => c.cosmeticCost > 0).toList();
      if (buyable.isEmpty) return const LootboxReward.coins(40);
      return LootboxReward.cosmetic(buyable[random.nextInt(buyable.length)]);
    }
    if (r < 0.62) return LootboxReward.coins(5 + random.nextInt(4) * 5);
    return LootboxReward.blockPoints(1000 + random.nextInt(5) * 1000);
  }
}

/// Lifetime numbers shown on the statistics screen
class PlayerStats {
  final int gamesPlayed;
  final int levelsSolved;
  final int highestLevel;
  final int bestCombo;
  final int bestScore;
  final int totalBlockPoints;
  final int hintsUsed;
  final int playSeconds;
  final int lootboxesOpened;
  final int multiplayerMatches;
  final DateTime? firstPlayed;
  final DateTime? lastReviewRequest;

  const PlayerStats({
    this.gamesPlayed = 0,
    this.levelsSolved = 0,
    this.highestLevel = 0,
    this.bestCombo = 0,
    this.bestScore = 0,
    this.totalBlockPoints = 0,
    this.hintsUsed = 0,
    this.playSeconds = 0,
    this.lootboxesOpened = 0,
    this.multiplayerMatches = 0,
    this.firstPlayed,
    this.lastReviewRequest,
  });

  PlayerStats copyWith({
    int? gamesPlayed,
    int? levelsSolved,
    int? highestLevel,
    int? bestCombo,
    int? bestScore,
    int? totalBlockPoints,
    int? hintsUsed,
    int? playSeconds,
    int? lootboxesOpened,
    int? multiplayerMatches,
    DateTime? firstPlayed,
    DateTime? lastReviewRequest,
  }) {
    return PlayerStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      levelsSolved: levelsSolved ?? this.levelsSolved,
      highestLevel: highestLevel ?? this.highestLevel,
      bestCombo: bestCombo ?? this.bestCombo,
      bestScore: bestScore ?? this.bestScore,
      totalBlockPoints: totalBlockPoints ?? this.totalBlockPoints,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      playSeconds: playSeconds ?? this.playSeconds,
      lootboxesOpened: lootboxesOpened ?? this.lootboxesOpened,
      multiplayerMatches: multiplayerMatches ?? this.multiplayerMatches,
      firstPlayed: firstPlayed ?? this.firstPlayed,
      lastReviewRequest: lastReviewRequest ?? this.lastReviewRequest,
    );
  }

  /// Average Blockpunkte per game, 0 before the first game
  int get averageScore =>
      gamesPlayed == 0 ? 0 : (totalBlockPoints / gamesPlayed).round();

  Map<String, dynamic> toJson() => {
    'gamesPlayed': gamesPlayed,
    'levelsSolved': levelsSolved,
    'highestLevel': highestLevel,
    'bestCombo': bestCombo,
    'bestScore': bestScore,
    'totalBlockPoints': totalBlockPoints,
    'hintsUsed': hintsUsed,
    'playSeconds': playSeconds,
    'lootboxesOpened': lootboxesOpened,
    'multiplayerMatches': multiplayerMatches,
    'firstPlayed': firstPlayed?.toIso8601String(),
    'lastReviewRequest': lastReviewRequest?.toIso8601String(),
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] is String ? DateTime.tryParse(json[key] as String) : null;
    return PlayerStats(
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      levelsSolved: json['levelsSolved'] as int? ?? 0,
      highestLevel: json['highestLevel'] as int? ?? 0,
      bestCombo: json['bestCombo'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      totalBlockPoints: json['totalBlockPoints'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      playSeconds: json['playSeconds'] as int? ?? 0,
      lootboxesOpened: json['lootboxesOpened'] as int? ?? 0,
      multiplayerMatches: json['multiplayerMatches'] as int? ?? 0,
      firstPlayed: date('firstPlayed'),
      lastReviewRequest: date('lastReviewRequest'),
    );
  }

  /// Games before the store rating dialog may come up
  static const int reviewMinGames = 8;

  /// Days of use before the store rating dialog may come up
  static const int reviewMinDays = 3;

  /// Days between two rating requests
  static const int reviewRepeatDays = 90;

  /// Whether now is a good moment to ask for a store rating: the player has
  /// been around for a few days, played a number of games, and was not
  /// asked recently.
  bool shouldRequestReview(DateTime now) {
    if (firstPlayed == null || gamesPlayed < reviewMinGames) return false;
    if (now.difference(firstPlayed!).inDays < reviewMinDays) return false;
    if (lastReviewRequest == null) return true;
    return now.difference(lastReviewRequest!).inDays >= reviewRepeatDays;
  }
}
