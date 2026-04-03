import 'package:cachium/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger', () {
    test('can be constructed with a tag', () {
      const logger = AppLogger('TestTag');
      expect(logger.tag, 'TestTag');
    });

    test('debug does not throw', () {
      const logger = AppLogger('Test');
      expect(() => logger.debug('test message'), returnsNormally);
    });

    test('warning does not throw', () {
      const logger = AppLogger('Test');
      expect(() => logger.warning('test warning'), returnsNormally);
    });

    test('error does not throw without error object', () {
      const logger = AppLogger('Test');
      expect(() => logger.error('test error'), returnsNormally);
    });

    test('error does not throw with error object', () {
      const logger = AppLogger('Test');
      expect(
        () => logger.error('test error', Exception('cause')),
        returnsNormally,
      );
    });

    test('is const-constructible', () {
      // Verify it works as a const field
      const logger = AppLogger('Static');
      expect(logger.tag, 'Static');
    });
  });
}
