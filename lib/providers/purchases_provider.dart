import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// RevenueCat entitlement identifiers
class Entitlements {
  static String get coins50 =>
      dotenv.env['REVENUECAT_ENTITLEMENT_COINS_50'] ?? '50_coins';
  static String get removeAds =>
      dotenv.env['REVENUECAT_ENTITLEMENT_REMOVE_ADS'] ?? 'remove_ads';
}

/// RevenueCat product identifiers
class Products {
  static String get coins50 =>
      dotenv.env['REVENUECAT_PRODUCT_COINS_50'] ?? 'coins_50';
  static String get coins150 =>
      dotenv.env['REVENUECAT_PRODUCT_COINS_150'] ?? 'coins_150';
  static String get coins400 =>
      dotenv.env['REVENUECAT_PRODUCT_COINS_400'] ?? 'coins_400';
  static String get coins1000 =>
      dotenv.env['REVENUECAT_PRODUCT_COINS_1000'] ?? 'coins_1000';
  static String get removeAds =>
      dotenv.env['REVENUECAT_PRODUCT_REMOVE_ADS'] ?? 'remove_ads';
  static const String lifetime = 'lifetime';
}

/// Provider for managing RevenueCat purchases and subscriptions
class PurchasesProvider extends ChangeNotifier {
  // API Keys from environment variables
  static String get _apiKeyAndroid =>
      dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? '';
  static String get _apiKeyIOS => dotenv.env['REVENUECAT_API_KEY_IOS'] ?? '';

  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  bool _isInitialized = false;
  bool _isPurchasing = false;
  String? _error;
  bool _purchaseCancelled = false;

  // Getters
  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  bool get isInitialized => _isInitialized;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;
  bool get purchaseCancelled => _purchaseCancelled;

  /// Check if user has the 50_coins entitlement
  bool get has50CoinsEntitlement {
    return _customerInfo?.entitlements.active.containsKey(
          Entitlements.coins50,
        ) ??
        false;
  }

  /// Check if user has purchased ad-free
  bool get isAdFree {
    return _customerInfo?.entitlements.active.containsKey(
          Entitlements.removeAds,
        ) ??
        false;
  }

  /// Check if user has any active entitlement
  bool get hasActiveEntitlement {
    return _customerInfo?.entitlements.active.isNotEmpty ?? false;
  }

  /// Get the lifetime offering package if available
  Package? get lifetimePackage {
    return _offerings?.current?.lifetime;
  }

  /// Get all available packages
  List<Package> get availablePackages {
    return _offerings?.current?.availablePackages ?? [];
  }

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    try {
      // Configure RevenueCat
      final configuration = PurchasesConfiguration(
        Platform.isIOS ? _apiKeyIOS : _apiKeyAndroid,
      );

      // Enable debug logs in debug mode
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      await Purchases.configure(configuration);

      // Listen for customer info updates
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        notifyListeners();
      });

      // Get initial customer info and offerings
      await _refreshCustomerInfo();
      await _refreshOfferings();

      _isInitialized = true;
      _error = null;
      notifyListeners();

      debugPrint('RevenueCat initialized successfully');
      debugPrint('Ad-free status: $isAdFree');
    } catch (e) {
      _error = 'Failed to initialize RevenueCat: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  /// Check and refresh ad-free status from RevenueCat
  /// Call this on app start to ensure entitlements are up to date
  Future<bool> checkAdFreeStatus() async {
    try {
      await _refreshCustomerInfo();
      debugPrint('Ad-free status checked: $isAdFree');
      return isAdFree;
    } catch (e) {
      debugPrint('Failed to check ad-free status: $e');
      return false;
    }
  }

  /// Refresh customer info from RevenueCat
  Future<void> _refreshCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to get customer info: $e');
    }
  }

  /// Refresh offerings from RevenueCat
  Future<void> _refreshOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
    }
  }

  /// Purchase a package
  Future<bool> purchasePackage(Package package) async {
    if (_isPurchasing) return false;

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _customerInfo = result.customerInfo;
      _isPurchasing = false;
      notifyListeners();

      // Purchase was successful if no exception was thrown
      // For consumables (credits), there won't be an active entitlement
      // For non-consumables (remove_ads), check if entitlement is active
      final isNonConsumable =
          _customerInfo?.entitlements.active.isNotEmpty ?? false;
      final hasNewTransaction =
          result.customerInfo.nonSubscriptionTransactions.isNotEmpty;

      if (isNonConsumable || hasNewTransaction) {
        debugPrint(
          'Purchase successful! Non-consumable: $isNonConsumable, Has transaction: $hasNewTransaction',
        );
        return true;
      }

      // If we reach here without exception, the purchase was still successful
      debugPrint('Purchase completed successfully');
      return true;
    } on PurchasesErrorCode catch (e) {
      _isPurchasing = false;

      // Handle specific error codes
      switch (e) {
        case PurchasesErrorCode.purchaseCancelledError:
          _purchaseCancelled = true;
          _error = null;
          break;
        case PurchasesErrorCode.productAlreadyPurchasedError:
          _error = 'You already own this product';
          await _refreshCustomerInfo();
          break;
        case PurchasesErrorCode.purchaseNotAllowedError:
          _error = 'Purchases not allowed on this device';
          break;
        case PurchasesErrorCode.paymentPendingError:
          _error = 'Payment is pending';
          break;
        default:
          _error = 'Purchase failed: $e';
      }

      notifyListeners();
      debugPrint('Purchase failed: $_error');
      return false;
    } catch (e) {
      _isPurchasing = false;
      _error = 'Purchase failed: $e';
      notifyListeners();
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    if (_isPurchasing) return false;

    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      _customerInfo = await Purchases.restorePurchases();
      _isPurchasing = false;
      notifyListeners();

      if (_customerInfo?.entitlements.active.isNotEmpty ?? false) {
        debugPrint('Restore successful - active entitlements found');
        return true;
      } else {
        debugPrint('No purchases to restore');
        return false;
      }
    } catch (e) {
      _isPurchasing = false;
      _error = 'Failed to restore purchases: $e';
      notifyListeners();
      return false;
    }
  }

  /// Present the RevenueCat paywall
  Future<PaywallResult> presentPaywall({String? offeringIdentifier}) async {
    try {
      final result = await RevenueCatUI.presentPaywall(
        displayCloseButton: true,
      );

      // Refresh customer info after paywall dismissal
      await _refreshCustomerInfo();

      return result;
    } catch (e) {
      debugPrint('Failed to present paywall: $e');
      return PaywallResult.cancelled;
    }
  }

  /// Present the RevenueCat paywall if needed (user doesn't have entitlement)
  Future<PaywallResult> presentPaywallIfNeeded(String entitlementId) async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
        displayCloseButton: true,
      );

      // Refresh customer info after paywall dismissal
      await _refreshCustomerInfo();

      return result;
    } catch (e) {
      debugPrint('Failed to present paywall: $e');
      return PaywallResult.cancelled;
    }
  }

  /// Present the Customer Center for managing subscriptions
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
      // Refresh customer info after customer center dismissal
      await _refreshCustomerInfo();
    } catch (e) {
      debugPrint('Failed to present customer center: $e');
    }
  }

  /// Identify user with a custom app user ID
  Future<void> identifyUser(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      _customerInfo = result.customerInfo;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to identify user: $e');
    }
  }

  /// Log out current user (reset to anonymous)
  Future<void> logOut() async {
    try {
      _customerInfo = await Purchases.logOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to log out: $e');
    }
  }

  /// Get the current app user ID
  Future<String> getAppUserID() async {
    return await Purchases.appUserID;
  }

  /// Check entitlement and return true if active
  bool checkEntitlement(String entitlementId) {
    return _customerInfo?.entitlements.active.containsKey(entitlementId) ??
        false;
  }

  /// Get subscription management URL (for Android)
  String? get managementURL {
    return _customerInfo?.managementURL;
  }

  /// Clear any error state
  void clearError() {
    _error = null;
    _purchaseCancelled = false;
    notifyListeners();
  }
}
