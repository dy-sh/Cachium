import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart' show conversionGainLoss, roundCurrency;
import '../../../settings/presentation/providers/settings_provider.dart';
import 'filtered_transactions_provider.dart';

class ConversionGainLossData {
  final double totalGainLoss;
  final Map<String, double> byCurrency;
  final bool hasSkippedDueToMainCurrencyChange;

  const ConversionGainLossData({
    required this.totalGainLoss,
    required this.byCurrency,
    this.hasSkippedDueToMainCurrencyChange = false,
  });
}

final conversionGainLossProvider = Provider<ConversionGainLossData>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final mainCurrency = ref.watch(mainCurrencyCodeProvider);
  final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};

  double total = 0;
  final byCurrency = <String, double>{};
  bool hasSkipped = false;

  for (final tx in transactions) {
    // Detect transactions skipped due to main currency mismatch
    if (tx.currencyCode != tx.mainCurrencyCode &&
        tx.mainCurrencyCode != mainCurrency &&
        tx.mainCurrencyAmount != null) {
      hasSkipped = true;
    }
    final gl = conversionGainLoss(tx, rates, mainCurrency);
    if (gl == null) continue;
    total += gl;
    byCurrency[tx.currencyCode] = (byCurrency[tx.currencyCode] ?? 0) + gl;
  }

  // Round values
  total = roundCurrency(total);
  for (final key in byCurrency.keys.toList()) {
    byCurrency[key] = roundCurrency(byCurrency[key]!);
  }

  return ConversionGainLossData(
    totalGainLoss: total,
    byCurrency: byCurrency,
    hasSkippedDueToMainCurrencyChange: hasSkipped,
  );
});
