import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../tactile/tactile.dart';

/// Settings screen as a full page
class SettingsScreen extends StatelessWidget {
  final bool isFromStartScreen;

  const SettingsScreen({super.key, this.isFromStartScreen = false});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final gameProvider = context.read<GameProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final text = TactileText(palette);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: palette.textPrimary),
          onPressed: () {
            context.read<AudioProvider>().playUiTapSound();
            context.pop();
          },
        ),
        title: Text('settings'.tr(), style: text.heading),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSlider(
                palette,
                label: 'brightness'.tr(),
                valueLabel: '${settingsProvider.brightness}%',
                value: settingsProvider.brightness.toDouble(),
                min: 30,
                max: 150,
                onChanged: (value) =>
                    settingsProvider.setBrightness(value.round()),
              ),

              const SizedBox(height: 14),

              _buildSlider(
                palette,
                label: 'music_volume'.tr(),
                valueLabel:
                    '${(settingsProvider.musicVolume * 100).toStringAsFixed(0)}%',
                value: settingsProvider.musicVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) {
                  settingsProvider.setMusicVolume(value);
                  context.read<AudioProvider>().setMusicVolume(value);
                },
              ),

              const SizedBox(height: 14),

              _buildSlider(
                palette,
                label: 'sound_volume'.tr(),
                valueLabel:
                    '${(settingsProvider.soundVolume * 100).toStringAsFixed(0)}%',
                value: settingsProvider.soundVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) {
                  settingsProvider.setSoundVolume(value);
                  context.read<AudioProvider>().setSoundVolume(value);
                },
              ),

              // End game button (only when not from start screen)
              if (!isFromStartScreen) ...[
                const SizedBox(height: 28),
                TactileButton(
                  tone: palette.danger,
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onTap: () {
                    context.read<AudioProvider>().playUiTapSound();
                    context.read<AudioProvider>().playBackgroundMusic();
                    gameProvider.goToHome();
                    context.go(AppRoutes.home);
                  },
                  child: Text('end_game'.tr(), style: text.button),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(
    TactilePalette palette, {
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    final text = TactileText(palette);

    return TactileSurface(
      tone: palette.surface,
      radius: TactileRadii.lg,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: text.label.copyWith(
                  fontSize: 13,
                  color: palette.textSecondary,
                ),
              ),
              Text(valueLabel, style: text.number(16, color: palette.accent)),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: palette.primary.face,
              inactiveTrackColor: palette.backgroundDeep,
              thumbColor: palette.textPrimary,
              overlayColor: palette.primary.face.withValues(alpha: 0.18),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 13,
                elevation: 3,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
