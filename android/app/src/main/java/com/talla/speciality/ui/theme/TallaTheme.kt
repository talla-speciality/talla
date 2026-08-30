package com.talla.speciality.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Sand = Color(0xFFC8965A)
val Coffee = Color(0xFF714626)
val Cream = Color(0xFFF8F3EA)
val Ink = Color(0xFF241A13)
val Sage = Color(0xFF5E6F5B)

private val LightColors = lightColorScheme(
    primary = Coffee,
    onPrimary = Color.White,
    secondary = Sand,
    background = Cream,
    surface = Color(0xFFFFFBF5),
    onBackground = Ink,
    onSurface = Ink,
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFFE1B780),
    secondary = Sand,
    background = Color(0xFF17120F),
    surface = Color(0xFF211A16),
)

@Composable
fun TallaTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors,
        content = content,
    )
}
