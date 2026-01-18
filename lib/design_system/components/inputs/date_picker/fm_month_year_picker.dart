import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';

/// Month and year selection picker used in the date picker modal.
class FMMonthYearPicker extends ConsumerWidget {
  final DateTime displayedMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final void Function(int year, int month) onMonthYearSelected;

  const FMMonthYearPicker({
    super.key,
    required this.displayedMonth,
    required this.firstDate,
    required this.lastDate,
    required this.onMonthYearSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);

    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            child: _MonthList(
              displayedMonth: displayedMonth,
              accentColor: accentColor,
              onMonthSelected: (month) => onMonthYearSelected(displayedMonth.year, month),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _YearList(
              displayedMonth: displayedMonth,
              firstDate: firstDate,
              lastDate: lastDate,
              accentColor: accentColor,
              onYearSelected: (year) => onMonthYearSelected(year, displayedMonth.month),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthList extends StatelessWidget {
  final DateTime displayedMonth;
  final Color accentColor;
  final ValueChanged<int> onMonthSelected;

  const _MonthList({
    required this.displayedMonth,
    required this.accentColor,
    required this.onMonthSelected,
  });

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == displayedMonth.month;

        return GestureDetector(
          onTap: () => onMonthSelected(month),
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.transparent,
              borderRadius: AppRadius.smAll,
            ),
            child: Center(
              child: Text(
                _monthNames[index],
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.background : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _YearList extends StatefulWidget {
  final DateTime displayedMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color accentColor;
  final ValueChanged<int> onYearSelected;

  const _YearList({
    required this.displayedMonth,
    required this.firstDate,
    required this.lastDate,
    required this.accentColor,
    required this.onYearSelected,
  });

  @override
  State<_YearList> createState() => _YearListState();
}

class _YearListState extends State<_YearList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _initializeScrollController();
  }

  void _initializeScrollController() {
    final startYear = widget.firstDate.year;
    final endYear = widget.lastDate.year;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);
    final selectedYearIndex = years.indexOf(widget.displayedMonth.year);

    _scrollController = ScrollController(
      initialScrollOffset: selectedYearIndex > 0 ? (selectedYearIndex - 2) * 40.0 : 0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startYear = widget.firstDate.year;
    final endYear = widget.lastDate.year;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    return ListView.builder(
      controller: _scrollController,
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final isSelected = year == widget.displayedMonth.year;

        return GestureDetector(
          onTap: () => widget.onYearSelected(year),
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? widget.accentColor : Colors.transparent,
              borderRadius: AppRadius.smAll,
            ),
            child: Center(
              child: Text(
                '$year',
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? AppColors.background : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
