import 'package:uuid/uuid.dart';

import '../../features/settings/data/models/app_settings.dart' as ui;
import '../database/app_database.dart';
import 'notification_service.dart';

/// Business logic for scheduling notifications based on settings and data.
class NotificationScheduler {
  final NotificationService _notificationService;
  final AppDatabase _database;
  static const _uuid = Uuid();

  // Notification ID ranges to avoid collisions
  static const _budgetAlertBase = 1000;
  static const _recurringReminderBase = 2000;
  static const _weeklySummaryId = 3000;

  NotificationScheduler({
    required NotificationService notificationService,
    required AppDatabase database,
  })  : _notificationService = notificationService,
        _database = database;

  /// Check budget thresholds and fire immediate notification if exceeded.
  Future<void> checkBudgetThreshold({
    required ui.AppSettings settings,
    required String budgetId,
    required String budgetLabel,
    required double budgetAmount,
    required double currentSpending,
  }) async {
    if (!settings.notificationsEnabled) return;

    final percentage = budgetAmount > 0
        ? (currentSpending / budgetAmount * 100).round()
        : 0;

    for (final threshold in settings.budgetAlertThresholds) {
      if (percentage >= threshold) {
        // Check if we already sent this alert recently
        final alreadySent = await _database.wasNotificationSentRecently(
          type: 'budget_alert',
          referenceId: '${budgetId}_$threshold',
          within: const Duration(hours: 24),
        );

        if (!alreadySent) {
          final title = percentage >= 100
              ? 'Budget Exceeded'
              : 'Budget Alert: $percentage%';
          final body = percentage >= 100
              ? '$budgetLabel has exceeded its limit'
              : '$budgetLabel has reached $percentage% of its limit';

          await _notificationService.show(
            id: (_budgetAlertBase + budgetId.hashCode + threshold) & 0x7FFFFFFF,
            title: title,
            body: body,
            payload: 'budget:$budgetId',
          );

          await _database.insertNotificationLog(
            id: _uuid.v4(),
            type: 'budget_alert',
            referenceId: '${budgetId}_$threshold',
            sentAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
    }
  }

  /// Schedule recurring transaction reminders.
  Future<void> scheduleRecurringReminders({
    required ui.AppSettings settings,
    required List<({String id, String name, DateTime nextDate})> upcomingRules,
  }) async {
    if (!settings.notificationsEnabled || !settings.recurringRemindersEnabled) {
      return;
    }

    // Cancel existing recurring reminders
    for (int i = 0; i < 64; i++) {
      await _notificationService.cancel(_recurringReminderBase + i);
    }

    final advanceDays = settings.recurringReminderAdvanceDays;
    final now = DateTime.now();
    int scheduled = 0;

    for (final rule in upcomingRules) {
      if (scheduled >= 30) break; // Reserve slots for other notifications

      final reminderDate = rule.nextDate.subtract(Duration(days: advanceDays));
      if (reminderDate.isAfter(now)) {
        await _notificationService.schedule(
          id: _recurringReminderBase + scheduled,
          title: 'Upcoming Transaction',
          body: '${rule.name} is due ${advanceDays == 0 ? "today" : "in $advanceDays day${advanceDays > 1 ? "s" : ""}"}',
          scheduledDate: DateTime(
            reminderDate.year,
            reminderDate.month,
            reminderDate.day,
            9,
            0,
          ),
          payload: 'recurring:${rule.id}',
        );
        scheduled++;
      }
    }
  }

  /// Schedule weekly spending summary.
  Future<void> scheduleWeeklySummary({
    required ui.AppSettings settings,
  }) async {
    if (!settings.notificationsEnabled ||
        !settings.weeklySpendingSummaryEnabled) {
      await _notificationService.cancel(_weeklySummaryId);
      return;
    }

    // Find next occurrence of the selected day
    final now = DateTime.now();
    var nextSummaryDate = now;
    while (nextSummaryDate.weekday != settings.weeklySpendingSummaryDay) {
      nextSummaryDate = nextSummaryDate.add(const Duration(days: 1));
    }
    // If it's today but past 9am, schedule for next week
    if (nextSummaryDate.day == now.day && now.hour >= 9) {
      nextSummaryDate = nextSummaryDate.add(const Duration(days: 7));
    }

    await _notificationService.schedule(
      id: _weeklySummaryId,
      title: 'Weekly Spending Summary',
      body: 'Tap to review your spending this week',
      scheduledDate: DateTime(
        nextSummaryDate.year,
        nextSummaryDate.month,
        nextSummaryDate.day,
        9,
        0,
      ),
      payload: 'weekly_summary',
    );
  }

  /// Reschedule all notifications based on current settings.
  Future<void> rescheduleAll({
    required ui.AppSettings settings,
  }) async {
    if (!settings.notificationsEnabled) {
      await _notificationService.cancelAll();
      return;
    }

    await scheduleWeeklySummary(settings: settings);

    // Clean up old notification logs
    await _database.cleanupOldNotificationLogs(const Duration(days: 30));
  }
}
