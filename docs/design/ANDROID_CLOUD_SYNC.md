# Personal cloud sync — D32، 2026-10-08

## النطاق والحقائق قبل التنفيذ

المستخدم طلب استكمال «التذكيرات وكدا» بعد مناقشة تأجيل التذكيرات والمزامنة، ورفع كل العمل. نفهم النطاق استكمال A3/A4 في مشروع Native القائم، لا تحويله إلى Flutter. دمج اللوجو له سؤال منصة مستقل ما زال معلقًا.

Supabase الحالي المحدد بالإعداد المحلي متاح، وجداول tasks/projects مطابقة للمصدر، وRLS owner-only مفعّل. تحقق SQL اقتصر على metadata. Room v1 موجود وreminderDate مهيأ. حساب iOS اختياري ومزامنته يدوية. مراجعة iOS كشفت عيوبًا مؤثرة في التشغيل المشترك: push غير مشروط قبل pull، trigger يبدل updated_at إلى وقت الاستلام، tombstone upsert دون الحقول المطلوبة، due_day كنموذج Date رغم كونه يومًا فقط، وPersistedTombstone غير مدرج في Bootstrap schema. تُصحح الأجزاء اللازمة للتوافق بدل نسخ العيوب لأندرويد.

## معايير القبول

- حساب اختياري بالبريد وكلمة المرور، إنشاء حساب/تأكيد البريد، دخول/خروج واستعادة جلسة مشفرة بـAndroid Keystore. لا gate جديد في startup ولا حاجة للشبكة للمهام المحلية.
- إعدادات public URL/client key من ملف ignored + example؛ لا service_role أو سر إداري داخل التطبيق أو GitHub.
- زر حساب ومزامنة في التنقل الحالي؛ حالة تقدم/نجاح/فشل صادقة ومنع النقرات المتكررة. لا مزامنة تلقائية أو realtime أو فريق ضمن C1.
- RPC واحد Security Invoker، owner = auth.uid()، grant لـauthenticated فقط؛ معاملة server ذرية ومقارنة updated_at تمنع الكتابة القديمة من سحق الأحدث. deleted_at جزء من LWW وتنتشر آثار الحذف؛ المشروع المحذوف لا يحذف مهامه.
- JSON date-only YYYY-MM-DD لـdue_day، وISO instant للتذكير/التواريخ الأخرى.
- Room يبقى مصدر الواجهة. snapshot صادر متسق؛ تطبيق ذري يحافظ على التعديلات المحلية الأحدث ويحترم الحذف، ثم إعادة مصالحة التذكيرات. لا migration أو مسح محلي.
- نسخة JSON احتياطية إلزامية محفوظة ذريًا قبل أول sync. فشل النسخة يوقف العملية. لا نقل بيانات الجهاز إلى حساب آخر: ربط أول مزامنة بحساب واحد، ومنع المزامنة بحساب مختلف دون حذف البيانات.
- عند فشل شبكة أو session أو server تظل البيانات والمسودات محفوظة؛ لا عدّ مزامنة ناجحة قبل انتهاء RPC وتطبيق Room.
- iOS يستخدم نفس RPC وتصحيح التواريخ وآثار الحذف والأخطاء والنسخة الاحتياطية، مع الحفاظ على التنقل والمظهر.
- تحقق build/lint، RPC/LWW/delete/RLS في معاملة تجربة rollback دون تعديل بيانات المستخدم أو إرسال بريد، وتجربة الواجهة المحلية والأخطاء على المحاكي. لا ادعاء تسجيل دخول حقيقي أو مزامنة جهازين دون بيانات حساب واختبار فعلي.

## الملفات والأثر

Android: cloud config/API/session vault/controller وAccountSheet، DAO snapshot/apply في طبقة data، ViewModel وHome/TaskApp، manifest وgradle وgitignore. iOS: bootstrap/repository/cloud service للسلامة والتوافق فقط. SQL: دالة sync شخصية ومراجعة trigger الموجودة، دون إعادة تشغيل schema.sql على المشروع. docs وREADME والحالة تُحدّث بعد التحقق. لا نشر موقع.

## مراجع روجعت

- https://supabase.com/changelog.md — فُحص فهرس breaking changes قبل التنفيذ.
- https://supabase.com/docs/guides/auth/passwords
- https://supabase.com/docs/guides/auth/sessions
- https://supabase.com/docs/guides/database/functions

## التحقق الفعلي — 2026-10-08

Android assembleDebug/lintDebug نجحا (0 errors / 16 warnings). iOS simulator build نجح وفتح التطبيق على iPhone 17 Pro/iOS 26.2 إلى RootTabs/Home الموجودين، مع صورة تشغيل فعلية. أُضيف PersistedTombstone إلى SwiftData schema، واستُبدلت عمليات push/pull غير المشروطة بـ RPC، وتصحيح day-only والدمج الذري والنسخة الاحتياطية وaccount binding.

migration 20261007230659_personal_sync_rpc طبقت على Supabase باستخدام migration API. اختبارات SQL داخل BEGIN/ROLLBACK نجحت لـ LWW/date/tombstones/detach/atomic failure/RLS read-write-RPC. استخدمت UUIDs ثابتة لfixtures داخل المعاملة، دون بريد أو جلسة أو بقاء بيانات تجريبية. security advisor: lints=[] بعد النشر. لا تعديل لبيانات المستخدم الموجودة.

لم تُجرَ تجربة حساب حقيقي أو تأكيد بريد أو انتقال بيانات بين جهازين؛ فحص SQL ليس دليلًا عليها. جلسات Android/Keystore والـrefresh تحتاج اختبار حساب حقيقي. ملفات الاتصال الفعلية ignored ولم تدخل Git.

Backend auth smoke: login-only request with reserved example.invalid credentials returned HTTP 400 / invalid_credentials. No sign-up, mail or account created. This confirms backend reachability/error behavior only, not successful Android/iOS login.

Android runtime: account sheet opened from existing Home menu, showed the configured optional sign-in form, and empty submit displayed «البريد الإلكتروني وكلمة المرور مطلوبان.» without account/network mutation. Closing it retained local tasks.
