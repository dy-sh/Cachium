import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/inputs/toggle.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;
    if (settings == null) return const SizedBox.shrink();

    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Notifications',
              onClose: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding),
                children: [
                  // Master toggle
                  SettingsSection(
                    title: 'General',
                    children: [
                      SettingsTile(
                        title: 'Enable Notifications',
                        description: 'Allow Cachium to send local notifications',
                        icon: LucideIcons.bell,
                        showChevron: false,
                        trailing: Toggle(
                          value: settings.notificationsEnabled,
                          onChanged: (value) async {
                            if (value) {
                              final granted = await NotificationService()
                                  .requestPermissions();
                              if (!granted) {
                                if (context.mounted) {
                                  context.showWarningNotification(
                                      'Notification permission denied');
                                }
                                return;
                              }
                            }
                            notifier.setNotificationsEnabled(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Budget alerts
                  SettingsSection(
                    title: 'Budget Alerts',
                    children: [
                      SettingsTile(
                        title: 'Alert Thresholds',
                        description: settings.budgetAlertThresholds
                            .map((t) => '$t%')
                            .join(', '),
                        icon: LucideIcons.alertTriangle,
                        showChevron: false,
                      ),
                    ],
                  ),
                  if (!settings.notificationsEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Enable notifications to use budget alerts',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  // Recurring reminders
                  SettingsSection(
                    title: 'Recurring Reminders',
                    children: [
                      SettingsTile(
                        title: 'Remind Before Due',
                        description: 'Get notified before recurring transactions',
                        icon: LucideIcons.clock,
                        showChevron: false,
                        trailing: Toggle(
                          value: settings.recurringRemindersEnabled &&
                              settings.notificationsEnabled,
                          onChanged: settings.notificationsEnabled
                              ? (value) =>
                                  notifier.setRecurringRemindersEnabled(value)
                              : null,
                        ),
                      ),
                      SettingsTile(
                        title: 'Advance Days',
                        description:
                            '${settings.recurringReminderAdvanceDays} day${settings.recurringReminderAdvanceDays != 1 ? "s" : ""} before due date',
                        icon: LucideIcons.calendarClock,
                        showChevron: false,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: settings.recurringReminderAdvanceDays > 0
                                  ? () => notifier
                                      .setRecurringReminderAdvanceDays(
                                          settings.recurringReminderAdvanceDays -
                                              1)
                                  : null,
                              child: Icon(LucideIcons.minus,
                                  size: 18, color: AppColors.textSecondary),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              child: Text(
                                '${settings.recurringReminderAdvanceDays}',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                            GestureDetector(
                              onTap: settings.recurringReminderAdvanceDays < 7
                                  ? () => notifier
                                      .setRecurringReminderAdvanceDays(
                                          settings.recurringReminderAdvanceDays +
                                              1)
                                  : null,
                              child: Icon(LucideIcons.plus,
                                  size: 18, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Weekly summary
                  SettingsSection(
                    title: 'Weekly Summary',
                    children: [
                      SettingsTile(
                        title: 'Weekly Spending Summary',
                        description: 'Get a spending overview each week',
                        icon: LucideIcons.barChart3,
                        showChevron: false,
                        trailing: Toggle(
                          value: settings.weeklySpendingSummaryEnabled &&
                              settings.notificationsEnabled,
                          onChanged: settings.notificationsEnabled
                              ? (value) => notifier
                                  .setWeeklySpendingSummaryEnabled(value)
                              : null,
                        ),
                      ),
                      SettingsTile(
                        title: 'Summary Day',
                        description: _dayName(settings.weeklySpendingSummaryDay),
                        icon: LucideIcons.calendar,
                        showChevron: false,
                        trailing: DropdownButton<int>(
                          value: settings.weeklySpendingSummaryDay,
                          underline: const SizedBox.shrink(),
                          dropdownColor: AppColors.surface,
                          style: AppTypography.bodyMedium,
                          items: List.generate(7, (i) {
                            final day = i + 1;
                            return DropdownMenuItem(
                              value: day,
                              child: Text(_dayName(day)),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              notifier.setWeeklySpendingSummaryDay(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }
}
