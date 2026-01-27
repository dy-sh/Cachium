import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../date_picker/date_picker_icon_button.dart';
import '../date_picker/date_picker_navigation_button.dart';
import '../date_picker/calendar_grid.dart';
import '../date_picker/month_year_picker.dart';

/// A date range picker modal derived from the single DatePickerModal.
///
/// Users tap to select a start date, then an end date. The range is
/// highlighted on the calendar.
class DateRangePickerModal extends ConsumerStatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const DateRangePickerModal({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.initialStart,
    this.initialEnd,
  });

  @override
  ConsumerState<DateRangePickerModal> createState() =>
      _DateRangePickerModalState();
}

class _DateRangePickerModalState extends ConsumerState<DateRangePickerModal> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _displayedMonth;
  late PageController _pageController;
  bool _showMonthYearPicker = false;

  bool get _isSelectingEnd => _startDate != null && _endDate == null;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStart;
    _endDate = widget.initialEnd;
    final initial = _startDate ?? DateTime.now();
    _displayedMonth = DateTime(initial.year, initial.month, 1);

    final monthsSinceStart =
        (_displayedMonth.year - widget.firstDate.year) * 12 +
            (_displayedMonth.month - widget.firstDate.month);
    _pageController = PageController(initialPage: monthsSinceStart);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageIndex) {
    final newMonth = DateTime(
      widget.firstDate.year +
          (pageIndex + widget.firstDate.month - 1) ~/ 12,
      (pageIndex + widget.firstDate.month - 1) % 12 + 1,
      1,
    );
    setState(() => _displayedMonth = newMonth);
  }

  void _goToPreviousMonth() {
    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage > 0) {
        _pageController.animateToPage(
          currentPage - 1,
          duration: AppAnimations.slow,
          curve: AppAnimations.defaultCurve,
        );
        HapticHelper.lightImpact();
      }
    }
  }

  void _goToNextMonth() {
    if (_pageController.hasClients) {
      final totalMonths =
          (widget.lastDate.year - widget.firstDate.year) * 12 +
              (widget.lastDate.month - widget.firstDate.month);
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage < totalMonths) {
        _pageController.animateToPage(
          currentPage + 1,
          duration: AppAnimations.slow,
          curve: AppAnimations.defaultCurve,
        );
        HapticHelper.lightImpact();
      }
    }
  }

  void _selectDate(DateTime date) {
    if (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate)) {
      return;
    }

    setState(() {
      if (_startDate == null || _endDate != null) {
        // Start fresh selection
        _startDate = date;
        _endDate = null;
      } else {
        // Selecting end date
        if (date.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
      }
    });
    HapticHelper.mediumImpact();
  }

  void _selectMonthYear(int year, int month) {
    final monthsSinceStart = (year - widget.firstDate.year) * 12 +
        (month - widget.firstDate.month);

    setState(() {
      _displayedMonth = DateTime(year, month, 1);
      _showMonthYearPicker = false;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(monthsSinceStart);
    }

    HapticHelper.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              const SizedBox(height: AppSpacing.lg),
              _buildHeader(accentColor),
              const SizedBox(height: AppSpacing.sm),
              _buildRangeLabel(),
              const SizedBox(height: AppSpacing.lg),
              if (_showMonthYearPicker)
                MonthYearPicker(
                  displayedMonth: _displayedMonth,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onMonthYearSelected: _selectMonthYear,
                )
              else
                _buildCalendar(accentColor),
              const SizedBox(height: AppSpacing.lg),
              _buildConfirmButton(accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isSelectingEnd ? 'Select End Date' : 'Select Start Date',
          style: AppTypography.h3,
        ),
        Row(
          children: [
            if (_startDate != null && _endDate == null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  HapticHelper.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Reset',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            if (_startDate != null && _endDate == null)
              const SizedBox(width: AppSpacing.sm),
            DatePickerIconButton(
              icon: LucideIcons.x,
              accentColor: accentColor,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeLabel() {
    final fmt = DateFormat('MMM d, yyyy');
    String label;
    if (_startDate != null && _endDate != null) {
      label = '${fmt.format(_startDate!)} — ${fmt.format(_endDate!)}';
    } else if (_startDate != null) {
      label = '${fmt.format(_startDate!)} — ...';
    } else {
      label = 'Tap a date to begin';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCalendar(Color accentColor) {
    return Column(
      children: [
        _buildCalendarHeader(accentColor),
        const SizedBox(height: AppSpacing.md),
        const WeekDayLabels(),
        const SizedBox(height: AppSpacing.sm),
        _buildCalendarPageView(accentColor),
      ],
    );
  }

  Widget _buildCalendarHeader(Color accentColor) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DatePickerNavigationButton(
          icon: LucideIcons.chevronLeft,
          onTap: _goToPreviousMonth,
        ),
        GestureDetector(
          onTap: () {
            setState(() => _showMonthYearPicker = !_showMonthYearPicker);
            HapticHelper.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _showMonthYearPicker ? accentColor : AppColors.background,
              borderRadius: AppRadius.smAll,
              border: Border.all(
                color: _showMonthYearPicker ? accentColor : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: AppTypography.labelLarge.copyWith(
                    color: _showMonthYearPicker
                        ? AppColors.background
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  _showMonthYearPicker
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 16,
                  color: _showMonthYearPicker
                      ? AppColors.background
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        DatePickerNavigationButton(
          icon: LucideIcons.chevronRight,
          onTap: _goToNextMonth,
        ),
      ],
    );
  }

  Widget _buildCalendarPageView(Color accentColor) {
    final totalMonths =
        (widget.lastDate.year - widget.firstDate.year) * 12 +
            (widget.lastDate.month - widget.firstDate.month) +
            1;

    return SizedBox(
      height: AppSpacing.calendarGridHeight,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: totalMonths,
        itemBuilder: (context, index) {
          final month = DateTime(
            widget.firstDate.year +
                (index + widget.firstDate.month - 1) ~/ 12,
            (index + widget.firstDate.month - 1) % 12 + 1,
            1,
          );
          return _RangeCalendarGrid(
            month: month,
            startDate: _startDate,
            endDate: _endDate,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            accentColor: accentColor,
            onDateSelected: _selectDate,
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton(Color accentColor) {
    final canConfirm = _startDate != null && _endDate != null;

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          if (_showMonthYearPicker) {
            setState(() => _showMonthYearPicker = false);
            return;
          }
          if (!canConfirm) return;
          HapticHelper.mediumImpact();
          Navigator.pop(
            context,
            DateTimeRange(start: _startDate!, end: _endDate!),
          );
        },
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          height: AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            color: canConfirm || _showMonthYearPicker
                ? accentColor
                : accentColor.withValues(alpha: 0.3),
            borderRadius: AppRadius.button,
          ),
          child: Center(
            child: Text(
              _showMonthYearPicker
                  ? 'Select'
                  : canConfirm
                      ? 'Confirm'
                      : _isSelectingEnd
                          ? 'Select end date'
                          : 'Select start date',
              style: AppTypography.button.copyWith(
                color: canConfirm || _showMonthYearPicker
                    ? AppColors.background
                    : AppColors.background.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Calendar grid with range highlighting.
class _RangeCalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color accentColor;
  final ValueChanged<DateTime> onDateSelected;

  const _RangeCalendarGrid({
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.firstDate,
    required this.lastDate,
    required this.accentColor,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final List<Widget> allCells = [];

    for (int i = 0; i < startingWeekday; i++) {
      allCells.add(const SizedBox(
        width: AppSpacing.calendarDayCellSize,
        height: AppSpacing.calendarDayCellSize,
      ));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isDisabled = date.isBefore(firstDate) || date.isAfter(lastDate);
      final isStart =
          startDate != null && DateFormatter.isSameDay(date, startDate!);
      final isEnd =
          endDate != null && DateFormatter.isSameDay(date, endDate!);
      final isInRange = startDate != null &&
          endDate != null &&
          date.isAfter(startDate!) &&
          date.isBefore(endDate!);
      final isToday = DateFormatter.isSameDay(date, DateTime.now());

      allCells.add(
        _RangeDayCell(
          day: day,
          isStart: isStart,
          isEnd: isEnd,
          isInRange: isInRange,
          isToday: isToday,
          isDisabled: isDisabled,
          accentColor: accentColor,
          onTap: () => onDateSelected(date),
        ),
      );
    }

    while (allCells.length < AppSpacing.calendarGridCellCount) {
      allCells.add(const SizedBox(
        width: AppSpacing.calendarDayCellSize,
        height: AppSpacing.calendarDayCellSize,
      ));
    }

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

class _RangeDayCell extends StatelessWidget {
  final int day;
  final bool isStart;
  final bool isEnd;
  final bool isInRange;
  final bool isToday;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _RangeDayCell({
    required this.day,
    required this.isStart,
    required this.isEnd,
    required this.isInRange,
    required this.isToday,
    required this.isDisabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = isStart || isEnd;
    final textColor = isDisabled
        ? AppColors.textTertiary.withValues(alpha: 0.5)
        : isSelected
            ? AppColors.background
            : isInRange
                ? accentColor
                : isToday
                    ? accentColor
                    : AppColors.textPrimary;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: AppSpacing.calendarDayCellSize,
        height: AppSpacing.calendarDayCellSize,
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor
              : isInRange
                  ? accentColor.withValues(alpha: 0.1)
                  : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !isSelected && !isInRange
              ? Border.all(color: accentColor, width: 1)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: AppTypography.labelMedium.copyWith(
              color: textColor,
              fontWeight: isSelected || isToday || isInRange
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
