import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/audio_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../game/block_points.dart';
import '../tactile/tactile.dart';

/// Lifetime statistics of the player
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>().stats;
    final credits = context.watch<CreditProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final text = TactileText(palette);

    final tiles = <(String, String, Color?)>[
      ('stats_best_score', '${stats.bestScore}', palette.accent),
      ('stats_highest_level', '${stats.highestLevel}', null),
      ('stats_games', '${stats.gamesPlayed}', null),
      ('stats_levels', '${stats.levelsSolved}', null),
      ('stats_best_combo', 'x${stats.bestCombo}', TactileColors.orange.face),
      ('stats_avg_points', formatBlockPoints(stats.averageScore), null),
      ('stats_hints', '${stats.hintsUsed}', null),
      ('stats_play_time', _formatDuration(stats.playSeconds), null),
      ('stats_lootboxes', '${stats.lootboxesOpened}', palette.cta.face),
      ('stats_multiplayer', '${stats.multiplayerMatches}', null),
    ];

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            TactileTopBar(
              palette: palette,
              title: 'stats_title'.tr(),
              backLabel: 'a11y_back'.tr(),
              onBack: () {
                context.read<AudioProvider>().playUiTapSound();
                context.pop();
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Blockpunkte: earned in total and what is left to spend
                  TactileSurface(
                    tone: palette.surface,
                    radius: TactileRadii.lg,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        BlockPointIcon(palette: palette, size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'stats_total_points'.tr().toUpperCase(),
                                style: text.label,
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${stats.totalBlockPoints}',
                                  style: text.number(
                                    32,
                                    color: palette.primary.face,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'stats_balance'.tr().toUpperCase(),
                              style: text.label,
                            ),
                            Text(
                              formatBlockPoints(credits.blockPoints),
                              style: text.number(20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.7,
                        ),
                    itemCount: tiles.length,
                    itemBuilder: (context, i) {
                      final (key, value, color) = tiles[i];
                      return TactileWell(
                        color: palette.backgroundDeep,
                        radius: TactileRadii.md,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              key.tr().toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: text.label.copyWith(fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                style: text.number(26, color: color),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 75 -> "1m", 3720 -> "1h 2m"
  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}
