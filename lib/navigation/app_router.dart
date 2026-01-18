import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      pageBuilder: (context, state) => _buildSlideUpTransition(
        state,
        const TransactionFormScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.accountForm,
      pageBuilder: (context, state) => _buildSlideUpTransition(
        state,
        const AccountFormScreen(),
      ),
    ),
  ],
);

CustomTransitionPage<void> _buildSlideUpTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
