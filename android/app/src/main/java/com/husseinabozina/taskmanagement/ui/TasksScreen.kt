package com.husseinabozina.taskmanagement.ui

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.*
import com.husseinabozina.taskmanagement.R
import com.husseinabozina.taskmanagement.domain.*
import com.husseinabozina.taskmanagement.ui.theme.Lexend
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID
import kotlinx.coroutines.launch

@Composable
fun TasksScreen(snapshot: AppSnapshot, model: TaskAppViewModel, initialDay: LocalDate?, projectId: UUID?,
    onBack: (() -> Unit)?, onTask: (TaskItem) -> Unit) {
    var selectedDay by rememberSaveable { mutableStateOf(initialDay?.toString()) }
    var status by rememberSaveable { mutableStateOf("any") }
    var priority by rememberSaveable { mutableStateOf("any") }
    var search by rememberSaveable { mutableStateOf("") }
    var draft by rememberSaveable { mutableStateOf("") }
    var error by rememberSaveable { mutableStateOf<String?>(null) }
    var saving by remember { mutableStateOf(false) }
    var menu by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val query = search.trim()
    val date = selectedDay?.let(LocalDate::parse)
    val tasks = snapshot.tasks.filter {
        (projectId == null || it.projectId == projectId) &&
            (date == null || it.dueDay?.date == date) &&
            (status == "any" || it.status.raw == status) &&
            (priority == "any" || it.priority.raw == priority) &&
            (query.isEmpty() || it.title.contains(query, ignoreCase = true))
    }
    val hasFilter = date != null || status != "any" || priority != "any" || query.isNotEmpty()
    val title = snapshot.project(projectId)?.name ?: "مهامي"
    val days = buildList {
        addAll((0..6).map { snapshot.today.plusDays(it.toLong()) })
        if (date != null && date !in this) add(0, date)
    }
    fun addTask() {
        if (saving) return
        if (draft.trim().isEmpty()) { error = "عنوان المهمة مطلوب."; return }
        saving = true
        scope.launch {
            try {
                error = model.quickAdd(draft, date, projectId)
                if (error == null) draft = ""
            } finally { saving = false }
        }
    }
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(22.dp, 12.dp, 22.dp, 24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (onBack != null) IconButton(onClick = onBack) { AppIcon(R.drawable.icon_arrow_left, "رجوع") }
                Text(title, Modifier.weight(1f), fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
            }
        }
        item {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(search, onValueChange = { search = it }, Modifier.weight(1f),
                    placeholder = { Text("ابحث عن مهمة…", fontSize = 14.sp) }, singleLine = true,
                    shape = RoundedCornerShape(15.dp), keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search))
                Box {
                    TextButton(onClick = { menu = true }) {
                        Text(TaskPriority.entries.firstOrNull { it.raw == priority }?.label() ?: "الأولوية", fontSize = 12.sp)
                    }
                    DropdownMenu(menu, onDismissRequest = { menu = false }) {
                        DropdownMenuItem(text = { Text("كل الأولويات") }, onClick = { priority = "any"; menu = false })
                        TaskPriority.entries.reversed().forEach { value ->
                            DropdownMenuItem(text = { Text(value.label()) }, onClick = { priority = value.raw; menu = false })
                        }
                    }
                }
            }
        }
        item {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                item { DayCard(selected = date == null, month = "", number = "الكل", weekday = "", onClick = { selectedDay = null }) }
                items(days, key = { it.toString() }) { day ->
                    DayCard(selected = date == day, month = day.format(DateTimeFormatter.ofPattern("MMM", Arabic)),
                        number = "${day.dayOfMonth}", weekday = day.format(DateTimeFormatter.ofPattern("EEE", Arabic)),
                        onClick = { selectedDay = day.toString() })
                }
            }
        }
        item {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ChoiceChip("الكل", status == "any") { status = "any" }
                TaskStatus.entries.forEach { value -> ChoiceChip(value.label(), status == value.raw) { status = value.raw } }
            }
        }
        if (tasks.isEmpty()) item {
            EmptyState(if (hasFilter) "لا توجد نتائج مطابقة" else "لا توجد مهام بعد",
                if (hasFilter) "غيّر البحث أو اليوم أو الفلاتر، أو اختر «الكل»."
                else "أضف مهمتك الأولى من حقل الإضافة السريعة أدناه أو من زر ＋.")
        }
        items(tasks, key = { it.id.toString() }) { task ->
            TaskRow(task, snapshot.project(task.projectId), snapshot.today,
                onOpen = { onTask(task) }, onToggle = { model.toggle(task) })
        }
        item {
            AppCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(draft, onValueChange = { draft = it }, Modifier.weight(1f), enabled = !saving,
                        placeholder = { Text("أضف مهمة…", fontSize = 14.sp) }, singleLine = true,
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(onDone = { addTask() }), shape = RoundedCornerShape(9.dp))
                    IconButton(onClick = ::addTask, enabled = !saving) { AppIcon(R.drawable.icon_add, "إضافة المهمة") }
                }
                if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error, fontSize = 12.sp)
            }
        }
    }
}

@Composable
private fun DayCard(selected: Boolean, month: String, number: String, weekday: String, onClick: () -> Unit) {
    val primary = MaterialTheme.colorScheme.primary
    Column(Modifier.width(64.dp).height(84.dp).background(
        if (selected) primary else MaterialTheme.colorScheme.surface, RoundedCornerShape(15.dp))
        .clickable(role = Role.RadioButton, onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        val color = if (selected) Color.White else MaterialTheme.colorScheme.onSurface
        if (month.isNotEmpty()) Text(month, fontSize = 11.sp, color = color)
        Text(number, fontSize = 19.sp, fontWeight = FontWeight.SemiBold,
            fontFamily = if (month.isNotEmpty()) Lexend else null, color = color)
        if (weekday.isNotEmpty()) Text(weekday, fontSize = 11.sp, color = color)
    }
}
