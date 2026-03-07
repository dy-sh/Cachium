import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'filtered_transactions_provider.dart';

class ConversionGainLossData {
  final double totalGainLoss;
  final Map<String, double> byCurrency;

  const ConversionGainLossData({
    required this.totalGainLoss,
    required this.byCurrency,
  });
}

final conversionGainLossProvider = Provider<ConversionGainLossData>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final mainCurrency = ref.watch(mainCurrencyCodeProvider);
  final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};

  double total = 0;
  final byCurrency = <String, double>{};

  for (final tx in transactions) {
    final gl = conversionGainLoss(tx, rates, mainCurrency);
    if (gl == null) continue;
    total += gl;
    byCurrency[tx.currencyCode] = (byCurrency[tx.currencyCode] ?? 0) + gl;
  }

  // Round values
  total = double.parse(total.toStringAsFixed(2));
  for (final key in byCurrency.keys.toList()) {
    byCurrency[key] = double.parse(byCurrency[key]!.toStringAsFixed(2));
  }

  return ConversionGainLossData(
    totalGainLoss: total,
    byCurrency: byCurrency,
  );
});
