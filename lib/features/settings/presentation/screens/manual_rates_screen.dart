import 'dart:convert';

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
import '../providers/settings_provider.dart';

class ManualRatesScreen extends ConsumerStatefulWidget {
  const ManualRatesScreen({super.key});

  @override
  ConsumerState<ManualRatesScreen> createState() => _ManualRatesScreenState();
}

class _ManualRatesScreenState extends ConsumerState<ManualRatesScreen> {
  late Map<String, double> _rates;
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _rates = {};
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadRates() {
    final settings = ref.read(settingsProvider).valueOrNull;
    final mainCurrency = settings?.mainCurrencyCode ?? 'USD';
    final cachedJson = settings?.cachedExchangeRates;

    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final cached = (jsonDecode(cachedJson) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        _rates = Map.from(cached);
      } catch (_) {
        _rates = {mainCurrency: 1.0};
      }
    } else {
      _rates = {mainCurrency: 1.0};
    }

    // Init controllers for existing rates
    for (final entry in _rates.entries) {
      if (!_controllers.containsKey(entry.key)) {
        _controllers[entry.key] = TextEditingController(
          text: entry.value == 1.0 && entry.key == mainCurrency ? '1.0' : entry.value.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final mainCurrency = settings.mainCurrencyCode;

    // Load rates on first build
    if (_rates.isEmpty) {
      _loadRates();
    }

    // Sort: main currency first, then alphabetically
    final sortedKeys = _rates.keys.toList()
      ..sort((a, b) {
        if (a == mainCurrency) return -1;
        if (b == mainCurrency) return 1;
        return a.compareTo(b);
      });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsHeader(
              title: 'Manual Rates',
              actions: [
                CircularButton(
                  onTap: () => _addCurrency(context, mainCurrency),
                  icon: LucideIcons.plus,
                  size: AppSpacing.settingsBackButtonSize,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set exchange rates relative to $mainCurrency (1 $mainCurrency = ?)',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final code = sortedKeys[index];
                  final isBase = code == mainCurrency;
                  final currency = Currency.fromCode(code);
                  final controller = _controllers[code]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(currency.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 44,
                          child: Text(
                            code,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: isBase
                              ? Text(
                                  '1.0 (base)',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                )
                              : TextField(
                                  controller: controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: AppTypography.input,
                                  cursorColor: AppColors.textPrimary,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    final parsed = double.tryParse(value);
                                    if (parsed != null && parsed > 0) {
                                      _rates[code] = parsed;
                                    }
                                  },
                                ),
                        ),
                        if (!isBase)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rates.remove(code);
                                _controllers[code]?.dispose();
                                _controllers.remove(code);
                              });
                            },
                            child: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => _saveRates(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Center(
                      child: Text(
                        'Save Rates',
                        style: AppTypography.button.copyWith(
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCurrency(BuildContext context, String mainCurrency) {
    showCurrencyPickerSheet(
      context: context,
      selectedCode: mainCurrency,
      onSelected: (code) {
        if (_rates.containsKey(code)) return;
        setState(() {
          _rates[code] = 1.0;
          _controllers[code] = TextEditingController(text: '1.0');
        });
      },
    );
  }

  void _saveRates(BuildContext context) {
    final json = jsonEncode(_rates);
    ref.read(settingsProvider.notifier).setCachedExchangeRates(json);

    // Update the exchange rate service cache
    final mainCurrency = ref.read(mainCurrencyCodeProvider);
    final service = ref.read(exchangeRateServiceProvider);
    service.setCachedRates(_rates, mainCurrency);

    // Invalidate to pick up new rates
    ref.invalidate(exchangeRatesProvider);

    if (context.mounted) {
      context.pop();
      context.showSuccessNotification('Manual rates saved');
    }
  }
}
