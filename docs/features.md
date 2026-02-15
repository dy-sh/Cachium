# Implemented Features

## New Features

### High Impact

#### 1. Transfers between accounts
- Added `transfer` transaction type with source/destination account
- Dedicated UI in transaction form with "From Account" / "To Account" selectors
- 3-way toggle (Income / Expense / Transfer) in form
- Transfer filter on transactions screen
- Transfer display across home, transactions, and account detail screens
- Balance logic: debits source account, credits destination account

#### 2. Budget alerts & progress
- Budget progress bars on home screen (top 3 budgets)
- Color-coded indicators: green (<75%), yellow (75-100%), red (>100%)
- Shows spent / budget amount with progress bar

---

## UX Polish

### High Impact

#### 3. Onboarding flow
- Already existed: WelcomeScreen with 3 setup options (Demo Data, Quick Start, Start from Scratch)
- Import from Backup option
- `onboardingCompleted` flag and `shouldShowWelcomeProvider` gate

#### 4. Drag-to-reorder categories
- Already existed: drag handles in Settings > Categories
- `sortOrder` field persisted via updates

#### 5. Bulk edit transactions
- Bulk re-categorize via modal bottom sheet picker
- Bulk change account via modal bottom sheet picker
- Action buttons in selection header bar

#### 6. Swipe actions on transactions
- Swipe-left to delete (with undo notification)
- Swipe-right to duplicate (creates copy with today's date)

#### 7. Pull-to-refresh
- Added `RefreshIndicator` to transactions screen, home screen, and accounts screen
- Styled with app theme colors

### Medium Impact

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

### Nice to Have

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
