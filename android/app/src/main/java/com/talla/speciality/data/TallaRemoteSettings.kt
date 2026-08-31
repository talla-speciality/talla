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

data class PassportOrigin(
    val id: String,
    val title: String,
    val emoji: String,
    val keywords: List<String>,
    val rewardLabel: String?,
)

data class PassportSettings(
    val origins: List<PassportOrigin> = emptyList(),
    val completionRewardTitle: String? = null,
    val completionRewardDetail: String? = null,
)

data class PaymentSettings(
    val benefitPayEnabled: Boolean = true,
    val benefitEnabled: Boolean = true,
    val cardEnabled: Boolean = true,
    val cashOnDeliveryEnabled: Boolean = true,
    val noticeEn: String = "",
    val noticeAr: String = "",
)

data class FulfillmentSettings(
    val deliveryEnabled: Boolean = true,
    val pickupEnabled: Boolean = true,
    val pickupNameEn: String = "Talla, Riffa",
    val pickupNameAr: String = "تالة، الرفاع",
    val pickupAddressEn: String = "Villa 336, Street 1307, Riffa 913",
    val pickupAddressAr: String = "فيلا 336، طريق 1307، الرفاع 913",
    val openingHoursEn: String = "",
    val openingHoursAr: String = "",
)

data class SupportSettings(
    val whatsappUrl: String = "https://wa.me/97339392414",
    val privacyUrl: String = "",
    val termsUrl: String = "",
)

data class ReleaseSettings(
    val maintenanceEnabled: Boolean = false,
    val checkoutMaintenanceEnabled: Boolean = false,
    val titleEn: String = "We'll be right back",
    val titleAr: String = "سنعود قريباً",
    val messageEn: String = "Talla is being updated. Please try again shortly.",
    val messageAr: String = "يتم تحديث تالة. يرجى المحاولة بعد قليل.",
)

data class TallaAppSettings(
    val announcement: TallaAnnouncement = TallaAnnouncement(),
    val homeSections: HomeSectionSettings = HomeSectionSettings(),
    val payments: PaymentSettings = PaymentSettings(),
    val fulfillment: FulfillmentSettings = FulfillmentSettings(),
    val support: SupportSettings = SupportSettings(),
    val release: ReleaseSettings = ReleaseSettings(),
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
    val passport: PassportSettings = PassportSettings(),
)

class TallaRemoteSettingsRepository {
    suspend fun fetch(): TallaRemoteSettings = withContext(Dispatchers.IO) {
        TallaRemoteSettings(
            home = parseHome(get("/app/home-settings")),
            app = parseApp(get("/app/settings")),
            events = parseEvents(get("/app/events")),
            passport = parsePassport(get("/app/passport-settings")),
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
        val payments = json.optJSONObject("payments") ?: JSONObject()
        val fulfillment = json.optJSONObject("fulfillment") ?: JSONObject()
        val support = json.optJSONObject("support") ?: JSONObject()
        val release = json.optJSONObject("release") ?: JSONObject()
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
            payments = PaymentSettings(
                benefitPayEnabled = payments.optBoolean("benefitPayEnabled", true),
                benefitEnabled = payments.optBoolean("benefitEnabled", true),
                cardEnabled = payments.optBoolean("cardEnabled", true),
                cashOnDeliveryEnabled = payments.optBoolean("cashOnDeliveryEnabled", true),
                noticeEn = payments.optString("noticeEN"),
                noticeAr = payments.optString("noticeAR"),
            ),
            fulfillment = FulfillmentSettings(
                deliveryEnabled = fulfillment.optBoolean("deliveryEnabled", true),
                pickupEnabled = fulfillment.optBoolean("pickupEnabled", true),
                pickupNameEn = fulfillment.optString("pickupNameEN", "Talla, Riffa"),
                pickupNameAr = fulfillment.optString("pickupNameAR", "تالة، الرفاع"),
                pickupAddressEn = fulfillment.optString("pickupAddressEN", "Villa 336, Street 1307, Riffa 913"),
                pickupAddressAr = fulfillment.optString("pickupAddressAR", "فيلا 336، طريق 1307، الرفاع 913"),
                openingHoursEn = fulfillment.optString("openingHoursEN"),
                openingHoursAr = fulfillment.optString("openingHoursAR"),
            ),
            support = SupportSettings(
                whatsappUrl = support.optString("whatsappURL", "https://wa.me/97339392414"),
                privacyUrl = support.optString("privacyURL"),
                termsUrl = support.optString("termsURL"),
            ),
            release = ReleaseSettings(
                maintenanceEnabled = release.optBoolean("maintenanceEnabled"),
                checkoutMaintenanceEnabled = release.optBoolean("checkoutMaintenanceEnabled"),
                titleEn = release.optString("titleEN", "We'll be right back"),
                titleAr = release.optString("titleAR", "سنعود قريباً"),
                messageEn = release.optString("messageEN", "Talla is being updated. Please try again shortly."),
                messageAr = release.optString("messageAR", "يتم تحديث تالة. يرجى المحاولة بعد قليل."),
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

    private fun parsePassport(json: JSONObject): PassportSettings {
        val origins = buildList {
            val values = json.optJSONArray("origins") ?: return@buildList
            for (index in 0 until values.length()) {
                val origin = values.optJSONObject(index) ?: continue
                add(
                    PassportOrigin(
                        id = origin.optString("id", index.toString()),
                        title = origin.optString("title"),
                        emoji = origin.optString("emoji", "☕"),
                        keywords = origin.stringList("keywords"),
                        rewardLabel = origin.optionalText("rewardLabel"),
                    )
                )
            }
        }
        return PassportSettings(
            origins = origins,
            completionRewardTitle = json.optionalText("completionRewardTitle"),
            completionRewardDetail = json.optionalText("completionRewardDetail"),
        )
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
