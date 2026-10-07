package com.husseinabozina.taskmanagement.ui

import androidx.annotation.DrawableRes
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.GenericShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.*
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.vector.PathParser
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.*
import com.husseinabozina.taskmanagement.R
import com.husseinabozina.taskmanagement.domain.*
import com.husseinabozina.taskmanagement.ui.theme.Lexend
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

val Arabic: Locale = Locale.forLanguageTag("ar-EG")
fun dateLabel(day: LocalDate): String = day.format(DateTimeFormatter.ofPattern("d MMM", Arabic))
fun TaskStatus.label() = when (this) {
    TaskStatus.ACTIVE -> "مفتوحة"
    TaskStatus.IN_PROGRESS -> "قيد التنفيذ"
    TaskStatus.COMPLETED -> "مكتملة"
}
fun TaskPriority.label() = when (this) {
    TaskPriority.LOW -> "منخفضة"
    TaskPriority.NORMAL -> "عادية"
    TaskPriority.HIGH -> "عالية"
}
val PaletteKeys = listOf("pink", "purple", "orange", "yellow", "blue", "peach", "sky")
fun paletteLabel(key: String) = when (key) {
    "pink" -> "وردي"; "orange" -> "برتقالي"; "yellow" -> "أصفر"
    "blue" -> "أزرق"; "peach" -> "خوخي"; "sky" -> "سماوي"; else -> "بنفسجي"
}
@Composable
fun pastel(key: String?): Color {
    val dark = isSystemInDarkTheme()
    return when (key) {
        "pink" -> if (dark) Color(0xFF3C2433) else Color(0xFFFFE4F2)
        "orange" -> if (dark) Color(0xFF3D2A1D) else Color(0xFFFFE6D4)
        "yellow" -> if (dark) Color(0xFF3B351D) else Color(0xFFFFF6D4)
        "blue" -> if (dark) Color(0xFF1A2B3D) else Color(0xFFE7F3FF)
        "peach" -> if (dark) Color(0xFF3C2921) else Color(0xFFFFE9E1)
        "sky" -> if (dark) Color(0xFF1C2C3C) else Color(0xFFE3F2FF)
        else -> if (dark) Color(0xFF2C2440) else Color(0xFFEDE4FF)
    }
}
@Composable fun lavender() = if (isSystemInDarkTheme()) Color(0xFF2A2140) else Color(0xFFEEE9FF)

// SVG path data is copied verbatim from assets/figma/shapes, scaled to its viewBox.
private const val PrimaryPath = "M0 15.724C0 8.10065 6.07036 1.88083 13.6924 1.74208C43.5021 1.19944 115.638 -0.00982952 166 6.1035e-05C215.917 0.00986419 287.605 1.20647 317.307 1.74384C324.93 1.88176 330.999 8.10196 330.999 15.7262V36.2737C330.999 43.8979 324.93 50.1181 317.307 50.2561C287.605 50.7935 215.917 51.9901 166 51.9999C115.638 52.0098 43.5021 50.8005 13.6924 50.2578C6.07035 50.1191 0 43.8993 0 36.2759V15.724Z"
private const val BarPath = "M0 22C0 9.84974 9.84974 0 22 0H93.5H141C141 0 145.5 0 154 0C164.148 0 162 27 187.5 27C214.5 27 210.735 -5.64924e-06 220.5 0C229 4.91738e-06 233.5 0 233.5 0H282.5H353C365.15 0 375 9.84974 375 22V56H0V22Z"
private fun svgShape(data: String, width: Float, height: Float) = GenericShape { size, _ ->
    val path = PathParser().parsePathString(data).toPath()
    path.transform(Matrix().apply { scale(size.width / width, size.height / height) })
    addPath(path)
}
private val PrimaryShape = svgShape(PrimaryPath, 331f, 52f)
private val BarShape = svgShape(BarPath, 375f, 56f)

@Composable
fun PrimaryAction(title: String, enabled: Boolean = true, onClick: () -> Unit) {
    val primary = MaterialTheme.colorScheme.primary
    Row(
        Modifier.fillMaxWidth().height(52.dp)
            .shadow(if (enabled) 8.dp else 0.dp, PrimaryShape, spotColor = primary.copy(alpha = .35f))
            .clip(PrimaryShape).background(primary.copy(alpha = if (enabled) 1f else .45f))
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center
    ) {
        Text(title, fontSize = 19.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
        Spacer(Modifier.width(8.dp))
        AppIcon(R.drawable.icon_arrow_left, null, Color.White, 20.dp)
    }
}

@Composable
fun AppIcon(@DrawableRes resource: Int, description: String?, tint: Color = MaterialTheme.colorScheme.primary, size: Dp = 24.dp) {
    Icon(painterResource(resource), description, Modifier.size(size), tint = tint)
}

@Composable
fun AppCard(modifier: Modifier = Modifier, onClick: (() -> Unit)? = null, content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier.fillMaxWidth().shadow(5.dp, RoundedCornerShape(15.dp),
            ambientColor = Color.Black.copy(alpha = .04f), spotColor = Color.Black.copy(alpha = .04f))
            .clip(RoundedCornerShape(15.dp)).background(MaterialTheme.colorScheme.surface)
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(16.dp), content = content
    )
}

@Composable
fun SectionHeading(title: String, count: Int? = null, action: (@Composable () -> Unit)? = null) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(title, fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
        if (count != null) {
            Spacer(Modifier.width(8.dp))
            Text("$count", Modifier.background(lavender(), CircleShape).padding(horizontal = 7.dp, vertical = 2.dp),
                color = MaterialTheme.colorScheme.primary, fontSize = 11.sp, fontFamily = Lexend)
        }
        Spacer(Modifier.weight(1f))
        action?.invoke()
    }
}

@Composable
fun ChoiceChip(title: String, selected: Boolean, enabled: Boolean = true, onClick: () -> Unit) {
    Box(Modifier.heightIn(min = 44.dp).clickable(enabled = enabled, role = Role.RadioButton, onClick = onClick)
        .semantics { this.selected = selected }.padding(vertical = 5.dp), contentAlignment = Alignment.Center) {
        Text(title, Modifier.clip(RoundedCornerShape(9.dp))
            .background(if (selected) MaterialTheme.colorScheme.primary else lavender())
            .padding(horizontal = 14.dp, vertical = 5.dp), fontSize = 14.sp,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
            color = if (selected) Color.White else MaterialTheme.colorScheme.primary)
    }
}

@Composable
fun EmptyState(title: String, message: String, @DrawableRes icon: Int = R.drawable.icon_document) {
    Column(Modifier.fillMaxWidth().padding(vertical = 36.dp, horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        AppIcon(icon, null, size = 42.dp)
        Text(title, fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
        Text(message, color = MaterialTheme.colorScheme.secondary, fontSize = 14.sp,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center)
    }
}

@Composable
fun TaskRow(task: TaskItem, project: ProjectItem?, today: LocalDate, onOpen: () -> Unit, onToggle: () -> Unit) {
    val statusColor = when (task.status) {
        TaskStatus.ACTIVE -> Color(0xFF0087FF)
        TaskStatus.IN_PROGRESS -> Color(0xFFFF7D53)
        TaskStatus.COMPLETED -> MaterialTheme.colorScheme.primary
    }
    val statusBack = pastel(when (task.status) {
        TaskStatus.ACTIVE -> "sky"; TaskStatus.IN_PROGRESS -> "peach"; else -> "purple"
    })
    AppCard(onClick = onOpen) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                if (project != null) Text(project.name, fontSize = 11.sp, color = MaterialTheme.colorScheme.secondary,
                    maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text((if (task.isPinned) "📌 " else "") + task.title, fontSize = 14.sp,
                    maxLines = 2, overflow = TextOverflow.Ellipsis)
                task.dueDay?.let {
                    val overdue = it.date < today && task.status != TaskStatus.COMPLETED
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                        val color = if (overdue) Color(0xFFFF7D53) else Color(0xFFAB94FF)
                        AppIcon(R.drawable.icon_time_circle, null, color, 14.dp)
                        Text(if (it.date == today) "اليوم" else dateLabel(it.date), fontSize = 11.sp, color = color)
                    }
                }
            }
            Column(horizontalAlignment = Alignment.End) {
                if (project != null) Text(project.emoji ?: "📁", Modifier.background(pastel(project.colorKey),
                    RoundedCornerShape(7.dp)).padding(5.dp), fontSize = 14.sp)
                Box(Modifier.heightIn(min = 44.dp).clickable(role = Role.Button, onClick = onToggle)
                    .semantics { contentDescription = if (task.status == TaskStatus.COMPLETED) "إعادة فتح المهمة" else "إتمام المهمة" },
                    contentAlignment = Alignment.Center) {
                    Text(task.status.label(), Modifier.background(statusBack, RoundedCornerShape(7.dp))
                        .padding(horizontal = 9.dp, vertical = 4.dp), color = statusColor, fontSize = 10.sp)
                }
            }
        }
    }
}

@Composable
fun ProjectRow(project: ProjectItem, snapshot: AppSnapshot, onOpen: () -> Unit, onDelete: (() -> Unit)? = null) {
    AppCard(onClick = onOpen) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Text(project.emoji ?: "📁", Modifier.background(pastel(project.colorKey), RoundedCornerShape(9.dp))
                .padding(8.dp), fontSize = 18.sp)
            Column(Modifier.weight(1f)) {
                Text(project.name, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text("${snapshot.projectTasks(project.id).count { it.status != TaskStatus.COMPLETED }} مهام مفتوحة",
                    fontSize = 11.sp, color = MaterialTheme.colorScheme.secondary)
            }
            Text("${(snapshot.progress(project.id) * 100).roundToInt()}%", fontFamily = Lexend,
                color = MaterialTheme.colorScheme.primary, fontSize = 11.sp)
            if (onDelete != null) TextButton(onClick = onDelete, contentPadding = PaddingValues(4.dp)) {
                Text("حذف", fontSize = 11.sp, color = MaterialTheme.colorScheme.error)
            }
        }
    }
}

@Composable
fun AppBottomBar(selected: String, onSelect: (String) -> Unit, onAdd: () -> Unit) {
    val tint = MaterialTheme.colorScheme.primary
    BoxWithConstraints(Modifier.fillMaxWidth().navigationBarsPadding().height(78.dp)) {
        Box(Modifier.fillMaxWidth().height(56.dp).align(Alignment.BottomCenter).background(lavender(), BarShape))
        val tabs = listOf(
            Triple("home", R.drawable.icon_home_bulk, 44f),
            Triple("calendar", R.drawable.icon_calendar_bulk, 111f),
            Triple("tasks", R.drawable.icon_document, 265f),
            Triple("projects", R.drawable.icon_briefcase, 331f)
        )
        tabs.forEach { (key, resource, center) ->
            val active = selected == key
            val image = if (active && key == "home") R.drawable.icon_home_bold
                else if (active && key == "calendar") R.drawable.icon_calendar_bold else resource
            IconButton(onClick = { onSelect(key) }, modifier = Modifier
                .offset(x = maxWidth * (center / 375f) - 22.dp, y = 28.dp).size(44.dp)) {
                AppIcon(image, when (key) { "home" -> "الرئيسية"; "calendar" -> "التقويم"; "tasks" -> "مهامي"; else -> "المشاريع" },
                    if (active) tint else MaterialTheme.colorScheme.secondary)
            }
        }
        Box(Modifier.align(Alignment.TopCenter).size(44.dp)
            .shadow(10.dp, CircleShape, spotColor = tint.copy(alpha = .49f)).clip(CircleShape)
            .background(tint).clickable(role = Role.Button, onClick = onAdd)
            .semantics { contentDescription = "إضافة مهمة جديدة" }, contentAlignment = Alignment.Center) {
            AppIcon(R.drawable.icon_add, null, Color.White, 20.dp)
        }
    }
}
