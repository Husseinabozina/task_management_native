Current phase: C1 السحابة (Supabase) كود مكتمل ومبني بنجاح — بانتظار: (أ) إنشاء مشروع Supabase من المستخدم (checklist 5 دقائق في docs/supabase/SETUP.md) (ب) تجربة V1 الشاملة
Project path: /Volumes/Hussein/DevStorage/Projects/task_management_native (الهارد الخارجي — symlink في الـ workspace)
Branch / HEAD: main — commit: C1 Supabase
Approved scope: V1 (Checkpoints 0-9) + السحابة C1 بقرار المستخدم (D23 / CLOUD_PLAN)
Locked decisions: D1–D23 (جديد D23: Supabase + full snapshot LWW + tombstones + نسخة احتياطية قبل أول مزامنة)
Completed behaviors (منطقيًا): schema.sql كامل (جداول + RLS owner-only + triggers revision + profile تلقائي)؛ supabase-swift SPM؛ SupabaseConfig.plist (gitignored) + example؛ AuthSession (دخول/حساب جديد برسائل عربية مفهومة)؛ AccountSheet من أيقونة ☁️ في رأس الرئيسية (بدون config: حالة إعداد صادقة بخطواتها)؛ CloudSyncService: دفع/جلب كامل LWW + tombstones + نسخة احتياطية إلزامية قبل أول مزامنة؛ الحذف المحلي يسجل tombstone
Implemented but runtime-unverified: كل مسار السحابة — مستحيل اختباره قبل إنشاء مشروع Supabase الحقيقي وملء الـ plist (هذا دور المستخدم)؛ أول تشغيل كذلك يختبر migrations السمات الجديدة
Verification actually performed: xcodebuild ناجح (معزول) مع حل SPM، parse نظيف، مراجعة مصادر ضد CLOUD_PLAN
Known issues: قيم التواريخ في JSON مع supabase-swift تعتمد الافتراضي — يحتاج تأكيد runtime؛ واجهة حساب بإيميل فقط — Apple Sign-in مؤجل لـ C2
Deferred features: BACKLOG
Native / visual review: user-owned
Exact next checkpoint: 10 — المستخدم: (1) checklist SETUP.md (2) تجربة V1 الشاملة (3) أول مزامنة حقيقية ورفع التقرير
