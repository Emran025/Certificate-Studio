import 'package:certificate_studio/config/env/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes safe stable defaults', () {
    expect(AppEnvironment.appNameKey, 'Certificate Studio');
    expect(AppEnvironment.defaultLocale, 'en');
    expect(AppEnvironment.supportedLocales, containsAll(['en', 'ar']));
    expect(AppEnvironment.maxRecentProjects, greaterThan(0));
    expect(AppEnvironment.defaultExportFilePattern, contains('.pdf'));
  });
}
