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
    if (isArabic) {
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

  static const _en = <String, String>{
    'Project workspace': 'Project workspace',
    'Manage projects and import existing workspaces.':
        'Manage projects and import existing workspaces.',
    'Projectworkspace': 'Projectworkspace',
    'New project': 'New project',
    'Import project': 'Import project',
    'Recent projects': 'Recent projects',
    'Your workspace': 'Your workspace',
    'Create project': 'Create project',
    'Create your first project': 'Create your first project',
    'Start with project information, then add a template and student data.':
        'Start with project information, then add a template and student data.',
    'No projects have been created yet.': 'No projects have been created yet.',
    'Offline ready': 'Offline ready',
    'Draft': 'Draft',
    'Verify certificate': 'Verify certificate',
    'Use the certificate file itself. Verification runs offline from its embedded security record.':
        'Use the certificate file itself. Verification runs offline from its embedded security record.',
    'Certificate file': 'Certificate file',
    'Select an issued certificate. For PNG/JPG images, the QR code is extracted automatically and the result reports extraction success or failure.':
        'Select an issued certificate. For PNG/JPG images, the QR code is extracted automatically and the result reports extraction success or failure.',
    'Select certificate file': 'Select certificate file',
    'QR verification': 'QR verification',
    'Scan the QR code with your device and paste its cstudio:// payload here.':
        'Scan the QR code with your device and paste its cstudio:// payload here.',
    'QR payload': 'QR payload',
    'Verify QR payload': 'Verify QR payload',
    'Certificate ID': 'Certificate ID',
    'Additional lookup method for certificates already available in this offline workspace.':
        'Additional lookup method for certificates already available in this offline workspace.',
    'Verify certificate ID': 'Verify certificate ID',
    'certificate-…': 'certificate-…',
    'Certificate library': 'Certificate library',
    'Export all': 'Export all',
    'Export project': 'Export project',
    'Export the background, font, data, and field positions.':
        'Export the background, font, data, and field positions.',
    'Student data': 'Student data',
    'Export all PNG files (ZIP)': 'Export all PNG files (ZIP)',
    'Export all PDF files (ZIP)': 'Export all PDF files (ZIP)',
    'Generated certificates': 'Generated certificates',
    'Browse, preview, verify, and export the actual generated certificate files.':
        'Browse, preview, verify, and export the actual generated certificate files.',
    'Search by recipient, certificate ID, or project':
        'Search by recipient, certificate ID, or project',
    'signed': 'signed',
    'Signed': 'Signed',
    'valid': 'valid',
    'failed': 'failed',
    'pending': 'pending',
    'generating': 'generating',
    'generated': 'generated',
    'Recipient unavailable': 'Recipient unavailable',
    'Certificate Studio': 'Certificate Studio',
    'Certificate preview': 'Certificate preview',
    'Certificate export settings': 'Certificate export settings',
    'Choose file name field': 'Choose file name field',
    'Field used for the file name': 'Field used for the file name',
    'Archive style': 'Archive style',
    'All files in one ZIP': 'All files in one ZIP',
    'ZIP per certificate with signature.txt':
        'ZIP per certificate with signature.txt',
    'Certificate details': 'Certificate details',
    'Recipient': 'Recipient',
    'Status': 'Status',
    'Available': 'Available',
    'Unavailable': 'Unavailable',
    'Security': 'Security',
    'Valid signature': 'Valid signature',
    'Verification failed': 'Verification failed',
    'The certificate is authentic.': 'The certificate is authentic.',
    'Unable to verify.': 'Unable to verify.',
    'View': 'View',
    'Export PNG': 'Export PNG',
    'Export PDF': 'Export PDF',
    'Export PNG ZIP': 'Export PNG ZIP',
    'Export PDF ZIP': 'Export PDF ZIP',
    'No certificates match your search.': 'No certificates match your search.',
    'No certificates generated yet.': 'No certificates generated yet.',
    'Field properties': 'Field properties',
    'Position and size': 'Position and size',
    'Select a template before designing this certificate.':
        'Select a template before designing this certificate.',
    'Import recipient data first so fields can be mapped to columns.':
        'Import recipient data first so fields can be mapped to columns.',
    'Unsaved changes': 'Unsaved changes',
    'Saved': 'Saved',
    'Saving...': 'Saving...',
    'Template name': 'Template name',
    'Background image': 'Background image',
    'Choose image': 'Choose image',
    'DPI': 'DPI',
    'Choose a certificate template': 'Choose a certificate template',
    'Template library': 'Template library',
    'Add template': 'Add template',
    'Use template': 'Use template',
    'Edit template': 'Edit template',
    'Selected': 'Selected',
    'In use': 'In use',
    'Use': 'Use',
    'Import font': 'Import font',
    'Font library': 'Font library',
    'Manage fonts available to projects.':
        'Manage fonts available to projects.',
    'Live font preview': 'Live font preview',
    'Write a sample to compare how every imported font renders it.':
        'Write a sample to compare how every imported font renders it.',
    'Preview text': 'Preview text',
    'Generate certificates': 'Generate certificates',
    'Create signed PDF and high-resolution PNG certificates with offline verification records.':
        'Create signed PDF and high-resolution PNG certificates with offline verification records.',
    'Ready to generate': 'Ready to generate',
    'Generating certificates…': 'Generating certificates…',
    'Open certificate library': 'Open certificate library',
    'Certificate is authentic': 'Certificate is authentic',
    'The signature and document hash are valid.':
        'The signature and document hash are valid.',
    'The requested file is unavailable.': 'The requested file is unavailable.',
    'Certificate exported successfully.': 'Certificate exported successfully.',
    'No generated files were available to export.':
        'No generated files were available to export.',
    'Field used for the exported file name':
        'Field used for the exported file name',
    'Verification QR': 'Verification QR',
    'Set up your institution': 'Set up your institution',
    'Continue to workspace': 'Continue to workspace',
    'Add student data': 'Add student data',
    'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.':
        'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.',
    'Paste table data': 'Paste table data',
    'Choose Excel file': 'Choose Excel file',
    'Paste from clipboard': 'Paste from clipboard',
    'Import data': 'Import data',
    'Data preview': 'Data preview',
    'Fields': 'Fields',
    'fields detected': '{count} fields detected',
    'Add field': 'Add field',
    'Edit field': 'Edit field',
    'Delete field': 'Delete field',
    'Field name': 'Field name',
    'Field name must be unique and not empty.':
        'Field name must be unique and not empty.',
    'At least one field is required.': 'At least one field is required.',
    'Edit student': 'Edit student',
    'Student row {number}': 'Student row {number}',
    'Detected fixed values': 'Choose one of the detected values',
    'Value must be between {min} and {max}.':
        'Value must be between {min} and {max}.',
    'Editable student rows': 'Editable student rows',
    'Add student row': 'Add student row',
    'Delete student row': 'Delete student row',
    'Edit value': 'Edit value',
    'Row actions': 'Row actions',
    'No recipient data yet. Import a table to continue to certificate design.':
        'No recipient data yet. Import a table to continue to certificate design.',
    'Certificate type': 'Certificate type',
    'Creating...': 'Creating...',
    'Create new project': 'Create new project',
    'Delete project': 'Delete project',
    'Organization settings': 'Organization settings',
    'Control center': 'Control center',
    'Appearance & language': 'Appearance & language',
    'Application language': 'Application language',
    'Arabic': 'Arabic',
    'English': 'English',
    'Color mode': 'Color mode',
    'System': 'System',
    'Light': 'Light',
    'Dark': 'Dark',
    'Brand color': 'Brand color',
    'Open color picker': 'Open color picker',
    'Primary color': 'Primary color',
    'Choose custom color': 'Choose custom color',
    'Electronic signature': 'Electronic signature',
    'Export institution profile': 'Export institution profile',
    'Import institution profile': 'Import institution profile',
    'Export signatures': 'Export signatures',
    'Import signatures': 'Import signatures',

    'localWorkspaceUnavailable': 'Local workspace is unavailable.',
    'home': 'Home',
    'projects': 'Projects',
    'templates': 'Templates',
    'fonts': 'Fonts',
    'certificates': 'Certificates',
    'verification': 'Verification',
    'settings': 'Settings',
    'workspace': 'Workspace',
    'createManageCertificates': 'Create and manage your certificates',
    'offlineReady': 'Offline ready',
    'notifications': 'Notifications',
    'verify': 'Verify',
    'Open navigation': 'Open navigation',
    'newProject': 'New project',
    'importProject': 'Import project',
    'recentProjects': 'Recent projects',
    'yourWorkspace': 'Your workspace',
    'createFirstProject': 'Create your first project',
    'firstProjectDescription':
        'Start with project information, then add a template and student data.',
    'createProject': 'Create project',
    'failedLoadProjects': 'Failed to load projects. Please try again.',
    'verifyCertificate': 'Verify certificate',
    'selectCertificateFile': 'Select certificate file',
    'certificateFile': 'Certificate file',
    'qrVerification': 'QR verification',
    'certificateId': 'Certificate ID',
    'verifyQrPayload': 'Verify QR payload',
    'verifyCertificateId': 'Verify certificate ID',
    'qrPayload': 'QR payload',
    'cancel': 'Cancel',
    'save': 'Save',
    'close': 'Close',
    'delete': 'Delete',
    'addDataField': 'Add data field',
    'select': 'Select',
    'search': 'Search',
    'success': 'Success',
    'error': 'Error',
    'continue': 'Continue',
    'back': 'Back',
    'persistedFonts': '{count} persisted fonts available to projects.',
    'This information is used to identify your certificates and verification records.':
        'This information is used to identify your certificates and verification records.',
    'A private institution key will be generated and kept behind secure storage. It is never displayed or written into the project package.':
        'A private institution key will be generated and kept behind secure storage. It is never displayed or written into the project package.',
    'Institution name is required.': 'Institution name is required.',
    'Project information': 'Project information',
    'Set up the context for this certificate-issuing project. You can configure templates and data next.':
        'Set up the context for this certificate-issuing project. You can configure templates and data next.',
    'Project name is required.': 'Project name is required.',
    'Training': 'Training',
    'Achievement': 'Achievement',
    'Participation': 'Participation',
    'Custom': 'Custom',
    'Continue': 'Continue',
    'Configure this project, then design and generate certificates.':
        'Configure this project, then design and generate certificates.',
    'Choose the certificate background.': 'Choose the certificate background.',
    'Import or paste recipient data.': 'Import or paste recipient data.',
    'Choose the font available to this project.':
        'Choose the font available to this project.',
    'Place fields on the certificate canvas.':
        'Place fields on the certificate canvas.',
    'Create certificates after setup is complete.':
        'Create certificates after setup is complete.',
    'Not set': 'Not set',
    'The certificate could not be verified.':
        'The certificate could not be verified.',
    'Success — QR payload was extracted from the image':
        'Success — QR payload was extracted from the image',
    'Failed — no readable QR code was found':
        'Failed — no readable QR code was found',
    'Hash matches embedded certificate data':
        'Hash matches embedded certificate data',
    'Valid Ed25519 signature': 'Valid Ed25519 signature',
    'Not provided': 'Not provided',
    'Certificate template': 'Certificate template',
    'Template image unavailable': 'Template image unavailable',
    'Please select a PDF, PNG, JPG, or JPEG certificate.':
        'Please select a PDF, PNG, JPG, or JPEG certificate.',
    'Create and manage your certificates':
        'Create and manage your certificates',
    'Failed to load projects. Please try again.':
        'Failed to load projects. Please try again.',
    'projectUpdated': '{course}  •  Updated {date}',
    'Certificate project': 'Certificate project',
    'persistedProjects': '{count} persisted projects',
    'createdDate': 'Created {date}',
    'This permanently removes the project, recipient data, design, generated certificates, verification records, and project key.':
        'This permanently removes the project, recipient data, design, generated certificates, verification records, and project key.',
    'tableDataExample': 'Field 1\tField 2\tField 3\nValue 1\tValue 2\tValue 3',
    'Choose a background image from your device, preview it, and use it as this project’s certificate canvas.':
        'Choose a background image from your device, preview it, and use it as this project’s certificate canvas.',
    'Browse persisted certificate backgrounds or import a new template.':
        'Browse persisted certificate backgrounds or import a new template.',
    'No templates saved yet. Add a PNG, JPG, or WEBP background image to continue.':
        'No templates saved yet. Add a PNG, JPG, or WEBP background image to continue.',
    'File not found at saved path': 'File not found at saved path',
    'Required': 'Required',
    'Valid certificate': 'Valid certificate',
    'Integrity compromised': 'Integrity compromised',
    'Invalid signature': 'Invalid signature',
    'Unknown certificate': 'Unknown certificate',
    'Verification data missing': 'Verification data missing',
    'Unsupported or malformed certificate':
        'Unsupported or malformed certificate',
    'QR extraction failed and no embedded verification record was found in the image.':
        'QR extraction failed and no embedded verification record was found in the image.',
    'We could not save your institution. Please try again.':
        'We could not save your institution. Please try again.',
    'We could not create this project. Please try again.':
        'We could not create this project. Please try again.',
    'Certificate was not found in this offline workspace.':
        'Certificate was not found in this offline workspace.',
    'The QR payload is malformed or uses an unsupported protocol.':
        'The QR payload is malformed or uses an unsupported protocol.',
    'This template is used by a project and cannot be deleted.':
        'This template is used by a project and cannot be deleted.',
    'We could not import this workbook.': 'We could not import this workbook.',
    'The exported file was not written.': 'The exported file was not written.',
    'SQLCipher persistence is not available on Flutter Web.':
        'SQLCipher persistence is not available on Flutter Web.',
    'e.g. Al-Noor Academy': 'e.g. Al-Noor Academy',
    'e.g. Flutter Advanced Course 2026': 'e.g. Flutter Advanced Course 2026',
    'e.g. Flutter Advanced': 'e.g. Flutter Advanced',
    'No certificates generated yet. Import recipient data, design the layout, then generate.':
        'No certificates generated yet. Import recipient data, design the layout, then generate.',
    'Choose file': 'Choose file',
  };

  static const _ar = <String, String>{
    'Project workspace': 'مساحة عمل المشروع',
    'Projectworkspace': 'مساحة عمل المشروع',
    'Manage projects and import existing workspaces.':
        'إدارة المشاريع واستيراد مساحات العمل الحالية.',
    'New project': 'مشروع جديد',
    'Import project': 'استيراد مشروع',
    'Recent projects': 'المشاريع الأخيرة',
    'Your workspace': 'مساحة عملك',
    'Create project': 'إنشاء مشروع',
    'Create your first project': 'أنشئ مشروعك الأول',
    'Start with project information, then add a template and student data.':
        'ابدأ بمعلومات المشروع، ثم أضف قالبًا وبيانات الطلاب.',
    'No projects have been created yet.': 'لم يتم إنشاء أي مشاريع بعد.',
    'Offline ready': 'جاهز للعمل دون اتصال',
    'Draft': 'مسودة',
    'Verify certificate': 'التحقق من الشهادة',
    'Use the certificate file itself. Verification runs offline from its embedded security record.':
        'استخدم ملف الشهادة نفسه. يعمل التحقق دون اتصال اعتمادًا على سجل الأمان المضمّن.',
    'Certificate file': 'ملف الشهادة',
    'Select an issued certificate. For PNG/JPG images, the QR code is extracted automatically and the result reports extraction success or failure.':
        'اختر شهادة صادرة. لصور PNG/JPG، يُستخرج رمز QR تلقائيًا ويعرض تقرير نجاح أو فشل الاستخراج.',
    'Select certificate file': 'اختيار ملف الشهادة',
    'QR verification': 'التحقق عبر رمز QR',
    'Scan the QR code with your device and paste its cstudio:// payload here.':
        'امسح رمز QR بجهازك والصق بيانات cstudio:// هنا.',
    'QR payload': 'بيانات QR',
    'Verify QR payload': 'التحقق من بيانات QR',
    'Certificate ID': 'معرّف الشهادة',
    'Additional lookup method for certificates already available in this offline workspace.':
        'طريقة بحث إضافية للشهادات المتاحة في مساحة العمل غير المتصلة.',
    'Verify certificate ID': 'التحقق من معرّف الشهادة',
    'certificate-…': 'certificate-…',
    'Certificate library': 'مكتبة الشهادات',
    'Export all': 'تصدير الكل',
    'Export project': 'تصدير المشروع',
    'Export the background, font, data, and field positions.':
        'تصدير الخلفية والخط والبيانات ومواضع الحقول.',
    'Export all PNG files (ZIP)': 'تصدير جميع ملفات PNG (ZIP)',
    'Export all PDF files (ZIP)': 'تصدير جميع ملفات PDF (ZIP)',
    'Generated certificates': 'الشهادات المنشأة',
    'Browse, preview, verify, and export the actual generated certificate files.':
        'استعراض ومعاينة والتحقق وتصدير ملفات الشهادات المنشأة.',
    'Search by recipient, certificate ID, or project':
        'البحث بالمستلم أو معرّف الشهادة أو المشروع',
    'signed': 'موقّعة',
    'Signed': 'موقّعة',
    'valid': 'صالحة',
    'failed': 'فشل',
    'pending': 'قيد الانتظار',
    'generating': 'جارٍ الإنشاء',
    'generated': 'تم الإنشاء',
    'Recipient unavailable': 'المستلم غير متوفر',
    'Certificate Studio': 'استوديو الشهادات',
    'Certificate preview': 'معاينة الشهادة',
    'Certificate export settings': 'إعدادات تصدير الشهادة',
    'Choose file name field': 'اختر حقل اسم الملف',
    'Field used for the file name': 'الحقل المستخدم لاسم الملف',
    'Archive style': 'نمط الأرشيف',
    'All files in one ZIP': 'جميع الملفات في ملف ZIP واحد',
    'ZIP per certificate with signature.txt':
        'ملف ZIP مستقل لكل شهادة مع signature.txt',
    'Certificate details': 'تفاصيل الشهادة',
    'Recipient': 'المستلم',
    'Status': 'الحالة',
    'Available': 'متاح',
    'Unavailable': 'غير متاح',
    'Security': 'الأمان',
    'Valid signature': 'التوقيع صحيح',
    'Verification failed': 'فشل التحقق',
    'The certificate is authentic.': 'الشهادة أصلية وموثوقة.',
    'Unable to verify.': 'تعذر التحقق.',
    'View': 'عرض',
    'Export PNG': 'تصدير PNG',
    'Export PDF': 'تصدير PDF',
    'Export PNG ZIP': 'تصدير PNG ZIP',
    'Export PDF ZIP': 'تصدير PDF ZIP',
    'No certificates match your search.': 'لا توجد شهادات تطابق بحثك.',
    'No certificates generated yet.': 'لم يتم إنشاء أي شهادات بعد.',
    'Field properties': 'خصائص الحقل',
    'Position and size': 'الموضع والحجم',
    'Select a template before designing this certificate.':
        'اختر قالبًا قبل تصميم هذه الشهادة.',
    'Import recipient data first so fields can be mapped to columns.':
        'استورد بيانات المستلمين أولاً لربط الحقول بالأعمدة.',
    'Unsaved changes': 'تغييرات غير محفوظة',
    'Saved': 'تم الحفظ',
    'Saving...': 'جارٍ الحفظ...',
    'Template name': 'اسم القالب',
    'Background image': 'صورة الخلفية',
    'Choose image': 'اختيار صورة',
    'DPI': 'دقة العرض (DPI)',
    'Choose a certificate template': 'اختر قالب شهادة',
    'Template library': 'مكتبة القوالب',
    'Add template': 'إضافة قالب',
    'Use template': 'استخدام القالب',
    'Edit template': 'تعديل القالب',
    'Selected': 'محدد',
    'In use': 'قيد الاستخدام',
    'Use': 'استخدام',
    'Import font': 'استيراد خط',
    'Font library': 'مكتبة الخطوط',
    'Manage fonts available to projects.': 'إدارة الخطوط المتاحة للمشاريع.',
    'Live font preview': 'معاينة الخط مباشرة',
    'Write a sample to compare how every imported font renders it.':
        'اكتب نصًا تجريبيًا لمقارنة طريقة عرضه بكل خط مستورد.',
    'Preview text': 'نص المعاينة',
    'Generate certificates': 'إنشاء الشهادات',
    'Create signed PDF and high-resolution PNG certificates with offline verification records.':
        'أنشئ شهادات PDF موقعة وصور PNG عالية الدقة مع سجلات تحقق دون اتصال.',
    'Ready to generate': 'جاهز للإنشاء',
    'Generating certificates…': 'جارٍ إنشاء الشهادات…',
    'Open certificate library': 'فتح مكتبة الشهادات',
    'Certificate is authentic': 'الشهادة أصلية وموثقة',
    'The signature and document hash are valid.':
        'التوقيع الرقمي وتجزئة المستند صالحان.',
    'The requested file is unavailable.': 'الملف المطلوب غير متاح.',
    'Certificate exported successfully.': 'تم تصدير الشهادة بنجاح.',
    'No generated files were available to export.':
        'لا توجد ملفات منشأة متاحة للتصدير.',
    'Field used for the exported file name':
        'الحقل المستخدم لتسمية الملف المُصدّر',
    'Verification QR': 'رمز QR للتحقق',
    'Set up your institution': 'إعداد المؤسسة',
    'Continue to workspace': 'المتابعة إلى مساحة العمل',
    'Add student data': 'إضافة بيانات الطلاب',
    'Import an .xlsx workbook or paste a spreadsheet. The first row becomes the column names.':
        'استورد ملف ‎.xlsx أو الصق جدولًا. سيصبح الصف الأول أسماء الأعمدة.',
    'Paste table data': 'لصق بيانات الجدول',
    'Choose Excel file': 'اختيار ملف Excel',
    'Paste from clipboard': 'لصق من الحافظة',
    'Import data': 'استيراد البيانات',
    'Data preview': 'معاينة البيانات',
    'Fields': 'الحقول',
    'fields detected': '{count} حقول مكتشفة',
    'Add field': 'إضافة حقل',
    'Edit field': 'تعديل الحقل',
    'Delete field': 'حذف الحقل',
    'Field name': 'اسم الحقل',
    'Field name must be unique and not empty.':
        'يجب أن يكون اسم الحقل غير فارغ وفريدًا.',
    'At least one field is required.': 'يجب الإبقاء على حقل واحد على الأقل.',
    'Edit student': 'تعديل بيانات الطالب',
    'Student row {number}': 'صف الطالب {number}',
    'Detected fixed values': 'اختر إحدى القيم المكتشفة',
    'Value must be between {min} and {max}.':
        'يجب أن تكون القيمة بين {min} و {max}.',
    'Editable student rows': 'صفوف الطلاب القابلة للتعديل',
    'Add student row': 'إضافة صف طالب',
    'Delete student row': 'حذف صف الطالب',
    'Edit value': 'تعديل القيمة',
    'Row actions': 'إجراءات الصف',
    'No recipient data yet. Import a table to continue to certificate design.':
        'لا توجد بيانات مستلمين بعد. استورد جدولًا للمتابعة إلى تصميم الشهادة.',
    'Certificate type': 'نوع الشهادة',
    'Creating...': 'جارٍ الإنشاء...',
    'Create new project': 'إنشاء مشروع جديد',
    'Delete project': 'حذف المشروع',
    'Organization settings': 'إعدادات المؤسسة',
    'Control center': 'مركز التحكم',
    'Appearance & language': 'المظهر واللغة',
    'Application language': 'لغة التطبيق',
    'Arabic': 'العربية',
    'English': 'الإنجليزية',
    'Color mode': 'نمط الألوان',
    'System': 'تلقائي',
    'Light': 'فاتح',
    'Dark': 'داكن',
    'Brand color': 'اللون الرئيسي',
    'Open color picker': 'فتح منتقي الألوان',
    'Primary color': 'اللون الرئيسي',
    'Choose custom color': 'اختيار لون مخصص',
    'Electronic signature': 'التوقيع الإلكتروني',
    'Export institution profile': 'تصدير ملف المؤسسة',
    'Import institution profile': 'استيراد ملف المؤسسة',
    'Export signatures': 'تصدير التوقيعات',
    'Import signatures': 'استيراد التوقيعات',

    'localWorkspaceUnavailable': 'مساحة العمل المحلية غير متاحة.',
    'home': 'الرئيسية',
    'projects': 'المشاريع',
    'templates': 'القوالب',
    'fonts': 'الخطوط',
    'certificates': 'الشهادات',
    'verification': 'التحقق',
    'settings': 'الإعدادات',
    'workspace': 'مساحة العمل',
    'createManageCertificates': 'أنشئ شهاداتك وأدرها بسهولة',
    'offlineReady': 'جاهز للعمل دون اتصال',
    'notifications': 'الإشعارات',
    'verify': 'تحقق',
    'Open navigation': 'فتح قائمة التنقل',
    'newProject': 'مشروع جديد',
    'importProject': 'استيراد مشروع',
    'recentProjects': 'المشاريع الأخيرة',
    'yourWorkspace': 'مساحة عملك',
    'createFirstProject': 'أنشئ مشروعك الأول',
    'firstProjectDescription':
        'ابدأ بمعلومات المشروع، ثم أضف قالبًا وبيانات الطلاب.',
    'createProject': 'إنشاء مشروع',
    'failedLoadProjects': 'تعذر تحميل المشاريع. يرجى المحاولة مرة أخرى.',
    'verifyCertificate': 'التحقق من الشهادة',
    'selectCertificateFile': 'اختيار ملف الشهادة',
    'certificateFile': 'ملف الشهادة',
    'qrVerification': 'التحقق عبر رمز QR',
    'certificateId': 'معرّف الشهادة',
    'verifyQrPayload': 'التحقق من بيانات QR',
    'verifyCertificateId': 'التحقق من معرّف الشهادة',
    'qrPayload': 'بيانات QR',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'close': 'إغلاق',
    'delete': 'حذف',
    'addDataField': 'إضافة حقل بيانات',
    'select': 'اختيار',
    'search': 'بحث',
    'success': 'تم بنجاح',
    'error': 'خطأ',
    'continue': 'متابعة',
    'back': 'رجوع',
    'Academy or institution name': 'اسم الأكاديمية أو المؤسسة',
    'Arabic name': 'الاسم بالعربية',
    'Back to workspace': 'العودة إلى مساحة العمل',
    'Certificate': 'الشهادة',
    'Contact information': 'معلومات التواصل',
    'Course': 'الدورة',
    'Course / project': 'الدورة / المشروع',
    'Course or program': 'الدورة أو البرنامج',
    'Created': 'تاريخ الإنشاء',
    'Data source field': 'حقل مصدر البيانات',
    'Description': 'الوصف',
    'Design': 'التصميم',
    'Digital signature': 'التوقيع الرقمي',
    'Document hash': 'تجزئة المستند',
    'Email, phone, or website': 'البريد الإلكتروني أو الهاتف أو الموقع',
    'English name': 'الاسم بالإنجليزية',
    'Failed': 'فشل',
    'Font family': 'عائلة الخط',
    'Font size': 'حجم الخط',
    'Format': 'التنسيق',
    'Generate': 'إنشاء',
    'Generate and create verification records': 'إنشاء سجلات التحقق',
    'Generated': 'تم الإنشاء',
    'Height': 'الارتفاع',
    'Identifier': 'المعرّف',
    'Institution': 'المؤسسة',
    'Institution name': 'اسم المؤسسة',
    'Institution name *': 'اسم المؤسسة *',
    'Integrity': 'سلامة البيانات',
    'Issue date': 'تاريخ الإصدار',
    'Optional project notes': 'ملاحظات المشروع الاختيارية',
    'Organization': 'الجهة',
    'Project name *': 'اسم المشروع *',
    'QR extraction': 'استخراج QR',
    'Redo': 'إعادة',
    'Refresh': 'تحديث',
    'Save design': 'حفظ التصميم',
    'Student data': 'بيانات الطلاب',
    'Template': 'القالب',
    'Text alignment': 'محاذاة النص',
    'Text color (#RRGGBB)': 'لون النص (#RRGGBB)',
    'Text direction': 'اتجاه النص',
    'Total': 'الإجمالي',
    'Type': 'النوع',
    'Undo': 'تراجع',
    'Width': 'العرض',
    'Zoom in': 'تكبير',
    'Zoom out': 'تصغير',
    'Add a field from imported data to start designing.':
        'أضف حقلًا من البيانات المستوردة لبدء التصميم.',
    'Add data field': 'إضافة حقل بيانات',
    'Bold': 'عريض',
    'Browse': 'استعراض',
    'Center': 'توسيط',
    'Data field': 'حقل البيانات',
    'Elements': 'العناصر',
    'Export': 'تصدير',
    'Italic': 'مائل',
    'Layers': 'الطبقات',
    'Left': 'يسار',
    'No fonts have been imported yet.': 'لم يتم استيراد أي خطوط بعد.',
    'QR code': 'رمز QR',
    'RTL': 'من اليمين إلى اليسار',
    'LTR': 'من اليسار إلى اليمين',
    'Right': 'يمين',
    'Select a field to edit its properties.': 'اختر حقلًا لتعديل خصائصه.',
    'Select a field': 'اختيار حقل',
    'Template image unavailable': 'صورة القالب غير متاحة',
    'X': 'س',
    'Y': 'ص',
    'persistedFonts': '{count} خط محفوظ متاح للمشاريع.',

    'This information is used to identify your certificates and verification records.':
        'تُستخدم هذه المعلومات للتعريف بشهاداتك وسجلات التحقق.',
    'A private institution key will be generated and kept behind secure storage. It is never displayed or written into the project package.':
        'سيتم إنشاء مفتاح خاص بالمؤسسة وحفظه في تخزين آمن. لن يتم عرضه أو كتابته داخل حزمة المشروع.',
    'Institution name is required.': 'اسم المؤسسة مطلوب.',
    'Project information': 'معلومات المشروع',
    'Set up the context for this certificate-issuing project. You can configure templates and data next.':
        'حدّد سياق مشروع إصدار الشهادات. يمكنك إعداد القوالب والبيانات لاحقًا.',
    'Project name is required.': 'اسم المشروع مطلوب.',
    'Training': 'تدريب',
    'Achievement': 'إنجاز',
    'Participation': 'مشاركة',
    'Custom': 'مخصص',
    'Continue': 'متابعة',
    'Configure this project, then design and generate certificates.':
        'اضبط هذا المشروع ثم صمّم الشهادات وأنشئها.',
    'Choose the certificate background.': 'اختر خلفية الشهادة.',
    'Import or paste recipient data.': 'استورد بيانات المستلمين أو الصقها.',
    'Choose the font available to this project.':
        'اختر الخط المتاح لهذا المشروع.',
    'Place fields on the certificate canvas.': 'ضع الحقول على لوحة الشهادة.',
    'Create certificates after setup is complete.':
        'أنشئ الشهادات بعد اكتمال الإعداد.',
    'Not set': 'غير محدد',
    'The certificate could not be verified.': 'تعذر التحقق من الشهادة.',
    'Success — QR payload was extracted from the image':
        'نجح استخراج بيانات QR من الصورة',
    'Failed — no readable QR code was found':
        'فشل — لم يتم العثور على رمز QR قابل للقراءة',
    'Hash matches embedded certificate data':
        'التجزئة مطابقة لبيانات الشهادة المضمّنة',
    'Valid Ed25519 signature': 'توقيع Ed25519 صالح',
    'Not provided': 'غير متوفر',
    'Certificate template': 'قالب الشهادة',
    'Please select a PDF, PNG, JPG, or JPEG certificate.':
        'يرجى اختيار شهادة بصيغة PDF أو PNG أو JPG أو JPEG.',
    'Create and manage your certificates': 'أنشئ شهاداتك وأدرها بسهولة',
    'Failed to load projects. Please try again.':
        'تعذر تحميل المشاريع. يرجى المحاولة مرة أخرى.',
    'projectUpdated': '{course}  •  آخر تحديث {date}',
    'Certificate project': 'مشروع شهادة',
    'persistedProjects': '{count} مشروع محفوظ',
    'createdDate': 'تاريخ الإنشاء {date}',
    'This permanently removes the project, recipient data, design, generated certificates, verification records, and project key.':
        'سيؤدي هذا إلى حذف المشروع وبيانات المستلمين والتصميم والشهادات المنشأة وسجلات التحقق ومفتاح المشروع نهائيًا.',
    'tableDataExample':
        'الحقل 1\tالحقل 2\tالحقل 3\nالقيمة 1\tالقيمة 2\tالقيمة 3',

    'Choose a background image from your device, preview it, and use it as this project’s certificate canvas.':
        'اختر صورة خلفية من جهازك، واعرضها ثم استخدمها كلوحة شهادة للمشروع.',
    'Browse persisted certificate backgrounds or import a new template.':
        'استعرض خلفيات الشهادات المحفوظة أو استورد قالبًا جديدًا.',
    'No templates saved yet. Add a PNG, JPG, or WEBP background image to continue.':
        'لا توجد قوالب محفوظة بعد. أضف صورة خلفية بصيغة PNG أو JPG أو WEBP للمتابعة.',
    'File not found at saved path': 'لم يتم العثور على الملف في المسار المحفوظ',
    'Required': 'مطلوب',
    'Valid certificate': 'شهادة صالحة',
    'Integrity compromised': 'تم اكتشاف خلل في سلامة البيانات',
    'Invalid signature': 'توقيع غير صالح',
    'Unknown certificate': 'شهادة غير معروفة',
    'Verification data missing': 'بيانات التحقق مفقودة',
    'Unsupported or malformed certificate': 'شهادة غير مدعومة أو تالفة',
    'QR extraction failed and no embedded verification record was found in the image.':
        'فشل استخراج QR ولم يتم العثور على سجل تحقق مضمّن في الصورة.',
    'We could not save your institution. Please try again.':
        'تعذر حفظ المؤسسة. يرجى المحاولة مرة أخرى.',
    'We could not create this project. Please try again.':
        'تعذر إنشاء المشروع. يرجى المحاولة مرة أخرى.',
    'Certificate was not found in this offline workspace.':
        'لم يتم العثور على الشهادة في مساحة العمل غير المتصلة.',
    'The QR payload is malformed or uses an unsupported protocol.':
        'بيانات QR تالفة أو تستخدم بروتوكولًا غير مدعوم.',
    'This template is used by a project and cannot be deleted.':
        'هذا القالب مستخدم في مشروع ولا يمكن حذفه.',
    'We could not import this workbook.': 'تعذر استيراد ملف Excel هذا.',
    'The exported file was not written.': 'تعذر كتابة الملف المُصدّر.',
    'SQLCipher persistence is not available on Flutter Web.':
        'تخزين SQLCipher غير متاح على Flutter Web.',
    'e.g. Al-Noor Academy': 'مثال: أكاديمية النور',
    'e.g. Flutter Advanced Course 2026': 'مثال: دورة فلاتر المتقدمة 2026',
    'e.g. Flutter Advanced': 'مثال: فلاتر متقدم',
    'No certificates generated yet. Import recipient data, design the layout, then generate.':
        'لم يتم إنشاء أي شهادات بعد. استورد بيانات المستلمين وصمم المخطط ثم أنشئ الشهادات.',
    'Choose file': 'اختيار ملف',
  };
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
