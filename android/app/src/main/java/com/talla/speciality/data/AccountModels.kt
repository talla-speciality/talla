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

data class DeliveryAddress(
    val id: String,
    val label: String,
    val fullName: String,
    val phone: String,
    val line1: String,
    val city: String,
    val countryCode: String,
    val isPreferred: Boolean,
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
