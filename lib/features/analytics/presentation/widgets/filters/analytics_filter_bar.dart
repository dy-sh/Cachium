import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import 'account_filter_chips.dart';
import 'category_filter_popup.dart';
import 'date_range_selector.dart';
import 'type_filter_toggle.dart';

class AnalyticsFilterBar extends StatelessWidget {
  const AnalyticsFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DateRangeSelector(),
        const SizedBox(height: AppSpacing.md),
        const AccountFilterChips(),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Row(
            children: const [
              CategoryFilterPopup(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Row(
            children: const [
              TypeFilterToggle(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
