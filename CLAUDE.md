# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cachium is a Flutter mobile personal finance manager app with a dark theme design system.

**Tech Stack:** Flutter (Dart SDK ^3.9.0), Riverpod 2.5.1, GoRouter 14.2.0, Material Design 3

## Common Commands

```bash
flutter pub get              # Install dependencies
flutter run                  # Run in debug mode
flutter run --release        # Run in release mode
flutter test                 # Run tests
flutter analyze              # Run linter (uses flutter_lints)
flutter build apk            # Android build
flutter build ios            # iOS build
```

## Architecture

```
lib/
├── main.dart                 # Entry point with ProviderScope wrapper
├── app.dart                  # CachiumApp widget, theme, routing config
├── core/                     # Shared utilities and providers
│   ├── constants/            # AppColors, Typography, Spacing, Radius, Animations
│   └── providers/            # CrudNotifier base class for list management
├── design_system/            # Reusable UI components (barrel: design_system.dart)
├── features/                 # Feature modules (accounts, categories, home, settings, transactions)
│   └── {feature}/
│       ├── data/models/      # Domain models + enums with extensions
│       └── presentation/     # Screens, providers, widgets
└── navigation/               # GoRouter config, bottom nav shell
```

## State Management Pattern

Riverpod with NotifierProvider for stateful entities:

```dart
class AccountsNotifier extends CrudNotifier<Account> {
  @override String getId(Account item) => item.id;
  @override List<Account> build() => List.from(DemoData.accounts);
}

final accountsProvider = NotifierProvider<AccountsNotifier, List<Account>>(...);
final totalBalanceProvider = Provider<double>((ref) => ...);  // Derived values
```

- Use `NotifierProvider` for entity lists (Accounts, Transactions, Categories)
- Use `Provider` for computed/derived values
- Use `Provider.family` for parameterized lookups (e.g., `accountByIdProvider`)
- Use `ref.watch()` in ConsumerWidget for reactive updates

## Key Conventions

- **Design system prefix:** All design system components use `fm_` prefix (e.g., `fm_button.dart`)
- **Model equality:** Models implement `==` and `hashCode` based on `id` only
- **CopyWith pattern:** All models use copyWith() for immutable updates
- **Enum extensions:** Heavy use of extensions for display names, colors, icons
- **Demo data:** Located in `lib/data/demo/demo_data.dart` for development

## Color System

ColorIntensity enum (bright/dim/pastel/neon/vintage) drives visual appearance globally. Key methods:
- `AppColors.getAccountColor(type, intensity)`
- `AppColors.getTransactionColor(type, intensity)`
- Opacity helpers: `getBgOpacity()`, `getBorderOpacity()`

## Key Files

- `lib/app.dart` - App setup and theme configuration
- `lib/navigation/app_router.dart` - All routes (use `AppRoutes` constants)
- `lib/core/constants/app_colors.dart` - Comprehensive color system
- `lib/core/providers/crud_notifier.dart` - Base class for CRUD operations
- `lib/features/settings/data/models/app_settings.dart` - Settings enums
