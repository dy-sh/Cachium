import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../data/models/account_data.dart';
import '../../../data/models/category_data.dart';
import '../../../data/models/transaction_data.dart';
import '../../exceptions/security_exception.dart';
import 'key_provider.dart';

/// Service for encrypting and decrypting data using AES-256-GCM.
///
/// The encrypted blob format is: [12-byte nonce][ciphertext][16-byte MAC]
/// This format allows the nonce to be prepended and MAC appended automatically
/// by the cryptography package's SecretBox.
class EncryptionService {
  final KeyProvider _keyProvider;
  final AesGcm _algorithm;

  EncryptionService(this._keyProvider) : _algorithm = AesGcm.with256bits();

  /// Encrypts any JSON-encodable data into a binary blob.
  ///
  /// Returns a Uint8List containing: nonce (12 bytes) + ciphertext + MAC (16 bytes)
  Future<Uint8List> encryptJson(Map<String, dynamic> json) async {
    final key = await _keyProvider.getKey();
    final secretKey = SecretKey(key);

    // Serialize to JSON then to bytes
    final jsonString = jsonEncode(json);
    final plaintext = utf8.encode(jsonString);

    // Encrypt with AES-GCM (automatically generates nonce)
    final secretBox = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
    );

    // Combine nonce + ciphertext + mac into single blob
    final result = Uint8List(
      secretBox.nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    var offset = 0;

    // Copy nonce
    result.setRange(offset, offset + secretBox.nonce.length, secretBox.nonce);
    offset += secretBox.nonce.length;

    // Copy ciphertext
    result.setRange(offset, offset + secretBox.cipherText.length, secretBox.cipherText);
    offset += secretBox.cipherText.length;

    // Copy MAC
    result.setRange(offset, offset + secretBox.mac.bytes.length, secretBox.mac.bytes);

    return result;
  }

  /// Decrypts an encrypted blob back to JSON.
  ///
  /// Throws [SecretBoxAuthenticationError] if decryption fails (wrong key or tampered data).
  Future<Map<String, dynamic>> decryptJson(Uint8List encryptedBlob) async {
    final key = await _keyProvider.getKey();
    final secretKey = SecretKey(key);

    // AES-GCM nonce is 12 bytes, MAC is 16 bytes
    const nonceLength = 12;
    const macLength = 16;

    if (encryptedBlob.length < nonceLength + macLength) {
      throw const FormatException('Encrypted blob is too short');
    }

    // Extract components
    final nonce = encryptedBlob.sublist(0, nonceLength);
    final cipherText = encryptedBlob.sublist(
      nonceLength,
      encryptedBlob.length - macLength,
    );
    final mac = Mac(encryptedBlob.sublist(encryptedBlob.length - macLength));

    // Reconstruct SecretBox
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    // Decrypt (will throw if MAC verification fails)
    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    // Parse JSON
    final jsonString = utf8.decode(plaintext);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Encrypts transaction data into a binary blob.
  ///
  /// Returns a Uint8List containing: nonce (12 bytes) + ciphertext + MAC (16 bytes)
  Future<Uint8List> encrypt(TransactionData data) async {
    return encryptJson(data.toJson());
  }

  /// Decrypts an encrypted blob back to transaction data.
  ///
  /// Performs integrity verification to ensure the decrypted data matches
  /// the expected row metadata (id and dateMillis). This prevents blob-swapping
  /// attacks where an attacker might swap encrypted blobs between rows.
  ///
  /// Throws [SecurityException] if integrity check fails.
  /// Throws [SecretBoxAuthenticationError] if decryption fails (wrong key or tampered data).
  Future<TransactionData> decrypt(
    Uint8List encryptedBlob, {
    required String expectedId,
    required int expectedDateMillis,
  }) async {
    final json = await decryptJson(encryptedBlob);
    final data = TransactionData.fromJson(json);

    // Integrity check: verify decrypted data matches row metadata
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

  /// Encrypts account data into a binary blob.
  ///
  /// Returns a Uint8List containing: nonce (12 bytes) + ciphertext + MAC (16 bytes)
  Future<Uint8List> encryptAccount(AccountData data) async {
    return encryptJson(data.toJson());
  }

  /// Decrypts an encrypted blob back to account data.
  ///
  /// Performs integrity verification to ensure the decrypted data matches
  /// the expected row metadata (id and createdAtMillis). This prevents blob-swapping
  /// attacks where an attacker might swap encrypted blobs between rows.
  ///
  /// Throws [SecurityException] if integrity check fails.
  /// Throws [SecretBoxAuthenticationError] if decryption fails (wrong key or tampered data).
  Future<AccountData> decryptAccount(
    Uint8List encryptedBlob, {
    required String expectedId,
    required int expectedCreatedAtMillis,
  }) async {
    final json = await decryptJson(encryptedBlob);
    final data = AccountData.fromJson(json);

    // Integrity check: verify decrypted data matches row metadata
    if (data.id != expectedId) {
      throw SecurityException(
        rowId: expectedId,
        fieldName: 'id',
        expectedValue: expectedId,
        actualValue: data.id,
      );
    }

    if (data.createdAtMillis != expectedCreatedAtMillis) {
      throw SecurityException(
        rowId: expectedId,
        fieldName: 'createdAtMillis',
        expectedValue: expectedCreatedAtMillis.toString(),
        actualValue: data.createdAtMillis.toString(),
      );
    }

    return data;
  }

  /// Encrypts category data into a binary blob.
  ///
  /// Returns a Uint8List containing: nonce (12 bytes) + ciphertext + MAC (16 bytes)
  Future<Uint8List> encryptCategory(CategoryData data) async {
    return encryptJson(data.toJson());
  }

  /// Decrypts an encrypted blob back to category data.
  ///
  /// Performs integrity verification to ensure the decrypted data matches
  /// the expected row metadata (id and sortOrder). This prevents blob-swapping
  /// attacks where an attacker might swap encrypted blobs between rows.
  ///
  /// Throws [SecurityException] if integrity check fails.
  /// Throws [SecretBoxAuthenticationError] if decryption fails (wrong key or tampered data).
  Future<CategoryData> decryptCategory(
    Uint8List encryptedBlob, {
    required String expectedId,
    required int expectedSortOrder,
  }) async {
    final json = await decryptJson(encryptedBlob);
    final data = CategoryData.fromJson(json);

    // Integrity check: verify decrypted data matches row metadata
    if (data.id != expectedId) {
      throw SecurityException(
        rowId: expectedId,
        fieldName: 'id',
        expectedValue: expectedId,
        actualValue: data.id,
      );
    }

    if (data.sortOrder != expectedSortOrder) {
      throw SecurityException(
        rowId: expectedId,
        fieldName: 'sortOrder',
        expectedValue: expectedSortOrder.toString(),
        actualValue: data.sortOrder.toString(),
      );
    }

    return data;
  }
}
