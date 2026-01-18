import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A base class for Riverpod notifiers that manage CRUD operations on a list.
///
/// Subclasses should implement [getId] to extract the ID from an item.
///
/// Usage:
/// ```dart
/// class AccountsNotifier extends CrudNotifier<Account> {
///   @override
///   String getId(Account item) => item.id;
///
///   @override
///   List<Account> build() => initialAccounts;
/// }
/// ```
abstract class CrudNotifier<T> extends Notifier<List<T>> {
  /// Gets the unique identifier for an item.
  String getId(T item);

  /// Adds an item to the list.
  void add(T item) {
    state = [...state, item];
  }

  /// Updates an existing item by its ID.
  void update(T item) {
    state = state.map((i) => getId(i) == getId(item) ? item : i).toList();
  }

  /// Deletes an item by its ID.
  void delete(String id) {
    state = state.where((i) => getId(i) != id).toList();
  }

  /// Gets an item by its ID, or null if not found.
  T? getById(String id) {
    try {
      return state.firstWhere((i) => getId(i) == id);
    } catch (_) {
      return null;
    }
  }

  /// Replaces the entire list.
  void setAll(List<T> items) {
    state = items;
  }

  /// Clears all items.
  void clear() {
    state = [];
  }
}
