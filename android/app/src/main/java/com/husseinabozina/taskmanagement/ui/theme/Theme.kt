package com.husseinabozina.taskmanagement.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.husseinabozina.taskmanagement.R
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

val Cairo = FontFamily(
    Font(R.font.cairo_regular, FontWeight.Normal),
    Font(R.font.cairo_semibold, FontWeight.SemiBold)
)
val Lexend = FontFamily(
    Font(R.font.lexenddeca_regular, FontWeight.Normal),
    Font(R.font.lexenddeca_semibold, FontWeight.SemiBold)
)
private val BaseTypography = Typography()
private val AppTypography = Typography(
    displayLarge = BaseTypography.displayLarge.copy(fontFamily = Cairo),
    displayMedium = BaseTypography.displayMedium.copy(fontFamily = Cairo),
    displaySmall = BaseTypography.displaySmall.copy(fontFamily = Cairo),
    headlineLarge = BaseTypography.headlineLarge.copy(fontFamily = Cairo),
    headlineMedium = BaseTypography.headlineMedium.copy(fontFamily = Cairo),
    headlineSmall = BaseTypography.headlineSmall.copy(fontFamily = Cairo),
    titleLarge = BaseTypography.titleLarge.copy(fontFamily = Cairo),
    titleMedium = BaseTypography.titleMedium.copy(fontFamily = Cairo),
    titleSmall = BaseTypography.titleSmall.copy(fontFamily = Cairo),
    bodyLarge = BaseTypography.bodyLarge.copy(fontFamily = Cairo),
    bodyMedium = BaseTypography.bodyMedium.copy(fontFamily = Cairo),
    bodySmall = BaseTypography.bodySmall.copy(fontFamily = Cairo),
    labelLarge = BaseTypography.labelLarge.copy(fontFamily = Cairo),
    labelMedium = BaseTypography.labelMedium.copy(fontFamily = Cairo),
    labelSmall = BaseTypography.labelSmall.copy(fontFamily = Cairo)
)

@Composable
fun TaskManagementTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography = AppTypography,
        content = content
    )
}
