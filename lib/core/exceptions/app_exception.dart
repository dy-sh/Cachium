/// Base exception class for all Cachium app exceptions.
///
/// All custom exceptions in the app should extend this class to provide
/// a consistent interface for error handling.
abstract class AppException implements Exception {
  /// Human-readable error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  /// Optional original error that caused this exception
  final Object? cause;

  const AppException({
    required this.message,
    this.code,
    this.cause,
  });

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when a repository operation fails.
///
/// This includes database errors, encryption/decryption failures, etc.
class RepositoryException extends AppException {
  /// The entity type involved (e.g., 'Account', 'Transaction', 'Category')
  final String? entityType;

  /// The operation that failed (e.g., 'create', 'update', 'delete', 'fetch')
  final String? operation;

  const RepositoryException({
    required super.message,
    super.code,
    super.cause,
    this.entityType,
    this.operation,
  });

  factory RepositoryException.create({
    required String entityType,
    Object? cause,
  }) {
    return RepositoryException(
      message: 'Failed to create $entityType',
      code: 'CREATE_FAILED',
      cause: cause,
      entityType: entityType,
      operation: 'create',
    );
  }

  factory RepositoryException.update({
    required String entityType,
    String? entityId,
    Object? cause,
  }) {
    return RepositoryException(
      message: 'Failed to update $entityType${entityId != null ? ' ($entityId)' : ''}',
      code: 'UPDATE_FAILED',
      cause: cause,
      entityType: entityType,
      operation: 'update',
    );
  }

  factory RepositoryException.delete({
    required String entityType,
    String? entityId,
    Object? cause,
  }) {
    return RepositoryException(
      message: 'Failed to delete $entityType${entityId != null ? ' ($entityId)' : ''}',
      code: 'DELETE_FAILED',
      cause: cause,
      entityType: entityType,
      operation: 'delete',
    );
  }

  factory RepositoryException.fetch({
    required String entityType,
    String? entityId,
    Object? cause,
  }) {
    return RepositoryException(
      message: 'Failed to fetch $entityType${entityId != null ? ' ($entityId)' : ''}',
      code: 'FETCH_FAILED',
      cause: cause,
      entityType: entityType,
      operation: 'fetch',
    );
  }

  factory RepositoryException.encryption({
    required String entityType,
    Object? cause,
  }) {
    return RepositoryException(
      message: 'Encryption failed for $entityType',
      code: 'ENCRYPTION_FAILED',
      cause: cause,
      entityType: entityType,
      operation: 'encrypt',
    );
  }

  factory RepositoryException.decryption({
    required String entityType,
    String? entityId,
    Object? cause,
  }) {
    return RepositoryException(
      message: 'Decryption failed for $entityType${entityId != null ? ' ($entityId)' : ''}',
      code: 'DECRYPTION_FAILED',
      cause: cause,
      entityType: entityType,
      operation: 'decrypt',
    );
  }
}

/// Exception thrown when an entity is not found.
class EntityNotFoundException extends AppException {
  /// The entity type that was not found
  final String entityType;

  /// The ID of the entity that was not found
  final String entityId;

  const EntityNotFoundException({
    required this.entityType,
    required this.entityId,
  }) : super(
          message: '$entityType not found: $entityId',
          code: 'NOT_FOUND',
        );
}

/// Exception thrown when validation fails.
class ValidationException extends AppException {
  /// The field that failed validation
  final String? field;

  /// The validation rule that failed
  final String? rule;

  const ValidationException({
    required super.message,
    super.code,
    this.field,
    this.rule,
  });

  factory ValidationException.required(String field) {
    return ValidationException(
      message: '$field is required',
      code: 'REQUIRED',
      field: field,
      rule: 'required',
    );
  }

  factory ValidationException.invalidFormat(String field, {String? expected}) {
    return ValidationException(
      message: 'Invalid format for $field${expected != null ? ' (expected: $expected)' : ''}',
      code: 'INVALID_FORMAT',
      field: field,
      rule: 'format',
    );
  }

  factory ValidationException.outOfRange(String field, {num? min, num? max}) {
    final rangeStr = min != null && max != null
        ? '$min-$max'
        : min != null
            ? '>= $min'
            : '<= $max';
    return ValidationException(
      message: '$field must be in range $rangeStr',
      code: 'OUT_OF_RANGE',
      field: field,
      rule: 'range',
    );
  }

  factory ValidationException.duplicate(String field, String value) {
    return ValidationException(
      message: '$field "$value" already exists',
      code: 'DUPLICATE',
      field: field,
      rule: 'unique',
    );
  }
}

/// Exception thrown when an import operation fails.
class ImportException extends AppException {
  /// The file format that was being imported (e.g., 'sqlite', 'csv')
  final String? format;

  /// The line or row number where the error occurred
  final int? lineNumber;

  const ImportException({
    required super.message,
    super.code,
    super.cause,
    this.format,
    this.lineNumber,
  });

  factory ImportException.invalidFormat(String format, {Object? cause}) {
    return ImportException(
      message: 'Invalid $format file format',
      code: 'INVALID_FORMAT',
      cause: cause,
      format: format,
    );
  }

  factory ImportException.parseError(String format, int lineNumber, {Object? cause}) {
    return ImportException(
      message: 'Parse error in $format file at line $lineNumber',
      code: 'PARSE_ERROR',
      cause: cause,
      format: format,
      lineNumber: lineNumber,
    );
  }

  factory ImportException.fileNotSelected() {
    return const ImportException(
      message: 'No file selected for import',
      code: 'NO_FILE',
    );
  }
}

/// Exception thrown when an export operation fails.
class ExportException extends AppException {
  /// The file format that was being exported (e.g., 'sqlite', 'csv')
  final String? format;

  const ExportException({
    required super.message,
    super.code,
    super.cause,
    this.format,
  });

  factory ExportException.writeFailed(String format, {Object? cause}) {
    return ExportException(
      message: 'Failed to write $format export',
      code: 'WRITE_FAILED',
      cause: cause,
      format: format,
    );
  }

  factory ExportException.shareFailed({Object? cause}) {
    return ExportException(
      message: 'Failed to share exported file',
      code: 'SHARE_FAILED',
      cause: cause,
    );
  }
}
