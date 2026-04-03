import 'package:cachium/core/services/exchange_rate_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake API that returns fixed rates.
class FakeExchangeRateApi implements ExchangeRateApi {
  final Map<String, double> rates;
  final bool shouldFail;
  int callCount = 0;

  FakeExchangeRateApi({
    this.rates = const {'USD': 1.0, 'EUR': 0.85, 'GBP': 0.73},
    this.shouldFail = false,
  });

  @override
  String get name => 'Fake';

  @override
  Future<Map<String, double>> fetchRates(String baseCurrency) async {
    callCount++;
    if (shouldFail) throw Exception('Network error');
    return Map.from(rates);
  }
}

void main() {
  group('ExchangeRateService', () {
    late ExchangeRateService service;
    late FakeExchangeRateApi fakeApi;

    setUp(() {
      fakeApi = FakeExchangeRateApi();
      service = ExchangeRateService(api: fakeApi);
    });

    test('fetchRates returns rates from API', () async {
      final rates = await service.fetchRates('USD');
      expect(rates['EUR'], 0.85);
      expect(rates['GBP'], 0.73);
      expect(fakeApi.callCount, 1);
    });

    test('fetchRates caches results', () async {
      await service.fetchRates('USD');
      expect(service.cachedRates['EUR'], 0.85);
      expect(service.cachedBaseCurrency, 'USD');
    });

    test('throttles repeated calls within 5 minutes', () async {
      await service.fetchRates('USD');
      await service.fetchRates('USD');
      // Second call should be throttled — only 1 actual API call
      expect(fakeApi.callCount, 1);
    });

    test('does not throttle for different base currency', () async {
      await service.fetchRates('USD');
      await service.fetchRates('EUR');
      expect(fakeApi.callCount, 2);
    });

    test('returns cached rates on failure', () async {
      // First call succeeds
      await service.fetchRates('USD');
      expect(fakeApi.callCount, 1);

      // Switch to failing API
      final failApi = FakeExchangeRateApi(shouldFail: true);
      service.setApi(failApi);

      // Force a fetch by using a different base initially then back
      // Actually, since rates are cached with 'USD', a direct call
      // within throttle window returns cached. Let's create a fresh service.
      final failService = ExchangeRateService(api: failApi);
      failService.setCachedRates({'USD': 1.0, 'EUR': 0.85}, 'USD');

      final rates = await failService.fetchRates('USD');
      expect(rates['EUR'], 0.85); // got cached rates
    });

    test('rethrows on failure when no cached rates', () async {
      final failApi = FakeExchangeRateApi(shouldFail: true);
      final failService = ExchangeRateService(api: failApi);

      expect(
        () => failService.fetchRates('USD'),
        throwsA(isA<Exception>()),
      );
    });

    test('convert handles same currency', () {
      final rates = {'USD': 1.0, 'EUR': 0.85};
      expect(service.convert(100, 'USD', 'USD', rates), 100);
    });

    test('convert handles cross-currency', () {
      final rates = {'USD': 1.0, 'EUR': 0.85};
      final result = service.convert(100, 'USD', 'EUR', rates);
      expect(result, closeTo(85.0, 0.01));
    });

    test('convert returns amount when currency not found', () {
      final rates = {'USD': 1.0};
      expect(service.convert(100, 'USD', 'JPY', rates), 100);
    });

    test('canFetch is true initially', () {
      expect(service.canFetch, true);
    });

    test('setApi does not clear cache', () {
      service.setCachedRates({'USD': 1.0}, 'USD');
      service.setApi(FakeExchangeRateApi());
      expect(service.cachedRates['USD'], 1.0);
    });
  });

  group('ManualRatesApi', () {
    test('returns only base currency', () async {
      final api = ManualRatesApi();
      final rates = await api.fetchRates('EUR');
      expect(rates, {'EUR': 1.0});
    });
  });
}
