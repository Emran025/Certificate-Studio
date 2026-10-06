import 'dart:io';

import 'package:certificate_studio/features/templates/presentation/template_file_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;
  late String existingPng;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'certificate-template-test-',
    );
    existingPng = '${tempDirectory.path}/background.png';
    File(existingPng).writeAsBytesSync([137, 80, 78, 71]);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  test('validates empty, missing, supported, and unsupported paths', () {
    expect(validateTemplatePath('  '), 'Required');
    expect(
      validateTemplatePath('${tempDirectory.path}/missing.png'),
      'File does not exist',
    );
    expect(validateTemplatePath(existingPng), isNull);

    final txt = '${tempDirectory.path}/background.txt';
    File(txt).writeAsStringSync('not an image');
    expect(validateTemplatePath(txt), 'Use PNG, JPG, or WEBP image');
    expect(templateFileExists(existingPng), isTrue);
    expect(templateFileExists('${tempDirectory.path}/missing.png'), isFalse);
  });

  testWidgets('returns a fallback preview for a missing file', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: templatePreview('${tempDirectory.path}/missing.png'),
        ),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });

  testWidgets('returns a canvas fallback for a missing file', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: templateCanvasPreview('${tempDirectory.path}/missing.png'),
        ),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
  });
}
