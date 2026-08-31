package com.talla.speciality.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.edit
import androidx.core.net.toUri
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider as DayNightColorProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.talla.speciality.MainActivity

data class TallaWidgetSnapshot(
    val signedIn: Boolean = false,
    val loyaltyPoints: Int = 0,
    val loyaltyTier: String = "",
    val loyaltyNextReward: String = "",
    val favoriteCount: Int = 0,
    val recentCount: Int = 0,
    val bagCount: Int = 0,
    val brewCount: Int = 0,
)

object TallaWidgetStateStore {
    private const val PREFERENCES = "talla_widget"
    private const val SIGNED_IN = "signed_in"
    private const val POINTS = "points"
    private const val TIER = "tier"
    private const val NEXT_REWARD = "next_reward"
    private const val FAVORITES = "favorites"
    private const val RECENT = "recent"
    private const val BAG = "bag"
    private const val BREWS = "brews"

    fun save(context: Context, snapshot: TallaWidgetSnapshot) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit {
            putBoolean(SIGNED_IN, snapshot.signedIn)
            putInt(POINTS, snapshot.loyaltyPoints)
            putString(TIER, snapshot.loyaltyTier)
            putString(NEXT_REWARD, snapshot.loyaltyNextReward)
            putInt(FAVORITES, snapshot.favoriteCount)
            putInt(RECENT, snapshot.recentCount)
            putInt(BAG, snapshot.bagCount)
            putInt(BREWS, snapshot.brewCount)
        }
    }

    fun read(context: Context): TallaWidgetSnapshot {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        return TallaWidgetSnapshot(
            signedIn = preferences.getBoolean(SIGNED_IN, false),
            loyaltyPoints = preferences.getInt(POINTS, 0),
            loyaltyTier = preferences.getString(TIER, "").orEmpty(),
            loyaltyNextReward = preferences.getString(NEXT_REWARD, "").orEmpty(),
            favoriteCount = preferences.getInt(FAVORITES, 0),
            recentCount = preferences.getInt(RECENT, 0),
            bagCount = preferences.getInt(BAG, 0),
            brewCount = preferences.getInt(BREWS, 0),
        )
    }
}

class TallaQuickActionsWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val state = TallaWidgetStateStore.read(context)
        provideContent { TallaWidgetContent(state) }
    }
}

class TallaWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TallaQuickActionsWidget()
}

@Composable
private fun TallaWidgetContent(state: TallaWidgetSnapshot) {
    val context = LocalContext.current
    val isArabic = context.resources.configuration.locales[0].language == "ar"
    val wide = LocalSize.current.width >= 240.dp
    val foreground = DayNightColorProvider(Color(0xFF2A190F), Color(0xFFFFEACC))
    val secondary = DayNightColorProvider(Color(0xFF725541), Color(0xFFD8B997))
    val panel = DayNightColorProvider(Color(0xFFF5E7D4), Color(0xFF2A211B))

    Column(
        modifier = GlanceModifier.fillMaxSize().background(panel).padding(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text("TALLA", style = TextStyle(color = foreground, fontSize = 19.sp, fontWeight = FontWeight.Bold))
                Text(
                    if (state.signedIn) {
                        val tier = state.loyaltyTier.ifBlank { if (isArabic) "عضو تالا" else "Talla member" }
                        if (isArabic) "${state.loyaltyPoints} حبة · $tier" else "${state.loyaltyPoints} Beans · $tier"
                    } else if (isArabic) "سجّل الدخول للـ Beans" else "Sign in for Beans",
                    style = TextStyle(color = secondary, fontSize = 12.sp, fontWeight = FontWeight.Medium),
                    maxLines = 1,
                )
            }
            WidgetAction(context, if (isArabic) "المكافآت" else "Rewards", "rewards", foreground)
        }

        Spacer(GlanceModifier.height(14.dp))

        if (wide) {
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                WidgetStat(if (isArabic) "الرف" else "Shelf", state.favoriteCount, foreground, secondary, GlanceModifier.defaultWeight())
                WidgetStat(if (isArabic) "الأخيرة" else "Recent", state.recentCount, foreground, secondary, GlanceModifier.defaultWeight())
                WidgetStat(if (isArabic) "السلة" else "Bag", state.bagCount, foreground, secondary, GlanceModifier.defaultWeight())
                WidgetStat(if (isArabic) "التحضير" else "Brews", state.brewCount, foreground, secondary, GlanceModifier.defaultWeight())
            }
            Spacer(GlanceModifier.height(12.dp))
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                WidgetAction(context, if (isArabic) "تسوق القهوة" else "Shop coffee", "shop", foreground, GlanceModifier.defaultWeight())
                Spacer(GlanceModifier.width(10.dp))
                WidgetAction(context, if (isArabic) "ابدأ التحضير" else "Start brewing", "brewing", foreground, GlanceModifier.defaultWeight())
            }
        } else {
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                WidgetStat(if (isArabic) "الرف" else "Shelf", state.favoriteCount, foreground, secondary, GlanceModifier.defaultWeight())
                WidgetStat(if (isArabic) "السلة" else "Bag", state.bagCount, foreground, secondary, GlanceModifier.defaultWeight())
                WidgetStat(if (isArabic) "التحضير" else "Brews", state.brewCount, foreground, secondary, GlanceModifier.defaultWeight())
            }
            Spacer(GlanceModifier.height(12.dp))
            WidgetAction(context, if (isArabic) "تسوق القهوة" else "Shop coffee", "shop", foreground, GlanceModifier.fillMaxWidth())
        }

        if (state.signedIn && state.loyaltyNextReward.isNotBlank()) {
            Spacer(GlanceModifier.height(8.dp))
            Text(state.loyaltyNextReward, style = TextStyle(color = secondary, fontSize = 10.sp), maxLines = 1)
        }
    }
}

@Composable
private fun WidgetStat(
    label: String,
    value: Int,
    foreground: ColorProvider,
    secondary: ColorProvider,
    modifier: GlanceModifier,
) {
    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value.toString(), style = TextStyle(color = foreground, fontSize = 17.sp, fontWeight = FontWeight.Bold))
        Text(label, style = TextStyle(color = secondary, fontSize = 10.sp), maxLines = 1)
    }
}

@Composable
private fun WidgetAction(
    context: Context,
    label: String,
    destination: String,
    foreground: ColorProvider,
    modifier: GlanceModifier = GlanceModifier,
) {
    val intent = Intent(Intent.ACTION_VIEW, "talla://$destination".toUri(), context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
    }
    Box(
        modifier = modifier
            .background(DayNightColorProvider(Color(0xFFD4A96A), Color(0xFF8F6538)))
            .clickable(actionStartActivity(intent))
            .padding(horizontal = 12.dp, vertical = 9.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, style = TextStyle(color = foreground, fontSize = 11.sp, fontWeight = FontWeight.Bold), maxLines = 1)
    }
}
