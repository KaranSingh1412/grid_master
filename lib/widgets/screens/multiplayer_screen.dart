import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/game_models.dart';
import '../../providers/audio_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/multiplayer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../game/board_decor.dart';
import '../game/grid_style.dart';
import '../tactile/tactile.dart';

/// Two players, one phone lying between them. Player 1 sits opposite, so
/// the top panel is turned upside down.
class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  late final MultiplayerProvider _mp;
  late final AudioProvider _audio;
  MultiplayerPhase _lastPhase = MultiplayerPhase.idle;

  @override
  void initState() {
    super.initState();
    _mp = context.read<MultiplayerProvider>();
    _audio = context.read<AudioProvider>();
    _mp.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audio.stopBackgroundMusic();
    });
  }

  @override
  void dispose() {
    _mp.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final phase = _mp.phase;
    if (phase == _lastPhase) return;
    if (phase == MultiplayerPhase.roundResult ||
        phase == MultiplayerPhase.matchOver) {
      if (_mp.roundWinner != null) {
        HapticFeedback.mediumImpact();
        _audio.playWinSound();
      } else {
        _audio.playLoseSound();
      }
    }
    _lastPhase = phase;
  }

  void _leave() {
    _mp.leave();
    _audio.playBackgroundMusic();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MultiplayerProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: _PlayerPanel(player: 0, palette: palette),
                  ),
                ),
                // The board never takes more than about half the height, so
                // both panels keep room for their keys
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _inMenu(mp)
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: _buildMenu(context, mp, palette),
                        )
                      : ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxHeight * 0.42,
                          ),
                          child: _MultiplayerBoard(palette: palette),
                        ),
                ),
                Expanded(
                  child: _PlayerPanel(
                    player: 1,
                    palette: palette,
                    onClose: _leave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _inMenu(MultiplayerProvider mp) =>
      mp.phase == MultiplayerPhase.idle ||
      mp.phase == MultiplayerPhase.matchOver;

  /// Before the first round and after the match: rules, start and home
  Widget _buildMenu(
    BuildContext context,
    MultiplayerProvider mp,
    TactilePalette palette,
  ) {
    final text = TactileText(palette);
    final isOver = mp.phase == MultiplayerPhase.matchOver;
    return TactileSurface(
      tone: palette.surface,
      radius: TactileRadii.xl,
      softShadow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('mp_title'.tr(), style: text.title),
          const SizedBox(height: 8),
          Text(
            'mp_first_to'.tr(
              namedArgs: {'n': '${MultiplayerProvider.winningScore}'},
            ),
            textAlign: TextAlign.center,
            style: text.body,
          ),
          const SizedBox(height: 16),
          TactileButton(
            tone: palette.cta,
            expand: true,
            softShadow: true,
            padding: const EdgeInsets.symmetric(vertical: 14),
            onTap: () {
              _audio.playUiTapSound();
              mp.startMatch();
            },
            child: Text(
              isOver ? 'mp_rematch'.tr() : 'mp_start'.tr(),
              style: text.button.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          TactileButton(
            tone: palette.raised,
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 11),
            onTap: _leave,
            child: Text('home'.tr(), style: text.button),
          ),
        ],
      ),
    );
  }
}

/// Score, status and color keys of one player
class _PlayerPanel extends StatelessWidget {
  final int player;
  final TactilePalette palette;
  final VoidCallback? onClose;

  const _PlayerPanel({
    required this.player,
    required this.palette,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MultiplayerProvider>();
    final text = TactileText(palette);
    final tone = player == 0 ? palette.gameTones[1] : palette.gameTones[0];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              TactileSurface(
                tone: tone,
                radius: TactileRadii.sm,
                depth: TactileDepth.small,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  'mp_player'.tr(namedArgs: {'n': '${player + 1}'}),
                  style: text.button.copyWith(fontSize: 15, color: tone.ink),
                ),
              ),
              const SizedBox(width: 12),
              // One pip per round won
              for (int i = 0; i < MultiplayerProvider.winningScore; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: i < mp.scores[player]
                          ? palette.cta.face
                          : palette.backgroundDeep,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              const Spacer(),
              if (onClose != null)
                TactileIconButton(
                  icon: Icons.close_rounded,
                  semanticLabel: 'a11y_back'.tr(),
                  tone: palette.raised,
                  iconColor: palette.textPrimary,
                  size: 40,
                  onTap: onClose!,
                ),
            ],
          ),
          // Scales down on short screens instead of pushing the keys away
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildStatus(mp, text),
            ),
          ),
          // No clock and no keys while the menu is up
          if (!_MultiplayerScreenState._inMenu(mp)) ...[
            _buildTimer(mp),
            const SizedBox(height: 10),
            _buildKeys(context, mp),
          ],
        ],
      ),
    );
  }

  Widget _buildStatus(MultiplayerProvider mp, TactileText text) {
    String label;
    Color color = palette.textPrimary;
    switch (mp.phase) {
      case MultiplayerPhase.idle:
        return const SizedBox.shrink();
      case MultiplayerPhase.preview:
        label = 'cue_memorize'.tr();
        color = palette.cta.face;
        break;
      case MultiplayerPhase.rebuild:
        label = mp.isHalfSolved(player) ? '✓' : 'cue_rebuild'.tr();
        color = palette.primary.face;
        break;
      case MultiplayerPhase.roundResult:
        if (mp.roundWinner == null) {
          label = 'mp_round_draw'.tr();
          color = palette.textSecondary;
        } else if (mp.roundWinner == player) {
          label = 'mp_round_won'.tr();
          color = palette.primary.face;
        } else {
          label = 'mp_round_lost'.tr();
          color = palette.danger.face;
        }
        break;
      case MultiplayerPhase.matchOver:
        final won = mp.matchWinner == player;
        label = won ? 'mp_you_win'.tr() : 'mp_you_lose'.tr();
        color = won ? palette.cta.face : palette.danger.face;
        break;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mp.phase != MultiplayerPhase.matchOver)
          Text(
            'mp_round'.tr(namedArgs: {'n': '${mp.round}'}).toUpperCase(),
            style: text.label,
          ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.toUpperCase(),
            style: text.number(34, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildTimer(MultiplayerProvider mp) {
    return ValueListenableBuilder<double>(
      valueListenable: mp.timerListenable,
      builder: (context, timer, _) {
        final progress = mp.maxTimer > 0
            ? (timer / mp.maxTimer).clamp(0.0, 1.0)
            : 0.0;
        final color = mp.phase == MultiplayerPhase.preview
            ? palette.cta.face
            : palette.primary.face;
        return TactileWell(
          color: palette.backgroundDeep,
          radius: 6,
          child: SizedBox(
            height: 10,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeys(BuildContext context, MultiplayerProvider mp) {
    final active =
        mp.phase == MultiplayerPhase.rebuild && !mp.isHalfSolved(player);
    return Opacity(
      opacity: active ? 1 : 0.35,
      child: IgnorePointer(
        ignoring: !active,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final color in mp.availableColors)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _ColorKey(
                  tone: palette.toneOf(color),
                  ring: palette.textPrimary,
                  selected: mp.selectedColor(player) == color,
                  onTap: () => mp.selectColor(player, color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorKey extends StatelessWidget {
  final TactileTone tone;
  final Color ring;
  final bool selected;
  final VoidCallback onTap;

  const _ColorKey({
    required this.tone,
    required this.ring,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    return AnimatedContainer(
      duration: TactileDurations.select,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32 + 3),
        border: Border.all(
          color: selected ? ring : Colors.transparent,
          width: 3,
        ),
      ),
      child: TactileButton(
        tone: tone,
        onTap: onTap,
        width: size,
        height: size,
        radius: size * 0.32,
        padding: EdgeInsets.zero,
        child: const SizedBox.shrink(),
      ),
    );
  }
}

/// The shared 4x4 board. A wider gap splits it into the two halves.
class _MultiplayerBoard extends StatelessWidget {
  final TactilePalette palette;

  const _MultiplayerBoard({required this.palette});

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MultiplayerProvider>();
    final cosmetics = context.select<CreditProvider, CosmeticState>(
      (c) => c.cosmeticState,
    );
    final style = GridStyleSpec.of(cosmetics.equippedGridStyleId, palette);
    final sprite = CellSprite.ofCosmetic(cosmetics.equippedSpriteId);

    final showTarget = mp.phase != MultiplayerPhase.rebuild;
    final cells = showTarget ? mp.target : mp.user;
    const n = MultiplayerProvider.gridSize;
    const gap = 6.0;
    const split = 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = constraints.maxWidth.clamp(0.0, 360.0);
        final cell = (boardWidth - 20 - gap * (n - 1)) / n;

        Widget row(int r) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int c = 0; c < n; c++) ...[
              if (c > 0) const SizedBox(width: gap),
              _cell(context, mp, r * n + c, cells, cell, style, sprite),
            ],
          ],
        );

        return TactileWell(
          color: palette.backgroundDeep,
          radius: style.trayRadius,
          borderColor: style.trayBorder,
          borderWidth: style.trayBorderWidth,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int r = 0; r < n; r++) ...[
                if (r > 0)
                  r == n ~/ 2
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: (split - 4) / 2,
                          ),
                          child: Container(
                            height: 4,
                            width: boardWidth * 0.8,
                            decoration: BoxDecoration(
                              color: palette.textMuted.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )
                      : const SizedBox(height: gap),
                row(r),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _cell(
    BuildContext context,
    MultiplayerProvider mp,
    int index,
    List<ColorType> cells,
    double size,
    GridStyleSpec style,
    CellSprite? sprite,
  ) {
    final color = cells[index];
    final owner = MultiplayerProvider.ownerOf(index);
    // After a round the halves that were not solved show their mistakes
    final isError =
        mp.phase == MultiplayerPhase.roundResult &&
        !mp.isHalfSolved(owner) &&
        mp.user[index] != mp.target[index];

    return Listener(
      // Pointer down instead of a tap: both players tap at the same time
      onPointerDown: (_) {
        if (mp.phase != MultiplayerPhase.rebuild) return;
        HapticFeedback.selectionClick();
        context.read<AudioProvider>().playPlaceSound();
        mp.onCellTap(owner, index);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: TactileCell(
          tone: palette.toneOf(color),
          radius: style.cellRadius,
          filled: color != ColorType.none,
          ringColor: isError ? palette.danger.face : style.cellRing,
          ringWidth: isError ? 3 : style.cellRingWidth,
          sprite: sprite,
        ),
      ),
    );
  }
}
