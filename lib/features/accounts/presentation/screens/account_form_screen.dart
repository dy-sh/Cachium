import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/fm_primary_button.dart';
import '../../../../design_system/components/layout/fm_form_header.dart';
import '../../../../design_system/components/inputs/fm_text_field.dart';
import '../../data/models/account.dart';
import '../providers/account_form_provider.dart';
import '../providers/accounts_provider.dart';

class AccountFormScreen extends ConsumerWidget {
  const AccountFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(accountFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FMFormHeader(
              title: 'New Account',
              onClose: () => context.pop(),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Type', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.md),
                    _AccountTypeGrid(
                      selectedType: formState.type,
                      onChanged: (type) {
                        ref.read(accountFormProvider.notifier).setType(type);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    FMTextField(
                      label: 'Account Name',
                      hint: 'Enter account name...',
                      autofocus: false,
                      onChanged: (value) {
                        ref.read(accountFormProvider.notifier).setName(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    FMTextField(
                      label: 'Initial Balance',
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      prefix: Text(
                        '\$',
                        style: AppTypography.input.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(accountFormProvider.notifier).setInitialBalance(
                              double.tryParse(value) ?? 0,
                            );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: FMPrimaryButton(
                label: 'Create Account',
                onPressed: formState.isValid
                    ? () {
                        ref.read(accountsProvider.notifier).addAccount(
                              name: formState.name,
                              type: formState.type!,
                              initialBalance: formState.initialBalance,
                            );
                        ref.read(accountFormProvider.notifier).reset();
                        context.pop();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTypeGrid extends StatelessWidget {
  final AccountType? selectedType;
  final ValueChanged<AccountType> onChanged;

  const _AccountTypeGrid({
    this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.1,
      children: AccountType.values.map((type) {
        final isSelected = type == selectedType;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            decoration: BoxDecoration(
              color: isSelected
                  ? type.color.withOpacity(0.15)
                  : AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: isSelected ? type.color : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type.icon,
                  color: isSelected ? type.color : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  type.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? type.color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
