package com.talla.speciality.data

import com.talla.speciality.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class ShopifyRepository {
    suspend fun products(): List<Product> = withContext(Dispatchers.IO) {
        val query = """
            query TallaProducts(${'$'}cursor: String) {
              products(first: 100, after: ${'$'}cursor, sortKey: CREATED_AT, reverse: true) {
                pageInfo { hasNextPage endCursor }
                edges {
                  node {
                    id handle title description productType tags
                    featuredImage { url }
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
                val variables = JSONObject().apply { put("cursor", cursor) }
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
            mutation CreateCart(${'$'}input: CartInput) {
              cartCreate(input: ${'$'}input) {
                cart { checkoutUrl }
                userErrors { message }
              }
            }
        """.trimIndent()
        val response = request(JSONObject().put("query", mutation).put("variables", JSONObject().put("input", input)))
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
        return Product(
            id = node.getString("id"),
            handle = node.getString("handle"),
            name = node.getString("title"),
            description = node.optString("description"),
            imageUrl = node.optJSONObject("featuredImage")?.optString("url")?.takeIf(String::isNotBlank),
            category = node.optString("productType").ifBlank { "Coffee" },
            variants = variants,
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
