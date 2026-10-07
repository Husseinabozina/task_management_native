package com.husseinabozina.taskmanagement.domain

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

/**
 * حالة المهمة — ثلاث حالات (عقد D20، نفس iOS).
 * القيم النصية مطابقة للتخزين iOS والسحابة: 'active' | 'inProgress' | 'completed'.
 */
enum class TaskStatus(val raw: String) {
    ACTIVE("active"),
    IN_PROGRESS("inProgress"),
    COMPLETED("completed");

    companion object {
        fun from(raw: String?): TaskStatus =
            entries.firstOrNull { it.raw == raw } ?: ACTIVE
    }
}

/** الأولوية — تُخزن كقيمة لا كنص واجهة مترجم. */
enum class TaskPriority(val raw: String) {
    LOW("low"),
    NORMAL("normal"),
    HIGH("high");

    val sortRank: Int
        get() = when (this) {
            HIGH -> 0
            NORMAL -> 1
            LOW -> 2
        }

    companion object {
        fun from(raw: String?): TaskPriority =
            entries.firstOrNull { it.raw == raw } ?: NORMAL
    }
}

/** يوم تقويمي بلا ساعة — تطبيع على بداية اليوم وفق تقويم الجهاز (العقد). */
data class CalendarDay(val date: LocalDate) : Comparable<CalendarDay> {

    override fun compareTo(other: CalendarDay): Int = date.compareTo(other.date)

    fun relationTo(other: CalendarDay): DayRelation = when {
        date < other.date -> DayRelation.PAST
        date > other.date -> DayRelation.FUTURE
        else -> DayRelation.SAME_DAY
    }

    companion object {
        fun today(zone: ZoneId = ZoneId.systemDefault()): CalendarDay =
            CalendarDay(LocalDate.now(zone))
    }
}

enum class DayRelation { PAST, SAME_DAY, FUTURE }

/** تصنيف اليوم وفق العقد — قاعدة واحدة في مكان واحد. */
enum class TaskDayBucket { OVERDUE, TODAY, UPCOMING, NO_DUE_DATE, COMPLETED }

/** مهمة المنتج — كيان دومين مستقل عن التخزين والواجهة (العقد). */
data class TaskItem(
    val id: UUID,
    val title: String,
    /** وصف المهمة (حقل description في العقد). */
    val details: String?,
    val status: TaskStatus,
    val priority: TaskPriority,
    /** مثبتة في أعلى القوائم (قرار D21). */
    val isPinned: Boolean,
    val dueDay: CalendarDay?,
    val projectId: UUID?,
    /** موعد التذكير الكامل (تاريخ + ساعة) — null = بدون تذكير (قرار D22). */
    val reminderDate: Instant?,
    val createdAt: Instant,
    val updatedAt: Instant,
    val completedAt: Instant?
) {
    fun dayBucket(today: CalendarDay): TaskDayBucket {
        if (status == TaskStatus.COMPLETED) return TaskDayBucket.COMPLETED
        val due = dueDay ?: return TaskDayBucket.NO_DUE_DATE
        return when (due.relationTo(today)) {
            DayRelation.PAST -> TaskDayBucket.OVERDUE
            DayRelation.SAME_DAY -> TaskDayBucket.TODAY
            DayRelation.FUTURE -> TaskDayBucket.UPCOMING
        }
    }
}

/** مدخل إنشاء مهمة — العنوان مطلوب بعد trim ويُتحقق منه في المخزن. */
data class NewTask(
    val title: String,
    val details: String? = null,
    val priority: TaskPriority = TaskPriority.NORMAL,
    val dueDay: CalendarDay? = null,
    val projectId: UUID? = null,
    val status: TaskStatus = TaskStatus.ACTIVE,
    val isPinned: Boolean = false,
    val reminderDate: Instant? = null
)

/** مشروع المنتج — هوية بالإيموجي واللون (قرار D3). */
data class ProjectItem(
    val id: UUID,
    val name: String,
    val emoji: String?,
    val colorKey: String?,
    val createdAt: Instant,
    val updatedAt: Instant
)

data class NewProject(
    val name: String,
    val emoji: String? = null,
    val colorKey: String? = null
)

/** فلتر اليوم — «الكل» يجمع المتأخرة/اليوم/القادمة/بلا موعد؛ DAY يحدد يومًا في queryDay. */
enum class DayFilter { ALL, DAY }

/** فلتر الحالة — «مفتوحة» لم تبدأ بعد (ليست شغالة عليها وليست مكتملة). */
enum class StatusFilter { ANY, ACTIVE, IN_PROGRESS, COMPLETED }

/** فلتر الأولوية. */
enum class PriorityFilter { ANY, LOW, NORMAL, HIGH }

/** فلتر القائمة — مطابق لعقد observeTasks (يوم + حالة + أولوية + مشروع اختياري). */
data class TaskQuery(
    val day: DayFilter = DayFilter.ALL,
    val queryDay: CalendarDay? = null,
    val status: StatusFilter = StatusFilter.ANY,
    val priority: PriorityFilter = PriorityFilter.ANY,
    val projectId: UUID? = null
)
