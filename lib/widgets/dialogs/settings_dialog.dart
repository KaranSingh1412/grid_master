import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/game_constants.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';

/// Settings dialog matching the React implementation
class SettingsDialog extends StatelessWidget {
  final bool isFromStartScreen;

  const SettingsDialog({super.key, this.isFromStartScreen = false});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final gameProvider = context.watch<GameProvider>();
    final brightness = settingsProvider.brightness;

    return Material(
      color: GameColors.slate950.withValues(alpha: 0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: GameColors.slate900,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: GameColors.slate700),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'settings'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<AudioProvider>().playUiTapSound();
                        Navigator.of(context).pop();
                      },
                      child: const Icon(
                        Icons.close,
                        color: GameColors.slate400,
                        size: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Brightness slider
                _buildBrightnessSlider(settingsProvider, brightness),

                const SizedBox(height: 24),

                // Music volume slider
                _buildMusicVolumeSlider(context, settingsProvider),

                const SizedBox(height: 24),

                // Sound volume slider
                _buildSoundVolumeSlider(context, settingsProvider),

                const SizedBox(height: 32),

                // Done button
                _buildDoneButton(context),

                // End game button (only when not from start screen)
                if (!isFromStartScreen) ...[
                  const SizedBox(height: 12),
                  _buildEndGameButton(context, gameProvider),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessSlider(
    SettingsProvider settingsProvider,
    int brightness,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'brightness'.tr().toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GameColors.slate300,
                letterSpacing: 2,
              ),
            ),
            Text(
              '$brightness%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: GameColors.emerald400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: GameColors.emerald500,
            inactiveTrackColor: GameColors.slate800,
            thumbColor: GameColors.emerald400,
            overlayColor: GameColors.emerald500.withValues(alpha: 0.2),
            trackHeight: 12,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: brightness.toDouble(),
            min: 30,
            max: 150,
            onChanged: (value) => settingsProvider.setBrightness(value.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicVolumeSlider(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'music_volume'.tr().toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GameColors.slate300,
                letterSpacing: 2,
              ),
            ),
            Text(
              '${(settingsProvider.musicVolume * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GameColors.emerald400,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: settingsProvider.musicVolume,
            onChanged: (value) {
              settingsProvider.setMusicVolume(value);
              context.read<AudioProvider>().setMusicVolume(value);
            },
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: GameColors.emerald400,
            inactiveColor: GameColors.slate700,
          ),
        ),
      ],
    );
  }

  Widget _buildSoundVolumeSlider(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'sound_volume'.tr().toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GameColors.slate300,
                letterSpacing: 2,
              ),
            ),
            Text(
              '${(settingsProvider.soundVolume * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GameColors.emerald400,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: settingsProvider.soundVolume,
            onChanged: (value) {
              settingsProvider.setSoundVolume(value);
              context.read<AudioProvider>().setSoundVolume(value);
            },
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: GameColors.emerald400,
            inactiveColor: GameColors.slate700,
          ),
        ),
      ],
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'done'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: GameColors.slate900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndGameButton(BuildContext context, GameProvider gameProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        context.read<AudioProvider>().playBackgroundMusic();
        gameProvider.goToHome();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: GameColors.slate800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GameColors.slate700),
        ),
        child: Center(
          child: Text(
            'end_game'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GameColors.slate400,
            ),
          ),
        ),
      ),
    );
  }
}
