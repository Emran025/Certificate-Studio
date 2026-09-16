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
    'Add student data': 'Add student data',
    'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.': 'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.',
    'Choose Excel file': 'Choose Excel file', 'Paste from clipboard': 'Paste from clipboard',
    'Saving...': 'Saving...', 'Import data': 'Import data', 'Data preview': 'Data preview',
    'No recipient data yet. Import a table to continue to certificate design.': 'No recipient data yet. Import a table to continue to certificate design.',
    'Set up your institution': 'Set up your institution',
    'This information is used to identify your certificates and verification records.': 'This information is used to identify your certificates and verification records.',
    'A private institution key will be generated and kept behind secure storage. It is never displayed or written into the project package.': 'A private institution key will be generated and kept behind secure storage. It is never displayed or written into the project package.',
    'Continue to workspace': 'Continue to workspace', 'Institution name is required.': 'Institution name is required.',
    'Project information': 'Project information',
    'Set up the context for this certificate-issuing project. You can configure templates and data next.': 'Set up the context for this certificate-issuing project. You can configure templates and data next.',
    'Project name is required.': 'Project name is required.', 'Certificate type': 'Certificate type',
    'Training': 'Training', 'Achievement': 'Achievement', 'Participation': 'Participation', 'Custom': 'Custom',
    'Creating...': 'Creating...', 'Continue': 'Continue',
    'Configure this project, then design and generate certificates.': 'Configure this project, then design and generate certificates.',
    'Project workspace': 'Project workspace', 'Choose the certificate background.': 'Choose the certificate background.',
    'Import or paste recipient data.': 'Import or paste recipient data.',
    'Choose the font available to this project.': 'Choose the font available to this project.',
    'Place fields on the certificate canvas.': 'Place fields on the certificate canvas.',
    'Create certificates after setup is complete.': 'Create certificates after setup is complete.',
    'Not set': 'Not set', 'The certificate could not be verified.': 'The certificate could not be verified.',
    'Success — QR payload was extracted from the image': 'Success — QR payload was extracted from the image',
    'Failed — no readable QR code was found': 'Failed — no readable QR code was found',
    'Hash matches embedded certificate data': 'Hash matches embedded certificate data',
    'Valid Ed25519 signature': 'Valid Ed25519 signature', 'Not provided': 'Not provided',
    'Certificate template': 'Certificate template', 'Template image unavailable': 'Template image unavailable',
    'Search by recipient, certificate ID, or project': 'Search by recipient, certificate ID, or project',
    'Please select a PDF, PNG, JPG, or JPEG certificate.': 'Please select a PDF, PNG, JPG, or JPEG certificate.',
    'tableDataExample': 'Field 1\tField 2\tField 3\nValue 1\tValue 2\tValue 3',
    'Choose a certificate template': 'Choose a certificate template', 'Template library': 'Template library',
    'Choose a background image from your device, preview it, and use it as this project’s certificate canvas.': 'Choose a background image from your device, preview it, and use it as this project’s certificate canvas.',
    'Browse persisted certificate backgrounds or import a new template.': 'Browse persisted certificate backgrounds or import a new template.',
    'No templates saved yet. Add a PNG, JPG, or WEBP background image to continue.': 'No templates saved yet. Add a PNG, JPG, or WEBP background image to continue.',
    'File not found at saved path': 'File not found at saved path', 'Selected': 'Selected', 'Required': 'Required',
    'Valid certificate': 'Valid certificate', 'Integrity compromised': 'Integrity compromised',
    'Invalid signature': 'Invalid signature', 'Unknown certificate': 'Unknown certificate',
    'Verification data missing': 'Verification data missing',
    'Unsupported or malformed certificate': 'Unsupported or malformed certificate',
    'Verification failed': 'Verification failed',
    'QR extraction failed and no embedded verification record was found in the image.': 'QR extraction failed and no embedded verification record was found in the image.',
    'We could not save your institution. Please try again.': 'We could not save your institution. Please try again.',
    'We could not create this project. Please try again.': 'We could not create this project. Please try again.',
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
    'Add student data': 'إضافة بيانات الطلاب',
    'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.': 'استورد ملف ‎.xlsx أو الصق جدولًا. سيصبح الصف الأول أسماء الأعمدة.',

    'Saving...': 'جارٍ الحفظ...', 'Import data': 'استيراد البيانات', 'Data preview': 'معاينة البيانات',
    'No recipient data yet. Import a table to continue to certificate design.': 'لا توجد بيانات مستلمين بعد. استورد جدولًا للمتابعة إلى تصميم الشهادة.',
    'Set up your institution': 'إعداد المؤسسة',
    'This information is used to identify your certificates and verification records.': 'تُستخدم هذه المعلومات للتعريف بشهاداتك وسجلات التحقق.',
    'A private institution key will be generated and kept behind secure storage. It is never displayed or written into the project package.': 'سيتم إنشاء مفتاح خاص بالمؤسسة وحفظه في تخزين آمن. لن يتم عرضه أو كتابته داخل حزمة المشروع.',
    'Continue to workspace': 'المتابعة إلى مساحة العمل', 'Institution name is required.': 'اسم المؤسسة مطلوب.',
    'Project information': 'معلومات المشروع',
    'Set up the context for this certificate-issuing project. You can configure templates and data next.': 'حدّد سياق مشروع إصدار الشهادات. يمكنك إعداد القوالب والبيانات لاحقًا.',
    'Project name is required.': 'اسم المشروع مطلوب.', 'Certificate type': 'نوع الشهادة',
    'Training': 'تدريب', 'Achievement': 'إنجاز', 'Participation': 'مشاركة', 'Custom': 'مخصص',
    'Creating...': 'جارٍ الإنشاء...', 'Continue': 'متابعة',
    'Configure this project, then design and generate certificates.': 'اضبط هذا المشروع ثم صمّم الشهادات وأنشئها.',
    'Choose the certificate background.': 'اختر خلفية الشهادة.',
    'Import or paste recipient data.': 'استورد بيانات المستلمين أو الصقها.',
    'Choose the font available to this project.': 'اختر الخط المتاح لهذا المشروع.',
    'Place fields on the certificate canvas.': 'ضع الحقول على لوحة الشهادة.',
    'Create certificates after setup is complete.': 'أنشئ الشهادات بعد اكتمال الإعداد.',
    'Not set': 'غير محدد', 'The certificate could not be verified.': 'تعذر التحقق من الشهادة.',
    'Success — QR payload was extracted from the image': 'نجح استخراج بيانات QR من الصورة',
    'Failed — no readable QR code was found': 'فشل — لم يتم العثور على رمز QR قابل للقراءة',
    'Hash matches embedded certificate data': 'التجزئة مطابقة لبيانات الشهادة المضمّنة',
    'Valid Ed25519 signature': 'توقيع Ed25519 صالح', 'Not provided': 'غير متوفر',
    'Certificate template': 'قالب الشهادة',
    'Search by recipient, certificate ID, or project': 'البحث بالمستلم أو معرّف الشهادة أو المشروع',
    'Please select a PDF, PNG, JPG, or JPEG certificate.': 'يرجى اختيار شهادة بصيغة PDF أو PNG أو JPG أو JPEG.',
    'tableDataExample': 'الحقل 1\tالحقل 2\tالحقل 3\nالقيمة 1\tالقيمة 2\tالقيمة 3',
    'Choose a certificate template': 'اختر قالب شهادة', 'Template library': 'مكتبة القوالب',
    'Choose a background image from your device, preview it, and use it as this project’s certificate canvas.': 'اختر صورة خلفية من جهازك، واعرضها ثم استخدمها كلوحة شهادة للمشروع.',
    'Browse persisted certificate backgrounds or import a new template.': 'استعرض خلفيات الشهادات المحفوظة أو استورد قالبًا جديدًا.',
    'No templates saved yet. Add a PNG, JPG, or WEBP background image to continue.': 'لا توجد قوالب محفوظة بعد. أضف صورة خلفية بصيغة PNG أو JPG أو WEBP للمتابعة.',
    'File not found at saved path': 'لم يتم العثور على الملف في المسار المحفوظ', 'Selected': 'محدد', 'Required': 'مطلوب',
    'Valid certificate': 'شهادة صالحة', 'Integrity compromised': 'تم اكتشاف خلل في سلامة البيانات',
    'Invalid signature': 'توقيع غير صالح', 'Unknown certificate': 'شهادة غير معروفة',
    'Verification data missing': 'بيانات التحقق مفقودة',
    'Unsupported or malformed certificate': 'شهادة غير مدعومة أو تالفة',
    'Verification failed': 'فشل التحقق',
    'QR extraction failed and no embedded verification record was found in the image.': 'فشل استخراج QR ولم يتم العثور على سجل تحقق مضمّن في الصورة.',
    'We could not save your institution. Please try again.': 'تعذر حفظ المؤسسة. يرجى المحاولة مرة أخرى.',
    'We could not create this project. Please try again.': 'تعذر إنشاء المشروع. يرجى المحاولة مرة أخرى.',
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
