import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'transaction_form_provider.dart';

mixin TransactionCurrencyHandler
    on AutoDisposeNotifier<TransactionFormState> {
  void recalculateDestinationAmount() {
    if (!state.isTransfer || state.accountId == null || state.destinationAccountId == null) {
      return;
    }
    final srcAccount = ref.read(accountByIdProvider(state.accountId!));
    final dstAccount = ref.read(accountByIdProvider(state.destinationAccountId!));
    if (srcAccount == null || dstAccount == null) return;

    if (srcAccount.currencyCode == dstAccount.currencyCode) {
      // Same currency - no destinationAmount needed
      state = state.copyWith(clearDestinationAmount: true);
      return;
    }

    // Cross-currency: calculate using live rates
    if (state.amount > 0) {
      final rate = ref.read(exchangeRateProvider((from: srcAccount.currencyCode, to: dstAccount.currencyCode)));
      final converted = state.amount * rate;
      state = state.copyWith(destinationAmount: roundCurrency(converted));
    }
  }

  void refreshExchangeRateForAccount(String accountId) {
    final account = ref.read(accountByIdProvider(accountId));
    final currencyCode = account?.currencyCode ?? state.currencyCode;
    final mainCurrency = ref.read(mainCurrencyCodeProvider);

    double conversionRate = 1.0;
    if (currencyCode != mainCurrency) {
      // Auto-refresh rates if stale and this is a foreign-currency account
      final isStale = ref.read(exchangeRatesStaleProvider);
      if (isStale) {
        ref.read(exchangeRatesProvider.notifier).refresh();
      }

      final rate = ref.read(exchangeRateProvider((from: currencyCode, to: mainCurrency)));
      conversionRate = rate;
    }

    state = state.copyWith(
      accountId: accountId,
      currencyCode: currencyCode,
      conversionRate: conversionRate,
    );
  }
}
