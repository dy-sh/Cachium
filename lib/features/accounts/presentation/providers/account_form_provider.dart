import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/account.dart';
import 'accounts_provider.dart';

/// Result of an account save operation.
class AccountSaveResult {
  final bool success;
  final String? errorMessage;
  final String? newAccountId;

  const AccountSaveResult({
    required this.success,
    this.errorMessage,
    this.newAccountId,
  });
}

class AccountFormState {
  final AccountType? type;
  final String name;
  final double initialBalance;
  final double transactionDelta; // sum of all transactions for this account
  final String currencyCode;
  final String? editingAccountId;
  final int? customColorIndex; // null means use default type color
  final Color? originalCustomColor; // stored color from account being edited
  final bool isSaving;

  const AccountFormState({
    this.type,
    this.name = '',
    this.initialBalance = 0,
    this.transactionDelta = 0,
    this.currencyCode = 'USD',
    this.editingAccountId,
    this.customColorIndex,
    this.originalCustomColor,
    this.isSaving = false,
  });

  // Current balance is computed from initial balance + transactions
  double get currentBalance => initialBalance + transactionDelta;

  bool get isValid => type != null && name.isNotEmpty;

  bool get isEditing => editingAccountId != null;

  bool get hasCustomColor => customColorIndex != null;

  AccountFormState copyWith({
    AccountType? type,
    String? name,
    double? initialBalance,
    double? transactionDelta,
    String? currencyCode,
    String? editingAccountId,
    int? customColorIndex,
    bool clearCustomColor = false,
    Color? originalCustomColor,
    bool clearOriginalCustomColor = false,
    bool? isSaving,
  }) {
    return AccountFormState(
      type: type ?? this.type,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      transactionDelta: transactionDelta ?? this.transactionDelta,
      currencyCode: currencyCode ?? this.currencyCode,
      editingAccountId: editingAccountId ?? this.editingAccountId,
      customColorIndex: clearCustomColor ? null : (customColorIndex ?? this.customColorIndex),
      originalCustomColor: clearOriginalCustomColor ? null : (originalCustomColor ?? this.originalCustomColor),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class AccountFormNotifier extends AutoDisposeNotifier<AccountFormState> {
  @override
  AccountFormState build() {
    final mainCurrency = ref.read(mainCurrencyCodeProvider);
    return AccountFormState(currencyCode: mainCurrency);
  }

  void setType(AccountType type) {
    // Clear custom color when changing type (reset to type's default color)
    state = state.copyWith(type: type, clearCustomColor: true, clearOriginalCustomColor: true);
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setInitialBalance(double balance) {
    state = state.copyWith(initialBalance: balance);
  }

  void reset() {
    state = AccountFormState(currencyCode: ref.read(mainCurrencyCodeProvider));
  }

  void setCurrencyCode(String code) {
    state = state.copyWith(currencyCode: code);
  }

  void initForEdit(Account account) {
    // Transaction delta = current balance - initial balance
    final transactionDelta = account.balance - account.initialBalance;
    state = AccountFormState(
      type: account.type,
      name: account.name,
      initialBalance: account.initialBalance,
      transactionDelta: transactionDelta,
      currencyCode: account.currencyCode,
      editingAccountId: account.id,
      originalCustomColor: account.customColor,
    );
  }

  void setTransactionDelta(double delta) {
    state = state.copyWith(transactionDelta: delta);
  }

  void setCustomColorIndex(int? index) {
    if (index == null) {
      state = state.copyWith(clearCustomColor: true);
    } else {
      state = state.copyWith(customColorIndex: index);
    }
  }

  /// Persist the current form as either a new account or an update.
  ///
  /// [customColor] is resolved by the caller from the current color intensity
  /// palette since that palette is UI-facing and lives outside the notifier.
  Future<AccountSaveResult> save({required Color? customColor}) async {
    if (state.isSaving) {
      return const AccountSaveResult(
        success: false,
        errorMessage: 'Save already in progress',
      );
    }
    if (!state.isValid) {
      return const AccountSaveResult(
        success: false,
        errorMessage: 'Please fill in all required fields',
      );
    }

    state = state.copyWith(isSaving: true);
    try {
      final formState = state;
      if (formState.isEditing) {
        final originalAccount = ref.read(
          accountByIdProvider(formState.editingAccountId!),
        );
        if (originalAccount == null) {
          return const AccountSaveResult(
            success: false,
            errorMessage: 'Account no longer exists',
          );
        }
        // Calculate new balance based on initial balance change
        final initialBalanceDiff =
            formState.initialBalance - originalAccount.initialBalance;
        final newBalance = originalAccount.balance + initialBalanceDiff;

        final updatedAccount = originalAccount.copyWith(
          name: formState.name,
          type: formState.type,
          initialBalance: formState.initialBalance,
          balance: newBalance,
          currencyCode: formState.currencyCode,
          customColor: customColor,
        );
        await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
        return const AccountSaveResult(success: true);
      } else {
        final newAccountId = await ref
            .read(accountsProvider.notifier)
            .addAccount(
              name: formState.name,
              type: formState.type!,
              initialBalance: formState.initialBalance,
              currencyCode: formState.currencyCode,
              customColor: customColor,
            );
        return AccountSaveResult(success: true, newAccountId: newAccountId);
      }
    } catch (e) {
      return AccountSaveResult(
        success: false,
        errorMessage:
            e is AppException ? e.userMessage : 'Failed to save account',
      );
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

final accountFormProvider =
    AutoDisposeNotifierProvider<AccountFormNotifier, AccountFormState>(() {
  return AccountFormNotifier();
});
