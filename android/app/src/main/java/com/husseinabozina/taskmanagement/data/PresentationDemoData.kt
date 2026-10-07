package com.husseinabozina.taskmanagement.data

import androidx.room.withTransaction
import java.nio.charset.StandardCharsets
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

/** Explicit, debug-only presentation import. Never upserts existing rows or resurrects deleted ones. */
object PresentationDemoData {
    data class ImportResult(val projectsAdded: Int, val tasksAdded: Int)
    private data class DemoProject(val key: String, val name: String, val emoji: String, val color: String)
    private data class DemoTask(
        val key: String, val title: String, val project: String, val dayOffset: Long?,
        val status: String = "active", val priority: String = "normal", val pinned: Boolean = false,
        val details: String
    )
    private fun id(key: String): UUID = UUID.nameUUIDFromBytes(
        "mahami.presentation.v1.$key".toByteArray(StandardCharsets.UTF_8)
    )

    suspend fun insertMissing(database: AppDatabase): ImportResult = database.withTransaction {
        val projects = listOf(
            DemoProject("launch", "إطلاق تطبيق مهامي", "🚀", "purple"),
            DemoProject("content", "خطة المحتوى", "✏️", "pink"),
            DemoProject("website", "تطوير الموقع", "💼", "blue"),
            DemoProject("learning", "التعلّم والتطوير", "📚", "orange")
        )
        val tasks = listOf(
            DemoTask("brand", "اعتماد الهوية البصرية", "launch", 0, "completed", details =
                "**الهدف:** توحيد هوية التطبيق.\n- اعتماد الألوان البنفسجية\n- مراجعة الأيقونات والخطوط\n- تجهيز ملفات العرض"),
            DemoTask("experience", "مراجعة تجربة الاستخدام", "launch", 0, "inProgress", "high", true,
                "مراجعة الرحلة من إنشاء المهمة إلى إتمامها، مع التركيز على *وضوح النصوص* وسهولة التنقّل."),
            DemoTask("presentation", "تجهيز العرض التقديمي", "launch", 0, priority = "high", details =
                "- اختيار لقطات الرئيسية والتقويم\n- تسجيل فيديو قصير لرحلة إضافة مهمة\n- ترتيب شرائح العرض"),
            DemoTask("release", "مراجعة الإصدار النهائي", "launch", 1, details =
                "مراجعة قائمة التسليم وتجهيز النسخة المحلية للعرض."),
            DemoTask("ideas", "تحديد أفكار المحتوى", "content", -1, "completed", "low", details =
                "إعداد ثلاث أفكار: تنظيم اليوم، متابعة المشاريع، والاحتفال بالإنجاز."),
            DemoTask("post", "كتابة منشور الإطلاق", "content", 0, "inProgress", "normal", true,
                "**الفكرة:** يوم أكثر تنظيمًا.\n- تقديم التطبيق بإيجاز\n- توضيح قيمة قائمة المهام\n- إضافة دعوة لتجربة التطبيق"),
            DemoTask("screens", "تصميم صور العرض", "content", 0, priority = "high", details =
                "تجهيز صور توضح الواجهة العربية، مع مراعاة الهوامش وجودة العرض."),
            DemoTask("schedule", "جدولة منشورات الأسبوع", "content", 2, priority = "low", details =
                "توزيع المحتوى على أيام الأسبوع وربط كل منشور بهدف واضح."),
            DemoTask("homepage", "تحسين الصفحة الرئيسية", "website", 0, "completed", details =
                "تبسيط العنوان الرئيسي وتحسين ترتيب الأقسام."),
            DemoTask("mobile", "مراجعة العرض على الهاتف", "website", 1, priority = "high", details =
                "مراجعة القراءة والمسافات وأزرار التنقّل على شاشة الهاتف."),
            DemoTask("portfolio", "تحديث صفحة المشاريع", "website", 3, "inProgress", details =
                "إضافة صور المشروع ووصف موجز يوضح المشكلة والحل."),
            DemoTask("arabic", "تدقيق النصوص العربية", "website", -1, details =
                "توحيد المصطلحات وصياغة الرسائل بلغة فصحى بسيطة."),
            DemoTask("reading", "قراءة فصل عن إدارة الوقت", "learning", -2, "completed", "low", details =
                "تدوين أبرز الأفكار وكيفية تطبيقها على خطة الأسبوع."),
            DemoTask("focus", "تطبيق تمرين التركيز", "learning", 0, "completed", details =
                "تخصيص جلسة تركيز واحدة لمهمة واضحة، ثم مراجعة النتيجة."),
            DemoTask("notes", "تلخيص ملاحظات الأسبوع", "learning", 4, priority = "low", details =
                "جمع الملاحظات في قائمة قصيرة من الخطوات العملية."),
            DemoTask("resources", "تنظيم مصادر التعلّم", "learning", null, details =
                "ترتيب الكتب والمقالات حسب الموضوع والرجوع إليها عند الحاجة.")
        )
        val taskDao = database.taskDao()
        val projectDao = database.projectDao()
        val deleted = database.tombstoneDao().all().map { it.key }.toSet()
        val today = LocalDate.now()
        val now = Instant.now()
        var projectsAdded = 0
        var tasksAdded = 0
        for (project in projects) {
            val projectId = id("project.${project.key}")
            if ("project:$projectId" !in deleted && projectDao.byId(projectId) == null) {
                projectDao.upsert(ProjectEntity(projectId, project.name, project.emoji, project.color, now, now))
                projectsAdded++
            }
        }
        for (task in tasks) {
            val taskId = id("task.${task.key}")
            if ("task:$taskId" in deleted || taskDao.byId(taskId) != null) continue
            val targetProject = id("project.${task.project}").takeIf { projectDao.byId(it) != null }
            taskDao.upsert(TaskEntity(
                id = taskId, title = task.title, details = task.details, statusRaw = task.status,
                priorityRaw = task.priority, isPinned = task.pinned,
                dueDay = task.dayOffset?.let(today::plusDays), projectId = targetProject,
                reminderDate = null, createdAt = now, updatedAt = now,
                completedAt = if (task.status == "completed") now else null
            ))
            tasksAdded++
        }
        ImportResult(projectsAdded, tasksAdded)
    }
}
