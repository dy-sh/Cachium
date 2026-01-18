import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import 'fm_calendar_grid.dart';
import 'fm_month_year_picker.dart';

/// The main date picker modal widget.
class FMDatePickerModal extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const FMDatePickerModal({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  ConsumerState<FMDatePickerModal> createState() => _FMDatePickerModalState();
}

class _FMDatePickerModalState extends ConsumerState<FMDatePickerModal> {
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
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _parseDateFromInput(String text) {
    final parts = text.split(RegExp(r'[/.\-]'));
    if (parts.length == 3) {
      try {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        if (month < 1 || month > 12) return null;
        if (day < 1 || day > 31) return null;
        if (year < 1900 || year > 2100) return null;

        final date = DateTime(year, month, day);
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
          duration: AppAnimations.slow,
          curve: AppAnimations.defaultCurve,
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
      _selectedDate = date;
      _textController.text = _formatDateForInput(date);
      _textError = null;
    });
    HapticHelper.mediumImpact();
  }

  void _selectMonthYear(int year, int month) {
    final monthsSinceStart = (year - widget.firstDate.year) * 12 +
        (month - widget.firstDate.month);

    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final newDay = _selectedDate.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : _selectedDate.day;
    final newDate = DateTime(year, month, newDay);

    setState(() {
      _displayedMonth = DateTime(year, month, 1);
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
              const SizedBox(height: AppSpacing.lg),
              if (_showTextInput) ...[
                _buildTextInput(accentColor),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (_showMonthYearPicker)
                FMMonthYearPicker(
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
        Text('Select Date', style: AppTypography.h3),
        if (_showMonthYearPicker)
          _DatePickerIconButton(
            icon: LucideIcons.x,
            accentColor: accentColor,
            onTap: () {
              setState(() => _showMonthYearPicker = false);
              HapticHelper.lightImpact();
            },
          )
        else
          Row(
            children: [
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
              _DatePickerIconButton(
                icon: LucideIcons.keyboard,
                isActive: _showTextInput,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _showTextInput = !_showTextInput;
                    if (_showTextInput) _showMonthYearPicker = false;
                  });
                  HapticHelper.lightImpact();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _DatePickerIconButton(
                icon: LucideIcons.x,
                accentColor: accentColor,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTextInput(Color accentColor) {
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
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onTextSubmitted(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9/.\-]')),
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              hintText: 'MM/DD/YYYY',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.check, size: 20),
                color: AppColors.textSecondary,
                onPressed: _onTextSubmitted,
              ),
            ),
            cursorColor: accentColor,
          ),
        ),
        if (_textError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _textError!,
            style: AppTypography.labelSmall.copyWith(color: AppColors.expense),
          ),
        ],
      ],
    );
  }

  Widget _buildCalendar(Color accentColor) {
    return Column(
      children: [
        _buildCalendarHeader(accentColor),
        const SizedBox(height: AppSpacing.md),
        const FMWeekDayLabels(),
        const SizedBox(height: AppSpacing.sm),
        _buildCalendarPageView(),
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
        _DatePickerNavigationButton(
          icon: LucideIcons.chevronLeft,
          onTap: _goToPreviousMonth,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _showMonthYearPicker = !_showMonthYearPicker;
              if (_showMonthYearPicker) _showTextInput = false;
            });
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
        _DatePickerNavigationButton(
          icon: LucideIcons.chevronRight,
          onTap: _goToNextMonth,
        ),
      ],
    );
  }

  Widget _buildCalendarPageView() {
    final totalMonths = (widget.lastDate.year - widget.firstDate.year) * 12 +
        (widget.lastDate.month - widget.firstDate.month) + 1;

    return SizedBox(
      height: AppSpacing.calendarGridHeight,
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
          return FMCalendarGrid(
            month: month,
            selectedDate: _selectedDate,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onDateSelected: _selectDate,
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton(Color accentColor) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          HapticHelper.mediumImpact();
          if (_showMonthYearPicker) {
            setState(() => _showMonthYearPicker = false);
          } else {
            Navigator.pop(context, _selectedDate);
          }
        },
        child: Container(
          height: AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: AppRadius.button,
          ),
          child: Center(
            child: Text(
              _showMonthYearPicker ? 'Select' : 'Confirm',
              style: AppTypography.button.copyWith(color: AppColors.background),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon button used in the date picker header.
class _DatePickerIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color accentColor;

  const _DatePickerIconButton({
    required this.icon,
    required this.onTap,
    required this.accentColor,
    this.isActive = false,
  });

  @override
  State<_DatePickerIconButton> createState() => _DatePickerIconButtonState();
}

class _DatePickerIconButtonState extends State<_DatePickerIconButton> {
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
        duration: AppAnimations.fast,
        width: AppSpacing.calendarHeaderButtonSize,
        height: AppSpacing.calendarHeaderButtonSize,
        decoration: BoxDecoration(
          color: widget.isActive
              ? widget.accentColor
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

/// Navigation button for calendar month navigation.
class _DatePickerNavigationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DatePickerNavigationButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_DatePickerNavigationButton> createState() => _DatePickerNavigationButtonState();
}

class _DatePickerNavigationButtonState extends State<_DatePickerNavigationButton> {
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
        duration: AppAnimations.fast,
        width: AppSpacing.calendarHeaderButtonSize,
        height: AppSpacing.calendarHeaderButtonSize,
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
