import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/app_lock_provider.dart';
import '../providers/settings_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
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
    if (_enteredPin.length >= 6) return;

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    final storedPin = ref.read(appPinCodeProvider);
    if (storedPin != null && _enteredPin.length == storedPin.length) {
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

  @override
  Widget build(BuildContext context) {
    final storedPin = ref.watch(appPinCodeProvider);
    final hasPinSet = storedPin != null;
    final pinLength = storedPin?.length ?? 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
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
                hasPinSet ? 'Enter your PIN' : 'Authenticate to access your data',
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
              if (hasPinSet) ...[
                const SizedBox(height: AppSpacing.xxl),
                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pinLength, (index) {
                    final filled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? AppColors.textPrimary
                            : Colors.transparent,
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
                const SizedBox(height: AppSpacing.xxl),
                // Number pad
                _buildNumberPad(),
                const SizedBox(height: AppSpacing.lg),
                // Biometric button
                GestureDetector(
                  onTap: _isAuthenticating ? null : _tryBiometric,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.fingerprint,
                        size: 20,
                        color: _isAuthenticating
                            ? AppColors.textTertiary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Use Fingerprint',
                        style: AppTypography.labelMedium.copyWith(
                          color: _isAuthenticating
                              ? AppColors.textTertiary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // No PIN set — show biometric-only UI
                const SizedBox(height: AppSpacing.xxxl),
                GestureDetector(
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
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tap to unlock',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
              const Spacer(flex: 3),
            ],
          ),
        ),
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
