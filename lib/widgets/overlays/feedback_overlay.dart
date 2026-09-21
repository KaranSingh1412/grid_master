import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../effects/overlay_entrance.dart';
import '../tactile/tactile.dart';
import 'overlay_parts.dart';

/// Game over overlay
class FeedbackOverlay extends StatefulWidget {
  const FeedbackOverlay({super.key});

  @override
  State<FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<FeedbackOverlay> {
  bool _hasRecordedLoss = false;

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final adsProvider = context.watch<AdsProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final score = gameProvider.score;

    if (!gameProvider.isGameOver) {
      _hasRecordedLoss = false;
      return const SizedBox.shrink();
    }

    // Record loss for interstitial ads (only once per game over)
    if (!_hasRecordedLoss) {
      _hasRecordedLoss = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adsProvider.recordLoss();
      });
    }

    return OverlayEntrance(
      scrim: palette.scrim,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildCard(context, gameProvider, palette, score),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    GameProvider gameProvider,
    TactilePalette palette,
    ScoreState score,
  ) {
    final text = TactileText(palette);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: TactileSurface(
        tone: palette.surface,
        radius: TactileRadii.xl,
        softShadow: true,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'wrong'.tr(),
              style: text.title.copyWith(color: palette.danger.face),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'wrong_message'.tr(),
              textAlign: TextAlign.center,
              style: text.body,
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OverlayStat(
                    palette: palette,
                    label: 'points'.tr(),
                    value: score.points.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OverlayStat(
                    palette: palette,
                    label: 'max_combo'.tr(),
                    value: 'x${score.bestCombo}',
                    valueColor: TactileColors.orange.face,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            OverlayButton(
              palette: palette,
              label: 'retry'.tr(),
              tone: palette.primary,
              large: true,
              onTap: () => gameProvider.restart(),
            ),

            _buildWatchAdButton(context, gameProvider, palette),

            const SizedBox(height: 12),

            OverlayButton(
              palette: palette,
              label: 'home'.tr(),
              tone: palette.raised,
              onTap: () {
                context.read<AudioProvider>().playBackgroundMusic();
                gameProvider.goToHome();
                context.go(AppRoutes.home);
              },
            ),

            const SizedBox(height: 20),

            Text('best_score'.tr().toUpperCase(), style: text.label),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                score.highScore.toString(),
                style: text.number(44, color: palette.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchAdButton(
    BuildContext context,
    GameProvider gameProvider,
    TactilePalette palette,
  ) {
    final adsProvider = context.watch<AdsProvider>();

    // Verstecke Button wenn bereits benutzt in dieser Runde oder keine Ad geladen
    if (gameProvider.hasUsedContinueThisRound ||
        !adsProvider.isRewardedAdLoaded) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OverlayButton(
        palette: palette,
        label: 'watch_ad_continue'.tr(),
        tone: palette.cta,
        icon: Icons.play_circle_filled,
        onTap: () {
          adsProvider.showRewardedAd(
            onRewarded: () {
              gameProvider.continueAfterAd();
            },
          );
        },
      ),
    );
  }
}
