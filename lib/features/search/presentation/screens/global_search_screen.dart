import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/search_result.dart';
import '../providers/global_search_provider.dart';
import '../providers/search_history_provider.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() =>
      _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(globalSearchQueryProvider.notifier).state = value;
      }
    });
  }

  void _executeSearch(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: query.length);
    ref.read(globalSearchQueryProvider.notifier).state = query;
    ref.read(searchHistoryProvider.notifier).addSearch(query);
    _focusNode.unfocus();
  }

  void _onSearchSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addSearch(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(globalSearchResultsProvider);
    final query = ref.watch(globalSearchQueryProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final recentSearches =
        ref.watch(searchHistoryProvider).valueOrNull ?? [];

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
                      CircularButton(
                        onTap: () {
                          ref
                              .read(globalSearchQueryProvider.notifier)
                              .state = '';
                          ref
                              .read(searchFilterProvider.notifier)
                              .state = SearchFilter.all;
                          context.pop();
                        },
                        icon: LucideIcons.chevronLeft,
                        size: AppSpacing.settingsBackButtonSize,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.iconButton,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onChanged: _onQueryChanged,
                            onSubmitted: _onSearchSubmitted,
                            textInputAction: TextInputAction.search,
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
                                        _debounceTimer?.cancel();
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
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            // Filter chips (only visible when there's a query)
            if (query.isNotEmpty) _buildFilterChips(),
            // Results / empty state / recent searches
            Expanded(
              child: query.isEmpty
                  ? _buildEmptyQueryState(recentSearches)
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
                                  'Try a different search term or filter',
                            ),
                          ),
                        )
                      : _buildResults(results, query, intensity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final currentFilter = ref.watch(searchFilterProvider);
    final accentColor = ref.watch(accentColorProvider);

    final filters = [
      (SearchFilter.all, 'All', LucideIcons.layers),
      (SearchFilter.transactions, 'Transactions', LucideIcons.receipt),
      (SearchFilter.accounts, 'Accounts', LucideIcons.wallet),
      (SearchFilter.categories, 'Categories', LucideIcons.layoutGrid),
      (SearchFilter.tags, 'Tags', LucideIcons.tag),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (filter, label, icon) = filters[index];
          final isSelected = currentFilter == filter;

          return SelectionChip(
            label: label,
            icon: icon,
            isSelected: isSelected,
            selectedColor: accentColor,
            onTap: () {
              ref.read(searchFilterProvider.notifier).state = filter;
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyQueryState(List<String> recentSearches) {
    if (recentSearches.isEmpty) {
      return Center(
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
                color: AppColors.textTertiary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Search transactions, accounts, categories, and tags',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(searchHistoryProvider.notifier).clearAll();
              },
              child: Text(
                'Clear All',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recentSearches.map((query) => _RecentSearchTile(
              query: query,
              onTap: () => _executeSearch(query),
              onRemove: () {
                ref
                    .read(searchHistoryProvider.notifier)
                    .removeSearch(query);
              },
            )),
      ],
    );
  }

  Widget _buildResults(
    List<GlobalSearchResult> results,
    String query,
    dynamic intensity,
  ) {
    // Group results by type
    final accounts = results
        .where((r) => r.type == SearchResultType.account)
        .toList();
    final categories = results
        .where((r) => r.type == SearchResultType.category)
        .toList();
    final tags = results
        .where((r) => r.type == SearchResultType.tag)
        .toList();
    final transactions = results
        .where((r) => r.type == SearchResultType.transaction)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (accounts.isNotEmpty) ...[
          _SectionHeader(
            title: 'Accounts',
            count: accounts.length,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...accounts.map((r) => _SearchResultTile(
                result: r,
                query: query,
              )),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (categories.isNotEmpty) ...[
          _SectionHeader(
            title: 'Categories',
            count: categories.length,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...categories.map((r) => _SearchResultTile(
                result: r,
                query: query,
              )),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (tags.isNotEmpty) ...[
          _SectionHeader(
            title: 'Tags',
            count: tags.length,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...tags.map((r) => _SearchResultTile(
                result: r,
                query: query,
              )),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (transactions.isNotEmpty) ...[
          _SectionHeader(
            title: 'Transactions',
            count: transactions.length,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...transactions.map((r) => _SearchResultTile(
                result: r,
                query: query,
              )),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _RecentSearchTile extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchTile({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 16,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                query,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
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
  final String query;

  const _SearchResultTile({
    required this.result,
    required this.query,
  });

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
          borderRadius: AppRadius.iconButton,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: result.color.withValues(alpha: 0.12),
                borderRadius: AppRadius.smAll,
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
                  _HighlightedText(
                    text: result.title,
                    query: query,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    highlightColor: result.color,
                  ),
                  const SizedBox(height: 2),
                  _HighlightedText(
                    text: result.subtitle,
                    query: query,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    highlightColor: result.color,
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

/// Renders text with query matches highlighted.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: highlightColor,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = index + query.length;
    }

    if (spans.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
