import '../../../transactions/data/models/transaction.dart';

enum RecurringFrequency {
  weekly,
  biweekly,
  monthly,
  yearly,
}

extension RecurringFrequencyExtension on RecurringFrequency {
  String get displayName {
    switch (this) {
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.biweekly:
        return 'Bi-weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  int get averageDays {
    switch (this) {
      case RecurringFrequency.weekly:
        return 7;
      case RecurringFrequency.biweekly:
        return 14;
      case RecurringFrequency.monthly:
        return 30;
      case RecurringFrequency.yearly:
        return 365;
    }
  }
}

enum RecurringConfidence {
  high,
  medium,
  low,
}

extension RecurringConfidenceExtension on RecurringConfidence {
  String get displayName {
    switch (this) {
      case RecurringConfidence.high:
        return 'High';
      case RecurringConfidence.medium:
        return 'Medium';
      case RecurringConfidence.low:
        return 'Low';
    }
  }
}

class RecurringTransaction {
  final String id;
  final String? merchant;
  final String categoryId;
  final double amount;
  final RecurringFrequency frequency;
  final RecurringConfidence confidence;
  final DateTime lastOccurrence;
  final DateTime? nextExpected;
  final List<Transaction> matchingTransactions;
  final int occurrenceCount;

  const RecurringTransaction({
    required this.id,
    this.merchant,
    required this.categoryId,
    required this.amount,
    required this.frequency,
    required this.confidence,
    required this.lastOccurrence,
    this.nextExpected,
    required this.matchingTransactions,
    required this.occurrenceCount,
  });

  double get monthlyAmount {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return amount * 4.33;
      case RecurringFrequency.biweekly:
        return amount * 2.17;
      case RecurringFrequency.monthly:
        return amount;
      case RecurringFrequency.yearly:
        return amount / 12;
    }
  }

  double get yearlyAmount {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return amount * 52;
      case RecurringFrequency.biweekly:
        return amount * 26;
      case RecurringFrequency.monthly:
        return amount * 12;
      case RecurringFrequency.yearly:
        return amount;
    }
  }
}

class RecurringSummary {
  final List<RecurringTransaction> subscriptions;
  final double totalMonthly;
  final double totalYearly;
  final int count;

  const RecurringSummary({
    required this.subscriptions,
    required this.totalMonthly,
    required this.totalYearly,
    required this.count,
  });

  factory RecurringSummary.empty() {
    return const RecurringSummary(
      subscriptions: [],
      totalMonthly: 0,
      totalYearly: 0,
      count: 0,
    );
  }
}
