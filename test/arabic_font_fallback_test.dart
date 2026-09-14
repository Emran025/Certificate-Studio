import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Arabic PDF rendering keeps source Unicode instead of presentation forms', () {
    final source = File(
      'lib/features/certificate_generation/domain/certificate_artifact_renderer.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('ArabicReshaper.instance.reshape')));
    expect(source, contains('static String _pdfText(String value) => value;'));
    expect(source, contains('fontFallback: fonts.values.where'));

    final designer = File(
      'lib/features/certificate_designer/presentation/screens/certificate_designer_screen.dart',
    ).readAsStringSync();
    expect(designer, contains('FontLoader(family)'));
    expect(designer, contains("row['font_bytes']"));

    final schema = File(
      'lib/core/database/database_tables.dart',
    ).readAsStringSync();
    expect(schema, contains('font_bytes BLOB'));
  });
}
