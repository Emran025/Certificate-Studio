import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Arabic PDF rendering keeps source Unicode instead of presentation forms',
    () {
      String readSource(String path) =>
          File(path).readAsStringSync().replaceAll('\r\n', '\n');

      final source = readSource(
        'lib/features/certificate_generation/domain/certificate_artifact_renderer.dart',
      );

      expect(source, isNot(contains('ArabicReshaper.instance.reshape')));
      expect(
        source,
        contains('static String _pdfText(String value) => value;'),
      );
      expect(source, contains('fontFallback: [\n        defaultFont,'));
      expect(source, contains('static bool _containsRtl(String value)'));
      expect(source, contains(r'\u0590-\u05FF'));
      expect(source, contains('on Object {'));
      expect(source, contains("fonts['Cairo'] ?? fonts.values.first"));
      expect(source, contains('defaultFont,\n        ...fonts.values'));

      final pdfOptions = readSource('packages/pdf/lib/src/pdf/options.dart');
      expect(pdfOptions, contains('defaultValue: true'));
      expect(
        readSource('pubspec.yaml'),
        contains('path: packages/pdf'),
      );

      final designer = readSource(
        'lib/features/certificate_designer/presentation/screens/certificate_designer_screen.dart',
      );
      expect(designer, contains('FontLoader(family)'));
      expect(designer, contains("row['font_bytes']"));

      final schema = readSource('lib/core/database/database_tables.dart');
      expect(schema, contains('font_bytes BLOB'));
    },
  );
}
