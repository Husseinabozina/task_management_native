package com.husseinabozina.taskmanagement.ui

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.*
import com.husseinabozina.taskmanagement.domain.TaskStatus
import com.husseinabozina.taskmanagement.ui.theme.Lexend
import java.time.*
import java.time.format.DateTimeFormatter
import java.util.Calendar
import java.util.Locale

@Composable
fun CalendarScreen(snapshot: AppSnapshot, onDay: (LocalDate) -> Unit) {
    var monthValue by rememberSaveable { mutableStateOf(YearMonth.from(snapshot.today).toString()) }
    val month = YearMonth.parse(monthValue)
    val deviceFirst = remember { Calendar.getInstance(Locale.getDefault()).firstDayOfWeek }
    val firstDayIso = ((deviceFirst + 5) % 7) + 1
    val first = month.atDay(1)
    val gridStart = first.minusDays(((first.dayOfWeek.value - firstDayIso + 7) % 7).toLong())
    val counts = snapshot.tasks.filter { it.status != TaskStatus.COMPLETED && it.dueDay != null }
        .groupingBy { it.dueDay!!.date }.eachCount()
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(22.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)) {
        SectionHeading("التقويم")
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = { monthValue = month.minusMonths(1).toString() }) { Text("السابق") }
            Text(first.format(DateTimeFormatter.ofPattern("MMMM yyyy", Arabic)), Modifier.weight(1f),
                fontSize = 19.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
            TextButton(onClick = { monthValue = month.plusMonths(1).toString() }) { Text("التالي") }
        }
        Row(Modifier.fillMaxWidth()) {
            repeat(7) { column ->
                val day = gridStart.plusDays(column.toLong())
                Text(day.format(DateTimeFormatter.ofPattern("EEEEE", Arabic)), Modifier.weight(1f),
                    textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.secondary, fontSize = 12.sp)
            }
        }
        repeat(6) { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                repeat(7) { col ->
                    val day = gridStart.plusDays((row * 7 + col).toLong())
                    val isToday = day == snapshot.today
                    val inMonth = YearMonth.from(day) == month
                    val count = counts[day] ?: 0
                    val shape = RoundedCornerShape(11.dp)
                    Column(Modifier.weight(1f).height(64.dp).background(
                        if (isToday) lavender() else MaterialTheme.colorScheme.surface, shape)
                        .border(if (isToday) 1.dp else 0.dp,
                            if (isToday) MaterialTheme.colorScheme.primary else Color.Transparent, shape)
                        .clickable(role = Role.Button, onClick = { onDay(day) }).semantics {
                            contentDescription = "${day.format(DateTimeFormatter.ofPattern("EEEE، d MMMM yyyy", Arabic))}، $count مهام مفتوحة"
                        }, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                        Text("${day.dayOfMonth}", fontFamily = Lexend, fontSize = 14.sp,
                            color = if (inMonth) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.secondary.copy(alpha = .45f))
                        if (count > 0) Text("$count", Modifier.background(lavender(), CircleShape)
                            .padding(horizontal = 5.dp), fontSize = 9.sp, fontFamily = Lexend,
                            color = MaterialTheme.colorScheme.primary)
                    }
                }
            }
        }
        Text("اختر يومًا لعرض مهامه", fontSize = 14.sp, color = MaterialTheme.colorScheme.secondary)
        TextButton(onClick = { monthValue = YearMonth.from(snapshot.today).toString() }) { Text("الشهر الحالي") }
    }
}
