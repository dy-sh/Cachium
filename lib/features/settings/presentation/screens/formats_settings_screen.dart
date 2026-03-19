import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class FormatsSettingsScreen extends ConsumerWidget {
  const FormatsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: LoadingIndicator()),
      );
    }

    final mainCurrency = Currency.fromCode(settings.mainCurrencyCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SettingsHeader(title: 'Formats'),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSection(
                      title: 'Display Formats',
                      children: [
                        SettingsTile(
                          title: 'Date Format',
                          value: settings.dateFormat.label,
                          onTap: () => _showDateFormatPicker(context, ref, settings),
                        ),
                        SettingsTile(
                          title: 'Main Currency',
                          value: '${mainCurrency.flag} ${mainCurrency.code} (${mainCurrency.symbol})',
                          onTap: () => _showCurrencyPicker(context, ref, settings),
                        ),
                        SettingsTile(
                          title: 'Exchange Rate Source',
                          value: settings.exchangeRateApiOption.displayName,
                          onTap: () => _showExchangeRateApiPicker(context, ref, settings),
                        ),
                        _buildRateStatusTile(context, ref, settings),
                        _buildFirstDayTile(context, ref, settings),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateStatusTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    if (settings.exchangeRateApiOption == ExchangeRateApiOption.manual) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rates', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(
                    'Using manual / cached rates',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/settings/formats/manual-rates'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Edit Rates',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final lastFetch = settings.lastRateFetchTimestamp;
    String statusText;
    if (lastFetch == null) {
      statusText = 'Never fetched';
    } else {
      final fetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
      final diff = DateTime.now().difference(fetchTime);
      if (diff.inMinutes < 1) {
        statusText = 'Just now';
      } else if (diff.inHours < 1) {
        statusText = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        statusText = '${diff.inHours}h ago';
      } else {
        statusText = '${diff.inDays}d ago (stale)';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rates as of', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: AppTypography.bodySmall.copyWith(
                    color: lastFetch != null && DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastFetch)).inHours >= 24
                        ? AppColors.amber
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await ref.read(exchangeRatesProvider.notifier).refresh();
              if (context.mounted) {
                context.showSuccessNotification('Exchange rates refreshed');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                LucideIcons.refreshCw,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstDayTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('First Day of Week', style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'For calendar display',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildSegmentedControl(
            options: ['Sun', 'Mon'],
            selectedIndex: settings.firstDayOfWeek == FirstDayOfWeek.sunday ? 0 : 1,
            onChanged: (index) {
              ref.read(settingsProvider.notifier).setFirstDayOfWeek(
                    index == 0 ? FirstDayOfWeek.sunday : FirstDayOfWeek.monday,
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : Colors.transparent,
                borderRadius: AppRadius.xsAll,
              ),
              child: Text(
                options[index],
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showDateFormatPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = _OptionPickerSheet(
      title: 'Date Format',
      options: DateFormatOption.values.map((f) => f.label).toList(),
      selectedIndex: DateFormatOption.values.indexOf(settings.dateFormat),
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setDateFormat(DateFormatOption.values[index]);
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    showCurrencyPickerSheet(
      context: context,
      selectedCode: settings.mainCurrencyCode,
      onSelected: (code) {
        ref.read(settingsProvider.notifier).setMainCurrencyCode(code);
      },
    );
  }

  void _showExchangeRateApiPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = _OptionPickerSheet(
      title: 'Exchange Rate Source',
      options: ExchangeRateApiOption.values.map((o) => o.displayName).toList(),
      selectedIndex: ExchangeRateApiOption.values.indexOf(settings.exchangeRateApiOption),
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setExchangeRateApiOption(
          ExchangeRateApiOption.values[index],
        );
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }
}

class _OptionPickerSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.xxsAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.h4),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(options.length, (index) {
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          options[index],
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.check,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
