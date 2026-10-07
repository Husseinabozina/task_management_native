# README portfolio checkpoint — D30، 2026-10-08

## الطلب ومعايير القبول قبل التنفيذ

المستخدم طلب README منسقًا مثل بقية مشاريعه، مع الصور الثماني المرفقة وروابط المشاريع، والتأكيد على Native لـ iOS وAndroid. طلب صراحة عدم إنشاء موقع؛ سينشئه من مكان آخر.

- README في جذر المشروع: أيقونة، تعريف باللغتين، شارات التقنية، تنقل للأقسام، معرض صور، مزايا، منصتان Native، حالة المشروع، تشغيل وروابط فعلية.
- كود iOS مستقل بـ Swift/SwiftUI وSwiftData؛ Android بـ Kotlin/Jetpack Compose وRoom. لا تسويق المزامنة أو التذكيرات المؤجلة على Android كميزات متاحة.
- الصور الثماني الأصلية تُنسخ دون تعديل إلى docs/showcase/screenshots بأسماء وصفية؛ تُنسب إلى لقطات Android التي أرسلها المستخدم في 2026-10-08. المحتوى التجريبي وهمي، وليس لقطات iOS أو تصميمًا مولدًا.
- روابط مشاريع المطور من README مشروع NOVA المحلي، مع تحقق HTTP، ودون اختراع رابط لموقع مهامي أو متجر أو فيديو أو إصدار تنزيل.
- التشغيل قابل للتطبيق من المصدر باستخدام مسارات نسبية؛ شرح script الهاتف وأسلوب --seed-demo الصريح، دون تضمين المسارات الشخصية للماك في README العام.
- الفحوص: وجود كل المراجع المحلية وanchors، سلامة صور JPEG وأبعادها، نسخ الصور byte-for-byte، git diff --check ومراجعة أوامر التشغيل أمام المصدر. لا build أو tests أو تشغيل للتطبيق لهذه المهمة التوثيقية.

## الثوابت وخريطة التأثير

README جديد، docs/showcase للأصول ونسبها، DECISIONS وCURRENT_STATE فقط. لا تغيير لكود التطبيق أو البيانات أو إعدادات البناء أو موقع أو نشر أو رفع GitHub. التعديلات المحلية السابقة تبقى كما هي، بما فيها حذف Package.resolved السابق.

مرجع التنسيق: /Volumes/Hussein/DevStorage/Projects/fashion_e_commerce/README.md. روابط NOVA وBrees وHealthTrack رجعت HTTP 200 أثناء القراءة. التحقق من حالة المنصتين بالمصدر وCURRENT_STATE وملفات المشروع؛ اكتمال البناء السابق ليس قبولًا نهائيًا لكل رحلة.

## إغلاق المعايير والتحقق الفعلي

| المعيار | النتيجة |
| --- | --- |
| تعريف Native لـiOS وAndroid | في العنوان والمقدمة وجدول التقنيات، مع SwiftUI/SwiftData وCompose/Room وحدود كل منصة |
| عرض الصور الثماني | 4 صور رئيسية + 4 صور في قسم قابل للفتح، روابط للأصل ونصوص alt لكل صورة |
| سلامة الأصول | JPEG 720×1604 سليمة بقراءة Pillow verify؛ SHA-256 مطابق للمرفقات الثماني؛ الأيقونة من كتالوج التطبيق |
| الروابط والتنقل | 20 هدفًا محليًا موجودة و4 anchors صحيحة؛ HTML متوازن؛ الشارات الأربع رجعت SVG وHTTP 200 عند GET، ومشاريع المطور الثلاثة HTTP 200 |
| الحالة الصادقة | إظهار iOS source/runtime distinction وAndroid deferred reminders/cloud والبيانات الوهمية |
| التشغيل | المسارات/المشروع/scheme/الأدوات/خيارات launcher طوبقت مع ملفات المشروع؛ لم تُنفذ الأوامر لهذه المهمة |
| النطاق | لا موقع ولا تغيير كود أو بيانات أو build أو tests أو نشر أو push |

فُتح ملف README في Codex عبر open_in_codex (الطلب queued). لم يُرفع إلى GitHub، لذلك لا ادعاء معاينة GitHub rendered النهائية. نُسخة المعاينة المحلية تستخدم مسارات ملفات مطلقة لعرض الأصول؛ README المستودع يستخدم مسارات نسبية قابلة للنقل. الحزمة المسلّمة تحتوي README وdocs/showcase فقط، وتوضع في جذر المستودع الحالي.

الثقة مرتفعة في المحتوى وسلامة الأصول والمراجع؛ عرض GitHub النهائي ينتظر رفع الملفات. لا تنطبق مقارنة فريم Figma بالتطبيق على هذا التغيير التوثيقي؛ لا واجهة تطبيق تغيّرت.

D31/D32: README status and features updated for native reminders and optional personal sync. SQL checks and simulator startup are distinguished from real-account/device acceptance; the eight original owner-supplied Android captures remain unchanged. No website was created.

GitHub delivery verified after push 51e4e34: rendered README HTML HTTP 200, all eight screenshot names, SwiftUI/Jetpack Compose and details section present. README + icon + eight screenshot raw URLs (10 files) returned HTTP 200. This is rendered-markup/link verification; no claim of a browser pixel comparison.
