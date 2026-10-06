import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps tests inside architecture-owned directories', () {
    final root = Directory('test');
    final rootDartFiles = root.listSync().whereType<File>().where(
      (file) => file.path.endsWith('_test.dart'),
    );

    expect(
      rootDartFiles,
      isEmpty,
      reason: 'Place every test under config, core, features, or shared.',
    );
  });

  test('uses descriptive test names and avoids coverage mega-files', () {
    final files = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'))
        .toList();

    expect(files, isNotEmpty);
    for (final file in files) {
      expect(
        file.uri.pathSegments.last,
        matches(RegExp(r'^[a-z0-9_]+_test\.dart$')),
      );
      expect(file.lengthSync(), lessThan(70000), reason: file.path);
    }
    expect(files.any((file) => file.path.contains('coverage')), isFalse);
  });
}
