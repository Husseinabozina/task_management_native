package com.husseinabozina.taskmanagement.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// ألوان الهوية — المصدر: docs/design/DESIGN_SYSTEM.md (قيم Light حرفية من الفيجما؛ الدارك مشتق مبدئيًا).
val AppPrimary = Color(0xFF5F33E1)
val AppPrimaryDark = Color(0xFF7B52F0)
val AppBackgroundLight = Color(0xFFFFFFFF)
val AppBackgroundDark = Color(0xFF161618)
val AppSurfaceLight = Color(0xFFFFFFFF)
val AppSurfaceDark = Color(0xFF232326)
val AppTextPrimaryLight = Color(0xFF24252C)
val AppTextPrimaryDark = Color(0xFFF2F2F2)
val AppTextSecondaryLight = Color(0xFF6E6A7C)
val AppTextSecondaryDark = Color(0xFFA0A0A8)
val AppLavenderLight = Color(0xFFEEE9FF)
val AppLavenderDark = Color(0xFF2A2140)

private val LightColors = lightColorScheme(
    primary = AppPrimary,
    background = AppBackgroundLight,
    surface = AppSurfaceLight,
    onPrimary = Color.White,
    onBackground = AppTextPrimaryLight,
    onSurface = AppTextPrimaryLight,
    secondary = AppTextSecondaryLight,
)

private val DarkColors = darkColorScheme(
    primary = AppPrimaryDark,
    background = AppBackgroundDark,
    surface = AppSurfaceDark,
    onPrimary = Color.White,
    onBackground = AppTextPrimaryDark,
    onSurface = AppTextPrimaryDark,
    secondary = AppTextSecondaryDark,
)

@Composable
fun TaskManagementTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        content = content
    )
}
