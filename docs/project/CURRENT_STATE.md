Current phase: Checkpoint 9 مكتمل (التذكيرات 🔔) — مبني بنجاح في مجلد معزول؛ الإشعارات الفعلية تحتاج تشغيل المستخدم (جدولة + إذن)
Project path: /Volumes/Hussein/DevStorage/Projects/task_management_native (الهارد الخارجي — symlink في الـ workspace)
Branch / HEAD: main — commit: Checkpoint 9
Approved scope: V1 + فيجما D8 + إضافات مرخصة (D18/D19) + D20/D21/D22
Locked decisions: D1–D22 (جديد D22: التذكيرات مربوطة بالمواعيد + مزامنة تلقائية للإشعارات + إذن لحظة التفعيل)
Completed behaviors (منطقيًا): المحرر يعرض كارت «تذكير 🔔» فقط للمهام ذات موعد، بوقت قابل للاختيار (افتراضي 9 صباحًا يوم الموعد ويتبع تغيّر اليوم)؛ طلب الإذن لحظة التفعيل والرفض يعني لا حفظ للتذكير مع رسالة واضحة؛ إطفاء الموعد يطفئ التذكير؛ ReminderSync يراقب كل المهام ويجدول/يلغي/يحدث إشعارات النظام بهوية المهمة؛ إتمام أو حذف مهمة = إشعارها يُلغى؛ التفاصيل تعرض صف «التذكير 🔔» بمعاده؛ delegate يعرض البانر حتى والتطبيق مفتوح
Implemented but runtime-unverified: جدولة الإشعار الفعلية ووصوله (يحتاج تشغيل المستخدم: ذكّرني بعد دقيقتين واقفل التطبيق وشوف)، وlightweight migration لـreminderDate عند أول فتح للنسخة الجديدة
Verification actually performed: xcodebuild ناجح في /tmp/tm_verify_dd؛ parse نظيف؛ مراجعة مصادر ضد قواعد الدليل §21 (لا ادعاء تذكير قبل جدولة حقيقية — الحالة الحالية: الجدولة موجودة والتأكيد النهائي runtime)
Known issues: إقلاع السيميوليتر كان معلقًا من قبل فالتشغيل مسند للمستخدم
Deferred features: BACKLOG (بروفايل/اسم المستخدم، board/templates/tags المتبقي، السحابة والفريق، أندرويد)
Native / visual review: user-owned — قائمة تجربة التذكيرات أُرسلت في الرسالة
Exact next checkpoint: 10 — جلسة تخطيط السحابة والفريق (بقرار المستخدم) أو أي بند من BACKLOG يطلبه
