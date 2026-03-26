import '../../../transactions/data/models/recurring_rule.dart';

/// A bill reminder with due date tracking.
class Bill {
  final String id;
  final String name;
  final double amount;
  final String currencyCode;
  final String? categoryId;
  final String? accountId;
  final String? assetId;
  final DateTime dueDate;
  final RecurrenceFrequency frequency;
  final bool isPaid;
  final DateTime? paidDate;
  final String? note;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final DateTime createdAt;

  const Bill({
    required this.id,
    required this.name,
    required this.amount,
    this.currencyCode = 'USD',
    this.categoryId,
    this.accountId,
    this.assetId,
    required this.dueDate,
    this.frequency = RecurrenceFrequency.monthly,
    this.isPaid = false,
    this.paidDate,
    this.note,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
    required this.createdAt,
  }) : assert(amount >= 0, 'Bill amount must be non-negative'),
       assert(reminderDaysBefore >= 0, 'Reminder days must be non-negative');

  /// Whether this bill is overdue (past due date and not paid).
  bool get isOverdue =>
      !isPaid && dueDate.isBefore(DateTime.now());

  /// Days until due date (negative if overdue).
  int get daysUntilDue =>
      DateTime(dueDate.year, dueDate.month, dueDate.day)
          .difference(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ))
          .inDays;

  /// Calculate the next due date based on the current due date and frequency.
  DateTime get nextDueDate => frequency.nextDate(dueDate);

  Bill copyWith({
    String? id,
    String? name,
    double? amount,
    String? currencyCode,
    String? categoryId,
    bool clearCategoryId = false,
    String? accountId,
    bool clearAccountId = false,
    String? assetId,
    bool clearAssetId = false,
    DateTime? dueDate,
    RecurrenceFrequency? frequency,
    bool? isPaid,
    DateTime? paidDate,
    bool clearPaidDate = false,
    String? note,
    bool clearNote = false,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      assetId: clearAssetId ? null : (assetId ?? this.assetId),
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      isPaid: isPaid ?? this.isPaid,
      paidDate: clearPaidDate ? null : (paidDate ?? this.paidDate),
      note: clearNote ? null : (note ?? this.note),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
