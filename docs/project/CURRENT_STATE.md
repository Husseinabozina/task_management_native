Current phase: Checkpoint 6 جاهز للتجربة — كود مكتمل وسليم نحويًا (لم يُبنى بعد — المستخدم سيتولى البناء والتشغيل بنفسه في Xcode)
Project path: /Volumes/Hussein/DevStorage/Projects/task_management_native (الهارد الخارجي — والمسار /Users/husseinabozina/.zcode/workspace/default/task_management_native symlink ليه)
Branch / HEAD: main — آخر commit: نقطة استرجاع قبل تجربة المستخدم لـCheckpoint 6
Approved scope: FEATURE_SCOPE.md «معتمد في V1» + فيجما معتمدة (D8) + ترخيص إضافات (تقويم D18)
Locked decisions: D1–D18 (آخرها D18: شاشة التقويم كتابت رابع + 4 تابات بمواقع الفيجما)
Completed behaviors (منطقيًا — بانتظار البناء): شاشة التقويم (شهر بتنقّل + شبكة 6 أسابيع تبدأ من أول يوم الجهاز + شارات عدد المهام المفتوحة + ضغطة يوم تفتح مهامي مفلترة عليه) + الشريط 4 تابات (home/تقويم بنسختي bold-bulk/مستند-مهامي/شنطة-مشاريع) + أيقونة تطبيق مولدة (بنفسجي + صح أبيض) في الـ catalog
Implemented but runtime-unverified: كل أعلاه — الكود الجديد لم يُبنَ إطلاقًا (بناء سابق اتعطل بقفل DB لتعارض مع Xcode المفتوح)
Verification actually performed: swiftc -parse نظيف لكل ملفات Swift؛ مراجعة يدوية كشفت وأصلحت bug ترتيب أيام الأسبوع (الصيغة القديمة كانت تبدأ بالجميع)؛ لا build ولا تشغيل — المستخدم اتولى
User changes preserved: مهمة المستخدم «يلا» ومشروع «مشروع تجربة — امسحني» في مخزن السيميوليتر
Known issues: درجات الدارك مشتقة مبدئيًا وتحتاج عين المستخدم؛ نسبة نجاح بناء كود التقويم الجديد غير مثبتة بعد
Deferred features: docs/project/BACKLOG.md (بروفايل تاب خامس مستقبلي، markdown display، cloud، تذكيرات...)
Native / visual review: user-owned — مطلوب منه: ⌘R في Xcode وتجربة التابات الأربعة والتقويم + فحص الأيقونة على الهوم سكرين + الدارك مود
Exact next checkpoint: 6-ب — استقبال ملاحظات المستخدم (أو errors البناء) وإغلاق Checkpoint 6
