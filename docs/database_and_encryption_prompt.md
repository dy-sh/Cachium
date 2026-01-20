
**System Role:** You are a Senior Flutter Architect specializing in "Offline-First", "Local-First", and Zero-Knowledge (E2EE) financial systems.
**Stack:** Flutter, Riverpod (Generator syntax), Drift (SQLite), Freezed, JSON Serializable, Cryptography (package), Supabase Flutter (Auth + Database + Storage), Flutter Secure Storage, Path Provider, Isolated Worker (for crypto operations), cryptography_flutter.
**Platform:** Android, iOS, Windows, macOS, Linux.
**Critical Desktop Requirement:** For Linux, assume the user needs `libsecret-1-dev`. Use `sqlite3_flutter_libs` to bundle SQLite binaries on Windows/Linux to prevent missing DLL errors.

**Project Goal:** Build a Secure Financial Manager where the server (Supabase) hosts encrypted data but cannot read it.
**Core Philosophy:**
1.  **Zero-Knowledge:** The cloud provider sees only encrypted binary/text blobs.
2.  **Master Key (MK):** A 32-byte key.
    *   *Storage:* Encrypted by User Password (Argon2id + AES-GCM) -> stored as `vault.json` in Supabase Storage.
    *   *Local Cache:* Stored in OS Secure Storage (Keychain/Keystore/libsecret) for quick access.
3.  **Sync Strategy:** "Append-Only Log" stored in a **Supabase Table**. Clients replay the log to rebuild the state.

**Workflow Instructions:**
*   **Strict Iteration:** Output code ONLY for the current stage. Wait for user confirmation before moving to the next.
*   **Desktop First:** Ensure solutions work on Windows/Linux. **Explicitly mention required OS libraries (e.g., `libsecret` for Linux) if adding packages.**
*   **Safety:** All crypto operations must use authenticated encryption (AES-GCM or Chacha20-Poly1305).

---

#### **Stage 1: Secure Local Database (Drift & TypeConverters)**
**Objective:** Set up a Drift database where encryption is handled transparently via TypeConverters.
**Tasks:**
1.  **Data Models:** Define a JSON-serializable `TransactionData` class (id, amount, category, description, currency, date). *Note: Include ID and Date inside the JSON model to verify integrity after decryption.*
2.  **Drift Setup:** Create `AppDatabase`.
    *   **Table `Transactions`:**
        *   `id` (UUID, Primary Key).
        *   `date` (Int - Unix Timestamp) -> *Plaintext for sorting*.
        *   `last_updated_at` (Int) -> *Plaintext for sync logic (LWW)*.
        *   `is_deleted` (Bool) -> *Soft delete flag*.
        *   `encrypted_blob` (Uint8List) -> Stores the encrypted JSON of `TransactionData`.
    *   **EncryptionConverter:** Implement a Drift `TypeConverter<TransactionData, String>`.
        *   It uses a `Provider` or Service to Encrypt/Decrypt on the fly.
        *   **Integrity Check (CRITICAL):** When decrypting, verify that the `id` inside the decrypted JSON matches the row `id`. **Also verify the `date` matches.** If they do not match, throw a `SecurityException` (prevents blob swapping attacks).
        *   *Mock Key:* For this stage, hardcode a dummy 32-byte key.
3.  **Repository:** Create `LocalDatabaseRepository` with CRUD (create, read, update, delete).
    *   *Note on Filtering:* Since the blob is encrypted, acknowledge that filtering by category/amount will happen **in-memory** (Dart side) after loading the list, not via SQL `WHERE` clauses.
**Deliverable:** A running app with a list of transactions. Ensure `sqlite3_flutter_libs` is used for Desktop support. Inspecting the `.sqlite` file must show unreadable ciphertext in the blob column.

#### **Stage 2: Cryptography, Auth & The Vault**
**Objective:** Implement the security core: Lock/Unlock the app, Key Derivation.
**Tasks:**
1.  **CryptoService:**
    *   Implement `deriveKeyFromPassword(password, salt)` using Argon2id. **CRITICAL:** This specific function MUST run inside `compute()` (Isolate) to avoid freezing the UI.
    *   Implement `encrypt(data, key)` / `decrypt(data, key)`.
2.  **Auth Flow (Supabase + Storage):**
    *   **Registration:**
        1.  Generate a random Master Key (MK).
        2.  Derive `Key_Encryption_Key` (KEK) from User Password using Argon2id (running in Isolate).
        3.  Encrypt MK with KEK -> Upload `vault.json` to Supabase Storage.
        4.  Generate a unique `device_id` (UUID) and store in Prefs.
    *   **Login (New Device):** Supabase Auth -> Download `vault.json` -> Ask Password -> Derive KEK -> Decrypt MK -> Store MK in Secure Storage.
    *   **Warning UI:** Explicitly show a dialog: "If you lose your password, your data is lost forever. We cannot reset it."
    *   **Quick App Launch:** Check `FlutterSecureStorage`. If MK exists, load it into memory.
3.  **Integration:** Inject the real MK into the `EncryptionConverter` from Stage 1 (replace the mock key).
**Deliverable:** Login/Register screens. The app encrypts the DB with a real key derived from the user's password.

#### **Stage 3: The Sync Queue (Tracking Changes)**
**Objective:** Capture local writes to prepare them for sync.
**Tasks:**
1.  **Table `SyncQueue` (Drift):**
    *   `id` (Auto-Inc), `operation` (UPSERT/DELETE), `row_id` (UUID), `table_name`, `encrypted_payload` (Text), `created_at` (Int).
2.  **Transaction Manager:**
    *   Create a manager/service that wraps DB writes.
    *   **On Save:**
        1.  Write to local `Transactions` table.
        2.  Serialize `TransactionData` to JSON -> Encrypt with MK.
        3.  Insert into `SyncQueue` with operation `UPSERT`.
    *   **On Delete:**
        1.  Mark `is_deleted = true` in local `Transactions`.
        2.  Insert into `SyncQueue` with operation `DELETE` (payload can be empty or minimal).
    *   Ensure strict Atomicity (Drift `.transaction()`).
**Deliverable:** Add/Delete a transaction in UI. Verify `SyncQueue` captures these events with encrypted payloads.

#### **Stage 4: Cloud Sync Engine (Push & Pull)**
**Objective:** Sync the encrypted queue with Supabase Database.
**Tasks:**
1.  **Supabase Table `enc_event_log`:**
    *   `id` (BigInt Primary Key, Auto-Increment), `user_id` (UUID), `device_id` (Text), `operation` (Text), `row_id` (UUID), `encrypted_body` (Text), `created_at` (Int).
    *   **RLS Policy:**
        *   `INSERT`: `auth.uid() = user_id`.
        *   `SELECT`: `auth.uid() = user_id`.
        *   `UPDATE/DELETE`: DENY ALL.
2.  **Sync Logic (Riverpod Provider):**
    *   **Push:**
        *   Read `SyncQueue` items.
        *   Batch Insert into Supabase `enc_event_log`.
        *   **Idempotency Strategy:** Ensure that if the network request fails, we do not delete from `SyncQueue`. Only delete locally after receiving a HTTP 200/201 OK from Supabase.
    *   **Pull:**
        *   Get `last_synced_id` from Prefs.
        *   **Filter:** Fetch `enc_event_log` where `id > last_synced_id` **AND `device_id != my_device_id`**. (Prevents applying own changes).
        *   *Optimization:* Limit fetch to 500 events per batch.
        *   Process events:
            *   *UPSERT:* Decrypt `encrypted_body` -> `insertOnConflictUpdate` into Drift.
            *   *DELETE:* Set `is_deleted = true` locally.
        *   **Crucial:** Disable the `SyncQueue` interceptor during Pull writes to prevent infinite loops.
**Deliverable:** Two simulators. Changes on A propagate to B after sync.

#### **Stage 5: Conflict Resolution & Polish**
**Objective:** Handle collisions (LWW) and connectivity.
**Tasks:**
1.  **LWW (Last Write Wins):**
    *   Modify Pull logic: When receiving an UPSERT, compare incoming `last_updated_at` (from inside the decrypted payload) vs local `last_updated_at`.
    *   Only apply update if incoming is newer.
2.  **Connectivity:**
    *   Use `connectivity_plus` to trigger sync when internet becomes available.
    *   Lifecycle Sync: Trigger a generic "Pull" when the app comes to the foreground (using AppLifecycleListener).
    *   Add a visual Sync Indicator (Syncing/Saved/Offline).
**Deliverable:** Final audit. Verify that offline changes on two devices resolve correctly (newest change wins) when both come online.

#### **Stage 6: Future Roadmap (Ideas for Scaling)**
*Note: This stage is for architectural context only. Do not implement code for this yet, but design previous stages to allow this evolution.*
1.  **Snapshotting (Log Compaction):**
    *   *Problem:* The `enc_event_log` grows indefinitely. A new device might need to download 50,000 events to reconstruct 500 active records.
    *   *Solution:* Implement a "Snapshot" mechanism.
        *   A device periodically uploads a fully encrypted backup of the SQLite DB (as a JSON dump) to Supabase Storage.
        *   A "Snapshot Pointer" record is created in the DB pointing to this file and the `last_event_id` it includes.
        *   New devices download the Snapshot first, then only play events *after* the snapshot's ID.
2.  **Key Rotation:**
    *   Logic to allow changing the Master Key. This would require re-encrypting the entire local database and uploading a fresh Snapshot, effectively invalidating the old event log.

---


### **Architecture Notes & Rationale**

1.  **Why Drift (SQLite) + Custom Sync instead of standard Supabase Offline?**
    *   **Granular E2EE Control:** Standard Supabase SDKs sync row-by-row. Implementing Zero-Knowledge encryption there is difficult because the server expects to read/filter data. By using Drift locally, we completely decouple the "application state" from the "transport layer."
    *   **ACID Compliance:** Financial apps require strict transaction integrity. SQLite ensures that a money transfer (debit one account, credit another) happens atomically, which is harder to guarantee with simple JSON file storage or key-value stores.
    *   **No Vendor Lock-in (Logic):** Our core logic relies on SQL. If we need to switch from Supabase to a generic file server (WebDAV) or another cloud later, we only change the "Sync Engine" (transport), not the entire database layer.

2.  **Why "Append-Only Log" (Event Sourcing) for Sync?**
    *   **Solves the "File Overwrite" & Race Conditions:** If Device A and Device B both try to upload a database file named `db.sqlite`, the last one wins, and data is lost. By appending small events (e.g., `Event #101: Insert Transaction`) to a list, both devices can push data without strictly blocking each other.
    *   **Bandwidth & Free Tier Friendly:** Uploading a 500-byte JSON event is much faster and cheaper than re-uploading a 10MB database file every time the user buys a coffee. This keeps the app well within Supabase's free tier quotas.
    *   **Conflict Context:** Storing *intent* (Insert/Delete) allows better conflict resolution strategies compared to binary file merging.

3.  **Why UUIDs for Primary Keys instead of Integers?**
    *   **Distributed Collision Avoidance:** In an offline-first system, Device A and Device B might both create a new transaction while offline. If we used auto-increment integers, both would create ID `5`. When they sync, this causes a collision.
    *   **Independence:** UUIDs (v4) allow devices to generate unique IDs without checking with a central server first.

4.  **Why a Separate `SyncQueue` Table?**
    *   **Capturing Deletes:** If we simply queried the `Transactions` table for "unsynced items", we would miss deletions (because the row is gone or just marked deleted). The `SyncQueue` acts as a persistent log of *intents*, ensuring that even if the local state changes, the instruction to update the remote state is preserved until confirmed sent.
    *   **Decoupling:** It separates the "UI State" (Transactions table) from the "Network State" (SyncQueue). The UI remains snappy because it doesn't wait for the network; the sync engine processes the queue in the background.

5.  **Why Hybrid Encryption (Plaintext Metadata + Encrypted Blob)?**
    *   **The "Server-Side Sort" Trade-off:** We store `date` and `last_updated_at` in plaintext. This allows us to ask the server: *"Give me all changes since timestamp X."*
    *   **The Searchability Trade-off:** Since SQL cannot index or search inside the encrypted blob (e.g., `WHERE description LIKE '%coffee%'`), we accept that text filtering must happen **in-memory** on the Dart side. For a personal finance app (<100k rows), loading decrypted data into memory is instant on modern devices and is a necessary trade-off for 100% privacy.
    *   **Security Boundary:** Even though the server sees *when* a transaction happened (metadata), it has mathematically zero probability of knowing *how much* money was involved or *what* was bought (AES-GCM encrypted blob).

6.  **Why Argon2id + `vault.json` (Key Derivation)?**
    *   **Separation of Concerns:** We do not encrypt the database with the user's password directly. We encrypt a random Master Key (MK).
        *   *Benefit 1:* The user can change their password without us having to re-encrypt thousands of database rows (we just re-encrypt the MK).
        *   *Benefit 2:* Argon2id is memory-hard, making brute-force attacks on the `vault.json` computationally infeasible.
    *   **Performance (Isolates):** Because Argon2id is computationally heavy by design, running it on the main UI thread would freeze the app for 1-3 seconds. We **strictly** enforce running this in an Isolate (`compute()`) to maintain a smooth 60fps UI.

7.  **Why `FlutterSecureStorage` + `sqlite3_flutter_libs`?**
    *   **Desktop Stability:** Standard packages often crash on Windows/Linux due to missing C-libraries. Explicitly including `sqlite3_flutter_libs` guarantees the app ships with its own binaries, preventing "DLL missing" errors.
    *   **Linux Requirements:** We use secure storage to improve UX (not typing passwords daily). On Linux, this relies on `libsecret`, which must be present in the OS environment. This is a known trade-off for security on desktop Linux.
    *   **UX vs. Security:** This allows the user to open the app quickly (biometrics can be added later), while ensuring the Master Key is never written to disk in plaintext.

8.  **Why Client-Side Validation of Decrypted Data?**
    *   **Integrity Check:** We store the `id` inside the encrypted JSON *and* as a plaintext column. During decryption, we verify they match.
    *   **Anti-Tampering:** This prevents a malicious server (or Man-in-the-Middle) from swapping the encrypted blobs of two different transactions (e.g., swapping a $5 transaction with a $5000 one) without the app noticing the mismatch.

9.  **Why Last-Write-Wins (LWW) instead of CRDTs?**
    *   **Pragmatism vs. Complexity:** While Conflict-Free Replicated Data Types (CRDTs) allow mathematical merging of data, they require complex custom data structures (like vector clocks) that are hard to map to standard SQL tables.
    *   **Context Logic:** For a personal finance app, if a user edits a transaction on two devices simultaneously, the intuitive expectation is that the "most recent" edit is the correct one. LWW is sufficient for this use case and significantly reduces codebase complexity.

10. **Why Supabase RLS (Row Level Security) if data is encrypted?**
    *   **Defense in Depth:** Encryption protects the *confidentiality* of the data (Supabase admins can't read it). RLS protects the *integrity* and *isolation* of the data.
    *   **Prevention:** RLS ensures that User A cannot accidentally or maliciously delete User B's encrypted rows, even if they share the same physical table. It acts as the authorization layer while AES-GCM acts as the privacy layer.

11. **Why JSON Serialization inside the Encrypted Blob?**
    *   **Schema Evolution:** Financial data models change (e.g., adding a "Tags" list or "Split Bill" feature later). By storing the core data as a JSON blob inside the encryption, we can add nullable fields to the Dart model without needing to perform complex SQL migrations for every minor change. We simply decrypt, parse the new structure, and handle missing fields gracefully.

12. **Why Filter by `device_id` during Sync (The "Echo" Problem)?**
    *   **Bandwidth Efficiency:** When Device A pushes a change to the server, that change becomes the latest event. If Device A immediately pulls "all new events," it would re-download its own change.
    *   **Logic Loop Prevention:** Filtering out events where `device_id == my_device_id` ensures that the sync logic only processes changes from *other* devices, preventing redundant writes or potential infinite loops in the sync queue.