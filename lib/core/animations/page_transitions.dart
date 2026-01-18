import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom page transition builders for consistent navigation animations
class PageTransitions {
  PageTransitions._();

  /// Fullscreen slide from right to left (for transaction/account forms)
  /// Duration: 350ms with easeOutCubic curve
  /// If [animationsEnabled] is false, returns NoTransitionPage
  static Page<void> buildSlideLeftTransition(
    GoRouterState state,
    Widget child, {
    bool animationsEnabled = true,
  }) {
    if (!animationsEnabled) {
      return NoTransitionPage(key: state.pageKey, child: child);
    }
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0), // Start from right
            end: Offset.zero, // End at current position
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Modal slide from bottom to top (for modal dialogs)
  /// Duration: 300ms with easeOutCubic curve
  /// If [animationsEnabled] is false, returns NoTransitionPage
  static Page<void> buildSlideUpTransition(
    GoRouterState state,
    Widget child, {
    bool animationsEnabled = true,
  }) {
    if (!animationsEnabled) {
      return NoTransitionPage(key: state.pageKey, child: child);
    }
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0), // Start from bottom
            end: Offset.zero, // End at current position
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

  /// Fade transition (for tab switches and subtle transitions)
  /// Duration: 200ms with easeInOut curve
  static CustomTransitionPage<void> buildFadeTransition(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  /// Shared axis transition for related screens
  /// Duration: 300ms with easeInOut curve
  static CustomTransitionPage<void> buildSharedAxisTransition(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// No transition (instant, for tab navigation)
  static NoTransitionPage<void> buildNoTransition(
    GoRouterState state,
    Widget child,
  ) {
    return NoTransitionPage(
      key: state.pageKey,
      child: child,
    );
  }
}
