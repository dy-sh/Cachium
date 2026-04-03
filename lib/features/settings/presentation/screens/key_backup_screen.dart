import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../design_system/design_system.dart';

class KeyBackupScreen extends ConsumerStatefulWidget {
  const KeyBackupScreen({super.key});

  @override
  ConsumerState<KeyBackupScreen> createState() => _KeyBackupScreenState();
}

class _KeyBackupScreenState extends ConsumerState<KeyBackupScreen> {
  String? _exportedKey;
  bool _isLoading = false;
  bool _keyRevealed = false;

  // Restore state
  final _restoreController = TextEditingController();
  String? _restoreError;
  bool _isRestoring = false;

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  Future<void> _exportKey() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(keyBackupServiceProvider);
      final key = await service.exportKeyAsBase64();
      if (mounted) {
        setState(() {
          _exportedKey = key;
          _keyRevealed = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        context.showErrorNotification('Failed to export key');
      }
    }
  }

  void _copyKey() {
    if (_exportedKey == null) return;
    Clipboard.setData(ClipboardData(text: _exportedKey!));
    context.showSuccessNotification('Key copied to clipboard');
  }

  Future<void> _restoreKey() async {
    final input = _restoreController.text.trim();
    if (input.isEmpty) {
      setState(() => _restoreError = 'Please paste your backup key');
      return;
    }

    final service = ref.read(keyBackupServiceProvider);
    if (!service.isValidKeyBackup(input)) {
      setState(() => _restoreError = 'Invalid key format. Must be a valid base64 string (32 bytes).');
      return;
    }

    // Check if it matches current key
    final matchesCurrent = await service.verifyBackupMatchesCurrent(input);
    if (matchesCurrent) {
      if (mounted) {
        setState(() => _restoreError = null);
        context.showInfoNotification('This key is already active');
      }
      return;
    }

    // Confirm before restoring
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Restore Encryption Key',
        message: 'This will replace your current encryption key. '
            'Only do this if your current key is lost or corrupted. '
            'If the new key is wrong, your data will be unreadable.',
        confirmLabel: 'Restore Key',
        isDestructive: true,
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      await service.restoreFromBase64(input);
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _restoreError = null;
          _restoreController.clear();
        });
        context.showSuccessNotification('Encryption key restored. Restart the app for changes to take effect.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRestoring = false;
          _restoreError = 'Failed to restore key: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SettingsHeader(title: 'Encryption Key'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                children: [
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.1),
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(
                        color: AppColors.expense.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.shieldAlert,
                          size: 18,
                          color: AppColors.expense,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Your encryption key protects all your financial data. '
                            'If you lose this key and your device, your data cannot be recovered. '
                            'Store the backup in a secure location.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Export section
                  Text(
                    'Export Key',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Copy your encryption key to store it safely.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_exportedKey == null)
                    PrimaryButton(
                      label: 'Show Encryption Key',
                      onPressed: _isLoading ? null : _exportKey,
                      isLoading: _isLoading,
                    )
                  else ...[
                    GestureDetector(
                      onTap: () => setState(() => _keyRevealed = !_keyRevealed),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _keyRevealed
                            ? SelectableText(
                                _exportedKey!,
                                style: AppTypography.moneySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(
                                    LucideIcons.eyeOff,
                                    size: 16,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Tap to reveal key',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SecondaryButton(
                      label: 'Copy to Clipboard',
                      onPressed: _copyKey,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),

                  // Restore section
                  Text(
                    'Restore Key',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Paste a previously backed up encryption key to restore access to encrypted data.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _restoreController,
                    style: AppTypography.moneySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Paste base64 key here...',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdAll,
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdAll,
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdAll,
                        borderSide: BorderSide(color: AppColors.textTertiary),
                      ),
                      errorText: _restoreError,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onChanged: (_) {
                      if (_restoreError != null) {
                        setState(() => _restoreError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DestructiveButton(
                    label: 'Restore Key',
                    onPressed: _isRestoring ? null : _restoreKey,
                    isLoading: _isRestoring,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
