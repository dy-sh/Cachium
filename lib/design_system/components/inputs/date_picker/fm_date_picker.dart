import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
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
  final container = ProviderScope.containerOf(context);
  final animationsEnabled = container.read(settingsProvider).formAnimationsEnabled;

  if (!animationsEnabled) {
    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: FMDatePickerModal(
              initialDate: initialDate,
              firstDate: firstDate ?? DateTime(2000),
              lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
            ),
          ),
        );
      },
    );
  }

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
