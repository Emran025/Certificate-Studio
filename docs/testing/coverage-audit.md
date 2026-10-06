# Coverage and architecture audit

## Scope

هذا التدقيق يراجع الاختبارات والتنظيم فقط. لا يغيّر أي وظيفة إنتاجية أو عقد API أو سلوك مستخدم.

## Findings

| الأولوية | الفجوة | الأثر | الإصلاح المهني |
|---|---|---|---|
| P0 | لا توجد تغطية كافية لمسارات فشل نقل المؤسسة/المشروع | خطر فقدان بيانات أو قبول archive غير صالح | اختبارات contract لكل validation وformat/key mismatch قبل اختبار file picker |
| P0 | `persistent_app_database_io.dart` كبير ويجمع migration/open/CRUD/transactions | صعوبة المراجعة وعزل الأعطال | فصل adapter، transaction coordinator، وCRUD query helpers بعد تثبيت characterization tests |
| P1 | معظم presentation `part` files لا تظهر في LCOV | سلوك الواجهات غير محمي بالكامل | اختبارات screen-level بحالات empty/loading/error/success وnavigation |
| P1 | PDF/PNG renderer كبير | صعوبة اختبار الخطوط والخلفيات وحقول RTL مستقلًا | فصل background preparation، field layout، PDF output، وPNG output مع golden/contract tests |
| P1 | platform implementations لها branches غير مختبرة | فروق IO/Web قد تنكسر بصمت | fake platform providers وtests منفصلة لكل implementation |
| P2 | بعض الاختبارات التكاملية ما زالت واسعة | صعوبة تحديد سبب الفشل | إبقاء integration للحدود العابرة فقط، ونقل pure/domain checks إلى ملفات أقرب للمصدر |
| P2 | لا يوجد حد coverage خاص بالطبقات | قد ترتفع النسبة بسبب اختبارات غير متوازنة | إضافة مؤشرات layer-aware تدريجية بدل ادعاء 100% شامل مبكرًا |

## Baseline

- `flutter analyze`: clean.
- Full suite: passing.
- 72 tests before this audit expansion.
- LCOV baseline: 25.89% (`1700/6566`).
- Largest remaining production surfaces include database IO, artifact renderer, designer/library screens, and workspace transfer.

## Definition of done

1. لا يتغير سلوك الإنتاج إلا بإصلاح defect مثبت باختبار فاشل.
2. كل public branch في domain/data services له test contract أو integration test.
3. كل screen رئيسي له empty/loading/error/success interaction tests.
4. كل platform implementation يملك test harness مستقلًا.
5. لا تُستعمل exclusions أو generated coverage أو assertions شكلية للوصول إلى رقم مرتفع.
6. كل مرحلة تنتهي بـ `flutter analyze`, `flutter test --coverage`, و`git diff --check`.

## Plan

1. حماية data-transfer وdatabase boundaries أولًا.
2. تثبيت renderer contracts ثم تقسيم renderer إلى مكونات صغيرة.
3. إضافة screen behavior suites حسب feature.
4. تفعيل layer-aware coverage report ورفع floor تدريجيًا.
5. الوصول إلى 100% فقط عندما يكون الرقم حقيقيًا وقابلًا للصيانة، مع فصل native/golden suites عند الحاجة.
