import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/settings/presentation/providers/app_lock_provider.dart';
import 'features/settings/presentation/providers/database_management_providers.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/settings/presentation/screens/lock_screen.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';
import 'navigation/app_router.dart';

class CachiumApp extends ConsumerWidget {
  const CachiumApp({super.key});

  static final _theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.textPrimary,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );

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

class _AppGateState extends ConsumerState<_AppGate> {
  @override
  void initState() {
    super.initState();
    // Migrate plaintext credentials to hashed on first load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(settingsProvider.notifier).migrateCredentialsIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final shouldShowWelcomeAsync = ref.watch(shouldShowWelcomeProvider);
    final isResetting = ref.watch(isResettingDatabaseProvider);

    // During reset, directly show welcome screen
    if (isResetting) {
      return _wrapInApp(const WelcomeScreen());
    }

    // On initial load (no cached value), wait for provider to resolve
    if (!shouldShowWelcomeAsync.hasValue) {
      return shouldShowWelcomeAsync.when(
        data: (showWelcome) =>
            showWelcome ? _wrapInApp(const WelcomeScreen()) : const _LockGate(),
        loading: () => _wrapInApp(
          const Scaffold(
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
    return const _LockGate();
  }

  /// Wraps a pre-router screen in a simple MaterialApp.
  Widget _wrapInApp(Widget home) {
    return MaterialApp(
      title: 'Cachium',
      debugShowCheckedModeBanner: false,
      theme: CachiumApp._theme,
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
        theme: CachiumApp._theme,
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

class _MainApp extends ConsumerWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Cachium',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: CachiumApp._theme,
    );
  }
}
