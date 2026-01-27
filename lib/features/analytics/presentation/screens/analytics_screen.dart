import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/layout/page_layout.dart';
import '../widgets/tabs/overview_tab.dart';
import '../widgets/tabs/comparisons_tab.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: PageLayout(
        title: 'Analytics',
        body: Column(
          children: [
            TabBar(
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTypography.bodyMedium,
              indicatorColor: AppColors.textPrimary,
              dividerColor: AppColors.surface,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Comparisons'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  OverviewTab(),
                  ComparisonsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
