import 'package:flutter/widgets.dart';

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
    final dictionary = isArabic ? _ar : _en;
    var value = dictionary[key] ?? dictionary[key.toLowerCase()] ?? key;
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  static const _en = <String, String>{
    'localWorkspaceUnavailable': 'Local workspace is unavailable.',
    'home': 'Home', 'projects': 'Projects', 'templates': 'Templates',
    'fonts': 'Fonts', 'certificates': 'Certificates', 'verification': 'Verification',
    'settings': 'Settings', 'workspace': 'Workspace',
    'createManageCertificates': 'Create and manage your certificates',
    'offlineReady': 'Offline ready', 'notifications': 'Notifications',
    'verify': 'Verify', 'newProject': 'New project', 'importProject': 'Import project',
    'recentProjects': 'Recent projects', 'yourWorkspace': 'Your workspace',
    'createFirstProject': 'Create your first project',
    'firstProjectDescription': 'Start with project information, then add a template and student data.',
    'createProject': 'Create project', 'failedLoadProjects': 'Failed to load projects. Please try again.',
    'verifyCertificate': 'Verify certificate', 'selectCertificateFile': 'Select certificate file',
    'certificateFile': 'Certificate file', 'qrVerification': 'QR verification',
    'certificateId': 'Certificate ID', 'verifyQrPayload': 'Verify QR payload',
    'verifyCertificateId': 'Verify certificate ID', 'qrPayload': 'QR payload',
    'cancel': 'Cancel', 'save': 'Save', 'close': 'Close', 'delete': 'Delete',
    'addDataField': 'Add data field', 'select': 'Select', 'search': 'Search',
    'success': 'Success', 'error': 'Error', 'continue': 'Continue', 'back': 'Back',
    'persistedFonts': '{count} persisted fonts available to projects.',
  };

  static const _ar = <String, String>{
    'localWorkspaceUnavailable': 'مساحة العمل المحلية غير متاحة.',
    'home': 'الرئيسية', 'projects': 'المشاريع', 'templates': 'القوالب',
    'fonts': 'الخطوط', 'certificates': 'الشهادات', 'verification': 'التحقق',
    'settings': 'الإعدادات', 'workspace': 'مساحة العمل',
    'createManageCertificates': 'أنشئ شهاداتك وأدرها بسهولة',
    'offlineReady': 'جاهز للعمل دون اتصال', 'notifications': 'الإشعارات',
    'verify': 'تحقق', 'newProject': 'مشروع جديد', 'importProject': 'استيراد مشروع',
    'recentProjects': 'المشاريع الأخيرة', 'yourWorkspace': 'مساحة عملك',
    'createFirstProject': 'أنشئ مشروعك الأول',
    'firstProjectDescription': 'ابدأ بمعلومات المشروع، ثم أضف قالبًا وبيانات الطلاب.',
    'createProject': 'إنشاء مشروع', 'failedLoadProjects': 'تعذر تحميل المشاريع. يرجى المحاولة مرة أخرى.',
    'verifyCertificate': 'التحقق من الشهادة', 'selectCertificateFile': 'اختيار ملف الشهادة',
    'certificateFile': 'ملف الشهادة', 'qrVerification': 'التحقق عبر رمز QR',
    'certificateId': 'معرّف الشهادة', 'verifyQrPayload': 'التحقق من بيانات QR',
    'verifyCertificateId': 'التحقق من معرّف الشهادة', 'qrPayload': 'بيانات QR',
    'cancel': 'إلغاء', 'save': 'حفظ', 'close': 'إغلاق', 'delete': 'حذف',
    'addDataField': 'إضافة حقل بيانات', 'select': 'اختيار', 'search': 'بحث',
    'success': 'تم بنجاح', 'error': 'خطأ', 'continue': 'متابعة', 'back': 'رجوع',
    'Academy or institution name': 'اسم الأكاديمية أو المؤسسة',
    'Arabic name': 'الاسم بالعربية', 'Back to workspace': 'العودة إلى مساحة العمل',
    'Certificate': 'الشهادة', 'Choose Excel file': 'اختيار ملف Excel',
    'Contact information': 'معلومات التواصل', 'Course': 'الدورة',
    'Course / project': 'الدورة / المشروع', 'Course or program': 'الدورة أو البرنامج',
    'Created': 'تاريخ الإنشاء', 'Data source field': 'حقل مصدر البيانات',
    'Description': 'الوصف', 'Design': 'التصميم', 'Digital signature': 'التوقيع الرقمي',
    'Document hash': 'تجزئة المستند', 'Draft': 'مسودة',
    'Email, phone, or website': 'البريد الإلكتروني أو الهاتف أو الموقع',
    'English name': 'الاسم بالإنجليزية', 'Failed': 'فشل', 'Font family': 'عائلة الخط',
    'Font size': 'حجم الخط', 'Format': 'التنسيق', 'Generate': 'إنشاء',
    'Generate and create verification records': 'إنشاء سجلات التحقق',
    'Generated': 'تم الإنشاء', 'Generated certificates': 'الشهادات المنشأة',
    'Height': 'الارتفاع', 'Identifier': 'المعرّف', 'Institution': 'المؤسسة',
    'Institution name': 'اسم المؤسسة', 'Institution name *': 'اسم المؤسسة *',
    'Integrity': 'سلامة البيانات', 'Issue date': 'تاريخ الإصدار',
    'Optional project notes': 'ملاحظات المشروع الاختيارية', 'Organization': 'الجهة',
    'Paste from clipboard': 'لصق من الحافظة', 'Paste table data': 'لصق بيانات الجدول',
    'Project name *': 'اسم المشروع *', 'Project workspace': 'مساحة عمل المشروع',
    'QR extraction': 'استخراج QR', 'Recent projects': 'المشاريع الأخيرة',
    'Recipient': 'المستلم', 'Redo': 'إعادة', 'Refresh': 'تحديث',
    'Save design': 'حفظ التصميم', 'Status': 'الحالة', 'Student data': 'بيانات الطلاب',
    'Template': 'القالب', 'Text alignment': 'محاذاة النص',
    'Text color (#RRGGBB)': 'لون النص (#RRGGBB)', 'Text direction': 'اتجاه النص',
    'Use template': 'استخدام القالب', 'View': 'عرض', 'Total': 'الإجمالي',
    'Type': 'النوع', 'Undo': 'تراجع', 'Width': 'العرض', 'Zoom in': 'تكبير',
    'Zoom out': 'تصغير', 'Add a field from imported data to start designing.': 'أضف حقلًا من البيانات المستوردة لبدء التصميم.',
    'Add data field': 'إضافة حقل بيانات', 'Add template': 'إضافة قالب',
    'Additional lookup method for certificates already available in this offline workspace.': 'طريقة بحث إضافية للشهادات المتاحة في مساحة العمل غير المتصلة.',
    'Bold': 'عريض', 'Browse': 'استعراض', 'Center': 'توسيط', 'Data field': 'حقل البيانات',
    'Delete field': 'حذف الحقل', 'Elements': 'العناصر', 'Export': 'تصدير',
    'Export PDF': 'تصدير PDF', 'Export PNG': 'تصدير PNG', 'Font library': 'مكتبة الخطوط',
    'Import font': 'استيراد خط', 'Italic': 'مائل', 'Layers': 'الطبقات',
    'Left': 'يسار', 'No fonts have been imported yet.': 'لم يتم استيراد أي خطوط بعد.',
    'Open certificate library': 'فتح مكتبة الشهادات', 'QR code': 'رمز QR',
    'RTL': 'من اليمين إلى اليسار', 'LTR': 'من اليسار إلى اليمين', 'Right': 'يمين',
    'Scan the QR code with your device and paste its cstudio:// payload here.': 'امسح رمز QR بجهازك والصق بيانات cstudio:// هنا.',
    'Select a field to edit its properties.': 'اختر حقلًا لتعديل خصائصه.',
    'Select a field': 'اختيار حقل', 'Template image unavailable': 'صورة القالب غير متاحة',
    'Use the certificate file itself. Verification runs offline from its embedded security record.': 'استخدم ملف الشهادة نفسه. يعمل التحقق دون اتصال اعتمادًا على سجل الأمان المضمّن.',
    'X': 'س', 'Y': 'ص',
    'Verify certificate': 'التحقق من الشهادة', 'Certificate file': 'ملف الشهادة',
    'QR verification': 'التحقق عبر رمز QR',
    'Arabic text keeps its original Unicode characters. If a selected font misses a glyph, the preview and export use the next available fallback font.': 'يحتفظ النص العربي بمحارف Unicode الأصلية. إذا كان الخط المحدد لا يدعم رمزًا، فسيستخدم العرض والتصدير خطًا احتياطيًا مناسبًا.',
    'persistedFonts': '{count} خط محفوظ متاح للمشاريع.',
  };
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((item) => item.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
