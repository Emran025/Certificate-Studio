import 'package:certificate_studio/core/entities/operation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OperationResult', () {
    test('folds a success and exposes its value', () {
      const result = OperationSuccess<int>(42);

      expect(result.isSuccess, isTrue);
      expect(
        result.fold(
          success: (value) => 'value:$value',
          failure: (message) => message,
        ),
        'value:42',
      );
    });

    test('folds a failure and exposes its message', () {
      const result = OperationFailure<int>('network unavailable');

      expect(result.isSuccess, isFalse);
      expect(
        result.fold(
          success: (value) => '$value',
          failure: (message) => message,
        ),
        'network unavailable',
      );
    });
  });
}
