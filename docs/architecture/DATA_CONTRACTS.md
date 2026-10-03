# DATA_CONTRACTS — عقد بيانات المهمة

عقد مستقل عن اللغة والمنصة. أي تغيير هنا يُراجع أثره على iOS وAndroid معًا قبل التنفيذ.

## TaskItem

| الحقل | المعنى والقاعدة |
|---|---|
| `id` | هوية ثابتة UUID؛ لا يُستخدم مكان العنصر في القائمة كهوية |
| `title` | مطلوب بعد trim؛ حد أقصى 200 حرف |
| `description` | اختياري؛ حد أقصى 5,000 حرف؛ محتوى markdown-lite يُعرض منسقًا ويُخزن نصًا خامًا. (في Swift اسمه `details` لتجنب تعارض تسمية `NSObject.description` في نماذج التخزين) |
| `status` | `active` \| `completed` — لا حالات وسيطة في V1 |
| `priority` | `low` \| `normal` \| `high` — افتراضي `normal`؛ تُخزن القيمة لا نص الواجهة المترجم |
| `dueDate` | تاريخ تقويمي اختياري (يوم بلا ساعة)؛ يُحفظ كتاريخ محلي، لا يُحول لمنتصف الليل UTC |
| `projectId` | اختياري؛ رابط ثابت لمشروع قائم |
| `createdAt` / `updatedAt` | وقت إنشاء/تحديث مع timezone؛ المسؤول عنهما المخزن |
| `completedAt` | يُضبط عند الإتمام ويُلغى عند إعادة الفتح، في نفس عملية تغيير الحالة |

ملاحظات: `ownerId`/`workspaceId`/`revision` لا تُضاف الآن — تُضاف عند checkpoint السحابة مع migration يحفظ بيانات المستخدم (قرار D2). `archivedAt` غير موجود لأن الأرشفة خارج نطاق V1.

## Project

| الحقل | المعنى والقاعدة |
|---|---|
| `id` | UUID ثابت |
| `name` | مطلوب بعد trim؛ حد 80 حرفًا |
| `emoji` | إيموجي واحد اختياري |
| `color` | قيمة من لوحة ثابتة (8 ألوان) أو بدون لون |
| `createdAt` | وقت الإنشاء |

حذف المشروع: عملية صريحة بتأكيد؛ المهام المرتبطة تنتقل إلى «بدون مشروع» (projectId → null) ولا تُحذف.

## قواعد التاريخ والتصنيف (مكان واحد فقط في الكود)

- **Today**: نشطة وdueDate = يوم اليوم وفق تقويم الجهاز.
- **Overdue**: نشطة وdueDate قبل يوم اليوم. المكتملة لا تصير متأخرة أبدًا.
- **Upcoming**: نشطة وdueDate بعد يوم اليوم (بلا حد زمني في V1).
- **بلا موعد**: تظهر في All فقط، ولا تدخل Today/Overdue/Upcoming.
- **ترتيب القائمة**: overdue أولًا ثم اليوم ثم القادم ثم بلا موعد؛ داخل كل مجموعة: high → normal → low، ثم الأقدم dueDate أولًا، ثم المعرف كسر التعادل. المكتملة تظهر آخر القائمة في «الكل» بترتيب completedAt داخل مجموعة أخيرة (إضافة موثقة 2026-10-02).

## عمليات Repository (عقد V1)

```text
observeTasks(view, filter) -> stream تحديثات القائمة   (المصدر الوحيد لتحديث الواجهة)
observeProjects()          -> stream قائمة المشاريع
create(input)              -> TaskItem محفوظة أو failure معلوم
update(id, changes)        -> TaskItem محفوظة أو failure
setCompleted(id, Bool)     -> TaskItem محفوظة أو failure (completedAt يتغير معها في نفس العملية)
deleteTask(id)             -> نجاح أو failure (بعد تأكيد الواجهة)
createProject / updateProject / deleteProject
```

معاملات `observeTasks` (مطابقة لواجهة الفيجما):

```text
day:   all | specific calendar date     («الكل» يجمع متأخرة/اليوم/قادمة/بلا موعد بعناوينها)
status: any | active | completed
projectId: اختياري لقائمة مشروع محدد
```

- العقد يعيد domain entities وfailures فقط — لا صفوف قاعدة بيانات ولا JSON في الواجهة.
- تحديث القائمة بالمراقبة (observation) بدل دمج refresh يدوي معه؛ لا تكرار للنهجين بطريقة تنتج صفوفًا مكررة.
- الأزرار لا تقبل double submit أثناء الحفظ؛ فشل الكتابة لا يتحول إلى نجاح UI.
- فشل قراءة عام لا يمسح البيانات أبدًا.
