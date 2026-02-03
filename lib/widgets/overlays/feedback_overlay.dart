import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/game_constants.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/audio_provider.dart';
import '../../router/app_router.dart';

/// Game over overlay matching the React FeedbackOverlay
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

    return Container(
      color: GameColors.slate950.withValues(alpha: 0.9),
      child: BackdropFilter(
        filter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.3),
          BlendMode.darken,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildCard(context, gameProvider, score),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    GameProvider gameProvider,
    ScoreState score,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: GameColors.slate900,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: GameColors.slate700.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'wrong'.tr(),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: GameColors.rose400,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'wrong_message'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: GameColors.slate400,
            ),
          ),

          const SizedBox(height: 24),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'points'.tr(),
                  score.points.toString(),
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'max_combo'.tr(),
                  'x${score.bestCombo}',
                  GameColors.orange500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Retry button
          _buildButton(
            context,
            'retry'.tr(),
            GameColors.emerald500,
            GameColors.emerald400,
            () => gameProvider.restart(),
            isPrimary: true,
          ),

          const SizedBox(height: 12),

          // Watch Ad to continue button
          _buildWatchAdButton(context, gameProvider),

          const SizedBox(height: 12),

          // Home button
          _buildButton(
            context,
            'home'.tr(),
            GameColors.slate800,
            GameColors.slate700,
            () {
              context.read<AudioProvider>().playBackgroundMusic();
              gameProvider.goToHome();
              context.go(AppRoutes.home);
            },
            textColor: GameColors.slate300,
          ),

          const SizedBox(height: 16),

          // Best score footer - enhanced
          Column(
            children: [
              Text(
                'best_score'.tr().toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GameColors.slate400,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                score.highScore.toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -2,
                  shadows: [
                    Shadow(
                      color: GameColors.emerald400.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                    Shadow(
                      color: GameColors.emerald400.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.slate800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameColors.slate700.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: GameColors.slate500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchAdButton(BuildContext context, GameProvider gameProvider) {
    final adsProvider = context.watch<AdsProvider>();

    // Verstecke Button wenn bereits benutzt in dieser Runde oder keine Ad geladen
    if (gameProvider.hasUsedContinueThisRound ||
        !adsProvider.isRewardedAdLoaded) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        adsProvider.showRewardedAd(
          onRewarded: () {
            gameProvider.continueAfterAd();
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [GameColors.amber400, GameColors.orange500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: GameColors.amber400.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'watch_ad_continue'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    Color bgColor,
    Color hoverColor,
    VoidCallback onTap, {
    Color textColor = Colors.white,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isPrimary ? 16 : 12,
          horizontal: 32,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: GameColors.slate700),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isPrimary ? 18 : 14,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
