/// Game state enum matching the React implementation
enum GameState {
  start,
  preview,
  rebuild,
  feedback,
  levelUp,
  showSolution,
  gameOver,
  paused,
}

/// Game mode types
enum GameMode { classic }

/// Color types available in the game
enum ColorType { red, blue, green, yellow, purple, orange, pink, none }

/// Cosmetic theme types
enum CosmeticThemeType {
  defaultTheme,
  zenCalm,
  neonGlow,
  midnight,
  forest,
  sunset,
  ocean,
  lavender,
}

/// Cosmetic unlock category
enum CosmeticCategory { theme, gridStyle, cellAnimation, soundPack }

/// Represents a cosmetic item that can be unlocked
class CosmeticItem {
  final String id;
  final String nameKey; // Localization key
  final CosmeticCategory category;
  final CosmeticThemeType? themeType;
  final int cosmeticCost; // Cost in cosmetic credits (0 = level unlock only)

  const CosmeticItem({
    required this.id,
    required this.nameKey,
    required this.category,
    this.themeType,
    this.cosmeticCost = 0,
  });
}

/// Player's cosmetic progression state
class CosmeticState {
  final Set<String> unlockedCosmetics;
  final String equippedThemeId;
  final String equippedGridStyleId;
  final String equippedCellAnimationId;
  final String equippedSoundPackId;

  const CosmeticState({
    this.unlockedCosmetics = const {
      'default_theme',
      'default_grid',
      'default_animation',
      'default_sound',
    },
    this.equippedThemeId = 'default_theme',
    this.equippedGridStyleId = 'default_grid',
    this.equippedCellAnimationId = 'default_animation',
    this.equippedSoundPackId = 'default_sound',
  });

  CosmeticState copyWith({
    Set<String>? unlockedCosmetics,
    String? equippedThemeId,
    String? equippedGridStyleId,
    String? equippedCellAnimationId,
    String? equippedSoundPackId,
  }) {
    return CosmeticState(
      unlockedCosmetics: unlockedCosmetics ?? this.unlockedCosmetics,
      equippedThemeId: equippedThemeId ?? this.equippedThemeId,
      equippedGridStyleId: equippedGridStyleId ?? this.equippedGridStyleId,
      equippedCellAnimationId:
          equippedCellAnimationId ?? this.equippedCellAnimationId,
      equippedSoundPackId: equippedSoundPackId ?? this.equippedSoundPackId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unlockedCosmetics': unlockedCosmetics.toList(),
      'equippedThemeId': equippedThemeId,
      'equippedGridStyleId': equippedGridStyleId,
      'equippedCellAnimationId': equippedCellAnimationId,
      'equippedSoundPackId': equippedSoundPackId,
    };
  }

  factory CosmeticState.fromJson(Map<String, dynamic> json) {
    return CosmeticState(
      unlockedCosmetics: Set<String>.from(
        json['unlockedCosmetics'] as List? ??
            [
              'default_theme',
              'default_grid',
              'default_animation',
              'default_sound',
            ],
      ),
      equippedThemeId: json['equippedThemeId'] as String? ?? 'default_theme',
      equippedGridStyleId:
          json['equippedGridStyleId'] as String? ?? 'default_grid',
      equippedCellAnimationId:
          json['equippedCellAnimationId'] as String? ?? 'default_animation',
      equippedSoundPackId:
          json['equippedSoundPackId'] as String? ?? 'default_sound',
    );
  }

  bool isUnlocked(String cosmeticId) => unlockedCosmetics.contains(cosmeticId);
}

/// Represents a single cell in the grid
class GridCell {
  final int id;
  ColorType color;

  GridCell({required this.id, this.color = ColorType.none});

  GridCell copyWith({int? id, ColorType? color}) {
    return GridCell(id: id ?? this.id, color: color ?? this.color);
  }
}

/// Level configuration
class LevelConfig {
  final int id;
  final int gridSize;
  final int colorCount;
  final int patternSize;
  final double previewSeconds;
  final String difficulty;

  const LevelConfig({
    required this.id,
    required this.gridSize,
    required this.colorCount,
    required this.patternSize,
    required this.previewSeconds,
    required this.difficulty,
  });
}

/// Score state
class ScoreState {
  final int points;
  final int combo;
  final int bestCombo;
  final int level;
  final int highScore;
  final GameMode gameMode;

  const ScoreState({
    this.points = 0,
    this.combo = 0,
    this.bestCombo = 0,
    this.level = 1,
    this.highScore = 0,
    this.gameMode = GameMode.classic,
  });

  ScoreState copyWith({
    int? points,
    int? combo,
    int? bestCombo,
    int? level,
    int? highScore,
    GameMode? gameMode,
  }) {
    return ScoreState(
      points: points ?? this.points,
      combo: combo ?? this.combo,
      bestCombo: bestCombo ?? this.bestCombo,
      level: level ?? this.level,
      highScore: highScore ?? this.highScore,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}

/// Mode-specific progress tracking
class ModeProgress {
  final int highScore;
  final int highestLevel;
  final int totalGamesPlayed;
  final int perfectLevels; // Levels completed without mistakes

  const ModeProgress({
    this.highScore = 0,
    this.highestLevel = 1,
    this.totalGamesPlayed = 0,
    this.perfectLevels = 0,
  });

  ModeProgress copyWith({
    int? highScore,
    int? highestLevel,
    int? totalGamesPlayed,
    int? perfectLevels,
  }) {
    return ModeProgress(
      highScore: highScore ?? this.highScore,
      highestLevel: highestLevel ?? this.highestLevel,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      perfectLevels: perfectLevels ?? this.perfectLevels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highScore': highScore,
      'highestLevel': highestLevel,
      'totalGamesPlayed': totalGamesPlayed,
      'perfectLevels': perfectLevels,
    };
  }

  factory ModeProgress.fromJson(Map<String, dynamic> json) {
    return ModeProgress(
      highScore: json['highScore'] as int? ?? 0,
      highestLevel: json['highestLevel'] as int? ?? 1,
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      perfectLevels: json['perfectLevels'] as int? ?? 0,
    );
  }
}

/// Game settings for brightness and audio
class GameSettings {
  final int brightness;
  final bool musicEnabled;
  final bool soundEnabled;
  final double musicVolume;
  final double soundVolume;

  const GameSettings({
    this.brightness = 100,
    this.musicEnabled = true,
    this.soundEnabled = true,
    this.musicVolume = 1.0,
    this.soundVolume = 1.0,
  });

  GameSettings copyWith({
    int? brightness,
    bool? musicEnabled,
    bool? soundEnabled,
    double? musicVolume,
    double? soundVolume,
  }) {
    return GameSettings(
      brightness: brightness ?? this.brightness,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      soundVolume: soundVolume ?? this.soundVolume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brightness': brightness,
      'musicEnabled': musicEnabled,
      'soundEnabled': soundEnabled,
      'musicVolume': musicVolume,
      'soundVolume': soundVolume,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      brightness: json['brightness'] as int? ?? 100,
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      musicVolume: json['musicVolume'] as double? ?? 1.0,
      soundVolume: json['soundVolume'] as double? ?? 1.0,
    );
  }
}
