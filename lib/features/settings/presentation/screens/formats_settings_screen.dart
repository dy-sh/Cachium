import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
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
                        Text('Formats', style: AppTypography.h3),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SettingsSection(
                    title: 'Display Formats',
                    children: [
                      SettingsTile(
                        title: 'Date Format',
                        value: settings.dateFormat.label,
                        onTap: () => _showDateFormatPicker(context, ref, settings),
                      ),
                      SettingsTile(
                        title: 'Currency Symbol',
                        value: settings.currencySymbol == CurrencySymbol.custom
                            ? settings.customCurrencySymbol ?? '\$'
                            : settings.currencySymbol.symbol,
                        onTap: () => _showCurrencyPicker(context, ref, settings),
                      ),
                      _buildFirstDayTile(context, ref, settings),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
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
                borderRadius: BorderRadius.circular(4),
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
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = _CurrencyPickerSheet(
      settings: settings,
      onSelected: (symbol, customValue) {
        ref.read(settingsProvider.notifier).setCurrencySymbol(symbol);
        if (symbol == CurrencySymbol.custom && customValue != null) {
          ref.read(settingsProvider.notifier).setCustomCurrencySymbol(customValue);
        }
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
        isScrollControlled: true,
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
                  borderRadius: BorderRadius.circular(2),
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

class _CurrencyPickerSheet extends StatefulWidget {
  final AppSettings settings;
  final void Function(CurrencySymbol symbol, String? customValue) onSelected;

  const _CurrencyPickerSheet({
    required this.settings,
    required this.onSelected,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  late TextEditingController _customController;
  late CurrencySymbol _selectedSymbol;

  @override
  void initState() {
    super.initState();
    _selectedSymbol = widget.settings.currencySymbol;
    _customController = TextEditingController(
      text: widget.settings.customCurrencySymbol ?? '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Currency Symbol', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.lg),
            ...CurrencySymbol.values.where((s) => s != CurrencySymbol.custom).map((symbol) {
              final isSelected = symbol == _selectedSymbol;
              return GestureDetector(
                onTap: () {
                  widget.onSelected(symbol, null);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          symbol.symbol,
                          style: AppTypography.bodyLarge,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          symbol.label,
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _customController,
                    style: AppTypography.bodyLarge,
                    maxLength: 3,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '\$',
                      hintStyle: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.textPrimary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_customController.text.isNotEmpty) {
                        widget.onSelected(CurrencySymbol.custom, _customController.text);
                      }
                    },
                    child: Text(
                      'Custom',
                      style: AppTypography.bodyMedium.copyWith(
                        color: _selectedSymbol == CurrencySymbol.custom
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                if (_selectedSymbol == CurrencySymbol.custom)
                  Icon(
                    LucideIcons.check,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
