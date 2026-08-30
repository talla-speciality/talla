package com.talla.speciality.data

object ShippingRules {
    private val gccCountries = setOf("SA", "KW", "AE", "QA", "OM")

    fun rateBhd(countryCode: String, weightGrams: Double, cashOnDelivery: Boolean = false): Double? {
        val country = countryCode.trim().uppercase()
        if (country == "BH") return 2.0
        if (country !in gccCountries) return null
        if (weightGrams <= 0 || weightGrams > 4_000) return null

        val halfKiloBands = kotlin.math.ceil(weightGrams / 500.0).toInt().coerceIn(1, 8)
        val base = 4.5 + halfKiloBands
        return base + if (cashOnDelivery) 2.0 else 0.0
    }
}
