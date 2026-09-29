package com.talla.speciality.data

data class Product(
    val id: String,
    val handle: String,
    val name: String,
    val description: String,
    val imageUrl: String?,
    val imageUrls: List<String> = imageUrl?.let(::listOf) ?: emptyList(),
    val category: String,
    val variants: List<ProductVariant>,
    val roastDate: Long? = null,
) {
    val defaultVariant: ProductVariant? get() = variants.firstOrNull { it.available } ?: variants.firstOrNull()
    val priceLabel: String get() = defaultVariant?.let { "${it.currencyCode} ${it.price}" } ?: "Unavailable"
}

data class ProductVariant(
    val id: String,
    val title: String,
    val price: String,
    val currencyCode: String,
    val available: Boolean,
    val requiresShipping: Boolean,
    val weightGrams: Double?,
)

data class CoffeeTasteProfile(
    val acidity: String = "balanced",
    val sweetness: String = "sweet",
    val body: String = "balanced",
    val roast: String = "medium",
    val temperature: String = "hot",
    val style: String = "modern",
    val configured: Boolean = false,
)

data class BrewLaunchRequest(
    val coffeeName: String,
    val method: String,
    val doseGrams: Int = 20,
    val ratio: Double = 15.0,
)

data class CartLine(
    val product: Product,
    val variant: ProductVariant,
    val quantity: Int,
)
