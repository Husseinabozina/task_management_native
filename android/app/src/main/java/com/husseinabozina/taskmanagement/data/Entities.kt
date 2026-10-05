package com.husseinabozina.taskmanagement.data

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

/** نماذج التخزين — طبقة data فقط، لا تسرّب للواجهة (العقد المشترك). */
@Entity(tableName = "tasks", indices = [Index("updatedAt")])
data class TaskEntity(
    @PrimaryKey val id: UUID,
    val title: String,
    val details: String?,
    val statusRaw: String,
    val priorityRaw: String,
    val isPinned: Boolean,
    /** بداية اليوم المحلي — يوم تقويمي بلا ساعة. */
    val dueDay: LocalDate?,
    val projectId: UUID?,
    val reminderDate: Instant?,
    val createdAt: Instant,
    val updatedAt: Instant,
    val completedAt: Instant?
)

@Entity(tableName = "projects", indices = [Index("updatedAt")])
data class ProjectEntity(
    @PrimaryKey val id: UUID,
    val name: String,
    val emoji: String?,
    val colorKey: String?,
    val createdAt: Instant,
    val updatedAt: Instant
)

/** آثار الحذف المحلية — key = kind:uuid لتفادي التكرار. */
@Entity(tableName = "tombstones")
data class TombstoneEntity(
    @PrimaryKey val key: String,
    val kind: String,
    val rowId: UUID,
    val deletedAt: Instant
)
