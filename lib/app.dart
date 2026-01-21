import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/settings/presentation/providers/database_providers.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';
import 'navigation/app_router.dart';

class CachiumApp extends ConsumerWidget {
  const CachiumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set system UI overlay style for dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Cachium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.textPrimary,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowWelcomeAsync = ref.watch(shouldShowWelcomeProvider);
    final isResetting = ref.watch(isResettingDatabaseProvider);

    // During reset, directly show welcome screen
    // The welcome screen will handle the setup options and reset the flag
    if (isResetting) {
      return const WelcomeScreen();
    }

    // On initial load (no cached value), wait for provider to resolve
    // This ensures first launch shows welcome screen if needed
    if (!shouldShowWelcomeAsync.hasValue) {
      return shouldShowWelcomeAsync.when(
        data: (showWelcome) => showWelcome ? const WelcomeScreen() : const _MainApp(),
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        error: (_, __) => const _MainApp(),
      );
    }

    // Has cached value - use it to prevent flickering during navigation
    if (shouldShowWelcomeAsync.value == true) {
      return const WelcomeScreen();
    }
    return const _MainApp();
  }
}

class _MainApp extends ConsumerWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Cachium',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.textPrimary,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
    );
  }
}
