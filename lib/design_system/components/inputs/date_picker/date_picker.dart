import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import 'date_picker_modal.dart';

export 'calendar_grid.dart';
export 'date_picker_modal.dart';
export 'day_cell.dart';
export 'month_year_picker.dart';

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
  final animationsEnabled = container.read(formAnimationsEnabledProvider);

  if (!animationsEnabled) {
    return Navigator.of(context).push<DateTime>(
      PageRouteBuilder<DateTime>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: DatePickerModal(
                initialDate: initialDate,
                firstDate: firstDate ?? DateTime(2000),
                lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
              ),
            ),
          );
        },
      ),
    );
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DatePickerModal(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    ),
  );
}
