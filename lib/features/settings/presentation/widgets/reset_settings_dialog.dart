import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/feedback/confirmation_dialog.dart';

Future<bool?> showResetSettingsDialog({
  required BuildContext context,
}) async {
  final result = await showConfirmationDialog(
    context: context,
    title: 'Reset Settings?',
    message:
        'This will reset all appearance, format, preference, and transaction settings to their default values. Your data (accounts, transactions, categories) will not be affected.',
    confirmLabel: 'Reset',
    isDestructive: true,
    icon: LucideIcons.rotateCcw,
  );
  return result;
}
