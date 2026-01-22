import 'app_exception.dart';

/// Exception thrown when data integrity checks fail during decryption.
///
/// This exception indicates a potential security breach, such as:
/// - Blob-swapping attacks (someone swapped encrypted data between rows)
/// - Data corruption
/// - Tampering with the database
class SecurityException extends AppException {
  /// The row ID that was being accessed
  final String rowId;

  /// The field name that failed validation (e.g., 'id', 'dateMillis')
  final String fieldName;

  /// The expected value from the plaintext row metadata
  final String expectedValue;

  /// The actual value found in the decrypted blob
  final String actualValue;

  SecurityException({
    required this.rowId,
    required this.fieldName,
    required this.expectedValue,
    required this.actualValue,
  }) : super(
          message: 'Integrity check failed for row $rowId: '
              '$fieldName mismatch (expected: $expectedValue, actual: $actualValue). '
              'Possible blob-swapping attack or data corruption.',
          code: 'INTEGRITY_FAILURE',
        );
}
