import 'package:go_router/go_router.dart';
import '../core/animations/page_transitions.dart';
import '../features/accounts/presentation/screens/account_form_screen.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import 'navigation_shell.dart';

class AppRoutes {
  static const home = '/';
  static const transactions = '/transactions';
  static const accounts = '/accounts';
  static const settings = '/settings';
  static const transactionForm = '/transaction/new';
  static const accountForm = '/account/new';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
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
      ),
    ),
    GoRoute(
      path: AppRoutes.accountForm,
      pageBuilder: (context, state) => PageTransitions.buildSlideUpTransition(
        state,
        const AccountFormScreen(),
      ),
    ),
  ],
);
