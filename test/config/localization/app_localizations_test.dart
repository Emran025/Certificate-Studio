import 'package:certificate_studio/config/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('supports Arabic and English locales', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('ar')));
  });

  test('returns translated Arabic labels', () {
    const arabic = AppLocalizations(Locale('ar'));
    expect(arabic.isArabic, isTrue);
    expect(arabic.text('home'), 'الرئيسية');
    expect(arabic.text('Verify'), 'تحقق');
  });

  test('falls back to English for unsupported device languages', () {
    const english = AppLocalizations(Locale('fr'));
    expect(english.isArabic, isFalse);
    expect(english.text('home'), 'Home');
  });
}
