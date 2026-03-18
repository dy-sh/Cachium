import '../../../../core/constants/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/transactions_provider.dart';

class MerchantAutocomplete extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const MerchantAutocomplete({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  ConsumerState<MerchantAutocomplete> createState() => _MerchantAutocompleteState();
}

class _MerchantAutocompleteState extends ConsumerState<MerchantAutocomplete> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchants = ref.watch(merchantSuggestionsProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Merchant (optional)',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable.empty();
            final query = textEditingValue.text.toLowerCase();
            return merchants
                .where((m) => m.toLowerCase().contains(query))
                .take(8);
          },
          onSelected: (selection) {
            widget.controller.text = selection;
            widget.onChanged(selection);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: _isFocused ? accentColor : AppColors.border,
                  width: _isFocused ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: widget.onChanged,
                style: AppTypography.input,
                cursorColor: accentColor,
                decoration: InputDecoration(
                  hintText: 'e.g. Amazon, Starbucks...',
                  hintStyle: AppTypography.inputHint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.inputPadding,
                    vertical: AppSpacing.inputPadding,
                  ),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            border: index < options.length - 1
                                ? Border(
                                    bottom: BorderSide(
                                      color: AppColors.border.withValues(alpha: 0.5),
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.store,
                                size: 16,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                option,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
