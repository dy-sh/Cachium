import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../features/settings/data/models/app_settings.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';

class AmountInput extends ConsumerStatefulWidget {
  final double? initialValue;
  final ValueChanged<double>? onChanged;
  final String transactionType;
  final bool autofocus;
  final AmountDisplaySize? sizeOverride;

  const AmountInput({
    super.key,
    this.initialValue,
    this.onChanged,
    this.transactionType = 'expense',
    this.autofocus = false,
    this.sizeOverride,
  });

  @override
  ConsumerState<AmountInput> createState() => _FMAmountInputState();
}

class _FMAmountInputState extends ConsumerState<AmountInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue != null ? widget.initialValue.toString() : '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(AmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller when initialValue changes (for edit mode)
    // Skip if focused - user is actively typing
    if (!_focusNode.hasFocus &&
        widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != null) {
      final newText = widget.initialValue.toString();
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  String get _prefix {
    return widget.transactionType == 'income' ? '+' : '-';
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final prefixColor = AppColors.getTransactionColor(widget.transactionType, intensity);
    final amountSize = widget.sizeOverride ?? ref.watch(transactionAmountSizeProvider);
    final isSmall = amountSize == AmountDisplaySize.small;

    // Typography based on size
    final textStyle = isSmall ? AppTypography.moneyMedium : AppTypography.moneyLarge;
    final textColor = isSmall ? AppColors.textSecondary : AppColors.textPrimary;
    final prefixDisplayColor = isSmall ? prefixColor.withValues(alpha: 0.7) : prefixColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: isSmall ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: _isFocused ? prefixColor : AppColors.border,
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _prefix,
            style: textStyle.copyWith(color: prefixDisplayColor),
          ),
          Text(
            '\$',
            style: textStyle.copyWith(
              color: isSmall ? AppColors.textTertiary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                _AmountInputFormatter(),
              ],
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                widget.onChanged?.call(amount);
              },
              style: textStyle.copyWith(color: textColor),
              cursorColor: prefixColor,
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: textStyle.copyWith(
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountInputFormatter extends TextInputFormatter {
  final RegExp _validPattern = RegExp(r'^\d*\.?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty string
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // If the new value matches the pattern, accept it and preserve cursor position
    if (_validPattern.hasMatch(newValue.text)) {
      return newValue;
    }

    // Otherwise, reject the change and keep the old value
    return oldValue;
  }
}
