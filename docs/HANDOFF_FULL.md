# HANDOFF — تسليم المشروع كاملًا لموديل آخر (2026-10-04)

> المستخدم طلب تسليمًا كاملًا: هذا الملف هو المصدر. اقرأه كله قبل أي تنفيذ.
> مشروع iOS كامل مكتوب + سحابة C1 كود + أندرويد في منتصف A1 ببناء فاشل (الإصلاح الدقيق موثق في §6).

---

## 1) هوية المشروع والمسارات

| البند | القيمة |
|---|---|
| المنتج | «مهامي» — تطبيق مهام عربي RTL، Native فقط |
| Repo (خاص) | Husseinabozina/task_management_native — main |
| المسار المحلي | /Volumes/Hussein/DevStorage/Projects/task_management_native (الهارد الخارجي؛ symlink من ~/.zcode/workspace/default/task_management_native) |
| iOS | ios/ — SwiftUI، iOS 17+، @Observable، SwiftData، XcodeGen (project.yml = المصدر، .xcodeproj مولّد) |
| أندرويد | android/ — Kotlin 2.2 + Compose + Room، minSdk 26، target 36 |
| Supabase | مشروع قائم فعلًا: ref nqrqvmvucfdtfmoaiqgp (eu-central-1)، URL: https://nqrqvmvucfdtfmoaiqgp.supabase.co — السكيما منفذة ومتحقق منها، RLS owner-only، الـ anon key في ios/TaskManagement/Resources/SupabaseConfig.plist (0600، gitignored) |
| أدوات | Xcode 26.2، JDK 24 (Temurin) + Gradle 8.14.3 (اشتغلوا معًا بنجاح)، SDK أندرويد: /Volumes/Hussein/DevStorage/Android/sdk، GRADLE_USER_HOME=/Volumes/Hussein/DevStorage/Gradle/user-home (الديسك الداخلي فيه 3GB فقط — لا تبنِ عليه) |
| الجهاز | macOS arm64، darwin 25.5.0 |

## 2) القواعد الثابتة (لا تخالفها)

1. **AGENTS.md** في جذر المشروع: 14 قاعدة ملزمة — أهمها: التحقق بلا ادعاء زائد، «حرفيًا» = استنساخ من المصدر لا من ملخص، التأجيل بلا مسجل = إسقاط صامت (R-GEN-009)، بوابة المقارنة الجانبية للشغل البصري.
2. **AI Reliability Playbook**: استنسخة في ~/.ai-reliability-playbook (symlink → الهارد الخارجي) — **أي تعديل عليه: commit + push فورًا** (سياسة Hussein).
3. **حدود التشغيل**: التحقق runtime (تشغيل التطبيق/السيميوليتر/الإموليتر) مسؤولية Hussein — البناء الآلي (xcodebuild/gradlew) مسموح. لا تحذف بيانات، لا force push، لا تنشر بدون تفويض.
4. **الاختبارات الآلية**: لا تضاف إلا بطلب صريح من Hussein.
5. **التوثيق أولًا**: أي ميزة جديدة = سطر في FEATURE_SCOPE/خطة قبل الكود. القرارات تُسجل في docs/architecture/DECISIONS.md (حاليًا D1–D25).

## 3) روابط التصميم (Figma — معتمدة حرفيًا D8)

- الملف: Task management & to-do list app (Community) — key: `oja3AAf5WtxELKlXH0v4dn`
- شاشة البداية «Let's Start»: https://www.figma.com/design/oja3AAf5WtxELKlXH0v4dn/Task-management---to-do-list-app--Community-?node-id=101-100
- الرئيسية: https://www.figma.com/design/oja3AAf5WtxELKlXH0v4dn/Task-management---to-do-list-app--Community-?node-id=101-125
- مهام اليوم: https://www.figma.com/design/oja3AAf5WtxELKlXH0v4dn/Task-management---to-do-list-app--Community-?node-id=101-265
- إضافة مشروع: https://www.figma.com/design/oja3AAf5WtxELKlXH0v4dn/Task-management---to-do-list-app--Community-?node-id=101-358
- الأصول المنزلة: assets/figma/ (16 أيقونة SVG + 7 صور PNG + أشكال SVG للزر المنحني والـ bottom bar). ملاحظة نقدية: **الملخص المنظم للفريم يكتب borderRadius=14 على الزر بينما حقيقته SVG path منحني** — لا تثق بالملخص في الأشكال، نزّل الـ path (حادثة I-2026-004).

## 4) ما اتعمل (منفذ ومبني — بترتيب الـ checkpoints)

### iOS (كلها في ios/TaskManagement)
- **C0-C1**: توثيق كامل (PRODUCT_BRIEF/FEATURE_SCOPE/USER_FLOWS/DATA_CONTRACTS/DECISIONS D1-D25/SCREEN_PLAN/DESIGN_SYSTEM/UI_DIRECTION/CLOUD_PLAN/C2_PLAN) + AGENTS.md بـ14 قاعدة + نسخة الدليل في docs/guide.
- **C2**: هيكل XcodeGen + توكنز كود (Theme/Typography/Metrics) + PrimaryButton **بشكل SVG منحني حرفي** (PrimaryButtonShape) + شاشة «يلا نبدأ» (فقاعات متدرجة من الفيجما).
- **C3**: Domain (TaskItem/TaskStatus 3 حالات/TaskPriority/TaskQuery بـ PriorityFilter/CalendarDay) + عقود TaskRepository/ProjectRepository + SwiftData (PersistedTask/Project/Tombstone) + LocalDataRepository (create/update/setCompleted/setPinned/delete + observe بالـ AsyncStream + قواعد التحقق والترتيب: pinned أولًا ثم dayBucket ثم priority ثم dueDay ثم id).
- **C4**: شاشة مهامي (شريط «الكل»+7 أيام، chips 4 حالات، **بحث فوري بالعنوان + فلتر أولوية Menu**، صفوف TaskRowView بـ pills من الفيجما + 📌، quick-add سطري) + BottomBar **بـ NotchedBarShape من SVG** و4 تابات بمواقع الفيجما الحرفية (44/111/265/331 @375 — RTL يعكس تلقائيًا، اكتب LTR الأصلية) + FAB.
- **C5**: الرئيسية كاملة (جرس بنقطة المتأخرات، كارت تقدم حقيقي بدونات، كارتان بارزتان، مهام النهارده، مشاريعك) + TaskDetailSheet (Markdown بـ AttributedString + metadata + تعديل/حذف بتأكيد) + إعادة جولة الترحيب من شاشة الحساب.
- **C6**: شاشة التقويم (شبكة 6 أسابيع تبدأ بأول يوم الجهاز + عدادات + ضغطة يوم → مهامي مفلترة).
- **C7**: المشاريع (قائمة/إنشاء بإيموجي ولون/حذف بتأكيد ينقل المهام).
- **C8**: تذكيرات — ReminderSync يراقب كل المهام ويوائمق إشعارات النظام (إتمام/حذف = إلغاء)، إذن لحظة التفعيل، الرفض = لا حفظ ولا ادعاء.
- **C9**: أيقونة تطبيق مولدة (1024 بنفسجي + صح) + زر + بحجم glyph الأصلي.

### السحابة C1 (Supabase)
- **مشروع قائم**: nqrqvmvucfdtfmoaiqgp — السكيما منفذة (profiles/projects/tasks + RLS owner-only + triggers revision + tombstones deleted_at) ومتحقق منها من قاعدة البيانات + تصليح صلاحيات (anon مرفوض، authenticated CRUD فقط) + security advisors نضيف (شغل Codex، commit b4ad5ac).
- **كود التطبيق**: AuthSession (دخول/حساب جديد برسائل عربية) + AccountSheet (من ☁️ في الرأس؛ بدون config تعرض خطوات الإعداد) + CloudSyncService (دفع/جلب full snapshot بـ LWW + tombstones + **نسخة احتياطية إلزامية قبل أول مزامنة** إلى Documents/Backups) + CloudBundle عبر environment.
- **schema.sql** في docs/supabase/ (المصدر — **لا تشغله تاني** على المشروع القائم).

### أندرويد
- **A0**: هيكل يبني APK (settings/root/app gradle + wrapper 8.14.3 من مشاريع Hussein + Manifest عربي + Theme بتوكنز + MainActivity stub صادق) — **assembleDebug ناجح**.
- **A1 قيد التنفيذ (مكتمل الكود — البناء فاشل بخطوة أخيرة واحدة)**: domain/Models.kt (نفس العقود: TaskItem/TaskStatus/TaskPriority/CalendarDay/TaskQuery/ProjectItem) + data/ (Entities + Daos + Converters + AppDatabase Room v1 + TombstoneEntity) + domain/RepositoryContracts.kt + data/LocalTaskRepository.kt (تنفيذ كامل بنفس دلالات iOS) — **كلها غير مضافة لـ git بعد** (WIP).

## 5) ما NOT done (الناقص بالظبط)

1. **iOS runtime validation**: Hussein لم يشغل التطبيق بعد — كل بنود ACCEPTANCE_CHECKLIST.md (أ/ب/ج/د/هـ/و/ز) معلقة. **هذا أول الأولويات**.
2. **C1 runtime**: أول مزامنة حقيقية لم تحدث (تذكر: أول مزامنة = نسخة احتياطية تلقائية؛ تحقق F4-F7 في الـ checklist).
3. **أندرويد A1 البناء**: فاشل بسبب خطأ واحدة دقيقة — انظر §6.
4. **أندرويد A2-A5**: واجهات Compose (مهامي/رئيسية/تقويم/مشاريع/تفاصيل بنفس تصميم iOS)، تذكيرات (BroadcastReceiver)، مزامنة Supabase (supabase-kt).
5. **C2** (خطة جاهزة في C2_PLAN.md): Apple Sign-In، outbox push تفاضلي، مزامنة تلقائية عند foreground، مؤشرات حالة، backoff، conflict_log — **لا تنفيذ قبل قبول C1**.
6. **C3** (الفريق): workspaces/دعوات/RLS membership — غير مصمم بالتفصيل بعد.
7. BACKLOG المتبقي: بروفايل/اسم مستخدم، board view، templates، tags، widgets.

## 6) ⚠️ الحالة اللحظية: بناء أندرويد A1 فاشل (الإصلاح الدقيق جاهز)

**الخطأ**: KSP يقول `no such column: deletedAt` في استعلامي `observeAll()` في Daos.kt — لأني كتبت `WHERE deletedAt IS NULL` بينما **TaskEntity مفيهوش عمود deletedAt أصلًا** (الحذف محليًا فيزيائي + tombstone في جدول منفصل — انظر LocalTaskRepository.deleteTask).

**الإصلاح الدقيق (سطر واحد × 2)**: في `android/app/src/main/java/com/husseinabozina/taskmanagement/data/Daos.kt` غيّر:
```kotlin
@Query("SELECT * FROM tasks WHERE deletedAt IS NULL")
```
إلى:
```kotlin
@Query("SELECT * FROM tasks")
```
ونفس الشيء لاستعلام projects. ثم: `export GRADLE_USER_HOME=/Volumes/Hussein/DevStorage/Gradle/user-home && export ANDROID_HOME=/Volumes/Hussein/DevStorage/Android/sdk && ./gradlew assembleDebug` من مجلد android/.

**بعد نجاح البناء**: اربط LocalTaskRepository بالـ MainActivity (استبدل الـ stub) أو أكمل A2 (واجهة مهامي بـ Compose).

## 7) سجل القرارات D1–D25 (الملخص)

D1 iOS أولًا ثم أندرويد تعاقبًا • D2 محلي أولًا بعقود جاهزة للسحابة • D3 إضافات Notion (إيموجي+لون للمشاريع، quick-add، markdown) • D4 لا Settings • D5 repo واحد للمسارين • D6 تحديث بالمراقبة • D7 حذف بتأكيد بلا Undo • D8 فيجما مرجعًا حرفيًا • D9 Lexend Deca + Cairo للعربي • D10/D17 تابات حقيقية فقط • D11 (ألغاه D20) • D12 حقول مشروع V1 • D13 iOS 17 + @Observable • D14 XcodeGen + DerivedData خارجي • D15 اسم «مهامي» • D16 SwiftData • D18 شاشة تقويم • D19 تفاصيل مهمة بـ Markdown • D20 حالة «شغالة عليها» • D21 تثبيت 📌 • D22 تذكيرات (إذن لحظة التفعيل + مزامنة إلغاء) • D23 Supabase • D24 إنشاء المشروع والسكيما (شغل Codex) • D25 بدء أندرويد موازيًا.

## 8) دروس ملزمة من الحوادث (التفاصيل في البلاي بوك)

- **I-2026-004 / R-UIF-001..009**: «حرفيًا» = نقل من المصدر (SVG path) لا من الملخص؛ الملخص قد يكون مضللًا؛ أي تقريب يُعلن؛ التحقق مقارنة عنصر-بعنصر؛ RTL: اكتب إحداثيات LTR الأصلية وسيب الانعكاس للنظام.
- **R-GEN-009**: التأجيل بلا مسجل = إسقاط صامت — قارن الخطة بالمنفذ عند كل إغلاق (البحث والأولوية سقطوا هكذا واكتشفهم Hussein).
- **السياسة**: تعديل البلاي بوك = push فورًا.

## 9) المستندات المرجعية (كلها في docs/)

product/(BRIEF/SCOPE/FLOWS) • design/(SCREEN_PLAN/DESIGN_SYSTEM/UI_DIRECTION) • architecture/(ARCHITECTURE/DATA_CONTRACTS/DECISIONS/CLOUD_PLAN/C2_PLAN) • project/(CURRENT_STATE/BACKLOG/ACCEPTANCE_CHECKLIST) • supabase/(schema.sql/SETUP.md/CHATGPT_HANDOFF.md) • guide/(دليل التنفيذ الكامل).

## 10) المعلق على Hussein (مستحيل بغيره)

1. تجربة iOS وفق ACCEPTANCE_CHECKLIST (أ–ز) — تشغيل أول مرة يختبر migrations السمات أيضًا.
2. أول مزامنة سحابية حقيقية (F1–F7).
3. قرار اعتماد C2_PLAN بعد قبول C1، ومصير C3/أندرويد أولوية.

## 11) أخطاء شائعة تجنبها (ضربت فيها أنا)

1. تعديل ملفات عبر python heredoc داخل bash: escaping الـ $ يفشل بصمت — **تحقق دائمًا أن التعديل طبق** (grep بعد الكتابة).
2. #Predicate في SwiftData لا يلتقط متغيرات الـ loop مباشرة — انسخها لثابت محلي أولًا.
3. تكرار @Entity annotation في Room = خطأ؛ وأسماء الأعمدة = أسماء الـ properties (camelCase) ما لم تحدد @ColumnInfo.
4. حجب بناء xcodebuild والبناء الآلي معًا = build.db locked — ابنِ في derivedDataPath معزول أو انتظر.
5. AsyncStream مع bufferingPolicy في Swift الجديد: `.bufferingNewest(1)` (بقيم).
6. FlatMap مع failable init مرجعيًا (`flatMap(CalendarDay.init(date:))`) لا يصرَّف — استخدم closure صريح.
