package com.husseinabozina.taskmanagement.ui

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.view.ContextThemeWrapper
import android.Manifest
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.*
import com.husseinabozina.taskmanagement.domain.*
import com.husseinabozina.taskmanagement.reminders.ReminderScheduler
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.UUID
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaskEditorSheet(task: TaskItem?, model: TaskAppViewModel, projects: List<ProjectItem>,
    initialProject: UUID?, initialDay: LocalDate?, onDismiss: () -> Unit) {
    var title by rememberSaveable(task?.id?.toString()) { mutableStateOf(task?.title ?: "") }
    var details by rememberSaveable(task?.id?.toString()) { mutableStateOf(task?.details ?: "") }
    var statusRaw by rememberSaveable(task?.id?.toString()) { mutableStateOf(task?.status?.raw ?: TaskStatus.ACTIVE.raw) }
    var priorityRaw by rememberSaveable(task?.id?.toString()) { mutableStateOf(task?.priority?.raw ?: TaskPriority.NORMAL.raw) }
    var pinned by rememberSaveable(task?.id?.toString()) { mutableStateOf(task?.isPinned ?: false) }
    var hasReminder by rememberSaveable(task?.id?.toString()) { mutableStateOf(task?.reminderDate != null) }
    var reminderMillis by rememberSaveable(task?.id?.toString()) {
        mutableLongStateOf(task?.reminderDate?.toEpochMilli() ?: Instant.now().plusSeconds(3_600).toEpochMilli())
    }
    var hasDate by rememberSaveable(task?.id?.toString()) { mutableStateOf(task?.dueDay != null || (task == null && initialDay != null)) }
    var dateValue by rememberSaveable(task?.id?.toString()) {
        mutableStateOf((task?.dueDay?.date ?: initialDay ?: LocalDate.now()).toString())
    }
    var projectValue by rememberSaveable(task?.id?.toString()) {
        mutableStateOf((if (task != null) task.projectId else initialProject)?.toString())
    }
    var projectMenu by remember { mutableStateOf(false) }
    var newProjectOpen by rememberSaveable { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }
    var error by rememberSaveable { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    var permissionRevision by remember { mutableIntStateOf(0) }
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        permissionRevision++
        if (granted && ReminderScheduler.notificationsAllowed(context)) {
            hasReminder = true
            error = null
        } else {
            error = "لم يُفعّل التذكير. اسمح بالإشعارات من إعدادات الهاتف أو احفظ المهمة دون تذكير."
        }
    }
    val settingsLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        permissionRevision++
        model.refreshReminders()
    }
    fun openReminderSettings(exact: Boolean) {
        val intent = if (exact && Build.VERSION.SDK_INT >= 31) {
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${context.packageName}"))
        } else {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        }
        try { settingsLauncher.launch(intent) }
        catch (_: android.content.ActivityNotFoundException) { error = "تعذّر فتح الإعدادات. افتح إعدادات مهامي من الهاتف." }
    }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true, confirmValueChange = { !saving })
    ModalBottomSheet(onDismissRequest = { if (!saving) onDismiss() }, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.background) {
        Column(Modifier.fillMaxWidth().fillMaxHeight(.92f).imePadding().verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            EditorHeading(if (task == null) "مهمة جديدة" else "تعديل المهمة", !saving, onDismiss)
            FieldCard("عنوان المهمة") {
                OutlinedTextField(title, onValueChange = { title = it }, Modifier.fillMaxWidth(), enabled = !saving,
                    placeholder = { Text("مثال: تسليم التقرير") }, singleLine = true, shape = RoundedCornerShape(9.dp),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next))
            }
            FieldCard("الوصف (اختياري)") {
                OutlinedTextField(details, onValueChange = { details = it }, Modifier.fillMaxWidth(), enabled = !saving,
                    placeholder = { Text("تفاصيل المهمة…") }, minLines = 3, maxLines = 8, shape = RoundedCornerShape(9.dp))
            }
            FieldCard("الحالة") {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TaskStatus.entries.forEach { value ->
                        ChoiceChip(value.label(), statusRaw == value.raw, !saving) { statusRaw = value.raw }
                    }
                }
            }
            FieldCard("التثبيت") {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("مثبتة في أعلى القائمة", Modifier.weight(1f), fontSize = 14.sp)
                    Switch(pinned, onCheckedChange = { pinned = it }, enabled = !saving)
                }
            }
            FieldCard("الأولوية") {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TaskPriority.entries.reversed().forEach { value ->
                        ChoiceChip(value.label(), priorityRaw == value.raw, !saving) { priorityRaw = value.raw }
                    }
                }
            }
            FieldCard("المشروع (اختياري)") {
                Box {
                    TextButton(enabled = !saving, onClick = { projectMenu = true }) {
                        Text(projects.firstOrNull { it.id.toString() == projectValue }?.let { "${it.emoji ?: "📁"} ${it.name}" }
                            ?: if (projectValue == null) "بدون مشروع" else "اختر مشروعًا آخر")
                    }
                    DropdownMenu(projectMenu, onDismissRequest = { projectMenu = false }) {
                        DropdownMenuItem(text = { Text("بدون مشروع") }, onClick = { projectValue = null; projectMenu = false })
                        projects.forEach { project ->
                            DropdownMenuItem(text = { Text("${project.emoji ?: "📁"} ${project.name}") },
                                onClick = { projectValue = project.id.toString(); projectMenu = false })
                        }
                        DropdownMenuItem(text = { Text("مشروع جديد") }, onClick = { projectMenu = false; newProjectOpen = true })
                    }
                }
            }
            FieldCard("الموعد (اختياري)") {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("تحديد موعد للمهمة", Modifier.weight(1f), fontSize = 14.sp)
                    Switch(hasDate, onCheckedChange = { hasDate = it }, enabled = !saving)
                }
                if (hasDate) {
                    TextButton(enabled = !saving, onClick = {
                        val date = LocalDate.parse(dateValue)
                        val config = Configuration(configuration).apply { setLocale(Arabic) }
                        val localized = ContextThemeWrapper(context, context.theme).apply { applyOverrideConfiguration(config) }
                        DatePickerDialog(localized, { _, year, month, day ->
                            dateValue = LocalDate.of(year, month + 1, day).toString()
                        }, date.year, date.monthValue - 1, date.dayOfMonth).apply {
                            setTitle("موعد المهمة")
                            setButton(DatePickerDialog.BUTTON_POSITIVE, "اختيار", this)
                            setButton(DatePickerDialog.BUTTON_NEGATIVE, "إلغاء", this)
                        }.show()
                    }) { Text("${dateLabel(LocalDate.parse(dateValue))} ${LocalDate.parse(dateValue).year}  ·  تغيير") }
                }
            }
            FieldCard("التذكير (اختياري)") {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("إشعار بموعد المهمة", Modifier.weight(1f), fontSize = 14.sp)
                    Switch(hasReminder, enabled = !saving, onCheckedChange = { enabled ->
                        if (!enabled) hasReminder = false
                        else if (ReminderScheduler.notificationsAllowed(context)) hasReminder = true
                        else if (Build.VERSION.SDK_INT >= 33) permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        else error = "اسمح بالإشعارات من إعدادات الهاتف أولًا."
                    })
                }
                // Reading this revision refreshes platform permission state after Settings returns.
                key(permissionRevision) {
                    if (!ReminderScheduler.notificationsAllowed(context)) {
                        Text("إشعارات المهام غير مفعّلة على هذا الهاتف.", fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.secondary)
                        TextButton(enabled = !saving, onClick = { openReminderSettings(false) }) { Text("إعدادات الإشعارات") }
                    }
                    if (hasReminder && !ReminderScheduler.exactAllowed(context)) {
                        Text("قد يتأخر الإشعار وفق إعدادات النظام. اسمح بالتنبيهات الدقيقة لإرساله في الموعد المحدد.",
                            fontSize = 12.sp, color = MaterialTheme.colorScheme.secondary)
                        TextButton(enabled = !saving, onClick = { openReminderSettings(true) }) { Text("ضبط دقة التذكير") }
                    }
                }
                if (hasReminder) {
                    val selected = Instant.ofEpochMilli(reminderMillis).atZone(ZoneId.systemDefault())
                    val formatter = DateTimeFormatter.ofPattern("d MMM yyyy، h:mm a", Arabic)
                    Text(formatter.format(selected), fontSize = 14.sp)
                    Row {
                        TextButton(enabled = !saving, onClick = {
                            val config = Configuration(configuration).apply { setLocale(Arabic) }
                            DatePickerDialog(ContextThemeWrapper(context, context.theme).apply { applyOverrideConfiguration(config) }, { _, year, month, day ->
                                reminderMillis = selected.withYear(year).withMonth(1).withDayOfMonth(1)
                                    .withMonth(month + 1).withDayOfMonth(day).withSecond(0).withNano(0).toInstant().toEpochMilli()
                            }, selected.year, selected.monthValue - 1, selected.dayOfMonth).apply {
                                setTitle("تاريخ التذكير")
                                setButton(DatePickerDialog.BUTTON_POSITIVE, "اختيار", this)
                                setButton(DatePickerDialog.BUTTON_NEGATIVE, "إلغاء", this)
                            }.show()
                        }) { Text("تغيير التاريخ") }
                        TextButton(enabled = !saving, onClick = {
                            val config = Configuration(configuration).apply { setLocale(Arabic) }
                            TimePickerDialog(ContextThemeWrapper(context, context.theme).apply { applyOverrideConfiguration(config) }, { _, hour, minute ->
                                reminderMillis = selected.withHour(hour).withMinute(minute).withSecond(0).withNano(0)
                                    .toInstant().toEpochMilli()
                            }, selected.hour, selected.minute, android.text.format.DateFormat.is24HourFormat(context)).apply {
                                setTitle("وقت التذكير")
                                setButton(TimePickerDialog.BUTTON_POSITIVE, "اختيار", this)
                                setButton(TimePickerDialog.BUTTON_NEGATIVE, "إلغاء", this)
                            }.show()
                        }) { Text("تغيير الساعة") }
                    }
                    if (statusRaw == TaskStatus.COMPLETED.raw) {
                        Text("لن يُرسل إشعار للمهمة المكتملة.", fontSize = 12.sp, color = MaterialTheme.colorScheme.secondary)
                    }
                }
            }
            if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error, fontSize = 14.sp)
            PrimaryAction(if (saving) "جارٍ الحفظ…" else "حفظ", !saving) {
                if (saving) return@PrimaryAction
                if (title.trim().isEmpty()) { error = "عنوان المهمة مطلوب."; return@PrimaryAction }
                if (title.trim().length > 200) { error = "العنوان أطول من الحد المسموح (200 حرف)."; return@PrimaryAction }
                if (details.length > 5_000) { error = "الوصف أطول من الحد المسموح (5000 حرف)."; return@PrimaryAction }
                saving = true
                scope.launch {
                    try {
                        error = model.saveTask(task?.id, NewTask(title = title,
                            details = details.trim().takeIf { it.isNotEmpty() }, priority = TaskPriority.from(priorityRaw),
                            status = TaskStatus.from(statusRaw), isPinned = pinned,
                            dueDay = if (hasDate) CalendarDay(LocalDate.parse(dateValue)) else null,
                            projectId = projectValue?.let(UUID::fromString),
                            reminderDate = if (hasReminder) Instant.ofEpochMilli(reminderMillis) else null))
                        if (error == null) onDismiss()
                    } finally { saving = false }
                }
            }
            Spacer(Modifier.height(32.dp))
        }
    }
    if (newProjectOpen) ProjectEditorSheet(model, onDismiss = { newProjectOpen = false },
        onCreated = { projectValue = it.id.toString() })
}

@Composable
private fun EditorHeading(title: String, enabled: Boolean, onDismiss: () -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(title, Modifier.weight(1f), fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
        TextButton(enabled = enabled, onClick = onDismiss) { Text("إلغاء") }
    }
}

@Composable
private fun FieldCard(label: String, content: @Composable ColumnScope.() -> Unit) {
    AppCard {
        Text(label, fontSize = 11.sp, color = MaterialTheme.colorScheme.secondary)
        Spacer(Modifier.height(8.dp))
        content()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProjectEditorSheet(model: TaskAppViewModel, onDismiss: () -> Unit, onCreated: (ProjectItem) -> Unit = {}) {
    var name by rememberSaveable { mutableStateOf("") }
    var emoji by rememberSaveable { mutableStateOf("💼") }
    var color by rememberSaveable { mutableStateOf("purple") }
    var error by rememberSaveable { mutableStateOf<String?>(null) }
    var saving by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true, confirmValueChange = { !saving })
    ModalBottomSheet(onDismissRequest = { if (!saving) onDismiss() }, sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.background) {
        Column(Modifier.fillMaxWidth().imePadding().verticalScroll(rememberScrollState()).padding(horizontal = 22.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)) {
            EditorHeading("مشروع جديد", !saving, onDismiss)
            FieldCard("اسم المشروع") {
                OutlinedTextField(name, onValueChange = { name = it }, Modifier.fillMaxWidth(), enabled = !saving,
                    placeholder = { Text("مثال: مشروع التخرج") }, singleLine = true, shape = RoundedCornerShape(9.dp))
            }
            FieldCard("الأيقونة") {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("💼", "📚", "🚀", "✏️", "🗂️", "🎯", "🏠", "💡").forEach { value ->
                        ChoiceChip(value, emoji == value, !saving) { emoji = value }
                    }
                }
            }
            FieldCard("اللون") {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    PaletteKeys.forEach { value ->
                        val selected = color == value
                        Box(Modifier.size(44.dp).background(pastel(value), CircleShape)
                            .border(if (selected) 2.dp else 0.dp,
                                if (selected) MaterialTheme.colorScheme.primary else Color.Transparent, CircleShape)
                            .clickable(enabled = !saving, role = Role.RadioButton, onClick = { color = value })
                            .semantics { contentDescription = "لون ${paletteLabel(value)}"; this.selected = selected },
                            contentAlignment = Alignment.Center) {
                            if (selected) Text("✓", color = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
            }
            if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error)
            PrimaryAction(if (saving) "جارٍ الحفظ…" else "إضافة المشروع", !saving) {
                if (saving) return@PrimaryAction
                if (name.trim().isEmpty()) { error = "اسم المشروع مطلوب."; return@PrimaryAction }
                if (name.trim().length > 80) { error = "الاسم أطول من الحد المسموح (80 حرف)."; return@PrimaryAction }
                saving = true
                scope.launch {
                    try {
                        error = model.saveProject(NewProject(name, emoji, color), onCreated)
                        if (error == null) onDismiss()
                    } finally { saving = false }
                }
            }
            Spacer(Modifier.height(32.dp))
        }
    }
}
