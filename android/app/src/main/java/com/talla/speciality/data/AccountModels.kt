package com.talla.speciality.data

data class AccountProfile(val id: String, val firstName: String, val lastName: String, val email: String)

data class LoyaltyAccount(
    val memberId: String,
    val pointsBalance: Int,
    val tier: String,
    val nextReward: String,
    val perks: List<String>,
)

data class CustomerOrder(
    val id: String,
    val title: String,
    val total: Double,
    val status: String,
    val createdAt: String,
    val items: List<OrderItem> = emptyList(),
)

data class OrderItem(val name: String, val quantity: Int)

data class AddressDetails(
    val region: String? = null,
    val district: String? = null,
    val block: String? = null,
    val building: String? = null,
    val unit: String? = null,
    val postalCode: String? = null,
    val additionalNumber: String? = null,
    val landmark: String? = null,
)

data class DeliveryAddress(
    val id: String,
    val label: String,
    val fullName: String,
    val phone: String,
    val line1: String,
    val city: String,
    val countryCode: String,
    val isPreferred: Boolean,
    val details: AddressDetails? = null,
)

data class AccountSession(
    val profile: AccountProfile,
    val accessToken: String,
    val refreshToken: String,
    val expiresAt: String,
    val refreshExpiresAt: String,
)

data class AccountTokens(
    val accessToken: String,
    val refreshToken: String,
    val expiresAt: String,
    val refreshExpiresAt: String,
)

data class Voucher(
    val code: String,
    val reward: String,
    val points: Int,
    val detail: String,
    val expiresAt: String,
)

data class StockAlert(
    val productId: String,
    val productName: String,
    val available: Boolean,
    val status: String,
)

data class TasteMemoryRecord(
    val id: String,
    val orderId: String,
    val productName: String,
    val reaction: String,
    val tags: List<String>,
    val createdAt: String,
    val updatedAt: String,
)

data class NextCupRecommendation(
    val productId: String,
    val title: String,
    val price: String?,
    val availableForSale: Boolean,
    val imageUrl: String?,
    val score: Int,
    val reasons: List<String>,
    val summary: String,
    val actions: List<String>,
)

data class NextCupRecommendationResponse(
    val action: String,
    val headline: String,
    val recommendations: List<NextCupRecommendation>,
    val lovedSignals: List<String>,
    val avoidedSignals: List<String>,
    val freshnessState: String,
    val freshnessDays: Int?,
    val coffeeInsights: CoffeeInsights? = null,
)

data class CoffeeInsights(val reorder: List<CoffeeReorder> = emptyList())
data class CoffeeReorder(
    val productId: String?,
    val productName: String,
    val estimatedBrews: Int,
    val reason: String,
)

data class GulfCoffeeOffering(
    val id: String,
    val name: String,
    val detail: String,
    val kind: String,
    val brewMethod: String? = null,
    val brewTip: String? = null,
)

data class GulfCoffeeEvent(
    val id: String,
    val title: String,
    val kind: String,
    val startsAt: String,
    val url: String? = null,
)

data class GulfCoffeePlace(
    val id: String,
    val name: String,
    val city: String,
    val country: String,
    val neighborhood: String,
    val address: String,
    val categories: List<String>,
    val tags: List<String>,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val verificationStatus: String = "",
    val verifiedAt: String? = null,
    val lastCheckedAt: String? = null,
    val description: String = "",
    val tastingNotes: String = "",
    val offerings: List<GulfCoffeeOffering> = emptyList(),
    val events: List<GulfCoffeeEvent> = emptyList(),
)
