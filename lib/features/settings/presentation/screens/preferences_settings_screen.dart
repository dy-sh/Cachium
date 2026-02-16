import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../data/models/app_settings.dart';
import '../providers/app_lock_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_toggle_tile.dart';

class PreferencesSettingsScreen extends ConsumerWidget {
  const PreferencesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Pinned header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('Preferences', style: AppTypography.h3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSection(
                      title: 'General',
                      children: [
                        SettingsToggleTile(
                          title: 'Haptic Feedback',
                          description: 'Vibration on button taps',
                          value: settings.hapticFeedbackEnabled,
                          onChanged: (value) => ref.read(settingsProvider.notifier).setHapticFeedbackEnabled(value),
                        ),
                        _buildStartScreenTile(context, ref, settings),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSecuritySection(context, ref, settings),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, WidgetRef ref, AppSettings settings) {
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final hasPinSet = settings.appPinCode != null;

    return SettingsSection(
      title: 'Security',
      children: [
        SettingsToggleTile(
          title: 'App Lock',
          description: biometricAvailable.when(
            data: (available) => available
                ? 'Require biometric or PIN to open app'
                : hasPinSet
                    ? 'Require PIN to open app'
                    : 'Set a PIN or enable biometrics to lock the app',
            loading: () => 'Checking availability...',
            error: (_, __) => hasPinSet
                ? 'Require PIN to open app'
                : 'Set a PIN to lock the app',
          ),
          value: settings.appLockEnabled,
          onChanged: (value) async {
            if (value) {
              final available = biometricAvailable.valueOrNull ?? false;
              if (!available && !hasPinSet) {
                // No biometric and no PIN — prompt to set PIN first
                if (context.mounted) {
                  context.showWarningNotification(
                    'Set a PIN code first to enable App Lock',
                  );
                }
                return;
              }

              if (available) {
                // Verify with biometric before enabling
                final service = ref.read(appLockServiceProvider);
                final authenticated = await service.authenticate();
                if (!authenticated) return;
              }
              ref.read(settingsProvider.notifier).setAppLockEnabled(true);
            } else {
              ref.read(settingsProvider.notifier).setAppLockEnabled(false);
            }
          },
        ),
        SettingsTile(
          title: hasPinSet ? 'Change PIN' : 'Set PIN Code',
          description: hasPinSet
              ? 'Change or remove your PIN'
              : 'Add a PIN as an alternative unlock method',
          onTap: () => _showPinSetupSheet(context, ref, hasPinSet),
        ),
      ],
    );
  }

  void _showPinSetupSheet(BuildContext context, WidgetRef ref, bool hasPinSet) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = _PinSetupSheet(
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
              // If no biometric available, also disable app lock
              final biometric = ref.read(biometricAvailableProvider).valueOrNull ?? false;
              if (!biometric) {
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

  Widget _buildStartScreenTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    final startScreenLabels = {
      StartScreen.home: 'Home',
      StartScreen.transactions: 'Transactions',
      StartScreen.accounts: 'Accounts',
    };
    return SettingsTile(
      title: 'Start Screen',
      description: 'Screen to show when opening the app',
      value: startScreenLabels[settings.startScreen],
      onTap: () => _showStartScreenPicker(context, ref, settings),
    );
  }

  void _showStartScreenPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final modalContent = _OptionPickerSheet(
      title: 'Start Screen',
      options: const ['Home', 'Transactions', 'Accounts'],
      selectedIndex: StartScreen.values.indexOf(settings.startScreen),
      onSelected: (index) {
        ref.read(settingsProvider.notifier).setStartScreen(StartScreen.values[index]);
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
}

class _OptionPickerSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.h4),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(options.length, (index) {
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          options[index],
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.check,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

enum _PinStep { enter, confirm }

class _PinSetupSheet extends StatefulWidget {
  final bool hasPinSet;
  final ValueChanged<String> onPinSet;
  final VoidCallback? onPinRemoved;

  const _PinSetupSheet({
    required this.hasPinSet,
    required this.onPinSet,
    this.onPinRemoved,
  });

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  _PinStep _step = _PinStep.enter;
  String _firstPin = '';
  String _currentPin = '';
  String? _error;
  static const _pinLength = 4;

  String get _title {
    if (_step == _PinStep.enter) {
      return widget.hasPinSet ? 'Enter New PIN' : 'Set PIN Code';
    }
    return 'Confirm PIN';
  }

  String get _subtitle {
    if (_step == _PinStep.enter) return 'Enter a $_pinLength-digit PIN';
    return 'Re-enter your PIN to confirm';
  }

  void _onDigit(String digit) {
    if (_currentPin.length >= _pinLength) return;

    setState(() {
      _currentPin += digit;
      _error = null;
    });

    if (_currentPin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        if (_step == _PinStep.enter) {
          setState(() {
            _firstPin = _currentPin;
            _currentPin = '';
            _step = _PinStep.confirm;
          });
        } else {
          // Confirm step
          if (_currentPin == _firstPin) {
            widget.onPinSet(_currentPin);
          } else {
            setState(() {
              _error = 'PINs do not match';
              _currentPin = '';
              _step = _PinStep.enter;
              _firstPin = '';
            });
          }
        }
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
                  borderRadius: BorderRadius.circular(2),
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
              children: List.generate(_pinLength, (index) {
                final filled = index < _currentPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
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
            const SizedBox(height: AppSpacing.xxl),
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
