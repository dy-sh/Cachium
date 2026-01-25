## Database Management & Export/Import

### Overview

The app provides database management features for data portability and backup:

- **Metrics Display**: View counts and timestamps of all data
- **Delete Database**: Wipe all data with optional settings reset
- **Demo Database**: Seed sample data for testing
- **Export**: SQLite or CSV format with encryption toggle
- **Import**: Auto-detects format and re-encrypts into current database

### Export Format Matrix

Both SQLite and CSV exports support the same encryption toggle:

| Encryption | Format |
|------------|--------|
| **ON** (default) | Plaintext metadata (id, date, lastUpdatedAt, isDeleted) + `encryptedBlob` column (Base64 for CSV) |
| **OFF** | Plaintext metadata + separate columns for each field (amount, categoryId, accountId, type, note, etc.) |

**Why offer plaintext export?**
- Allows data migration to other apps
- Enables spreadsheet analysis in Excel/Google Sheets
- Provides human-readable backups
- Still requires physical access to device to export

### Deleted Records Handling

The app uses soft-delete (`isDeleted` flag) rather than hard-delete. Export behavior differs by format:

| Export Type | Deleted Records | `is_deleted` Column |
|-------------|-----------------|---------------------|
| SQLite (encrypted) | Included | Yes |
| SQLite (plaintext) | Included | Yes |
| CSV (encrypted) | Included | Yes |
| CSV (plaintext) | **Skipped** | **No** |

**Why skip deleted records in plaintext CSV?**

1. **User intent**: Plaintext CSV is for spreadsheet analysis or migration to other apps. Users expect to see their active data, not soft-deleted records they've already removed.

2. **Cleaner output**: No confusing `is_deleted=0` column that's always the same value.

3. **Sync is separate**: The app's sync architecture uses `enc_event_log` (append-only log in Supabase), not file exports. Skipping deleted records in CSV doesn't affect sync.

4. **Full backup still available**: Users who need complete data (including deleted records) can use:
   - SQLite export (encrypted or plaintext) - includes all records
   - CSV encrypted export - includes all records

**When deleted records matter:**

| Use Case | Need Deleted? | Recommended Export |
|----------|---------------|-------------------|
| Spreadsheet analysis | No | CSV plaintext |
| Migration to other apps | No | CSV plaintext |
| Fresh restore/backup | No | CSV plaintext |
| Full forensic backup | Yes | SQLite (any) |
| Manual merge with existing data | Maybe | SQLite plaintext |

### Export Services Architecture

```
lib/core/database/services/
├── database_metrics_service.dart   # Query counts and timestamps
├── database_export_service.dart    # SQLite and CSV export
└── database_import_service.dart    # SQLite and CSV import with format detection
```

### Export Database Schema

**Encrypted format** (encryption ON):
```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  date INTEGER NOT NULL,
  lastUpdatedAt INTEGER NOT NULL,
  isDeleted INTEGER NOT NULL DEFAULT 0,
  encryptedBlob BLOB NOT NULL          -- Same as internal storage
);
```

**Plaintext format** (encryption OFF):
```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  date INTEGER NOT NULL,
  lastUpdatedAt INTEGER NOT NULL,
  isDeleted INTEGER NOT NULL DEFAULT 0,
  amount REAL NOT NULL,                 -- Decrypted fields
  categoryId TEXT NOT NULL,
  accountId TEXT NOT NULL,
  type TEXT NOT NULL,
  note TEXT,
  currency TEXT NOT NULL DEFAULT 'USD',
  createdAtMillis INTEGER NOT NULL
);
```

### Import Format Detection

Imports automatically detect the format by examining the schema:

```dart
bool _hasEncryptedBlob(Database db, String tableName) {
  final result = db.select("PRAGMA table_info($tableName)");
  for (final row in result) {
    if (row['name'] == 'encryptedBlob') {
      return true;  // Encrypted format
    }
  }
  return false;  // Plaintext format
}
```

**Import always re-encrypts** data into the current database's encrypted format, regardless of the source format.

**Optional `is_deleted` column:** When importing plaintext CSV (without `encrypted_blob`), the `is_deleted` column is optional. If missing, records default to `isDeleted = false`. This allows seamless round-trip export/import of plaintext CSVs which skip deleted records.

### CSV Export Details

CSV export creates 4 separate files:
- `transactions.csv`
- `accounts.csv`
- `categories.csv`
- `app_settings.csv`

Each follows the same encryption toggle logic. For encrypted format, the `encryptedBlob` is Base64-encoded.

**Plaintext CSV columns** (encryption OFF, deleted records excluded):

| File | Columns |
|------|---------|
| transactions.csv | `id, date, last_updated_at, amount, category_id, account_id, type, note, currency` |
| accounts.csv | `id, created_at, last_updated_at, name, type, balance, initial_balance, custom_color_value, custom_icon_code_point` |
| categories.csv | `id, sort_order, last_updated_at, name, icon_code_point, icon_font_family, icon_font_package, color_index, type, is_custom, parent_id` |
| app_settings.csv | `id, last_updated_at, json_data` |

**Encrypted CSV columns** (encryption ON, all records included):

| File | Columns |
|------|---------|
| transactions.csv | `id, date, last_updated_at, is_deleted, encrypted_blob` |
| accounts.csv | `id, created_at, last_updated_at, is_deleted, encrypted_blob` |
| categories.csv | `id, sort_order, last_updated_at, is_deleted, encrypted_blob` |
| app_settings.csv | `id, last_updated_at, json_data` |

### Database Management Operations

**Delete All Data:**
```dart
await database.deleteAllData(includeSettings: resetSettings);
```

**Seed Demo Database:**
```dart
// Delete existing data
await database.deleteAllData(includeSettings: false);

// Seed from DemoData
for (final account in DemoData.accounts) {
  await accountRepo.createAccount(account);
}
// ... categories and transactions
```

### Security Considerations for Export

| Scenario | Security |
|----------|----------|
| Encrypted export on secure device | Full protection - blob cannot be read |
| Encrypted export shared via email | Protected - requires matching encryption key |
| Plaintext export on secure device | Data visible but requires device access |
| Plaintext export shared externally | **No protection** - treat as sensitive file |

The app defaults to encrypted export and shows a warning when encryption is disabled.