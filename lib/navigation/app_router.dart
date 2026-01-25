import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/animations/page_transitions.dart';
import '../features/accounts/presentation/screens/account_form_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../features/settings/data/models/export_options.dart';
import '../features/settings/presentation/screens/about_settings_screen.dart';
import '../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../features/settings/presentation/screens/category_management_screen.dart';
import '../features/settings/presentation/screens/column_mapping_screen.dart';
import '../features/settings/presentation/screens/coming_soon_settings_screen.dart';
import '../features/settings/presentation/screens/csv_import_screen.dart';
import '../features/settings/presentation/screens/database_settings_screen.dart';
import '../features/settings/presentation/screens/export_screen.dart';
import '../features/settings/presentation/screens/formats_settings_screen.dart';
import '../features/settings/presentation/screens/import_preview_screen.dart';
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
  static const databaseSettings = '/settings/database';
  static const exportSqlite = '/settings/database/export-sqlite';
  static const exportCsv = '/settings/database/export-csv';
  static const csvImport = '/settings/csv-import';
  static const csvImportMapping = '/settings/csv-import/mapping';
  static const csvImportPreview = '/settings/csv-import/preview';
  static const transactionForm = '/transaction/new';
  static const transactionEdit = '/transaction/:id';
  static const accountForm = '/account/new';
  static const accountEdit = '/account/:id';
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
        pageBuilder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return PageTransitions.buildSlideLeftTransition(
            state,
            TransactionFormScreen(initialType: type),
            animationsEnabled: ref.read(formAnimationsEnabledProvider),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.transactionEdit,
        pageBuilder: (context, state) {
          final transactionId = state.pathParameters['id']!;
          return PageTransitions.buildSlideLeftTransition(
            state,
            TransactionFormScreen(transactionId: transactionId),
            animationsEnabled: ref.read(formAnimationsEnabledProvider),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.accountForm,
        pageBuilder: (context, state) => PageTransitions.buildSlideUpTransition(
          state,
          const AccountFormScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountEdit,
        pageBuilder: (context, state) {
          final accountId = state.pathParameters['id']!;
          return PageTransitions.buildSlideUpTransition(
            state,
            AccountFormScreen(accountId: accountId),
            animationsEnabled: ref.read(formAnimationsEnabledProvider),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.categoryManagement,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const CategoryManagementScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.appearanceSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const AppearanceSettingsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.formatsSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const FormatsSettingsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.preferencesSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const PreferencesSettingsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.comingSoonSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const ComingSoonSettingsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.aboutSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const AboutSettingsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.databaseSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const DatabaseSettingsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.exportSqlite,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const ExportScreen(format: ExportFormat.sqlite),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.exportCsv,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const ExportScreen(format: ExportFormat.csv),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.csvImport,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const CsvImportScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.csvImportMapping,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const ColumnMappingScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.csvImportPreview,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const ImportPreviewScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
    ],
  );
});
