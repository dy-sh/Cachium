import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../design_system/components/layout/bottom_nav_bar.dart';
import '../features/transactions/presentation/providers/recurring_rules_provider.dart';
import '../features/transactions/presentation/widgets/pending_recurring_dialog.dart';
import 'app_router.dart';

class NavigationShell extends ConsumerStatefulWidget {
  final Widget child;

  const NavigationShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  bool _checkedPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingRecurring();
    });
  }

  Future<void> _checkPendingRecurring() async {
    if (_checkedPending) return;
    _checkedPending = true;

    try {
      // Wait for rules to load
      await ref.read(recurringRulesProvider.future);
      final rules = ref.read(recurringRulesProvider).valueOrNull ?? [];
      final pendingRules =
          rules.where((r) => r.hasPendingGenerations).toList();

      if (pendingRules.isNotEmpty && mounted) {
        await showPendingRecurringDialog(
          context: context,
          ref: ref,
          pendingRules: pendingRules,
        );
      }
    } catch (_) {
      // Non-fatal: recurring check failure shouldn't block the app
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.transactions:
        return 1;
      case AppRoutes.analytics:
        return 2;
      case AppRoutes.accounts:
        return 3;
      case AppRoutes.settings:
        return 4;
      default:
        return 0;
    }
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.transactions);
        break;
      case 2:
        context.go(AppRoutes.analytics);
        break;
      case 3:
        context.go(AppRoutes.accounts);
        break;
      case 4:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: BottomNavBar.defaultItems,
      ),
    );
  }
}
