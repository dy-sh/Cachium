import 'dart:convert';
import 'dart:io';

import '../utils/app_logger.dart';

const _log = AppLogger('ExchangeRateService');

abstract class ExchangeRateApi {
  String get name;
  Future<Map<String, double>> fetchRates(String baseCurrency);
}

class FrankfurterApi implements ExchangeRateApi {
  @override
  String get name => 'Frankfurter';

  @override
  Future<Map<String, double>> fetchRates(String baseCurrency) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.frankfurter.app/latest?from=$baseCurrency'),
      );
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException('Failed to fetch rates: ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final rates = (json['rates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
      // Add base currency with rate 1.0
      rates[baseCurrency] = 1.0;
      return rates;
    } finally {
      client.close();
    }
  }
}

class OpenExchangeRateApi implements ExchangeRateApi {
  @override
  String get name => 'Open ER-API';

  @override
  Future<Map<String, double>> fetchRates(String baseCurrency) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://open.er-api.com/v6/latest/$baseCurrency'),
      );
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException('Failed to fetch rates: ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final rates = (json['rates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
      rates[baseCurrency] = 1.0;
      return rates;
    } finally {
      client.close();
    }
  }
}

class ManualRatesApi implements ExchangeRateApi {
  @override
  String get name => 'Manual';

  @override
  Future<Map<String, double>> fetchRates(String baseCurrency) async {
    // Returns empty map - user provides rates manually
    return {baseCurrency: 1.0};
  }
}

class ExchangeRateService {
  ExchangeRateApi _api;
  Map<String, double> _cachedRates = {};
  String? _cachedBaseCurrency;
  DateTime? _lastFetchTime;
  static const _minFetchInterval = Duration(minutes: 5);

  ExchangeRateService({ExchangeRateApi? api})
      : _api = api ?? FrankfurterApi();

  bool get canFetch {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) >= _minFetchInterval;
  }

  void setApi(ExchangeRateApi api) {
    _api = api;
    // Don't clear cache - it serves as fallback
  }

  void setCachedRates(Map<String, double> rates, String baseCurrency) {
    _cachedRates = Map.from(rates);
    _cachedBaseCurrency = baseCurrency;
  }

  Map<String, double> get cachedRates => Map.unmodifiable(_cachedRates);
  String? get cachedBaseCurrency => _cachedBaseCurrency;

  Future<Map<String, double>> fetchRates(String baseCurrency) async {
    // Rate limit: return cached rates if fetched recently for the same base currency
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _minFetchInterval &&
        _cachedBaseCurrency == baseCurrency &&
        _cachedRates.isNotEmpty) {
      _log.debug('THROTTLED: returning cached rates (last fetch ${DateTime.now().difference(_lastFetchTime!).inSeconds}s ago)');
      return Map.from(_cachedRates);
    }

    _log.debug('fetchRates(base=$baseCurrency) using ${_api.name}');
    try {
      final rates = await _api.fetchRates(baseCurrency);
      _cachedRates = Map.from(rates);
      _cachedBaseCurrency = baseCurrency;
      _lastFetchTime = DateTime.now();
      _log.debug('SUCCESS: ${rates.length} rates, EUR=${rates['EUR']}');
      return rates;
    } catch (e) {
      _log.error('FAILED', e);
      // Return cached rates on failure if base currency matches
      if (_cachedBaseCurrency == baseCurrency && _cachedRates.isNotEmpty) {
        _log.warning('Using cached rates as fallback');
        return Map.from(_cachedRates);
      }
      rethrow;
    }
  }

  double convert(double amount, String fromCurrency, String toCurrency,
      Map<String, double> rates) {
    if (fromCurrency == toCurrency) return amount;

    final fromRate = rates[fromCurrency];
    final toRate = rates[toCurrency];

    if (fromRate == null || toRate == null) return amount;

    // Convert: amount in fromCurrency -> base -> toCurrency
    return amount / fromRate * toRate;
  }
}
