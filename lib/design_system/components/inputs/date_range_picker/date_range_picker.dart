import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import 'date_range_picker_modal.dart';

export 'date_range_picker_modal.dart';

/// Shows a custom modal date range picker.
///
/// Returns a [DateTimeRange] or null if dismissed.
Future<DateTimeRange?> showFMDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialStart,
  DateTime? initialEnd,
}) {
  final container = ProviderScope.containerOf(context);
  final animationsEnabled = container.read(formAnimationsEnabledProvider);

  if (!animationsEnabled) {
    return Navigator.of(context).push<DateTimeRange>(
      PageRouteBuilder<DateTimeRange>(
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
              child: DateRangePickerModal(
                firstDate: firstDate,
                lastDate: lastDate,
                initialStart: initialStart,
                initialEnd: initialEnd,
              ),
            ),
          );
        },
      ),
    );
  }

  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DateRangePickerModal(
      firstDate: firstDate,
      lastDate: lastDate,
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}
