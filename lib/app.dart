import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'features/settings/data/models/app_settings.dart';
import 'features/settings/presentation/providers/app_lock_provider.dart';
import 'features/settings/presentation/providers/database_management_providers.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/settings/presentation/screens/lock_screen.dart';
import 'features/welcome/presentation/screens/tutorial_screen.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';
import 'navigation/app_router.dart';

class CachiumApp extends ConsumerWidget {
  const CachiumApp({super.key});

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surfaceDark,
      primary: AppColors.textPrimaryDark,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surfaceColorLight,
      primary: AppColors.textPrimaryLight,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );

  static ThemeData get currentTheme => AppColors.isDarkMode ? darkTheme : lightTheme;

  /// Resolve the effective dark mode flag from theme mode setting + platform brightness.
  static bool resolveIsDarkMode(ThemeModeOption mode, Brightness platformBrightness) {
    switch (mode) {
      case ThemeModeOption.dark:
        return true;
      case ThemeModeOption.light:
        return false;
      case ThemeModeOption.system:
        return platformBrightness == Brightness.dark;
    }
  }

  /// Update AppColors.isDarkMode and system chrome based on theme mode.
  static void applyThemeMode(ThemeModeOption mode, Brightness platformBrightness) {
    final isDark = resolveIsDarkMode(mode, platformBrightness);
    AppColors.isDarkMode = isDark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _AppGate();
  }
}

class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> with WidgetsBindingObserver {
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
    super.didChangeAppLifecycleState(state);
    final appLockEnabled = ref.read(appLockEnabledProvider);
    if (!appLockEnabled) return;

    final autoLockTimeout = ref.read(settingsProvider).valueOrNull?.autoLockTimeout ?? AutoLockTimeout.immediate;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      ref.read(appLockStateProvider.notifier).onBackground();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(appLockStateProvider.notifier).onForeground(
        timeoutDuration: autoLockTimeout.duration,
        isImmediate: autoLockTimeout == AutoLockTimeout.immediate,
        isNever: autoLockTimeout == AutoLockTimeout.never,
      );
    }
  }

  @override
  void didChangePlatformBrightness() {
    // Re-evaluate theme when system brightness changes
    final themeMode = ref.read(themeModeProvider);
    if (themeMode == ThemeModeOption.system) {
      setState(() {
        CachiumApp.applyThemeMode(
          themeMode,
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final themeMode = ref.watch(themeModeProvider);
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    CachiumApp.applyThemeMode(themeMode, platformBrightness);

    final shouldShowWelcomeAsync = ref.watch(shouldShowWelcomeProvider);
    final isResetting = ref.watch(isResettingDatabaseProvider);
    final tutorialCompleted = ref.watch(tutorialCompletedProvider);

    // During reset, directly show welcome screen
    if (isResetting) {
      return _wrapInApp(const WelcomeScreen());
    }

    // On initial load (no cached value), wait for provider to resolve
    if (!shouldShowWelcomeAsync.hasValue) {
      return shouldShowWelcomeAsync.when(
        data: (showWelcome) {
          if (showWelcome) return _wrapInApp(const WelcomeScreen());
          if (!tutorialCompleted) return _buildTutorial();
          return const _LockGate();
        },
        loading: () => _wrapInApp(
          Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        error: (_, __) => const _LockGate(),
      );
    }

    // Has cached value - use it to prevent flickering during navigation
    if (shouldShowWelcomeAsync.value == true) {
      return _wrapInApp(const WelcomeScreen());
    }

    // Show tutorial if not yet completed
    if (!tutorialCompleted) {
      return _buildTutorial();
    }

    return const _LockGate();
  }

  Widget _buildTutorial() {
    return _wrapInApp(
      TutorialScreen(
        onComplete: () {
          ref.invalidate(settingsProvider);
        },
      ),
    );
  }

  /// Wraps a pre-router screen in a simple MaterialApp.
  Widget _wrapInApp(Widget home) {
    return MaterialApp(
      title: 'Cachium',
      debugShowCheckedModeBanner: false,
      theme: CachiumApp.currentTheme,
      home: home,
    );
  }
}

/// Gate that shows lock screen if app lock is enabled and app is locked.
class _LockGate extends ConsumerWidget {
  const _LockGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockEnabled = ref.watch(appLockEnabledProvider);
    final isLocked = ref.watch(appLockStateProvider);

    if (appLockEnabled && isLocked) {
      return MaterialApp(
        title: 'Cachium',
        debugShowCheckedModeBanner: false,
        theme: CachiumApp.currentTheme,
        home: LockScreen(
          onUnlocked: () {
            // State already updated by the lock screen
          },
        ),
      );
    }

    return const _MainApp();
  }
}

class _MainApp extends ConsumerStatefulWidget {
  const _MainApp();

  @override
  ConsumerState<_MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<_MainApp> {
  late final StreamSubscription<String> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = NotificationService.actionStream.stream.listen((action) {
      final router = ref.read(appRouterProvider);
      switch (action) {
        case 'add_expense':
          router.push('${AppRoutes.transactionForm}?type=expense');
        case 'add_income':
          router.push('${AppRoutes.transactionForm}?type=income');
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Cachium',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: CachiumApp.currentTheme,
    );
  }
}
