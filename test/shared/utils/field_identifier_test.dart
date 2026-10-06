import 'package:certificate_studio/shared/utils/field_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes whitespace and punctuation', () {
    expect(canonicalFieldClassId('  Student Name  '), 'student_name');
    expect(canonicalFieldClassId('Course-2026'), 'course_2026');
  });

  test('preserves unicode letters and provides fallback for empty values', () {
    expect(canonicalFieldClassId(' اسم الطالب '), 'اسم_الطالب');
    expect(canonicalFieldClassId('---'), 'field');
  });
}
