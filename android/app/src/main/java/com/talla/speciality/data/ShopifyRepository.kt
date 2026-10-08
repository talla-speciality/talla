package com.talla.speciality.data

import com.talla.speciality.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Locale

class ShopifyRepository {
    suspend fun products(): List<Product> = withContext(Dispatchers.IO) {
        val query = """
            query TallaProducts(${'$'}cursor: String, ${'$'}language: LanguageCode!) @inContext(language: ${'$'}language) {
              products(first: 100, after: ${'$'}cursor, sortKey: CREATED_AT, reverse: true) {
                pageInfo { hasNextPage endCursor }
                edges {
                  node {
                    id handle title description productType tags
                    featuredImage { url }
                    images(first: 12) { nodes { url } }
                    variants(first: 50) {
                      edges { node {
                        id title availableForSale requiresShipping weight weightUnit
                        price { amount currencyCode }
                      } }
                    }
                  }
                }
              }
            }
        """.trimIndent()

        buildList {
            var cursor: String? = null
            do {
                val language = androidx.appcompat.app.AppCompatDelegate.getApplicationLocales().get(0)?.language ?: Locale.getDefault().language
                val variables = JSONObject().apply { put("cursor", cursor); put("language", if (language == "ar") "AR" else "EN") }
                val response = request(JSONObject().put("query", query).put("variables", variables))
                val products = response.getJSONObject("data").getJSONObject("products")
                val edges = products.getJSONArray("edges")
                for (index in 0 until edges.length()) add(parseProduct(edges.getJSONObject(index).getJSONObject("node")))
                val pageInfo = products.getJSONObject("pageInfo")
                cursor = pageInfo.optString("endCursor").takeIf { pageInfo.getBoolean("hasNextPage") && it.isNotBlank() }
            } while (cursor != null)
        }.filter { it.variants.isNotEmpty() }
    }

    suspend fun checkoutUrl(
        lines: List<CartLine>,
        fulfillmentMethod: String,
        customerEmail: String? = null,
        address: DeliveryAddress? = null,
    ): String = withContext(Dispatchers.IO) {
        require(lines.isNotEmpty()) { "Your bag is empty" }
        val inputLines = org.json.JSONArray().apply {
            lines.forEach { line ->
                put(JSONObject().put("merchandiseId", line.variant.id).put("quantity", line.quantity))
            }
        }
        val attributes = org.json.JSONArray()
            .put(JSONObject().put("key", "talla_fulfillment_method").put("value", fulfillmentMethod))
            .put(JSONObject().put("key", "talla_payment_method").put("value", "cash_on_delivery"))
        val input = JSONObject().put("lines", inputLines).put("attributes", attributes)
        val buyerIdentity = JSONObject()
        customerEmail?.takeIf(String::isNotBlank)?.let { buyerIdentity.put("email", it) }
        if (fulfillmentMethod == "delivery" && address != null) {
            val names = address.fullName.trim().split(Regex("\\s+"), limit = 2)
            val deliveryAddress = JSONObject()
                .put("address1", address.line1)
                .put("city", address.city)
                .put("countryCode", address.countryCode)
                .put("firstName", names.firstOrNull().orEmpty())
                .put("lastName", names.getOrNull(1).orEmpty())
                .put("phone", address.phone)
            buyerIdentity.put("deliveryAddressPreferences", JSONArray().put(JSONObject().put("deliveryAddress", deliveryAddress)))
        }
        if (buyerIdentity.length() > 0) input.put("buyerIdentity", buyerIdentity)
        val mutation = """
            mutation CreateCart(${'$'}input: CartInput, ${'$'}language: LanguageCode!) @inContext(language: ${'$'}language) {
              cartCreate(input: ${'$'}input) {
                cart { checkoutUrl }
                userErrors { message }
              }
            }
        """.trimIndent()
        val language = androidx.appcompat.app.AppCompatDelegate.getApplicationLocales().get(0)?.language ?: Locale.getDefault().language
        val response = request(JSONObject().put("query", mutation).put("variables", JSONObject().put("input", input).put("language", if (language == "ar") "AR" else "EN")))
        val payload = response.getJSONObject("data").getJSONObject("cartCreate")
        val errors = payload.getJSONArray("userErrors")
        if (errors.length() > 0) error(errors.getJSONObject(0).optString("message", "Unable to create checkout"))
        payload.optJSONObject("cart")?.optString("checkoutUrl")?.takeIf(String::isNotBlank)
            ?: error("Shopify did not return a checkout URL")
    }

    private fun request(body: JSONObject): JSONObject {
        val endpoint = URL("https://${BuildConfig.SHOP_DOMAIN}/api/2025-10/graphql.json")
        val connection = endpoint.openConnection() as HttpURLConnection
        return try {
            connection.requestMethod = "POST"
            connection.connectTimeout = 15_000
            connection.readTimeout = 20_000
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("X-Shopify-Storefront-Access-Token", BuildConfig.STOREFRONT_TOKEN)
            connection.outputStream.use { it.write(body.toString().toByteArray()) }
            val stream = if (connection.responseCode in 200..299) connection.inputStream else connection.errorStream
            val payload = stream.bufferedReader().use { it.readText() }
            if (connection.responseCode !in 200..299) error("Shopify returned ${connection.responseCode}")
            JSONObject(payload).also { json ->
                if (json.has("errors")) error(json.getJSONArray("errors").optJSONObject(0)?.optString("message") ?: "Shopify request failed")
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun parseProduct(node: JSONObject): Product {
        val variantEdges = node.getJSONObject("variants").getJSONArray("edges")
        val variants = buildList {
            for (index in 0 until variantEdges.length()) {
                val variant = variantEdges.getJSONObject(index).getJSONObject("node")
                val money = variant.getJSONObject("price")
                add(
                    ProductVariant(
                        id = variant.getString("id"),
                        title = variant.getString("title"),
                        price = money.getString("amount"),
                        currencyCode = money.getString("currencyCode"),
                        available = variant.optBoolean("availableForSale"),
                        requiresShipping = variant.optBoolean("requiresShipping"),
                        weightGrams = normalizedWeight(variant.optDouble("weight", Double.NaN), variant.optString("weightUnit")),
                    )
                )
            }
        }
        val featuredImageUrl = node.optJSONObject("featuredImage")?.optString("url")?.takeIf(String::isNotBlank)
        val imageUrls = buildList {
            featuredImageUrl?.let(::add)
            val images = node.optJSONObject("images")?.optJSONArray("nodes") ?: JSONArray()
            for (index in 0 until images.length()) {
                images.optJSONObject(index)?.optString("url")?.takeIf(String::isNotBlank)?.let(::add)
            }
        }.distinct()
        val tags = node.optJSONArray("tags") ?: JSONArray()
        val roastDate = (0 until tags.length()).asSequence()
            .map { tags.optString(it) }
            .firstOrNull { it.startsWith("Talla Roast Date:", ignoreCase = true) }
            ?.substringAfter(':')?.trim()
            ?.let { value ->
                listOf("yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy").firstNotNullOfOrNull { format ->
                    runCatching { SimpleDateFormat(format, Locale.US).parse(value)?.time }.getOrNull()
                }
            }
        return Product(
            id = node.getString("id"),
            handle = node.getString("handle"),
            name = node.getString("title"),
            description = node.optString("description"),
            imageUrl = featuredImageUrl,
            imageUrls = imageUrls,
            category = if (Regex("arabic.?coffee|qahwa|gahwa|shamali|قهوة عربية|قهوة خليجية", RegexOption.IGNORE_CASE)
                .containsMatchIn(node.optString("title") + " " + node.optString("productType") + " " + tags.toString())) "Arabic Coffee · القهوة العربية"
                else node.optString("productType").ifBlank { "Coffee" },
            variants = variants,
            roastDate = roastDate,
        )
    }

    private fun normalizedWeight(value: Double, unit: String): Double? {
        if (!value.isFinite() || value <= 0) return null
        return when (unit.uppercase()) {
            "KILOGRAMS" -> value * 1_000
            "POUNDS" -> value * 453.59237
            "OUNCES" -> value * 28.349523125
            else -> value
        }
    }
}
