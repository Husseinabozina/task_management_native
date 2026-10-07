package com.husseinabozina.taskmanagement.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.husseinabozina.taskmanagement.R
import com.husseinabozina.taskmanagement.domain.ProjectItem
import kotlinx.coroutines.launch

@Composable
fun ProjectsScreen(snapshot: AppSnapshot, model: TaskAppViewModel, onNew: () -> Unit, onProject: (ProjectItem) -> Unit) {
    var deleteId by rememberSaveable { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    var error by rememberSaveable { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val target = snapshot.projects.firstOrNull { it.id.toString() == deleteId }
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(22.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { SectionHeading("مشاريعك", snapshot.projects.size) {
            TextButton(onClick = onNew) { Text("مشروع جديد") }
        } }
        if (error != null) item { Text(error!!, color = MaterialTheme.colorScheme.error) }
        if (snapshot.projects.isEmpty()) item {
            EmptyState("لا توجد مشاريع بعد", "أنشئ مشروعك الأول لتنظيم مهامك من زر «مشروع جديد» أعلاه.", R.drawable.icon_briefcase)
        }
        items(snapshot.projects, key = { it.id.toString() }) { project ->
            ProjectRow(project, snapshot, onOpen = { onProject(project) }, onDelete = { deleteId = project.id.toString() })
        }
    }
    if (target != null) AlertDialog(
        onDismissRequest = { if (!busy) deleteId = null },
        title = { Text("حذف مشروع «${target.name}»؟") },
        text = { Column {
            Text("ستبقى المهام محفوظة ضمن «بدون مشروع».")
            if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error)
        } },
        confirmButton = {
            TextButton(enabled = !busy, onClick = {
                if (busy) return@TextButton
                busy = true
                scope.launch {
                    try {
                        error = model.deleteProject(target.id)
                        if (error == null) deleteId = null
                    } finally { busy = false }
                }
            }) { Text(if (busy) "جارٍ الحذف…" else "حذف المشروع", color = MaterialTheme.colorScheme.error) }
        },
        dismissButton = { TextButton(enabled = !busy, onClick = { deleteId = null }) { Text("إلغاء") } }
    )
}
