import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/utils/formatting_providers.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_template.dart';
import '../providers/transaction_templates_provider.dart';

class TransactionTemplatesScreen extends ConsumerWidget {
  const TransactionTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(transactionTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsHeader(
              title: 'Transaction Templates',
              actions: [
                CircularButton(
                  onTap: () => context.push('/settings/templates/new'),
                  icon: LucideIcons.plus,
                  size: AppSpacing.settingsBackButtonSize,
                ),
              ],
            ),
            Expanded(
              child: templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: EmptyState.centered(
                        icon: LucideIcons.fileText,
                        title: 'No Templates',
                        subtitle:
                            'Create templates to quickly fill in transaction details.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    itemCount: templates.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      return _TemplateCard(template: template);
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textSecondary,
                  ),
                ),
                error: (_, __) => const Center(
                  child: Text('Failed to load templates'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final TransactionTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final category =
        categories.where((c) => c.id == template.categoryId).firstOrNull;
    final intensity = ref.watch(colorIntensityProvider);
    final typeColor = template.type == TransactionType.income
        ? AppColors.getTransactionColor('income', intensity)
        : template.type == TransactionType.transfer
            ? AppColors.getTransactionColor('transfer', intensity)
            : AppColors.getTransactionColor('expense', intensity);

    return GestureDetector(
      onTap: () =>
          context.push('/settings/templates/${template.id}/edit'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: AppRadius.iconButton,
              ),
              child: Icon(
                LucideIcons.fileText,
                size: 20,
                color: typeColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      template.type.displayName,
                      if (category != null) category.name,
                    ].join(' \u2022 '),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (template.amount != null)
              Text(
                ref.watch(currencyFormatterProvider).formatWithSign(
                    template.amount!, template.type.name),
                style: AppTypography.bodyMedium.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            PopupMenuButton<String>(
              icon: Icon(
                LucideIcons.moreVertical,
                size: 18,
                color: AppColors.textSecondary,
              ),
              color: AppColors.surface,
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await showConfirmationDialog(
                    context: context,
                    title: 'Delete Template',
                    message:
                        'Are you sure you want to delete "${template.name}"?',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                  if (confirmed && context.mounted) {
                    await ref
                        .read(transactionTemplatesProvider.notifier)
                        .deleteTemplate(template.id);
                    if (context.mounted) {
                      context.showSuccessNotification('Template deleted');
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: AppColors.expense,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Delete',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
