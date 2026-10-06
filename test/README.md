# Test architecture

تتبع اختبارات **Certificate Studio** حدود المعمارية النظيفة الموجودة في `lib/`. الهدف ليس جمع اختبارات كثيرة في ملف واحد، بل ربط كل اختبار بحدّ واضح ومسؤولية واحدة، مع اختبارات سلوك حقيقية للحالات السليمة والفاشلة والحالات الحدية.

## شجرة الاختبارات

```text
test/
├── architecture/                         # حراس بنية الاختبارات والتسمية
├── config/
│   ├── env/                              # AppEnvironment والثوابت
│   └── localization/                     # التعريب والـ fallback
├── core/
│   ├── data/models/                      # row/JSON ↔ entity
│   ├── database/                         # schema، migrations، CRUD
│   ├── entities/                         # OperationResult والكيانات العامة
│   └── security/                         # key storage وkey managers
├── features/
│   ├── app/presentation/                 # startup، BLoCs، app shell
│   ├── certificates/
│   │   ├── data/services/                # generation، export، rendering
│   │   ├── data/models/                  # certificate mappings
│   │   └── presentation/                 # library/designer widgets
│   ├── data_import/
│   │   ├── data/                         # datasource/repository
│   │   ├── domain/                       # ImportedTable/use cases
│   │   └── presentation/                 # BLoC، DataPreview، screens
│   ├── institution/presentation/         # setup screen
│   ├── projects/domain/                  # create/delete use cases
│   ├── shared/integration/               # cross-feature workflows only
│   └── verification/domain/              # certificate/QR verification
├── shared/
│   ├── fonts/                            # Arabic PDF/font behavior
│   └── utils/                            # field identifiers and pure helpers
└── helpers/                              # fakes/builders المشتركة عند الحاجة فقط
```

## طبقات الاختبار المطلوبة

| الطبقة | ما الذي تختبره؟ | القاعدة |
|---|---|---|
| `unit` | domain entities، use cases، pure utilities، state transitions | لا تعتمد على UI أو قاعدة بيانات حقيقية |
| `data` | models، data sources، repositories، serialization | تستخدم in-memory database أو fake storage |
| `contract` | التزام service/repository بالواجهة وسلوك الفشل | تختبر كل فرع public مهم، وليس implementation details |
| `integration` | workflow يعبر أكثر من feature أو database boundary | عددها قليل ومسمّاة حسب السيناريو |
| `presentation` | loading/empty/error/success، forms، dialogs، navigation | تستخدم `flutter_test` وقيود MediaQuery ثابتة |
| `architecture` | بنية شجرة الاختبار والتسمية وحجم الملفات | تمنع رجوع ملفات coverage المجمّعة إلى الجذر |

## معايير الجودة

- كل ملف إنتاج مهم له اختبار قريب من حدّه المعماري.
- كل public method له success path وفشل متوقع وحالة حدية حيث ينطبق.
- لا توجد اختبارات باسم عام مثل `coverage_test.dart` أو `widget_test.dart`.
- لا توجد ملفات `_test.dart` مباشرة داخل `test/`.
- اختبارات الـ UI تختبر السلوك المرئي والتفاعل، لا تفاصيل private classes المقسمة بـ `part`.
- اختبارات التشفير والتحقق لا تتجاوز فشل التوقيع أو فساد الـ hash بصمت.
- اختبارات التصدير لا تعتمد على وجود file picker تفاعلي؛ تعزل artifact store وتختبر payload/archive contracts.

## التشغيل المحلي

```bash
flutter pub get
flutter analyze
flutter test
flutter test --coverage
```

اختبارات التوليد التي تحتاج native renderer تُشغّل صراحة فقط:

```bash
flutter test --dart-define=RUN_NATIVE_GENERATION_TESTS=true
```

## الحالة الحالية

- الاعتماديات مثبتة عبر `flutter pub get`.
- `flutter analyze` يمر بلا مشاكل.
- جميع الاختبارات الحالية تمر.
- توجد تغطية مباشرة للـ core، database، models، repositories، BLoCs، DataPreview، institution setup، verification failure paths، export contracts، وArabic font behavior.
- تقرير التغطية يُستخدم لاكتشاف الفجوات، وليس كبديل عن اختبار السلوك. الملفات التي تعتمد على native rendering أو file picker تُختبر بعقود وfakes في الاختبار العادي، وباختبار native اختياري منفصل.
