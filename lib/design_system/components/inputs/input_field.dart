import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';

class InputField extends ConsumerStatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? errorText;
  final bool showClearButton;

  const InputField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.autofocus = false,
    this.focusNode,
    this.errorText,
    this.showClearButton = true,
  });

  @override
  ConsumerState<InputField> createState() => _FMTextFieldState();
}

class _FMTextFieldState extends ConsumerState<InputField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isFocused = false;
  String? _previousErrorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
    _previousErrorText = widget.errorText;

    // Shake animation controller for errors
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(InputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake animation when error appears
    if (widget.errorText != null &&
        widget.errorText != _previousErrorText &&
        _previousErrorText == null) {
      _triggerShake();
    }
    _previousErrorText = widget.errorText;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTextChange() {
    setState(() {});
  }

  void _triggerShake() {
    _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);
    final hasError = widget.errorText != null;
    final showClear = widget.showClearButton &&
        _controller.text.isNotEmpty &&
        !widget.obscureText;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * (hasError ? 1 : 0), 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.label != null) ...[
                Text(
                  widget.label!,
                  style: AppTypography.labelMedium.copyWith(
                    color: hasError ? AppColors.expense : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.input,
                  border: Border.all(
                    color: hasError
                        ? AppColors.expense
                        : (_isFocused ? accentColor : AppColors.border),
                    width: _isFocused || hasError ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.prefix != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.inputPadding),
                        child: widget.prefix,
                      ),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: widget.onChanged,
                        keyboardType: widget.keyboardType,
                        inputFormatters: widget.inputFormatters,
                        obscureText: widget.obscureText,
                        maxLines: widget.maxLines,
                        autofocus: widget.autofocus,
                        style: AppTypography.input,
                        cursorColor: accentColor,
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          hintStyle: AppTypography.inputHint,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: widget.prefix != null ? AppSpacing.sm : AppSpacing.inputPadding,
                            vertical: AppSpacing.inputPadding,
                          ),
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: showClear ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: showClear
                          ? GestureDetector(
                              onTap: _clearText,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : const SizedBox(width: 0),
                    ),
                    if (widget.suffix != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.inputPadding),
                        child: widget.suffix,
                      ),
                    ],
                  ],
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.errorText!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.expense,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
