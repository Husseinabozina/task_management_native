package com.husseinabozina.taskmanagement.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.*
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.*
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.husseinabozina.taskmanagement.R
import java.time.LocalDate
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaskApp(model: TaskAppViewModel) {
    val snapshot by model.snapshot.collectAsStateWithLifecycle()
    val onboarding by model.onboarding.collectAsStateWithLifecycle()
    val actionError by model.actionError.collectAsStateWithLifecycle()
    val notificationTask by model.notificationTask.collectAsStateWithLifecycle()
    var tab by rememberSaveable { mutableStateOf("home") }
    var taskProject by rememberSaveable { mutableStateOf<String?>(null) }
    var taskDay by rememberSaveable { mutableStateOf<String?>(null) }
    var returnTab by rememberSaveable { mutableStateOf<String?>(null) }
    var taskContext by rememberSaveable { mutableIntStateOf(0) }
    var taskEditorOpen by rememberSaveable { mutableStateOf(false) }
    var editId by rememberSaveable { mutableStateOf<String?>(null) }
    var detailId by rememberSaveable { mutableStateOf<String?>(null) }
    var projectEditorOpen by rememberSaveable { mutableStateOf(false) }
    var accountOpen by rememberSaveable { mutableStateOf(false) }
    val snackbar = remember { SnackbarHostState() }

    fun openTasks(project: String? = null, day: LocalDate? = null) {
        returnTab = tab.takeIf { it != "tasks" }
        taskProject = project
        taskDay = day?.toString()
        taskContext++
        tab = "tasks"
    }
    fun openNewTask() { editId = null; taskEditorOpen = true }
    fun backToTab() {
        tab = returnTab ?: "home"
        returnTab = null
        taskProject = null
        taskDay = null
    }

    LaunchedEffect(actionError) {
        actionError?.let { message ->
            model.clearActionError()
            snackbar.showSnackbar(message, actionLabel = "إغلاق")
        }
    }
    LaunchedEffect(notificationTask, onboarding, snapshot.loading) {
        if (!onboarding && !snapshot.loading) notificationTask?.let { id ->
            if (snapshot.error != null) return@let
            if (snapshot.tasks.any { it.id == id }) {
                taskEditorOpen = false
                projectEditorOpen = false
                detailId = id.toString()
            } else {
                snackbar.showSnackbar("المهمة المرتبطة بهذا التذكير لم تعد موجودة.")
            }
            model.consumeNotificationTask()
        }
    }
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        if (onboarding) {
            EntryScreen(onStart = model::completeOnboarding)
        } else {
            BackHandler(enabled = tab == "tasks" && returnTab != null &&
                !taskEditorOpen && detailId == null && !projectEditorOpen) { backToTab() }
            Scaffold(
                containerColor = MaterialTheme.colorScheme.background,
                contentWindowInsets = WindowInsets.statusBars,
                snackbarHost = { SnackbarHost(snackbar) },
                bottomBar = {
                    AppBottomBar(tab, onSelect = { next ->
                        tab = next
                        returnTab = null
                        taskProject = null
                        taskDay = null
                        if (next == "tasks") taskContext++
                    }, onAdd = ::openNewTask)
                }
            ) { insets ->
                Box(Modifier.fillMaxSize().padding(insets).imePadding()) {
                    when {
                        snapshot.loading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                        snapshot.error != null -> Column(Modifier.fillMaxSize().padding(22.dp),
                            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                            EmptyState("تعذّر تحميل البيانات", snapshot.error!!)
                            PrimaryAction("إعادة المحاولة", onClick = model::retry)
                        }
                        else -> when (tab) {
                            "home" -> HomeScreen(snapshot, onTasks = { openTasks() },
                                onProject = { openTasks(it.id.toString()) },
                                onTask = { detailId = it.id.toString() }, onToggle = model::toggle,
                                onAccount = { accountOpen = true },
                                onReplay = model::replayOnboarding)
                            "calendar" -> CalendarScreen(snapshot, onDay = { openTasks(day = it) })
                            "projects" -> ProjectsScreen(snapshot, model, onNew = { projectEditorOpen = true },
                                onProject = { openTasks(it.id.toString()) })
                            else -> key(taskContext) {
                                TasksScreen(snapshot, model,
                                    initialDay = taskDay?.let(LocalDate::parse),
                                    projectId = taskProject?.let(UUID::fromString),
                                    onBack = if (returnTab != null) ::backToTab else null,
                                    onTask = { detailId = it.id.toString() })
                            }
                        }
                    }
                }
            }
        }
        if (!onboarding && taskEditorOpen) {
            val edited = editId?.let { id -> snapshot.tasks.firstOrNull { it.id.toString() == id } }
            if (editId == null || edited != null) {
                TaskEditorSheet(
                    task = edited, model = model, projects = snapshot.projects,
                    initialProject = taskProject?.let(UUID::fromString),
                    initialDay = taskDay?.let(LocalDate::parse),
                    onDismiss = { taskEditorOpen = false; editId = null }
                )
            } else if (!snapshot.loading) {
                AlertDialog(onDismissRequest = { taskEditorOpen = false; editId = null },
                    title = { Text("تعذّر فتح المهمة") },
                    text = { Text("المهمة غير متاحة حاليًا. أغلق المحرر وأعد المحاولة.") },
                    confirmButton = { TextButton(onClick = { taskEditorOpen = false; editId = null }) { Text("إغلاق") } })
            }
        }
        if (!onboarding && detailId != null) {
            val task = snapshot.tasks.firstOrNull { it.id.toString() == detailId }
            if (task != null) {
                TaskDetailSheet(task, snapshot.project(task.projectId), snapshot.today, model,
                    onDismiss = { detailId = null }, onEdit = {
                        detailId = null
                        editId = task.id.toString()
                        taskEditorOpen = true
                    })
            } else if (!snapshot.loading) {
                LaunchedEffect(detailId) { detailId = null }
            }
        }
        if (!onboarding && projectEditorOpen) {
            ProjectEditorSheet(model, onDismiss = { projectEditorOpen = false })
        }
        if (!onboarding && accountOpen) AccountSheet(model.cloud, onDismiss = { accountOpen = false })
    }
}

@Composable
private fun EntryScreen(onStart: () -> Unit) {
    BoxWithConstraints(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        val canvasHeight = maxHeight
        // Same normalized centers and colors as iOS EntryScreen; graphics contain no living beings.
        val blobs = listOf(
            Triple(.888f, .286f, Color(0xFF2555FF)), Triple(.203f, .522f, Color(0xFF46BDF0)),
            Triple(.64f, .945f, Color(0xFFF0B646)), Triple(-.04f, .155f, Color(0xFF46F080)),
            Triple(.701f, 0f, Color(0xFFEDF046))
        )
        blobs.forEach { (x, y, color) ->
            Box(Modifier.absoluteOffset(maxWidth * x - 30.dp, maxHeight * y - 30.dp).size(60.dp)
                .blur(25.dp).background(Brush.verticalGradient(listOf(color, color.copy(alpha = .15f))), CircleShape))
        }
        val dots = listOf(Triple(.667f,.472f,Color(0xFFEAED2A)),Triple(.368f,.482f,Color(0xFFFFD7E4)),
            Triple(.672f,.090f,Color(0xFF92DEFF)),Triple(.539f,.113f,Color(0xFFBE9FFF)))
        dots.forEach { (x,y,color) ->
            Box(Modifier.absoluteOffset(maxWidth*x,maxHeight*y).size(6.dp).background(color,CircleShape))
        }
        Column(Modifier.fillMaxSize().safeDrawingPadding().verticalScroll(rememberScrollState()).padding(horizontal = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.height((canvasHeight * .17f).coerceAtMost(140.dp)))
            Image(painterResource(R.drawable.onboarding_productivity), null, Modifier.size(200.dp),
                contentScale = ContentScale.Fit)
            Spacer(Modifier.height(28.dp))
            Text("نظّم يومك\nوأنجز مهامك", fontSize = 24.sp, lineHeight = 36.sp,
                fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
            Spacer(Modifier.height(16.dp))
            Text("نظّم مهامك ومشاريعك في مكان واحد، واجعل كل يوم خطوة نحو أهدافك.",
                Modifier.padding(horizontal = 14.dp), fontSize = 14.sp, lineHeight = 24.sp,
                color = MaterialTheme.colorScheme.secondary, textAlign = TextAlign.Center)
            Spacer(Modifier.height((canvasHeight * .11f).coerceAtMost(94.dp)))
            PrimaryAction("لنبدأ", onClick = onStart)
            Spacer(Modifier.height(32.dp))
        }
    }
}
