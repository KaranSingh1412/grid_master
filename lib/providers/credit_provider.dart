import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/game_models.dart';
import '../constants/game_constants.dart';
import '../models/progress_models.dart';

/// Provider for managing in-game credits/coins
/// Uses secure storage to prevent tampering
class CreditProvider extends ChangeNotifier {
  static const _creditsKey = 'secure_credits';
  static const _cosmeticCreditsKey = 'cosmetic_credits';
  static const _lastAdWatchKey = 'last_ad_watch_date';
  static const _paidHintsKey = 'paid_hints_today';
  static const _paidHintsDateKey = 'paid_hints_date';
  static const _cosmeticStateKey = 'cosmetic_state';
  static const _blockPointsKey = 'block_points';
  static const _blockPointsLifetimeKey = 'block_points_lifetime';
  static const _lootboxesKey = 'lootboxes_pending';
  static const int maxPaidHintsPerDay = 3;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  int _credits = 0;
  int _cosmeticCredits = 0;
  int _lastCreditThreshold = 0;
  int _lastCosmeticCreditThreshold = 0;
  bool _isLoaded = false;
  DateTime? _lastAdWatchDate;
  int _paidHintsToday = 0;
  DateTime? _paidHintsDate;
  CosmeticState _cosmeticState = const CosmeticState();
  int _blockPoints = 0;
  int _blockPointsLifetime = 0;
  int _lootboxes = 0;
  final Random _random = Random();

  int get credits => _credits;

  /// Spendable Blockpunkte: every point scored in a run lands here
  int get blockPoints => _blockPoints;

  /// Blockpunkte ever earned, spending does not lower it
  int get blockPointsLifetime => _blockPointsLifetime;

  /// Free lootboxes waiting to be opened
  int get lootboxes => _lootboxes;

  /// 0..1 on the way to the next free lootbox
  double get lootboxProgress =>
      (_blockPointsLifetime % blockPointsPerLootbox) / blockPointsPerLootbox;
  int get cosmeticCredits => _cosmeticCredits;
  bool get isLoaded => _isLoaded;
  int get paidHintsRemaining => maxPaidHintsPerDay - _paidHintsToday;
  bool get canBuyHintToday => _paidHintsToday < maxPaidHintsPerDay;
  CosmeticState get cosmeticState => _cosmeticState;

  /// Get currently equipped theme
  CosmeticThemeType get equippedThemeType {
    final themeId = _cosmeticState.equippedThemeId;
    final cosmetic = allCosmetics.firstWhere(
      (c) => c.id == themeId,
      orElse: () => allCosmetics.first,
    );
    return cosmetic.themeType ?? CosmeticThemeType.defaultTheme;
  }

  /// Check if user can watch a rewarded ad today
  bool get canWatchAdToday {
    if (_lastAdWatchDate == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastWatch = DateTime(
      _lastAdWatchDate!.year,
      _lastAdWatchDate!.month,
      _lastAdWatchDate!.day,
    );
    return today.isAfter(lastWatch);
  }

  CreditProvider() {
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    try {
      final creditsStr = await _secureStorage.read(key: _creditsKey);
      _credits = creditsStr != null ? int.tryParse(creditsStr) ?? 0 : 0;

      // Load cosmetic credits
      final cosmeticCreditsStr = await _secureStorage.read(
        key: _cosmeticCreditsKey,
      );
      _cosmeticCredits = cosmeticCreditsStr != null
          ? int.tryParse(cosmeticCreditsStr) ?? 0
          : 0;

      // Load cosmetic state
      final cosmeticStateStr = await _secureStorage.read(
        key: _cosmeticStateKey,
      );
      if (cosmeticStateStr != null) {
        _cosmeticState = CosmeticState.fromJson(jsonDecode(cosmeticStateStr));
      }

      _blockPoints = await _readInt(_blockPointsKey);
      _blockPointsLifetime = await _readInt(_blockPointsLifetimeKey);
      _lootboxes = await _readInt(_lootboxesKey);

      // Load last ad watch date
      final lastAdStr = await _secureStorage.read(key: _lastAdWatchKey);
      if (lastAdStr != null) {
        _lastAdWatchDate = DateTime.tryParse(lastAdStr);
      }

      // Load paid hints tracking
      final paidHintsDateStr = await _secureStorage.read(
        key: _paidHintsDateKey,
      );
      if (paidHintsDateStr != null) {
        _paidHintsDate = DateTime.tryParse(paidHintsDateStr);
        // Check if it's a new day
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final hintsDay = DateTime(
          _paidHintsDate!.year,
          _paidHintsDate!.month,
          _paidHintsDate!.day,
        );
        if (today.isAfter(hintsDay)) {
          // New day, reset counter
          _paidHintsToday = 0;
        } else {
          final paidHintsStr = await _secureStorage.read(key: _paidHintsKey);
          _paidHintsToday = paidHintsStr != null
              ? int.tryParse(paidHintsStr) ?? 0
              : 0;
        }
      }
    } catch (e) {
      // Fallback if secure storage fails
      _credits = 0;
      _cosmeticCredits = 0;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<int> _readInt(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null ? int.tryParse(value) ?? 0 : 0;
  }

  Future<void> _saveProgress() async {
    try {
      await _secureStorage.write(
        key: _blockPointsKey,
        value: _blockPoints.toString(),
      );
      await _secureStorage.write(
        key: _blockPointsLifetimeKey,
        value: _blockPointsLifetime.toString(),
      );
      await _secureStorage.write(
        key: _lootboxesKey,
        value: _lootboxes.toString(),
      );
    } catch (e) {
      debugPrint('Failed to save Blockpunkte: $e');
    }
  }

  /// Book Blockpunkte scored in a run. Crossing a lootbox threshold of the
  /// lifetime total adds a free lootbox. Returns the number of new boxes.
  int addBlockPoints(int amount) {
    if (amount <= 0) return 0;
    final before = _blockPointsLifetime ~/ blockPointsPerLootbox;
    _blockPoints += amount;
    _blockPointsLifetime += amount;
    final newBoxes = _blockPointsLifetime ~/ blockPointsPerLootbox - before;
    _lootboxes += newBoxes;
    _saveProgress();
    notifyListeners();
    return newBoxes;
  }

  /// Buy a cosmetic with Blockpunkte instead of coins
  bool purchaseCosmeticWithBlockPoints(CosmeticItem item) {
    final cost = blockPointCost(item);
    if (cost <= 0 || _blockPoints < cost) return false;
    if (_cosmeticState.isUnlocked(item.id)) return false;
    _blockPoints -= cost;
    _cosmeticState = _cosmeticState.copyWith(
      unlockedCosmetics: Set<String>.from(_cosmeticState.unlockedCosmetics)
        ..add(item.id),
    );
    _saveProgress();
    _saveCosmeticState();
    notifyListeners();
    return true;
  }

  /// Open one waiting lootbox and pay out its reward
  LootboxReward? openLootbox() {
    if (_lootboxes <= 0) return null;
    final locked = allCosmetics
        .where((c) => !_cosmeticState.isUnlocked(c.id))
        .toList();
    final reward = LootboxReward.roll(_random, locked);
    _lootboxes--;
    switch (reward.type) {
      case LootboxRewardType.coins:
        _credits += reward.amount;
        _saveCredits();
        break;
      case LootboxRewardType.blockPoints:
        // A gift, not a score: it is spendable but does not count towards
        // the next lootbox
        _blockPoints += reward.amount;
        break;
      case LootboxRewardType.cosmetic:
        _cosmeticState = _cosmeticState.copyWith(
          unlockedCosmetics: Set<String>.from(_cosmeticState.unlockedCosmetics)
            ..add(reward.cosmetic!.id),
        );
        _saveCosmeticState();
        break;
    }
    _saveProgress();
    notifyListeners();
    return reward;
  }

  Future<void> _saveCredits() async {
    try {
      await _secureStorage.write(key: _creditsKey, value: _credits.toString());
      await _secureStorage.write(
        key: _cosmeticCreditsKey,
        value: _cosmeticCredits.toString(),
      );
    } catch (e) {
      // Log error but don't crash
      debugPrint('Failed to save credits securely: $e');
    }
  }

  Future<void> _saveCosmeticState() async {
    try {
      await _secureStorage.write(
        key: _cosmeticStateKey,
        value: jsonEncode(_cosmeticState.toJson()),
      );
    } catch (e) {
      debugPrint('Failed to save cosmetic state: $e');
    }
  }

  /// Record that user watched an ad today
  Future<void> recordAdWatch() async {
    _lastAdWatchDate = DateTime.now();
    try {
      await _secureStorage.write(
        key: _lastAdWatchKey,
        value: _lastAdWatchDate!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Failed to save ad watch date: $e');
    }
    notifyListeners();
  }

  /// Reset the threshold tracker for a new game round
  void resetThreshold() {
    _lastCreditThreshold = 0;
    _lastCosmeticCreditThreshold = 0;
  }

  /// Check and award credits based on current score
  /// Returns the number of new credits earned
  int checkAndAwardCredits(int currentScore) {
    int creditsEarned = 0;

    // Calculate how many 2000-point thresholds have been crossed
    final currentThreshold = (currentScore ~/ 2000) * 2000;

    // Award credits for each new threshold crossed
    while (_lastCreditThreshold < currentThreshold) {
      _lastCreditThreshold += 2000;
      creditsEarned++;
    }

    if (creditsEarned > 0) {
      _credits += creditsEarned;
      _saveCredits();
      notifyListeners();
    }

    return creditsEarned;
  }

  /// Check and award cosmetic credits based on current score
  /// Returns the number of new cosmetic credits earned
  int checkAndAwardCosmeticCredits(int currentScore) {
    int cosmeticCreditsEarned = 0;

    // Earn 1 cosmetic credit per 1500 points (faster than regular credits)
    final threshold = 1000;
    final currentThreshold = (currentScore ~/ threshold) * threshold;

    while (_lastCosmeticCreditThreshold < currentThreshold) {
      _lastCosmeticCreditThreshold += threshold;
      cosmeticCreditsEarned++;
    }

    if (cosmeticCreditsEarned > 0) {
      _cosmeticCredits += cosmeticCreditsEarned;
      _saveCredits();
      notifyListeners();
    }

    return cosmeticCreditsEarned;
  }

  /// Add credits (e.g., from watching ads or purchases)
  void addCredits(int amount) {
    _credits += amount;
    _saveCredits();
    notifyListeners();
  }

  /// Add cosmetic credits
  void addCosmeticCredits(int amount) {
    _cosmeticCredits += amount;
    _saveCredits();
    notifyListeners();
  }

  /// Spend cosmetic credits if enough are available
  bool spendCosmeticCredits(int amount) {
    if (_cosmeticCredits >= amount) {
      _cosmeticCredits -= amount;
      _saveCredits();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Unlock a cosmetic item by level milestone (free unlock)
  void unlockCosmeticByLevel(String cosmeticId) {
    if (!_cosmeticState.unlockedCosmetics.contains(cosmeticId)) {
      final newUnlocks = Set<String>.from(_cosmeticState.unlockedCosmetics)
        ..add(cosmeticId);
      _cosmeticState = _cosmeticState.copyWith(unlockedCosmetics: newUnlocks);
      _saveCosmeticState();
      notifyListeners();
    }
  }

  /// Purchase and unlock a cosmetic item with coins
  bool purchaseCosmetic(String cosmeticId, int cost) {
    if (_credits >= cost && !_cosmeticState.isUnlocked(cosmeticId)) {
      _credits -= cost;
      final newUnlocks = Set<String>.from(_cosmeticState.unlockedCosmetics)
        ..add(cosmeticId);
      _cosmeticState = _cosmeticState.copyWith(unlockedCosmetics: newUnlocks);
      _saveCredits();
      _saveCosmeticState();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Equip a cosmetic item (must be unlocked)
  void equipCosmetic(CosmeticItem item) {
    if (!_cosmeticState.isUnlocked(item.id)) return;

    switch (item.category) {
      case CosmeticCategory.theme:
        _cosmeticState = _cosmeticState.copyWith(equippedThemeId: item.id);
        break;
      case CosmeticCategory.gridStyle:
        _cosmeticState = _cosmeticState.copyWith(equippedGridStyleId: item.id);
        break;
      case CosmeticCategory.cellAnimation:
        _cosmeticState = _cosmeticState.copyWith(
          equippedCellAnimationId: item.id,
        );
        break;
      case CosmeticCategory.soundPack:
        _cosmeticState = _cosmeticState.copyWith(equippedSoundPackId: item.id);
        break;
      case CosmeticCategory.loseAnimation:
        _cosmeticState = _cosmeticState.copyWith(
          equippedLoseAnimationId: item.id,
        );
        break;
      case CosmeticCategory.gridFrame:
        _cosmeticState = _cosmeticState.copyWith(equippedFrameId: item.id);
        break;
      case CosmeticCategory.cellSprite:
        _cosmeticState = _cosmeticState.copyWith(equippedSpriteId: item.id);
        break;
    }
    _saveCosmeticState();
    notifyListeners();
  }

  /// Spend credits if enough are available
  /// Returns true if successful, false if not enough credits
  bool spendCredits(int amount) {
    if (_credits >= amount) {
      _credits -= amount;
      _saveCredits();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Spend credits for a hint (with daily limit)
  /// Returns true if successful, false if not enough credits or daily limit reached
  bool spendCreditsForHint(int amount) {
    if (!canBuyHintToday) return false;
    if (_credits < amount) return false;

    _credits -= amount;
    _paidHintsToday++;
    _paidHintsDate = DateTime.now();
    _saveCredits();
    _savePaidHints();
    notifyListeners();
    return true;
  }

  Future<void> _savePaidHints() async {
    try {
      await _secureStorage.write(
        key: _paidHintsKey,
        value: _paidHintsToday.toString(),
      );
      await _secureStorage.write(
        key: _paidHintsDateKey,
        value: _paidHintsDate!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Failed to save paid hints: $e');
    }
  }
}
