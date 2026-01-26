import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../design_system/components/layout/bottom_nav_bar.dart';
import 'app_router.dart';

class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({
    super.key,
    required this.child,
  });

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
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: BottomNavBar.defaultItems,
      ),
    );
  }
}
