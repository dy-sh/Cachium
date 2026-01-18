import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import 'fm_day_cell.dart';

/// Builds a month grid for the calendar.
class FMCalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  const FMCalendarGrid({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  bool _isToday(DateTime date) {
    return DateFormatter.isSameDay(date, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final List<Widget> allCells = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday; i++) {
      allCells.add(const SizedBox(
        width: AppSpacing.calendarDayCellSize,
        height: AppSpacing.calendarDayCellSize,
      ));
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = DateFormatter.isSameDay(date, selectedDate);
      final isToday = _isToday(date);
      final isDisabled = date.isBefore(firstDate) || date.isAfter(lastDate);

      allCells.add(
        FMDayCell(
          day: day,
          isSelected: isSelected,
          isToday: isToday,
          isDisabled: isDisabled,
          onTap: () => onDateSelected(date),
        ),
      );
    }

    // Fill remaining cells to make exactly 42 cells (6 rows * 7 days)
    while (allCells.length < AppSpacing.calendarGridCellCount) {
      allCells.add(const SizedBox(
        width: AppSpacing.calendarDayCellSize,
        height: AppSpacing.calendarDayCellSize,
      ));
    }

    // Build 6 rows
    final rows = <Widget>[];
    for (int i = 0; i < 6; i++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: allCells.sublist(i * 7, (i + 1) * 7),
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

/// Week day labels row for the calendar.
class FMWeekDayLabels extends StatelessWidget {
  const FMWeekDayLabels({super.key});

  static const _weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _weekDays.map((day) {
        return SizedBox(
          width: AppSpacing.calendarDayCellSize,
          child: Center(
            child: Text(
              day,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
