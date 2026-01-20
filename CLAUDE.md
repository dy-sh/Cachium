# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cachium is a Flutter mobile personal finance manager app with a dark theme design system.

**Tech Stack:** Flutter (Dart SDK ^3.9.0), Riverpod 2.5.1, GoRouter 14.2.0, Material Design 3

**Key Dependencies:** lucide_icons (icons), google_fonts (typography), uuid (ID generation), intl (formatting)

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
├── core/
│   ├── constants/            # AppColors, AppTypography, AppSpacing, AppRadius, AppAnimations
│   ├── providers/            # CrudNotifier base class for list management
│   └── utils/                # currency_formatter, date_formatter, haptic_helper, page_transitions
├── data/demo/                # Demo data for development (demo_data.dart)
├── design_system/            # Reusable UI components (barrel: design_system.dart)
│   ├── components/           # fm_* prefixed components (buttons, cards, chips, inputs, etc.)
│   ├── animations/           # Animation utilities
│   └── mixins/               # TapScaleMixin and other mixins
├── features/                 # Feature modules (accounts, categories, home, settings, transactions)
│   └── {feature}/
│       ├── data/models/      # Domain models + enums with extensions
│       └── presentation/     # Screens, providers (including form notifiers), widgets
└── navigation/               # AppRouter (GoRouter), NavigationShell (bottom nav with ShellRoute)
```

## State Management Patterns

### Entity Lists (CrudNotifier)
```dart
class AccountsNotifier extends CrudNotifier<Account> {
  @override String getId(Account item) => item.id;
  @override List<Account> build() => List.from(DemoData.accounts);
}
final accountsProvider = NotifierProvider<AccountsNotifier, List<Account>>(...);
```

### Settings (Immutable State)
```dart
class SettingsNotifier extends Notifier<AppSettings> {
  void setColorIntensity(ColorIntensity intensity) => state = state.copyWith(...);
}
```

### Form State
```dart
class AccountFormNotifier extends Notifier<AccountFormState> { ... }
```

**Conventions:**
- `NotifierProvider` for entity lists (Accounts, Transactions, Categories)
- `Notifier<T>` for settings and form state
- `Provider` for computed/derived values
- `Provider.family` for parameterized lookups (e.g., `accountByIdProvider`)
- `ref.watch()` in ConsumerWidget for reactive updates

## Key Conventions

- **Design system prefix:** All design system components use `fm_` prefix (e.g., `fm_button.dart`)
- **Model equality:** Models implement `==` and `hashCode` based on `id` only
- **CopyWith pattern:** All models use copyWith() for immutable updates
- **Enum extensions:** All enums have extensions for `displayName`, `color` (from AppColors), `icon` (IconData)
- **Hierarchical categories:** Categories support `parentId` for nesting; `DefaultCategories` provides presets
- **Account customization:** Accounts support `customColor` and `customIcon` overrides via `getColorWithIntensity()`

## Color System

ColorIntensity enum (`prism`/`zen`/`pastel`/`neon`/`vintage`) defined in `app_settings.dart` drives visual appearance globally.

Key methods in `AppColors`:
- `getAccountColor(type, intensity)` - Account type colors
- `getTransactionColor(type, intensity)` - Transaction type colors
- `getCategoryColors(intensity)` - Category color palette
- `getAccentColor(index, intensity)` - Accent color selection
- Opacity helpers: `getBgOpacity()`, `getBorderOpacity()`
- Color manipulation: `lighten()`, `darken()`, `withOpacity()`

## Key Files

- `lib/app.dart` - App setup and theme configuration
- `lib/navigation/app_router.dart` - All routes (use `AppRoutes` constants)
- `lib/core/constants/app_colors.dart` - Comprehensive color system (400+ lines)
- `lib/core/providers/crud_notifier.dart` - Base class for CRUD operations
- `lib/features/settings/data/models/app_settings.dart` - Settings model + ColorIntensity enum
- `lib/features/categories/data/models/category.dart` - Category with hierarchy support
