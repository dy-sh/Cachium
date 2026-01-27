import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../comparison/year_over_year_section.dart';
import '../comparison/period_comparison_section.dart';
import '../comparison/category_comparison_section.dart';
import '../comparison/account_comparison_section.dart';

class ComparisonsTab extends StatelessWidget {
  const ComparisonsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.bottomNavHeight + AppSpacing.lg,
      ),
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
