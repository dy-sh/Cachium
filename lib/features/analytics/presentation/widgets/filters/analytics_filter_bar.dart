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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateRangeSelector(),
        SizedBox(height: AppSpacing.md),
        AccountFilterChips(),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Row(
            children: [
              CategoryFilterPopup(),
              Spacer(),
              TypeFilterToggle(),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
