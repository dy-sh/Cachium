import 'package:flutter/material.dart';
import 'fm_date_picker_modal.dart';

export 'fm_calendar_grid.dart';
export 'fm_date_picker_modal.dart';
export 'fm_day_cell.dart';
export 'fm_month_year_picker.dart';

/// Shows a custom modal date picker.
///
/// Returns the selected [DateTime] or null if dismissed.
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
    builder: (context) => FMDatePickerModal(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    ),
  );
}
