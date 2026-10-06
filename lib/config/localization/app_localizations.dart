import 'package:flutter/widgets.dart';

part 'app_localizations_en.dart';
part 'app_localizations_ar.dart';

/// Offline-first localization for the application UI.
///
/// English is the source language. Arabic is selected automatically when the
/// device language is Arabic; every other device language falls back to English.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('en'), Locale('ar')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  bool get isArabic => locale.languageCode.toLowerCase() == 'ar';

  String text(String key, [Map<String, String> args = const {}]) {
    if (isArabic) {
      if (key == 'Static text') return 'نص ثابت';
      if (key == 'Text') return 'النص';
      if (key == 'Add') return 'إضافة';
      if (key == 'signed' || key == 'Signed') return 'موقّعة';
      if (key == 'draft' || key == 'Draft') return 'مسودة';
      if (key.endsWith(' selected')) {
        final count = key.substring(0, key.length - ' selected'.length);
        return '$count محدد';
      }
      if (key.endsWith(' persisted projects') ||
          key.endsWith(' persisted project')) {
        final count = key.split(' ').first;
        return '$count مشروع محفوظ';
      }

      if (key.startsWith('Verification could not be completed: ')) {
        return 'تعذر إكمال التحقق: ${key.substring('Verification could not be completed: '.length)}';
      }
      if (key.startsWith('Verification failed: ')) {
        return 'فشل التحقق: ${key.substring('Verification failed: '.length)}';
      }
      if (key.startsWith('Unable to load projects: ')) {
        return 'تعذر تحميل المشاريع: ${key.substring('Unable to load projects: '.length)}';
      }
      if (key.startsWith('Generation failed: ')) {
        return 'فشل الإنشاء: ${key.substring('Generation failed: '.length)}';
      }
      if (key.startsWith('Delete ') && key.endsWith('?')) {
        final name = key.substring('Delete '.length, key.length - 1);
        return 'حذف $name؟';
      }
      if (key.startsWith('Design · ')) {
        return 'تصميم · ${key.substring('Design · '.length)}';
      }
      if (key.startsWith('Generate · ')) {
        return 'إنشاء · ${key.substring('Generate · '.length)}';
      }
      if (key.startsWith('Export failed: ')) {
        return 'فشل التصدير: ${key.substring('Export failed: '.length)}';
      }
      if (key.endsWith(' records saved')) {
        final count = key.substring(0, key.length - ' records saved'.length);
        return '$count سجل محفوظ';
      }
      if (key.contains(' recipients processed')) {
        final match = RegExp(
          r'(\d+)\s+of\s+(\d+)\s+recipients processed',
        ).firstMatch(key);
        if (match != null) {
          return 'تمت معالجة ${match.group(1)} من ${match.group(2)} مستلم';
        }
      }
      if (key.endsWith(' exported as a ZIP archive.')) {
        final count = key
            .substring(0, key.length - ' exported as a ZIP archive.'.length)
            .replaceAll(' certificates', '')
            .replaceAll(' certificate', '');
        return 'تم تصدير $count شهادة كأرشيف ZIP.';
      }
      if (key.contains(' generated certificate') &&
          key.contains('available in the library.')) {
        final count = key.split(' ').first;
        return '$count شهادة منشأة متاحة في المكتبة.';
      }
      if (key.startsWith('Job ') && key.contains(' · ')) {
        final parts = key.substring('Job '.length).split(' · ');
        final statusMap = {
          'completed': 'مكتمل',
          'failed': 'فشل',
          'running': 'قيد التشغيل',
          'pending': 'قيد الانتظار',
        };
        final status = statusMap[parts.last.toLowerCase()] ?? parts.last;
        return 'المهمة ${parts.first} · $status';
      }
      if (RegExp(r'^\d+ persisted project(s)?$').hasMatch(key)) {
        final count = key.split(' ').first;
        return '$count مشروع محفوظ';
      }
      if (key.endsWith(' deleted')) {
        return '${key.substring(0, key.length - ' deleted'.length)} تم حذفه';
      }
    }
    final dictionary = isArabic ? _ar : _en;
    var value = dictionary[key] ?? dictionary[key.toLowerCase()] ?? key;
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
