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
  });
}
