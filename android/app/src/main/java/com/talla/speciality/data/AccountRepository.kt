package com.talla.speciality.data

import android.content.Context
import com.talla.speciality.BuildConfig
import com.talla.speciality.security.PlayIntegrityClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant

class AccountRepository(private val context: Context) {
    suspend fun login(email: String, password: String): AccountSession = withContext(Dispatchers.IO) {
        sessionRequest("/accounts/login", JSONObject().put("email", email).put("password", password))
    }

    suspend fun register(firstName: String, lastName: String, email: String, password: String): AccountSession = withContext(Dispatchers.IO) {
        sessionRequest(
            "/accounts/register",
            JSONObject().put("firstName", firstName).put("lastName", lastName).put("email", email).put("password", password),
        )
    }

    suspend fun refreshSession(refreshToken: String): AccountTokens = withContext(Dispatchers.IO) {
        val json = request("POST", "/accounts/session/refresh", JSONObject().put("refreshToken", refreshToken))
        AccountTokens(
            accessToken = json.getString("accessToken"),
            refreshToken = json.getString("refreshToken"),
            expiresAt = json.getString("expiresAt"),
            refreshExpiresAt = json.getString("refreshExpiresAt"),
        )
    }

    suspend fun profile(token: String): AccountProfile = withContext(Dispatchers.IO) {
        parseProfile(request("GET", "/accounts/profile", token = token))
    }

    suspend fun loyalty(token: String): LoyaltyAccount = withContext(Dispatchers.IO) {
        val json = request("GET", "/loyalty/account", token = token)
        LoyaltyAccount(
            memberId = json.optString("memberID"),
            pointsBalance = json.optInt("pointsBalance"),
            tier = json.optString("tier", "Member"),
            nextReward = json.optString("nextReward"),
            perks = json.optJSONArray("perks").strings(),
        )
    }

    suspend fun orders(token: String): List<CustomerOrder> = withContext(Dispatchers.IO) {
        requestArray("GET", "/orders", token).objects().map { json ->
            CustomerOrder(
                id = json.optString("id"), title = json.optString("title"), total = json.optDouble("total"),
                status = json.optString("status"), createdAt = json.optString("createdAt"),
                items = json.optJSONArray("items").objects().map { item ->
                    OrderItem(item.optString("name"), item.optInt("quantity", 1))
                },
            )
        }
    }

    suspend fun tasteMemory(token: String): List<TasteMemoryRecord> = withContext(Dispatchers.IO) {
        requestArray("GET", "/taste-memory", token).objects().map(::parseTasteMemory)
    }

    suspend fun fetchCustomerLibrary(token: String): CustomerLibrary = withContext(Dispatchers.IO) {
        parseCustomerLibrary(request("GET", "/customer-library", token = token))
    }

    suspend fun mergeCustomerLibrary(
        token: String,
        favorites: Set<String>,
        recentlyViewed: List<String>,
        brewJournal: List<BrewJournalEntry>,
    ): CustomerLibrary = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("action", "merge")
            .put("favorites", JSONArray(favorites.toList()))
            .put("recentlyViewed", JSONArray(recentlyViewed))
            .put("brewJournal", brewJournalJson(brewJournal))
        parseCustomerLibrary(request("POST", "/customer-library", body, token))
    }

    suspend fun setFavorite(token: String, productId: String, favorite: Boolean) = withContext(Dispatchers.IO) {
        request("POST", "/customer-library", JSONObject().put("action", "setFavorite").put("productID", productId).put("favorite", favorite), token)
        Unit
    }

    suspend fun recordRecentlyViewed(token: String, productId: String) = withContext(Dispatchers.IO) {
        request("POST", "/customer-library", JSONObject().put("action", "recordRecent").put("productID", productId), token)
        Unit
    }

    suspend fun saveBrewJournal(token: String, entry: BrewJournalEntry) = withContext(Dispatchers.IO) {
        request("POST", "/customer-library", JSONObject().put("action", "saveJournal").put("journal", brewJournalEntryJson(entry)), token)
        Unit
    }

    suspend fun deleteBrewJournal(token: String, id: String) = withContext(Dispatchers.IO) {
        request("POST", "/customer-library", JSONObject().put("action", "deleteJournal").put("journalID", id), token)
        Unit
    }

    suspend fun saveTasteMemory(
        token: String,
        orderId: String,
        productName: String,
        reaction: String,
        tags: List<String>,
    ): List<TasteMemoryRecord> = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("orderID", orderId)
            .put("productName", productName)
            .put("reaction", reaction)
            .put("tags", JSONArray(tags))
        request("POST", "/taste-memory/save", body, token)
            .optJSONArray("tasteMemory").objects().map(::parseTasteMemory)
    }

    suspend fun addresses(token: String): List<DeliveryAddress> = withContext(Dispatchers.IO) {
        requestArray("GET", "/addresses", token).objects().map(::parseAddress)
    }

    suspend fun vouchers(token: String): List<Voucher> = withContext(Dispatchers.IO) {
        requestArray("GET", "/vouchers", token).objects().map { json ->
            Voucher(json.optString("code"), json.optString("reward"), json.optInt("points"), json.optString("detail"), json.optString("expiresAt"))
        }
    }

    suspend fun alerts(token: String): List<StockAlert> = withContext(Dispatchers.IO) {
        requestArray("GET", "/alerts", token).objects().map(::parseAlert)
    }

    suspend fun watchProduct(token: String, product: Product): StockAlert = withContext(Dispatchers.IO) {
        val body = JSONObject().put("productID", product.id).put("productName", product.name)
            .put("isAvailableForSale", product.variants.any { it.available })
        parseAlert(request("POST", "/alerts/watch", body, token))
    }

    suspend fun unwatchProduct(token: String, productId: String) = withContext(Dispatchers.IO) {
        request("POST", "/alerts/unwatch", JSONObject().put("productID", productId), token)
        Unit
    }

    suspend fun saveAddress(
        token: String,
        label: String,
        fullName: String,
        phone: String,
        line1: String,
        city: String,
        countryCode: String,
    ): List<DeliveryAddress> = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("label", label).put("fullName", fullName).put("phone", phone)
            .put("line1", line1).put("city", city).put("countryCode", countryCode.uppercase())
            .put("isPreferred", true)
        requestArrayBody("POST", "/addresses/save", body, token).objects().map(::parseAddress)
    }

    suspend fun deleteAddress(token: String, addressId: String): List<DeliveryAddress> = withContext(Dispatchers.IO) {
        requestArrayBody("POST", "/addresses/delete", JSONObject().put("addressID", addressId), token).objects().map(::parseAddress)
    }

    suspend fun logout(token: String) = withContext(Dispatchers.IO) {
        runCatching { request("POST", "/accounts/logout", JSONObject(), token) }
        Unit
    }

    suspend fun registerPushToken(token: String, email: String, deviceToken: String) = withContext(Dispatchers.IO) {
        request(
            "POST",
            "/notifications/push/register",
            JSONObject().put("email", email).put("deviceToken", deviceToken).put("platform", "android"),
            token,
        )
        Unit
    }

    suspend fun unregisterPushToken(token: String, email: String, deviceToken: String) = withContext(Dispatchers.IO) {
        request(
            "POST",
            "/notifications/push/unregister",
            JSONObject().put("email", email).put("deviceToken", deviceToken).put("platform", "android"),
            token,
        )
        Unit
    }

    private suspend fun sessionRequest(path: String, body: JSONObject): AccountSession {
        val json = request("POST", path, body)
        return AccountSession(
            profile = parseProfile(json.getJSONObject("profile")),
            accessToken = json.getString("accessToken"),
            refreshToken = json.getString("refreshToken"),
            expiresAt = json.getString("expiresAt"),
            refreshExpiresAt = json.getString("refreshExpiresAt"),
        )
    }

    private suspend fun request(method: String, path: String, body: JSONObject? = null, token: String? = null): JSONObject {
        val rawBody = body?.toString().orEmpty()
        val connection = connection(path, method, token, rawBody)
        return try {
            if (body != null) connection.outputStream.use { it.write(rawBody.toByteArray()) }
            val payload = responseText(connection)
            JSONObject(payload.ifBlank { "{}" })
        } finally { connection.disconnect() }
    }

    private suspend fun requestArray(method: String, path: String, token: String): JSONArray {
        val connection = connection(path, method, token, "")
        return try { JSONArray(responseText(connection)) } finally { connection.disconnect() }
    }

    private suspend fun requestArrayBody(method: String, path: String, body: JSONObject, token: String): JSONArray {
        val rawBody = body.toString()
        val connection = connection(path, method, token, rawBody)
        return try {
            connection.outputStream.use { it.write(rawBody.toByteArray()) }
            JSONArray(responseText(connection))
        } finally { connection.disconnect() }
    }

    private suspend fun connection(path: String, method: String, token: String?, rawBody: String): HttpURLConnection {
        require(BuildConfig.BACKEND_URL.isNotBlank()) { "Talla backend URL is not configured" }
        val integrityHeaders = if (path in integrityProtectedPaths) {
            PlayIntegrityClient.headers(context, method, path, rawBody)
        } else {
            emptyMap()
        }
        return (URL(BuildConfig.BACKEND_URL.trimEnd('/') + path).openConnection() as HttpURLConnection).apply {
            requestMethod = method
            connectTimeout = 15_000
            readTimeout = 25_000
            setRequestProperty("Accept", "application/json")
            if (token != null) setRequestProperty("Authorization", "Bearer $token")
            integrityHeaders.forEach(::setRequestProperty)
            if (method == "POST") {
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
            }
        }
    }

    private fun responseText(connection: HttpURLConnection): String {
        val code = connection.responseCode
        val stream = if (code in 200..299) connection.inputStream else connection.errorStream
        val payload = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
        if (code !in 200..299) {
            val message = runCatching { JSONObject(payload).optString("error") }.getOrNull().orEmpty()
            error(message.ifBlank { "Talla returned HTTP $code" })
        }
        return payload
    }

    private fun parseProfile(json: JSONObject) = AccountProfile(
        id = json.optString("id"),
        firstName = json.optString("firstName"),
        lastName = json.optString("lastName"),
        email = json.optString("email"),
    )

    private fun parseAddress(json: JSONObject) = DeliveryAddress(
        id = json.optString("id"), label = json.optString("label"), fullName = json.optString("fullName"),
        phone = json.optString("phone"), line1 = json.optString("line1"), city = json.optString("city"),
        countryCode = json.optString("countryCode", "BH"), isPreferred = json.optBoolean("isPreferred"),
    )

    private fun parseAlert(json: JSONObject) = StockAlert(
        productId = json.optString("productID"), productName = json.optString("productName"),
        available = json.optBoolean("isAvailableForSale"), status = json.optString("status"),
    )

    private fun parseCustomerLibrary(json: JSONObject): CustomerLibrary = CustomerLibrary(
        favorites = json.optJSONArray("favorites").strings().filter(String::isNotBlank).toSet(),
        recentlyViewed = json.optJSONArray("recentlyViewed").strings().filter(String::isNotBlank).take(20),
        brewJournal = json.optJSONArray("brewJournal").objects().mapNotNull { entry ->
            val id = entry.optString("id").trim()
            if (id.isEmpty()) return@mapNotNull null
            BrewJournalEntry(
                id = id,
                title = entry.optString("title"),
                method = entry.optString("method"),
                coffeeGrams = entry.optDouble("coffeeGrams", 0.0).toInt(),
                ratio = entry.optDouble("ratio", 0.0),
                waterGrams = entry.optDouble("waterGrams", 0.0).toInt(),
                brewTimeSeconds = entry.optInt("brewTimeSeconds", 0),
                rating = entry.optInt("rating", 1).coerceIn(1, 5),
                notes = entry.optString("notes"),
                createdAt = runCatching { Instant.parse(entry.optString("createdAt")).toEpochMilli() }.getOrDefault(System.currentTimeMillis()),
            )
        }.take(BrewJournalPolicy.MAX_ENTRIES),
    )

    private fun brewJournalJson(entries: List<BrewJournalEntry>) = JSONArray().apply {
        entries.take(BrewJournalPolicy.MAX_ENTRIES).forEach { put(brewJournalEntryJson(it)) }
    }

    private fun brewJournalEntryJson(entry: BrewJournalEntry) = JSONObject()
        .put("id", entry.id)
        .put("title", entry.title)
        .put("method", entry.method)
        .put("coffeeGrams", entry.coffeeGrams)
        .put("ratio", entry.ratio)
        .put("waterGrams", entry.waterGrams)
        .put("brewTimeSeconds", entry.brewTimeSeconds)
        .put("rating", entry.rating)
        .put("notes", entry.notes)
        .put("createdAt", Instant.ofEpochMilli(entry.createdAt).toString())

    private fun parseTasteMemory(json: JSONObject) = TasteMemoryRecord(
        id = json.optString("id"), orderId = json.optString("orderID"), productName = json.optString("productName"),
        reaction = json.optString("reaction"), tags = json.optJSONArray("tags").strings(),
        createdAt = json.optString("createdAt"), updatedAt = json.optString("updatedAt"),
    )

    private fun JSONArray?.strings(): List<String> = if (this == null) emptyList() else (0 until length()).map { optString(it) }
    private fun JSONArray?.objects(): List<JSONObject> = if (this == null) emptyList() else (0 until length()).map { getJSONObject(it) }

    private companion object {
        val integrityProtectedPaths = setOf(
            "/addresses/save",
            "/addresses/preferred",
            "/addresses/delete",
            "/notifications/push/register",
            "/notifications/push/unregister",
            "/loyalty/transactions/redeem",
            "/loyalty/transactions/earn",
            "/vouchers/consume",
            "/accounts/profile/update",
            "/accounts/password/change",
            "/accounts/session/refresh",
            "/customer-library",
        )
    }
}
