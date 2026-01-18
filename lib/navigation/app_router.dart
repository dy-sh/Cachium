import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/animations/page_transitions.dart';
import '../features/accounts/presentation/screens/account_form_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../features/settings/presentation/screens/about_settings_screen.dart';
import '../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../features/settings/presentation/screens/category_management_screen.dart';
import '../features/settings/presentation/screens/coming_soon_settings_screen.dart';
import '../features/settings/presentation/screens/formats_settings_screen.dart';
import '../features/settings/presentation/screens/preferences_settings_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import 'navigation_shell.dart';

class AppRoutes {
  static const home = '/';
  static const transactions = '/transactions';
  static const accounts = '/accounts';
  static const settings = '/settings';
  static const categoryManagement = '/settings/categories';
  static const appearanceSettings = '/settings/appearance';
  static const formatsSettings = '/settings/formats';
  static const preferencesSettings = '/settings/preferences';
  static const comingSoonSettings = '/settings/coming-soon';
  static const aboutSettings = '/settings/about';
  static const transactionForm = '/transaction/new';
  static const accountForm = '/account/new';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final startScreen = ref.read(startScreenProvider);

  return GoRouter(
    initialLocation: startScreen.route,
    routes: [
      ShellRoute(
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AccountsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.transactionForm,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const TransactionFormScreen(),
          animationsEnabled: ref.read(settingsProvider).formAnimationsEnabled,
        ),
      ),
      GoRoute(
        path: AppRoutes.accountForm,
        pageBuilder: (context, state) => PageTransitions.buildSlideUpTransition(
          state,
          const AccountFormScreen(),
          animationsEnabled: ref.read(settingsProvider).formAnimationsEnabled,
        ),
      ),
      GoRoute(
        path: AppRoutes.categoryManagement,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const CategoryManagementScreen(),
          animationsEnabled: ref.read(settingsProvider).formAnimationsEnabled,
        ),
      ),
      GoRoute(
        path: AppRoutes.appearanceSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const AppearanceSettingsScreen(),
          animationsEnabled: ref.read(settingsProvider).formAnimationsEnabled,
        ),
      ),
      GoRoute(
        path: AppRoutes.formatsSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const FormatsSettingsScreen(),
          animationsEnabled: ref.read(settingsProvider).formAnimationsEnabled,
        ),
      ),
      GoRoute(
        path: AppRoutes.preferencesSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const PreferencesSettingsScreen(),
          animationsEnabled: ref.read(settingsProvider).formAnimationsEnabled,
        ),
      ),
      GoRoute(
        path: AppRoutes.comingSoonSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const ComingSoonSettingsScreen(),
          animationsEnabled: ref.read(settingsProvider).formAnimationsEnabled,
        ),
      ),
      GoRoute(
        path: AppRoutes.aboutSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const AboutSettingsScreen(),
          animationsEnabled: ref.read(settingsProvider).formAnimationsEnabled,
        ),
      ),
    ],
  );
});
