import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../accounts/data/models/account.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// A widget for selecting an account from a grid.
/// Shows recently used accounts first, with a "More" button to reveal others.
class AccountSelector extends ConsumerStatefulWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final List<String>? recentAccountIds;
  final int initialVisibleCount;
  final VoidCallback? onCreatePressed;

  const AccountSelector({
    super.key,
    required this.accounts,
    this.selectedId,
    required this.onChanged,
    this.recentAccountIds,
    this.initialVisibleCount = 3,
    this.onCreatePressed,
  });

  @override
  ConsumerState<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends ConsumerState<AccountSelector> {
  bool _showAll = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch({bool collapse = false}) {
    _searchController.clear();
    _searchQuery = '';
    _searchFocusNode.unfocus();
    if (collapse) {
      _showAll = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);

    // Show empty state if no accounts available
    if (widget.accounts.isEmpty) {
      return EmptyState(
        icon: LucideIcons.walletCards,
        title: 'No accounts available',
        subtitle: 'Tap to create an account',
        onTap: widget.onCreatePressed,
      );
    }

    // Sort accounts by recent usage if provided
    final sortedAccounts = _getSortedAccounts();
    final filteredAccounts = _searchQuery.isEmpty
        ? sortedAccounts
        : sortedAccounts.where((a) => a.name.toLowerCase().contains(_searchQuery)).toList();
    final hasMore = sortedAccounts.length > widget.initialVisibleCount;

    // Calculate items to show: accounts + optional "More" button + optional "Create" button
    final List<_GridItem> gridItems = [];

    if (_showAll || !hasMore) {
      // Show all accounts (use filtered when searching)
      for (final account in filteredAccounts) {
        gridItems.add(_GridItem.account(account));
      }
      // Add create button when expanded or when 3 or fewer accounts
      if (widget.onCreatePressed != null) {
        gridItems.add(_GridItem.create());
      }
    } else {
      // Show limited accounts + "More" button
      for (int i = 0; i < widget.initialVisibleCount; i++) {
        gridItems.add(_GridItem.account(sortedAccounts[i]));
      }
      gridItems.add(_GridItem.more(sortedAccounts.length - widget.initialVisibleCount));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showAll) ...[
          InputField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hint: 'Search accounts...',
            prefix: Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
            suffix: GestureDetector(
              onTap: () => setState(() => _clearSearch(collapse: true)),
              child: Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
            ),
            showClearButton: false,
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnimatedSize(
          duration: AppAnimations.slow,
          curve: AppAnimations.defaultCurve,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              crossAxisSpacing: AppSpacing.chipGap,
              mainAxisSpacing: AppSpacing.chipGap,
            ),
            itemCount: gridItems.length,
            itemBuilder: (context, index) {
              final item = gridItems[index];
              switch (item.type) {
                case _GridItemType.account:
                  final account = item.account!;
                  final isSelected = account.id == widget.selectedId;
                  return _AccountCard(
                    account: account,
                    isSelected: isSelected,
                    intensity: intensity,
                    onTap: () {
                      HapticHelper.lightImpact();
                      widget.onChanged(account.id);
                      // Clear search and unfocus when selecting an account
                      setState(_clearSearch);
                    },
                  );
                case _GridItemType.more:
                  return _MoreCard(
                    count: item.moreCount!,
                    onTap: () => setState(() => _showAll = true),
                  );
                case _GridItemType.create:
                  return _CreateNewCard(onTap: widget.onCreatePressed!);
              }
            },
          ),
        ),
        if (_showAll && hasMore) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() {
              _showAll = false;
              _clearSearch();
            }),
            child: Text(
              'Show Less',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Account> _getSortedAccounts() {
    if (widget.recentAccountIds == null || widget.recentAccountIds!.isEmpty) {
      return widget.accounts;
    }

    // Create a map for quick lookup
    final accountMap = {for (var a in widget.accounts) a.id: a};

    // Build sorted list: recent accounts first, then remaining
    final sorted = <Account>[];
    final addedIds = <String>{};

    // Add accounts in order of recent usage
    for (final id in widget.recentAccountIds!) {
      final account = accountMap[id];
      if (account != null && !addedIds.contains(id)) {
        sorted.add(account);
        addedIds.add(id);
      }
    }

    // Add any remaining accounts not in the recent list
    for (final account in widget.accounts) {
      if (!addedIds.contains(account.id)) {
        sorted.add(account);
      }
    }

    return sorted;
  }
}

enum _GridItemType { account, more, create }

class _GridItem {
  final _GridItemType type;
  final Account? account;
  final int? moreCount;

  _GridItem._({required this.type, this.account, this.moreCount});

  factory _GridItem.account(Account account) =>
      _GridItem._(type: _GridItemType.account, account: account);

  factory _GridItem.more(int count) =>
      _GridItem._(type: _GridItemType.more, moreCount: count);

  factory _GridItem.create() => _GridItem._(type: _GridItemType.create);
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final bool isSelected;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.isSelected,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accountColor = account.getColorWithIntensity(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return SelectableCard(
      isSelected: isSelected,
      color: accountColor,
      bgOpacity: bgOpacity,
      icon: account.icon,
      onTap: onTap,
      unselectedIconBgColor: accountColor.withOpacity(0.6),
      unselectedIconColor: AppColors.background,
      selectedIconColor: AppColors.background,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            account.name,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? accountColor : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '\$${account.balance.toStringAsFixed(0)}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MoreCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticHelper.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                LucideIcons.moreHorizontal,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '+$count More',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateNewCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateNewCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.3),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: 16,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              'New Account',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
