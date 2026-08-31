package com.talla.speciality.data

import com.talla.speciality.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

data class HomeSettings(
    val signatureRoastProductIds: List<String> = emptyList(),
    val quickDrinkProductIds: List<String> = emptyList(),
    val funPickProductId: String? = null,
    val heroEyebrow: String? = null,
    val heroTitle: String? = null,
    val heroSubtitle: String? = null,
    val heroBadge: String? = null,
    val primaryButtonTitle: String? = null,
    val secondaryButtonTitle: String? = null,
)

data class TallaAnnouncement(
    val enabled: Boolean = false,
    val title: String = "",
    val message: String = "",
    val actionLabel: String = "",
    val actionUrl: String = "",
)

data class HomeSectionSettings(
    val showQuickDrinks: Boolean = true,
    val showFunPick: Boolean = true,
    val showSignatureRoasts: Boolean = true,
    val showPassport: Boolean = true,
)

data class TallaAppSettings(
    val announcement: TallaAnnouncement = TallaAnnouncement(),
    val homeSections: HomeSectionSettings = HomeSectionSettings(),
)

data class SeasonalEvent(
    val id: String,
    val titleEn: String,
    val titleAr: String,
    val subtitleEn: String,
    val subtitleAr: String,
    val badgeEn: String,
    val badgeAr: String,
    val ctaEn: String,
    val ctaAr: String,
    val imageUrl: String,
    val accentHex: String,
    val secondaryHex: String,
    val productIds: List<String>,
)

data class TallaRemoteSettings(
    val home: HomeSettings = HomeSettings(),
    val app: TallaAppSettings = TallaAppSettings(),
    val events: List<SeasonalEvent> = emptyList(),
)

class TallaRemoteSettingsRepository {
    suspend fun fetch(): TallaRemoteSettings = withContext(Dispatchers.IO) {
        TallaRemoteSettings(
            home = parseHome(get("/app/home-settings")),
            app = parseApp(get("/app/settings")),
            events = parseEvents(get("/app/events")),
        )
    }

    private fun get(path: String): JSONObject {
        require(BuildConfig.BACKEND_URL.isNotBlank()) { "Talla backend URL is not configured" }
        val connection = URL(BuildConfig.BACKEND_URL.trimEnd('/') + path).openConnection() as HttpURLConnection
        return try {
            connection.requestMethod = "GET"
            connection.connectTimeout = 15_000
            connection.readTimeout = 20_000
            connection.setRequestProperty("Accept", "application/json")
            val stream = if (connection.responseCode in 200..299) connection.inputStream else connection.errorStream
            val payload = stream.bufferedReader().use { it.readText() }
            if (connection.responseCode !in 200..299) error("Talla returned ${connection.responseCode}")
            JSONObject(payload)
        } finally {
            connection.disconnect()
        }
    }

    private fun parseHome(json: JSONObject) = HomeSettings(
        signatureRoastProductIds = json.stringList("signatureRoastProductIDs"),
        quickDrinkProductIds = json.stringList("quickDrinkProductIDs"),
        funPickProductId = json.optionalText("funPickProductID"),
        heroEyebrow = json.optionalText("heroEyebrow"),
        heroTitle = json.optionalText("heroTitle"),
        heroSubtitle = json.optionalText("heroSubtitle"),
        heroBadge = json.optionalText("heroBadge"),
        primaryButtonTitle = json.optionalText("primaryButtonTitle"),
        secondaryButtonTitle = json.optionalText("secondaryButtonTitle"),
    )

    private fun parseApp(json: JSONObject): TallaAppSettings {
        val announcement = json.optJSONObject("announcement") ?: JSONObject()
        val sections = json.optJSONObject("homeSections") ?: JSONObject()
        return TallaAppSettings(
            announcement = TallaAnnouncement(
                enabled = announcement.optBoolean("enabled"),
                title = announcement.optString("title"),
                message = announcement.optString("message"),
                actionLabel = announcement.optString("actionLabel"),
                actionUrl = announcement.optString("actionURL"),
            ),
            homeSections = HomeSectionSettings(
                showQuickDrinks = sections.optBoolean("showQuickDrinks", true),
                showFunPick = sections.optBoolean("showFunPick", true),
                showSignatureRoasts = sections.optBoolean("showSignatureRoasts", true),
                showPassport = sections.optBoolean("showPassport", true),
            ),
        )
    }

    private fun parseEvents(json: JSONObject): List<SeasonalEvent> = buildList {
        val events = json.optJSONArray("events") ?: return@buildList
        for (index in 0 until events.length()) {
            val event = events.optJSONObject(index) ?: continue
            add(
                SeasonalEvent(
                    id = event.optString("id", index.toString()),
                    titleEn = event.optString("titleEN"),
                    titleAr = event.optString("titleAR"),
                    subtitleEn = event.optString("subtitleEN"),
                    subtitleAr = event.optString("subtitleAR"),
                    badgeEn = event.optString("badgeEN"),
                    badgeAr = event.optString("badgeAR"),
                    ctaEn = event.optString("ctaEN"),
                    ctaAr = event.optString("ctaAR"),
                    imageUrl = event.optString("imageURL"),
                    accentHex = event.optString("accentHex", "#C8965A"),
                    secondaryHex = event.optString("secondaryHex", "#2A1D14"),
                    productIds = event.stringList("productIDs"),
                )
            )
        }
    }
}

private fun JSONObject.optionalText(key: String): String? =
    optString(key).trim().takeIf(String::isNotEmpty)

private fun JSONObject.stringList(key: String): List<String> = buildList {
    val values = optJSONArray(key) ?: return@buildList
    for (index in 0 until values.length()) {
        values.optString(index).trim().takeIf(String::isNotEmpty)?.let(::add)
    }
}
