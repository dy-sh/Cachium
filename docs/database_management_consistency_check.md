# Database Consistency Check

## Table of Contents

1. [Overview](#overview)
2. [Consistency Checks](#consistency-checks)
3. [Architecture](#architecture)
4. [User Interface](#user-interface)
5. [Implementation Details](#implementation-details)
6. [When Consistency Refreshes](#when-consistency-refreshes)

---

## Overview

The Database Consistency Check feature validates the integrity of data relationships and calculated values in the Cachium database. It detects orphaned records, invalid references, and data inconsistencies that could occur due to bugs, failed operations, or corrupted imports.

The feature is accessible via **Settings → Database** in the Metrics section, displayed as a card below the Database Metrics card.

---

## Consistency Checks

The system performs the following checks:

### 1. Transactions with Invalid Category

**What it checks:** Transactions where `categoryId` references a category that doesn't exist in the database.

**How it can happen:**
- Category was deleted but transactions weren't updated
- Database import with mismatched IDs
- Data corruption

**Icon:** Tag

### 2. Transactions with Invalid Account

**What it checks:** Transactions where `accountId` references an account that doesn't exist in the database.

**How it can happen:**
- Account was deleted but transactions weren't updated
- Database import with mismatched IDs
- Data corruption

**Icon:** Wallet

### 3. Duplicate Transactions

**What it checks:** Transactions that have the same date/time (down to milliseconds) AND the same amount.

**How it can happen:**
- Double-tap on save button
- Import of duplicate records
- Bug in transaction creation

**Note:** The app prevents this by assigning unique timestamps (including seconds and milliseconds) to each transaction at creation time. When editing, the original timestamp is preserved.

**Icon:** Copy

### 4. Categories with Invalid Parent

**What it checks:** Categories where `parentId` references a parent category that doesn't exist.

**How it can happen:**
- Parent category was deleted but child wasn't updated
- Database import with mismatched hierarchy
- Data corruption

**Icon:** Folder Tree

### 5. Accounts with Incorrect Balance

**What it checks:** Accounts where the stored `balance` doesn't match the calculated balance.

**Calculation formula:**
```
expectedBalance = initialBalance + sum(income transactions) - sum(expense transactions)
```

**How it can happen:**
- Transaction was modified without updating account balance
- Bug in balance calculation
- Race condition during concurrent operations

**Tolerance:** 0.001 (to handle floating-point precision issues)

**Icon:** Calculator

---

## Architecture

### Files Structure

```
lib/
├── core/database/services/
│   └── database_consistency_service.dart    # Service performing checks
├── features/settings/
│   ├── data/models/
│   │   └── database_consistency.dart        # Data models
│   └── presentation/
│       ├── providers/
│       │   └── database_providers.dart      # Providers (modified)
│       ├── screens/
│       │   └── database_settings_screen.dart # Screen (modified)
│       └── widgets/
│           ├── database_consistency_card.dart    # Main UI card
│           └── consistency_details_dialog.dart   # Details popup
```

### Data Models

#### ConsistencyCheck

Represents a single check result:

```dart
class ConsistencyCheck {
  final String label;    // Display name
  final int count;       // Number of issues found
  final IconData icon;   // Icon for display

  bool get hasIssues => count > 0;
}
```

#### DatabaseConsistency

Aggregates all check results:

```dart
class DatabaseConsistency {
  final int transactionsWithInvalidCategory;
  final int transactionsWithInvalidAccount;
  final int categoriesWithInvalidParent;
  final int accountsWithIncorrectBalance;
  final int duplicateTransactions;

  bool get isConsistent => totalIssues == 0;
  int get totalIssues => /* sum of all counts */;
  List<ConsistencyCheck> get allChecks => /* all checks with icons */;
  List<ConsistencyCheck> get issueChecks => /* only checks with issues */;
}
```

### Providers

```dart
// Service provider
final databaseConsistencyServiceProvider = Provider<DatabaseConsistencyService>(...);

// Async data provider
final databaseConsistencyProvider = FutureProvider<DatabaseConsistency>(...);
```

---

## User Interface

### Consistency Card States

#### All Data Consistent (Green)

```
┌─────────────────────────────────────────┐
│ [✓]  Data Consistency                   │
│      All data consistent                │
│      tap for details                    │
└─────────────────────────────────────────┘
```

- Green checkmark icon
- "All data consistent" message
- Tap opens details dialog showing all checks with zero counts

#### Issues Found (Red, Collapsed)

```
┌─────────────────────────────────────────┐
│ [⚠]  Data Consistency               [>] │
│      3 issues found                     │
│      tap for details                    │
└─────────────────────────────────────────┘
```

- Red alert triangle icon
- Shows total issue count
- Chevron to expand inline list
- Tap opens details dialog

#### Issues Found (Red, Expanded)

```
┌─────────────────────────────────────────┐
│ [⚠]  Data Consistency               [v] │
│      3 issues found                     │
│      tap for details                    │
├─────────────────────────────────────────┤
│ Transactions with invalid category   2  │
│ Duplicate transactions               1  │
└─────────────────────────────────────────┘
```

- Shows only checks that have issues
- Counts displayed in red

### Details Dialog

```
┌─────────────────────────────────────────┐
│ [✓/⚠]  Consistency Details              │
├─────────────────────────────────────────┤
│ [tag]    Transactions with invalid...  0│
│ [wallet] Transactions with invalid...  2│
│ [copy]   Duplicate transactions        0│
│ [tree]   Categories with invalid...    0│
│ [calc]   Accounts with incorrect...    1│
├─────────────────────────────────────────┤
│                              [ Close ]  │
└─────────────────────────────────────────┘
```

- Shows ALL checks (including zeros)
- Icon for each check type
- Count colored green (0) or red (>0)
- Header icon matches overall status

---

## Implementation Details

### DatabaseConsistencyService

The service performs all checks in a single method:

```dart
Future<DatabaseConsistency> checkConsistency() async {
  // 1. Fetch all data (already decrypted by repositories)
  final transactions = await transactionRepository.getAllTransactions();
  final accounts = await accountRepository.getAllAccounts();
  final categories = await categoryRepository.getAllCategories();

  // 2. Build valid ID sets for lookups
  final validAccountIds = accounts.map((a) => a.id).toSet();
  final validCategoryIds = categories.map((c) => c.id).toSet();

  // 3. Check transaction references
  for (final tx in transactions) {
    if (!validCategoryIds.contains(tx.categoryId)) {
      transactionsWithInvalidCategory++;
    }
    if (!validAccountIds.contains(tx.accountId)) {
      transactionsWithInvalidAccount++;
    }
  }

  // 4. Check for duplicates (same timestamp + amount)
  final Map<String, int> transactionKeys = {};
  for (final tx in transactions) {
    final key = '${tx.date.millisecondsSinceEpoch}_${tx.amount}';
    transactionKeys[key] = (transactionKeys[key] ?? 0) + 1;
  }
  for (final count in transactionKeys.values) {
    if (count > 1) duplicateTransactions += count;
  }

  // 5. Check category hierarchy
  for (final category in categories) {
    if (category.parentId != null &&
        !validCategoryIds.contains(category.parentId)) {
      categoriesWithInvalidParent++;
    }
  }

  // 6. Check account balances
  // Calculate expected balances from transactions
  final Map<String, double> accountDeltas = {};
  for (final tx in transactions) {
    final delta = tx.type == income ? tx.amount : -tx.amount;
    accountDeltas[tx.accountId] = (accountDeltas[tx.accountId] ?? 0) + delta;
  }

  for (final account in accounts) {
    final expected = account.initialBalance + (accountDeltas[account.id] ?? 0);
    if ((account.balance - expected).abs() > 0.001) {
      accountsWithIncorrectBalance++;
    }
  }

  return DatabaseConsistency(...);
}
```

### Time Selection in Transaction Editor

The transaction editor includes both date and time selection to give users precise control over transaction timestamps.

#### UI Layout

```
┌─────────────────────────────────────────────────────┐
│ Date                                                │
├─────────────────────────────────────────────────────┤
│ [Today] [Yesterday] [Start of Month] [Custom]       │
├─────────────────────────────────────────────────────┤
│ ┌─────────────────────────────┐ ┌─────────────────┐ │
│ │ [📅] January 21, 2026    [>]│ │ [🕐] 14:35      │ │
│ └─────────────────────────────┘ └─────────────────┘ │
│        Date Field                  Time Field       │
└─────────────────────────────────────────────────────┘
```

#### Quick Date Options

- **Today** - Sets date to current day with current time (hour:minute)
- **Yesterday** - Sets date to previous day with current time
- **Start of Month** - Sets date to first day of current month with current time
- **Custom** - Opens date picker calendar

#### Time Picker

Tapping the time field opens the native time picker allowing selection of hours and minutes.

#### How Timestamps Work

> **Important:** The time selection system is designed to prevent false duplicate detection in the consistency check.

Since duplicate detection uses the full timestamp (including seconds and milliseconds), the editor ensures each transaction gets a unique timestamp:

| Scenario | Date | Time (H:M) | Seconds/Milliseconds |
|----------|------|------------|----------------------|
| New transaction opened | Current | Current | Current (set once at form open) |
| Quick date selected | Selected | Current | Preserved from form open |
| Custom date selected | Selected | Preserved | Preserved from form open |
| Time picker used | Preserved | Selected | Preserved from form open |
| Editing existing transaction | Original | Original | Original (never changed) |

**Key principle:** Seconds and milliseconds are set **once** when the form opens and **never changed** during editing. This ensures:

1. Each new transaction gets a unique timestamp based on when the editor was opened
2. Editing a transaction preserves its original timestamp exactly
3. Changing date/time and then changing it back won't mark the form as "changed"
4. No false positives in duplicate detection

#### Implementation

```dart
// Form provider initializes with current timestamp (new transaction)
TransactionFormState build() {
  return TransactionFormState(
    date: DateTime.now(),  // Includes seconds/milliseconds
    ...
  );
}

// DateSelector preserves seconds/milliseconds on all changes
DateTime _withCurrentTime(DateTime dateOnly) {
  final now = DateTime.now();
  return DateTime(
    dateOnly.year,
    dateOnly.month,
    dateOnly.day,
    now.hour,
    now.minute,
    date.second,       // Preserved from form state
    date.millisecond,  // Preserved from form state
  );
}

DateTime _combineDateTime(DateTime selectedDate, TimeOfDay time) {
  return DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    time.hour,
    time.minute,
    date.second,       // Preserved from form state
    date.millisecond,  // Preserved from form state
  );
}
```

#### Change Detection for Edit Mode

When editing an existing transaction, the Save button is only enabled if something actually changed. Date comparison ignores seconds/milliseconds:

```dart
bool _isSameDateTime(DateTime a, DateTime? b) {
  if (b == null) return false;
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
  // Seconds/milliseconds intentionally ignored
}
```

This means users can tap around the date/time selectors without accidentally enabling the Save button if they end up with the same hour and minute as the original.

---

## When Consistency Refreshes

The consistency check is automatically refreshed:

| Action | Refreshes Consistency |
|--------|----------------------|
| Open Database Settings screen | ✓ |
| Delete database | ✓ |
| Create demo database | ✓ |
| Import SQLite | ✓ |
| Import CSV | ✓ |
| Recalculate balances | ✓ |
| Add/edit/delete transaction | ✗ (on next screen open) |

The refresh is triggered by calling `ref.invalidate(databaseConsistencyProvider)` in the relevant notifiers.

### Screen Open Refresh

```dart
class _DatabaseSettingsScreenState extends ConsumerState<DatabaseSettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(databaseConsistencyProvider);
    });
  }
}
```

---

## Future Improvements

Potential enhancements:

1. **Auto-fix capabilities:** Button to automatically fix certain issues (e.g., recalculate all balances, remove orphaned references)
2. **Detailed issue list:** Show which specific transactions/categories have issues
3. **Background checking:** Periodic consistency checks with notifications
4. **Export inconsistency report:** Generate report for debugging
