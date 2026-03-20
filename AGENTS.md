# AGENTS.md

Instructions for AI agents (Claude Code, Codex, etc.) working on this repository.

## Critical Rules

1. **No git commits.** Never run `git commit`, `git add`, or use `--commit` flags. The user handles all git operations.
2. **No SnackBar/ScaffoldMessenger.** Use the custom notification system instead (see Notifications below).
3. **Incremental database migrations.** Add a new migration case in `app_database.dart` `onUpgrade` for each schema change. Bump `schemaVersion` and add the migration under `if (from < N)`. Destructive recreate is only used for `from < 16` (legacy users).
4. **Keep AGENTS.md in sync.** When you add or change rules, conventions, or architectural patterns in this file, ensure changes are reflected here. If you notice AGENTS.md is outdated relative to the codebase, update it proactively.
5. **Run `feature-docs-updater` agent** after completing a new feature to update `docs/features.md` and `docs/features_new.md`.

## Project Overview

**Cachium** — Flutter mobile personal finance app with dark/light theme support.

**Stack:** Flutter (Dart ^3.9.0), Riverpod 2.5.1, GoRouter 14.2.0, Material Design 3, SQLite3, lucide_icons, google_fonts

**Commands:**
```bash
flutter pub get          # Install deps
flutter run              # Debug mode
flutter analyze          # Lint
flutter test             # Tests
```

## Architecture

```
lib/
├── main.dart                 # Entry point (ProviderScope)
├── app.dart                  # Theme, routing config
├── core/
│   ├── constants/            # AppColors, AppTypography, AppSpacing, AppRadius
│   ├── database/services/    # Metrics, Export, Import services
│   ├── providers/            # Database & repository providers
│   └── utils/                # Formatters, currency_conversion, haptic_helper
├── data/
│   ├── encryption/           # DTOs for encrypted storage
│   └── repositories/         # Repository classes
├── design_system/            # Reusable components (barrel: design_system.dart)
├── features/                 # Feature modules: accounts, bills, categories, home, settings, transactions
│   └── {feature}/
│       ├── data/models/      # Domain models + enum extensions
│       └── presentation/     # Screens, providers, widgets
└── navigation/               # GoRouter setup, NavigationShell
```

## State Management

- **AsyncNotifier** for entity lists (accounts, transactions, categories)
- **Notifier<T>** for settings and form state
- **Provider** for computed/derived values
- **Provider.family** for parameterized lookups (e.g. `accountByIdProvider`)
- Use `ref.watch()` in ConsumerWidget for reactive updates

## Key Conventions

- **Design system naming:** Semantic names without prefixes (`PrimaryButton`, `SecondaryButton`, `DestructiveButton`, `Surface`, `InputField`, `PageLayout`)
- **Button variants:** `PrimaryButton` (filled accent), `SecondaryButton` (outlined), `DestructiveButton` (red, filled or outlined)
- **Model equality:** `==` and `hashCode` based on `id` only; all models use `copyWith()`
- **Model validation:** Models use `assert()` for invariants (non-negative amounts, valid currency codes, valid month/year ranges). These fire in debug mode to catch bad data early.
- **Enum extensions:** All enums have `displayName`, `color`, `icon` extensions
- **Categories:** Support `parentId` for hierarchy; `DefaultCategories` provides presets
- **Accounts:** Support `customColor`/`customIcon` overrides via `getColorWithIntensity()`
- **Credential hashing:** PIN/password stored as `pbkdf2:<iterations>:<base64-salt>:<base64-hash>` via `CredentialHasher`. Never store plaintext. Use `CredentialHasher.verify()` for comparisons (handles legacy `sha256:` and plaintext fallback). New credentials always use PBKDF2 with 100k iterations.
- **PopScope for forms:** All form screens must wrap their Scaffold in `PopScope` with unsaved-work detection and confirmation dialog.
- **Provider lookups:** Use `accountMapProvider`/`categoryMapProvider` for O(1) lookups by ID. Prefer `accountByIdProvider`/`categoryByIdProvider` which use these maps.
- **Error handling:** Wrap all async operations in try-catch with `context.showErrorNotification()` in screens. Settings provider uses optimistic updates with rollback on error.

## Notifications

Use context extensions — never SnackBar:
```dart
context.showSuccessNotification('Done');
context.showErrorNotification('Failed');
context.showWarningNotification('Warning');
context.showInfoNotification('Info');
```
Located in `lib/design_system/components/feedback/notification.dart`.

## Multi-Currency

- Per-account and per-transaction `currencyCode` independent of main currency
- `conversionRate` multiplier: `amount * conversionRate ~ mainCurrencyAmount`
- `destinationAmount` for cross-currency transfers
- `mainCurrencyCode` / `mainCurrencyAmount` — historical snapshots persisted at save time; never leave null on new records
- Use `roundCurrency()` from `currency_conversion.dart` for all rounding (not inline `toStringAsFixed`). Pass `currencyCode` for currency-aware decimal places (e.g., JPY=0, KWD=3). Use `currencyDecimalPlaces()` to get the correct decimals for a currency.
- Use `conversionGainLoss()` for all gain/loss calculations (returns `double?`, handle null)
- Aggregated totals always in main currency; foreign items show "~ $X,XXX" subtitle
- Exchange rates: Open ER-API (free) or Manual rates at `/settings/formats/manual-rates`

## Theme System

- **Dark/Light/System** theme modes via `ThemeModeOption` enum in `app_settings.dart`
- `AppColors` uses a static `isDarkMode` flag — theme-dependent colors are getters, not `const`
- **Do NOT use `const`** with theme-dependent `AppColors` values: `background`, `surface`, `surfaceLight`, `border`, `borderSelected`, `textPrimary`, `textSecondary`, `textTertiary`, `accentPrimary`, `selectionGlow`, `navActive`, `navInactive`
- Hue-based colors (red, green, cyan, etc.) remain `static const` and are safe in `const` contexts
- `CachiumApp.applyThemeMode()` sets `AppColors.isDarkMode` and updates system chrome
- `themeModeProvider` provides the current theme mode setting

## Color System

`ColorIntensity` enum (`prism`/`zen`/`neon`) in `app_settings.dart` drives global color saturation.

Key `AppColors` methods: `getAccountColor()`, `getTransactionColor()`, `getCategoryColors()`, `getAccentColor()`, plus opacity and color manipulation helpers.

## Bills & Reminders

- Bill model in `lib/features/bills/data/models/bill.dart` with due dates, frequency, reminder settings
- Encrypted storage like other entities (BillData freezed DTO)
- `billsProvider` (AsyncNotifier), `upcomingBillsProvider`, `overdueBillsProvider`
- `markAsPaid` creates an expense transaction and generates the next recurring bill
- Routes: `/settings/bills`, `/bill/new`, `/bill/:id/edit`

## Budget Rollover

- Per-budget `rolloverEnabled` flag (default: false)
- Effective budget = current month amount + rollover from previous months
- Cascading rollover up to 12 months; overspending produces zero rollover (clamped)
- `BudgetProgress.effectiveBudget` used for progress calculations

## Key Files

- `lib/app.dart` — Theme and routing (dark/light ThemeData, gated by welcome/lock/main screens)
- `lib/main.dart` — Entry point (SystemChrome setup, key migration, provider container)
- `lib/navigation/app_router.dart` — Routes (`AppRoutes` constants)
- `lib/core/constants/app_colors.dart` — Theme-aware color system (dark/light variants)
- `lib/core/database/app_database.dart` — Database schema (version 23, incremental migrations)
- `lib/core/utils/currency_conversion.dart` — `conversionGainLoss()`, `roundCurrency()`
- `lib/core/utils/credential_hasher.dart` — PBKDF2 credential hashing (with legacy SHA-256 and plaintext migration)
- `lib/features/settings/data/models/app_settings.dart` — Settings model + ThemeModeOption + ColorIntensity + AutoLockTimeout
- `lib/design_system/components/feedback/notification.dart` — Custom notifications
- `lib/core/services/exchange_rate_service.dart` — Exchange rate fetching
- `lib/features/bills/` — Bill reminders feature module
- `lib/features/budgets/` — Budgets with rollover support
