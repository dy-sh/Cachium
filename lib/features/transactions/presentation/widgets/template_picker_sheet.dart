import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transaction_templates_provider.dart';

void showTemplatePicker({
  required BuildContext context,
  required WidgetRef ref,
  required TextEditingController merchantController,
  required TextEditingController noteController,
  required VoidCallback onApplied,
}) {
  final templates =
      ref.read(transactionTemplatesProvider).valueOrNull ?? [];
  if (templates.isEmpty) {
    context.showInfoNotification('No templates yet. Create one in Settings.');
    return;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Text('Apply Template', style: AppTypography.h4),
            ),
            Column(
              children: List.generate(templates.length, (index) {
                final template = templates[index];
                final typeColor = AppColors.getTransactionColor(
                  template.type.name,
                  ref.read(colorIntensityProvider),
                );
                final subtitleParts = <String>[template.type.displayName];
                if (template.amount != null) {
                  subtitleParts.add(template.amount!.toStringAsFixed(2));
                }
                if (template.merchant != null) {
                  subtitleParts.add(template.merchant!);
                }
                return ListTile(
                  leading: Icon(
                    LucideIcons.fileText,
                    color: typeColor,
                    size: 20,
                  ),
                  title: Text(
                    template.name,
                    style: AppTypography.bodyMedium,
                  ),
                  subtitle: Text(
                    subtitleParts.join(' \u00b7 '),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref.read(transactionFormProvider.notifier)
                        .applyTemplate(template);
                    if (template.merchant != null) {
                      merchantController.text = template.merchant!;
                    }
                    if (template.note != null) {
                      noteController.text = template.note!;
                    }
                    onApplied();
                  },
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    },
  );
}
