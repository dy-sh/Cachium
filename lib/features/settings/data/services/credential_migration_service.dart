import '../../../../core/utils/credential_hasher.dart';
import '../models/app_settings.dart';

/// Pure logic for credential hashing upgrades and migrations.
///
/// Keeps hashing-format concerns out of `SettingsNotifier`. Returns a new
/// [AppSettings] with re-hashed credentials, or `null` if nothing changed.
class CredentialMigrationService {
  const CredentialMigrationService();

  /// Re-hash a credential to PBKDF2 after successful verification.
  ///
  /// Called from the lock screen when the raw credential is available.
  /// Returns an updated [AppSettings] if any field was upgraded, else `null`.
  Future<AppSettings?> upgradeIfNeeded(
    AppSettings current, {
    String? rawPin,
    String? rawPassword,
  }) async {
    var needsSave = false;
    var updated = current;

    if (rawPin != null &&
        current.appPinCode != null &&
        CredentialHasher.needsUpgrade(current.appPinCode!)) {
      final hashed = await CredentialHasher.hash(rawPin);
      updated = updated.copyWith(appPinCode: hashed);
      needsSave = true;
    }

    if (rawPassword != null &&
        current.appPassword != null &&
        CredentialHasher.needsUpgrade(current.appPassword!)) {
      final hashed = await CredentialHasher.hash(rawPassword);
      updated = updated.copyWith(appPassword: hashed);
      needsSave = true;
    }

    return needsSave ? updated : null;
  }

  /// Migrate credentials to the current hashing format (PBKDF2).
  ///
  /// Handles plaintext → PBKDF2. SHA-256 entries are left alone because
  /// they still verify correctly and the raw value isn't available here.
  /// Returns an updated [AppSettings] if any field was migrated, else `null`.
  Future<AppSettings?> migrateIfNeeded(AppSettings current) async {
    var needsSave = false;
    var updated = current;

    if (current.appPinCode != null &&
        !CredentialHasher.isPbkdf2(current.appPinCode!) &&
        !CredentialHasher.isHashed(current.appPinCode!)) {
      final hashed = await CredentialHasher.hash(current.appPinCode!);
      updated = updated.copyWith(appPinCode: hashed);
      needsSave = true;
    }

    if (current.appPassword != null &&
        !CredentialHasher.isPbkdf2(current.appPassword!) &&
        !CredentialHasher.isHashed(current.appPassword!)) {
      final hashed = await CredentialHasher.hash(current.appPassword!);
      updated = updated.copyWith(appPassword: hashed);
      needsSave = true;
    }

    return needsSave ? updated : null;
  }
}
