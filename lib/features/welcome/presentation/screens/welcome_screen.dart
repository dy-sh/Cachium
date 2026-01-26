import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../data/demo/demo_data.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/database_management_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../widgets/welcome_option_card.dart';

/// Default accounts created when selecting "Default Categories" option.
class DefaultAccounts {
  static List<Account> get all => [
        Account(
          id: 'a0b1c2d3-e4f5-4a6b-7c8d-9e0f1a2b3c4d',
          name: 'Cash',
          type: AccountType.cash,
          balance: 0,
          initialBalance: 0,
          createdAt: DateTime.now(),
        ),
        Account(
          id: 'b1c2d3e4-f5a6-4b7c-8d9e-0f1a2b3c4d5e',
          name: 'Credit Card',
          type: AccountType.creditCard,
          balance: 0,
          initialBalance: 0,
          createdAt: DateTime.now(),
        ),
      ];
}

enum WelcomeOption { demo, defaultCategories, empty }

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  WelcomeOption? _loadingOption;

  Future<void> _handleImportFromBackup() async {
    if (_loadingOption != null) return;

    // Mark onboarding as completed with empty database
    await ref.read(settingsProvider.notifier).setOnboardingCompleted(true);
    await ref.read(settingsProvider.notifier).setStartScreen(StartScreen.home);

    // Reset the resetting flag if it was set
    ref.read(isResettingDatabaseProvider.notifier).state = false;

    // Invalidate data providers
    ref.invalidate(accountsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(databaseMetricsProvider);
    ref.invalidate(shouldShowWelcomeProvider);

    // Navigate to database settings in import-only mode
    if (mounted) {
      ref.read(appRouterProvider).go('${AppRoutes.databaseSettings}?importOnly=true');
    }
  }

  Future<void> _handleOptionSelected(WelcomeOption option) async {
    if (_loadingOption != null) return;

    setState(() {
      _loadingOption = option;
    });

    try {
      final db = ref.read(databaseProvider);
      final accountRepo = ref.read(accountRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);

      // Wrap all database operations in a transaction to prevent locking
      await db.transaction(() async {
        switch (option) {
          case WelcomeOption.demo:
            // Seed accounts
            for (final account in DemoData.accounts) {
              await accountRepo.upsertAccount(account);
            }
            // Seed default categories
            await categoryRepo.seedDefaultCategories();
            // Seed transactions
            for (final transaction in DemoData.transactions) {
              await transactionRepo.upsertTransaction(transaction);
            }
            break;

          case WelcomeOption.defaultCategories:
            // Seed default accounts (Cash and Credit Card)
            for (final account in DefaultAccounts.all) {
              await accountRepo.upsertAccount(account);
            }
            // Seed default categories
            await categoryRepo.seedDefaultCategories();
            break;

          case WelcomeOption.empty:
            // Do nothing - start with empty database
            break;
        }
      });

      // Mark onboarding as completed
      await ref.read(settingsProvider.notifier).setOnboardingCompleted(true);

      // Ensure we start at home screen after welcome
      await ref.read(settingsProvider.notifier).setStartScreen(StartScreen.home);

      // Reset the resetting flag if it was set
      ref.read(isResettingDatabaseProvider.notifier).state = false;

      // Invalidate all data providers to reload from database
      ref.invalidate(accountsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(shouldShowWelcomeProvider);

      // Invalidate router to create fresh instance starting at home
      ref.invalidate(appRouterProvider);
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Setup failed: $e');
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
                    iconColor: AppColors.getAccentColor(19, intensity), // violet - demo/magic
                    title: 'Create Demo Data',
                    description:
                        'Load sample accounts, categories, and transactions. Perfect for exploring the app\'s features.',
                    isLoading: _loadingOption == WelcomeOption.demo,
                    onTap: () => _handleOptionSelected(WelcomeOption.demo),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  WelcomeOptionCard(
                    icon: LucideIcons.layoutGrid,
                    iconColor: AppColors.getAccentColor(9, intensity), // green - ready/go
                    title: 'Quick Start',
                    description:
                        'Create default categories and basic accounts (Cash, Credit Card). A great starting point.',
                    isLoading: _loadingOption == WelcomeOption.defaultCategories,
                    onTap: () => _handleOptionSelected(WelcomeOption.defaultCategories),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  WelcomeOptionCard(
                    icon: LucideIcons.plus,
                    iconColor: AppColors.getAccentColor(13, intensity), // cyan - fresh/clean
                    title: 'Start from Scratch',
                    description:
                        'Begin with a completely empty database. Full control from the start.',
                    isLoading: _loadingOption == WelcomeOption.empty,
                    onTap: () => _handleOptionSelected(WelcomeOption.empty),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Import from backup hint
              GestureDetector(
                onTap: _handleImportFromBackup,
                child: Text.rich(
                  TextSpan(
                    text: 'Have a backup? ',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Import data',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 2),
              // Hint
              Text(
                'To open this screen again:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Settings → Database → Reset',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
