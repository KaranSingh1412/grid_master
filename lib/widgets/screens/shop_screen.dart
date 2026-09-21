import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_master/providers/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/game_constants.dart';
import '../../models/game_models.dart';
import '../../providers/credit_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../effects/bump.dart';
import '../effects/count_up_text.dart';
import '../effects/grid_collapse.dart';
import '../effects/grid_collapse_preview.dart';
import '../tactile/tactile.dart';

/// Credit package definition
class CreditPackage {
  final String id;
  final String nameKey;
  final int credits;
  final double price;
  final String? badge;

  const CreditPackage({
    required this.id,
    required this.nameKey,
    required this.credits,
    required this.price,
    this.badge,
  });

  double get pricePerCredit => price / credits;
}

/// Available credit packages
const List<CreditPackage> creditPackages = [
  CreditPackage(
    id: 'coins_50',
    nameKey: 'shop_pack_small',
    credits: 50,
    price: 0.99,
  ),
  CreditPackage(
    id: 'coins_150',
    nameKey: 'shop_pack_medium',
    credits: 150,
    price: 2.49,
  ),
  CreditPackage(
    id: 'coins_400',
    nameKey: 'shop_pack_large',
    credits: 400,
    price: 4.99,
  ),
  CreditPackage(
    id: 'coins_1000',
    nameKey: 'shop_pack_mega',
    credits: 1000,
    price: 9.99,
  ),
];

/// Unified shop screen with tabs for Coins and Cosmetics
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TactileTopBar(
              palette: palette,
              title: 'shop_title'.tr(),
              backLabel: 'a11y_back'.tr(),
              onBack: () => context.pop(),
              trailing: _CoinBalance(palette: palette),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TactileTabs(
                palette: palette,
                controller: _tabController,
                labels: [
                  'shop_coins_tab'.tr(),
                  'cosmetics_tab_themes'.tr(),
                  'cosmetics_tab_grids'.tr(),
                  'cosmetics_tab_animations'.tr(),
                  'cosmetics_tab_lose'.tr(),
                  'cosmetics_tab_sounds'.tr(),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ShopCoinsTab(),
                  _ShopCosmeticCategoryList(category: CosmeticCategory.theme),
                  _ShopCosmeticCategoryList(
                    category: CosmeticCategory.gridStyle,
                  ),
                  _ShopCosmeticCategoryList(
                    category: CosmeticCategory.cellAnimation,
                  ),
                  _ShopCosmeticCategoryList(
                    category: CosmeticCategory.loseAnimation,
                  ),
                  _ShopCosmeticCategoryList(
                    category: CosmeticCategory.soundPack,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coin balance in the app bar
class _CoinBalance extends StatelessWidget {
  final TactilePalette palette;

  const _CoinBalance({required this.palette});

  @override
  Widget build(BuildContext context) {
    final credits = context.select<CreditProvider, int>((c) => c.credits);

    // Every change of the balance kicks the pill; gains also count up
    return Bump(
      trigger: credits,
      scale: 1.22,
      rotate: 0.06,
      child: TactileSurface(
        tone: palette.surface,
        radius: TactileRadii.pill,
        depth: TactileDepth.small,
        padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/coin.png', width: 22, height: 22),
            const SizedBox(width: 6),
            CountUpText(
              value: credits,
              style: TactileText(
                palette,
              ).number(18, color: palette.cta.face, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coins tab with credit packages and remove ads
class _ShopCoinsTab extends StatelessWidget {
  const _ShopCoinsTab();

  void _showError(BuildContext context, String message) {
    final palette = context.read<ThemeProvider>().palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: palette.danger.ink)),
        backgroundColor: palette.danger.face,
      ),
    );
  }

  void _showPurchaseSuccess(BuildContext context, int credits) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Image.asset('assets/img/coin.png', width: 24, height: 24),
            const SizedBox(width: 8),
            Text('+$credits ${'credits_received'.tr()}'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRemoveAdsSuccess(BuildContext context) {
    final palette = context.read<ThemeProvider>().palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: palette.primary.face, size: 24),
            const SizedBox(width: 8),
            Text('shop_remove_ads_success'.tr()),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    String packageId, {
    String searchPattern = '',
    VoidCallback? onSuccess,
  }) async {
    final purchasesProvider = context.read<PurchasesProvider>();
    if (purchasesProvider.isPurchasing) return;

    final rcPackages = purchasesProvider.availablePackages;

    var matchingPackage = rcPackages
        .where((p) => p.storeProduct.identifier == packageId)
        .firstOrNull;

    matchingPackage ??= rcPackages
        .where(
          (p) => p.storeProduct.identifier.contains(
            searchPattern.isEmpty ? packageId : searchPattern,
          ),
        )
        .firstOrNull;

    if (matchingPackage == null) {
      _showError(context, 'shop_product_not_available'.tr());
      return;
    }

    final success = await purchasesProvider.purchasePackage(matchingPackage);

    if (!success) {
      _showError(context, 'shop_purchase_cancelled'.tr());
      purchasesProvider.clearError();
      return;
    }
    onSuccess?.call();
  }

  void _purchaseRemoveAds(BuildContext context) {
    _handlePurchase(
      context,
      'remove_ads',
      onSuccess: () {
        context.read<AdsProvider>().setAdFree(true);
        _showRemoveAdsSuccess(context);
      },
    );
  }

  void _purchasePackage(BuildContext context, CreditPackage package) {
    _handlePurchase(
      context,
      package.id,
      onSuccess: () {
        context.read<CreditProvider>().addCredits(package.credits);
        _showPurchaseSuccess(context, package.credits);
      },
    );
  }

  void _restorePurchases(BuildContext context) async {
    final purchasesProvider = context.read<PurchasesProvider>();
    final success = await purchasesProvider.restorePurchases();

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('shop_restore_success'.tr())));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('shop_restore_none'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchasesProvider = context.watch<PurchasesProvider>();
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final text = TactileText(palette);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Remove Ads (if not already purchased)
          if (!purchasesProvider.isAdFree) ...[
            _buildOfferRow(
              palette,
              icon: Icons.block,
              iconTone: palette.danger,
              title: 'shop_remove_ads'.tr(),
              subtitle: 'shop_remove_ads_desc'.tr(),
              action: TactileButton(
                tone: palette.danger,
                depth: TactileDepth.small,
                radius: TactileRadii.sm,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                onTap: purchasesProvider.isPurchasing
                    ? null
                    : () => _purchaseRemoveAds(context),
                child: purchasesProvider.isPurchasing
                    ? _spinner(palette.danger.ink)
                    : Text(
                        'shop_buy'.tr(),
                        style: text.button.copyWith(fontSize: 15),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          Text(
            'shop_buy_credits'.tr(),
            style: text.heading.copyWith(fontSize: 20),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: creditPackages.length,
            itemBuilder: (context, index) {
              final package = creditPackages[index];
              return _buildPackageKey(
                context,
                palette,
                package,
                purchasesProvider,
              );
            },
          ),

          const SizedBox(height: 24),

          TactileButton(
            tone: palette.raised,
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onTap: purchasesProvider.isPurchasing
                ? null
                : () => _restorePurchases(context),
            child: purchasesProvider.isPurchasing
                ? _spinner(palette.raised.ink)
                : Text(
                    'shop_restore_purchases'.tr(),
                    style: text.button.copyWith(fontSize: 16),
                  ),
          ),

          const SizedBox(height: 16),

          Text(
            'shop_info'.tr(),
            textAlign: TextAlign.center,
            style: text.body.copyWith(fontSize: 12, color: palette.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _spinner(Color color) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  Widget _buildOfferRow(
    TactilePalette palette, {
    required IconData icon,
    required TactileTone iconTone,
    required String title,
    required String subtitle,
    required Widget action,
    bool dimmed = false,
  }) {
    final text = TactileText(palette);
    return TactileSurface(
      tone: palette.surface,
      radius: TactileRadii.lg,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          TactileSurface(
            tone: iconTone,
            radius: TactileRadii.sm,
            depth: TactileDepth.small,
            child: SizedBox(
              width: 48,
              height: 44,
              child: Icon(icon, color: iconTone.ink, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.button.copyWith(
                    fontSize: 16,
                    color: dimmed ? palette.textSecondary : palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.body.copyWith(
                    fontSize: 13,
                    color: dimmed ? palette.textMuted : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          action,
        ],
      ),
    );
  }

  Widget _buildPackageKey(
    BuildContext context,
    TactilePalette palette,
    CreditPackage package,
    PurchasesProvider purchasesProvider,
  ) {
    final text = TactileText(palette);

    // The whole package is one big key
    return TactileButton(
      tone: palette.surface,
      radius: TactileRadii.lg,
      padding: const EdgeInsets.all(14),
      onTap: () => _purchasePackage(context, package),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/img/coin.png', width: 48, height: 48),
          const SizedBox(height: 6),
          Text(
            '${package.credits}',
            style: text.number(28, color: palette.cta.face),
          ),
          Text('credits'.tr(), style: text.body.copyWith(fontSize: 13)),
          const Spacer(),
          TactileSurface(
            tone: palette.cta,
            radius: TactileRadii.sm,
            depth: TactileDepth.small,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: purchasesProvider.isPurchasing
                  ? _spinner(palette.cta.ink)
                  : Text(
                      '€${package.price.toStringAsFixed(2)}',
                      style: text.number(
                        16,
                        color: palette.cta.ink,
                        weight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cosmetic category list widget
class _ShopCosmeticCategoryList extends StatelessWidget {
  final CosmeticCategory category;

  const _ShopCosmeticCategoryList({required this.category});

  @override
  Widget build(BuildContext context) {
    final items = allCosmetics.where((c) => c.category == category).toList();
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    return Consumer2<CreditProvider, SettingsProvider>(
      builder: (context, credits, settings, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _ShopCosmeticItemCard(
              item: item,
              isUnlocked: credits.cosmeticState.isUnlocked(item.id),
              isEquipped: _isEquipped(credits.cosmeticState, item),
              coinCredits: credits.credits,
              onEquip: () {
                credits.equipCosmetic(item);
                // Theme sofort aktualisieren wenn ein Theme ausgewählt wird
                if (item.category == CosmeticCategory.theme) {
                  context.read<ThemeProvider>().updateFromThemeId(item.id);
                }
                if (item.category == CosmeticCategory.soundPack) {
                  audioProvider.setEquippedSoundPack(item.id);
                  audioProvider.restartBackgroundMusic();
                }
              },
              onPurchase: () =>
                  credits.purchaseCosmetic(item.id, item.cosmeticCost),
              onUnlockByLevel: () => credits.unlockCosmeticByLevel(item.id),
            );
          },
        );
      },
    );
  }

  bool _isEquipped(CosmeticState state, CosmeticItem item) {
    switch (item.category) {
      case CosmeticCategory.theme:
        return state.equippedThemeId == item.id;
      case CosmeticCategory.gridStyle:
        return state.equippedGridStyleId == item.id;
      case CosmeticCategory.cellAnimation:
        return state.equippedCellAnimationId == item.id;
      case CosmeticCategory.soundPack:
        return state.equippedSoundPackId == item.id;
      case CosmeticCategory.loseAnimation:
        return state.equippedLoseAnimationId == item.id;
    }
  }
}

/// Cosmetic item card widget
class _ShopCosmeticItemCard extends StatelessWidget {
  final CosmeticItem item;
  final bool isUnlocked;
  final bool isEquipped;
  final int coinCredits;
  final VoidCallback onEquip;
  final VoidCallback onPurchase;
  final VoidCallback onUnlockByLevel;

  const _ShopCosmeticItemCard({
    required this.item,
    required this.isUnlocked,
    required this.isEquipped,
    required this.coinCredits,
    required this.onEquip,
    required this.onPurchase,
    required this.onUnlockByLevel,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.select<ThemeProvider, TactilePalette>(
      (t) => t.palette,
    );
    final text = TactileText(palette);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Bump(
        // Buying or equipping kicks the card
        trigger: '$isUnlocked-$isEquipped',
        scale: 1.05,
        child: _buildCard(palette, text),
      ),
    );
  }

  Widget _buildCard(TactilePalette palette, TactileText text) {
    return Padding(
      padding: EdgeInsets.zero,
      child: TactileSurface(
        tone: palette.surface,
        radius: TactileRadii.lg,
        ringColor: isEquipped ? palette.primary.face : null,
        ringWidth: isEquipped ? 3 : 0,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _buildPreview(palette),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameKey.tr(),
                    style: text.button.copyWith(
                      fontSize: 16,
                      color: isUnlocked
                          ? palette.textPrimary
                          : palette.textSecondary,
                    ),
                  ),
                  if (isEquipped) ...[
                    const SizedBox(height: 2),
                    Text(
                      'cosmetics_equipped'.tr(),
                      style: text.body.copyWith(
                        fontSize: 13,
                        color: palette.primary.face,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            _buildActionButton(palette, text),
          ],
        ),
      ),
    );
  }

  /// Themes preview as a mini board in their own colors, lose animations
  /// play on one, the rest shows an icon
  Widget _buildPreview(TactilePalette palette) {
    if (item.themeType != null) {
      final preview = TactilePalette.fromTheme(
        item.themeType!,
        CosmeticThemeColors.getTheme(item.themeType!),
      );
      return Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: preview.background,
          borderRadius: BorderRadius.circular(TactileRadii.sm),
          border: Border.all(color: preview.surface.face, width: 2),
        ),
        child: GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final tone in [
              preview.gameTones[0],
              preview.gameTones[1],
              preview.gameTones[2],
              preview.primary,
            ])
              CustomPaint(
                painter: TactilePainter(
                  tone: tone,
                  radius: 5,
                  depth: const TactileDepth(lip: 3, lipPressed: 1),
                  sheen: false,
                ),
              ),
          ],
        ),
      );
    }

    // Lose animations play on a mini board, so they can be seen before buying
    final collapse = GridCollapseKind.ofCosmetic(item.id);
    if (collapse != null) {
      return GridCollapsePreview(kind: collapse, palette: palette);
    }

    final tone = isUnlocked
        ? palette.raised
        : palette.raised.muted(palette.surface.face);
    return TactileSurface(
      tone: tone,
      radius: TactileRadii.sm,
      depth: TactileDepth.small,
      child: SizedBox(
        width: 52,
        height: 48,
        child: Icon(
          _getCategoryIcon(),
          color: isUnlocked ? palette.accent : palette.textMuted,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildActionButton(TactilePalette palette, TactileText text) {
    const pad = EdgeInsets.symmetric(horizontal: 14, vertical: 8);

    if (isEquipped) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Bump(
          trigger: true,
          animateOnAppear: true,
          scale: 1.5,
          child: Icon(
            Icons.check_circle,
            color: palette.primary.face,
            size: 28,
          ),
        ),
      );
    }

    if (isUnlocked) {
      return TactileButton(
        tone: palette.raised,
        depth: TactileDepth.small,
        radius: TactileRadii.sm,
        padding: pad,
        onTap: onEquip,
        child: Text(
          'cosmetics_equip'.tr(),
          style: text.button.copyWith(fontSize: 14),
        ),
      );
    }

    if (item.cosmeticCost > 0) {
      final canAfford = coinCredits >= item.cosmeticCost;
      final muted = palette.raised.muted(palette.surface.face);
      return TactileButton(
        tone: palette.cta,
        disabledTone: muted,
        depth: TactileDepth.small,
        radius: TactileRadii.sm,
        padding: pad,
        onTap: canAfford ? onPurchase : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/coin.png', width: 16, height: 16),
            const SizedBox(width: 4),
            Text(
              '${item.cosmeticCost}',
              style: text.number(
                14,
                color: canAfford ? palette.cta.ink : palette.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Icon(Icons.lock, color: palette.textMuted, size: 20),
    );
  }

  IconData _getCategoryIcon() {
    switch (item.category) {
      case CosmeticCategory.theme:
        return Icons.palette_outlined;
      case CosmeticCategory.gridStyle:
        return Icons.grid_on_rounded;
      case CosmeticCategory.cellAnimation:
        return Icons.auto_awesome_motion_rounded;
      case CosmeticCategory.soundPack:
        return Icons.music_note_rounded;
      case CosmeticCategory.loseAnimation:
        return Icons.block_rounded;
    }
  }
}
