/// Build-independent application configuration.
///
/// Secrets and institution keys must never be hard-coded here. They belong in
/// the platform key storage abstraction described by the project architecture.
abstract final class AppEnvironment {
  static const appName = 'اسـتوديو الشهـــــــائد'; // 'Certificate Studio'
  static const appVersion = '1.0.0';
  static const supportedLocales = ['en', 'ar'];
  static const defaultLocale = 'en';
  static const projectFileExtensions = ['cstudio', 'certproject'];
  static const maxRecentProjects = 5;
  static const defaultExportFilePattern = '{field_1}_{field_2}.pdf';
}
