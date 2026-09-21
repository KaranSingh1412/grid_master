import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_session/audio_session.dart';

import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ads_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/purchases_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'theme/tactile_tokens.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureAudioSession();
  await dotenv.load(fileName: ".env");
  await EasyLocalization.ensureInitialized();
  await MobileAds.instance.initialize();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: TactileColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('de'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('de'),
      startLocale: const Locale('de'),
      child: const GridMasterApp(),
    ),
  );
}

Future<void> configureAudioSession() async {
  final session = await AudioSession.instance;

  await session.configure(
    const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.ambient,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.game,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: true,
    ),
  );
}

class GridMasterApp extends StatelessWidget {
  const GridMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
        ChangeNotifierProvider(create: (_) => CreditProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const _AppInitializer(),
    );
  }
}

/// Handles initialization of providers that depend on each other
class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final purchasesProvider = context.read<PurchasesProvider>();
    final adsProvider = context.read<AdsProvider>();
    final gameProvider = context.read<GameProvider>();
    final audioProvider = context.read<AudioProvider>();

    // Initialize RevenueCat first
    await purchasesProvider.initialize();

    // Check ad-free status and set it on AdsProvider
    final isAdFree = await purchasesProvider.checkAdFreeStatus();
    adsProvider.setAdFree(isAdFree);

    // Initialize ads (will skip banner/interstitial if ad-free)
    await adsProvider.initialize();

    // Set audio provider on game provider for sound effects
    gameProvider.setAudioProvider(audioProvider);

    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SettingsProvider, AudioProvider, CreditProvider>(
      builder:
          (context, settingsProvider, audioProvider, creditProvider, child) {
            // Initialize audio with settings when loaded
            if (settingsProvider.isLoaded && creditProvider.isLoaded) {
              audioProvider.initialize(
                musicEnabled: settingsProvider.musicEnabled,
                soundEnabled: settingsProvider.soundEnabled,
                musicVolume: settingsProvider.musicVolume,
                soundVolume: settingsProvider.soundVolume,
                soundPackId: creditProvider.cosmeticState.equippedSoundPackId,
              );
            }

            // Synchronisiere Theme mit CreditProvider
            if (creditProvider.isLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final themeProvider = context.read<ThemeProvider>();
                themeProvider.updateFromThemeId(
                  creditProvider.cosmeticState.equippedThemeId,
                );
              });
            }

            // Update ad-free status when purchases change (after build)
            final purchasesProvider = context.watch<PurchasesProvider>();
            if (_isInitialized && purchasesProvider.isInitialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final adsProvider = context.read<AdsProvider>();
                adsProvider.setAdFree(purchasesProvider.isAdFree);
              });
            }

            return MaterialApp.router(
              title: 'GridMaster',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.fromPalette(
                context.watch<ThemeProvider>().palette,
              ),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              routerConfig: appRouter,
              builder: (context, child) {
                return AppWrapper(child: child);
              },
            );
          },
    );
  }
}

/// Main wrapper that handles brightness and background
class AppWrapper extends StatelessWidget {
  final Widget? child;

  const AppWrapper({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = settingsProvider.brightness / 100;
    final palette = themeProvider.palette;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_brightnessMatrix(brightness)),
      child: Stack(
        children: [
          // Ground: theme background, slightly deeper towards the bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.background,
                    Color.lerp(
                      palette.background,
                      palette.backgroundDeep,
                      0.3,
                    )!,
                  ],
                ),
              ),
            ),
          ),

          // Router content
          if (child != null) child!,
        ],
      ),
    );
  }

  /// Create brightness matrix for ColorFiltered
  List<double> _brightnessMatrix(double brightness) {
    return [
      brightness,
      0,
      0,
      0,
      0,
      0,
      brightness,
      0,
      0,
      0,
      0,
      0,
      brightness,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}
