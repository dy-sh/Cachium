import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/search_result.dart';
import '../providers/global_search_provider.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() =>
      _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(globalSearchResultsProvider);
    final query = ref.watch(globalSearchQueryProvider);
    final intensity = ref.watch(colorIntensityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(globalSearchQueryProvider.notifier)
                              .state = '';
                          context.pop();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onChanged: (value) {
                              ref
                                  .read(
                                      globalSearchQueryProvider.notifier)
                                  .state = value;
                            },
                            style: AppTypography.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Search everywhere...',
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              prefixIcon: Icon(
                                LucideIcons.search,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              suffixIcon: query.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _controller.clear();
                                        ref
                                            .read(
                                                globalSearchQueryProvider
                                                    .notifier)
                                            .state = '';
                                      },
                                      child: Icon(
                                        LucideIcons.x,
                                        size: 16,
                                        color: AppColors.textTertiary,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            // Results
            Expanded(
              child: query.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.search,
                              size: 48,
                              color: AppColors.textTertiary
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Search transactions, accounts, and categories',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPadding,
                            ),
                            child: EmptyState.centered(
                              icon: LucideIcons.searchX,
                              title: 'No results found',
                              subtitle:
                                  'Try a different search term',
                            ),
                          ),
                        )
                      : _buildResults(results, intensity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
      List<GlobalSearchResult> results, dynamic intensity) {
    // Group results by type
    final accounts = results
        .where((r) => r.type == SearchResultType.account)
        .toList();
    final categories = results
        .where((r) => r.type == SearchResultType.category)
        .toList();
    final transactions = results
        .where((r) => r.type == SearchResultType.transaction)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      children: [
        if (accounts.isNotEmpty) ...[
          _SectionHeader(
            title: 'Accounts',
            count: accounts.length,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...accounts.map((r) => _SearchResultTile(result: r)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (categories.isNotEmpty) ...[
          _SectionHeader(
            title: 'Categories',
            count: categories.length,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...categories.map((r) => _SearchResultTile(result: r)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (transactions.isNotEmpty) ...[
          _SectionHeader(
            title: 'Transactions',
            count: transactions.length,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...transactions.map((r) => _SearchResultTile(result: r)),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '($count)',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final GlobalSearchResult result;

  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: result.route != null
          ? () => context.push(result.route!)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: result.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                result.icon,
                size: 18,
                color: result.color,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (result.route != null)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
