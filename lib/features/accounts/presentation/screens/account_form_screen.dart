import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/fm_primary_button.dart';
import '../../../../design_system/components/inputs/fm_text_field.dart';
import '../../data/models/account.dart';
import '../providers/accounts_provider.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  AccountType? _selectedType;
  String _name = '';
  double _initialBalance = 0;

  bool get _isValid => _selectedType != null && _name.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'New Account',
                      style: AppTypography.h3,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account type selection
                    Text('Account Type', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.md),
                    _AccountTypeGrid(
                      selectedType: _selectedType,
                      onChanged: (type) {
                        setState(() => _selectedType = type);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Name input
                    FMTextField(
                      label: 'Account Name',
                      hint: 'Enter account name...',
                      autofocus: false,
                      onChanged: (value) {
                        setState(() => _name = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Initial balance
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
                        setState(() {
                          _initialBalance = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // Save button
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: FMPrimaryButton(
                label: 'Create Account',
                onPressed: _isValid
                    ? () {
                        ref.read(accountsProvider.notifier).addAccount(
                              name: _name,
                              type: _selectedType!,
                              initialBalance: _initialBalance,
                            );
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
            duration: const Duration(milliseconds: 200),
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
