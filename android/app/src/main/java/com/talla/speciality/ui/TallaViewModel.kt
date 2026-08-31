package com.talla.speciality.ui

import android.app.Application
import android.net.Uri
import androidx.core.content.edit
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.talla.speciality.data.CartLine
import com.talla.speciality.data.AccountProfile
import com.talla.speciality.data.AccountRepository
import com.talla.speciality.data.CustomerOrder
import com.talla.speciality.data.DeliveryAddress
import com.talla.speciality.data.LoyaltyAccount
import com.talla.speciality.data.Product
import com.talla.speciality.data.SecureTokenStore
import com.talla.speciality.data.Voucher
import com.talla.speciality.data.StockAlert
import com.talla.speciality.data.ShopifyRepository
import com.talla.speciality.data.BenefitPaySession
import com.talla.speciality.data.BrewJournalEntry
import com.talla.speciality.data.BrewJournalPolicy
import com.talla.speciality.data.CoffeeBagScanResult
import com.talla.speciality.data.CoffeeBagTextRecognizer
import com.talla.speciality.data.PaymentRepository
import com.talla.speciality.data.TasteMemoryRecord
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

data class TallaUiState(
    val products: List<Product> = emptyList(),
    val loading: Boolean = true,
    val error: String? = null,
    val cart: Map<String, CartLine> = emptyMap(),
    val favoriteProductIds: Set<String> = emptySet(),
    val recentlyViewedProductIds: List<String> = emptyList(),
    val checkoutLoading: Boolean = false,
    val checkoutUrl: String? = null,
    val checkoutError: String? = null,
    val hostedBenefitOrderId: String? = null,
    val clickToPayOrderId: String? = null,
    val benefitPaySession: BenefitPaySession? = null,
    val paymentMessage: String? = null,
    val profile: AccountProfile? = null,
    val loyalty: LoyaltyAccount? = null,
    val orders: List<CustomerOrder> = emptyList(),
    val addresses: List<DeliveryAddress> = emptyList(),
    val vouchers: List<Voucher> = emptyList(),
    val stockAlerts: List<StockAlert> = emptyList(),
    val tasteMemory: List<TasteMemoryRecord> = emptyList(),
    val brewJournal: List<BrewJournalEntry> = emptyList(),
    val coffeeBagScan: CoffeeBagScanResult? = null,
    val coffeeBagScanning: Boolean = false,
    val coffeeBagScanError: String? = null,
    val accountLoading: Boolean = false,
    val accountError: String? = null,
) {
    val cartCount: Int get() = cart.values.sumOf { it.quantity }
}

class TallaViewModel(application: Application) : AndroidViewModel(application) {
    private val shopify = ShopifyRepository()
    private val accounts = AccountRepository()
    private val payments = PaymentRepository()
    private val tokenStore = SecureTokenStore(application)
    private val preferences = application.getSharedPreferences("talla_state", 0)
    private val pendingCart = loadCartQuantities()
    private val mutableState = MutableStateFlow(
        TallaUiState(
            favoriteProductIds = preferences.getStringSet("favorites", emptySet()).orEmpty(),
            recentlyViewedProductIds = loadRecentIds(),
            hostedBenefitOrderId = preferences.getString("hosted_benefit_order", null),
            clickToPayOrderId = preferences.getString("click_to_pay_order", null),
            brewJournal = loadBrewJournal(),
        )
    )
    val state: StateFlow<TallaUiState> = mutableState.asStateFlow()

    init {
        refresh()
        restoreAccount()
    }

    fun refresh() {
        viewModelScope.launch {
            mutableState.update { it.copy(loading = true, error = null) }
            runCatching { shopify.products() }
                .onSuccess { products ->
                    val byVariant = products.flatMap { product -> product.variants.map { it.id to (product to it) } }.toMap()
                    val restoredCart = pendingCart.mapNotNull { (variantId, quantity) ->
                        byVariant[variantId]?.let { (product, variant) -> variantId to CartLine(product, variant, quantity) }
                    }.toMap()
                    mutableState.update { it.copy(products = products, cart = restoredCart, loading = false) }
                }
                .onFailure { failure -> mutableState.update { it.copy(loading = false, error = failure.message ?: "Unable to load the shop") } }
        }
    }

    fun addToCart(product: Product, selectedVariantId: String? = null) {
        val variant = product.variants.firstOrNull { it.id == selectedVariantId } ?: product.defaultVariant ?: return
        mutableState.update { current ->
            val existing = current.cart[variant.id]
            current.copy(cart = current.cart + (variant.id to CartLine(product, variant, (existing?.quantity ?: 0) + 1))).also(::persistCart)
        }
    }

    fun removeFromCart(variantId: String) {
        mutableState.update { current ->
            val line = current.cart[variantId] ?: return@update current
            val next = if (line.quantity == 1) current.cart - variantId
            else current.cart + (variantId to line.copy(quantity = line.quantity - 1))
            current.copy(cart = next).also(::persistCart)
        }
    }

    fun toggleFavorite(productId: String) {
        mutableState.update { current ->
            val next = if (productId in current.favoriteProductIds) current.favoriteProductIds - productId else current.favoriteProductIds + productId
            preferences.edit { putStringSet("favorites", next) }
            current.copy(favoriteProductIds = next)
        }
    }

    fun markViewed(productId: String) {
        mutableState.update { current ->
            val next = (listOf(productId) + current.recentlyViewedProductIds.filterNot { it == productId }).take(20)
            preferences.edit { putString("recent", JSONArray(next).toString()) }
            current.copy(recentlyViewedProductIds = next)
        }
    }

    fun beginCheckout(fulfillmentMethod: String) {
        val current = mutableState.value
        val lines = current.cart.values.toList()
        val preferredAddress = current.addresses.firstOrNull { it.isPreferred } ?: current.addresses.firstOrNull()
        viewModelScope.launch {
            mutableState.update { it.copy(checkoutLoading = true, checkoutError = null) }
            runCatching { shopify.checkoutUrl(lines, fulfillmentMethod, current.profile?.email, preferredAddress) }
                .onSuccess { url -> mutableState.update { it.copy(checkoutLoading = false, checkoutUrl = url) } }
                .onFailure { failure -> mutableState.update { it.copy(checkoutLoading = false, checkoutError = failure.message ?: "Checkout is unavailable") } }
        }
    }

    fun consumeCheckoutUrl() = mutableState.update { it.copy(checkoutUrl = null) }
    fun clearCheckoutError() = mutableState.update { it.copy(checkoutError = null) }

    fun beginHostedBenefit(fulfillmentMethod: String) {
        val current = mutableState.value
        val token = tokenStore.read()
        val profile = current.profile
        if (token == null || profile == null) {
            mutableState.update { it.copy(checkoutError = "Sign in to pay with BENEFIT") }
            return
        }
        viewModelScope.launch {
            mutableState.update { it.copy(checkoutLoading = true, checkoutError = null, paymentMessage = null) }
            runCatching { payments.prepareHostedBenefit(token, profile.email, current.cart.values.toList(), fulfillmentMethod) }
                .onSuccess { checkout ->
                    preferences.edit { putString("hosted_benefit_order", checkout.orderId) }
                    mutableState.update {
                        it.copy(checkoutLoading = false, checkoutUrl = checkout.paymentUrl, hostedBenefitOrderId = checkout.orderId)
                    }
                }
                .onFailure { failure -> mutableState.update { it.copy(checkoutLoading = false, checkoutError = failure.message ?: "BENEFIT checkout is unavailable") } }
        }
    }

    fun checkHostedBenefitStatus() {
        val orderId = mutableState.value.hostedBenefitOrderId ?: return
        val token = tokenStore.read() ?: return
        viewModelScope.launch {
            runCatching { payments.hostedBenefitStatus(token, orderId) }
                .onSuccess { status ->
                    when (status.status) {
                        "succeeded" -> {
                            preferences.edit { remove("hosted_benefit_order") }
                            mutableState.update { current ->
                                current.copy(
                                    cart = emptyMap(), hostedBenefitOrderId = null,
                                    paymentMessage = "BENEFIT payment confirmed. Your order is being prepared.",
                                ).also(::persistCart)
                            }
                            refreshAccount()
                        }
                        "failed", "cancelled" -> {
                            preferences.edit { remove("hosted_benefit_order") }
                            mutableState.update {
                                it.copy(hostedBenefitOrderId = null, checkoutError = "BENEFIT payment was not completed")
                            }
                        }
                    }
                }
        }
    }

    fun beginClickToPay(fulfillmentMethod: String) {
        val current = mutableState.value
        val token = tokenStore.read()
        val profile = current.profile
        if (token == null || profile == null) {
            mutableState.update { it.copy(checkoutError = "Sign in to use Click to Pay") }
            return
        }
        viewModelScope.launch {
            mutableState.update { it.copy(checkoutLoading = true, checkoutError = null, paymentMessage = null) }
            runCatching { payments.prepareClickToPay(token, profile.email, current.cart.values.toList(), fulfillmentMethod) }
                .onSuccess { checkout ->
                    preferences.edit { putString("click_to_pay_order", checkout.localOrderId) }
                    mutableState.update {
                        it.copy(checkoutLoading = false, checkoutUrl = checkout.paymentUrl, clickToPayOrderId = checkout.localOrderId)
                    }
                }
                .onFailure { failure -> mutableState.update { it.copy(checkoutLoading = false, checkoutError = failure.message ?: "Click to Pay is unavailable") } }
        }
    }

    fun checkClickToPayStatus() {
        val orderId = mutableState.value.clickToPayOrderId ?: return
        val token = tokenStore.read() ?: return
        viewModelScope.launch {
            runCatching { payments.clickToPayStatus(token, orderId) }
                .onSuccess { status ->
                    when {
                        status.confirmed -> {
                            preferences.edit { remove("click_to_pay_order") }
                            mutableState.update { current ->
                                current.copy(
                                    cart = emptyMap(), clickToPayOrderId = null,
                                    paymentMessage = "Click to Pay confirmed. Your order is being prepared.",
                                ).also(::persistCart)
                            }
                            refreshAccount()
                        }
                        status.status.equals("Cancelled", ignoreCase = true) || status.status.equals("Failed", ignoreCase = true) || status.status.equals("Declined", ignoreCase = true) -> {
                            preferences.edit { remove("click_to_pay_order") }
                            mutableState.update { it.copy(clickToPayOrderId = null, checkoutError = "Click to Pay was not completed") }
                        }
                    }
                }
        }
    }

    fun beginBenefitPay(fulfillmentMethod: String) {
        val current = mutableState.value
        val token = tokenStore.read()
        val profile = current.profile
        if (token == null || profile == null) {
            mutableState.update { it.copy(checkoutError = "Sign in to pay with BenefitPay") }
            return
        }
        viewModelScope.launch {
            mutableState.update { it.copy(checkoutLoading = true, checkoutError = null, paymentMessage = null) }
            runCatching { payments.prepareBenefitPay(token, profile.email, current.cart.values.toList(), fulfillmentMethod) }
                .onSuccess { session -> mutableState.update { it.copy(checkoutLoading = false, benefitPaySession = session) } }
                .onFailure { failure -> mutableState.update { it.copy(checkoutLoading = false, checkoutError = failure.message ?: "BenefitPay is unavailable") } }
        }
    }

    fun confirmBenefitPay(session: BenefitPaySession) {
        val token = tokenStore.read()
        if (token == null) {
            mutableState.update { it.copy(checkoutError = "Sign in again to confirm your payment", benefitPaySession = null) }
            return
        }
        viewModelScope.launch {
            mutableState.update { it.copy(checkoutLoading = true, checkoutError = null) }
            runCatching { payments.confirmBenefitPay(token, session) }
                .onSuccess { confirmation ->
                    if (confirmation.status == "succeeded") {
                        mutableState.update { current ->
                            current.copy(
                                cart = emptyMap(), checkoutLoading = false, benefitPaySession = null,
                                paymentMessage = "Payment confirmed. Your order is being prepared.",
                            ).also(::persistCart)
                        }
                        refreshAccount()
                    } else {
                        mutableState.update { it.copy(checkoutLoading = false, benefitPaySession = null, checkoutError = "BenefitPay did not approve the payment") }
                    }
                }
                .onFailure { failure -> mutableState.update { it.copy(checkoutLoading = false, benefitPaySession = null, checkoutError = failure.message ?: "Unable to confirm BenefitPay") } }
        }
    }

    fun failBenefitPay(message: String) = mutableState.update {
        it.copy(checkoutLoading = false, benefitPaySession = null, checkoutError = message)
    }

    fun dismissBenefitPay() = mutableState.update { it.copy(benefitPaySession = null, checkoutLoading = false) }
    fun clearPaymentMessage() = mutableState.update { it.copy(paymentMessage = null) }

    fun login(email: String, password: String) {
        accountAction {
            val session = accounts.login(email.trim(), password)
            tokenStore.save(session.accessToken)
            loadAccount(session.accessToken, session.profile)
        }
    }

    fun register(firstName: String, lastName: String, email: String, password: String) {
        accountAction {
            val session = accounts.register(firstName.trim(), lastName.trim(), email.trim(), password)
            tokenStore.save(session.accessToken)
            loadAccount(session.accessToken, session.profile)
        }
    }

    fun logout() {
        val token = tokenStore.read()
        tokenStore.clear()
        mutableState.update {
            it.copy(
                profile = null, loyalty = null, orders = emptyList(), addresses = emptyList(), vouchers = emptyList(),
                stockAlerts = emptyList(), tasteMemory = emptyList(), accountError = null,
            )
        }
        if (token != null) viewModelScope.launch { accounts.logout(token) }
    }

    fun refreshAccount() {
        val token = tokenStore.read() ?: return
        accountAction { loadAccount(token, accounts.profile(token)) }
    }

    fun clearAccountError() = mutableState.update { it.copy(accountError = null) }

    fun saveAddress(label: String, fullName: String, phone: String, line1: String, city: String, countryCode: String) {
        val token = tokenStore.read() ?: return
        accountAction {
            val addresses = accounts.saveAddress(token, label, fullName, phone, line1, city, countryCode)
            mutableState.update { it.copy(addresses = addresses, accountLoading = false) }
        }
    }

    fun deleteAddress(addressId: String) {
        val token = tokenStore.read() ?: return
        accountAction {
            val addresses = accounts.deleteAddress(token, addressId)
            mutableState.update { it.copy(addresses = addresses, accountLoading = false) }
        }
    }

    fun toggleStockAlert(product: Product) {
        val token = tokenStore.read()
        if (token == null) {
            mutableState.update { it.copy(accountError = "Sign in to receive stock alerts") }
            return
        }
        accountAction {
            val watching = mutableState.value.stockAlerts.any { it.productId == product.id }
            val next = if (watching) {
                accounts.unwatchProduct(token, product.id)
                mutableState.value.stockAlerts.filterNot { it.productId == product.id }
            } else {
                mutableState.value.stockAlerts + accounts.watchProduct(token, product)
            }
            mutableState.update { it.copy(stockAlerts = next, accountLoading = false) }
        }
    }

    fun saveTasteMemory(orderId: String, productName: String, reaction: String, tags: List<String>) {
        val token = tokenStore.read()
        if (token == null) {
            mutableState.update { it.copy(accountError = "Sign in to save taste feedback") }
            return
        }
        accountAction {
            val records = accounts.saveTasteMemory(token, orderId, productName, reaction, tags)
            mutableState.update { it.copy(tasteMemory = records, accountLoading = false) }
        }
    }

    fun saveBrewJournalEntry(
        title: String,
        method: String,
        coffeeGrams: Int,
        ratio: Double,
        waterGrams: Int,
        brewTimeSeconds: Int,
        rating: Int,
        notes: String,
    ) {
        val cleanTitle = title.trim().ifBlank { method.trim().ifBlank { "Coffee brew" } }
        val entry = BrewJournalEntry(
            id = UUID.randomUUID().toString(), title = cleanTitle, method = method.trim().ifBlank { "Coffee" },
            coffeeGrams = coffeeGrams, ratio = ratio, waterGrams = waterGrams,
            brewTimeSeconds = brewTimeSeconds, rating = rating, notes = notes.trim(), createdAt = System.currentTimeMillis(),
        )
        mutableState.update { current ->
            current.copy(brewJournal = BrewJournalPolicy.add(current.brewJournal, entry)).also(::persistBrewJournal)
        }
    }

    fun deleteBrewJournalEntry(id: String) {
        mutableState.update { current ->
            current.copy(brewJournal = BrewJournalPolicy.remove(current.brewJournal, id)).also(::persistBrewJournal)
        }
    }

    fun scanCoffeeBag(imageUri: Uri) {
        viewModelScope.launch {
            mutableState.update { it.copy(coffeeBagScanning = true, coffeeBagScanError = null) }
            runCatching { CoffeeBagTextRecognizer.analyze(getApplication(), imageUri) }
                .onSuccess { result ->
                    mutableState.update {
                        it.copy(coffeeBagScan = result, coffeeBagScanning = false, coffeeBagScanError = null)
                    }
                }
                .onFailure { failure ->
                    mutableState.update {
                        it.copy(
                            coffeeBagScanning = false,
                            coffeeBagScanError = failure.message ?: "Unable to read this coffee bag",
                        )
                    }
                }
        }
    }

    fun clearCoffeeBagScan() = mutableState.update {
        it.copy(coffeeBagScan = null, coffeeBagScanError = null, coffeeBagScanning = false)
    }

    private fun restoreAccount() {
        val token = tokenStore.read() ?: return
        accountAction { loadAccount(token, accounts.profile(token)) }
    }

    private fun accountAction(action: suspend () -> Unit) {
        viewModelScope.launch {
            mutableState.update { it.copy(accountLoading = true, accountError = null) }
            runCatching { action() }
                .onFailure { failure ->
                    if (failure.message?.contains("401") == true || failure.message?.contains("session", ignoreCase = true) == true) tokenStore.clear()
                    mutableState.update { it.copy(accountLoading = false, accountError = failure.message ?: "Account service is unavailable") }
                }
        }
    }

    private suspend fun loadAccount(token: String, profile: AccountProfile) {
        val loyalty = accounts.loyalty(token)
        val orders = accounts.orders(token)
        val addresses = accounts.addresses(token)
        val vouchers = accounts.vouchers(token)
        val stockAlerts = accounts.alerts(token)
        val tasteMemory = accounts.tasteMemory(token)
        mutableState.update {
            it.copy(
                profile = profile, loyalty = loyalty, orders = orders, addresses = addresses, vouchers = vouchers,
                stockAlerts = stockAlerts, tasteMemory = tasteMemory, accountLoading = false, accountError = null,
            )
        }
    }

    private fun persistCart(state: TallaUiState) {
        val json = JSONObject()
        state.cart.forEach { (variantId, line) -> json.put(variantId, line.quantity) }
        preferences.edit { putString("cart", json.toString()) }
    }

    private fun loadCartQuantities(): Map<String, Int> = runCatching {
        val json = JSONObject(preferences.getString("cart", "{}") ?: "{}")
        json.keys().asSequence().associateWith { json.optInt(it, 0) }.filterValues { it > 0 }
    }.getOrDefault(emptyMap())

    private fun loadRecentIds(): List<String> = runCatching {
        val json = JSONArray(preferences.getString("recent", "[]") ?: "[]")
        (0 until json.length()).mapNotNull { json.optString(it).takeIf(String::isNotBlank) }
    }.getOrDefault(emptyList())

    private fun persistBrewJournal(state: TallaUiState) {
        val json = JSONArray()
        state.brewJournal.forEach { entry ->
            json.put(
                JSONObject()
                    .put("id", entry.id).put("title", entry.title).put("method", entry.method)
                    .put("coffeeGrams", entry.coffeeGrams).put("ratio", entry.ratio).put("waterGrams", entry.waterGrams)
                    .put("brewTimeSeconds", entry.brewTimeSeconds).put("rating", entry.rating)
                    .put("notes", entry.notes).put("createdAt", entry.createdAt)
            )
        }
        preferences.edit { putString("brew_journal", json.toString()) }
    }

    private fun loadBrewJournal(): List<BrewJournalEntry> = runCatching {
        val json = JSONArray(preferences.getString("brew_journal", "[]") ?: "[]")
        (0 until json.length()).map { index ->
            val entry = json.getJSONObject(index)
            BrewJournalEntry(
                id = entry.getString("id"), title = entry.optString("title"), method = entry.optString("method"),
                coffeeGrams = entry.optInt("coffeeGrams"), ratio = entry.optDouble("ratio"),
                waterGrams = entry.optInt("waterGrams"), brewTimeSeconds = entry.optInt("brewTimeSeconds"),
                rating = entry.optInt("rating", 4).coerceIn(1, 5), notes = entry.optString("notes"),
                createdAt = entry.optLong("createdAt"),
            )
        }.take(BrewJournalPolicy.MAX_ENTRIES)
    }.getOrDefault(emptyList())
}
