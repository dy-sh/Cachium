import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Notification type determines the color scheme and icon.
enum FMNotificationType {
  success,
  error,
  warning,
  info,
}

extension FMNotificationTypeExtension on FMNotificationType {
  Color get color {
    switch (this) {
      case FMNotificationType.success:
        return AppColors.green;
      case FMNotificationType.error:
        return AppColors.red;
      case FMNotificationType.warning:
        return AppColors.yellow;
      case FMNotificationType.info:
        return AppColors.cyan;
    }
  }

  IconData get icon {
    switch (this) {
      case FMNotificationType.success:
        return LucideIcons.checkCircle2;
      case FMNotificationType.error:
        return LucideIcons.xCircle;
      case FMNotificationType.warning:
        return LucideIcons.alertTriangle;
      case FMNotificationType.info:
        return LucideIcons.info;
    }
  }
}

/// A notification widget matching the Cachium design system.
/// Appears from the top with slide + fade animation.
class Notification extends StatefulWidget {
  final String message;
  final FMNotificationType type;
  final Duration duration;
  final VoidCallback? onDismiss;
  final bool showCloseButton;
  final String? actionLabel;
  final VoidCallback? onAction;

  const Notification({
    super.key,
    required this.message,
    this.type = FMNotificationType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
    this.showCloseButton = true,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<Notification> createState() => _FMNotificationState();
}

class _FMNotificationState extends State<Notification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  void resetTimer() {
    _dismissTimer?.cancel();
    if (widget.duration > Duration.zero) {
      _dismissTimer = Timer(widget.duration, _dismiss);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.sharpCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));

    _controller.forward();

    if (widget.duration > Duration.zero) {
      _dismissTimer = Timer(widget.duration, _dismiss);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.type.color;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            _dismiss();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  widget.type.icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Message
              Expanded(
                child: Text(
                  widget.message,
                  style: AppTypography.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Action button
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () {
                    widget.onAction!();
                    _dismiss();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      widget.actionLabel!,
                      style: AppTypography.labelMedium.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
              // Close button
              if (widget.showCloseButton) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Manages showing notifications as overlays.
class NotificationOverlay {
  static final NotificationOverlay _instance = NotificationOverlay._();
  static NotificationOverlay get instance => _instance;

  NotificationOverlay._();

  OverlayEntry? _currentEntry;
  String? _currentMessage;
  final GlobalKey<_FMNotificationState> _notificationKey = GlobalKey();
  final List<_NotificationItem> _queue = [];
  bool _isShowing = false;

  /// Shows a notification with the given message and type.
  void show(
    BuildContext context,
    String message, {
    FMNotificationType type = FMNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // If the same message is already showing, just reset the timer
    if (_isShowing && _currentMessage == message) {
      _notificationKey.currentState?.resetTimer();
      // Also drop any queued duplicates of this message
      _queue.removeWhere((item) => item.message == message);
      return;
    }

    // Also deduplicate from the queue
    _queue.removeWhere((item) => item.message == message);

    _queue.add(_NotificationItem(
      context: context,
      message: message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    ));

    if (!_isShowing) {
      _showNext();
    }
  }

  void _showNext() {
    if (_queue.isEmpty) {
      _isShowing = false;
      _currentMessage = null;
      return;
    }

    _isShowing = true;
    final item = _queue.removeAt(0);
    _currentMessage = item.message;

    final overlay = Overlay.of(item.context);

    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(item.context).padding.top + AppSpacing.md,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Notification(
            key: _notificationKey,
            message: item.message,
            type: item.type,
            duration: item.duration,
            actionLabel: item.actionLabel,
            onAction: item.onAction,
            onDismiss: () {
              _currentEntry?.remove();
              _currentEntry = null;
              _currentMessage = null;
              _showNext();
            },
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);
  }

  /// Shows a success notification.
  void success(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      type: FMNotificationType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shows an error notification.
  void error(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      type: FMNotificationType.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Shows a warning notification.
  void warning(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      type: FMNotificationType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shows an info notification.
  void info(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message,
      type: FMNotificationType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Dismisses the current notification immediately.
  void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _currentMessage = null;
    _showNext();
  }
}

class _NotificationItem {
  final BuildContext context;
  final String message;
  final FMNotificationType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  _NotificationItem({
    required this.context,
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });
}

/// Extension for easy access from BuildContext.
extension FMNotificationContext on BuildContext {
  void showNotification(
    String message, {
    FMNotificationType type = FMNotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    NotificationOverlay.instance.show(this, message, type: type, duration: duration);
  }

  void showSuccessNotification(String message, {Duration? duration}) {
    NotificationOverlay.instance.success(this, message, duration: duration);
  }

  void showErrorNotification(String message, {Duration? duration}) {
    NotificationOverlay.instance.error(this, message, duration: duration);
  }

  void showWarningNotification(String message, {Duration? duration}) {
    NotificationOverlay.instance.warning(this, message, duration: duration);
  }

  void showInfoNotification(String message, {Duration? duration}) {
    NotificationOverlay.instance.info(this, message, duration: duration);
  }

  void showUndoNotification(String message, VoidCallback onUndo) {
    NotificationOverlay.instance.show(
      this,
      message,
      type: FMNotificationType.success,
      duration: const Duration(seconds: 5),
      actionLabel: 'Undo',
      onAction: onUndo,
    );
  }
}
