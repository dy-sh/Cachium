import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/animations/page_transitions.dart';
import '../features/accounts/presentation/screens/account_detail_screen.dart';
import '../features/accounts/presentation/screens/account_form_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/assets/presentation/screens/asset_detail_screen.dart';
import '../features/assets/presentation/screens/assets_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import '../features/settings/data/models/export_options.dart';
import '../features/settings/presentation/screens/about_settings_screen.dart';
import '../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../features/settings/presentation/screens/category_management_screen.dart';
import '../features/settings/presentation/screens/column_mapping_screen.dart';
import '../features/settings/presentation/screens/csv_import_screen.dart';
import '../features/settings/presentation/screens/database_settings_screen.dart';
import '../features/settings/presentation/screens/export_screen.dart';
import '../features/settings/presentation/screens/formats_settings_screen.dart';
import '../features/settings/presentation/screens/home_settings_screen.dart';
import '../features/settings/presentation/screens/import_preview_screen.dart';
import '../features/settings/presentation/screens/preferences_settings_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/transactions_settings_screen.dart';
import '../features/budgets/presentation/screens/budget_settings_screen.dart';
import '../features/transactions/presentation/screens/deleted_transactions_screen.dart';
import '../features/savings_goals/presentation/screens/savings_goals_screen.dart';
import '../features/search/presentation/screens/global_search_screen.dart';
import '../features/transactions/presentation/screens/recurring_rules_screen.dart';
import '../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import 'navigation_shell.dart';

class AppRoutes {
  static const home = '/';
  static const transactions = '/transactions';
  static const analytics = '/analytics';
  static const accounts = '/accounts';
  static const settings = '/settings';
  static const categoryManagement = '/settings/categories';
  static const appearanceSettings = '/settings/appearance';
  static const formatsSettings = '/settings/formats';
  static const preferencesSettings = '/settings/preferences';
  static const transactionsSettings = '/settings/transactions';
  static const homeSettings = '/settings/home';
  static const aboutSettings = '/settings/about';
  static const databaseSettings = '/settings/database';
  static const exportSqlite = '/settings/database/export-sqlite';
  static const exportCsv = '/settings/database/export-csv';
  static const budgetSettings = '/settings/budgets';
  static const csvImport = '/settings/csv-import';
  static const csvImportMapping = '/settings/csv-import/mapping';
  static const csvImportPreview = '/settings/csv-import/preview';
  static const search = '/search';
  static const savingsGoals = '/settings/savings-goals';
  static const recurringRules = '/settings/recurring';
  static const deletedTransactions = '/transactions/deleted';
  static const transactionForm = '/transaction/new';
  static const transactionDetail = '/transaction/:id';
  static const transactionEdit = '/transaction/:id/edit';
  static const accountForm = '/account/new';
  static const accountDetail = '/account/:id';
  static const accountEdit = '/account/:id/edit';
  static const assets = '/settings/assets';
  static const assetDetail = '/asset/:id';
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
            path: AppRoutes.analytics,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AnalyticsScreen(),
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
        path: AppRoutes.transactionDetail,
        pageBuilder: (context, state) {
          final transactionId = state.pathParameters['id']!;
          return PageTransitions.buildSlideLeftTransition(
            state,
            TransactionDetailScreen(transactionId: transactionId),
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
        path: AppRoutes.accountDetail,
        pageBuilder: (context, state) {
          final accountId = state.pathParameters['id']!;
          return PageTransitions.buildSlideLeftTransition(
            state,
            AccountDetailScreen(accountId: accountId),
            animationsEnabled: ref.read(formAnimationsEnabledProvider),
          );
        },
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
        path: AppRoutes.assets,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const AssetsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.assetDetail,
        pageBuilder: (context, state) {
          final assetId = state.pathParameters['id']!;
          return PageTransitions.buildSlideLeftTransition(
            state,
            AssetDetailScreen(assetId: assetId),
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
        path: AppRoutes.transactionsSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const TransactionsSettingsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const HomeSettingsScreen(),
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
        pageBuilder: (context, state) {
          final importOnly = state.uri.queryParameters['importOnly'] == 'true';
          return PageTransitions.buildSlideLeftTransition(
            state,
            DatabaseSettingsScreen(importOnly: importOnly),
            animationsEnabled: ref.read(formAnimationsEnabledProvider),
          );
        },
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
        path: AppRoutes.budgetSettings,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const BudgetSettingsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const GlobalSearchScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.savingsGoals,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const SavingsGoalsScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.recurringRules,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const RecurringRulesScreen(),
          animationsEnabled: ref.read(formAnimationsEnabledProvider),
        ),
      ),
      GoRoute(
        path: AppRoutes.deletedTransactions,
        pageBuilder: (context, state) => PageTransitions.buildSlideLeftTransition(
          state,
          const DeletedTransactionsScreen(),
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
