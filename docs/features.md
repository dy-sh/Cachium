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

#### 52. Dark theme
- Single dark theme (no light mode)
- Material Design 3 base
- Dark surface backgrounds throughout

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

---