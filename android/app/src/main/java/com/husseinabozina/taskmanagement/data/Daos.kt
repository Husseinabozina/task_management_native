package com.husseinabozina.taskmanagement.data

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import kotlinx.coroutines.flow.Flow
import java.util.UUID

/** عقود الوصول المحلي — مرآة لعقد Repository في iOS (العقد المشترك). */
@Dao
interface TaskDao {
    @Upsert
    suspend fun upsert(entity: TaskEntity)

    @Upsert
    suspend fun upsertAll(entities: List<TaskEntity>)

    @Query("SELECT * FROM tasks WHERE deletedAt IS NULL")
    fun observeAll(): Flow<List<TaskEntity>>

    @Query("SELECT * FROM tasks WHERE id = :id")
    suspend fun byId(id: UUID): TaskEntity?

    @Query("DELETE FROM tasks WHERE id = :id")
    suspend fun deleteById(id: UUID)
}

@Dao
interface ProjectDao {
    @Upsert
    suspend fun upsert(entity: ProjectEntity)

    @Upsert
    suspend fun upsertAll(entities: List<ProjectEntity>)

    @Query("SELECT * FROM projects WHERE deletedAt IS NULL ORDER BY created_at")
    fun observeAll(): Flow<List<ProjectEntity>>

    @Query("SELECT * FROM projects WHERE id = :id")
    suspend fun byId(id: UUID): ProjectEntity?

    @Query("DELETE FROM projects WHERE id = :id")
    suspend fun deleteById(id: UUID)
}

/** آثار الحذف المحلية — تُدفع للسحابة بعد نجاح المزامنة ثم تُمسح (خطة C1). */
@Dao
interface TombstoneDao {
    @Upsert
    suspend fun upsert(entity: TombstoneEntity)

    @Query("SELECT * FROM tombstones")
    suspend fun all(): List<TombstoneEntity>

    @Query("DELETE FROM tombstones WHERE key IN (:keys)")
    suspend fun deleteByKeys(keys: List<String>)
}
