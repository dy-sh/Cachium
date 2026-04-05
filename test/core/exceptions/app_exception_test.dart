import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/exceptions/app_exception.dart';

void main() {
  group('RepositoryException.userMessage', () {
    test('CREATE_FAILED returns save message', () {
      final e = RepositoryException.create(entityType: 'Account');
      expect(e.userMessage, 'Could not save Account. Please try again.');
    });

    test('UPDATE_FAILED returns update message', () {
      final e = RepositoryException.update(entityType: 'Transaction');
      expect(
        e.userMessage,
        'Could not update Transaction. Please try again.',
      );
    });

    test('DELETE_FAILED returns delete message', () {
      final e = RepositoryException.delete(entityType: 'Budget');
      expect(e.userMessage, 'Could not delete Budget. Please try again.');
    });

    test('FETCH_FAILED returns load message', () {
      final e = RepositoryException.fetch(entityType: 'Category');
      expect(
        e.userMessage,
        'Could not load Category. Pull to refresh or try again.',
      );
    });

    test('DECRYPTION_FAILED returns corruption message', () {
      final e = RepositoryException.decryption(entityType: 'Transaction');
      expect(
        e.userMessage,
        'Could not read Transaction. The data may be corrupted.',
      );
    });

    test('ENCRYPTION_FAILED returns encrypt message', () {
      final e = RepositoryException.encryption(entityType: 'Account');
      expect(
        e.userMessage,
        'Could not encrypt Account. Please try again.',
      );
    });

    test('unknown code falls back to message', () {
      const e = RepositoryException(
        message: 'Something broke',
        code: 'UNKNOWN_CODE',
      );
      expect(e.userMessage, 'Something broke');
    });
  });

  group('RepositoryException factories', () {
    test('create sets correct fields', () {
      final e = RepositoryException.create(
        entityType: 'Account',
        cause: 'db error',
      );
      expect(e.code, 'CREATE_FAILED');
      expect(e.entityType, 'Account');
      expect(e.operation, 'create');
      expect(e.cause, 'db error');
    });

    test('update includes entityId in message', () {
      final e = RepositoryException.update(
        entityType: 'Transaction',
        entityId: 'tx-123',
      );
      expect(e.message, contains('tx-123'));
      expect(e.operation, 'update');
    });

    test('delete includes entityId in message', () {
      final e = RepositoryException.delete(
        entityType: 'Budget',
        entityId: 'b-1',
      );
      expect(e.message, contains('b-1'));
      expect(e.operation, 'delete');
    });

    test('fetch includes entityId in message', () {
      final e = RepositoryException.fetch(
        entityType: 'Category',
        entityId: 'cat-1',
      );
      expect(e.message, contains('cat-1'));
      expect(e.operation, 'fetch');
    });

    test('decryption sets correct fields', () {
      final e = RepositoryException.decryption(
        entityType: 'Transaction',
        entityId: 'tx-1',
      );
      expect(e.code, 'DECRYPTION_FAILED');
      expect(e.operation, 'decrypt');
      expect(e.message, contains('tx-1'));
    });

    test('encryption sets correct fields', () {
      final e = RepositoryException.encryption(entityType: 'Account');
      expect(e.code, 'ENCRYPTION_FAILED');
      expect(e.operation, 'encrypt');
    });
  });

  group('RepositoryException.toString', () {
    test('includes type and message', () {
      final e = RepositoryException.create(entityType: 'Account');
      expect(e.toString(), contains('RepositoryException'));
      expect(e.toString(), contains('Failed to create Account'));
      expect(e.toString(), contains('CREATE_FAILED'));
    });
  });

  group('EntityNotFoundException', () {
    test('sets correct fields', () {
      const e = EntityNotFoundException(
        entityType: 'Account',
        entityId: 'acc-123',
      );
      expect(e.message, 'Account not found: acc-123');
      expect(e.code, 'NOT_FOUND');
      expect(e.entityType, 'Account');
      expect(e.entityId, 'acc-123');
    });

    test('userMessage is friendly', () {
      const e = EntityNotFoundException(
        entityType: 'Transaction',
        entityId: 'tx-1',
      );
      expect(
        e.userMessage,
        'Transaction no longer exists. It may have been deleted.',
      );
    });
  });

  group('ValidationException', () {
    test('required factory', () {
      final e = ValidationException.required('name');
      expect(e.message, 'name is required');
      expect(e.code, 'REQUIRED');
      expect(e.field, 'name');
      expect(e.rule, 'required');
    });

    test('invalidFormat factory', () {
      final e = ValidationException.invalidFormat('email', expected: 'user@example.com');
      expect(e.message, contains('Invalid format'));
      expect(e.message, contains('email'));
      expect(e.message, contains('user@example.com'));
      expect(e.code, 'INVALID_FORMAT');
      expect(e.field, 'email');
    });

    test('invalidFormat without expected', () {
      final e = ValidationException.invalidFormat('date');
      expect(e.message, 'Invalid format for date');
      expect(e.code, 'INVALID_FORMAT');
    });

    test('outOfRange with both min and max', () {
      final e = ValidationException.outOfRange('month', min: 1, max: 12);
      expect(e.message, contains('1-12'));
      expect(e.code, 'OUT_OF_RANGE');
      expect(e.field, 'month');
    });

    test('outOfRange with only min', () {
      final e = ValidationException.outOfRange('amount', min: 0);
      expect(e.message, contains('>= 0'));
    });

    test('outOfRange with only max', () {
      final e = ValidationException.outOfRange('count', max: 100);
      expect(e.message, contains('<= 100'));
    });

    test('duplicate factory', () {
      final e = ValidationException.duplicate('name', 'Food');
      expect(e.message, 'name "Food" already exists');
      expect(e.code, 'DUPLICATE');
      expect(e.field, 'name');
      expect(e.rule, 'unique');
    });
  });

  group('ImportException', () {
    test('invalidFormat factory', () {
      final e = ImportException.invalidFormat('csv');
      expect(e.message, 'Invalid csv file format');
      expect(e.code, 'INVALID_FORMAT');
      expect(e.format, 'csv');
    });

    test('parseError factory', () {
      final e = ImportException.parseError('csv', 42);
      expect(e.message, contains('line 42'));
      expect(e.code, 'PARSE_ERROR');
      expect(e.lineNumber, 42);
    });

    test('fileNotSelected factory', () {
      final e = ImportException.fileNotSelected();
      expect(e.code, 'NO_FILE');
    });
  });

  group('ExportException', () {
    test('writeFailed factory', () {
      final e = ExportException.writeFailed('sqlite');
      expect(e.message, contains('sqlite'));
      expect(e.code, 'WRITE_FAILED');
      expect(e.format, 'sqlite');
    });

    test('shareFailed factory', () {
      final e = ExportException.shareFailed();
      expect(e.code, 'SHARE_FAILED');
    });
  });
}
