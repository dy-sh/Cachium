import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../design_system/components/buttons/circular_button.dart';
import '../../../../design_system/components/layout/settings_header.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../navigation/app_router.dart';
import '../../../transactions/data/models/transaction.dart';
import '../providers/calendar_screen_provider.dart';

class FinancialCalendarScreen extends ConsumerWidget {
  const FinancialCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayMonth = ref.watch(calendarScreenDisplayMonthProvider);
    final calendarData = ref.watch(calendarScreenDataProvider);
    final selectedDay = ref.watch(calendarScreenSelectedDayProvider);
    final dayTransactions = ref.watch(calendarDayTransactionsProvider);
    final billDates = ref.watch(calendarBillDatesProvider);
    final firstDayOfWeek = ref.watch(firstDayOfWeekProvider);
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);

    final monthLabel = DateFormat('MMMM yyyy').format(displayMonth);
    final today = DateTime.now();

    // Build calendar grid
    final firstOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastOfMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    final startWeekday = firstOfMonth.weekday; // 1=Monday, 7=Sunday

    // Calculate offset based on first day of week setting
    final isMondayFirst = firstDayOfWeek == FirstDayOfWeek.monday;
    final offset = isMondayFirst
        ? (startWeekday - 1) % 7
        : startWeekday % 7;

    final dayLabels = isMondayFirst
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    // Map calendar data by day
    final dataByDay = <int, _DayCellData>{};
    for (final d in calendarData) {
      dataByDay[d.date.day] = _DayCellData(
        income: d.income,
        expense: d.expense,
        net: d.net,
        intensity: d.intensity,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SettingsHeader(title: 'Calendar'),

            // Month navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircularButton(
                    onTap: () => ref.read(calendarScreenMonthOffsetProvider.notifier).state--,
                    icon: LucideIcons.chevronLeft,
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(calendarScreenMonthOffsetProvider.notifier).state = 0;
                    },
                    child: Text(monthLabel, style: AppTypography.h4),
                  ),
                  CircularButton(
                    onTap: () => ref.read(calendarScreenMonthOffsetProvider.notifier).state++,
                    icon: LucideIcons.chevronRight,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Day of week headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: dayLabels.map((label) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Calendar grid
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _CalendarGrid(
                  key: ValueKey(displayMonth),
                  offset: offset,
                  daysInMonth: lastOfMonth.day,
                  dataByDay: dataByDay,
                  billDates: billDates,
                  displayMonth: displayMonth,
                  today: today,
                  selectedDay: selectedDay,
                  mainCurrency: mainCurrency,
                  onDayTap: (day) {
                    final tapped = DateTime(displayMonth.year, displayMonth.month, day);
                    final current = ref.read(calendarScreenSelectedDayProvider);
                    if (current?.day == day &&
                        current?.month == displayMonth.month &&
                        current?.year == displayMonth.year) {
                      ref.read(calendarScreenSelectedDayProvider.notifier).state = null;
                    } else {
                      ref.read(calendarScreenSelectedDayProvider.notifier).state = tapped;
                    }
                  },
                ),
              ),
            ),

            // Selected day detail
            if (selectedDay != null &&
                selectedDay.month == displayMonth.month &&
                selectedDay.year == displayMonth.year)
              _DayDetail(
                selectedDay: selectedDay,
                transactions: dayTransactions,
                mainCurrency: mainCurrency,
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCellData {
  final double income;
  final double expense;
  final double net;
  final int intensity;

  const _DayCellData({
    required this.income,
    required this.expense,
    required this.net,
    required this.intensity,
  });
}

class _CalendarGrid extends StatelessWidget {
  final int offset;
  final int daysInMonth;
  final Map<int, _DayCellData> dataByDay;
  final Set<String> billDates;
  final DateTime displayMonth;
  final DateTime today;
  final DateTime? selectedDay;
  final String mainCurrency;
  final void Function(int day) onDayTap;

  const _CalendarGrid({
    super.key,
    required this.offset,
    required this.daysInMonth,
    required this.dataByDay,
    required this.billDates,
    required this.displayMonth,
    required this.today,
    required this.selectedDay,
    required this.mainCurrency,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: List.generate(rows, (row) {
          return Expanded(
            child: Row(
              children: List.generate(7, (col) {
                final index = row * 7 + col;
                final day = index - offset + 1;

                if (day < 1 || day > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final data = dataByDay[day];
                final isToday = today.year == displayMonth.year &&
                    today.month == displayMonth.month &&
                    today.day == day;
                final isSelected = selectedDay?.year == displayMonth.year &&
                    selectedDay?.month == displayMonth.month &&
                    selectedDay?.day == day;
                final billKey = '${displayMonth.year}-${displayMonth.month}-$day';
                final hasBill = billDates.contains(billKey);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(day),
                    child: _DayCell(
                      day: day,
                      data: data,
                      isToday: isToday,
                      isSelected: isSelected,
                      hasBill: hasBill,
                      mainCurrency: mainCurrency,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final _DayCellData? data;
  final bool isToday;
  final bool isSelected;
  final bool hasBill;
  final String mainCurrency;

  const _DayCell({
    required this.day,
    required this.data,
    required this.isToday,
    required this.isSelected,
    required this.hasBill,
    required this.mainCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = data != null && (data!.income > 0 || data!.expense > 0);

    Color? bgColor;
    if (isSelected) {
      bgColor = AppColors.accentPrimary.withValues(alpha: 0.15);
    } else if (hasData) {
      final intensity = data!.intensity;
      final isPositive = data!.net >= 0;
      final baseColor = isPositive ? AppColors.income : AppColors.expense;
      bgColor = baseColor.withValues(alpha: 0.05 + intensity * 0.04);
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppColors.accentPrimary, width: 1.5)
            : isSelected
                ? Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.5), width: 1)
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: AppTypography.labelSmall.copyWith(
                    color: isToday ? AppColors.accentPrimary : AppColors.textPrimary,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (hasBill)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasData) ...[
              if (data!.income > 0)
                Text(
                  CurrencyFormatter.formatCompact(data!.income, currencyCode: mainCurrency),
                  style: TextStyle(
                    fontSize: 8,
                    color: AppColors.income,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (data!.expense > 0)
                Text(
                  CurrencyFormatter.formatCompact(data!.expense, currencyCode: mainCurrency),
                  style: TextStyle(
                    fontSize: 8,
                    color: AppColors.expense,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayDetail extends ConsumerWidget {
  final DateTime selectedDay;
  final List<Transaction> transactions;
  final String mainCurrency;

  const _DayDetail({
    required this.selectedDay,
    required this.transactions,
    required this.mainCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(selectedDay),
                  style: AppTypography.labelLarge,
                ),
                Row(
                  children: [
                    if (totalIncome > 0)
                      Text(
                        '+${CurrencyFormatter.formatSimple(totalIncome, currencyCode: mainCurrency)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.income,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (totalIncome > 0 && totalExpense > 0)
                      const SizedBox(width: AppSpacing.sm),
                    if (totalExpense > 0)
                      Text(
                        '-${CurrencyFormatter.formatSimple(totalExpense, currencyCode: mainCurrency)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Transaction list
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No transactions',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.md,
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
              ),
              child: Column(
                children: List.generate(transactions.length, (index) {
                  final tx = transactions[index];
                  return _TransactionTile(
                    transaction: tx,
                    mainCurrency: mainCurrency,
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final String mainCurrency;

  const _TransactionTile({
    required this.transaction,
    required this.mainCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountByIdProvider(transaction.accountId));
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));

    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final sign = isIncome ? '+' : '-';

    return GestureDetector(
      onTap: () => context.push(AppRoutes.transactionDetailPath(transaction.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            if (category != null)
              Icon(category.icon, size: 16, color: AppColors.textSecondary),
            if (category != null) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchant ?? category?.name ?? 'Transaction',
                    style: AppTypography.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (account != null)
                    Text(
                      account.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '$sign${CurrencyFormatter.formatSimple(transaction.amount, currencyCode: transaction.currencyCode)}',
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
