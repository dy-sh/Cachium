import 'package:cachium/features/accounts/data/models/account.dart';
import 'package:cachium/features/accounts/presentation/providers/account_form_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountFormState.isSaving', () {
    test('defaults to false', () {
      const state = AccountFormState();
      expect(state.isSaving, isFalse);
    });

    test('copyWith toggles isSaving to true', () {
      const state = AccountFormState(name: 'Checking', type: AccountType.cash);
      final saving = state.copyWith(isSaving: true);
      expect(saving.isSaving, isTrue);
      expect(saving.name, 'Checking');
      expect(saving.type, AccountType.cash);
    });

    test('copyWith without isSaving preserves value', () {
      final state = const AccountFormState(name: 'Savings')
          .copyWith(isSaving: true);
      final next = state.copyWith(name: 'Renamed');
      expect(next.isSaving, isTrue);
      expect(next.name, 'Renamed');
    });

    test('copyWith can reset isSaving to false', () {
      final state = const AccountFormState().copyWith(isSaving: true);
      final next = state.copyWith(isSaving: false);
      expect(next.isSaving, isFalse);
    });
  });

  group('AccountFormState.isValid', () {
    test('false when type missing', () {
      const state = AccountFormState(name: 'Test');
      expect(state.isValid, isFalse);
    });

    test('false when name empty', () {
      const state = AccountFormState(type: AccountType.cash);
      expect(state.isValid, isFalse);
    });

    test('true when both name and type set', () {
      const state =
          AccountFormState(name: 'Test', type: AccountType.cash);
      expect(state.isValid, isTrue);
    });
  });
}
