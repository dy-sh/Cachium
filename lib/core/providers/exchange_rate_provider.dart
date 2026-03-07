import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/models/app_settings.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../services/exchange_rate_service.dart';
import '../utils/currency_conversion.dart';

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

void _log(String msg) {
  // ignore: avoid_print
  if (kDebugMode) print(msg);
}

class ExchangeRatesNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() async {
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);
    final apiOption = ref.watch(exchangeRateApiOptionProvider);
    final service = ref.read(exchangeRateServiceProvider);
    final settings = ref.read(settingsProvider).valueOrNull;

    // Wire up the selected API
    switch (apiOption) {
      case ExchangeRateApiOption.frankfurter:
        service.setApi(FrankfurterApi());
      case ExchangeRateApiOption.exchangeRateHost:
        service.setApi(OpenExchangeRateApi());
      case ExchangeRateApiOption.manual:
        service.setApi(ManualRatesApi());
    }

    _log('[ExchangeRates] build() mainCurrency=$mainCurrency api=${apiOption.name}');

    // Try to load cached rates from settings first
    final cachedJson = settings?.cachedExchangeRates;
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final cached = (jsonDecode(cachedJson) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        service.setCachedRates(cached, mainCurrency);
        _log('[ExchangeRates] Loaded ${cached.length} cached rates, EUR=${cached['EUR']}');
      } catch (e) {
        _log('[ExchangeRates] Failed to parse cached rates: $e');
      }
    } else {
      _log('[ExchangeRates] No cached rates found');
    }

    // Check if rates are stale (>24h) or fresh enough to skip fetch
    final lastFetch = settings?.lastRateFetchTimestamp;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isStale = lastFetch == null || (now - lastFetch) > 24 * 60 * 60 * 1000;

    if (!isStale && service.cachedRates.isNotEmpty) {
      _log('[ExchangeRates] Rates are fresh (${((now - lastFetch) / 3600000).toStringAsFixed(1)}h old), using cache');
      return service.cachedRates;
    }

    try {
      final rates = await service.fetchRates(mainCurrency);
      _log('[ExchangeRates] Fetched ${rates.length} rates from API, EUR=${rates['EUR']}');
      // Cache the fetched rates in settings
      _cacheRates(rates);
      return rates;
    } catch (e) {
      _log('[ExchangeRates] API fetch failed: $e');
      // Return cached rates if available
      if (service.cachedRates.isNotEmpty) {
        _log('[ExchangeRates] Using ${service.cachedRates.length} cached rates as fallback');
        return service.cachedRates;
      }
      // Return minimal map with just the main currency
      _log('[ExchangeRates] No cached rates, returning only {$mainCurrency: 1.0}');
      return {mainCurrency: 1.0};
    }
  }

  void _cacheRates(Map<String, double> rates) {
    try {
      final json = jsonEncode(rates);
      ref.read(settingsProvider.notifier).setCachedExchangeRates(json);
      ref.read(settingsProvider.notifier).setLastRateFetchTimestamp(
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    final mainCurrency = ref.read(mainCurrencyCodeProvider);
    final service = ref.read(exchangeRateServiceProvider);

    try {
      final rates = await service.fetchRates(mainCurrency);
      _cacheRates(rates);
      state = AsyncData(rates);
    } catch (_) {
      // Keep current state on refresh failure
    }
  }
}

final exchangeRatesProvider =
    AsyncNotifierProvider<ExchangeRatesNotifier, Map<String, double>>(() {
  return ExchangeRatesNotifier();
});

/// Convert an amount from one currency to the main currency using current rates.
double convertToMainCurrency(
  double amount,
  String fromCurrency,
  String mainCurrency,
  Map<String, double> rates,
) {
  if (fromCurrency == mainCurrency) return amount;

  final fromRate = rates[fromCurrency];
  if (fromRate == null) {
    _log('[convertToMain] NO RATE for $fromCurrency in ${rates.length} rates. Returning $amount as-is');
    return amount;
  }

  final result = roundCurrency(amount / fromRate);
  _log('[convertToMain] $amount $fromCurrency / $fromRate = $result $mainCurrency');
  return result;
}

/// Convert a transaction amount to the main currency for display/aggregation.
/// Uses the transaction's stored conversion rate as fallback when live rates unavailable.
double convertTransactionToMainCurrency(
  double amount,
  String fromCurrency,
  String mainCurrency,
  Map<String, double> rates,
  double storedConversionRate,
) {
  if (fromCurrency == mainCurrency) return amount;

  final fromRate = rates[fromCurrency];
  if (fromRate != null) {
    return roundCurrency(amount / fromRate);
  }

  // Fallback to stored rate
  return roundCurrency(amount * storedConversionRate);
}

/// Whether exchange rates are stale (>24h old) or missing.
final exchangeRatesStaleProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  if (settings == null) return false;

  final lastFetch = settings.lastRateFetchTimestamp;
  if (lastFetch == null) return true;

  final now = DateTime.now().millisecondsSinceEpoch;
  return (now - lastFetch) > 24 * 60 * 60 * 1000;
});

final exchangeRateProvider =
    Provider.family<double, ({String from, String to})>((ref, params) {
  final rates = ref.watch(exchangeRatesProvider).valueOrNull;
  if (rates == null) return 1.0;
  if (params.from == params.to) return 1.0;

  final fromRate = rates[params.from];
  final toRate = rates[params.to];
  if (fromRate == null || toRate == null) return 1.0;

  return toRate / fromRate;
});
