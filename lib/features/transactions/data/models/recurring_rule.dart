import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'transaction.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.biweekly:
        return 'Bi-weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  IconData get icon {
    switch (this) {
      case RecurrenceFrequency.daily:
        return LucideIcons.clock;
      case RecurrenceFrequency.weekly:
        return LucideIcons.calendarDays;
      case RecurrenceFrequency.biweekly:
        return LucideIcons.calendarRange;
      case RecurrenceFrequency.monthly:
        return LucideIcons.calendar;
      case RecurrenceFrequency.yearly:
        return LucideIcons.calendarHeart;
    }
  }

  /// Calculate the next date after [from] based on this frequency.
  DateTime nextDate(DateTime from) {
    switch (this) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.biweekly:
        return from.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}

/// A user-defined recurring transaction rule that auto-generates transactions.
class RecurringRule {
  final String id;
  final String name;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final String? destinationAccountId;
  final String? merchant;
  final String? note;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime lastGeneratedDate;
  final bool isActive;
  final DateTime createdAt;

  const RecurringRule({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.destinationAccountId,
    this.merchant,
    this.note,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.lastGeneratedDate,
    this.isActive = true,
    required this.createdAt,
  });

  RecurringRule copyWith({
    String? id,
    String? name,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? destinationAccountId,
    bool clearDestinationAccountId = false,
    String? merchant,
    String? note,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? lastGeneratedDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      destinationAccountId: clearDestinationAccountId
          ? null
          : (destinationAccountId ?? this.destinationAccountId),
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the next date a transaction should be generated.
  DateTime? get nextDueDate {
    if (!isActive) return null;
    final next = frequency.nextDate(lastGeneratedDate);
    if (endDate != null && next.isAfter(endDate!)) return null;
    return next;
  }

  /// Check if there are pending transactions to generate (up to today).
  bool get hasPendingGenerations {
    final next = nextDueDate;
    if (next == null) return false;
    return !next.isAfter(DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurringRule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
