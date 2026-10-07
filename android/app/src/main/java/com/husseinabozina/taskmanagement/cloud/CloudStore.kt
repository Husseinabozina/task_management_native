package com.husseinabozina.taskmanagement.cloud

import androidx.room.withTransaction
import com.husseinabozina.taskmanagement.data.*
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

/** Wire serialization and atomic Room merge live at the data boundary. */
class CloudStore(private val database: AppDatabase) {
    suspend fun export(): JSONObject = database.withTransaction {
        val projects = JSONArray()
        database.projectDao().all().forEach { row -> projects.put(JSONObject()
            .put("id", row.id).put("name", row.name).putNullable("emoji", row.emoji)
            .putNullable("color_key", row.colorKey).put("created_at", row.createdAt).put("updated_at", row.updatedAt)) }
        val tasks = JSONArray()
        database.taskDao().all().forEach { row -> tasks.put(JSONObject()
            .put("id", row.id).put("title", row.title).putNullable("details", row.details)
            .put("status", row.statusRaw).put("priority", row.priorityRaw).put("is_pinned", row.isPinned)
            .putNullable("due_day", row.dueDay).putNullable("project_id", row.projectId)
            .putNullable("reminder_date", row.reminderDate).putNullable("completed_at", row.completedAt)
            .put("created_at", row.createdAt).put("updated_at", row.updatedAt)) }
        val deletedProjects = JSONArray()
        val deletedTasks = JSONArray()
        database.tombstoneDao().all().forEach { row ->
            val target = if (row.kind == "project") deletedProjects else deletedTasks
            target.put(JSONObject().put("id", row.rowId).put("deleted_at", row.deletedAt))
        }
        JSONObject().put("p_projects", projects).put("p_tasks", tasks)
            .put("p_deleted_projects", deletedProjects).put("p_deleted_tasks", deletedTasks)
    }

    suspend fun apply(response: JSONObject, ownerId: String) = database.withTransaction {
        val projects = response.getJSONArray("projects")
        val tasks = response.getJSONArray("tasks")
        val tombstones = database.tombstoneDao().all().associateBy { it.key }
        val projectDao = database.projectDao()
        val taskDao = database.taskDao()
        val tombstoneDao = database.tombstoneDao()

        for (index in 0 until projects.length()) {
            val row = projects.getJSONObject(index)
            require(row.getString("owner_id") == ownerId)
            val id = UUID.fromString(row.getString("id"))
            val updated = row.instant("updated_at")
            val pending = tombstones["project:$id"]
            val deleted = row.optionalInstant("deleted_at")
            val current = projectDao.byId(id)
            if (pending != null && (pending.deletedAt > updated || (deleted == null && pending.deletedAt == updated))) continue
            if (current == null || current.updatedAt <= updated) {
                if (deleted != null) {
                    taskDao.detachCloudProject(id, updated)
                    projectDao.deleteById(id)
                } else {
                    projectDao.upsert(ProjectEntity(id, row.getString("name"), row.optionalString("emoji"),
                        row.optionalString("color_key"), row.instant("created_at"), updated))
                }
            }
            if (pending != null && updated >= pending.deletedAt) tombstoneDao.acknowledge(pending.key, pending.deletedAt)
        }
        for (index in 0 until tasks.length()) {
            val row = tasks.getJSONObject(index)
            require(row.getString("owner_id") == ownerId)
            val id = UUID.fromString(row.getString("id"))
            val updated = row.instant("updated_at")
            val pending = tombstones["task:$id"]
            val deleted = row.optionalInstant("deleted_at")
            val current = taskDao.byId(id)
            if (pending != null && (pending.deletedAt > updated || (deleted == null && pending.deletedAt == updated))) continue
            if (current == null || current.updatedAt <= updated) {
                if (deleted != null) taskDao.deleteById(id)
                else {
                    val project = row.optionalString("project_id")?.let(UUID::fromString)
                        ?.takeIf { projectDao.byId(it) != null }
                    taskDao.upsert(TaskEntity(id, row.getString("title"), row.optionalString("details"),
                        row.getString("status"), row.getString("priority"), row.getBoolean("is_pinned"),
                        row.optionalString("due_day")?.let(LocalDate::parse), project,
                        row.optionalInstant("reminder_date"), row.instant("created_at"), updated,
                        row.optionalInstant("completed_at")))
                }
            }
            if (pending != null && updated >= pending.deletedAt) tombstoneDao.acknowledge(pending.key, pending.deletedAt)
        }
    }

    private fun JSONObject.putNullable(key: String, value: Any?): JSONObject = put(key, value ?: JSONObject.NULL)
    private fun JSONObject.optionalString(key: String): String? = if (isNull(key)) null else getString(key)
    private fun JSONObject.instant(key: String): Instant = Instant.parse(getString(key))
    private fun JSONObject.optionalInstant(key: String): Instant? = optionalString(key)?.let(Instant::parse)
}
