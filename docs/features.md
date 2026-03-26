# Implemented Features


## Core App Features

#### 15. Transaction management (CRUD)
- Create income, expense, or transfer transactions
- Edit all transaction fields with change tracking (canSave requires hasChanges)
- Soft-delete with undo notification via custom notification system
- Restore soft-deleted transactions from dedicated Deleted Transactions screen
- Batch delete and batch restore of deleted transactions
- Search deleted transactions by amount, note, merchant, date

#### 16. Transaction form
- Type toggle: Income / Expense / Transfer
- Amount input with currency formatting
- Foldable category selector with sort options (last used / list order / alphabetical)
- Inline "New" category creation directly from transaction form
- Foldable account selector with inline "New" account creation
- Destination account picker for transfers (validates source != destination)
- Date picker with calendar UI
- Merchant field with autocomplete from history
- Note field for freeform text
- Auto-selection of last used account and/or category (configurable)
- Configurable visible category/account count
- Validation: amount > 0 (or >= 0 if zero allowed), required category, required account

#### 17. Transaction list & filtering
- Search by notes and merchants
- Filter chips: All / Income / Expense / Transfer (color-coded)
- Transactions grouped by date with net amount per group (income, expense, net)
- "More" menu with access to Deleted Transactions
- Staggered list animations on initial load

#### 18. Account management (CRUD)
- Create accounts with 6 types: Bank, Credit Card, Cash, Savings, Investment, Wallet
- Edit name, type, initial balance, color, icon
- Delete with 3 options:
  1. Simple delete (no transactions)
  2. Move transactions to another account, then delete
  3. Delete account with all its transactions
- Account type properties: isLiability (Credit Card), isHolding (others), isLiquid (Bank, Cash, Wallet)
- Picker mode: account form can be opened inline from transaction form, returns new account ID

#### 19. Account customization
- Custom color picker (24-color palette) with "Reset to default" option
- Custom icon selection
- Colors respect ColorIntensity setting via `getColorWithIntensity()`

#### 20. Account list screen
- Total balance header with animated counter
- Accounts grouped by type
- Gradient background cards with decorative circles
- Card style: Dim or Bright (configurable in appearance settings)
- Pull-to-refresh

#### 21. Account balance management
- Creating/editing/deleting transactions automatically adjusts account balances
- Transfers adjust both source and destination accounts
- Moving transactions between accounts updates balances
- Balance recalculation tool in database settings (with preview dialog showing current vs. recalculated)

#### 22. Hierarchical categories
- Parent categories with subcategories via `parentId`
- Expandable/collapsible in category management
- Configurable whether parent categories can be selected for transactions
- Default categories: 5 income + 17 expense presets with subcategories

#### 23. Category management
- Income/Expense type toggle
- Category tree with drag-and-drop reordering
- Expandable parent categories showing children
- Create new category with: name, icon, color, type, parent
- Edit existing categories
- Delete with options: reassign transactions to another category, or delete with all transactions
- Drop zones for reparenting (move category under different parent)
- 24-color accent palette for category colors

#### 24. Budget management
- Monthly budgets per expense category
- Month/year navigator to browse budgets across months
- Add budget via bottom sheet (select category + enter amount)
- Edit budget amount
- Delete budget via long-press
- Budget progress with color-coded indicators
- Auto-shown on home screen when budgets exist

---

## Analytics (27 screens, 33+ sections, 16 chart types)

#### 25. Analytics overview tab
- Period summary cards: income, expense, net for selected period
- Savings gauge: visual savings rate indicator
- Financial health section: overall financial health scoring
- Financial insights section: text insights about spending patterns
- Spending trends section: trend analysis over time
- Balance line chart: account balance over time
- Net worth chart: net worth tracking
- Holding/liability pie chart: holding vs liability breakdown
- Income/expense chart: income vs expense comparison
- Waterfall chart: cash flow waterfall visualization
- Category pie chart: spending by category
- Treemap chart: hierarchical category spending visualization
- Top categories list: ranked category spending
- Merchant analysis section: spending by merchant
- Sankey flow section: money flow diagram (accounts to categories)
- Account flow section: flow between accounts
- Cash flow calendar: daily spending heatmap calendar
- Spending heatmap: time-based spending intensity
- Budget progress section (shown if budgets exist)

#### 26. Analytics comparisons tab
- Year over year section: YoY spending comparison
- Period comparison section: compare any two periods
- Category comparison section: category-level comparisons
- Account comparison section: account-level comparisons

#### 27. Analytics forecasts tab
- Spending projection chart: future spending projections
- Budget forecast cards: predicted month-end outcomes
- Trend extrapolation section: trend-based predictions
- Recurring timeline: detected recurring transactions timeline
- What-if simulator: scenario modeling tool
- Savings goal section: goal tracking and projections

#### 28. Analytics insights tab
- Streaks: spending/saving streak tracking (with flame icon)
- Anomaly alerts: unusual spending detection
- Predictions: forward-looking predictions
- Smart financial insights: pattern-based recommendations
- Subscription tracker: detected recurring subscriptions

#### 29. Analytics filters & drill-down
- Date range: 10 presets (Last 7/30 Days, This/Last Month, Last 3/6/12 Months, This Year, All Time, Custom)
- Account filter: multi-select specific accounts
- Category filter: multi-select specific categories
- Type filter: All, Income, or Expense
- Collapsible filter bar with active filter indicator
- Date range navigator for stepping through periods
- Chart drill-down: tap chart elements to navigate to filtered transaction lists

#### 30. Custom chart widgets (16 types)
- Holding/Liability Pie, Balance Line, Category Lines, Category Pie
- Comparative Bar, Income/Expense, Net Worth, Radar Spending
- Sankey Diagram, Savings Gauge, Spending Heatmap, Stacked Area
- Top Categories List, Treemap, Waterfall
- Shared chart tooltip overlay component

---

## Home Screen

#### 31. Home screen layout
- Time-based greeting: "Good morning", "Good afternoon", "Good evening"
- Add transaction button in header
- All sections configurable (show/hide in home settings)
- Pull-to-refresh
- Staggered list animations on initial load

#### 32. Accounts list section
- Horizontal scrollable account cards
- "See all" link to accounts screen
- Configurable text size

#### 33. Total balance card
- Animated counter for total balance
- Holdings vs. Liabilities breakdown
- Privacy mode: tap-to-reveal when balances hidden by default
- Configurable text size (large/small)

#### 34. Quick actions
- Three buttons: Income, Expense, Transfer
- Each opens transaction form pre-set to that type
- TapScaleMixin press animation
- Color-coded by transaction type

---

## Settings & Customization

#### 35. Appearance settings
- Color palette: 3 intensity modes (Prism - vibrant, Zen - muted, Neon - vivid)
- Accent color: full color picker grid from 24-color palette
- Account card style: Dim or Bright gradient with live preview
- Animation toggles: Tab Transitions, Form Animations, Balance Counters (each independent)

#### 36. Format settings
- Date format: MM/DD/YYYY, DD/MM/YYYY, DD.MM.YYYY, YYYY-MM-DD
- Currency symbol: USD ($), EUR, GBP, Custom (up to 3 characters)
- First day of week: Sunday or Monday

#### 37. Preference settings
- Haptic feedback toggle
- Start screen: choose default tab on app launch (Home, Transactions, Accounts)

#### 38. Transaction settings
- Default transaction type (Income/Expense)
- Select last account / Select last category toggles
- Allow zero amount toggle
- Amount size: Large or Small
- Category sort: Last Used / List Order / Alphabetical
- Visible categories count
- Visible accounts count
- Show add account button / Show add category button toggles
- Allow select parent category toggle

#### 39. Home page settings
- Section visibility: show/hide Accounts List, Total Balance, Quick Actions, Recent Transactions
- Hide balances by default (privacy, tap to reveal)
- Configurable text sizes for accounts and total balance

#### 40. Reset to defaults
- Available from main settings screen

---

## Database & Data Management

#### 41. Database metrics
- Transaction/category/account/budget counts
- Creation and last update timestamps per table
- Displayed on database settings screen

#### 42. Database consistency checks
- Transactions with invalid category references
- Transactions with invalid account references
- Categories with invalid parent references
- Duplicate transaction detection (same date + amount)
- Accounts with incorrect balances
- Returns issue counts

#### 43. Export functionality
- SQLite export: encrypted (raw blobs) or plaintext (decrypted columns)
- CSV export: encrypted (base64-encoded blobs) or plaintext (individual columns)
- Settings exported as JSON in both formats
- File sharing via system share sheet (share_plus)

#### 44. Import functionality
- SQLite import: auto-detects encrypted vs. plaintext, re-encrypts on import
- CSV import: auto-detects encrypted vs. plaintext
- Flexible CSV import: 3-step guided flow (file selection, column mapping, preview with validation)
- Metrics comparison dialog (current vs. incoming record counts before import)

#### 45. Database management
- Delete database with optional "reset app settings" checkbox
- Create demo database: seeds sample data for testing
- Balance recalculation with preview dialog

---

## Security & Encryption

#### 46. AES-256-GCM encryption
- All database records encrypted at rest
- Encrypted blob format: [12-byte nonce][ciphertext][16-byte MAC]
- Unique nonce per encryption operation
- Integrity verification: decrypted ID and timestamps must match row metadata (prevents blob-swapping)
- Separate encrypt/decrypt for Transaction, Account, Budget, Category data
- Generic encryptJson/decryptJson for arbitrary data

#### 47. Privacy features
- Hide balances by default on home screen (tap to reveal)
- Encrypted export option preserves encryption in exported files

---

## Design System & UI

#### 48. Custom notification system
- Replaces Flutter SnackBar entirely
- 4 types: success (green/checkmark), error (red/X), warning (yellow/alert), info (cyan/info)
- Slide + fade animation from top of screen
- Swipe up to dismiss
- Auto-dismiss: 3s for success/warning/info, 4s for error
- Action button support (used for "Undo" after delete)
- Queue system for multiple notifications
- BuildContext extensions: `showSuccessNotification()`, `showErrorNotification()`, etc.

#### 49. Design system components (22 components)
- **Animations:** AnimatedCounter (smooth number animation), ShimmerLoading, StaggeredList
- **Buttons:** CircularButton, IconBtn, PrimaryButton
- **Cards:** Surface (customizable container), SelectableCard
- **Chips:** SelectionChip, ToggleChip
- **Feedback:** EmptyState, HelpIcon, LoadingIndicator, Notification
- **Inputs:** AmountInput, DatePicker, Toggle, InputField, InlineSelector
- **Layout:** BottomNavBar (5-tab), FormHeader, PageLayout, ScreenHeader
- **Mixins:** TapScaleMixin (press-down scale animation)

#### 50. Color system
- ColorIntensity enum: Prism / Zen / Neon
- `getAccountColor()`, `getTransactionColor()`, `getCategoryColors()`, `getAccentColor()`
- Opacity helpers: `getBgOpacity()`, `getBorderOpacity()`
- Color manipulation: `lighten()`, `darken()`, `withOpacity()`
- 24-color accent palette

#### 51. Typography & spacing
- Consistent type scale: moneyLarge, moneySmall, h1-h4, bodySmall/bodyMedium, labelSmall/labelMedium
- Spacing scale: xs, sm, md, lg, xl, xxl, xxxl, screenPadding
- Consistent border radius presets

#### 52. Light/Dark/System theme
- Three theme modes: Light, Dark, and System (follows device setting)
- `ThemeModeOption` enum drives mode selection
- `AppColors.isDarkMode` static flag makes all color helpers theme-aware
- Theme toggle accessible from Appearance settings

---

## Navigation & Routing

#### 53. Navigation architecture
- GoRouter with 27 route definitions
- ShellRoute wrapping 5 main tabs with persistent bottom navigation
- 5-tab BottomNavBar: Home, Transactions, Analytics, Accounts, Settings
- Page transitions: SlideLeft (detail/edit screens), SlideUp (create forms), NoTransition (tab switches)
- All transitions respect `formAnimationsEnabledProvider` setting
- Configurable start screen (Home, Transactions, or Accounts)

---

## Utilities

#### 54. Currency formatter
- `format()` for standard currency formatting
- `formatWithSign()` adds +/- prefix based on transaction type
- Respects user's currency symbol setting

#### 55. Date formatter
- `formatRelative()` - "Today", "Yesterday", or date
- `formatFull()` - Full date display
- Respects user's date format and first day of week settings

#### 56. Haptic helper
- Provides haptic feedback respecting the haptic feedback setting


## New Features

#### 1. Transfers between accounts
- `transfer` transaction type with source/destination account
- Dedicated UI in transaction form with "From Account" / "To Account" selectors
- 3-way toggle (Income / Expense / Transfer) in form
- Transfer filter on transactions screen
- Transfer display across home, transactions, and account detail screens
- Balance logic: debits source account, credits destination account

#### 2. Budget alerts & progress
- Budget progress bars on home screen (top 3 budgets)
- Color-coded indicators: green (<75%), yellow (75-100%), red (>100%)
- Shows spent / budget amount with progress bar


#### 3. Onboarding flow
- WelcomeScreen with 3 setup options (Demo Data, Quick Start, Start from Scratch)
- Import from Backup option (navigates to database settings in import-only mode)
- `onboardingCompleted` flag and `shouldShowWelcomeProvider` gate
- Hint text that welcome screen can be re-accessed via Settings > Database > Reset

#### 4. Drag-to-reorder categories
- Drag handles in Settings > Categories
- `sortOrder` field persisted via updates
- Drop zones for reparenting (move category under different parent)

#### 5. Bulk edit transactions
- Long-press to enter multi-select mode
- Bulk re-categorize via modal bottom sheet picker
- Bulk change account via modal bottom sheet picker
- Bulk delete selected transactions
- Select all / deselect all
- Action buttons in selection header bar

#### 6. Swipe actions on transactions
- Swipe-left to delete (with undo notification)
- Swipe-right to duplicate (creates copy with today's date)

#### 7. Pull-to-refresh
- `RefreshIndicator` on transactions screen, home screen, and accounts screen
- Styled with app theme colors


#### 8. Transaction details screen
- Read-only detail view with amount, type badge, category, account, date, merchant, note
- Color-coded amount display with transaction type indicator
- Edit button navigates to form, delete button with undo
- For transfers: shows "From" and "To" accounts
- Route: `/transaction/:id` shows detail, `/transaction/:id/edit` opens form

#### 9. Category icon picker enhancement
- Search field with keyword matching across 60 icons
- Each icon tagged with semantic keywords (e.g., "food dining restaurant")
- Filtered grid updates as user types
- "No icons found" empty state

#### 10. Merchant auto-complete
- `merchantSuggestionsProvider` returns distinct merchants sorted by frequency
- `RawAutocomplete` widget with styled dropdown
- Suggestions filtered by typed text, limited to top 5
- Store icon and merchant name in dropdown items

#### 11. Account transaction history
- Account detail screen: tapping an account shows balance, type, monthly stats
- Monthly income/expense breakdown for the account
- Full transaction history filtered to that account
- Transfer context: shows "To/From" relative to current account
- Edit button navigates to account form
- Route: `/account/:id` shows detail, `/account/:id/edit` opens form


#### 12. Contextual empty states
- Accounts: "Add your first account" with tap-to-create action
- Recent transactions: icon + "No transactions yet" + "Tap to add your first transaction"

#### 13. Confirmation animations
- Success notification after saving/updating a transaction ("Transaction saved" / "Transaction updated")

#### 14. Keyboard shortcuts / Quick entry
- Amount field supports math expressions: `+`, `-`, `*`, `/`
- Live preview shows evaluated result (e.g., `= $75.00`)
- Expression auto-resolves on blur, replacing text with computed value
- Proper operator precedence (* and / before + and -)

#### 15. Multi-currency support
- Accounts and transactions each store their own `currencyCode` independently of the main currency
- Account edit preserves `currencyCode`; transaction edit preserves `currencyCode` and `conversionRate`
- Account form reset defaults to the user's main currency instead of hardcoded USD
- Exchange rates are eagerly loaded when the transaction form opens and refreshed right before saving
- `setConversionRate()` on `TransactionFormNotifier` allows reliable rate updates
- All `CurrencyFormatter.format()` and `AnimatedCounter` calls use the correct per-account or per-transaction `currencyCode`
- Aggregated totals (total balance, analytics, budgets) display in the main currency
- Foreign-currency accounts and transactions show an "≈ $X,XXX.XX" subtitle in main currency on account detail, account cards, account preview list, and transaction detail screens

#### 16. Cross-currency transfer destination amount
- `destinationAmount` field on Transaction model and TransactionData DTO stores the credited amount separately from the debited amount
- Transaction form shows an editable destination amount field when source and destination accounts have different currencies
- `transactions_provider` credits destination accounts using `destinationAmount` (not `amount`) for correct cross-currency balance updates

#### 17. Exchange rate API selection
- `ExchangeRatesNotifier.build()` reads `exchangeRateApiOption` from settings and calls `service.setApi()` with the correct implementation before fetching
- Replaced broken ExchangeRate.host implementation with `OpenExchangeRateApi` using `open.er-api.com` (free, no key required); display name is "Open ER-API"

#### 18. Rate staleness indicator
- `lastRateFetchTimestamp` stored in AppSettings and SettingsData
- Formats settings screen shows "Rates as of: X" with staleness indication and a manual refresh button
- Auto-skips fetch if rates are less than 24 hours old

#### 19. Manual exchange rate editor
- New `ManualRatesScreen` at route `/settings/formats/manual-rates` (`AppRoutes.manualRates`)
- When Manual mode is selected in formats settings, an "Edit Rates" button appears
- Users can add currencies and set custom exchange rates without relying on an external API

#### 20. Multi-currency bug fixes and robustness
- `deleteTransactionsForCategory` now correctly reverses both source and destination account balances for transfer transactions instead of treating them as income/expense
- `moveTransactionsToAccount` handles cross-currency account moves by converting amounts using live exchange rates when source and destination accounts have different currencies; also properly handles transfer transactions
- `hasChanges()` in `TransactionFormNotifier` tracks `originalDestinationAmount` so editing only the destination amount correctly enables the save button
- `convertedAmount()`, `convertToMainCurrency()`, and `convertTransactionToMainCurrency()` round results to 2 decimal places to prevent floating-point accumulation errors
- `exchangeRatesStaleProvider` in `exchange_rate_provider.dart` derives whether rates are more than 24 hours old; `TotalBalanceCard` shows a warning icon next to "TOTAL BALANCE" when rates are stale and multiple account currencies are in use

#### 22. Currency-aware daily group net amounts
- `TransactionGroup` now computes `netAmountInMainCurrency()`, `totalIncomeInMainCurrency()`, and `totalExpenseInMainCurrency()` by converting each transaction to the main currency before aggregating, replacing the previous raw-amount sum that produced incorrect totals when a group contained transactions in multiple currencies

#### 23. Converted amount subtitle in transaction lists
- Foreign-currency transactions display an "≈ $X,XXX" subtitle showing the main-currency equivalent beneath the transaction amount in the main transactions screen, the home screen recent transactions list, and the account detail screen; matches the existing subtitle pattern used on account cards

#### 24. Bug fix: duplicate transaction preserves currency fields
- Swipe-to-duplicate now copies `currencyCode`, `conversionRate`, `destinationAmount`, `mainCurrencyCode`, and `mainCurrencyAmount` to the new transaction and recomputes the conversion rate using current live exchange rates, preventing currency data from being silently dropped on duplication

#### 25. Bug fix: moveTransactionsToAccount correct mainCurrencyAmount
- Fixed `moveTransactionsToAccount` computing the wrong `mainCurrencyAmount` when the source and destination accounts have different currencies; now calls `convertToMainCurrency()` using the destination account's currency and updates both `conversionRate` and `mainCurrencyCode` on each moved transaction

#### 26. Multi-currency robustness improvements
- `Transaction.mainCurrencyAmount` is now `double?` instead of `double`, preventing legacy records with missing values from silently appearing as 0 and corrupting gain/loss calculations; `conversionGainLoss()` returns null when the field is null
- `roundCurrency(double value, {int decimals = 2})` added to `currency_conversion.dart` as a centralised rounding helper, replacing scattered `double.parse(x.toStringAsFixed(2))` patterns across the codebase
- Transaction form automatically refreshes exchange rates when a foreign-currency account is selected and rates are stale (>24h); a warning chip appears near the amount input while rates are stale
- `ConversionGainLossData` gains a `hasSkippedDueToMainCurrencyChange` flag; `ConversionGainLossCard` shows an info banner when some transactions were recorded under a different main currency and are excluded from the gain/loss total
- `conversionRate` field on `Transaction` and `TransactionFormState` is documented with dartdoc explaining the multiplier semantics: `amount * conversionRate ≈ mainCurrencyAmount`

#### 27. Shared balance calculation helper
- `calculateAccountDeltas()` in `lib/core/utils/balance_calculation.dart` computes the net balance change across a list of transactions for a given account, correctly debiting the source and crediting the destination for transfer transactions
- Used by `RecalculateBalancesNotifier` and `DatabaseConsistencyService` to eliminate duplicated (and previously incorrect) per-feature balance logic

#### 28. Account icon font family persistence
- `customIconFontFamily` and `customIconFontPackage` fields added to `AccountData` so custom icons from packages other than MaterialIcons are stored and restored correctly
- `AccountRepository._toAccount()` uses the stored font family/package instead of hardcoding 'MaterialIcons'; SQLite plaintext export/import, CSV export/import, and flexible CSV import updated to include these columns

#### 29. Recurring rules currency fields
- `currencyCode` and `destinationAmount` fields added to `RecurringRule`, `RecurringRuleData`, `RecurringRuleRepository`, form state, and form screen so recurring rules correctly carry currency information
- `generatePendingTransactions()` now computes and passes `currencyCode`, `conversionRate`, and `mainCurrencyAmount` when creating transactions from recurring rules; export/import updated for the new fields

#### 30. Balance reconciliation after import
- `DatabaseImportService._reconcileAccountBalances()` recalculates each account's balance from `initialBalance + calculateAccountDeltas(transactions)` immediately after every import
- Corrects any balance mismatches introduced by the imported data and emits warnings for each account that was adjusted

#### 33. Transaction form refactoring
- Confirmation dialogs for discard-changes and delete actions use the shared `showConfirmationDialog()` helper instead of raw AlertDialog
- Field-level validation: tapping Save with missing or invalid fields (amount, category, account, same-account transfer) shows inline error messages; Save button is always tappable and triggers validation on press
- Save logic (~190 lines) extracted from the widget into `TransactionFormNotifier.save()` returning a `SaveResult`
- Change tracking simplified from 12 separate `original*` fields to a single `Transaction? originalTransaction` in form state
- Build method decomposed into focused sub-widgets: `_TransactionTypeSelector`, `_AmountSection`, `_CategorySection`, `_AssetSection`, `_AccountSection`, `_SaveBar`
- `MerchantAutocomplete` extracted to `widgets/merchant_autocomplete.dart`; `CategoryPickerFormScreen` extracted to `widgets/category_picker_form_screen.dart`

#### 31. Corruption visibility
- `_lastCorruptedCount` tracking added to `AccountRepository`, `CategoryRepository`, `RecurringRuleRepository`, `SavingsGoalRepository`, `AssetRepository`, and `TransactionTemplateRepository`
- `corruption_status_provider.dart` aggregates counts across all repositories; `NavigationShell` shows a warning notification on startup when corruption is detected; `DatabaseSettingsScreen` displays the corruption count in the maintenance section

#### 32. Transaction data integrity fixes
- `TransactionFormState` gains `originalMainCurrencyAmount` and `originalMainCurrencyCode` tracking fields populated by `initForEdit()`; the save handler now conditionally preserves historical snapshots, only recalculating `mainCurrencyAmount`/`mainCurrencyCode` when amount, `currencyCode`, or `conversionRate` actually changed
- `isCrossCurrencyTransferProvider` added to `transaction_form_provider.dart`; the save handler blocks saving with an error notification when a transfer is cross-currency and `destinationAmount` is null; debug assertions in `transactions_provider.dart` catch the same condition at add/update time
- All three import paths in `DatabaseImportService` (`_importTransactionsFromSqlite`, `_importTransactionsFromCsv`, `_importTransactionsFromCsvSkipDuplicates`) now preserve null `mainCurrencyAmount` instead of fabricating a value with `roundCurrency(amount * conversionRate)`
- Individual `double.parse`/`int.parse` calls in both CSV import methods are wrapped in field-specific try-catch blocks, surfacing granular error messages for amount, conversionRate, destinationAmount, mainCurrencyAmount, dateMillis, createdAtMillis, date, and lastUpdatedAt
- `DeletedTransactionsScreen` converted to `ConsumerStatefulWidget`; after deleted transactions load it checks `repo.lastCorruptedCount > 0` and shows a warning notification listing how many corrupted transactions could not be loaded

#### 34. UI and design system consistency improvements
- Extended `AppRadius` with `xxs`, `xxsAll`, and `iconButton` constants, and added `AppSpacing` constants for settings back button, toggle, badge, and notification sizes, replacing all hardcoded `BorderRadius.circular(N)` values across 50+ files
- New reusable `SettingsHeader` widget (`lib/design_system/components/layout/settings_header.dart`) replaces the duplicated back-button + title pattern across 19 screens; accepts `title`, optional `onBack` callback, and optional `actions` list
- `Notification` widget now reads `ColorIntensity` from settings and applies intensity-aware colors instead of hardcoded zen-palette values
- `CircularButton`, `IconBtn`, and `Toggle` widgets accept an optional `semanticLabel` parameter and wrap their content in a `Semantics` widget for accessibility; `textTertiary` color changed from `0xFF5A5A5A` to `0xFF787878` for WCAG AA contrast compliance
- `ScreenHeader` refactored to use `CircularButton` internally, eliminating a duplicated container pattern

#### 35. Credential hashing
- PIN codes and passwords are stored as SHA-256 hashes instead of plaintext
- `CredentialHasher` utility (`lib/core/utils/credential_hasher.dart`) handles hashing and verification
- Legacy plaintext credentials are auto-migrated to hashed form on app startup
- 11 unit tests cover hashing, verification, legacy fallback, and edge cases

#### 36. New button variants
- `SecondaryButton` (outlined style) added to the design system at `lib/design_system/components/buttons/`
- `DestructiveButton` (red, available in filled or outlined style) added for destructive actions

#### 37. Map-based provider lookups
- `accountByIdProvider` and `categoryByIdProvider` now derive from computed `accountMapProvider` and `categoryMapProvider` (`Map<String, T>`)
- Lookup cost reduced from O(n) list scan to O(1) map access

#### 38. Single MaterialApp architecture
- Eliminated dual `MaterialApp` pattern; shared theme via `CachiumApp._theme`
- `SystemChrome` configuration moved from `build()` to `main()` for correct single-time initialization

#### 39. Additional database indexes
- Schema version bumped to 18 with composite indexes on `(is_deleted, date)` for the transactions table and `is_deleted` indexes for all other entity tables
- Reduces query cost for the common filtered-by-deletion-status access pattern

#### 40. Settings optimistic updates with rollback
- Settings provider applies changes optimistically and rolls back to the previous state if the persistence call fails
- Account form and savings goals screens wrapped in try-catch blocks that show error notifications on failure

#### 41. PopScope discard confirmation on account form
- Navigating back from the account form with unsaved changes shows a "Discard changes?" confirmation dialog, preventing accidental data loss

#### 42. Atomic category reassignment
- Deleting a category with transaction reassignment is now wrapped in a single database transaction, ensuring no partial state if the operation fails mid-way

#### 43. Export temp file cleanup
- Previous export temp files are deleted before a new export is created, preventing stale files from accumulating in the temp directory

#### 44. Import amount validation
- Transaction amounts are validated as non-negative during import; negative values are rejected with a descriptive error rather than silently imported

#### 45. Tags / Labels
- Cross-cutting transaction classification system independent of categories
- Create tags with custom name, color, and icon; manage from Settings > Tags
- Assign multiple tags to a transaction via a multi-select chip selector in the transaction form
- Tags displayed on the transaction details screen
- Full CRUD with drag-and-drop reorder support
- Tag metadata stored in encrypted blob storage; transaction-tag relationships stored in a plaintext junction table

#### 46. Notifications & Reminders
- Local notification system using flutter_local_notifications and timezone packages
- Budget threshold alerts: fires when spending reaches a user-configured percentage of a budget
- Recurring transaction reminders: notifies a configurable number of days before a recurring transaction is due
- Optional weekly spending summary notification
- Configurable from Settings > Notifications
- NotificationLog table tracks sent notifications to prevent duplicate alerts

#### 47. Receipt / Photo Attachments
- Attach receipt photos to transactions via camera or gallery picker
- Images saved to the app documents directory; auto-generated thumbnails (~200 px JPEG) for list display
- Full-screen InteractiveViewer for viewing attachments, with swipe-between-images support
- Storage usage viewable from Settings > Storage
- Attachment metadata stored in encrypted blob; image files stored on disk
- Optional per-file encryption setting available

#### 48. Account Reordering
- Drag-and-drop reordering of accounts within each type group on the Accounts screen
- `sortOrder` field added to Account model; DB migration v22 adds `sort_order` column
- Reorder mode toggled via a button on the Accounts screen; drag handles shown in reorder mode
- `reorderAccount()` method on `AccountsNotifier` persists the new order

#### 49. Customizable Home Dashboard
- Home screen sections can be individually reordered and toggled on/off
- `homeSectionOrder` (List<String>) and `homeShowBudgetProgress` (bool) added to AppSettings
- HomeSettingsScreen redesigned with ReorderableListView showing drag handles and visibility toggles
- HomeScreen dynamically renders sections based on saved order and visibility settings

#### 50. Undo for Bulk Actions
- Bulk category change and bulk account change on the Transactions screen now show undo notifications
- Before applying the change, original category/account IDs are captured
- The undo callback restores all affected transactions to their previous category or account, including balance adjustments for account changes

#### 51. Category Merge
- Categories can be merged into another category of the same type
- `mergeCategory(sourceId, targetId)` on `CategoriesNotifier` reassigns transactions, moves subcategories under the target, and soft-deletes the source in a single DB transaction
- "Merge into..." button added to `CategoryFormModal` in edit mode
- Merge picker uses `BulkPickerSheet` with a confirmation dialog showing affected transaction and subcategory counts

#### 52. Quick-add from Notification
- Notification action buttons ("Add Expense" / "Add Income") attached to weekly summary and recurring reminder notifications
- `NotificationService` configured with Android action buttons and iOS notification categories
- An action stream broadcasts tapped notification actions; the main app listens and navigates to the transaction form with the transaction type pre-selected

#### 53. Bill Reminders / Due Date Tracking
- Track upcoming bills with due dates, amounts, and recurrence frequency via a dedicated bills feature module at `lib/features/bills/`
- Mark a bill as paid to auto-create a transaction and generate the next bill occurrence
- Per-bill reminder settings and overdue tracking
- Home screen shows upcoming bills; manageable from Settings > Bills
- Routes: `/settings/bills`, `/bill/new`, `/bill/:id/edit`

#### 54. Biometric Unlock Enhancement
- Configurable auto-lock timeout: immediate, 30 seconds, 1 minute, 5 minutes, 15 minutes, or never
- Toggle to enable or disable biometric unlock independently of the timeout
- Background timer tracks app lifecycle to enforce timeout-based locking

#### 55. Full-Text Search Enhancement
- Unified search across transactions (notes, merchants, amounts), accounts, categories, and tags
- Recent search history: last 10 queries persisted across sessions
- Filter chips (All, Transactions, Accounts, Categories, Tags) to narrow results by type
- Results grouped by type with counts; matched text highlighted; debounced 300 ms input

#### 56. Budget Rollover
- Per-budget `rolloverEnabled` flag carries unused budget forward up to 12 months
- Effective budget = base amount + accumulated rollover; overspending produces zero rollover
- Toggle per budget in budget settings; rollover amount displayed in the budget progress view

#### 57. Performance Optimizations
- Analytics sections lazy-load: first 3 sections render immediately, the rest load on scroll
- Transaction list pagination at 50 items per page with infinite scroll
- Analytics providers cached with `ref.keepAlive()` to avoid redundant recalculation

#### 21. Historical main currency value storage
- `mainCurrencyCode` and `mainCurrencyAmount` fields added to Transaction model and TransactionData DTO to snapshot the main-currency equivalent at the moment a transaction is saved
- Transaction form computes and persists these fields on save; old records fall back to a calculated value via `conversionRate` for backward compatibility
- Transaction detail screen shows "Original Value" (the snapshotted main-currency amount) and "Rate Change" (gain/loss since creation) for foreign-currency transactions
- Account detail screen aggregates and displays "Currency Impact" for foreign-currency accounts, summarising total conversion gain/loss
- New `conversionGainLoss()` utility in `currency_conversion.dart` computes the difference between the historical and current converted values
- Analytics Overview tab gains a "Conversion Gain/Loss" card (`ConversionGainLossCard`) driven by `conversionGainLossProvider`, showing the total conversion impact across all foreign-currency transactions in the selected period
- Export/import updated to include `main_currency_code` and `main_currency_amount` columns with fallback defaults for older files; demo data seeded with these fields

#### 58. PopScope Unsaved-Work Detection
- RecurringRuleFormScreen, TransactionTemplateFormScreen, CategoryFormModal, and AssetFormModal now wrap their Scaffold in PopScope
- Navigating back with unsaved changes triggers a "Discard changes?" confirmation dialog, preventing accidental data loss

#### 59. Orphaned Record Cleanup
- Database migration v24 adds a `cleanupOrphanedRecords()` method to AppDatabase
- Removes orphaned `transaction_tags` and attachment records where the parent transaction or tag no longer exists

#### 60. Exchange Rate API Rate Limiting
- ExchangeRateService enforces a 5-minute minimum interval between API calls
- Repeated calls within the throttle window return cached rates; a `canFetch` getter exposes throttle status to the UI

#### 61. Onboarding Tutorial
- 4-page tutorial screen (TutorialScreen) shown after welcome/onboarding for new users
- Covers: Track Transactions, Manage Accounts, Set Budgets, View Analytics
- Can be skipped or completed; completion state persisted via `tutorialCompleted` setting

#### 62. Financial Calendar Screen
- Standalone monthly calendar grid accessible via a calendar icon in the home screen header
- Each day shows mini income/expense amounts with intensity-based background color shading
- Bill due date indicators displayed on relevant days
- Tapping a day opens a detail panel listing that day's transactions
- Independent of analytics filters

#### 63. Auto-Categorization by Merchant
- When creating a new transaction, typing a previously used merchant name automatically suggests the most frequently used category for that merchant
- A subtle "Auto-selected from merchant" hint displays below the category field when auto-filled; manual category selection overrides it
- Configurable via Settings > Transactions > "Auto-categorize by Merchant" (default: on)

#### 64. Advanced Transaction Filters
- Expandable filter panel on the transactions list, toggled via a sliders icon next to the search bar
- Filters include: amount range (min/max), date range picker, category multi-select, and account multi-select
- An active filter count badge shows on the filter icon; "Clear All Filters" resets all active filters at once

#### 65. Net Worth History (Persistent Snapshots)
- Monthly net worth snapshots are automatically recorded to the database; up to 12 months of history are backfilled from existing transaction data on first launch
- A new "Net Worth History" screen (accessible via "Full History" on the Analytics net worth chart) displays a full-timeline chart with holdings, liabilities, and net worth lines, current net worth with month-over-month trend, and a monthly breakdown list
- Database schema bumped to v25 with a new NetWorthSnapshots table

#### 66. Asset Acquisition Cost Flag
- `isAcquisitionCost` boolean field added to the Transaction model to mark transactions auto-created from the asset purchase or sale flow
- `assetCostBreakdownProvider` uses this flag instead of fragile note string-matching to identify acquisition costs; legacy note-matching retained as a fallback for older records
- DB schema bumped to v27; Transaction model, TransactionData DTO, repository, form provider, transactions provider, asset analytics providers, and export/import services all updated

#### 67. Asset-Bill Linking
- Bills can now be linked to an asset via an optional `assetId` field on the Bill model
- When a linked bill is paid, the auto-created transaction inherits the bill's `assetId`; the next recurring bill also preserves the asset link
- A "Linked Bills" section on the asset detail screen shows all upcoming bills tied to that asset
- The bill form screen includes an optional asset selector; `billsByAssetProvider` added for fetching bills filtered by asset

#### 68. Asset Detail Time Range Filtering
- A time range selector (All Time / This Year / Last 12 Months / Custom) appears below the hero card on the asset detail screen
- All analytics on the screen — monthly spending, cumulative cost, category breakdown, cost breakdown, stats, and transactions by month — are driven by a new `filteredTransactionsByAssetProvider` that respects the selected date range
- `assetDetailDateRangeProvider` manages the selected range; the asset list screen continues to use all-time data

---