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

### CSV Export Details

CSV export creates 3 separate files:
- `transactions.csv`
- `accounts.csv`
- `categories.csv`

Each follows the same encryption toggle logic. For encrypted format, the `encryptedBlob` is Base64-encoded.

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