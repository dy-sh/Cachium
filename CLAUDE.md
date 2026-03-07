# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cachium is a Flutter mobile personal finance manager app with a dark theme design system.

**Tech Stack:** Flutter (Dart SDK ^3.9.0), Riverpod 2.5.1, GoRouter 14.2.0, Material Design 3

**Key Dependencies:** lucide_icons (icons), google_fonts (typography), uuid (ID generation), intl (formatting), share_plus (file sharing), file_picker (file selection), csv (CSV parsing), sqlite3 (raw SQLite operations)

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

## Git Workflow

**IMPORTANT:** Do NOT create git commits. The user will handle all git operations manually.

- NEVER run `git commit` or `git add` commands
- NEVER use the `--commit` flag with scripts
- Focus on making code changes only
- Let the user review and commit changes themselves

## Feature Documentation

**IMPORTANT:** After completing a new feature, always run the `feature-docs-updater` agent to keep documentation up to date.

```
/agents feature-docs-updater
```

This agent updates CLAUDE.md and any relevant docs to reflect new routes, providers, models, services, or architectural patterns introduced by the feature.

## Architecture

```
lib/
├── main.dart                 # Entry point with ProviderScope wrapper
├── app.dart                  # CachiumApp widget, theme, routing config
├── core/
│   ├── constants/            # AppColors, AppTypography, AppSpacing, AppRadius, AppAnimations
│   ├── database/services/    # DatabaseMetricsService, DatabaseExportService, DatabaseImportService
│   ├── providers/            # Database and repository providers
│   └── utils/                # currency_formatter, date_formatter, haptic_helper, page_transitions
├── data/
│   ├── demo/                 # Demo data for development (demo_data.dart)
│   ├── encryption/           # Internal DTOs for encryption (*_data.dart models)
│   └── repositories/         # Repository classes for encrypted storage
├── design_system/            # Reusable UI components (barrel: design_system.dart)
│   ├── components/           # Semantic-named components (buttons, cards, chips, inputs, etc.)
│   ├── animations/           # Animation utilities
│   └── mixins/               # TapScaleMixin and other mixins
├── features/                 # Feature modules (accounts, categories, home, settings, transactions)
│   └── {feature}/
│       ├── data/models/      # Domain models + enums with extensions
│       └── presentation/     # Screens, providers (including form notifiers), widgets
└── navigation/               # AppRouter (GoRouter), NavigationShell (bottom nav with ShellRoute)
```

## State Management Patterns

### Entity Lists (AsyncNotifier)
```dart
class AccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    final repository = ref.watch(accountRepositoryProvider);
    return repository.getAllAccounts();
  }
}
final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<Account>>(...);
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

- **Design system naming:** Components use semantic, purpose-driven names without prefixes. Examples: `PrimaryButton`, `Surface` (customizable container), `InputField`, `PageLayout`, `DatePicker`, `SelectionChip`, `CircularButton`. Names are chosen to be descriptive and avoid conflicts with Flutter Material widgets through semantic alternatives.
- **Model equality:** Models implement `==` and `hashCode` based on `id` only
- **CopyWith pattern:** All models use copyWith() for immutable updates
- **Enum extensions:** All enums have extensions for `displayName`, `color` (from AppColors), `icon` (IconData)
- **Hierarchical categories:** Categories support `parentId` for nesting; `DefaultCategories` provides presets
- **Account customization:** Accounts support `customColor` and `customIcon` overrides via `getColorWithIntensity()`

## Notifications

**IMPORTANT:** Do NOT use Flutter's `SnackBar` or `ScaffoldMessenger`. Use the custom `Notification` system instead.

The app uses a custom notification system (`lib/design_system/components/feedback/notification.dart`) that appears from the top with slide + fade animation, matching the app's dark theme.

**Notification Types:**
- `success` - green, checkmark icon
- `error` - red, X icon
- `warning` - yellow, alert triangle icon
- `info` - cyan, info icon

**Usage via BuildContext extension:**
```dart
context.showSuccessNotification('Operation completed');
context.showErrorNotification('Something went wrong');
context.showWarningNotification('Check this out');
context.showInfoNotification('FYI...');

// With custom duration
context.showSuccessNotification('Done', duration: Duration(seconds: 5));
```

**Features:**
- Appears from top with animation
- Swipe up to dismiss
- Auto-dismisses after duration (default: 3s for success/warning/info, 4s for error)
- Queues multiple notifications

## Color System

ColorIntensity enum (`prism`/`zen`/`pastel`/`neon`/`vintage`) defined in `app_settings.dart` drives visual appearance globally.

Key methods in `AppColors`:
- `getAccountColor(type, intensity)` - Account type colors
- `getTransactionColor(type, intensity)` - Transaction type colors
- `getCategoryColors(intensity)` - Category color palette
- `getAccentColor(index, intensity)` - Accent color selection
- Opacity helpers: `getBgOpacity()`, `getBorderOpacity()`
- Color manipulation: `lighten()`, `darken()`, `withOpacity()`

## Multi-Currency

The app supports per-account and per-transaction currency codes independent of the main currency.

**Transaction model fields:**
- `currencyCode` - currency of the transaction amount
- `conversionRate` - rate used to convert to main currency for aggregation
- `destinationAmount` - for cross-currency transfers: the actual amount credited to the destination account (may differ from `amount` due to exchange rate)

**Exchange rate providers:**
- `ExchangeRatesNotifier` reads `exchangeRateApiOption` from settings and calls `service.setApi()` before fetching; auto-skips fetch if rates are less than 24h old (`lastRateFetchTimestamp` in AppSettings)
- `exchangeRatesStaleProvider` (derived `Provider<bool>`) is `true` when `lastRateFetchTimestamp` is more than 24h ago; consumed by `TotalBalanceCard` to show a warning icon when multiple account currencies are in use
- Supported APIs: Open ER-API (`open.er-api.com`, free, no key), Manual (user-defined rates via `ManualRatesScreen`)
- Manual rates are edited at `/settings/formats/manual-rates`

**Key conventions:**
- All `CurrencyFormatter.format()` and `AnimatedCounter` calls pass the per-account or per-transaction `currencyCode`
- Aggregated totals (total balance, analytics, budgets) always display in the main currency
- Foreign-currency items show an "≈ $X,XXX.XX" subtitle converted to main currency
- `convertedAmount()`, `convertToMainCurrency()`, and `convertTransactionToMainCurrency()` round to 2 decimal places — do not skip this when adding new conversion helpers
- `deleteTransactionsForCategory` and `moveTransactionsToAccount` in `transactions_provider.dart` treat transfers specially: both source and destination account balances are adjusted; cross-currency moves use live exchange rates for conversion
- `TransactionFormNotifier.hasChanges()` tracks `originalDestinationAmount`; always include it when comparing original vs. current form state

## Database Management

**IMPORTANT:** Do NOT create database migration logic when the schema changes. The app is in testing/development phase and not used in production. Simply increment `schemaVersion` in `app_database.dart` - the existing `MigrationStrategy` will recreate all tables automatically.

The app includes comprehensive database import/export functionality accessible via Settings → Database.

**Features:**
- **Metrics Display:** Transaction/category/account counts with creation and last update timestamps
- **Delete Database:** Confirmation dialog with optional "reset app settings" checkbox
- **Create Demo Database:** Seeds sample data for testing
- **Export SQLite/CSV:** With encryption toggle (encrypted blob or plaintext columns)
- **Import SQLite/CSV:** Auto-detects format (encrypted vs plaintext) and re-encrypts on import

**Key Services:**
- `DatabaseMetricsService` - Queries counts and timestamps from all tables
- `DatabaseExportService` - SQLite and CSV export with encryption options
- `DatabaseImportService` - SQLite and CSV import with format detection

**Routes:**
- `/settings/database` - Main database settings page
- `/settings/database/export-sqlite` - SQLite export options
- `/settings/database/export-csv` - CSV export options
- `/settings/formats/manual-rates` - Manual exchange rate editor (`AppRoutes.manualRates`)

## Key Files

- `lib/app.dart` - App setup and theme configuration
- `lib/navigation/app_router.dart` - All routes (use `AppRoutes` constants)
- `lib/core/constants/app_colors.dart` - Comprehensive color system (400+ lines)
- `lib/core/providers/database_providers.dart` - Core database and repository providers
- `lib/core/database/app_database.dart` - Drift database schema and operations
- `lib/core/database/services/` - Database metrics, export, and import services
- `lib/features/settings/data/models/app_settings.dart` - Settings model + ColorIntensity enum
- `lib/features/settings/presentation/providers/database_management_providers.dart` - Database management providers
- `lib/features/categories/data/models/category.dart` - Category with hierarchy support
- `lib/design_system/components/feedback/notification.dart` - Custom notification system (replaces SnackBar)
- `lib/core/services/exchange_rate_service.dart` - Exchange rate fetching; active API set via `setApi()` before fetch
- `lib/core/providers/exchange_rate_provider.dart` - `ExchangeRatesNotifier` wires API from settings on build
- `lib/features/settings/presentation/screens/manual_rates_screen.dart` - Manual exchange rate editor
