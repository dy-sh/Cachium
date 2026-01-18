import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/color_picker_grid.dart';
import '../widgets/coming_soon_tile.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final categories = ref.watch(categoriesProvider);
    final customCategoryCount = categories.where((c) => c.isCustom).length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text('Settings', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Categories Section
                SettingsSection(
                  title: 'Categories',
                  children: [
                    SettingsTile(
                      title: 'Manage Categories',
                      description: customCategoryCount > 0
                          ? '$customCategoryCount custom ${customCategoryCount == 1 ? 'category' : 'categories'}'
                          : 'Create and edit categories',
                      icon: LucideIcons.tags,
                      iconColor: AppColors.accentOptions[1],
                      onTap: () => context.push('/settings/categories'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Appearance Section
                SettingsSection(
                  title: 'Appearance',
                  children: [
                    _buildColorIntensityTile(context, ref, settings),
                    _buildAccentColorTile(context, ref, settings),
                    SettingsToggleTile(
                      title: 'Tab Transitions',
                      description: 'Fade effect when switching tabs',
                      value: settings.tabTransitionsEnabled,
                      onChanged: (value) => ref.read(settingsProvider.notifier).setTabTransitionsEnabled(value),
                    ),
                    SettingsToggleTile(
                      title: 'Form Animations',
                      description: 'Slide-in effects for forms and modals',
                      value: settings.formAnimationsEnabled,
                      onChanged: (value) => ref.read(settingsProvider.notifier).setFormAnimationsEnabled(value),
                    ),
                    SettingsToggleTile(
                      title: 'Balance Counters',
                      description: 'Animate balance numbers when they change',
                      value: settings.balanceCountersEnabled,
                      onChanged: (value) => ref.read(settingsProvider.notifier).setBalanceCountersEnabled(value),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Formats Section
                SettingsSection(
                  title: 'Formats',
                  children: [
                    _buildDateFormatTile(context, ref, settings),
                    _buildCurrencyTile(context, ref, settings),
                    _buildFirstDayTile(context, ref, settings),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Preferences Section
                SettingsSection(
                  title: 'Preferences',
                  children: [
                    SettingsToggleTile(
                      title: 'Haptic Feedback',
                      description: 'Vibration on button taps',
                      value: settings.hapticFeedbackEnabled,
                      onChanged: (value) => ref.read(settingsProvider.notifier).setHapticFeedbackEnabled(value),
                    ),
                    _buildStartScreenTile(context, ref, settings),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Coming Soon Section
                SettingsSection(
                  title: 'Coming Soon',
                  children: const [
                    ComingSoonTile(
                      title: 'Import/Export CSV',
                      icon: LucideIcons.fileSpreadsheet,
                    ),
                    ComingSoonTile(
                      title: 'iCloud Sync',
                      icon: LucideIcons.cloud,
                    ),
                    ComingSoonTile(
                      title: 'Apple Watch App',
                      icon: LucideIcons.watch,
                    ),
                    ComingSoonTile(
                      title: 'Siri Integration',
                      icon: LucideIcons.mic,
                    ),
                    ComingSoonTile(
                      title: 'Password Protection',
                      icon: LucideIcons.lock,
                    ),
                    ComingSoonTile(
                      title: 'Graphs & Analytics',
                      icon: LucideIcons.barChart3,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // About Section
                SettingsSection(
                  title: 'About',
                  children: [
                    SettingsTile(
                      title: 'Version',
                      value: '1.0.0',
                      showChevron: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorIntensityTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    return SettingsTile(
      title: 'Color Intensity',
      description: 'Vibrant or muted colors throughout the app',
      value: settings.colorIntensity == ColorIntensity.bright ? 'Bright' : 'Dim',
      showChevron: false,
      trailing: _buildSegmentedControl(
        options: ['Bright', 'Dim'],
        selectedIndex: settings.colorIntensity == ColorIntensity.bright ? 0 : 1,
        onChanged: (index) {
          ref.read(settingsProvider.notifier).setColorIntensity(
                index == 0 ? ColorIntensity.bright : ColorIntensity.dim,
              );
        },
      ),
    );
  }

  Widget _buildAccentColorTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accent Color', style: AppTypography.bodyMedium),
          const SizedBox(height: 2),
          Text(
            'Affects selected states, buttons, highlights',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          ColorPickerGrid(
            colors: AppColors.accentOptions,
            selectedColor: settings.accentColor,
            onColorSelected: (color) {
              ref.read(settingsProvider.notifier).setAccentColor(color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFormatTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    return SettingsTile(
      title: 'Date Format',
      value: settings.dateFormat.label,
      onTap: () => _showDateFormatPicker(context, ref, settings),
    );
  }

  Widget _buildCurrencyTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    final displayValue = settings.currencySymbol == CurrencySymbol.custom
        ? settings.customCurrencySymbol ?? '\$'
        : settings.currencySymbol.symbol;
    return SettingsTile(
      title: 'Currency Symbol',
      value: displayValue,
      onTap: () => _showCurrencyPicker(context, ref, settings),
    );
  }

  Widget _buildFirstDayTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    return SettingsTile(
      title: 'First Day of Week',
      description: 'For calendar display',
      value: settings.firstDayOfWeek == FirstDayOfWeek.sunday ? 'Sunday' : 'Monday',
      showChevron: false,
      trailing: _buildSegmentedControl(
        options: ['Sun', 'Mon'],
        selectedIndex: settings.firstDayOfWeek == FirstDayOfWeek.sunday ? 0 : 1,
        onChanged: (index) {
          ref.read(settingsProvider.notifier).setFirstDayOfWeek(
                index == 0 ? FirstDayOfWeek.sunday : FirstDayOfWeek.monday,
              );
        },
      ),
    );
  }

  Widget _buildStartScreenTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    final startScreenLabels = {
      StartScreen.home: 'Home',
      StartScreen.transactions: 'Transactions',
      StartScreen.accounts: 'Accounts',
    };
    return SettingsTile(
      title: 'Start Screen',
      value: startScreenLabels[settings.startScreen],
      onTap: () => _showStartScreenPicker(context, ref, settings),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OptionPickerSheet(
        title: 'Date Format',
        options: DateFormatOption.values.map((f) => f.label).toList(),
        selectedIndex: DateFormatOption.values.indexOf(settings.dateFormat),
        onSelected: (index) {
          ref.read(settingsProvider.notifier).setDateFormat(DateFormatOption.values[index]);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CurrencyPickerSheet(
        settings: settings,
        onSelected: (symbol, customValue) {
          ref.read(settingsProvider.notifier).setCurrencySymbol(symbol);
          if (symbol == CurrencySymbol.custom && customValue != null) {
            ref.read(settingsProvider.notifier).setCustomCurrencySymbol(customValue);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStartScreenPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OptionPickerSheet(
        title: 'Start Screen',
        options: const ['Home', 'Transactions', 'Accounts'],
        selectedIndex: StartScreen.values.indexOf(settings.startScreen),
        onSelected: (index) {
          ref.read(settingsProvider.notifier).setStartScreen(StartScreen.values[index]);
          Navigator.pop(context);
        },
      ),
    );
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
