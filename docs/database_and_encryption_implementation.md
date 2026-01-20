# Database and Encryption System

## Table of Contents

1. [Overview](#overview)
2. [The Idea](#the-idea)
3. [Core Principles](#core-principles)
4. [Design Decisions](#design-decisions)
5. [Security Model](#security-model)
6. [Implementation Details](#implementation-details)
7. [Data Flow](#data-flow)
8. [Future Considerations](#future-considerations)

---

## Overview

Cachium implements a **Zero-Knowledge Architecture** for storing sensitive financial data. This means that even if the database file is compromised, or in future stages when data syncs to a cloud server (Supabase), the server and any potential attackers can only see encrypted blobs - they cannot read the actual transaction details like amounts, categories, or notes.

The system uses **client-side encryption** with AES-256-GCM, where encryption keys never leave the user's device. The database stores a mix of plaintext metadata (for querying) and encrypted blobs (for sensitive data).

---

## The Idea

### Problem Statement

Personal finance apps handle extremely sensitive data:
- Transaction amounts reveal spending habits
- Categories expose lifestyle choices
- Notes may contain personal details
- Account information is financially sensitive

Traditional approaches either:
1. Store everything in plaintext (convenient but insecure)
2. Encrypt the entire database file (secure but prevents server-side operations)
3. Use server-managed encryption (secure in transit but server can read data)

### Our Solution

We implement **application-layer encryption** with a hybrid storage model:

```
┌─────────────────────────────────────────────────────────────┐
│                      Database Row                           │
├─────────────────┬───────────────────────────────────────────┤
│   PLAINTEXT     │              ENCRYPTED BLOB               │
├─────────────────┼───────────────────────────────────────────┤
│ • id            │ • amount                                  │
│ • date          │ • categoryId                              │
│ • lastUpdatedAt │ • accountId                               │
│ • isDeleted     │ • type (income/expense)                   │
│                 │ • note                                    │
│                 │ • currency                                │
│                 │ • id (duplicated for integrity)           │
│                 │ • dateMillis (duplicated for integrity)   │
│                 │ • createdAtMillis                         │
└─────────────────┴───────────────────────────────────────────┘
```

**Plaintext fields** enable:
- Efficient date-range queries and sorting
- Unique identification without decryption
- Sync conflict resolution (Last-Write-Wins)
- Soft delete propagation

**Encrypted blob** protects:
- All financially sensitive information
- Personal notes and memos
- Category and account associations

---

## Core Principles

### 1. Zero-Knowledge Architecture

The server (current: local SQLite, future: Supabase) should never have access to decrypted financial data. Even database administrators, backup systems, or potential attackers who gain database access cannot read sensitive information.

```
User Device                          Server/Database
┌──────────────┐                    ┌──────────────┐
│              │                    │              │
│  Plaintext   │ ───► Encrypt ───►  │  Encrypted   │
│  Transaction │                    │    Blob      │
│              │ ◄─── Decrypt ◄───  │              │
│              │                    │              │
└──────────────┘                    └──────────────┘
     Keys never leave device
```

### 2. Defense in Depth

Multiple security layers protect data:

1. **Encryption at rest**: AES-256-GCM encrypts sensitive fields
2. **Integrity verification**: Duplicated fields detect tampering
3. **Authenticated encryption**: GCM mode prevents undetected modifications
4. **Key isolation**: Keys stored separately from encrypted data

### 3. Minimal Plaintext Exposure

Only the absolute minimum data required for functionality is stored in plaintext:

| Field | Why Plaintext? |
|-------|----------------|
| `id` | Primary key for lookups, foreign key references |
| `date` | Sorting, date-range filtering, timeline views |
| `lastUpdatedAt` | Sync conflict resolution (LWW strategy) |
| `isDeleted` | Soft delete for sync propagation |

Everything else is encrypted, even if it might be convenient to query (like category or amount).

### 4. Eventual Sync Readiness

The schema is designed for future cloud synchronization:

- **Soft deletes**: `isDeleted` flag instead of hard deletes allows sync to propagate deletions
- **LWW timestamps**: `lastUpdatedAt` enables Last-Write-Wins conflict resolution
- **Stable IDs**: UUIDs ensure no conflicts between devices
- **Blob opacity**: Server can store/sync encrypted blobs without understanding contents

---

## Design Decisions

### Why AES-256-GCM?

We chose AES-256-GCM (Galois/Counter Mode) for several reasons:

1. **Authenticated Encryption**: GCM provides both confidentiality AND integrity. If anyone modifies the ciphertext, decryption fails with an authentication error.

2. **Industry Standard**: AES-256 is approved by NIST and used by governments and financial institutions worldwide.

3. **Performance**: GCM mode is highly efficient, especially on modern processors with AES-NI instructions.

4. **No Padding Oracle Attacks**: Unlike CBC mode, GCM is not vulnerable to padding oracle attacks.

```
Encryption Process:
┌──────────┐     ┌─────────┐     ┌────────────────────────────┐
│ Plaintext│ ──► │ AES-GCM │ ──► │ Nonce + Ciphertext + MAC   │
│   JSON   │     │   256   │     │    (12)    (var)    (16)   │
└──────────┘     └─────────┘     └────────────────────────────┘
                      ▲
                      │
                 Secret Key (32 bytes)
```

### Why Encrypt JSON, Not Individual Fields?

We serialize the entire `TransactionData` object to JSON, then encrypt the JSON string:

**Advantages:**
- Simpler implementation - one encryption operation per record
- Flexible schema - adding new fields doesn't require database migration
- Consistent security - no risk of forgetting to encrypt a sensitive field
- Smaller overhead - one nonce/MAC per record instead of per field

**Trade-offs:**
- Cannot query encrypted fields (acceptable - we query by date primarily)
- Must decrypt entire blob to access any field (acceptable for single-record operations)

### Why Duplicate Fields for Integrity?

The encrypted blob contains `id` and `dateMillis` which are also stored in plaintext columns. This enables **integrity verification**:

```dart
// During decryption
if (decryptedData.id != row.id) {
  throw SecurityException("Blob swapping detected!");
}
if (decryptedData.dateMillis != row.date) {
  throw SecurityException("Date tampering detected!");
}
```

**Attack scenario prevented:**
1. Attacker gains database access
2. Attacker swaps `encrypted_blob` between two rows
3. Without integrity check: App decrypts wrong data, user sees incorrect transaction
4. With integrity check: App detects mismatch, refuses to display tampered data

### Why Soft Deletes?

Hard deletes (`DELETE FROM transactions WHERE id = ?`) create problems for sync:

1. **Lost information**: Once deleted, the server doesn't know to delete on other devices
2. **Resurrection**: If another device syncs before learning of deletion, the record reappears

Soft deletes (`UPDATE transactions SET isDeleted = true WHERE id = ?`) solve this:

1. **Sync propagation**: All devices eventually see `isDeleted = true`
2. **Audit trail**: Deletion timestamp preserved in `lastUpdatedAt`
3. **Recovery possible**: Accidental deletions can be undone

### Why Last-Write-Wins (LWW)?

For sync conflict resolution, we use the Last-Write-Wins strategy based on `lastUpdatedAt`:

```
Device A: Updates transaction at T=100
Device B: Updates same transaction at T=105
Sync: Device B's version wins (T=105 > T=100)
```

**Why LWW over other strategies:**

| Strategy | Pros | Cons |
|----------|------|------|
| LWW | Simple, deterministic | May lose edits |
| CRDT | No data loss | Complex, larger payloads |
| Manual merge | User control | Poor UX, interrupts workflow |

For a personal finance app where:
- Conflicts are rare (single user, few devices)
- Transactions are typically created once, rarely edited
- Simplicity is valued over perfect conflict handling

LWW is the pragmatic choice.

### Why SQLite via Drift?

**Drift advantages:**
- Type-safe queries with compile-time verification
- Reactive streams for UI updates
- Cross-platform (iOS, Android, macOS, Windows, Linux)
- Built-in migration support
- Excellent Flutter integration

**SQLite advantages:**
- Battle-tested, billions of deployments
- Zero configuration
- Single file database (easy backup)
- ACID compliant
- Works offline

---

## Security Model

### Threat Model

We protect against:

| Threat | Mitigation |
|--------|------------|
| Database file theft | AES-256-GCM encryption |
| Cloud server compromise | Zero-knowledge (server only sees blobs) |
| Man-in-the-middle (future sync) | TLS + client-side encryption |
| Blob swapping attacks | Integrity verification via duplicated fields |
| Ciphertext modification | GCM authentication tag |
| Replay attacks | Unique nonce per encryption |

We do NOT protect against (out of scope for Stage 1):

| Threat | Future Mitigation |
|--------|-------------------|
| Device compromise with unlocked app | Stage 2: Biometric/PIN unlock |
| Key extraction from memory | Stage 2: Secure enclave storage |
| Rooted/jailbroken device attacks | Platform security features |

### Key Management

**Stage 1 (Current):** Mock key provider with hardcoded key for development.

```dart
class MockKeyProvider implements KeyProvider {
  static final Uint8List _mockKey = Uint8List.fromList([
    0x01, 0x02, 0x03, ... // 32 bytes
  ]);

  Future<Uint8List> getKey() async => _mockKey;
}
```

**Stage 2 (Planned):** Secure key storage using platform capabilities.

```
┌─────────────────────────────────────────────────┐
│                  Key Storage                     │
├─────────────────┬───────────────────────────────┤
│ iOS             │ Keychain Services             │
│ Android         │ Android Keystore              │
│ macOS           │ Keychain Services             │
│ Windows         │ Windows Credential Manager    │
│ Linux           │ libsecret                     │
└─────────────────┴───────────────────────────────┘
```

### Encryption Details

**Algorithm:** AES-256-GCM
**Key size:** 256 bits (32 bytes)
**Nonce size:** 96 bits (12 bytes) - randomly generated per encryption
**Tag size:** 128 bits (16 bytes)

**Encrypted blob format:**
```
┌────────────┬─────────────────────┬────────────┐
│   Nonce    │     Ciphertext      │    MAC     │
│  12 bytes  │    variable size    │  16 bytes  │
└────────────┴─────────────────────┴────────────┘
```

---

## Implementation Details

### Project Structure

```
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart              # Drift database definition
│   │   ├── app_database.g.dart            # Generated code
│   │   ├── exceptions/
│   │   │   └── security_exception.dart    # Integrity failure exception
│   │   └── services/
│   │       ├── encryption_service.dart    # AES-GCM encrypt/decrypt
│   │       ├── key_provider.dart          # Key management abstraction
│   │       ├── database_metrics_service.dart   # Query counts/timestamps
│   │       ├── database_export_service.dart    # SQLite/CSV export
│   │       └── database_import_service.dart    # SQLite/CSV import
│   └── providers/
│       └── database_providers.dart        # Riverpod DI providers
├── data/
│   ├── models/
│   │   ├── transaction_data.dart          # Freezed model for encryption
│   │   ├── transaction_data.freezed.dart
│   │   └── transaction_data.g.dart
│   └── repositories/
│       └── transaction_repository.dart    # CRUD with encryption
└── features/
    ├── settings/
    │   ├── data/models/
    │   │   ├── database_metrics.dart      # Metrics statistics model
    │   │   └── export_options.dart        # Export configuration
    │   └── presentation/
    │       ├── providers/
    │       │   └── database_providers.dart # Metrics, export/import state
    │       ├── screens/
    │       │   ├── database_settings_screen.dart  # Database management UI
    │       │   └── export_screen.dart             # Export options UI
    │       └── widgets/
    │           ├── database_metrics_card.dart     # Metrics display
    │           └── delete_database_dialog.dart    # Confirmation dialog
    └── transactions/
        └── presentation/
            └── providers/
                └── transactions_provider.dart # AsyncNotifier
```

### Database Schema

```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,           -- UUID, plaintext
  date INTEGER NOT NULL,         -- Unix milliseconds, for sorting
  last_updated_at INTEGER NOT NULL, -- For LWW sync
  is_deleted INTEGER DEFAULT 0,  -- Soft delete flag
  encrypted_blob BLOB NOT NULL   -- AES-GCM encrypted JSON
);

CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_deleted ON transactions(is_deleted);
```

### TransactionData Model

The `TransactionData` class represents the structure that gets serialized to JSON and encrypted:

```dart
@freezed
class TransactionData with _$TransactionData {
  const factory TransactionData({
    required String id,           // Duplicated for integrity check
    required double amount,
    required String categoryId,
    required String accountId,
    required String type,         // 'income' or 'expense'
    String? note,
    @Default('USD') String currency,
    required int dateMillis,      // Duplicated for integrity check
    required int createdAtMillis,
  }) = _TransactionData;

  factory TransactionData.fromJson(Map<String, dynamic> json) =>
      _$TransactionDataFromJson(json);
}
```

**Why Freezed?**
- Immutable by default
- Auto-generated `==`, `hashCode`, `copyWith`, `toString`
- JSON serialization via `json_serializable`
- Null safety enforcement

### Encryption Service

```dart
class EncryptionService {
  final KeyProvider _keyProvider;
  final AesGcm _algorithm = AesGcm.with256bits();

  /// Encrypts TransactionData to binary blob
  Future<Uint8List> encrypt(TransactionData data) async {
    // 1. Get encryption key
    final key = await _keyProvider.getKey();
    final secretKey = SecretKey(key);

    // 2. Serialize to JSON
    final jsonString = jsonEncode(data.toJson());
    final plaintext = utf8.encode(jsonString);

    // 3. Encrypt (automatically generates random nonce)
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
    );

    // 4. Combine: nonce + ciphertext + mac
    final result = Uint8List(
      secretBox.nonce.length +
      secretBox.cipherText.length +
      secretBox.mac.bytes.length
    );

    // Copy components into result buffer
    var offset = 0;
    result.setRange(offset, offset + 12, secretBox.nonce);
    offset += 12;
    result.setRange(offset, offset + secretBox.cipherText.length,
                    secretBox.cipherText);
    offset += secretBox.cipherText.length;
    result.setRange(offset, offset + 16, secretBox.mac.bytes);

    return result;
  }

  /// Decrypts blob back to TransactionData with integrity verification
  Future<TransactionData> decrypt(
    Uint8List encryptedBlob, {
    required String expectedId,
    required int expectedDateMillis,
  }) async {
    // 1. Get decryption key
    final key = await _keyProvider.getKey();
    final secretKey = SecretKey(key);

    // 2. Extract components from blob
    final nonce = encryptedBlob.sublist(0, 12);
    final cipherText = encryptedBlob.sublist(12, encryptedBlob.length - 16);
    final mac = Mac(encryptedBlob.sublist(encryptedBlob.length - 16));

    // 3. Decrypt (throws if MAC verification fails)
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    // 4. Parse JSON
    final jsonString = utf8.decode(plaintext);
    final data = TransactionData.fromJson(jsonDecode(jsonString));

    // 5. Integrity verification - detect blob swapping
    if (data.id != expectedId) {
      throw SecurityException(
        rowId: expectedId,
        fieldName: 'id',
        expectedValue: expectedId,
        actualValue: data.id,
      );
    }

    if (data.dateMillis != expectedDateMillis) {
      throw SecurityException(
        rowId: expectedId,
        fieldName: 'dateMillis',
        expectedValue: expectedDateMillis.toString(),
        actualValue: data.dateMillis.toString(),
      );
    }

    return data;
  }
}
```

### Repository Pattern

The `TransactionRepository` bridges the UI model and encrypted storage:

```dart
class TransactionRepository {
  final AppDatabase database;
  final EncryptionService encryptionService;

  /// Convert UI Transaction → Internal TransactionData
  TransactionData _toData(Transaction transaction) {
    return TransactionData(
      id: transaction.id,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
      type: transaction.type.name,
      note: transaction.note,
      currency: 'USD',
      dateMillis: transaction.date.millisecondsSinceEpoch,
      createdAtMillis: transaction.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Convert Internal TransactionData → UI Transaction
  Transaction _toTransaction(TransactionData data) {
    return Transaction(
      id: data.id,
      amount: data.amount,
      type: data.type == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: data.categoryId,
      accountId: data.accountId,
      date: DateTime.fromMillisecondsSinceEpoch(data.dateMillis),
      note: data.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  /// Create: Encrypt and insert
  Future<void> createTransaction(Transaction transaction) async {
    final data = _toData(transaction);
    final encryptedBlob = await encryptionService.encrypt(data);

    await database.insertTransaction(
      id: transaction.id,
      date: transaction.date.millisecondsSinceEpoch,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Read: Fetch, decrypt, verify
  Future<Transaction?> getTransaction(String id) async {
    final row = await database.getTransaction(id);
    if (row == null) return null;

    final data = await encryptionService.decrypt(
      row.encryptedBlob,
      expectedId: row.id,
      expectedDateMillis: row.date,
    );

    return _toTransaction(data);
  }

  /// Read all: Fetch all, decrypt each
  Future<List<Transaction>> getAllTransactions() async {
    final rows = await database.getAllTransactions();
    final transactions = <Transaction>[];

    for (final row in rows) {
      final data = await encryptionService.decrypt(
        row.encryptedBlob,
        expectedId: row.id,
        expectedDateMillis: row.date,
      );
      transactions.add(_toTransaction(data));
    }

    return transactions;
  }

  /// Update: Re-encrypt and update
  Future<void> updateTransaction(Transaction transaction) async {
    final data = _toData(transaction);
    final encryptedBlob = await encryptionService.encrypt(data);

    await database.updateTransaction(
      id: transaction.id,
      date: transaction.date.millisecondsSinceEpoch,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      encryptedBlob: encryptedBlob,
    );
  }

  /// Delete: Soft delete
  Future<void> deleteTransaction(String id) async {
    await database.softDeleteTransaction(
      id,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
```

### State Management with AsyncNotifier

Since database operations are asynchronous, we use Riverpod's `AsyncNotifier`:

```dart
class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final repo = ref.watch(transactionRepositoryProvider);

    // Check for existing data
    final hasData = await repo.hasTransactions();

    if (!hasData) {
      // Seed demo data on first run
      for (final tx in DemoData.transactions) {
        await repo.createTransaction(tx);
      }
      return List.from(DemoData.transactions);
    }

    return repo.getAllTransactions();
  }

  Future<void> addTransaction({...}) async {
    final repo = ref.read(transactionRepositoryProvider);

    // Create transaction object
    final transaction = Transaction(...);

    // Save to encrypted database
    await repo.createTransaction(transaction);

    // Update local state optimistically
    state = state.whenData((txs) => [transaction, ...txs]);

    // Update related account balance
    ref.read(accountsProvider.notifier).updateBalance(...);
  }
}
```

### Dependency Injection

Riverpod providers wire everything together:

```dart
// Key provider (Stage 1: Mock, Stage 2: Secure)
final keyProviderProvider = Provider<KeyProvider>((ref) {
  return MockKeyProvider();
});

// Encryption service
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(ref.watch(keyProviderProvider));
});

// Database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Repository combining database + encryption
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});
```

### UI Handling of AsyncValue

Screens handle loading, error, and data states:

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final transactionsAsync = ref.watch(transactionsProvider);

  return transactionsAsync.when(
    loading: () => const CircularProgressIndicator(),
    error: (error, stack) => ErrorWidget(error),
    data: (transactions) => TransactionsList(transactions),
  );
}
```

---

## Data Flow

### Creating a Transaction

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CREATE TRANSACTION                           │
└─────────────────────────────────────────────────────────────────────┘

1. User fills form and taps "Save"
         │
         ▼
2. TransactionsNotifier.addTransaction()
         │
         ▼
3. Create Transaction object with UUID
         │
         ▼
4. Repository.createTransaction(transaction)
         │
         ├──► Convert Transaction → TransactionData
         │
         ├──► EncryptionService.encrypt(data)
         │         │
         │         ├──► Serialize to JSON
         │         ├──► Get key from KeyProvider
         │         ├──► AES-256-GCM encrypt
         │         └──► Return: nonce + ciphertext + mac
         │
         └──► Database.insertTransaction(id, date, timestamp, blob)
                    │
                    └──► SQLite INSERT
         │
         ▼
5. Update local state: state = [newTx, ...existing]
         │
         ▼
6. Update account balance
         │
         ▼
7. UI rebuilds via Riverpod reactivity
```

### Reading Transactions

```
┌─────────────────────────────────────────────────────────────────────┐
│                        READ TRANSACTIONS                             │
└─────────────────────────────────────────────────────────────────────┘

1. App starts / TransactionsNotifier.build()
         │
         ▼
2. Repository.getAllTransactions()
         │
         ├──► Database.getAllTransactions()
         │         │
         │         └──► SQLite SELECT WHERE isDeleted = false
         │                    ORDER BY date DESC
         │
         └──► For each row:
                    │
                    ├──► EncryptionService.decrypt(blob, expectedId, expectedDate)
                    │         │
                    │         ├──► Extract nonce, ciphertext, mac
                    │         ├──► Get key from KeyProvider
                    │         ├──► AES-256-GCM decrypt
                    │         ├──► Parse JSON → TransactionData
                    │         ├──► Verify: data.id == row.id ✓
                    │         └──► Verify: data.dateMillis == row.date ✓
                    │
                    └──► Convert TransactionData → Transaction
         │
         ▼
3. Return List<Transaction>
         │
         ▼
4. UI displays transactions
```

---

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

---

## Future Considerations

### Stage 2: Secure Key Storage

Replace `MockKeyProvider` with platform-specific secure storage:

```dart
class SecureKeyProvider implements KeyProvider {
  final FlutterSecureStorage _storage;

  Future<Uint8List> getKey() async {
    var key = await _storage.read(key: 'encryption_key');

    if (key == null) {
      // Generate new key on first use
      key = _generateSecureKey();
      await _storage.write(key: 'encryption_key', value: key);
    }

    return base64Decode(key);
  }
}
```

### Stage 3: Cloud Sync with Supabase

The current schema is sync-ready:

1. **Push changes**: Upload encrypted blobs to Supabase
2. **Pull changes**: Download blobs, decrypt locally
3. **Conflict resolution**: Compare `lastUpdatedAt`, keep newer
4. **Delete propagation**: Sync `isDeleted = true` to all devices

```
Device A                    Supabase                    Device B
    │                          │                            │
    │──── Push encrypted ─────►│                            │
    │     blob + metadata      │                            │
    │                          │◄──── Pull changes ─────────│
    │                          │      (encrypted blobs)     │
    │                          │                            │
    │                    ┌─────┴─────┐                      │
    │                    │  Server   │                      │
    │                    │  sees     │                      │
    │                    │  only     │                      │
    │                    │  blobs    │                      │
    │                    └───────────┘                      │
```

### Performance Optimizations

For large datasets, consider:

1. **Pagination**: Load transactions in chunks
2. **Caching**: Cache decrypted transactions in memory
3. **Background decryption**: Decrypt blobs off main thread
4. **Incremental sync**: Only sync changed records

### Additional Entities

Extend encryption to other sensitive entities:

- Accounts (balance, account numbers)
- Categories (spending patterns)
- Budgets (financial goals)
- Recurring transactions (payment schedules)

---

## Conclusion

This encryption system provides strong security guarantees while maintaining usability:

- **Users** get seamless experience - encryption is invisible
- **Developers** get type-safe, reactive data layer
- **Security** ensures data remains private even if storage is compromised
- **Architecture** supports future cloud sync without compromising privacy

The Zero-Knowledge approach means that in future cloud deployments, we can offer sync functionality while honestly telling users: "We cannot read your financial data - only you can."
