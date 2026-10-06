import 'dart:io';

import 'package:certificate_studio/core/files/project_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProvider extends PathProviderPlatform {
  FakePathProvider(this.directory);
  final String directory;

  @override
  Future<String?> getApplicationSupportPath() async => directory;
}

void main() {
  late Directory tempDirectory;
  late PathProviderPlatform previousPlatform;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'certificate-assets-test-',
    );
    previousPlatform = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tempDirectory.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = previousPlatform;
    if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
  });

  test('saves project background bytes on the active platform', () async {
    final path = await saveProjectBackground(
      fileName: 'background.bin',
      bytes: [1, 2, 3],
    );

    expect(
      path,
      '${tempDirectory.path}${Platform.pathSeparator}project_backgrounds${Platform.pathSeparator}background.bin',
    );
    final file = File(path!);
    expect(file.existsSync(), isTrue);
    expect(file.readAsBytesSync(), [1, 2, 3]);
  });
}
