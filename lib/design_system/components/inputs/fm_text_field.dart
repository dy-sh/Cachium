import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class FMTextField extends StatefulWidget {
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

  const FMTextField({
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
  });

  @override
  State<FMTextField> createState() => _FMTextFieldState();
}

class _FMTextFieldState extends State<FMTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.input,
            border: Border.all(
              color: _isFocused ? AppColors.borderSelected : AppColors.border,
              width: _isFocused ? 1.5 : 1,
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
                  cursorColor: AppColors.textPrimary,
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
              if (widget.suffix != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.inputPadding),
                  child: widget.suffix,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
