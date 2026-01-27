import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../comparison/year_over_year_section.dart';
import '../comparison/period_comparison_section.dart';
import '../comparison/category_comparison_section.dart';
import '../comparison/account_comparison_section.dart';
import '../scroll_anchored_list.dart';

class ComparisonsTab extends StatelessWidget {
  const ComparisonsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollAnchoredList(
      children: const [
        YearOverYearSection(),
        SizedBox(height: AppSpacing.lg),
        PeriodComparisonSection(),
        SizedBox(height: AppSpacing.lg),
        CategoryComparisonSection(),
        SizedBox(height: AppSpacing.lg),
        AccountComparisonSection(),
      ],
    );
  }
}
