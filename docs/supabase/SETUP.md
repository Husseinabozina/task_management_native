# SETUP — السحابة جاهزة للتجربة

تم إنشاء مشروع `task_management_native` في `Husseinabozina's Org` بتاريخ 2026-10-04، بمنطقة `eu-central-1`.

- المشروع: https://supabase.com/dashboard/project/nqrqvmvucfdtfmoaiqgp
- API: https://nqrqvmvucfdtfmoaiqgp.supabase.co
- السكيما طبقت وفحصت: profiles / projects / tasks، العلاقات، RLS owner-only، triggers.
- ملف SupabaseConfig.plist الحقيقي محفوظ محليًا داخل موارد التطبيق، gitignored، ومربوط بـ Resources في Xcode. لا تنسخ المفتاح إلى التوثيق.
- الجداول كلها فارغة قبل التسجيل وأول مزامنة.

## التجربة الآن

1. افتح `ios/TaskManagement.xcodeproj` في Xcode وشغل ⌘R.
2. افتح ☁️ بجوار الجرس → «حساب جديد» بالإيميل وكلمة السر.
3. فعّل الإيميل من رسالة التأكيد، ثم سجّل دخول. تأكيد الإيميل مفعّل في Supabase.
4. اضغط «مزامنة الآن»؛ النسخة الاحتياطية المحلية جزء من مسار أول مزامنة.
5. راجع tasks في Table Editor؛ عدّل مهمة ثم زامن؛ احذف مهمة ثم زامن وتحقق من deleted_at.

لم يشغّل المساعد التطبيق أو ينشئ حساب اختبار؛ المزامنة من iOS ما زالت غير متحققة runtime.

## عند نسخ المشروع لجهاز آخر

ملف الاتصال الحقيقي غير موجود في git. انسخه محليًا أو أنشئه من ملف المثال، ثم أعد توليد المشروع بـ XcodeGen ليضاف إلى Resources. `schema.sql` مخصص للتهيئة الأولى على مشروع جديد؛ لا تعِد تشغيله على هذا المشروع لأن السياسات والـtriggers موجودة بالفعل.
