package com.husseinabozina.taskmanagement.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.*
import com.husseinabozina.taskmanagement.R
import com.husseinabozina.taskmanagement.domain.*
import com.husseinabozina.taskmanagement.ui.theme.Lexend
import java.time.format.DateTimeFormatter
import kotlin.math.roundToInt

@Composable
fun HomeScreen(snapshot: AppSnapshot, onTasks: () -> Unit, onProject: (ProjectItem) -> Unit,
    onTask: (TaskItem) -> Unit, onToggle: (TaskItem) -> Unit, onReplay: () -> Unit, onAccount: () -> Unit) {
    val todayTasks = snapshot.tasks.filter { it.dueDay?.date == snapshot.today }
    val done = todayTasks.count { it.status == TaskStatus.COMPLETED }
    val openToday = todayTasks.filter { it.status != TaskStatus.COMPLETED }
    val overdue = snapshot.tasks.count { it.dayBucket(CalendarDay(snapshot.today)) == TaskDayBucket.OVERDUE }
    val featured = snapshot.projects.filter { project ->
        snapshot.projectTasks(project.id).any { it.status != TaskStatus.COMPLETED }
    }.sortedWith(compareByDescending<ProjectItem> { p ->
        snapshot.projectTasks(p.id).count { it.status != TaskStatus.COMPLETED }
    }.thenByDescending { snapshot.progress(it.id) }.thenBy { it.id }).take(2)
    var menu by remember { mutableStateOf(false) }

    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(22.dp, 12.dp, 22.dp, 24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("أهلًا", fontSize = 14.sp, color = MaterialTheme.colorScheme.secondary)
                    Text(snapshot.today.format(DateTimeFormatter.ofPattern("EEEE، d MMMM", Arabic)),
                        fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
                }
                Box {
                    IconButton(onClick = { menu = true }) { AppIcon(R.drawable.icon_more, "خيارات") }
                    DropdownMenu(menu, onDismissRequest = { menu = false }) {
                        DropdownMenuItem(text = { Text("الحساب والمزامنة") },
                            onClick = { menu = false; onAccount() })
                        DropdownMenuItem(text = { Text("إعادة جولة الترحيب") },
                            onClick = { menu = false; onReplay() })
                    }
                }
                Box(Modifier.size(32.dp).semantics {
                    contentDescription = if (overdue > 0) "لديك $overdue مهام متأخرة" else "لا توجد مهام متأخرة"
                }, contentAlignment = Alignment.Center) {
                    AppIcon(R.drawable.icon_notification, null, MaterialTheme.colorScheme.onSurface)
                    if (overdue > 0) Box(Modifier.align(Alignment.TopEnd).size(8.dp)
                        .background(MaterialTheme.colorScheme.primary, CircleShape))
                }
            }
        }
        item {
            Row(Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.primary, RoundedCornerShape(24.dp))
                .padding(20.dp), verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(when {
                        todayTasks.isEmpty() -> "لا توجد مهام اليوم. أضف مهمتك الأولى من زر ＋"
                        done == todayTasks.size -> "أحسنت! أنجزت جميع مهام اليوم 🎉"
                        else -> "مهام اليوم: أنجزت $done من ${todayTasks.size}"
                    }, color = Color.White, fontSize = 14.sp, lineHeight = 24.sp)
                    Text("عرض مهامك", Modifier.background(lavender(), RoundedCornerShape(9.dp))
                        .clickable(role = Role.Button, onClick = onTasks).padding(horizontal = 16.dp, vertical = 10.dp),
                        color = MaterialTheme.colorScheme.primary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                }
                ProgressRing(if (todayTasks.isEmpty()) 0f else done.toFloat() / todayTasks.size)
            }
        }
        if (featured.isNotEmpty()) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    SectionHeading("أبرز المشاريع النشطة", featured.size)
                    LazyRow(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        items(featured, key = { it.id.toString() }) { project ->
                            Column(Modifier.width(202.dp).heightIn(min = 116.dp)
                                .background(pastel(project.colorKey), RoundedCornerShape(19.dp))
                                .clickable(onClick = { onProject(project) }).padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text("${project.emoji ?: "📁"}  ${project.name}", fontSize = 14.sp,
                                    fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                                Text("${snapshot.projectTasks(project.id).count { it.status != TaskStatus.COMPLETED }} مهام مفتوحة",
                                    fontSize = 11.sp, color = MaterialTheme.colorScheme.secondary)
                                LinearProgressIndicator(progress = { snapshot.progress(project.id) },
                                    modifier = Modifier.fillMaxWidth().height(6.dp),
                                    color = MaterialTheme.colorScheme.primary, trackColor = MaterialTheme.colorScheme.surface)
                            }
                        }
                    }
                }
            }
        }
        if (openToday.isNotEmpty()) {
            item { SectionHeading("مهام اليوم", openToday.size) {
                TextButton(onClick = onTasks) { Text("الكل") }
            } }
            items(openToday.take(3), key = { "today-${it.id}" }) { task ->
                TaskRow(task, snapshot.project(task.projectId), snapshot.today,
                    onOpen = { onTask(task) }, onToggle = { onToggle(task) })
            }
        }
        if (snapshot.projects.isNotEmpty()) {
            item { SectionHeading("مشاريعك", snapshot.projects.size) }
            items(snapshot.projects, key = { "project-${it.id}" }) { project ->
                ProjectRow(project, snapshot, onOpen = { onProject(project) })
            }
        }
    }
}

@Composable
private fun ProgressRing(progress: Float) {
    val animated by animateFloatAsState(progress, label = "تقدم اليوم")
    Box(Modifier.size(76.dp).semantics {
        contentDescription = "تقدم مهام اليوم ${(progress * 100).roundToInt()} بالمئة"
    }, contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize().padding(4.dp)) {
            val stroke = 8.dp.toPx()
            drawCircle(Color(0xFFEEE9FF), style = Stroke(stroke))
            drawArc(Color(0xFF8764FF), -90f, animated * 360, false,
                style = Stroke(stroke, cap = StrokeCap.Round))
        }
        Text("${(progress * 100).roundToInt()}%", fontFamily = Lexend, color = Color.White, fontSize = 11.sp)
    }
}
