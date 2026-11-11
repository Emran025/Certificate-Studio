import 'package:certificate_studio/features/sharing/domain/usecases/normalize_phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normalize = NormalizePhoneNumber();

  test(
    'normalizes international numbers with plus, 00, or explicit country code',
    () {
      expect(normalize('+967 712 345 678'), '967712345678');
      expect(normalize('00967-712-345-678'), '967712345678');
      expect(normalize('967712345678'), '967712345678');
    },
  );

  test('converts Arabic and Persian digits to ASCII', () {
    expect(normalize('+٩٦٧ ٧١٢٣٤٥٦٧٨'), '967712345678');
    expect(normalize('+۹۶۷ ۷۱۲۳۴۵۶۷۸'), '967712345678');
  });

  test('does not treat local or incomplete values as direct recipients', () {
    expect(normalize('712345678'), isNull);
    expect(normalize('1234567890'), isNull);
    expect(normalize(''), isNull);
    expect(normalize(null), isNull);
  });
}
