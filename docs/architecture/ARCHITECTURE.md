# ARCHITECTURE — القواعد الثابتة

## القاعدة الأساسية

```text
Screen → Screen Model / ViewModel → Repository contract ←→ Data implementation (محلي الآن، سحابي لاحقًا)
```

- الواجهة تعرض الحالة وترسل نية المستخدم؛ منطق المنتج يتعامل مع أنواع مستقلة.
- Domain أنواع قياسية بلا استيراد SwiftUI/Compose أو Context أو HTTP أو SDK تخزين.
- implementation واحد حقيقي واحد الآن (المخزن المحلي)؛ قابلية التبديل لاحقًا تتحقق بالحدود لا بكتابة implementation غير مستخدم.
- تركيب الاعتماديات صريح في نقطة واحدة عند بدء التطبيق، بلا مكتبة DI.
- مالك الحالة: screen model لكل شاشة؛ لا controller عالمي؛ draft المحرر local state بعمر واضح لا يفقد عند تحديث عابر.
- بناء feature-first: `Features/Tasks` و`Features/Projects` (+ غيرهما عند حاجة فعلية).

## الهيكل المستهدف (iOS أولًا — قرار D1)

المثال التفصيلي في `docs/guide/task_management_zcode_guide_ar.md` §6 (شجرة `TaskManagement/`). يُنشأ عند Checkpoint 2 بالأجزاء ذات الاستخدام الفعلي فقط — لا مجلدات فارغة ولا ملفات استباقية.

## قواعد متقاطعة

- قاعدة تصنيف التواريخ والترتيب في مكان واحد فقط (موضحة في `DATA_CONTRACTS.md`).
- كل mutation يعيد العنصر المحفوظ أو failure معلومًا؛ الواجهة لا تفترض نجاحًا صامتًا.
- IDs ثابتة لقوائم SwiftUI/Compose.
- لا I/O متزامن على خيط UI؛ الاشتراكات تُغلق حسب lifecycle.
- لا cache/outbox/event bus/طبقات services استباقية.

## جاهزية السحابة (قرار D2 — ما الذي يجعل الترقية آمنة لاحقًا)

- كل قراءة/كتابة تمر عبر repository contract — إضافة تنفيذ سحابي لا يمس الواجهة.
- لا افتراضات محلية مسربة للنوع العام (لا صفوف DB في الواجهة).
- الحقول المستقبلية (ownerId/workspaceId/revision) موثقة في DATA_CONTRACTS وتُضاف وقتها بـ migration.
