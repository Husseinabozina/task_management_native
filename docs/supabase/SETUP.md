# SETUP — تشغيل السحابة (C1) في 5 دقائق

1. **اعمل مشروع**: supabase.com ← New project (بلان مجاني، احفظ كلمة سر قاعدة البيانات).
2. **شغّل السكيما**: من Project ← SQL Editor ← الصق محتوى `docs/supabase/schema.sql` ← Run. المفروض يقول Success.
3. **خذ الإعدادات**: Project Settings ← API: انسخ **Project URL** و **anon public key**.
4. **جهّز التطبيق**: انسخ `ios/TaskManagement/Resources/SupabaseConfig.example.plist` في نفس المجلد وسمّه **SupabaseConfig.plist** (بمن غير example) واملأ القيمتين. (الملف ده gitignored — مش بيترفع).
5. **شغّل** ⌘R ← افتح الرئيسية ← أيقونة ☁️ جنب الجرس ← «حساب جديد» بالإيميل → بعدها «مزامنة الآن».

## التحقق (معايير قبول C1)
- أول مزامنة تعمل نسخة احتياطية تلقائية في مجلد Documents/Backups.
- مهامك المحلية تظهر في Supabase ← Table Editor ← tasks.
- غيّر مهمة واعمل مزامنة ← تتغير في Table Editor.
- امسح مهمة واعمل مزامنة ← `deleted_at` بيتعبى (tombstone).
- (اختياري) جهاز/سيميوليتر تاني بنفس الحساب ← نفس المهام بعد مزامنة.

## ملاحظات
- لو ظهرت «السحابة مش مضبوطة» → ملف الـ plist ناقص أو اسمه غلط أو محتاج ⌘R بعد إضافته.
- الإيميل بتأكيد: Supabase بيبعت رسالة تأكيد عند التسجيل (أو اقفل التأكيد من Auth ← Providers ← Email).
