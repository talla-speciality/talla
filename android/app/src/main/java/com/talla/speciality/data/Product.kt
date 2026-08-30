package com.talla.speciality.data

data class Product(
    val id: String,
    val handle: String,
    val name: String,
    val description: String,
    val imageUrl: String?,
    val category: String,
    val variants: List<ProductVariant>,
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

data class CartLine(
    val product: Product,
    val variant: ProductVariant,
    val quantity: Int,
)
