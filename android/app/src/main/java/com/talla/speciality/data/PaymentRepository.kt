package com.talla.speciality.data

import com.talla.speciality.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.math.BigDecimal
import java.math.RoundingMode
import java.net.HttpURLConnection
import java.net.URL

data class BenefitPaySession(
    val appId: String,
    val merchantId: String,
    val merchantName: String,
    val merchantCity: String,
    val merchantCategoryCode: String,
    val countryCode: String,
    val currencyCode: String,
    val amount: String,
    val referenceId: String,
    val paymentToken: String,
    val orderId: String,
)

data class BenefitPayConfirmation(val status: String, val orderId: String, val duplicate: Boolean)
data class HostedBenefitCheckout(val paymentUrl: String, val orderId: String)
data class HostedBenefitStatus(val status: String, val paid: Boolean)
data class ClickToPayCheckout(val paymentUrl: String, val localOrderId: String)
data class ClickToPayStatus(val status: String, val confirmed: Boolean)

class PaymentRepository {
    suspend fun prepareBenefitPay(
        token: String,
        email: String,
        lines: List<CartLine>,
        fulfillmentMethod: String,
    ): BenefitPaySession = withContext(Dispatchers.IO) {
        val orderId = createPendingOrder(token, email, lines, fulfillmentMethod)
        val session = post("/api/payments/benefitpay/session", JSONObject().put("orderID", orderId), token)
        BenefitPaySession(
            appId = session.getString("appId"), merchantId = session.getString("merchantId"),
            merchantName = session.getString("merchantName"), merchantCity = session.getString("merchantCity"),
            merchantCategoryCode = session.getString("merchantCategoryCode"), countryCode = session.getString("countryCode"),
            currencyCode = session.getString("currencyCode"), amount = session.getString("amount"),
            referenceId = session.getString("referenceId"), paymentToken = session.getString("paymentToken"),
            orderId = session.getString("orderId"),
        )
    }

    suspend fun prepareHostedBenefit(
        token: String,
        email: String,
        lines: List<CartLine>,
        fulfillmentMethod: String,
    ): HostedBenefitCheckout = withContext(Dispatchers.IO) {
        val orderId = createPendingOrder(token, email, lines, fulfillmentMethod)
        val result = post("/api/payments/benefit/create", JSONObject().put("orderID", orderId), token)
        HostedBenefitCheckout(result.getString("paymentUrl"), orderId)
    }

    suspend fun hostedBenefitStatus(token: String, orderId: String): HostedBenefitStatus = withContext(Dispatchers.IO) {
        val result = post("/api/payments/benefit/status", JSONObject().put("orderID", orderId), token)
        HostedBenefitStatus(result.optString("status", "pending"), result.optBoolean("paid"))
    }

    suspend fun prepareClickToPay(
        token: String,
        email: String,
        lines: List<CartLine>,
        fulfillmentMethod: String,
    ): ClickToPayCheckout = withContext(Dispatchers.IO) {
        val localOrderId = createPendingOrder(token, email, lines, fulfillmentMethod)
        val result = post("/api/payments/click-to-pay/create", JSONObject().put("orderID", localOrderId), token)
        ClickToPayCheckout(result.getString("paymentUrl"), localOrderId)
    }

    suspend fun clickToPayStatus(token: String, localOrderId: String): ClickToPayStatus = withContext(Dispatchers.IO) {
        val result = post("/api/payments/card/order/retrieve", JSONObject().put("localOrderId", localOrderId), token)
        ClickToPayStatus(result.optString("status", "Pending"), result.optBoolean("confirmed"))
    }

    suspend fun confirmBenefitPay(token: String, session: BenefitPaySession): BenefitPayConfirmation = withContext(Dispatchers.IO) {
        var confirmation: BenefitPayConfirmation? = null
        val delays = listOf(0L, 1_000L, 2_000L, 3_000L, 4_000L)
        for (delayMillis in delays) {
            if (delayMillis > 0) kotlinx.coroutines.delay(delayMillis)
            val json = post(
                "/api/payments/benefitpay/confirm",
                JSONObject().put("orderID", session.orderId).put("referenceID", session.referenceId)
                    .put("paymentToken", session.paymentToken),
                token,
            )
            confirmation = BenefitPayConfirmation(json.optString("status"), json.optString("orderId"), json.optBoolean("duplicate"))
            if (confirmation.status != "pending") break
        }
        confirmation?.takeIf { it.status != "pending" }
            ?: error("BenefitPay is still confirming your payment. Check your orders again shortly.")
    }

    private fun createPendingOrder(
        token: String,
        email: String,
        lines: List<CartLine>,
        fulfillmentMethod: String,
    ): String {
        require(lines.isNotEmpty()) { "Your bag is empty" }
        val items = JSONArray().apply {
            lines.forEach { line ->
                put(JSONObject().put("name", line.product.name).put("quantity", line.quantity).put("variantId", line.variant.id))
            }
        }
        val total = lines.fold(BigDecimal.ZERO) { sum, line ->
            sum + (line.variant.price.toBigDecimalOrNull() ?: BigDecimal.ZERO) * line.quantity.toBigDecimal()
        }.setScale(3, RoundingMode.HALF_UP)
        return post(
            "/orders/checkout-started",
            JSONObject().put("email", email).put("title", if (fulfillmentMethod == "pickup") "Pickup order" else "Delivery order")
                .put("total", total).put("fulfillmentMethod", fulfillmentMethod).put("items", items),
            token,
        ).getString("orderID")
    }

    private fun post(path: String, body: JSONObject, token: String): JSONObject {
        require(BuildConfig.BACKEND_URL.isNotBlank()) { "Talla backend URL is not configured" }
        val connection = (URL(BuildConfig.BACKEND_URL.trimEnd('/') + path).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 15_000
            readTimeout = 25_000
            doOutput = true
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("Authorization", "Bearer $token")
        }
        return try {
            connection.outputStream.use { it.write(body.toString().toByteArray()) }
            val code = connection.responseCode
            val stream = if (code in 200..299) connection.inputStream else connection.errorStream
            val payload = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
            if (code !in 200..299) {
                val message = runCatching { JSONObject(payload).optString("error") }.getOrNull().orEmpty()
                error(message.ifBlank { "Payment service returned HTTP $code" })
            }
            JSONObject(payload.ifBlank { "{}" })
        } finally {
            connection.disconnect()
        }
    }
}
