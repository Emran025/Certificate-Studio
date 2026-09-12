---
title: Certificate Studio - Software Requirements Specification
version: 1.1.0
date: 2026-09-12
---

## Summary Table of Functional Modules

| Module | Requirement Count | Description |
|--------|-------------------|-------------|
| Institution | 5 | Setup, identity, and keys |
| Projects | 6 | Course and project management |
| Templates | 5 | Template upload and management |
| Fonts | 4 | Font embedding and management |
| Designer | 10 | Visual certificate designer |
| Data Import | 6 | Excel and Copy/Paste import |
| Mapping | 2 | Column to Class mapping |
| Signatures | 4 | Signature and stamp handling |
| Renderer | 5 | High-resolution PDF/PNG generation |
| Certificates | 6 | Browsing and management |
| Verification | 4 | Authenticity verification |
| Cryptography | 5 | Encryption, Hash, and Signatures |
| Project Package | 3 | Export/Import of project files |
| SQLCipher | 2 | Local encrypted database |
| Offline | 3 | Offline-first operations |
| Sharing | 2 | PDF/Image sharing |
| WhatsApp | 2 | Direct WhatsApp sharing |
| Export | 3 | ZIP export by student/class |
| Settings | 4 | System and institution settings |
| Cross-platform | 5 | Multi-platform support |




## 1. إدارة المؤسسة والتهيئة الأولية

عند تشغيل التطبيق لأول مرة تظهر معالج تهيئة للمؤسسة، ويتضمن:

* اسم المؤسسة.
* اسم المؤسسة بالعربي والإنجليزي.
* الشعار.
* معلومات التواصل.
* معلومات اختيارية تظهر على الشهادة.
* إعدادات التصدير الافتراضية.
* إعدادات التوقيع الإلكتروني.
* إعداد مفتاح المؤسسة الرئيسي.
* إمكانية تغيير المفتاح من إعدادات المؤسسة.

يكون للمؤسسة **مفتاح تشفير/سرية رئيسي واحد** Master Institution Key، وتكون قيمته قابلة للتغيير من إعدادات التطبيق، لكن لا ينبغي وضع المفتاح الحقيقي hard-coded داخل تطبيق Flutter.

ويفضل أن يكون هناك أيضًا **معرّف مؤسسة ثابت** Institution ID يستخدم ضمن بيانات التحقق.

---

## 2. إدارة المشاريع / المقررات

كل عملية إصدار شهادات تكون داخل **Project** مستقل.

مثال:

```text
المؤسسة
│
├── دورة Flutter Advanced
│   ├── القالب
│   ├── إعدادات الحقول
│   ├── الطلاب
│   ├── الشهادات
│   └── مفتاح المشروع
│
├── دورة Database Systems
│   ├── القالب
│   ├── إعدادات الحقول
│   ├── الطلاب
│   └── الشهادات
│
└── دورة Software Engineering
```

ويحتوي المشروع على:

* اسم المشروع.
* اسم المقرر/الدورة.
* وصف المشروع.
* تاريخ البداية والنهاية.
* اسم المدرب.
* اسم الجهة.
* الشعار.
* قالب الشهادة.
* إعدادات الحقول.
* قائمة الطلاب.
* مفتاح المشروع.
* إعدادات التوقيع.
* إعدادات التصدير.
* إعدادات التحقق.
* تاريخ إنشاء المشروع.
* آخر تعديل.
* إصدار المشروع.

ويكون لكل مشروع **Project Key** مستقل، بحيث يمكن مشاركة المشروع أو نقله دون الحاجة إلى تغيير مفتاح المؤسسة.

---

## 3. إدارة قوالب الشهادات

يجب أن يستطيع المستخدم:

* اختيار صورة شهادة من الجهاز.
* سحب وإفلات صورة القالب على التطبيق Desktop.
* استخدام قالب محفوظ مسبقًا.
* حفظ القالب في مكتبة القوالب.
* تسمية القالب.
* معاينة القالب.
* حذف القالب.
* إعادة استخدام قالب في مشروع آخر.

القالب يمكن أن يكون مثل:

```text
certificate_template.png
```

ويُفضل الاحتفاظ أيضًا بأبعاد القالب الأصلية:

```text
width
height
dpi
format
```

حتى لا يحدث اختلاف في مواضع النص عند التصدير.

---

## 4. محرر تصميم الشهادة

هذه أهم واجهة في التطبيق.

بعد اختيار الخلفية تظهر لوحة تصميم تحتوي على القالب، وفوقها الحقول التي يمكن وضعها.

مثلًا:

```text
┌───────────────────────────────────────┐
│                                       │
│        UNIVERSITY CERTIFICATE         │
│                                       │
│          [ STUDENT NAME ]             │
│                                       │
│       successfully completed          │
│                                       │
│             [ CLASS ]                 │
│                                       │
│       [ DATE ]          [ GRADE ]     │
│                                       │
│                         Signature     │
└───────────────────────────────────────┘
```

ويستطيع المستخدم إنشاء Box لكل Class.

مثلاً:

```text
Class: student_name
X: 450
Y: 300
Width: 900
Height: 120
```

ثم:

```text
Class: course_name
X: 450
Y: 450
Width: 900
Height: 100
```

و:

```text
Class: grade
X: 1200
Y: 700
Width: 250
Height: 80
```

### خصائص كل Box

كل Box يجب أن يدعم:

* Class name.
* مصدر البيانات.
* X.
* Y.
* Width.
* Height.
* Alignment.
* Vertical alignment.
* Font.
* Font size.
* Font weight.
* Italic.
* Underline.
* Letter spacing.
* Line height.
* Text colour.
* Text direction.
* Maximum lines.
* Overflow behaviour.
* Rotation.
* Opacity.
* Text wrapping.

ويكون تحريك الـ Box بالماوس مع إمكانية الضبط الدقيق بالأرقام.

---

## 5. نظام الخطوط Fonts

هذه نقطة مهمة جدًا في مشروعك.

التطبيق لا يعتمد فقط على الخطوط المثبتة في Windows أو Android.

بل يكون لديه:

```text
Fonts
├── Cairo
├── Amiri
├── Noto Sans Arabic
├── Times New Roman
└── CustomFont.ttf
```

ويستطيع المستخدم:

* إضافة `.ttf`.
* إضافة `.otf` إن دعمناه.
* تسمية الخط.
* معاينة الخط.
* استخدامه داخل Box.
* حفظ الخط ضمن المشروع.

والأفضل أن **الخط المستخدم في المشروع يتم تضمينه داخل Package المشروع**، بحيث لو نقلت المشروع إلى جهاز آخر لا يحدث:

> Font not found

---

## 6. استيراد بيانات الطلاب

يدعم التطبيق Excel، وكذلك النسخ واللصق المباشر.

مثلاً Excel:

| class | name           | course  | grade | date       | phone  |
| ----- | -------------- | ------- | ----- | ---------- | ------ |
| A001  | Ahmed Ali      | Flutter | 95    | 2026-09-12 | 777xxx |
| A002  | Mohammed Saleh | Flutter | 91    | 2026-09-12 | 733xxx |

ويستطيع المستخدم:

* رفع `.xlsx`.
* رفع `.xls` إذا أردنا دعمه.
* نسخ جدول من Excel.
* لصقه مباشرة داخل التطبيق.
* تعديل البيانات يدويًا.
* إضافة صف.
* حذف صف.
* إعادة ترتيب الأعمدة.
* تغيير أسماء الأعمدة.
* تحديد العمود الذي يمثل Class.

---

## 7. ربط أعمدة Excel بالـ Classes

بعد استيراد البيانات تظهر شاشة:

```text
Excel Column        Certificate Class
--------------------------------------
name          →     student_name
course        →     course_name
grade         →     grade
date          →     issue_date
phone         →     phone
```

وبالتالي لا يكون التطبيق مرتبطًا بأسماء أعمدة محددة.

مثلاً مؤسسة تستخدم:

```text
Student Name
```

وأخرى:

```text
اسم الطالب
```

وثالثة:

```text
student
```

كلها يمكن ربطها بالـ:

```text
student_name
```

---

## 8. التوقيع الإلكتروني

يتم دعم:

* صورة توقيع PNG.
* توقيع بخلفية شفافة.
* تحديد مكان التوقيع.
* تحديد الحجم.
* إمكانية إضافة أكثر من توقيع.
* اسم صاحب التوقيع.
* المسمى الوظيفي.
* إمكانية استخدام توقيع مختلف لكل مشروع.

مثلاً:

```text
Director Signature
Trainer Signature
Institution Stamp
```

ويُحفظ التوقيع ضمن إعدادات المشروع.

---

## 9. توليد الشهادات

بعد الضغط على:

**Generate Certificates**

يقوم التطبيق:

1. بقراءة الطلاب.
2. تحميل القالب.
3. تحميل الخطوط.
4. قراءة إعدادات الـ Boxes.
5. استبدال البيانات.
6. رسم النصوص.
7. إضافة التوقيع.
8. إضافة الشعار/الختم.
9. إضافة بيانات التحقق.
10. إنشاء نسخة PDF.
11. إنشاء صورة عالية الدقة.
12. حفظ بيانات الشهادة في قاعدة البيانات.

مثلاً:

```text
Certificates
├── A001
│   ├── certificate.pdf
│   └── certificate.png
│
├── A002
│   ├── certificate.pdf
│   └── certificate.png
```

---

## 10. تسمية ملفات الشهادات

يجب ألا تكون التسمية ثابتة.

بل يكون هناك Template للتسمية.

مثلاً:

```text
{class}.pdf
```

فتصبح:

```text
A001.pdf
A002.pdf
A003.pdf
```

أو:

```text
{student_name}_{class}.pdf
```

فتصبح:

```text
Ahmed_Ali_A001.pdf
```

أو:

```text
{course}_{class}.pdf
```

ويستطيع المستخدم تحديد ذلك قبل التصدير.

---

## 11. تصدير ZIP

يستطيع المستخدم اختيار:

```text
Export Project
```

أو:

```text
Export Certificates
```

### تصدير الشهادات

مثلاً:

```text
Certificates.zip

A001/
    A001.pdf
    A001.png

A002/
    A002.pdf
    A002.png
```

أو حسب إعداد المستخدم:

```text
A001.pdf
A001.png
A002.pdf
A002.png
```

---

# 12. ملف المشروع القابل للنقل

هذه نقطة ممتازة في فكرتك، ويجب فصلها عن نتائج الشهادات.

مثلاً امتداد خاص:

```text
.certproject
```

أو:

```text
.cstudio
```

والملف عبارة عن ZIP داخلي لكن بامتداد خاص.

مثلاً:

```text
MyCourse.certproject
```

ويحتوي:

```text
project/
│
├── manifest.json
├── database.json
├── template.png
├── fonts/
│   ├── Cairo.ttf
│   └── Custom.ttf
│
├── signatures/
│   └── director.png
│
├── configuration/
│   ├── fields.json
│   ├── export.json
│   └── verification.json
│
└── keys/
    └── project.key
```

**ولا يحتوي على صور شهادات الطلاب الناتجة**.

وهذا يجعل حجم ملف المشروع صغيرًا وقابلًا للنقل.

---

## 13. تشفير ملف المشروع

هنا أقترح تصميمًا أكثر أمانًا من مجرد وضع المفتاح داخل الملف.

لدينا:

```text
Institution Key
        │
        ├── Project Key
        │
        └── Verification
```

وكل Project يمتلك مفتاحًا مستقلًا.

مثلاً:

```text
Institution Key
      ↓
Key Derivation
      ↓
Project Key
      ↓
Encrypt Project Data
```

ويكون تشفير البيانات باستخدام مكتبة Python مستقلة.

---

# 14. مكتبة Python للتشفير

بدل وضع منطق التشفير داخل Flutter مباشرة، ننشئ Package مستقل، مثلاً:

```text
certificate_crypto
```

ويكون مسؤولًا عن:

```text
Key generation
Key derivation
Encryption
Decryption
Hashing
Digital signatures
Verification
Project encryption
Certificate metadata signing
```

مثلاً API منطقي:

```python
generate_key()

derive_project_key()

encrypt(data, key)

decrypt(data, key)

sign(data, private_key)

verify(data, signature, public_key)

hash_data(data)
```

لكن هنا يوجد قرار معماري مهم: **إذا كان التطبيق Flutter Desktop/Mobile/Web ويجب أن يعمل Offline، فلا أنصح بجعل Flutter يستدعي Python runtime مباشرة**؛ لأن ذلك سيصعّب Android وiOS وWeb. الأفضل أن تكون Python مكتبة مرجعية/أداة بناء، ثم يكون لها تنفيذ مكافئ داخل Dart/native حسب المنصة، أو استخدام مكتبة تشفير مشتركة مناسبة.

إذا كان هدفك تحديدًا أن تكون **Python package هي المصدر الرسمي لخوارزميات التشفير**، يمكن تصميم بروتوكول ثابت بحيث تكون نتائج Python وDart متطابقة.

---

# 15. بيانات التحقق من الشهادة

كل شهادة لا ينبغي أن تكون مجرد صورة.

بل يتم إنشاء **Certificate Verification Record**.

مثلاً:

```json
{
    "institution_id": "...",
    "project_id": "...",
    "certificate_id": "...",
    "student_class": "A001",
    "course": "Flutter",
    "issue_date": "2026-09-12",
    "document_hash": "...",
    "signature": "..."
}
```

ثم تُشفّر/توقّع هذه البيانات.

وبالتالي يمكن للتطبيق التحقق:

```text
Certificate
      ↓
Extract verification data
      ↓
Decrypt / Verify
      ↓
Calculate hash
      ↓
Compare
      ↓
VALID / INVALID
```

---

# 16. وضع بيانات التحقق داخل الوثيقة نفسها

هذه من أهم أجزاء التصميم.

يمكن وضع:

* Certificate ID.
* Institution ID.
* Project ID.
* Hash.
* Digital signature.
* Verification code.
* QR Code.

داخل PDF أو الصورة.

مثلاً QR:

```text
https://verify.example/c/A8F92K...
```

أو Offline:

```text
CERT:A8F92K...
```

وبالتالي حتى لو أُرسلت الشهادة وحدها، تبقى مرتبطة بهوية المؤسسة.

---

# 17. التحقق Offline

بما أنك تريد Offline، لا ينبغي أن يكون التحقق معتمدًا على Internet فقط.

يمكن للتطبيق أن يستقبل:

```text
PDF
```

ثم:

```text
Extract Metadata
        ↓
Extract Signature
        ↓
Extract Certificate ID
        ↓
Verify Institution
        ↓
Verify Project
        ↓
Verify Hash
```

ويظهر:

### Valid

```text
✓ Certificate is authentic

Institution:
XXXX University

Course:
Flutter Advanced

Student:
Ahmed Ali

Certificate ID:
A8F92K...
```

أو:

### Invalid

```text
✕ Certificate verification failed

Reason:
Document has been modified.
```

---

# 18. واجهة التحقق المستقلة

يكون هناك قسم مستقل:

```text
Verify Certificate
```

ويمكن التحقق عن طريق:

* اختيار PDF.
* اختيار صورة.
* تصوير الشهادة بالكاميرا.
* QR Code.
* إدخال Certificate ID.
* سحب الملف وإفلاته Desktop.

---

# 19. إدارة الشهادات

داخل كل Project:

```text
Certificates
```

تظهر قائمة الطلاب:

| Class | Student    | Course  | Status    |
| ----- | ---------- | ------- | --------- |
| A001  | Ahmed Ali  | Flutter | Generated |
| A002  | Mohammed   | Flutter | Generated |
| A003  | Ali Hassan | Flutter | Generated |

مع:

* Search.
* Filter.
* Sort.
* Preview.
* Open PDF.
* Open image.
* Share.
* Regenerate.
* Delete.
* Export.

---

# 20. معاينة الشهادة

عند الضغط على طالب تظهر:

```text
┌─────────────────────────┐
│                         │
│       CERTIFICATE       │
│                         │
│       Ahmed Ali         │
│                         │
│       Flutter           │
│                         │
└─────────────────────────┘

[ PDF ] [ Image ] [ Share ]
```

---

# 21. المشاركة

يتم توفير Share عبر نظام التشغيل.

على Android مثلاً:

```text
Share
 ↓
WhatsApp
Telegram
Email
Bluetooth
Drive
...
```

وعلى Windows:

```text
Share / Open Folder
```

ويتم مشاركة PDF أو الصورة حسب اختيار المستخدم.

---

# 22. WhatsApp

بالنسبة لعبارة:

> إذا كان يوجد class phone يتم التصدير إلى WhatsApp وإرسال مباشر إلى نفس الرقم مع انتظار عملية الإرسال

يمكن تصميمها كالتالي:

```text
phone → WhatsApp recipient
```

وعند:

```text
Send Certificate
```

يتم:

```text
Student
   ↓
phone
   ↓
Normalize phone
   ↓
Open WhatsApp
   ↓
Attach certificate
   ↓
User confirms sending
```

لكن يجب التفريق معماريًا بين **فتح WhatsApp مع بيانات المستلم** وبين **الإرسال الصامت التلقائي**؛ الإرسال المباشر دون تدخل المستخدم ليس مضمونًا عبر تطبيق WhatsApp العادي، ويعتمد على APIs/سياسات المنصة. لذلك نجعل نظام المشاركة قابلاً للتوسع بحيث يدعم لاحقًا WhatsApp Business API إذا احتجنا إرسالًا مؤسسيًا آليًا.

---

# 23. قاعدة البيانات SQLCipher

الـ local database يمكن تصميمها تقريبًا:

```text
institutions
projects
templates
fonts
signatures
students
certificate_fields
certificate_layouts
certificates
verification_records
settings
```

مثلاً:

```text
projects
---------
id
name
description
template_id
project_key
created_at
updated_at
```

و:

```text
certificate_fields
------------------
id
project_id
class_name
x
y
width
height
font_id
font_size
alignment
color
...
```

و:

```text
students
--------
id
project_id
class
name
phone
data_json
```

---

# 24. نظام الملفات

من الأفضل عدم وضع كل شيء عشوائيًا في SQLCipher.

نستخدم:

```text
Application Data
│
├── database/
│   └── certificates.db
│
├── projects/
│
├── templates/
│
├── fonts/
│
├── signatures/
│
└── certificates/
```

وتكون SQLCipher مسؤولة عن **metadata والعلاقات**، والملفات الكبيرة تبقى Filesystem.

---

# 25. دعم Desktop / Mobile / Web

أقترح أن تكون البنية:

```text
Flutter
│
├── Android
├── Windows
├── Linux
├── macOS
├── iOS
└── Web
```

مع:

```text
Clean Architecture
       +
Repository Pattern
       +
Platform Services
```

لكن هناك فرق مهم:

**Web Offline + SQLCipher** يحتاج تصميمًا مختلفًا عن Desktop/Mobile؛ لأن `SQLCipher` التقليدي ليس الخيار الطبيعي للويب. لذلك يمكن جعل طبقة التخزين abstraction:

```text
LocalDatabase
     │
     ├── SQLCipher implementation
     │      Android
     │      Windows
     │      Linux
     │      macOS
     │
     └── Web implementation
            IndexedDB / SQLCipher WASM
```

وبذلك لا نربط Domain Layer بـ SQLCipher مباشرة.

---

# 26. Offline-first

التطبيق بالكامل يعمل بدون Internet:

```text
Create Project       ✓
Import Excel         ✓
Design Certificate   ✓
Add Fonts            ✓
Generate PDF         ✓
Generate Image       ✓
Encrypt              ✓
Decrypt              ✓
Verify               ✓
Export Project       ✓
Import Project       ✓
Browse Certificates  ✓
Share Files          ✓
```

الإنترنت يكون **اختياريًا فقط** لأشياء مثل:

```text
WhatsApp
Online verification
Updates
Cloud backup
```

---

# 27. بنية المشروع المقترحة

أرى أن المشروع نفسه يكون Modular:

```text
certificate_studio/
│
├── flutter_app/
│
├── packages/
│   ├── certificate_core/
│   ├── certificate_crypto/
│   ├── certificate_renderer/
│   ├── certificate_import/
│   ├── certificate_export/
│   ├── certificate_verification/
│   └── certificate_storage/
│
├── python/
│   └── certificate_crypto/
│
└── docs/
```

وهذا مهم جدًا لأنك لا تريد أن يتحول التطبيق إلى كتلة Flutter ضخمة.

---

# 28. دورة العمل الكاملة للمستخدم

المسار النهائي سيكون بسيطًا جدًا:

```text
فتح التطبيق
     ↓
اختيار المؤسسة
     ↓
إنشاء مشروع
     ↓
"Flutter Advanced Course"
     ↓
اختيار قالب الشهادة
     ↓
إضافة الخطوط
     ↓
تصميم Classes / Boxes
     ↓
استيراد Excel
     ↓
ربط الأعمدة بالـ Classes
     ↓
إضافة التوقيع
     ↓
معاينة
     ↓
Generate
     ↓
      ┌───────────────┐
      │ 100 Students  │
      └───────┬───────┘
              ↓
       100 Certificates
              ↓
       PDF + High-res PNG
              ↓
        Browse / Share
              ↓
           Export
```

---

# 29. تصدير واستيراد المشروع

يكون عند المستخدم:

```text
Export Project
```

وينتج:

```text
Flutter_Advanced.certproject
```

ثم يمكن نقله إلى:

* USB
* WhatsApp
* Telegram
* Email
* Google Drive
* جهاز آخر

وعند فتحه:

```text
Import Project
       ↓
Verify Project Package
       ↓
Decrypt
       ↓
Extract
       ↓
Restore Project
```

ولا يتم استيراد شهادات الطلاب الناتجة، إلا إذا صممنا خيارًا منفصلًا لذلك.

---

# 30. الأمان

أقترح أن تكون لدينا ثلاثة مستويات:

```text
Institution Identity
        │
        ▼
Institution Key
        │
        ▼
Project Key
        │
        ▼
Certificate Signature
```

مع:

* تشفير البيانات الحساسة.
* Hash للشهادة.
* Digital Signature للتحقق من المصدر.
* Certificate ID فريد.
* Institution ID.
* Project ID.
* حماية مفاتيح المؤسسة.
* عدم تخزين المفاتيح في plaintext داخل ملفات المشروع.
* إمكانية تغيير مفتاح المؤسسة.
* آلية Key Rotation مستقبلية.

والأهم: **التشفير وحده لا يثبت أن الشهادة صادرة من المؤسسة**. الذي يثبت الأصل هو **التوقيع الرقمي بالمفتاح الخاص للمؤسسة + التحقق بالمفتاح العام**. أما التشفير فيحمي سرية البيانات.

---

## 31. أهم قرار معماري أقترحه

لا تجعل:

```text
Flutter
   ↓
Python
   ↓
Encryption
```

هو التصميم الأساسي.

بل:

```text
                 Certificate Core
                       │
       ┌───────────────┼───────────────┐
       ↓               ↓               ↓
   Rendering        Storage         Security
       │                               │
       │                 ┌─────────────┴────────────┐
       │                 ↓                          ↓
       │          Dart implementation        Python package
       │
       ↓
PDF / PNG
```

وتكون Python Package **مرجعًا رسميًا للبروتوكول والتشفير وأدوات التطوير/التحقق**، بينما Flutter يستطيع العمل مستقلًا Offline على Android/Desktop/Web.

بهذا لا يصبح التطبيق معتمدًا على تثبيت Python عند المستخدم.

---

## 32. الوحدات الوظيفية النهائية

لو أردنا تحويل كل ما ذكرته إلى قائمة Requirements رسمية، فالنظام النهائي يحتوي على:

| الوحدة              | الوظائف                                    |
| ------------------- | ------------------------------------------ |
| **Institution**     | إعداد المؤسسة، الهوية، المفاتيح            |
| **Projects**        | إنشاء وإدارة المقررات والمشاريع            |
| **Templates**       | إضافة وحفظ وإدارة القوالب                  |
| **Fonts**           | إضافة وحفظ وتضمين الخطوط                   |
| **Designer**        | إنشاء وتحريك وضبط Boxes                    |
| **Data Import**     | Excel + Copy/Paste                         |
| **Mapping**         | ربط Columns بالـ Classes                   |
| **Signatures**      | التوقيع والختم                             |
| **Renderer**        | إنتاج PDF وPNG عالي الدقة                  |
| **Certificates**    | استعراض وإدارة الشهادات                    |
| **Verification**    | التحقق من أصالة الشهادة                    |
| **Cryptography**    | Encryption / Decryption / Hash / Signature |
| **Project Package** | Export / Import للمشروع                    |
| **SQLCipher**          | التخزين المحلي                             |
| **Offline**         | تشغيل كامل دون Internet                    |
| **Sharing**         | مشاركة PDF/Image                           |
| **WhatsApp**        | مشاركة حسب `phone`                         |
| **Export**          | ZIP حسب الطالب/Class                       |
| **Settings**        | إعدادات النظام والمؤسسة                    |
| **Cross-platform**  | Desktop / Android / Web وغيرها             |


## Non-Functional Requirements

### Performance
- **Generation Time:** Generating a batch of 100 certificates must complete in under 10 seconds.
- **DB Queries:** Database operations must be optimized to ensure minimal latency, utilizing indexes on frequently queried fields.
- **UI Responsiveness:** The UI must maintain a smooth 60fps framerate, especially during heavy tasks like rendering or Excel import.

### Security
- **Key Storage:** Cryptographic keys must be stored securely using platform-specific secure enclaves/keychains where possible.
- **Encryption Standards:** Use AES-256 for data at rest and RSA/ECC for digital signatures.
- **No Plaintext Keys:** Under no circumstances should master or project keys be stored in plaintext within the database or project files.

### Usability
- **Offline-First:** All core features (design, generate, verify) must work seamlessly without an internet connection.
- **No Technical Jargon:** The user interface must use clear, accessible language, avoiding complex cryptographic or database terminology.

### Portability
- **Cross-Platform:** The application must run consistently on Windows, macOS, Android, and Web platforms.
- **Project File Portability:** `.certproject` files must be self-contained and easily transferable between different devices and OSs.

## Constraints and Assumptions

**Constraints:**
- Must operate entirely offline for sensitive data processing.
- Must not rely on a local Python installation on the user's machine for core features.

**Assumptions:**
- Users have basic familiarity with Excel for data preparation.
- System dates and times are accurate for certificate generation and validation.
## Key Acceptance Criteria

- **Certificate Generation:** A batch of 100 certificates (PDF and PNG) must generate successfully and complete in a reasonable time (under 10 seconds).
- **Verification:** The offline verification process must successfully validate authentic certificates and reject tampered ones without requiring any internet connection.
- **Security:** Security audits must confirm that institution and project keys are never stored in plaintext on the file system or database.
## Glossary

- **Box / Class:** A visual element on the certificate template linked to data (e.g., student name).
- **Institution Key:** The master cryptographic key used by an institution to sign and secure its certificates.
- **Project Key:** A derived key specific to a single course or batch of certificates.
- **Certificate Verification Record:** A structured dataset embedded in the certificate to prove its authenticity.
- **.certproject:** A proprietary, encrypted ZIP format containing all project assets (templates, fonts, DB) excluding generated output.
