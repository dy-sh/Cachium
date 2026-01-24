import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class PageLayout extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final EdgeInsets? padding;
  final bool extendBody;

  const PageLayout({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.title,
    this.actions,
    this.showBackButton = false,
    this.onBack,
    this.padding,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: extendBody,
      appBar: title != null || showBackButton || actions != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: SafeArea(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    children: [
                      if (showBackButton)
                        GestureDetector(
                          onTap: onBack ?? () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: padding != null
          ? Padding(padding: padding!, child: body)
          : body,
      floatingActionButton: floatingActionButton,
    );
  }
}
