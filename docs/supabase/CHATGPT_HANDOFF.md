# CHATGPT_HANDOFF — تسليم سياق المشروع لمحادثة ChatGPT (بـ Supabase connector)

> انسخ المحتوى اللي داخل الكود بلوك في الرد من أول سطر لآخره والصقه كأول رسالة في محادثة ChatGPT الجديدة.
> آخر تحديث: 2026-10-04

---

```text
أهلاً — أنا شغال على تطبيق مهام iOS Native وسجّلت مشروعك Supabase عندك بالـ connector.
فيه المطلوب منك بالظبط في الآخر — الأول اقرأ السياق كله.

═══════════════ 1) المشروع ═══════════════
اسم الكود: task_management_native (repo خاص: Husseinabozina/task_management_native)
التطبيق: «مهامي» — تطبيق مهام iOS Native بـ SwiftUI (iOS 17+، @Observable، SwiftData تخزين محلي).
اللغة: عربي RTL أولًا (كله عربي).
التصميم: معتمد من فيجما مرجعية (بنفسجي #5F33E1، خط Cairo/Lexend Deca، bottom bar بـ notch).
الحالة: V1 كاملة (قائمة/مهنّم/تفاصيل Markdown/تقويم/مشاريع/3 حالات/تثبيت/تذكيرات محلية) + كود C1 للسحابة مكتوب — لكن **مفيش حاجة اتشغلت runtime لسه** (المستخدم ه يختبر دلوقتي).

═══════════════ 2) المعمارية (مهم تفهمها قبل أي SQL) ═══════════════
- المحلي مصدر الحقيقة: SwiftData على الجهاز. السحابة طبقة مزامنة (مرآة) — التطبيق offline-first كامل.
- كل قاعدة/كتابة تمر عبر Repository contracts — السحابة تنفيذ تاني لنفس العقود.
- المزامنة (C1): full snapshot باتجاهين بقاعدة LWW (الأحدث updated_at يفوز).
- الحذف: tombstones — عمود deleted_at (مش حذف فعلي) عشان الحذف ينتشر بين الأجهزة.
- التذكيرات: جدولة محلية لكل جهاز (UNUserNotificationCenter) — reminder_date بيانات بتتزامن، والإشعار نفسه محلي.

═══════════════ 3) السكيما المفروضة في Supabase (المصدر: docs/supabase/schema.sql) ═══════════════
3 جداول في public:

profiles(id uuid pk → auth.users, display_name text, created_at timestamptz)
  - trigger on_auth_user_created يعمل insert تلقائي عند التسجيل.

projects(
  id uuid pk, owner_id uuid → auth.users, name text not null,
  emoji text, color_key text, created_at timestamptz default now(),
  updated_at timestamptz default now(), revision bigint default 1,
  deleted_at timestamptz)

tasks(
  id uuid pk, owner_id uuid → auth.users, title text not null, details text,
  status text default 'active',        -- القيم: 'active' | 'inProgress' | 'completed'
  priority text default 'normal',      -- القيم: 'low' | 'normal' | 'high'
  is_pinned bool default false, due_day date, project_id uuid → projects,
  reminder_date timestamptz, completed_at timestamptz,
  created_at timestamptz, updated_at timestamptz, revision bigint default 1,
  deleted_at timestamptz)

Triggers:
- bump_revision على tasks و projects: قبل update → new.updated_at = now() و revision + 1.
- handle_new_user على auth.users: إنشاء profile تلقائي.

RLS مفعّل على الثلاثة — سياسات owner-only:
- profiles: auth.uid() = id
- projects: auth.uid() = owner_id (كل العمليات)
- tasks: auth.uid() = owner_id (كل العمليات)

═══════════════ 4) المطلوب منك بالظبط (بالترتيب) ═══════════════
1. افحص بالـ connector بتاعك: هل السكيما المنفذة مطابقة للمفروض فوق؟
   (الجداول الموجودة، الأعمدة وأنواعها، الـ RLS مفعّل وسياساته، الـ triggers)
2. اطبعلي تقرير فروقات واضح: موجود ✅ / ناقص ❌ / مختلف ⚠️.
3. اعرضلي: هل فيه بيانات؟ (عدد صفوف tasks/projects/profiles، وعينات من أول 3 صفوف لو موجودة).
4. لو المستخدم طلب منك إصلاح أو تعديل سكيما: اقترحه كـ SQL جاهز وانتظره يوافق — **ممنوع تنفيذ destructive أو تغيير سكيما من نفسك**.
5. لو المستخدم بيجرب مزامنة التطبيق وظهرت مشكلة: اسأله على الخطأ، وافحص الجداول تساعد في التشخيص (مثلاً: الصف اترفع؟ deleted_at اتملى؟).

═══════════════ 5) قواعد صارمة ═══════════════
- رد بالعربي.
- ممنوع: DROP على جداول/أعمدة، تعطيل RLS، حذف بيانات، أو تنفيذ SQL غير موافق عليه صراحة.
- لا تخترع أعمدة أو قيم مش في العقد فوق — العقود الثابتة في التطبيق: حالات 3، أولويات 3، UUID primary.
- المستخدم مش مبرمج backend — اشرح بساطة، والـ SQL الجاهز هو أفضل مخرج.
- لو سألك عن مفاتيح أو أسرار: التطبيق بيستخدم anon key محفوظ في جهازه — مش محتاج حاجة منك.
```

---

**ملاحظات أمنية سريعة قبل اللصق**:
- المتن ده **مفيهوش أي مفاتيح أو أسرار** — آمن للنسخ.
- الـ connector بتاع ChatGPT بيتصل بحساب Supabase بتاعك بصلاحياته — لو حسيت سلوك غريب، افصله من إعدادات الـ connector.
- لو عدلت السكيما يدوي بعدها: حدّث `docs/supabase/schema.sql` في المشروع هو المصدر.
