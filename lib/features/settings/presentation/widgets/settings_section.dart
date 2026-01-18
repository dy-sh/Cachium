import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool showDividers;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _buildChildren(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildren() {
    if (!showDividers || children.isEmpty) {
      return children;
    }

    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
          ),
        );
      }
    }
    return result;
  }
}
