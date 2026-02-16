import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/app_lock_provider.dart';
import '../providers/settings_provider.dart';

enum _UnlockMode { pin, password, biometric }

class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticating = false;
  String _enteredPin = '';
  String? _errorMessage;
  late _UnlockMode _mode;
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMode();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _initMode() {
    final hasPin = ref.read(appPinCodeProvider) != null;
    final hasPassword = ref.read(appPasswordProvider) != null;
    final biometricAsync = ref.read(biometricAvailableProvider);
    final hasBiometric = biometricAsync.valueOrNull ?? false;

    // Pick default mode: PIN > Password > Biometric
    if (hasPin) {
      _mode = _UnlockMode.pin;
    } else if (hasPassword) {
      _mode = _UnlockMode.password;
      _passwordFocusNode.requestFocus();
    } else if (hasBiometric) {
      _mode = _UnlockMode.biometric;
    } else {
      _mode = _UnlockMode.pin; // Fallback
    }
    setState(() {});

    // Auto-trigger biometric if available
    if (hasBiometric) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final service = ref.read(appLockServiceProvider);
    final success = await service.authenticate();

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    if (success) {
      _unlock();
    }
  }

  void _unlock() {
    ref.read(appLockStateProvider.notifier).unlock();
    widget.onUnlocked();
  }

  void _onPinDigit(String digit) {
    final storedPin = ref.read(appPinCodeProvider);
    if (storedPin == null) return;
    if (_enteredPin.length >= storedPin.length) return;

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == storedPin.length) {
      if (_enteredPin == storedPin) {
        _unlock();
      } else {
        setState(() {
          _errorMessage = 'Wrong PIN';
          _enteredPin = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  void _submitPassword() {
    final storedPassword = ref.read(appPasswordProvider);
    if (storedPassword == null) return;

    if (_passwordController.text == storedPassword) {
      _unlock();
    } else {
      setState(() {
        _errorMessage = 'Wrong password';
        _passwordController.clear();
      });
    }
  }

  void _switchMode(_UnlockMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _enteredPin = '';
      _passwordController.clear();
    });
    if (mode == _UnlockMode.password) {
      _passwordFocusNode.requestFocus();
    }
    if (mode == _UnlockMode.biometric) {
      _tryBiometric();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storedPin = ref.watch(appPinCodeProvider);
    final storedPassword = ref.watch(appPasswordProvider);
    final biometricAsync = ref.watch(biometricAvailableProvider);
    final hasBiometric = biometricAsync.valueOrNull ?? false;
    final hasPin = storedPin != null;
    final hasPassword = storedPassword != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Lock icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    LucideIcons.lock,
                    size: 36,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Cachium is Locked',
                  style: AppTypography.h3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _mode == _UnlockMode.pin
                      ? 'Enter your PIN'
                      : _mode == _UnlockMode.password
                          ? 'Enter your password'
                          : 'Authenticate to access your data',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.expense,
                    ),
                  ),
                ],

                // PIN mode
                if (_mode == _UnlockMode.pin && hasPin) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _buildPinDots(storedPin.length),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildNumberPad(),
                ],

                // Password mode
                if (_mode == _UnlockMode.password && hasPassword) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  _buildPasswordInput(),
                ],

                // Biometric-only mode (no PIN or password)
                if (_mode == _UnlockMode.biometric) ...[
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildBiometricButton(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Tap to unlock',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],

                // Alternative methods
                const SizedBox(height: AppSpacing.xxl),
                _buildAlternatives(
                  hasPin: hasPin,
                  hasPassword: hasPassword,
                  hasBiometric: hasBiometric,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots(int pinLength) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (index) {
        final filled = index < _enteredPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.textPrimary : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.textPrimary : AppColors.textTertiary,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPasswordInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: true,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.textTertiary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
            onSubmitted: (_) => _submitPassword(),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _submitPassword,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Unlock',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _isAuthenticating ? null : _tryBiometric,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.accentPrimary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentPrimary.withValues(alpha: 0.3),
          ),
        ),
        child: _isAuthenticating
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                ),
              )
            : Icon(
                LucideIcons.fingerprint,
                size: 28,
                color: AppColors.accentPrimary,
              ),
      ),
    );
  }

  Widget _buildAlternatives({
    required bool hasPin,
    required bool hasPassword,
    required bool hasBiometric,
  }) {
    final alternatives = <Widget>[];

    if (_mode != _UnlockMode.pin && hasPin) {
      alternatives.add(_buildAltButton(
        icon: LucideIcons.hash,
        label: 'Use PIN',
        onTap: () => _switchMode(_UnlockMode.pin),
      ));
    }
    if (_mode != _UnlockMode.password && hasPassword) {
      alternatives.add(_buildAltButton(
        icon: LucideIcons.keyRound,
        label: 'Use Password',
        onTap: () => _switchMode(_UnlockMode.password),
      ));
    }
    if (_mode != _UnlockMode.biometric && hasBiometric) {
      alternatives.add(_buildAltButton(
        icon: LucideIcons.fingerprint,
        label: 'Use Fingerprint',
        onTap: () => _switchMode(_UnlockMode.biometric),
      ));
    }

    if (alternatives.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xxl,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: alternatives,
    );
  }

  Widget _buildAltButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          _buildPadRow(['1', '2', '3']),
          const SizedBox(height: AppSpacing.md),
          _buildPadRow(['4', '5', '6']),
          const SizedBox(height: AppSpacing.md),
          _buildPadRow(['7', '8', '9']),
          const SizedBox(height: AppSpacing.md),
          _buildPadRow(['', '0', 'back']),
        ],
      ),
    );
  }

  Widget _buildPadRow(List<String> keys) {
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
          onTap: () => _onPinDigit(key),
          child: Container(
            width: 72,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
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
