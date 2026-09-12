---
title: Certificate Studio - UX/UI Specification
version: 1.1.0
date: 2026-09-12
---

# Screen Inventory

| Screen Name | Description | Key Components |
| --- | --- | --- |
| Home / Workspace | Main entry point showing recent projects and quick actions. | Project List, New/Import buttons, Sidebar |
| New Project Wizard | Step-by-step setup for a new certificate project. | Setup Forms, Next/Back actions |
| Data Import | Interface for importing and mapping student data. | Excel Drop Zone, Data Table Preview |
| Certificate Designer | Core editing interface for certificate layouts. | Canvas, Properties Panel, Elements List |
| Preview Mode | Paginated preview of certificates before generation. | Certificate View, Student Dropdown |
| Generation Job | Progress tracker for batch certificate generation. | Progress Bar, Status List |
| Certificate Library | Archive of all generated certificates. | Data Grid, Filters, Export Options |
| Verification | Independent tool to verify generated certificates. | Upload Zone, QR Scanner, Result View |
| Settings | Application and institution configuration. | Options List, Security Config |

نعم. الآن ننتقل من **هندسة المكونات** إلى **هندسة تجربة المستخدم UX + واجهة المستخدم UI + تدفق النظام بالكامل**.

وبما أن التطبيق الذي بنيناه ليس مجرد "مولّد شهادات"، بل **Certificate Authoring & Generation Studio** يعمل كمحرر + مستورد بيانات + مولّد + مدير شهادات + نظام تحقق، فالأفضل ألا نصممه كتطبيق CRUD تقليدي. الأفضل أن تكون التجربة قريبة من أدوات مثل محررات المستندات والتصميم: **Workspace + Wizard عند الإنشاء + Editor عند التصميم + Jobs عند التوليد + Library عند الإدارة**.

سأضع لك التصور الذي أراه مناسبًا كأساس نهائي قبل أن نبدأ رسم الشاشات.

---

# 1. الفكرة الأساسية للـ UX

المستخدم لا ينبغي أن يفكر في:

> Template → Mapping → Font → Signature → Generate → Export

هذه هي **بنية النظام الداخلية**، وليست بالضرورة تجربة المستخدم.

المستخدم يفكر:

> **أريد إنشاء شهادات لمجموعة طلاب.**

لذلك الواجهة تقوده بهذا التسلسل:

```text
إنشاء مشروع
    ↓
اختيار / إنشاء قالب الشهادة
    ↓
إضافة بيانات الطلاب
    ↓
ربط البيانات بأماكن الشهادة
    ↓
تخصيص التصميم
    ↓
معاينة
    ↓
توليد الشهادات
    ↓
مراجعة النتائج
    ↓
تصدير / مشاركة
    ↓
التحقق من الشهادة عند الحاجة
```

وهذا مهم جدًا:
**الـ UX يعكس رحلة المستخدم، بينما الـ architecture يعكس مكونات النظام.**

---

# 2. الشاشة الرئيسية — Home / Workspace

بعد فتح التطبيق لا نرمي المستخدم مباشرة في إعدادات.

تكون الشاشة تقريبًا:

```text
┌──────────────────────────────────────────────────────────────┐
│  Certificate Studio                              ⚙ Settings │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Good evening                                                │
│  Create and manage your certificates                         │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                  │
│  │                  │  │                  │                  │
│  │   + New Project  │  │  Import Project  │                  │
│  │                  │  │                  │                  │
│  └──────────────────┘  └──────────────────┘                  │
│                                                              │
│  Recent Projects                                             │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ 🖼  Programming Course 2026                24 certificates│ │
│  │     Updated 2 hours ago                                  │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │ 🖼  English Course                         41 certificates│ │
│  │     Updated yesterday                                    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  Templates                          Fonts                     │
│  ─────────                          ─────                     │
│  [Template] [Template] [Template]   [12 fonts]              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

لكن لا نكثر العناصر.

الـ Home له ثلاث وظائف رئيسية:

1. **New Project**
2. **Open Project**
3. **Import Project**

ثم المشاريع الأخيرة.

---

# 3. إنشاء مشروع جديد — أهم Wizard

بدل فتح محرر فارغ مباشرة، نستخدم **New Project Wizard**.

### Step 1 — Project Information

```text
Create New Project

Project name
[ Programming Course 2026              ]

Organization
[ Academy / Institution                 ]

Description
[ Optional                              ]

Certificate type
○ Course
○ Training
○ Achievement
○ Participation
○ Custom

                         Cancel   Continue →
```

لا نطلب 20 إعدادًا هنا.

الهدف من هذه المرحلة:

> إنشاء السياق الأساسي فقط.

---

# 4. Step 2 — Certificate Template

هنا تظهر مكتبة القوالب.

```text
Certificate Template

┌────────────┐ ┌────────────┐ ┌────────────┐
│            │ │            │ │            │
│ Template 1 │ │ Template 2 │ │ Template 3 │
│            │ │            │ │            │
└────────────┘ └────────────┘ └────────────┘

[ Import Template ]

or

Drop image here

Supported:
PNG / JPG / WEBP / PDF
```

والأفضل أن يكون هناك:

**Use as background**

أي أن الصورة نفسها لا تصبح "التصميم كله"؛ بل:

```text
Template
    +
Fields
    +
Fonts
    +
Signature
    +
QR
```

---

# 5. Step 3 — Data Source

هنا ندخل Excel.

والتجربة يجب أن تكون ممتازة جدًا.

```text
Add Student Data

┌───────────────────────────────────────────────────┐
│                                                   │
│  Drop Excel file here                             │
│                                                   │
│  or                                               │
│                                                   │
│  [ Choose Excel File ]    [ Paste from Clipboard ]│
│                                                   │
└───────────────────────────────────────────────────┘
```

إذا لصق المستخدم جدول Excel:

```text
Student Name | Course | Grade | Date | Phone
Ahmed Ali    | Flutter| A     | ...  | 77...
Mohammed ... | Flutter| A+    | ...  | 77...
```

نقوم بتحليل الأعمدة تلقائيًا.

ثم:

```text
Imported successfully

42 students
5 columns
0 invalid rows
```

مع إمكانية:

```text
[ View Data ]
[ Edit Data ]
[ Continue ]
```

---

# 6. Data Preview يجب أن يكون Spreadsheet حقيقي

هذه نقطة مهمة.

لا تجعلها مجرد ListView.

تكون:

```text
┌────┬──────────────┬──────────┬───────┬────────────┐
│ #  │ Student Name │ Course   │ Grade │ Phone      │
├────┼──────────────┼──────────┼───────┼────────────┤
│ 1  │ Ahmed Ali    │ Flutter  │ A     │ 777...     │
│ 2  │ Mohammed     │ Flutter  │ A+    │ 778...     │
│ 3  │ Ali Hassan   │ Flutter  │ B     │ 779...     │
└────┴──────────────┴──────────┴───────┴────────────┘

42 records
```

مع:

* Search
* Sort
* Filter
* Column visibility
* Validation indicators
* Edit cell
* Add/remove row
* Paste
* Undo/redo

لكن **لا نحول التطبيق إلى Excel كامل**.

---

# 7. بعدها يأتي قلب التطبيق: Certificate Designer

وهنا يجب أن نستخدم UX شبيهًا بـ Figma / Canva / PowerPoint، لكن أبسط.

الشاشة:

```text
┌──────────────────────────────────────────────────────────────┐
│ ← Projects   Programming Course 2026      Save    Preview    │
├───────────────┬──────────────────────────────┬───────────────┤
│               │                              │               │
│ Elements      │                              │ Properties    │
│               │                              │               │
│ + Text        │      ┌────────────────┐      │ Field         │
│ + Data Field  │      │                │      │               │
│ + Image       │      │  CERTIFICATE   │      │ Name          │
│ + Signature   │      │                │      │ Font          │
│ + QR Code     │      │     Ahmed      │      │ Size          │
│ + Shape       │      │                │      │ Color         │
│               │      └────────────────┘      │ Alignment     │
│               │                              │ Position      │
│ Layers        │                              │               │
│ ─────────     │                              │               │
│ QR            │                              │               │
│ Signature     │                              │               │
│ Student Name  │                              │               │
│ Background    │                              │               │
└───────────────┴──────────────────────────────┴───────────────┘
```

هذا يربط مباشرة بمكوناتنا:

```text
certificate_designer
        ↓
Field
Position
Style
Alignment
Overflow
Layer
```

---

# 8. لا تجعل المستخدم يكتب `{student_name}` يدويًا

هذه نقطة UX مهمة جدًا.

بدل:

```text
Text:
{student_name}
```

نعطيه:

### Add Data Field

```text
Add Data Field

Available columns:

○ Student Name
○ Course
○ Grade
○ Date
○ Instructor
○ Certificate ID

[ Add Field ]
```

عندما يضغط:

> Student Name

ينشأ Box تلقائيًا.

وفي نفس الوقت داخليًا يصبح:

```text
field.type = data
field.source = student_name
```

وهكذا المستخدم لا يحتاج معرفة الـ mapping الداخلي.

---

# 9. طريقتان لإضافة البيانات

الأفضل دعم الاثنين.

### الطريقة الأولى

من لوحة:

```text
+ Data Field
```

ثم اختيار:

```text
Student Name
```

### الطريقة الثانية — Drag & Drop

من:

```text
DATA

Student Name
Course
Grade
Date
Phone
```

يسحب:

```text
Student Name
```

إلى الشهادة.

فتظهر مباشرة:

```text
┌─────────────────────┐
│     Ahmed Ali       │
└─────────────────────┘
```

وهذه تجربة ممتازة جدًا.

---

# 10. خصائص الـ Field

عند تحديد Box:

```text
FIELD

Source
Student Name

Appearance

Font
[ Cairo ▼ ]

Font Size
[ 32 ]

Weight
[ Bold ▼ ]

Alignment
[ Left Center Right ]

Color
[ ■ ]

Opacity
[ 100% ]

Text Direction
[ Auto ▼ ]

Overflow
○ Clip
○ Shrink
○ Wrap

Position

X [ 420 ]
Y [ 280 ]

Size

W [ 600 ]
H [ 80 ]
```

والأفضل دعم:

**Lock position**

**Lock size**

**Visible**

**Duplicate**

**Delete**

---

# 11. Units يجب ألا تكون Pixels فقط

داخليًا يمكن استخدام pixels أو normalized coordinates، لكن UX الأفضل:

```text
Position
X: 42%
Y: 38%

Size
W: 35%
H: 8%
```

مع خيار:

```text
Advanced
X: 1240 px
Y: 860 px
```

لماذا؟

لأن التصميم يجب أن يبقى متناسقًا إذا تغيرت دقة الـ rendering.

---

# 12. Zoom / Rulers / Guides

المحرر يجب أن يحتوي على:

```text
[−] 100% [+]
```

و:

* Rulers
* Grid
* Snap
* Alignment guides
* Center guides
* Safe margins

مثل:

```text
      100      200      300
     ↓        ↓        ↓
 ───────────────────────────
 │                          │
 │          │               │
 │          │               │
 │     ┌────────────┐       │
 │     │ Student    │       │
 │     └────────────┘       │
 │          │               │
 ───────────────────────────
```

---

# 13. Preview ليس مجرد Image Preview

يجب أن يكون هناك **Preview Mode**.

```text
Preview

Student:
[ Ahmed Ali ▼ ]

< Previous      1 / 42      Next >

┌────────────────────────────┐
│                            │
│       CERTIFICATE          │
│                            │
│          Ahmed Ali         │
│                            │
└────────────────────────────┘

[ Edit Design ]       [ Generate ]
```

والـ dropdown يتيح اختبار أي طالب.

هذه أهم طريقة لاكتشاف:

* اسم طويل
* نص طويل
* خط غير مناسب
* Box صغير
* تاريخ خاطئ
* Arabic/English alignment
* missing data

---

# 14. Signature / Stamp

لا تجعل التوقيع عنصرًا غامضًا.

داخل Designer:

```text
Elements

+ Data Field
+ Text
+ Image
+ Signature
+ QR Code
```

عند:

```text
+ Signature
```

تظهر:

```text
Signature

[ Select existing signature ]

[ Import signature ]

Position
X
Y

Size
Width
Height

Opacity
```

وممكن:

```text
☑ Include in certificate
☑ Cryptographically sign certificate
```

وهنا نفرق UX بين:

**صورة التوقيع**

و

**التوقيع الرقمي cryptographic signature**

لأنهما ليسا نفس الشيء.

---

# 15. QR Code

الـ QR لا ينبغي أن يكون مجرد صورة.

نضيفه كعنصر خاص:

```text
QR Code

Content
● Certificate Verification

Certificate ID
[ Automatic ]

Verification Data
[ Automatic ]

Size
[ 180 × 180 ]

Error Correction
[ High ]

☑ Include certificate ID
☑ Include verification metadata
```

النظام هو الذي يبني المحتوى.

المستخدم لا يحتاج فهم التشفير.

---

# 16. أهم شيء: لا نُظهر التشفير للمستخدم العادي

الـ crypto architecture عندنا:

```text
certificate_crypto
       ↓
keys
hash
signature
encryption
```

لكن UX:

```text
Security

✓ Certificate authenticity enabled
✓ Integrity verification enabled

Institution
   Al-Noor Academy

Key
   Active

[ Security Settings ]
```

ولا نقول:

> Ed25519 + SHA-512 + KDF...

إلا داخل Advanced/Security Details.

---

# 17. Project Security

عند إنشاء المشروع:

```text
Project Security

Institution
Al-Noor Academy

Project Identity
CERT-2026-FLUTTER

Security
✓ Digital signature
✓ Integrity hash
✓ Verification QR

Project Key
●●●●●●●●●●●●

[ Advanced ]
```

لكن **المفتاح نفسه لا يظهر كنص عادي**.

---

# 18. Generate — لا نضع Generate في كل مكان

هناك فرق:

### Preview

يعرض شهادة واحدة.

### Generate

ينشئ الملفات فعليًا.

عند الضغط:

```text
Generate Certificates

42 students

Output:

☑ PDF
☑ High-resolution image
☑ QR verification

Filename:

[ {student_name}_{course} ]

Export:
○ Individual files
○ ZIP package

[ Cancel ]      [ Generate 42 Certificates ]
```

---

# 19. Generation Progress

لا نجمّد الشاشة.

بل Job UI:

```text
Generating Certificates

████████████████░░░░  82%

35 / 42

✓ Ahmed Ali
✓ Mohammed Hassan
✓ Ali Ahmed
...
⟳ Abdullah Saleh

Estimated remaining: 8 sec

[ Run in Background ]
```

وعند الخطأ:

```text
⚠ 2 certificates failed

Ahmed Ali        ✓
Mohammed Hassan  ✕ Missing date
Ali Ahmed        ✓

[ Review Errors ]
[ Continue Successful ]
```

---

# 20. النتيجة — Certificate Library

بعد التوليد نذهب إلى:

```text
Certificates

42 certificates generated

Search...
[________________________]

Filter:
[ All ] [ Valid ] [ Errors ]

┌────────────────────────────────────────────┐
│ Certificate ID    Student       Status     │
├────────────────────────────────────────────┤
│ CERT-00001       Ahmed Ali      ✓ Ready    │
│ CERT-00002       Mohammed       ✓ Ready    │
│ CERT-00003       Ali Hassan     ✓ Ready    │
└────────────────────────────────────────────┘
```

وعند فتح طالب:

```text
Certificate

┌─────────────────────────┐
│                         │
│      CERTIFICATE        │
│                         │
│        Ahmed Ali        │
│                         │
└─────────────────────────┘

Certificate ID
CERT-2026-00001

Status
✓ Authentic

Files

[ PDF ]
[ Image ]

[ Share ]
[ Export ]

Security
✓ Signature
✓ Integrity
✓ QR
```

---

# 21. مشاركة WhatsApp

إذا كان عند الطالب:

```text
phone
```

نظهر:

```text
Share

[ System Share ]

WhatsApp
→ Ahmed Ali
  +967...

[ Share Certificate ]
```

لكن إذا لم يوجد:

```text
Phone number unavailable

[ Enter number ]
[ Cancel ]
```

ولا نفترض أن التطبيق يستطيع إرسال WhatsApp تلقائيًا دون قيود.

---

# 22. Project Package

هذه نقطة أراها مهمة جدًا في UX.

المستخدم لا يرى:

```text
manifest.json
fonts/
template/
keys/
```

بل يرى:

```text
Project

[ Export Project ]

This will include:

✓ Template
✓ Fonts
✓ Layout
✓ Data mapping
✓ Project settings
✓ Security configuration

Generated certificates will NOT be included.

[ Export ]
```

وعند الاستيراد:

```text
Import Project

certificate-project.cstudio

Project:
Programming Course 2026

Template ✓
Fonts ✓
Layout ✓
Mappings ✓
Security ✓

[ Import Project ]
```

---

# 23. Library للقوالب والخطوط والتوقيعات

بدل جعلها صفحات CRUD منفصلة ومزعجة:

```text
Library

Templates | Fonts | Signatures
```

مثلاً:

```text
Templates

┌────────┐ ┌────────┐ ┌────────┐
│        │ │        │ │        │
│        │ │        │ │        │
│        │ │        │ │        │
└────────┘ └────────┘ └────────┘

+ Import Template
```

والخطوط:

```text
Fonts

Cairo
Noto Sans
Amiri
Custom Font

[ + Add Font ]
```

---

# 24. Verification يجب أن يكون Feature مستقل

الشاشة الرئيسية يجب أن تحتوي:

```text
Verify Certificate
```

لأن الشخص الذي يريد **التحقق** قد لا يكون منشئ الشهادة أصلًا.

مثلاً:

```text
Verify Certificate

Drop certificate here

or

[ Select PDF / Image ]

or

[ Scan QR Code ]

or

Certificate ID
[________________]

[ Verify ]
```

ثم:

```text
Verification Result

              ✓ VERIFIED

Certificate ID
CERT-2026-00042

Issued by
Al-Noor Academy

Project
Flutter Training 2026

Recipient
Ahmed Ali

Integrity
✓ Valid

Digital Signature
✓ Valid

Status
✓ Authentic
```

ولو تم التعديل:

```text
              ✕ INVALID

Certificate integrity check failed.

The document may have been modified
after it was issued.
```

---

# 25. Navigation الرئيسية

أنا أفضل على Desktop:

```text
┌──────────────────────────────┐
│ Certificate Studio           │
├──────────────────────────────┤
│                              │
│  Home                        │
│  Projects                    │
│  Templates                   │
│  Fonts                       │
│  Signatures                  │
│                              │
│  ──────────────────────────  │
│                              │
│  Certificates                │
│  Verification                │
│                              │
│  ──────────────────────────  │
│                              │
│  Settings                    │
│                              │
└──────────────────────────────┘
```

لكن **داخل المشروع** تتغير الـ navigation إلى Workspace:

```text
Project
│
├── Overview
├── Data
├── Design
├── Preview
├── Generate
├── Certificates
└── Export
```

وهذا أفضل بكثير من خلط كل شيء في Sidebar واحد.

---

# 26. على الهاتف لا ننسخ Desktop حرفيًا

Flutter عندنا Cross-platform، لذلك يجب أن يكون Responsive حقيقي.

Desktop:

```text
Sidebar
+ Canvas
+ Properties
```

Tablet:

```text
Sidebar collapsible
+ Canvas
+ Properties drawer
```

Mobile:

```text
┌──────────────────────────┐
│ ← Project       ⋮        │
├──────────────────────────┤
│                          │
│                          │
│       Certificate        │
│                          │
│                          │
├──────────────────────────┤
│  Fields │ Layers │ Data  │
├──────────────────────────┤
│      Properties          │
└──────────────────────────┘
```

وفي الهاتف نستخدم Bottom Sheets للخصائص بدل محاولة عرض ثلاث أعمدة.

---

# 27. أهم قاعدة: Contextual UI

لا نعرض للمستخدم كل شيء دائمًا.

مثلاً إذا لم يحدد Field:

```text
Properties

Select an element to edit
```

إذا حدد Text Field:

```text
Text properties
```

إذا حدد QR:

```text
QR properties
```

إذا حدد Signature:

```text
Signature properties
```

وهذا يقلل التعقيد بشكل ضخم.

---

# 28. المشروع نفسه له Dashboard

عند فتح Project:

```text
Programming Course 2026

┌──────────────────────────────────────────┐
│ Project Overview                         │
│                                          │
│ Template             ✓ Configured        │
│ Student Data         ✓ 42 records        │
│ Field Mapping        ✓ Complete          │
│ Design               ✓ Complete          │
│ Security             ✓ Enabled           │
│                                          │
│ Certificates         42 generated        │
└──────────────────────────────────────────┘

Quick Actions

[ Edit Design ]
[ Manage Data ]
[ Generate Certificates ]
[ View Certificates ]
[ Export Project ]
```

وهذا يعطي المستخدم **حالة المشروع** بدل أن يضطر يتذكر أين وصل.

---

# 29. Project Status

وهذه نقطة UX ممتازة جدًا.

المشروع يكون له:

```text
Setup
  ↓
Template Ready
  ↓
Data Ready
  ↓
Mapping Ready
  ↓
Design Ready
  ↓
Ready to Generate
  ↓
Generated
```

وفي Dashboard:

```text
Project readiness

██████████████████░░ 90%

✓ Template
✓ Data
✓ Mapping
✓ Design
○ Generation
```

والنظام يعرف تلقائيًا هل يمكن التوليد أم لا.

---

# 30. Validation قبل Generate

عند الضغط Generate:

```text
Pre-generation Check

✓ Template exists
✓ 42 students loaded
✓ All required fields mapped
✓ Fonts available
✓ Signature available
✓ Security keys valid

⚠ 3 students have missing phone numbers

Phone is not required for certificate generation.

[ Generate ]
```

أما إذا:

```text
✕ 2 students missing Student Name
```

فـ Generate يكون:

```text
[ Fix Issues ]
```

وليس مجرد Error exception.

---

# 31. Undo / Redo

في Designer هذا **إجباري**.

```text
↶ Undo
↷ Redo
```

ويدعم:

* Move
* Resize
* Delete
* Add
* Change font
* Change position
* Change mapping

ويفضل حفظ revisions داخليًا.

---

# 32. Autosave

لا نعتمد على:

```text
Ctrl + S
```

فقط.

يكون:

```text
● Saved
```

ثم:

```text
Saving...
```

ثم:

```text
✓ Saved just now
```

مع إمكانية:

```text
Version History
```

ولو أردنا مستوى احترافي أعلى:

```text
Restore previous version
```

---

# 33. Drag & Drop

في Desktop:

```text
Excel ─────→ Data
Template ──→ Template
Font ──────→ Fonts
Signature ─→ Designer
Project ───→ Import
```

وهذا يجعل التطبيق يشعر بأنه **Desktop Studio** وليس مجرد Flutter Form App.

---

# 34. Keyboard shortcuts

لأن المستخدم سيعمل على عشرات الشهادات:

```text
Ctrl + S       Save
Ctrl + Z       Undo
Ctrl + Shift Z Redo
Ctrl + C       Copy
Ctrl + V       Paste
Ctrl + D       Duplicate
Delete         Delete
Ctrl + P       Preview
Ctrl + G       Generate
Ctrl + +       Zoom in
Ctrl + -       Zoom out
```

وفي Help:

```text
Keyboard Shortcuts
```

---

# 35. نظام Notifications داخلي

بدل Dialog لكل شيء.

مثلاً:

```text
✓ Project saved
✓ 42 certificates generated
⚠ 2 records contain missing data
✕ Failed to export ZIP
```

Toast/Snackbar مناسب للأحداث البسيطة.

Dialog فقط للقرارات المهمة:

```text
Delete project?

This cannot be undone.

Cancel    Delete
```

---

# 36. حالات النظام التي يجب تصميمها من البداية

هذه مهمة جدًا في UX الاحترافي.

كل شاشة يجب أن تحتوي على:

### Loading

```text
Loading project...
```

### Empty

```text
No projects yet

Create your first certificate project.

[ New Project ]
```

### Error

```text
Something went wrong

We couldn't load this project.

[ Retry ]
```

### Offline

```text
Offline

All local features remain available.
```

### Success

```text
✓ Completed successfully
```

### Partial success

```text
38 succeeded
4 failed

[ Review failures ]
```

---

# 37. Offline-first يجب أن يظهر في UX

لأن التطبيق أساسًا Offline.

بدل إخفاء الأمر:

```text
● Local
```

مثلاً:

```text
Certificate Studio
● Offline mode
```

لكن لا نزعج المستخدم.

إذا لم يوجد اتصال:

```text
Offline
Your projects and generated certificates remain available.
```

---

# 38. Settings

لا نضع 50 خيارًا في Settings.

```text
Settings

General
├── Language
├── Appearance
└── Storage

Institution
├── Institution Profile
└── Security Keys

Certificates
├── Default Format
├── Default Filename
└── Default Export

Verification
├── Verification Settings
└── QR Settings

Fonts
└── Font Library

Advanced
├── Database
├── Encryption
├── Diagnostics
└── Developer Tools
```

---

# 39. First-run Experience

أول تشغيل:

```text
Welcome to Certificate Studio

Create, sign, generate and verify
institution-issued certificates offline.

[ Get Started ]
```

ثم:

```text
Set up your institution

Institution name
[________________]

Institution ID
[ Auto-generated ]

Security

Your institution signing identity
will be created locally.

[ Create Institution ]
```

ثم:

```text
You're ready.

[ Create Your First Project ]
```

وهكذا لا يدخل المستخدم إلى تطبيق فارغ.

---

# 40. الـ UX النهائي كرحلة كاملة

يمكن تلخيص التطبيق كله بهذا الشكل:

```text
                         APP
                          │
             ┌────────────┴────────────┐
             │                         │
          CREATE                    VERIFY
             │                         │
             ▼                         ▼
         New Project             Select / Scan
             │                         │
             ▼                         ▼
          Template                Certificate
             │                         │
             ▼                         ▼
            Data                  Verification
             │                         │
             ▼                    ┌────┴────┐
          Mapping                 │         │
             │                  Valid     Invalid
             ▼
          Design
             │
             ▼
          Preview
             │
             ▼
       Pre-generation
          validation
             │
             ▼
          Generate
             │
             ▼
      Certificate Library
             │
       ┌─────┼─────┐
       ▼     ▼     ▼
      PDF   Image  Share
             │
             ▼
           ZIP
```

---

# 41. الربط المباشر مع الـ Architecture الذي بنيناه

وهنا يصبح التصميم قويًا لأن الـ UI ليس منفصلًا عن architecture:

| UX                    | Flutter Feature                     |
| --------------------- | ----------------------------------- |
| Home                  | `features/app`                      |
| Institution Setup     | `features/institution`              |
| Projects              | `features/projects`                 |
| Template Library      | `features/templates`                |
| Font Library          | `features/fonts`                    |
| Student Data          | `features/data_import` + `students` |
| Mapping               | `features/field_mapping`            |
| Designer              | `features/certificate_designer`     |
| Signature             | `features/signatures`               |
| Preview               | `certificate_generation`            |
| Generate              | `certificate_generation`            |
| Certificate Library   | `certificates`                      |
| Export                | `export`                            |
| Project Import/Export | `project_package`                   |
| Share                 | `sharing`                           |
| Verify                | `verification`                      |
| Security              | `certificate_crypto`                |
| Rendering             | `certificate_renderer`              |
| Excel                 | `certificate_excel`                 |

وهذا بالضبط ما نريده:

> **كل component في الـ architecture له مكان واضح في تجربة المستخدم، لكن المستخدم لا يُجبر على فهم architecture.**

---

# 42. والأهم: لا نجعل التطبيق Wizard بالكامل

هذه نقطة أريد تثبيتها في التصميم.

الـ Wizard ممتاز **لإنشاء المشروع لأول مرة**:

```text
Project
→ Template
→ Data
→ Mapping
→ Design
→ Ready
```

لكن بعد إنشاء المشروع، المستخدم يحتاج حرية الرجوع:

```text
Project
 ├── Overview
 ├── Data
 ├── Design
 ├── Preview
 ├── Generate
 ├── Certificates
 └── Export
```

لأن مثلًا بعد أسبوع سيقول:

> أريد تغيير الخط فقط.

لا ينبغي أن يمر مرة أخرى بـ:

```text
Template → Excel → Mapping → ...
```

بل يدخل:

```text
Project → Design → Font → Save
```

وهذا فرق كبير بين **UX احترافي** و**تطبيق Wizard بسيط**.

---

# 43. الشكل العام الذي أقترحه للمنتج

أرى المنتج كالتالي:

```text
                CERTIFICATE STUDIO
                       │
       ┌───────────────┴───────────────┐
       │                               │
    WORKSPACE                       VERIFY
       │                               │
       ▼                               ▼
  ┌──────────┐                    ┌──────────┐
  │ Projects │                    │ Verify   │
  └────┬─────┘                    └──────────┘
       │
       ▼
  ┌──────────────┐
  │ Project      │
  │ Dashboard    │
  └──────┬───────┘
         │
   ┌─────┼─────────┬───────────┐
   ▼     ▼         ▼           ▼
 Data  Design    Preview     Generate
   │     │         │           │
   │     │         │           ▼
   │     │         │       Certificates
   │     │         │           │
   │     │         │       ┌───┴───┐
   │     │         │       ▼       ▼
   │     │         │      PDF    Image
   │     │         │               │
   └─────┴─────────┴───────────────┘
```

**بهذا الشكل يصبح المنتج واضحًا جدًا:**

* **Project** هو الوحدة الأساسية.
* **Designer** هو قلب صناعة الشهادة.
* **Data** هي مصدر الشهادات.
* **Generate** يحول التصميم والبيانات إلى نتائج.
* **Certificates** تدير النتائج.
* **Verify** وظيفة مستقلة لأي شخص.
* **Security** تعمل في الخلفية ولا تثقل تجربة المستخدم.
* **Project Package** يجعل المشروع قابلًا للنقل بين الأجهزة.
* وكل ذلك **Offline-first**.

والخطوة الصحيحة الآن ليست كتابة كود الواجهات مباشرة؛ بل أن ننتقل إلى **UX Specification كامل شاشةً شاشة**: نحدد لكل شاشة **App Bar، Sidebar/Navigation، المحتوى، الأزرار، الحالات، dialogs، bottom sheets، transitions، empty/loading/error states، وما الذي يفتح ماذا**، ثم بعدها نحولها إلى **UI Design System موحد** (الألوان، typography، spacing، components، cards، buttons، dialogs، responsive breakpoints) قبل بناء Flutter UI.

---

# Design System

### Colors
* **Primary:** Blue (#0052CC) - Used for primary actions, active states.
* **Secondary:** Teal (#00B8D9) - Used for highlights, accents.
* **Background:** Light Gray (#F4F5F7) - Used for workspace backgrounds.
* **Surface:** White (#FFFFFF) - Used for cards, panels, dialogs.
* **Text (Primary):** Dark Gray (#172B4D) - Main typography color.
* **Text (Secondary):** Medium Gray (#5E6C84) - Subtitles, helper text.
* **Error:** Red (#DE350B) - Invalid states, error messages.
* **Success:** Green (#36B37E) - Completed jobs, verified certificates.
* **Warning:** Yellow (#FFAB00) - Alerts, missing non-critical data.

### Typography
* **Font Family (English):** Inter or Roboto.
* **Font Family (Arabic):** Cairo or Noto Kufi Arabic.
* **Headings:** H1 (24px, Bold), H2 (20px, Semi-Bold), H3 (16px, Medium).
* **Body Text:** Normal (14px, Regular).
* **Small/Caption:** Caption (12px, Regular).

### Spacing & Layout
* **Base Unit:** 8px grid system (8, 16, 24, 32, 48).
* **Padding:** 16px for standard panels, 24px for dialogs.
* **Border Radius:** 8px for cards and panels, 4px for buttons and inputs.

---

# State Specifications

### 1. Home / Workspace
* **Loading:** Skeleton loaders for the Recent Projects list.
* **Empty:** Illustration with "Create your first project" button.
* **Error:** "Failed to load projects" with a "Retry" button.
* **Success:** Normal view with populated project list.

### 2. Certificate Designer
* **Loading:** Spinner centering the canvas while loading assets.
* **Empty:** Blank canvas with placeholder "Drop template here".
* **Error:** Missing font or template error dialog.
* **Success:** Fully rendered canvas and properties panel.

### 3. Data Import
* **Loading:** Progress bar during Excel parsing.
* **Empty:** Empty drop zone for Excel file.
* **Error:** Validation error table highlighting invalid rows.
* **Success:** Data grid showing successfully imported records.

### 4. Verification
* **Loading:** Scanning animation.
* **Empty:** Idle drop zone / QR scanner waiting for input.
* **Error:** "✕ INVALID" message with red highlight.
* **Success:** "✓ VERIFIED" details card with green highlight.

---

# Accessibility

* **RTL Support:** Full Right-To-Left layout support for Arabic, mirroring navigation, sidebars, and input fields.
* **Keyboard Navigation:** 
  * Full `Tab` navigation through interactive elements.
  * `Enter` / `Space` to activate buttons and checkboxes.
  * `Esc` to close modals and dropdowns.
* **Contrast:** Minimum 4.5:1 contrast ratio for all text against backgrounds to ensure readability.
* **Screen Readers:** ARIA labels on all icon-only buttons and canvas elements.

---

# Desktop Interactions

### Keyboard Shortcuts
* `Ctrl + S`: Save Project
* `Ctrl + Z` / `Ctrl + Shift + Z`: Undo / Redo in Designer
* `Ctrl + P`: Open Preview Mode
* `Ctrl + G`: Trigger Generation
* `Delete`: Remove selected element from Canvas
* `Ctrl + +` / `Ctrl + -`: Zoom Canvas In / Out

### Right-Click Context Menus
* **Canvas Elements:** Bring to front, Send to back, Lock/Unlock, Duplicate, Delete.
* **Data Grid Rows:** Edit row, Delete row, Duplicate row.
* **Certificate Library:** Open, Export as PDF, Verify, Share.

### Drag-and-Drop Zones
* **Home Screen:** Drop `.cstudio` project files to import.
* **Designer Canvas:** Drop image files to use as template/background or insert shapes/logos.
* **Data Import:** Drop `.xlsx` or `.csv` files to load students.
* **Verification:** Drop certificate `.pdf` or image files to verify.
