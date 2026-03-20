import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/buttons/secondary_button.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const TutorialScreen({super.key, required this.onComplete});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _TutorialPage(
      icon: LucideIcons.arrowLeftRight,
      title: 'Track Transactions',
      description:
          'Add income, expenses, and transfers to keep a complete record of your finances.',
    ),
    _TutorialPage(
      icon: LucideIcons.wallet,
      title: 'Manage Accounts',
      description:
          'Organize your bank accounts, cash, credit cards, and investments all in one place.',
    ),
    _TutorialPage(
      icon: LucideIcons.target,
      title: 'Set Budgets',
      description:
          'Create monthly budgets and track your spending progress to stay on target.',
    ),
    _TutorialPage(
      icon: LucideIcons.barChart3,
      title: 'View Analytics',
      description:
          'Explore charts, calendar views, and insights to understand your spending habits.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await ref.read(settingsProvider.notifier).setTutorialCompleted(true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SecondaryButton(
                  label: 'Skip',
                  onPressed: _complete,
                  isExpanded: false,
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding * 2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 48,
                            color: AppColors.accentPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          page.title,
                          style: AppTypography.h2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.accentPrimary
                          : AppColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: isLastPage ? 'Get Started' : 'Next',
                  onPressed: () {
                    if (isLastPage) {
                      _complete();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
