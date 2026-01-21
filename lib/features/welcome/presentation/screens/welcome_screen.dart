import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../data/demo/demo_data.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/database_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../widgets/welcome_option_card.dart';

enum WelcomeOption { demo, defaultCategories, empty }

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  WelcomeOption? _loadingOption;

  Future<void> _handleOptionSelected(WelcomeOption option) async {
    if (_loadingOption != null) return;

    setState(() {
      _loadingOption = option;
    });

    try {
      final accountRepo = ref.read(accountRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);

      switch (option) {
        case WelcomeOption.demo:
          // Seed accounts
          for (final account in DemoData.accounts) {
            await accountRepo.createAccount(account);
          }
          // Seed default categories
          await categoryRepo.seedDefaultCategories();
          // Seed transactions
          for (final transaction in DemoData.transactions) {
            await transactionRepo.createTransaction(transaction);
          }
          break;

        case WelcomeOption.defaultCategories:
          // Only seed default categories
          await categoryRepo.seedDefaultCategories();
          break;

        case WelcomeOption.empty:
          // Do nothing - start with empty database
          break;
      }

      // Mark onboarding as completed
      await ref.read(settingsProvider.notifier).setOnboardingCompleted(true);

      // Reset the resetting flag if it was set
      ref.read(isResettingDatabaseProvider.notifier).state = false;

      // Invalidate providers to refresh UI
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(shouldShowWelcomeProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingOption = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  size: 36,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Title
              Text(
                'Welcome to Cachium',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              // Subtitle
              Text(
                'How would you like to get started?',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // Options
              StaggeredList(
                itemDelay: const Duration(milliseconds: 100),
                children: [
                  WelcomeOptionCard(
                    icon: LucideIcons.sparkles,
                    iconColor: AppColors.getAccentColor(11, intensity),
                    title: 'Create Demo Data',
                    description:
                        'Load sample accounts, categories, and transactions. Perfect for exploring the app\'s features.',
                    isLoading: _loadingOption == WelcomeOption.demo,
                    onTap: () => _handleOptionSelected(WelcomeOption.demo),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  WelcomeOptionCard(
                    icon: LucideIcons.layoutGrid,
                    iconColor: AppColors.getAccentColor(3, intensity),
                    title: 'Create Default Categories',
                    description:
                        'Start with a ready-to-use set of income and expense categories. A great starting point.',
                    isLoading: _loadingOption == WelcomeOption.defaultCategories,
                    onTap: () => _handleOptionSelected(WelcomeOption.defaultCategories),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  WelcomeOptionCard(
                    icon: LucideIcons.plus,
                    iconColor: AppColors.getAccentColor(7, intensity),
                    title: 'Start from Scratch',
                    description:
                        'Begin with a completely empty database. Full control from the start.',
                    isLoading: _loadingOption == WelcomeOption.empty,
                    onTap: () => _handleOptionSelected(WelcomeOption.empty),
                  ),
                ],
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
