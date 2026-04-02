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

    // Try to load cached rates from settings first
    final cachedJson = settings?.cachedExchangeRates;
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final cached = (jsonDecode(cachedJson) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        service.setCachedRates(cached, mainCurrency);
      } catch (e) {
        debugPrint('ExchangeRates: failed to load cached rates: $e');
      }
    }

    // Check if rates are stale (>24h) or fresh enough to skip fetch
    final lastFetch = settings?.lastRateFetchTimestamp;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isStale = lastFetch == null || (now - lastFetch) > 24 * 60 * 60 * 1000;

    if (!isStale && service.cachedRates.isNotEmpty) {
      return service.cachedRates;
    }

    try {
      final rates = await service.fetchRates(mainCurrency);
      // Validate fetched rates before caching
      final validatedRates = <String, double>{};
      for (final entry in rates.entries) {
        if (isValidExchangeRate(entry.value)) {
          validatedRates[entry.key] = entry.value;
        } else {
          debugPrint('ExchangeRates: rejected invalid rate for ${entry.key}: ${entry.value}');
        }
      }
      _cacheRates(validatedRates);
      return validatedRates;
    } catch (e) {
      debugPrint('ExchangeRates: failed to fetch rates: $e');
      // Return cached rates if available, but log the staleness
      if (service.cachedRates.isNotEmpty) {
        debugPrint('ExchangeRates: using cached rates as fallback');
        return service.cachedRates;
      }
      // Return minimal map with just the main currency
      debugPrint('ExchangeRates: no cached rates available, using fallback {$mainCurrency: 1.0}');
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
    } catch (e) {
      debugPrint('ExchangeRates: failed to cache rates: $e');
    }
  }

  Future<void> refresh() async {
    final mainCurrency = ref.read(mainCurrencyCodeProvider);
    final service = ref.read(exchangeRateServiceProvider);

    try {
      final rates = await service.fetchRates(mainCurrency);
      _cacheRates(rates);
      state = AsyncData(rates);
    } catch (e) {
      debugPrint('ExchangeRates: refresh failed: $e');
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
  if (fromRate == null || fromRate <= 0 || !fromRate.isFinite) return amount;

  return roundCurrency(amount / fromRate);
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
  if (fromRate != null && fromRate > 0 && fromRate.isFinite) {
    return roundCurrency(amount / fromRate);
  }

  // Fallback to stored rate (validate it too)
  if (storedConversionRate > 0 && storedConversionRate.isFinite) {
    return roundCurrency(amount * storedConversionRate);
  }

  // Last resort: return amount as-is
  return amount;
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

/// Human-readable age of the last exchange rate fetch.
/// Returns null if rates have never been fetched.
final exchangeRateAgeProvider = Provider<String?>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  if (settings == null) return null;

  final lastFetch = settings.lastRateFetchTimestamp;
  if (lastFetch == null) return null;

  final age = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(lastFetch),
  );
  if (age.inMinutes < 1) return 'Updated just now';
  if (age.inMinutes < 60) return 'Updated ${age.inMinutes}m ago';
  if (age.inHours < 24) return 'Updated ${age.inHours}h ago';
  return 'Updated ${age.inDays}d ago';
});

/// Maximum reasonable exchange rate to guard against corrupt data.
const _maxReasonableRate = 1000000.0;

/// Validates that an exchange rate is positive, finite, and reasonable.
bool isValidExchangeRate(double rate) {
  return rate > 0 && rate.isFinite && rate <= _maxReasonableRate;
}

final exchangeRateProvider =
    Provider.family<double, ({String from, String to})>((ref, params) {
  final rates = ref.watch(exchangeRatesProvider).valueOrNull;
  if (rates == null) return 1.0;
  if (params.from == params.to) return 1.0;

  final fromRate = rates[params.from];
  final toRate = rates[params.to];
  if (fromRate == null || toRate == null) return 1.0;

  final rate = toRate / fromRate;
  if (!isValidExchangeRate(rate)) return 1.0;

  return rate;
});
