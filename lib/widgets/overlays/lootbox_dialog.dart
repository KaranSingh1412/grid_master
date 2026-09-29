import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/progress_models.dart';
import '../../providers/audio_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../game/block_points.dart';
import '../tactile/tactile.dart';

/// Opens the lootbox dialog if a free lootbox is waiting
Future<void> showLootboxDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: context.read<ThemeProvider>().palette.scrim,
    builder: (_) => const _LootboxDialog(),
  );
}

class _LootboxDialog extends StatefulWidget {
  const _LootboxDialog();

  @override
  State<_LootboxDialog> createState() => _LootboxDialogState();
}

class _LootboxDialogState extends State<_LootboxDialog>
    with TickerProviderStateMixin {
  /// The closed box wobbles to ask for a tap
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// The reward pops out of the opened box
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  LootboxReward? _reward;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _wobble.stop();
    } else if (_reward == null && !_wobble.isAnimating) {
      _wobble.repeat();
    }
  }

  @override
  void dispose() {
    _wobble.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _open() {
    if (_reward != null) return;
    final reward = context.read<CreditProvider>().openLootbox();
    if (reward == null) {
      Navigator.of(context).pop();
      return;
    }
    context.read<StatsProvider>().recordLootboxOpened();
    context.read<AudioProvider>().playWinSound();
    HapticFeedback.mediumImpact();
    _wobble.stop();
    setState(() => _reward = reward);
    if (MediaQuery.of(context).disableAnimations) {
      _reveal.value = 1;
    } else {
      _reveal.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final text = TactileText(palette);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            type: MaterialType.transparency,
            child: TactileSurface(
              tone: palette.surface,
              radius: TactileRadii.xl,
              softShadow: true,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'lootbox_title'.tr(),
                    textAlign: TextAlign.center,
                    style: text.title.copyWith(color: palette.cta.face),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: _reward == null
                        ? _buildClosedBox(palette)
                        : _buildReward(palette, text, _reward!),
                  ),
                  const SizedBox(height: 20),
                  TactileButton(
                    tone: _reward == null ? palette.cta : palette.primary,
                    expand: true,
                    softShadow: true,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onTap: _reward == null
                        ? _open
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      _reward == null
                          ? 'lootbox_tap'.tr()
                          : 'lootbox_collect'.tr(),
                      style: text.button.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosedBox(TactilePalette palette) {
    return GestureDetector(
      onTap: _open,
      child: AnimatedBuilder(
        animation: _wobble,
        builder: (context, child) {
          // Two quick shakes, then a rest
          final t = _wobble.value;
          final shake = t < 0.4 ? sin(t / 0.4 * pi * 4) * (1 - t / 0.4) : 0.0;
          return Transform.rotate(angle: shake * 0.12, child: child);
        },
        child: Center(
          child: TactileSurface(
            tone: palette.cta,
            radius: TactileRadii.lg,
            softShadow: true,
            child: SizedBox(
              width: 120,
              height: 110,
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 72,
                color: palette.cta.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReward(
    TactilePalette palette,
    TactileText text,
    LootboxReward reward,
  ) {
    Widget icon;
    String value;
    String label;
    switch (reward.type) {
      case LootboxRewardType.coins:
        icon = Image.asset('assets/img/coin.png', width: 64, height: 64);
        value = '+${reward.amount}';
        label = 'lootbox_reward_coins'.tr();
        break;
      case LootboxRewardType.blockPoints:
        icon = BlockPointIcon(palette: palette, size: 56);
        value = '+${reward.amount}';
        label = 'block_points'.tr();
        break;
      case LootboxRewardType.cosmetic:
        icon = Icon(
          Icons.auto_awesome_rounded,
          size: 64,
          color: palette.cta.face,
        );
        value = reward.cosmetic!.nameKey.tr();
        label = 'lootbox_reward_cosmetic'.tr();
        break;
    }

    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, child) {
        final t = _reveal.value;
        return Opacity(
          opacity: (t * 2).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: TactileCurves.popScale.transform(t),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: text.number(34, color: palette.cta.face)),
          ),
          Text(label.toUpperCase(), style: text.label),
        ],
      ),
    );
  }
}
