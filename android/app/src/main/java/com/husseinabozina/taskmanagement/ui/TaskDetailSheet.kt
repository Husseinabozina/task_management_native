package com.husseinabozina.taskmanagement.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.*
import androidx.compose.ui.text.*
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import com.husseinabozina.taskmanagement.domain.*
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaskDetailSheet(task: TaskItem, project: ProjectItem?, today: LocalDate, model: TaskAppViewModel,
    onDismiss: () -> Unit, onEdit: () -> Unit) {
    var confirm by rememberSaveable { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var error by rememberSaveable { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true, confirmValueChange = { !busy })
    ModalBottomSheet(onDismissRequest = { if (!busy) onDismiss() }, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.background) {
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = 22.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)) {
            SectionHeading("تفاصيل المهمة") {
                TextButton(enabled = !busy, onClick = onDismiss) { Text("إغلاق") }
            }
            Text(task.title, fontSize = 24.sp, lineHeight = 34.sp, fontWeight = FontWeight.SemiBold)
            if (project != null) Text("${project.emoji ?: "📁"} ${project.name}", color = MaterialTheme.colorScheme.secondary)
            if (task.isPinned) Text("📌 مثبتة", color = MaterialTheme.colorScheme.primary, fontSize = 14.sp)
            ChoiceChip(task.status.label(), selected = true, enabled = !busy) { model.toggle(task) }
            if (!task.details.isNullOrBlank()) {
                AppCard {
                    Text("الوصف", fontSize = 11.sp, color = MaterialTheme.colorScheme.secondary)
                    Spacer(Modifier.height(8.dp))
                    Text(markdown(task.details), fontSize = 14.sp, lineHeight = 25.sp)
                }
            }
            AppCard {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    MetaRow("الأولوية", task.priority.label())
                    task.dueDay?.date?.let { MetaRow("الموعد", if (it == today) "اليوم" else dateLabel(it)) }
                    MetaRow("الحالة", task.status.label())
                    task.reminderDate?.let {
                        val reminderFormatter = DateTimeFormatter.ofPattern("d MMM yyyy، h:mm a", Arabic)
                            .withZone(ZoneId.systemDefault())
                        MetaRow("التذكير", reminderFormatter.format(it))
                    }
                    val formatter = DateTimeFormatter.ofPattern("d MMM yyyy", Arabic).withZone(ZoneId.systemDefault())
                    MetaRow("أُنشئت", formatter.format(task.createdAt))
                    MetaRow("آخر تحديث", formatter.format(task.updatedAt))
                    task.completedAt?.let { MetaRow("أُنجزت", formatter.format(it)) }
                }
            }
            if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error)
            PrimaryAction("تعديل المهمة", !busy, onEdit)
            TextButton(enabled = !busy, onClick = { confirm = true }, modifier = Modifier.fillMaxWidth()) {
                Text("حذف المهمة", color = MaterialTheme.colorScheme.error)
            }
            Spacer(Modifier.height(24.dp))
        }
    }
    if (confirm) AlertDialog(onDismissRequest = { if (!busy) confirm = false },
        title = { Text("هل تريد حذف المهمة؟") },
        text = { Column {
            Text("«${task.title}» ستُحذف نهائيًا.")
            if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error)
        } },
        confirmButton = {
            TextButton(enabled = !busy, onClick = {
                if (busy) return@TextButton
                busy = true
                scope.launch {
                    try {
                        error = model.deleteTask(task.id)
                        if (error == null) { confirm = false; onDismiss() }
                    } finally { busy = false }
                }
            }) { Text(if (busy) "جارٍ الحذف…" else "حذف نهائي", color = MaterialTheme.colorScheme.error) }
        }, dismissButton = { TextButton(enabled = !busy, onClick = { confirm = false }) { Text("إلغاء") } }
    )
}

@Composable
private fun MetaRow(label: String, value: String) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(label, Modifier.weight(1f), fontSize = 12.sp, color = MaterialTheme.colorScheme.secondary)
        Text(value, fontSize = 12.sp)
    }
}

/** Minimal inline Markdown: bold, italic, code and bullet lines; raw text stays stored unchanged. */
private fun markdown(source: String): AnnotatedString = buildAnnotatedString {
    val tokens = Regex("\\*\\*(.+?)\\*\\*|`([^`]+)`|\\*([^*]+)\\*|_([^_]+)_")
    source.lines().forEachIndexed { lineIndex, raw ->
        if (lineIndex > 0) append("\n")
        val line = if (raw.startsWith("- ") || raw.startsWith("* ")) "• " + raw.drop(2) else raw
        var cursor = 0
        tokens.findAll(line).forEach { match ->
            append(line.substring(cursor, match.range.first))
            val groups = match.groupValues
            val text = groups.drop(1).first { it.isNotEmpty() }
            val style = when {
                groups[1].isNotEmpty() -> SpanStyle(fontWeight = FontWeight.SemiBold)
                groups[2].isNotEmpty() -> SpanStyle(fontFamily = FontFamily.Monospace)
                else -> SpanStyle(fontStyle = FontStyle.Italic)
            }
            withStyle(style) { append(text) }
            cursor = match.range.last + 1
        }
        append(line.substring(cursor))
    }
}
