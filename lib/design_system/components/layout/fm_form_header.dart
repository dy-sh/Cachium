import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../buttons/fm_close_button.dart';

/// A standardized header for form screens with a close button and title.
class FMFormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final Widget? trailing;

  const FMFormHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.trailing,
  });

  /// Factory constructor that automatically pops the navigation.
  factory FMFormHeader.pop({
    required BuildContext context,
    required String title,
    Widget? trailing,
  }) {
    return FMFormHeader(
      title: title,
      onClose: () => Navigator.of(context).pop(),
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Row(
        children: [
          FMCloseButton(onTap: onClose),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.h3,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
