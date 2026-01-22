import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/game_constants.dart';
import '../../providers/game_provider.dart';
import '../dialogs/settings_dialog.dart';

/// Pause overlay dialog
class PauseOverlay extends StatefulWidget {
  const PauseOverlay({super.key});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final score = gameProvider.score;

    if (!gameProvider.isPaused) {
      return const SizedBox.shrink();
    }

    return Container(
      color: GameColors.slate950.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with glow
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing glow
                  // AnimatedBuilder(
                  //   animation: _pulseAnimation,
                  //   builder: (context, child) {
                  //     return Transform.scale(
                  //       scale: _pulseAnimation.value,
                  //       child: Opacity(
                  //         opacity:
                  //             0.3 + (0.2 * (_pulseAnimation.value - 1.0) * 10),
                  //         child: Container(
                  //           width: 200,
                  //           height: 100,
                  //           decoration: BoxDecoration(
                  //             color: GameColors.emerald500.withValues(
                  //               alpha: 0.3,
                  //             ),
                  //             borderRadius: BorderRadius.circular(50),
                  //             boxShadow: [
                  //               BoxShadow(
                  //                 color: GameColors.emerald500.withValues(
                  //                   alpha: 0.5,
                  //                 ),
                  //                 blurRadius: 40,
                  //                 spreadRadius: 10,
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),

                  // Title text
                  Column(
                    children: [
                      Text(
                        'pause'.tr(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                          shadows: [
                            Shadow(
                              color: GameColors.emerald400.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: GameColors.emerald400.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 40,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: GameColors.emerald400.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 60,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 64,
                        height: 6,
                        decoration: BoxDecoration(
                          color: GameColors.emerald500,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Stats cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'level'.tr(),
                      score.level.toString(),
                      Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'points'.tr(),
                      score.points.toString(),
                      GameColors.emerald400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Continue button
              _buildContinueButton(context, gameProvider),

              const SizedBox(height: 12),

              // Settings button
              _buildSecondaryButton(
                'settings'.tr(),
                () => _showSettings(context),
              ),

              const SizedBox(height: 12),

              // Bottom buttons row
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryButton(
                      'restart'.tr(),
                      () => gameProvider.restart(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSecondaryButton(
                      'quit'.tr(),
                      () => gameProvider.goToHome(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.slate900.withValues(alpha: 0.8),
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
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, GameProvider gameProvider) {
    return GestureDetector(
      onTap: () => gameProvider.resume(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: GameColors.emerald500,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: GameColors.emerald500.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'continue_game'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: GameColors.slate800.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GameColors.slate700),
        ),
        child: Center(
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GameColors.slate300,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SettingsDialog(isFromStartScreen: false),
    );
  }
}
