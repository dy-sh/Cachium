import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/currencies.dart';

/// Shows a searchable currency picker bottom sheet.
void showCurrencyPickerSheet({
  required BuildContext context,
  required String selectedCode,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _CurrencyPickerSheet(
      selectedCode: selectedCode,
      onSelected: (code) {
        onSelected(code);
        Navigator.pop(context);
      },
    ),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<String> onSelected;

  const _CurrencyPickerSheet({
    required this.selectedCode,
    required this.onSelected,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  late TextEditingController _searchController;
  List<Currency> _filtered = Currency.all;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = Currency.all;
      } else {
        final q = query.toLowerCase();
        _filtered = Currency.all.where((c) {
          return c.code.toLowerCase().contains(q) ||
              c.name.toLowerCase().contains(q) ||
              c.symbol.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.xxsAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Select Currency', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.md),
            // Search field
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.iconButton,
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Currency list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final currency = _filtered[index];
                  final isSelected = currency.code == widget.selectedCode;
                  return GestureDetector(
                    onTap: () => widget.onSelected(currency.code),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Text(
                            currency.flag,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            currency.code,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              currency.name,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            currency.symbol,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              LucideIcons.check,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact currency code chip for use in forms.
class CurrencyCodeChip extends StatelessWidget {
  final String currencyCode;
  final VoidCallback? onTap;

  const CurrencyCodeChip({
    super.key,
    required this.currencyCode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = Currency.fromCode(currencyCode);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currency.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              currency.code,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(
                LucideIcons.chevronDown,
                size: 12,
                color: AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
