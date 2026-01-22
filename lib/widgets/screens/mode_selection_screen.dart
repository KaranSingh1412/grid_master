import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/game_models.dart';
import '../../constants/game_constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/credit_provider.dart';

/// Mode selection screen for choosing between Classic and Color Zen
class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.slate900,
      appBar: AppBar(
        backgroundColor: GameColors.slate900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'game_modes'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Classic Mode Card
              _ModeCard(
                mode: GameMode.classic,
                title: 'game_mode_classic'.tr(),
                description: 'game_mode_classic_desc'.tr(),
                icon: Icons.grid_on_rounded,
                gradientColors: const [
                  GameColors.emerald600,
                  GameColors.emerald500,
                ],
                levelCount: 200,
                onTap: () => _selectMode(context, GameMode.classic),
              ),

              const SizedBox(height: 20),

              // Color Zen Mode Card
              _ModeCard(
                mode: GameMode.colorZen,
                title: 'game_mode_color_zen'.tr(),
                description: 'game_mode_color_zen_desc'.tr(),
                icon: Icons.spa_rounded,
                gradientColors: const [Color(0xFF7DD3C0), Color(0xFF9FD5D1)],
                levelCount: 50,
                badge: 'zen_mode_bonus'.tr(),
                onTap: () => _selectMode(context, GameMode.colorZen),
              ),

              const Spacer(),

              // Progress comparison
              Consumer2<SettingsProvider, CreditProvider>(
                builder: (context, settings, credits, _) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GameColors.slate800,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GameColors.slate700),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ProgressStat(
                            label: 'game_mode_classic'.tr(),
                            level: settings.classicProgress.highestLevel,
                            highScore: settings.classicProgress.highScore,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: GameColors.slate600,
                        ),
                        Expanded(
                          child: _ProgressStat(
                            label: 'game_mode_color_zen'.tr(),
                            level: settings.colorZenProgress.highestLevel,
                            highScore: settings.colorZenProgress.highScore,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMode(BuildContext context, GameMode mode) {
    final gameProvider = context.read<GameProvider>();
    final creditProvider = context.read<CreditProvider>();

    gameProvider.setGameMode(mode);
    creditProvider.resetThreshold();

    // Pop back to start screen and start game
    Navigator.pop(context);
    gameProvider.startGame();
  }
}

class _ModeCard extends StatelessWidget {
  final GameMode mode;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final int levelCount;
  final String? badge;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.levelCount,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$levelCount Levels',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final int level;
  final int highScore;

  const _ProgressStat({
    required this.label,
    required this.level,
    required this.highScore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: GameColors.slate400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${'lvl'.tr()} $level',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          '$highScore ${'points'.tr()}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: GameColors.slate500,
          ),
        ),
      ],
    );
  }
}
