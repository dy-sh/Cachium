import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/feedback/confirmation_dialog.dart';

/// Result of the delete database dialog.
class DeleteDatabaseResult {
  final bool confirmed;
  final bool resetSettings;

  const DeleteDatabaseResult({
    required this.confirmed,
    required this.resetSettings,
  });
}

Future<DeleteDatabaseResult?> showDeleteDatabaseDialog({
  required BuildContext context,
}) async {
  final result = await showConfirmationDialogWithCheckbox(
    context: context,
    title: 'Delete All Data?',
    message:
        'This will permanently delete all transactions, accounts, and categories. This action cannot be undone.',
    confirmLabel: 'Delete',
    isDestructive: true,
    icon: LucideIcons.alertTriangle,
    checkboxLabel: 'Also reset app settings',
  );
  return DeleteDatabaseResult(
    confirmed: result.confirmed,
    resetSettings: result.checkboxValue,
  );
}
