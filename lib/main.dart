import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audio_session/audio_session.dart';

import 'constants/game_constants.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ads_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/purchases_provider.dart';
import 'providers/audio_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/screens/start_screen.dart';
import 'widgets/screens/game_screen.dart';

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
      systemNavigationBarColor: GameColors.slate900,
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
    return Consumer2<SettingsProvider, AudioProvider>(
      builder: (context, settingsProvider, audioProvider, child) {
        // Initialize audio with settings when loaded
        if (settingsProvider.isLoaded) {
          audioProvider.initialize(
            musicEnabled: settingsProvider.musicEnabled,
            soundEnabled: settingsProvider.soundEnabled,
            musicVolume: settingsProvider.musicVolume,
            soundVolume: settingsProvider.soundVolume,
          );
        }

        // Update ad-free status when purchases change (after build)
        final purchasesProvider = context.watch<PurchasesProvider>();
        if (_isInitialized && purchasesProvider.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final adsProvider = context.read<AdsProvider>();
            adsProvider.setAdFree(purchasesProvider.isAdFree);
          });
        }

        return MaterialApp(
          title: 'GridMaster',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: const GameWrapper(),
        );
      },
    );
  }
}

/// Main wrapper that handles brightness and game state
class GameWrapper extends StatelessWidget {
  const GameWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final gameProvider = context.watch<GameProvider>();
    final brightness = settingsProvider.brightness / 100;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_brightnessMatrix(brightness)),
      child: Scaffold(
        backgroundColor: GameColors.slate900,
        body: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      GameColors.slate900,
                      GameColors.blue900.withValues(alpha: 0.2),
                      GameColors.slate900,
                    ],
                  ),
                ),
              ),
            ),

            // Main content based on game state
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: gameProvider.isStart
                  ? const StartScreen()
                  : const GameScreen(),
            ),
          ],
        ),
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
