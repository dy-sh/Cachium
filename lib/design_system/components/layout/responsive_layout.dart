import 'package:flutter/material.dart';

/// Breakpoint thresholds for responsive layouts.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
}

/// A widget that selects between mobile and tablet layouts based on screen width.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobile && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Context extension for responsive queries.
extension ResponsiveContext on BuildContext {
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= ResponsiveBreakpoints.mobile;

  double get responsivePadding => isTablet ? 24.0 : 14.0;

  double get responsiveMaxContentWidth => isTablet ? 720.0 : double.infinity;
}
