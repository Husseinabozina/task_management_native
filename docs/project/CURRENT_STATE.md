Current phase: Checkpoint 8 مكتمل (حالة شغالة عليها + تثبيت 📌) — مبني بنجاح في مجلد معزول، بانتظار تجربة المستخدم (السيميوليتر كان معلقًا فتُرك له)
Project path: /Volumes/Hussein/DevStorage/Projects/task_management_native (الهارد الخارجي — symlink في الـ workspace)
Branch / HEAD: main — commit: Checkpoint 8
Approved scope: V1 + فيجما D8 + إضافات مرخصة (D18/D19) + D20/D21
Locked decisions: D1–D21 (جديد: D20 حالة شغالة عليها، D21 تثبيت المهام)
Completed behaviors (منطقيًا): عقد الحالة صار 3 حالات + isPinned؛ الفلاتر 4؛ الترتيب مثبت أولًا؛ pills من الفيجما؛ المحرر فيه اختيار الحالة + تثبيت؛ الإتمام من الـpill يعمل من أي حالة غير مكتملة؛ الشغالة تدخل Today/Overdue وتُعد في العدادات
Implemented but runtime-unverified: نفس أعلاه — build ناجح في /tmp/tm_verify_dd، التشغيل للـuser (السيميوليتر معلق الإقلاع)
Verification actually performed: build ناجح، parse نظيف، مراجعة دلالية للفلاتر والعدادات (لا بقايا حالتين)، lightweight migration موثقة (خاصية جديدة بقيمة افتراضية)
Known issues: migration SwiftData التلقائية تحتاج تشغيل حقيقي واحد للتأكد العملي (فتح التطبيق بعد التحديث)
Deferred features: BACKLOG (بروفايل/اسم المستخدم، markdown display أُنجز في D19 والباقي board/templates/tags، تذكيرات، سحابة، أندرويد)
Native / visual review: user-owned — بعد ⌘R: جرّب تغيير حالة مهمة من المحرر لـ«شغالة عليها» وشوف pill البرتقالي + ثبّت مهمة وشوفها أول القائمة + بياناتك القديمة لسه موجودة
Exact next checkpoint: 9 — التذكيرات (بعد اعتماد الـ8) أو جلسة تخطيط السحابة — بقرار المستخدم
