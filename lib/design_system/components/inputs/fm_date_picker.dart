import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/animations/haptic_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Shows a custom modal date picker
Future<DateTime?> showFMDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _FMDatePickerModal(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    ),
  );
}

class _FMDatePickerModal extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _FMDatePickerModal({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_FMDatePickerModal> createState() => _FMDatePickerModalState();
}

class _FMDatePickerModalState extends State<_FMDatePickerModal> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late TextEditingController _textController;
  late PageController _pageController;
  bool _showMonthYearPicker = false;
  bool _showTextInput = false;
  String? _textError;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _textController = TextEditingController(
      text: _formatDateForInput(_selectedDate),
    );

    // Calculate initial page index (months since firstDate)
    final monthsSinceStart = (_displayedMonth.year - widget.firstDate.year) * 12 +
        (_displayedMonth.month - widget.firstDate.month);
    _pageController = PageController(initialPage: monthsSinceStart);
  }

  @override
  void dispose() {
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatDateForInput(DateTime date) {
    // MM/DD/YYYY format (US regional)
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _parseDateFromInput(String text) {
    // Try parsing MM/DD/YYYY format
    final parts = text.split(RegExp(r'[/.\-]'));
    if (parts.length == 3) {
      try {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        // Validate ranges
        if (month < 1 || month > 12) return null;
        if (day < 1 || day > 31) return null;
        if (year < 1900 || year > 2100) return null;

        final date = DateTime(year, month, day);

        // Verify the date is valid (e.g., not Feb 30)
        if (date.month != month || date.day != day) return null;

        return date;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void _onPageChanged(int pageIndex) {
    final newMonth = DateTime(
      widget.firstDate.year + (pageIndex + widget.firstDate.month - 1) ~/ 12,
      (pageIndex + widget.firstDate.month - 1) % 12 + 1,
      1,
    );
    setState(() {
      _displayedMonth = newMonth;
    });
  }

  void _goToPreviousMonth() {
    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage > 0) {
        _pageController.animateToPage(
          currentPage - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        HapticHelper.lightImpact();
      }
    }
  }

  void _goToNextMonth() {
    if (_pageController.hasClients) {
      final totalMonths = (widget.lastDate.year - widget.firstDate.year) * 12 +
          (widget.lastDate.month - widget.firstDate.month);
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage < totalMonths) {
        _pageController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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
      _selectedDate = date;
      _textController.text = _formatDateForInput(date);
      _textError = null;
    });
    HapticHelper.mediumImpact();
  }

  void _selectMonthYear(int year, int month) {
    final targetMonth = DateTime(year, month, 1);
    final monthsSinceStart = (year - widget.firstDate.year) * 12 +
        (month - widget.firstDate.month);

    // Keep the same day, but adjust if it doesn't exist in the new month
    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final newDay = _selectedDate.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : _selectedDate.day;
    final newDate = DateTime(year, month, newDay);

    setState(() {
      _displayedMonth = targetMonth;
      _selectedDate = newDate;
      _textController.text = _formatDateForInput(newDate);
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(monthsSinceStart);
    }

    HapticHelper.lightImpact();
  }

  void _onTextSubmitted() {
    final parsed = _parseDateFromInput(_textController.text);
    if (parsed != null) {
      if (parsed.isBefore(widget.firstDate) || parsed.isAfter(widget.lastDate)) {
        setState(() {
          _textError = 'Date out of range';
        });
      } else {
        final monthsSinceStart = (parsed.year - widget.firstDate.year) * 12 +
            (parsed.month - widget.firstDate.month);

        setState(() {
          _selectedDate = parsed;
          _displayedMonth = DateTime(parsed.year, parsed.month, 1);
          _textError = null;
          _showTextInput = false;
        });

        // Jump to the selected month after setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients && mounted) {
            _pageController.jumpToPage(monthsSinceStart);
          }
        });

        HapticHelper.mediumImpact();
      }
    } else {
      setState(() {
        _textError = 'Invalid date format (MM/DD/YYYY)';
      });
    }
  }

  void _selectToday() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (todayDate.isBefore(widget.firstDate) || todayDate.isAfter(widget.lastDate)) {
      return;
    }

    final monthsSinceStart = (todayDate.year - widget.firstDate.year) * 12 +
        (todayDate.month - widget.firstDate.month);

    setState(() {
      _selectedDate = todayDate;
      _displayedMonth = DateTime(todayDate.year, todayDate.month, 1);
      _textController.text = _formatDateForInput(todayDate);
      _textError = null;
      _showTextInput = false;
      _showMonthYearPicker = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && mounted) {
        _pageController.jumpToPage(monthsSinceStart);
      }
    });

    HapticHelper.mediumImpact();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header with title and action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date',
                    style: AppTypography.h3,
                  ),
                  // Show different buttons based on mode
                  if (_showMonthYearPicker)
                    _IconButton(
                      icon: LucideIcons.x,
                      onTap: () {
                        setState(() {
                          _showMonthYearPicker = false;
                        });
                        HapticHelper.lightImpact();
                      },
                    )
                  else
                    Row(
                      children: [
                        // Today button
                        GestureDetector(
                          onTap: _selectToday,
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
                              'Today',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _IconButton(
                          icon: LucideIcons.keyboard,
                          isActive: _showTextInput,
                          onTap: () {
                            setState(() {
                              _showTextInput = !_showTextInput;
                              if (_showTextInput) {
                                _showMonthYearPicker = false;
                              }
                            });
                            HapticHelper.lightImpact();
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _IconButton(
                          icon: LucideIcons.x,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Text input mode
              if (_showTextInput) ...[
                _buildTextInput(),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Month/Year picker or Calendar
              if (_showMonthYearPicker)
                _buildMonthYearPicker()
              else
                _buildCalendar(),

              const SizedBox(height: AppSpacing.lg),

              // Bottom action button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    HapticHelper.mediumImpact();
                    if (_showMonthYearPicker) {
                      // Just close the month/year picker, go back to calendar
                      setState(() {
                        _showMonthYearPicker = false;
                      });
                    } else {
                      // Confirm and close the modal
                      Navigator.pop(context, _selectedDate);
                    }
                  },
                  child: Container(
                    height: AppSpacing.buttonHeight,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: AppRadius.button,
                    ),
                    child: Center(
                      child: Text(
                        _showMonthYearPicker ? 'Select' : 'Confirm',
                        style: AppTypography.button.copyWith(
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: _textError != null ? AppColors.expense : AppColors.border,
            ),
          ),
          child: TextField(
            controller: _textController,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onTextSubmitted(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9/.\-]')),
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              hintText: 'MM/DD/YYYY',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.check, size: 20),
                color: AppColors.textSecondary,
                onPressed: _onTextSubmitted,
              ),
            ),
            cursorColor: AppColors.accentPrimary,
          ),
        ),
        if (_textError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _textError!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.expense,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        _buildCalendarHeader(),
        const SizedBox(height: AppSpacing.md),
        _buildWeekDayLabels(),
        const SizedBox(height: AppSpacing.sm),
        _buildCalendarPageView(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavigationButton(
          icon: LucideIcons.chevronLeft,
          onTap: _goToPreviousMonth,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _showMonthYearPicker = !_showMonthYearPicker;
              if (_showMonthYearPicker) {
                _showTextInput = false;
              }
            });
            HapticHelper.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _showMonthYearPicker ? AppColors.accentPrimary : AppColors.background,
              borderRadius: AppRadius.smAll,
              border: Border.all(
                color: _showMonthYearPicker ? AppColors.accentPrimary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: AppTypography.labelLarge.copyWith(
                    color: _showMonthYearPicker ? AppColors.background : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  _showMonthYearPicker ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: _showMonthYearPicker ? AppColors.background : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        _NavigationButton(
          icon: LucideIcons.chevronRight,
          onTap: _goToNextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekDayLabels() {
    const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        return SizedBox(
          width: 40,
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

  Widget _buildCalendarPageView() {
    final totalMonths = (widget.lastDate.year - widget.firstDate.year) * 12 +
        (widget.lastDate.month - widget.firstDate.month) + 1;

    return SizedBox(
      height: 264, // Fixed height: 6 rows * (40px height + 4px spacing)
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: totalMonths,
        itemBuilder: (context, index) {
          final month = DateTime(
            widget.firstDate.year + (index + widget.firstDate.month - 1) ~/ 12,
            (index + widget.firstDate.month - 1) % 12 + 1,
            1,
          );
          return _buildMonthGrid(month);
        },
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final List<Widget> allCells = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday; i++) {
      allCells.add(const SizedBox(width: 40, height: 40));
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = _isSameDay(date, _selectedDate);
      final isToday = _isToday(date);
      final isDisabled = date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);

      allCells.add(
        _DayCell(
          day: day,
          isSelected: isSelected,
          isToday: isToday,
          isDisabled: isDisabled,
          onTap: () => _selectDate(date),
        ),
      );
    }

    // Fill remaining cells to make exactly 42 cells (6 rows * 7 days)
    while (allCells.length < 42) {
      allCells.add(const SizedBox(width: 40, height: 40));
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

    return Column(
      children: rows,
    );
  }

  Widget _buildMonthYearPicker() {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          // Month picker
          Expanded(
            child: _buildMonthList(),
          ),
          const SizedBox(width: AppSpacing.md),
          // Year picker
          Expanded(
            child: _YearListWidget(
              displayedMonth: _displayedMonth,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onYearSelected: (year) => _selectMonthYear(year, _displayedMonth.month),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthList() {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return ListView.builder(
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelected = month == _displayedMonth.month;

        return GestureDetector(
          onTap: () => _selectMonthYear(_displayedMonth.year, month),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentPrimary : Colors.transparent,
              borderRadius: AppRadius.smAll,
            ),
            child: Center(
              child: Text(
                monthNames[index],
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

class _YearListWidget extends StatefulWidget {
  final DateTime displayedMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<int> onYearSelected;

  const _YearListWidget({
    required this.displayedMonth,
    required this.firstDate,
    required this.lastDate,
    required this.onYearSelected,
  });

  @override
  State<_YearListWidget> createState() => _YearListWidgetState();
}

class _YearListWidgetState extends State<_YearListWidget> {
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
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentPrimary : Colors.transparent,
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

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _IconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppColors.accentPrimary
              : _isPressed
                  ? AppColors.surfaceLight
                  : AppColors.background,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: widget.isActive ? AppColors.background : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _NavigationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _isPressed ? AppColors.surfaceLight : AppColors.background,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDisabled
        ? AppColors.textTertiary.withOpacity(0.5)
        : widget.isSelected
            ? AppColors.background
            : widget.isToday
                ? AppColors.accentPrimary
                : AppColors.textPrimary;

    return GestureDetector(
      onTapDown: widget.isDisabled ? null : (_) => _controller.forward(),
      onTapUp: widget.isDisabled
          ? null
          : (_) {
              _controller.reverse();
              widget.onTap();
            },
      onTapCancel: widget.isDisabled ? null : () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isSelected ? AppColors.accentPrimary : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.accentPrimary.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
                border: widget.isToday && !widget.isSelected
                    ? Border.all(color: AppColors.accentPrimary, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${widget.day}',
                  style: AppTypography.labelMedium.copyWith(
                    color: textColor,
                    fontWeight: widget.isSelected || widget.isToday
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
