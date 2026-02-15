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
  double? _previewResult;

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
    if (!_focusNode.hasFocus) {
      // Evaluate expression on blur
      final result = _evaluateExpression(_controller.text);
      if (result != null && result > 0) {
        final text = _controller.text;
        // Only replace if the text contains operators (is an expression)
        if (text.contains('+') || text.contains('-') || text.contains('*') || text.contains('/')) {
          final rounded = double.parse(result.toStringAsFixed(2));
          _controller.text = rounded.toString();
          widget.onChanged?.call(rounded);
        }
      }
      _previewResult = null;
    }
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChanged(String value) {
    final result = _evaluateExpression(value);
    setState(() {
      // Show preview if the text contains operators
      if (value.contains('+') || value.contains('-') ||
          value.contains('*') || value.contains('/')) {
        _previewResult = result;
      } else {
        _previewResult = null;
      }
    });
    if (result != null) {
      widget.onChanged?.call(double.parse(result.toStringAsFixed(2)));
    } else {
      final amount = double.tryParse(value) ?? 0;
      widget.onChanged?.call(amount);
    }
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
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
                    _AmountExpressionFormatter(),
                  ],
                  onChanged: _onTextChanged,
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
        ),
        // Expression preview
        if (_previewResult != null && _isFocused)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              '= \$${_previewResult!.toStringAsFixed(2)}',
              style: AppTypography.bodySmall.copyWith(
                color: prefixColor.withValues(alpha: 0.7),
              ),
            ),
          ),
      ],
    );
  }
}

class _AmountExpressionFormatter extends TextInputFormatter {
  // Allow digits, decimal point, and math operators
  final RegExp _validChars = RegExp(r'^[\d\.\+\-\*\/\s]*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    if (_validChars.hasMatch(newValue.text)) return newValue;
    return oldValue;
  }
}

/// Evaluates a simple math expression string.
/// Supports +, -, *, / operators.
/// Returns null if the expression is invalid.
double? _evaluateExpression(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  // Simple number - just parse it
  final simple = double.tryParse(trimmed);
  if (simple != null) return simple;

  try {
    // Tokenize: split into numbers and operators
    final tokens = <String>[];
    var current = '';
    for (int i = 0; i < trimmed.length; i++) {
      final c = trimmed[i];
      if (c == ' ') continue;
      if ('+-*/'.contains(c) && current.isNotEmpty) {
        tokens.add(current);
        tokens.add(c);
        current = '';
      } else {
        current += c;
      }
    }
    if (current.isNotEmpty) tokens.add(current);

    if (tokens.isEmpty) return null;

    // Parse all numbers
    final numbers = <double>[];
    final operators = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      if (i.isEven) {
        final n = double.tryParse(tokens[i]);
        if (n == null) return null;
        numbers.add(n);
      } else {
        operators.add(tokens[i]);
      }
    }

    if (numbers.isEmpty) return null;
    if (numbers.length != operators.length + 1) return null;

    // First pass: handle * and /
    final nums = List<double>.from(numbers);
    final ops = List<String>.from(operators);
    for (int i = 0; i < ops.length;) {
      if (ops[i] == '*') {
        nums[i] = nums[i] * nums[i + 1];
        nums.removeAt(i + 1);
        ops.removeAt(i);
      } else if (ops[i] == '/') {
        if (nums[i + 1] == 0) return null;
        nums[i] = nums[i] / nums[i + 1];
        nums.removeAt(i + 1);
        ops.removeAt(i);
      } else {
        i++;
      }
    }

    // Second pass: handle + and -
    var result = nums[0];
    for (int i = 0; i < ops.length; i++) {
      if (ops[i] == '+') {
        result += nums[i + 1];
      } else if (ops[i] == '-') {
        result -= nums[i + 1];
      }
    }

    return result > 0 ? result : null;
  } catch (_) {
    return null;
  }
}
