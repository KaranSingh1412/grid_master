import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_master/providers/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/game_constants.dart';
import '../../models/game_models.dart';
import '../../providers/credit_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/purchases_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDefaultTheme =
        themeProvider.currentThemeType == CosmeticThemeType.defaultTheme;
    final backgroundColor = isDefaultTheme
        ? GameColors.slate900
        : themeProvider.backgroundColor;
    final surfaceColor = isDefaultTheme
        ? GameColors.slate800
        : themeProvider.surfaceColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'shop_title'.tr(),
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: themeProvider.accentColor,
          labelColor: themeProvider.accentColor,
          unselectedLabelColor: themeProvider.textSecondaryColor,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'shop_coins_tab'.tr()),
            Tab(text: 'cosmetics_tab_themes'.tr()),
            Tab(text: 'cosmetics_tab_grids'.tr()),
            Tab(text: 'cosmetics_tab_animations'.tr()),
            Tab(text: 'cosmetics_tab_sounds'.tr()),
          ],
        ),
      ),
      body: Column(
        children: [
          // Credits display header
          Consumer<CreditProvider>(
            builder: (context, credits, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.5),
                  border: Border(bottom: BorderSide(color: surfaceColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/img/coin.png', width: 24, height: 24),
                    const SizedBox(width: 8),
                    Text(
                      '${credits.credits}',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.accentColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ShopCoinsTab(),
                _ShopCosmeticCategoryList(category: CosmeticCategory.theme),
                _ShopCosmeticCategoryList(category: CosmeticCategory.gridStyle),
                _ShopCosmeticCategoryList(
                  category: CosmeticCategory.cellAnimation,
                ),
                _ShopCosmeticCategoryList(category: CosmeticCategory.soundPack),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Coins tab with credit packages and remove ads
class _ShopCoinsTab extends StatelessWidget {
  const _ShopCoinsTab();

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: GameColors.rose500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text(
              '+$credits ${'credits_received'.tr()}',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: GameColors.emerald600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRemoveAdsSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'shop_remove_ads_success'.tr(),
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: GameColors.emerald600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _watchAdForCredits(BuildContext context) {
    final creditProvider = context.read<CreditProvider>();
    if (!creditProvider.canWatchAdToday) return;

    final adsProvider = context.read<AdsProvider>();

    adsProvider.showRewardedAd(
      onRewarded: () {
        const int adRewardCredits = 5;
        creditProvider.addCredits(adRewardCredits);
        creditProvider.recordAdWatch();
        _showPurchaseSuccess(context, adRewardCredits);
      },
    );
  }

  void _restorePurchases(BuildContext context) async {
    final purchasesProvider = context.read<PurchasesProvider>();
    final success = await purchasesProvider.restorePurchases();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('shop_restore_success'.tr()),
          backgroundColor: GameColors.emerald600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('shop_restore_none'.tr()),
          backgroundColor: GameColors.slate700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchasesProvider = context.watch<PurchasesProvider>();
    final adsProvider = context.watch<AdsProvider>();
    final creditProvider = context.watch<CreditProvider>();
    final showFreeCredits = adsProvider.isRewardedAdLoaded;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Remove Ads Card (if not already purchased)
          if (!purchasesProvider.isAdFree)
            _buildRemoveAdsCard(context, purchasesProvider),

          if (!purchasesProvider.isAdFree) const SizedBox(height: 16),

          // Free Credits Section
          if (showFreeCredits) _buildFreeCreditsCard(context, creditProvider),

          if (showFreeCredits) const SizedBox(height: 24),

          // Credit Packages Header
          Text(
            'shop_buy_credits'.tr(),
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Credit Packages Grid
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
              return _buildPackageCard(context, package, purchasesProvider);
            },
          ),

          const SizedBox(height: 24),

          // Restore Purchases
          _buildRestoreButton(context, purchasesProvider),

          const SizedBox(height: 16),

          // Info Text
          Text(
            'shop_info'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: GameColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveAdsCard(
    BuildContext context,
    PurchasesProvider purchasesProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameColors.rose500.withValues(alpha: 0.3),
            GameColors.rose400.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.rose500.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GameColors.rose500.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.block, color: GameColors.rose400, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'shop_remove_ads'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'shop_remove_ads_desc'.tr(),
                  style: TextStyle(fontSize: 12, color: GameColors.slate400),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: purchasesProvider.isPurchasing
                ? null
                : () => _purchaseRemoveAds(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: GameColors.rose500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: purchasesProvider.isPurchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'shop_buy'.tr(),
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeCreditsCard(
    BuildContext context,
    CreditProvider creditProvider,
  ) {
    final canWatch = creditProvider.canWatchAdToday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canWatch
              ? [
                  GameColors.emerald600.withValues(alpha: 0.3),
                  GameColors.emerald500.withValues(alpha: 0.2),
                ]
              : [
                  GameColors.slate700.withValues(alpha: 0.3),
                  GameColors.slate600.withValues(alpha: 0.2),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canWatch
              ? GameColors.emerald500.withValues(alpha: 0.5)
              : GameColors.slate600.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: canWatch
                  ? GameColors.emerald500.withValues(alpha: 0.3)
                  : GameColors.slate600.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              canWatch ? Icons.play_circle_outline : Icons.check_circle,
              color: canWatch ? GameColors.emerald400 : GameColors.slate500,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'shop_free_credits'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: canWatch ? Colors.white : GameColors.slate400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  canWatch
                      ? 'shop_watch_ad'.tr()
                      : 'shop_ad_watched_today'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: canWatch ? GameColors.slate400 : GameColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: canWatch ? () => _watchAdForCredits(context) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: canWatch ? GameColors.emerald500 : GameColors.slate700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/img/coin.png', width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+5',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: canWatch ? Colors.white : GameColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    CreditPackage package,
    PurchasesProvider purchasesProvider,
  ) {
    return GestureDetector(
      onTap: () => _purchasePackage(context, package),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GameColors.slate800,
              GameColors.slate800.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameColors.violet500.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Coin icon
              Image.asset('assets/img/coin.png', width: 48, height: 48),

              const SizedBox(height: 8),

              // Credits amount
              Text(
                '${package.credits}',
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: GameColors.amber400,
                ),
              ),

              Text(
                'credits'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: GameColors.slate400,
                ),
              ),

              const Spacer(),

              // Price button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: GameColors.slate700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: purchasesProvider.isPurchasing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '€${package.price.toStringAsFixed(2)}',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton(
    BuildContext context,
    PurchasesProvider purchasesProvider,
  ) {
    return GestureDetector(
      onTap: purchasesProvider.isPurchasing
          ? null
          : () => _restorePurchases(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: GameColors.slate800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GameColors.slate700),
        ),
        child: Center(
          child: purchasesProvider.isPurchasing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'shop_restore_purchases'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GameColors.slate400,
                  ),
                ),
        ),
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
    final themeColors = item.themeType != null
        ? CosmeticThemeColors.getTheme(item.themeType!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GameColors.slate800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEquipped ? GameColors.emerald500 : GameColors.slate700,
          width: isEquipped ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Theme preview (for themes)
            if (themeColors != null)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColors.primary, themeColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColors.accent, width: 2),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: GameColors.slate700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: isUnlocked
                      ? GameColors.emerald400
                      : GameColors.slate500,
                  size: 24,
                ),
              ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameKey.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? Colors.white : GameColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isUnlocked && item.cosmeticCost > 0)
                    Row(
                      children: [
                        Image.asset(
                          'assets/img/coin.png',
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.cosmeticCost}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: GameColors.amber400,
                          ),
                        ),
                      ],
                    )
                  else if (isEquipped)
                    Text(
                      'cosmetics_equipped'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GameColors.emerald400,
                      ),
                    ),
                ],
              ),
            ),

            // Action button
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: GameColors.emerald500.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.check, color: GameColors.emerald400, size: 20),
      );
    }

    if (isUnlocked) {
      return GestureDetector(
        onTap: onEquip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: GameColors.slate700,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'cosmetics_equip'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (item.cosmeticCost > 0) {
      final canAfford = coinCredits >= item.cosmeticCost;
      return GestureDetector(
        onTap: canAfford ? onPurchase : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: canAfford ? GameColors.amber500 : GameColors.slate700,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/img/coin.png', width: 14, height: 14),
              const SizedBox(width: 4),
              Text(
                '${item.cosmeticCost}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: canAfford ? Colors.white : GameColors.slate500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: GameColors.slate700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.lock, color: GameColors.slate500, size: 16),
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
    }
  }
}
