import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/remote_config_service.dart';
import 'services/smart_ad_manager.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';

/// FCM background handler (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Optional: show local notification for data-only messages.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await RemoteConfigService.instance.initialize();
  await SmartAdManager.initialize();
  await NotificationService.instance.initialize();

  // When Remote Config fetch completes, reload ads so they use Firebase unit IDs
  RemoteConfigService.instance.onConfigUpdated = () {
    SmartAdManager.instance.reloadAdsFromRemoteConfig();
  };

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FcmService.instance.initialize();

  // Preload full-screen ads (from Remote Config defaults; reload when Firebase fetch completes)
  SmartAdManager.instance.loadInterstitial();
  SmartAdManager.instance.loadRewarded();
  SmartAdManager.instance.loadAppOpen();
  runApp(const BtcMiningApp());
}

class BtcMiningApp extends StatefulWidget {
  const BtcMiningApp({super.key});

  @override
  State<BtcMiningApp> createState() => _BtcMiningAppState();
}

class _BtcMiningAppState extends State<BtcMiningApp> with WidgetsBindingObserver {
  /// Set when app goes to background; used to show app-open only on real "app open".
  DateTime? _appBackgroundedAt;
  /// Cooldown: don't show app-open again within this duration (policy-friendly).
  static const _appOpenCooldown = Duration(hours: 4);
  /// Only show app-open if user was in background at least this long (avoids quick app-switch).
  static const _minBackgroundDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.scheduleHourlyReminders();
      // App-open ad only when user truly "opens" the app: returned from background after
      // at least [minBackgroundDuration], and not shown in the last [cooldown]. No cold start.
      final now = DateTime.now();
      final backgroundedAt = _appBackgroundedAt;
      _appBackgroundedAt = null;
      if (backgroundedAt != null &&
          SmartAdManager.instance.isAppOpenReady &&
          now.difference(backgroundedAt) >= _minBackgroundDuration) {
        final lastShown = SmartAdManager.instance.lastAppOpenShownAt;
        if (lastShown == null || now.difference(lastShown) >= _appOpenCooldown) {
          SmartAdManager.instance.showAppOpen();
        }
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _appBackgroundedAt ??= DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.light().textTheme;
    final spaceGroteskTextTheme = GoogleFonts.spaceGroteskTextTheme(baseTextTheme).copyWith(
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GIGA Kaspa Mining',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: spaceGroteskTextTheme,
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeShell(),
      },
    );
  }
}
