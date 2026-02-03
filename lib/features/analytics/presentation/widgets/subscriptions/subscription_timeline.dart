import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/recurring_transactions_provider.dart';

class SubscriptionTimeline extends ConsumerWidget {
  const SubscriptionTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingSubscriptionsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (upcoming.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by week
    final now = DateTime.now();
    final thisWeek = <dynamic>[];
    final nextWeek = <dynamic>[];
    final later = <dynamic>[];

    for (final sub in upcoming) {
      if (sub.nextExpected == null) continue;
      final daysUntil = sub.nextExpected!.difference(now).inDays;
      if (daysUntil <= 7) {
        thisWeek.add(sub);
      } else if (daysUntil <= 14) {
        nextWeek.add(sub);
      } else {
        later.add(sub);
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Payments',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (thisWeek.isNotEmpty) ...[
            _TimelineSection(
              title: 'This Week',
              items: thisWeek,
              categories: categories,
              colorIntensity: colorIntensity,
              currencySymbol: currencySymbol,
            ),
          ],
          if (nextWeek.isNotEmpty) ...[
            if (thisWeek.isNotEmpty) const SizedBox(height: AppSpacing.md),
            _TimelineSection(
              title: 'Next Week',
              items: nextWeek,
              categories: categories,
              colorIntensity: colorIntensity,
              currencySymbol: currencySymbol,
            ),
          ],
          if (later.isNotEmpty) ...[
            if (thisWeek.isNotEmpty || nextWeek.isNotEmpty)
              const SizedBox(height: AppSpacing.md),
            _TimelineSection(
              title: 'Later',
              items: later,
              categories: categories,
              colorIntensity: colorIntensity,
              currencySymbol: currencySymbol,
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final List<dynamic> categories;
  final dynamic colorIntensity;
  final String currencySymbol;

  const _TimelineSection({
    required this.title,
    required this.items,
    required this.categories,
    required this.colorIntensity,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColors = AppColors.getCategoryColors(colorIntensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((sub) {
          // Find category safely
          dynamic category;
          for (final c in categories) {
            if (c.id == sub.categoryId) {
              category = c;
              break;
            }
          }

          final categoryColor = category != null
              ? categoryColors[category.colorIndex % categoryColors.length]
              : AppColors.purple;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    sub.merchant ?? category?.name ?? 'Unknown',
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(sub.nextExpected!),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  CurrencyFormatter.format(sub.amount),
                  style: AppTypography.moneySmall.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
