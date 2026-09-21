import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/game_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../tactile/tactile.dart';
import 'overlay_parts.dart';

/// Pause overlay dialog
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final text = TactileText(palette);
    final score = gameProvider.score;

    if (!gameProvider.isPaused) {
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: palette.scrim,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
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
                    'pause'.tr(),
                    style: text.title,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OverlayStat(
                          palette: palette,
                          label: 'level'.tr(),
                          value: score.level.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OverlayStat(
                          palette: palette,
                          label: 'points'.tr(),
                          value: score.points.toString(),
                          valueColor: palette.accent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  OverlayButton(
                    palette: palette,
                    label: 'continue_game'.tr(),
                    tone: palette.primary,
                    large: true,
                    onTap: () => gameProvider.resume(),
                  ),

                  const SizedBox(height: 12),

                  OverlayButton(
                    palette: palette,
                    label: 'settings'.tr().toUpperCase(),
                    tone: palette.raised,
                    onTap: () => context.push(AppRoutes.settingsInGame),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OverlayButton(
                          palette: palette,
                          label: 'restart'.tr().toUpperCase(),
                          tone: palette.raised,
                          onTap: () => gameProvider.restart(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OverlayButton(
                          palette: palette,
                          label: 'quit'.tr().toUpperCase(),
                          tone: palette.raised,
                          onTap: () {
                            gameProvider.goToHome();
                            context.go(AppRoutes.home);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
