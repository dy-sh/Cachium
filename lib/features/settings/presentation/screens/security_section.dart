import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../providers/app_lock_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';
import '../../data/models/app_settings.dart';
import 'appearance_section.dart';

class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;
    if (settings == null) return const SizedBox.shrink();

    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final hasPinSet = settings.appPinCode != null;
    final hasPasswordSet = settings.appPassword != null;
    final hasAnyAuth = hasPinSet || hasPasswordSet;

    String lockDescription() {
      final hasBio = biometricAvailable.valueOrNull ?? false;
      if (hasBio || hasAnyAuth) {
        final methods = <String>[];
        if (hasBio) methods.add('biometric');
        if (hasPinSet) methods.add('PIN');
        if (hasPasswordSet) methods.add('password');
        return 'Require ${methods.join(' / ')} to open app';
      }
      return 'Set a PIN or password to lock the app';
    }

    return SettingsSection(
      title: 'Security',
      children: [
        SettingsToggleTile(
          title: 'App Lock',
          description: biometricAvailable.when(
            data: (_) => lockDescription(),
            loading: () => 'Checking availability...',
            error: (_, __) => lockDescription(),
          ),
          value: settings.appLockEnabled,
          onChanged: (value) async {
            if (value) {
              final available = biometricAvailable.valueOrNull ?? false;
              if (!available && !hasAnyAuth) {
                if (context.mounted) {
                  context.showWarningNotification(
                    'Set a PIN or password first to enable App Lock',
                  );
                }
                return;
              }

              if (available) {
                final service = ref.read(appLockServiceProvider);
                final authenticated = await service.authenticate();
                if (!authenticated) return;
              }
              unawaited(ref.read(settingsProvider.notifier).setAppLockEnabled(true));
            } else {
              unawaited(ref.read(settingsProvider.notifier).setAppLockEnabled(false));
            }
          },
        ),
        if (settings.appLockEnabled) ...[
          SettingsTile(
            title: 'Auto-lock Timeout',
            description: 'How long before the app locks after backgrounding',
            value: settings.autoLockTimeout.displayName,
            onTap: () => _showAutoLockTimeoutPicker(context, ref, settings),
          ),
          if (biometricAvailable.valueOrNull ?? false)
            SettingsToggleTile(
              title: 'Biometric Unlock',
              description: 'Use fingerprint or face to unlock the app',
              value: settings.biometricUnlockEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setBiometricUnlockEnabled(value);
              },
            ),
        ],
        SettingsToggleTile(
          title: 'Hide from Screenshots',
          description: 'Blocks screenshots and screen recording (Android)',
          value: settings.hideFromScreenshots,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setHideFromScreenshots(value);
          },
        ),
        SettingsTile(
          title: hasPinSet ? 'Change PIN' : 'Set PIN Code',
          description: hasPinSet
              ? 'Change or remove your 4–8 digit PIN'
              : 'Add a 4–8 digit PIN to unlock the app',
          onTap: () => _showPinSetupSheet(context, ref, hasPinSet),
        ),
        SettingsTile(
          title: hasPasswordSet ? 'Change Password' : 'Set Password',
          description: hasPasswordSet
              ? 'Change or remove your password'
              : 'Add a password to unlock the app',
          onTap: () => _showPasswordSetupSheet(context, ref, hasPasswordSet),
        ),
        SettingsTile(
          title: 'Encryption Key Backup',
          description: 'Back up or restore your data encryption key',
          icon: LucideIcons.key,
          onTap: () => context.push(AppRoutes.keyBackup),
        ),
      ],
    );
  }

  void _showAutoLockTimeoutPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = OptionPickerSheet(
      title: 'Auto-lock Timeout',
      options: AutoLockTimeout.values.map((e) => e.displayName).toList(),
      selectedIndex: AutoLockTimeout.values.indexOf(settings.autoLockTimeout),
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setAutoLockTimeout(AutoLockTimeout.values[index]);
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  void _showPinSetupSheet(BuildContext context, WidgetRef ref, bool hasPinSet) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = PinSetupSheet(
      hasPinSet: hasPinSet,
      onPinSet: (pin) {
        ref.read(settingsProvider.notifier).setAppPinCode(pin);
        Navigator.pop(context);
        context.showSuccessNotification(
          hasPinSet ? 'PIN changed' : 'PIN set',
        );
      },
      onPinRemoved: hasPinSet
          ? () {
              ref.read(settingsProvider.notifier).setAppPinCode(null);
              // If no other auth method, disable app lock
              final biometric = ref.read(biometricAvailableProvider).valueOrNull ?? false;
              final hasPassword = ref.read(settingsProvider).valueOrNull?.appPassword != null;
              if (!biometric && !hasPassword) {
                ref.read(settingsProvider.notifier).setAppLockEnabled(false);
              }
              Navigator.pop(context);
              context.showSuccessNotification('PIN removed');
            }
          : null,
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }

  void _showPasswordSetupSheet(BuildContext context, WidgetRef ref, bool hasPasswordSet) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = PasswordSetupSheet(
      hasPasswordSet: hasPasswordSet,
      onPasswordSet: (password) {
        ref.read(settingsProvider.notifier).setAppPassword(password);
        Navigator.pop(context);
        context.showSuccessNotification(
          hasPasswordSet ? 'Password changed' : 'Password set',
        );
      },
      onPasswordRemoved: hasPasswordSet
          ? () {
              ref.read(settingsProvider.notifier).setAppPassword(null);
              final biometric = ref.read(biometricAvailableProvider).valueOrNull ?? false;
              final hasPin = ref.read(settingsProvider).valueOrNull?.appPinCode != null;
              if (!biometric && !hasPin) {
                ref.read(settingsProvider.notifier).setAppLockEnabled(false);
              }
              Navigator.pop(context);
              context.showSuccessNotification('Password removed');
            }
          : null,
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }
}

// ─── PIN Setup Sheet ───────────────────────────────────────────────────────────

enum PinStep { enter, confirm }

class PinSetupSheet extends StatefulWidget {
  final bool hasPinSet;
  final ValueChanged<String> onPinSet;
  final VoidCallback? onPinRemoved;

  const PinSetupSheet({
    super.key,
    required this.hasPinSet,
    required this.onPinSet,
    this.onPinRemoved,
  });

  @override
  State<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<PinSetupSheet> {
  PinStep _step = PinStep.enter;
  String _firstPin = '';
  String _currentPin = '';
  String? _error;
  static const _minLength = 4;
  static const _maxLength = 8;

  String get _title {
    if (_step == PinStep.enter) {
      return widget.hasPinSet ? 'Enter New PIN' : 'Set PIN Code';
    }
    return 'Confirm PIN';
  }

  String get _subtitle {
    if (_step == PinStep.enter) return 'Enter a $_minLength–$_maxLength digit PIN';
    return 'Re-enter your ${_firstPin.length}-digit PIN to confirm';
  }

  bool get _canSubmit => _currentPin.length >= _minLength;

  void _submit() {
    if (!_canSubmit) return;
    if (_step == PinStep.enter) {
      setState(() {
        _firstPin = _currentPin;
        _currentPin = '';
        _step = PinStep.confirm;
      });
    } else {
      if (_currentPin == _firstPin) {
        widget.onPinSet(_currentPin);
      } else {
        setState(() {
          _error = 'PINs do not match';
          _currentPin = '';
          _step = PinStep.enter;
          _firstPin = '';
        });
      }
    }
  }

  void _onDigit(String digit) {
    final maxLen = _step == PinStep.confirm ? _firstPin.length : _maxLength;
    if (_currentPin.length >= maxLen) return;

    setState(() {
      _currentPin += digit;
      _error = null;
    });

    // Auto-submit on confirm step when length matches
    if (_step == PinStep.confirm && _currentPin.length == _firstPin.length) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _submit();
      });
    }
  }

  void _onBackspace() {
    if (_currentPin.isEmpty) return;
    setState(() {
      _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dotCount = _step == PinStep.confirm ? _firstPin.length : _maxLength;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.xxsAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(_title, style: AppTypography.h4),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.expense,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(dotCount, (index) {
                final filled = index < _currentPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.textPrimary : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            // Confirm button (only on enter step — confirm step auto-submits)
            if (_step == PinStep.enter) ...[
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: _canSubmit ? _submit : null,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: _canSubmit ? AppColors.textPrimary : AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: _canSubmit ? null : Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'Next',
                      style: AppTypography.labelLarge.copyWith(
                        color: _canSubmit ? AppColors.background : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Number pad
            _buildPad(),
            if (widget.hasPinSet && widget.onPinRemoved != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: widget.onPinRemoved,
                child: Text(
                  'Remove PIN',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.expense,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildPad() {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: AppSpacing.md),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: AppSpacing.md),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: AppSpacing.md),
          _buildRow(['', '0', 'back']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 72, height: 56);
        }
        if (key == 'back') {
          return GestureDetector(
            onTap: _onBackspace,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 72,
              height: 56,
              child: Center(
                child: Icon(
                  LucideIcons.delete,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }
        return GestureDetector(
          onTap: () => _onDigit(key),
          child: Container(
            width: 72,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                key,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Password Setup Sheet ──────────────────────────────────────────────────────

enum PasswordStep { enter, confirm }

class PasswordSetupSheet extends StatefulWidget {
  final bool hasPasswordSet;
  final ValueChanged<String> onPasswordSet;
  final VoidCallback? onPasswordRemoved;

  const PasswordSetupSheet({
    super.key,
    required this.hasPasswordSet,
    required this.onPasswordSet,
    this.onPasswordRemoved,
  });

  @override
  State<PasswordSetupSheet> createState() => _PasswordSetupSheetState();
}

class _PasswordSetupSheetState extends State<PasswordSetupSheet> {
  PasswordStep _step = PasswordStep.enter;
  String _firstPassword = '';
  String? _error;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _title {
    if (_step == PasswordStep.enter) {
      return widget.hasPasswordSet ? 'Enter New Password' : 'Set Password';
    }
    return 'Confirm Password';
  }

  String get _subtitle {
    if (_step == PasswordStep.enter) return 'Enter a password (4+ characters)';
    return 'Re-enter your password to confirm';
  }

  void _submit() {
    final text = _controller.text;
    if (text.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters');
      return;
    }

    if (_step == PasswordStep.enter) {
      setState(() {
        _firstPassword = text;
        _controller.clear();
        _step = PasswordStep.confirm;
        _error = null;
      });
      _focusNode.requestFocus();
    } else {
      if (text == _firstPassword) {
        widget.onPasswordSet(text);
      } else {
        setState(() {
          _error = 'Passwords do not match';
          _controller.clear();
          _step = PasswordStep.enter;
          _firstPassword = '';
        });
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.xxsAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(_title, style: AppTypography.h4),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.expense,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              obscureText: true,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _step == PasswordStep.enter ? 'Password' : 'Confirm password',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.background,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Center(
                  child: Text(
                    _step == PasswordStep.enter ? 'Next' : 'Set Password',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.hasPasswordSet && widget.onPasswordRemoved != null) ...[
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: widget.onPasswordRemoved,
                child: Text(
                  'Remove Password',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.expense,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
