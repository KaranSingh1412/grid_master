import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/game_constants.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';

/// Settings screen as a full page
class SettingsScreen extends StatelessWidget {
  final bool isFromStartScreen;

  const SettingsScreen({super.key, this.isFromStartScreen = false});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final gameProvider = context.watch<GameProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = settingsProvider.brightness;

    final isDefaultTheme =
        themeProvider.currentThemeType == CosmeticThemeType.defaultTheme;
    final backgroundColor = isDefaultTheme
        ? GameColors.slate900
        : themeProvider.backgroundColor;
    final surfaceColor = isDefaultTheme
        ? GameColors.slate800
        : themeProvider.surfaceColor;
    final accentColor = isDefaultTheme
        ? GameColors.emerald400
        : themeProvider.accentColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () {
            context.read<AudioProvider>().playUiTapSound();
            context.pop();
          },
        ),
        title: Text(
          'settings'.tr(),
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brightness slider
              _buildSettingsCard(
                context,
                surfaceColor: surfaceColor,
                child: _buildBrightnessSlider(
                  settingsProvider,
                  brightness,
                  accentColor,
                  surfaceColor,
                ),
              ),

              const SizedBox(height: 16),

              // Music volume slider
              _buildSettingsCard(
                context,
                surfaceColor: surfaceColor,
                child: _buildMusicVolumeSlider(
                  context,
                  settingsProvider,
                  accentColor,
                  surfaceColor,
                ),
              ),

              const SizedBox(height: 16),

              // Sound volume slider
              _buildSettingsCard(
                context,
                surfaceColor: surfaceColor,
                child: _buildSoundVolumeSlider(
                  context,
                  settingsProvider,
                  accentColor,
                  surfaceColor,
                ),
              ),

              const SizedBox(height: 32),

              // End game button (only when not from start screen)
              if (!isFromStartScreen) ...[
                _buildEndGameButton(context, gameProvider, surfaceColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required Color surfaceColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceColor),
      ),
      child: child,
    );
  }

  Widget _buildBrightnessSlider(
    SettingsProvider settingsProvider,
    int brightness,
    Color accentColor,
    Color surfaceColor,
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: surfaceColor,
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.2),
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
    Color accentColor,
    Color surfaceColor,
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor,
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
            activeColor: accentColor,
            inactiveColor: surfaceColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSoundVolumeSlider(
    BuildContext context,
    SettingsProvider settingsProvider,
    Color accentColor,
    Color surfaceColor,
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor,
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
            activeColor: accentColor,
            inactiveColor: surfaceColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEndGameButton(
    BuildContext context,
    GameProvider gameProvider,
    Color surfaceColor,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<AudioProvider>().playUiTapSound();
        context.read<AudioProvider>().playBackgroundMusic();
        gameProvider.goToHome();
        context.go(AppRoutes.home);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: GameColors.rose500.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GameColors.rose500.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Text(
            'end_game'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GameColors.rose400,
            ),
          ),
        ),
      ),
    );
  }
}
