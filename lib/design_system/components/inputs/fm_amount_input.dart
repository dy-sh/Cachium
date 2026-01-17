import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class FMAmountInput extends StatefulWidget {
  final double? initialValue;
  final ValueChanged<double>? onChanged;
  final String transactionType;
  final bool autofocus;

  const FMAmountInput({
    super.key,
    this.initialValue,
    this.onChanged,
    this.transactionType = 'expense',
    this.autofocus = false,
  });

  @override
  State<FMAmountInput> createState() => _FMAmountInputState();
}

class _FMAmountInputState extends State<FMAmountInput> {
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

  Color get _prefixColor {
    return widget.transactionType == 'income'
        ? AppColors.income
        : AppColors.expense;
  }

  String get _prefix {
    return widget.transactionType == 'income' ? '+' : '-';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: _isFocused ? _prefixColor : AppColors.border,
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _prefix,
            style: AppTypography.moneyLarge.copyWith(color: _prefixColor),
          ),
          Text(
            '\$',
            style: AppTypography.moneyLarge.copyWith(
              color: AppColors.textSecondary,
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
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                widget.onChanged?.call(amount);
              },
              style: AppTypography.moneyLarge,
              cursorColor: _prefixColor,
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: AppTypography.moneyLarge.copyWith(
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
