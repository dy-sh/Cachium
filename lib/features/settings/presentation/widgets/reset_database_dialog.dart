import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/feedback/confirmation_dialog.dart';

class ResetDatabaseResult {
  final bool confirmed;
  final bool resetSettings;

  const ResetDatabaseResult({
    required this.confirmed,
    required this.resetSettings,
  });
}

Future<ResetDatabaseResult?> showResetDatabaseDialog({
  required BuildContext context,
}) async {
  final result = await showConfirmationDialogWithCheckbox(
    context: context,
    title: 'Reset Database?',
    message:
        'This will permanently delete all transactions, accounts, and categories. You will be returned to the setup screen to start fresh.',
    confirmLabel: 'Reset',
    isDestructive: true,
    icon: LucideIcons.alertTriangle,
    checkboxLabel: 'Also reset app settings',
  );
  return ResetDatabaseResult(
    confirmed: result.confirmed,
    resetSettings: result.checkboxValue,
  );
}
