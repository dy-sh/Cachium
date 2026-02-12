import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether multi-select mode is active
final transactionSelectionModeProvider = StateProvider<bool>((ref) => false);

/// Set of currently selected transaction IDs
final selectedTransactionIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Whether a specific transaction is selected
final isTransactionSelectedProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(selectedTransactionIdsProvider).contains(id);
});

/// Count of currently selected transactions
final selectedCountProvider = Provider<int>((ref) {
  return ref.watch(selectedTransactionIdsProvider).length;
});
