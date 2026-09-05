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
import com.talla.speciality.data.CoffeeScaleManager
import com.talla.speciality.data.CoffeeDataStore
import com.talla.speciality.data.CoffeeEntityType
import com.talla.speciality.data.CoffeeConflict
import com.talla.speciality.data.PurchasedCoffee
import com.talla.speciality.data.PaymentRepository
import com.talla.speciality.data.TasteMemoryRecord
import com.talla.speciality.data.ScaleAction
import com.talla.speciality.data.ScaleUiState
import com.talla.speciality.data.TallaRemoteSettings
import com.talla.speciality.data.TallaRemoteSettingsRepository
import com.talla.speciality.widget.TallaQuickActionsWidget
import com.talla.speciality.widget.TallaWidgetSnapshot
import com.talla.speciality.widget.TallaWidgetStateStore
import com.talla.speciality.notifications.PushRegistrationManager
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID
import com.talla.speciality.telemetry.TallaTelemetry

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
    val coffeeInventory: List<PurchasedCoffee> = emptyList(),
    val coffeeConflicts: List<CoffeeConflict> = emptyList(),
    val coffeeBagScan: CoffeeBagScanResult? = null,
    val coffeeBagScanning: Boolean = false,
    val coffeeBagScanError: String? = null,
    val scale: ScaleUiState = ScaleUiState(),
    val accountLoading: Boolean = false,
    val accountError: String? = null,
    val remoteSettings: TallaRemoteSettings = TallaRemoteSettings(),
) {
    val cartCount: Int get() = cart.values.sumOf { it.quantity }
}

class TallaViewModel(application: Application) : AndroidViewModel(application) {
    private val shopify = ShopifyRepository()
    private val remoteSettings = TallaRemoteSettingsRepository()
    private val accounts = AccountRepository(application)
    private val payments = PaymentRepository(application)
    private val scales = CoffeeScaleManager(application)
    private val tokenStore = SecureTokenStore(application)
    private val coffeeData = CoffeeDataStore(application)
    private val preferences = application.getSharedPreferences("talla_state", 0)
    private val pendingCart = loadCartQuantities()
    private val mutableState = MutableStateFlow(
        TallaUiState(
            favoriteProductIds = preferences.getStringSet("favorites", emptySet()).orEmpty(),
            recentlyViewedProductIds = loadRecentIds(),
            hostedBenefitOrderId = preferences.getString("hosted_benefit_order", null),
            clickToPayOrderId = preferences.getString("click_to_pay_order", null),
            brewJournal = loadBrewJournal(),
            coffeeInventory = coffeeData.purchasedCoffee(),
            coffeeConflicts = coffeeData.conflicts(),
        )
    )
    val state: StateFlow<TallaUiState> = mutableState.asStateFlow()

    init {
        viewModelScope.launch {
            mutableState
                .map { current ->
                    TallaWidgetSnapshot(
                        signedIn = current.profile != null,
                        loyaltyPoints = current.loyalty?.pointsBalance ?: 0,
                        loyaltyTier = current.loyalty?.tier.orEmpty(),
                        loyaltyNextReward = current.loyalty?.nextReward.orEmpty(),
                        favoriteCount = current.favoriteProductIds.size,
                        recentCount = current.recentlyViewedProductIds.size,
                        bagCount = current.cartCount,
                        brewCount = current.brewJournal.size,
                    )
                }
                .distinctUntilChanged()
                .collect { widgetState ->
                    TallaWidgetStateStore.save(application, widgetState)
                    TallaQuickActionsWidget().updateAll(application)
                }
        }
        viewModelScope.launch {
            scales.state.collect { scaleState -> mutableState.update { it.copy(scale = scaleState) } }
        }
        refresh()
        restoreAccount()
    }

    fun refresh() {
        viewModelScope.launch {
            mutableState.update { it.copy(loading = true, error = null) }
            runCatching { remoteSettings.fetch() }
                .onSuccess { settings -> mutableState.update { it.copy(remoteSettings = settings) } }
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
        var isFavorite = false
        mutableState.update { current ->
            val next = if (productId in current.favoriteProductIds) current.favoriteProductIds - productId else current.favoriteProductIds + productId
            isFavorite = productId in next
            preferences.edit { putStringSet("favorites", next) }
            current.copy(favoriteProductIds = next)
        }
        tokenStore.read()?.let { token ->
            viewModelScope.launch { runCatching { accounts.setFavorite(token, productId, isFavorite) } }
        }
    }

    fun markViewed(productId: String) {
        mutableState.update { current ->
            val next = (listOf(productId) + current.recentlyViewedProductIds.filterNot { it == productId }).take(20)
            preferences.edit { putString("recent", JSONArray(next).toString()) }
            current.copy(recentlyViewedProductIds = next)
        }
        tokenStore.read()?.let { token ->
            viewModelScope.launch { runCatching { accounts.recordRecentlyViewed(token, productId) } }
        }
    }

    fun beginCheckout(fulfillmentMethod: String) {
        val current = mutableState.value
        val lines = current.cart.values.toList()
        val preferredAddress = current.addresses.firstOrNull { it.isPreferred } ?: current.addresses.firstOrNull()
        TallaTelemetry.track("checkout_started", properties = mapOf("method" to "shopify", "item_count" to lines.sumOf { it.quantity }))
        viewModelScope.launch {
            mutableState.update { it.copy(checkoutLoading = true, checkoutError = null) }
            runCatching { shopify.checkoutUrl(lines, fulfillmentMethod, current.profile?.email, preferredAddress) }
                .onSuccess { url ->
                    TallaTelemetry.track("payment_funnel_stage", properties = mapOf("method" to "shopify", "stage" to "checkout_opened"))
                    mutableState.update { it.copy(checkoutLoading = false, checkoutUrl = url) }
                }
                .onFailure { failure ->
                    TallaTelemetry.track("payment_failed", properties = mapOf("method" to "shopify", "stage" to "checkout_create"))
                    mutableState.update { it.copy(checkoutLoading = false, checkoutError = failure.message ?: "Checkout is unavailable") }
                }
        }
    }

    fun consumeCheckoutUrl() = mutableState.update { it.copy(checkoutUrl = null) }
    fun clearCheckoutError() = mutableState.update { it.copy(checkoutError = null) }

    fun beginHostedBenefit(fulfillmentMethod: String) {
        val current = mutableState.value
        val token = tokenStore.read()
        val profile = current.profile
        TallaTelemetry.track("payment_method_selected", properties = mapOf("method" to "benefit"))
        if (token == null || profile == null) {
            mutableState.update { it.copy(checkoutError = "Sign in to pay with BENEFIT") }
            return
        }
        viewModelScope.launch {
            mutableState.update { it.copy(checkoutLoading = true, checkoutError = null, paymentMessage = null) }
            runCatching { payments.prepareHostedBenefit(token, profile.email, current.cart.values.toList(), fulfillmentMethod) }
                .onSuccess { checkout ->
                    TallaTelemetry.track("payment_funnel_stage", properties = mapOf("method" to "benefit", "stage" to "checkout_opened"))
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
                            TallaTelemetry.track("purchase_completed", properties = mapOf("method" to "benefit"))
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
                            TallaTelemetry.track("payment_failed", properties = mapOf("method" to "benefit", "stage" to status.status))
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
        TallaTelemetry.track("payment_method_selected", properties = mapOf("method" to "click_to_pay"))
        if (token == null || profile == null) {
            mutableState.update { it.copy(checkoutError = "Sign in to use Click to Pay") }
            return
        }
        viewModelScope.launch {
            mutableState.update { it.copy(checkoutLoading = true, checkoutError = null, paymentMessage = null) }
            runCatching { payments.prepareClickToPay(token, profile.email, current.cart.values.toList(), fulfillmentMethod) }
                .onSuccess { checkout ->
                    TallaTelemetry.track("payment_funnel_stage", properties = mapOf("method" to "click_to_pay", "stage" to "checkout_opened"))
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
                            TallaTelemetry.track("purchase_completed", properties = mapOf("method" to "click_to_pay"))
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
                            TallaTelemetry.track("payment_failed", properties = mapOf("method" to "click_to_pay", "stage" to status.status.lowercase()))
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
        TallaTelemetry.track("payment_method_selected", properties = mapOf("method" to "benefit_pay"))
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
                        TallaTelemetry.track("purchase_completed", properties = mapOf("method" to "benefit_pay"))
                        mutableState.update { current ->
                            current.copy(
                                cart = emptyMap(), checkoutLoading = false, benefitPaySession = null,
                                paymentMessage = "Payment confirmed. Your order is being prepared.",
                            ).also(::persistCart)
                        }
                        refreshAccount()
                    } else {
                        TallaTelemetry.track("payment_failed", properties = mapOf("method" to "benefit_pay", "stage" to confirmation.status))
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
            tokenStore.save(session.accessToken, session.refreshToken)
            loadAccount(session.accessToken, session.profile)
        }
    }

    fun register(firstName: String, lastName: String, email: String, password: String) {
        accountAction {
            val session = accounts.register(firstName.trim(), lastName.trim(), email.trim(), password)
            tokenStore.save(session.accessToken, session.refreshToken)
            loadAccount(session.accessToken, session.profile)
        }
    }

    fun logout() {
        val token = tokenStore.read()
        val email = mutableState.value.profile?.email
        tokenStore.clear()
        mutableState.update {
            it.copy(
                profile = null, loyalty = null, orders = emptyList(), addresses = emptyList(), vouchers = emptyList(),
                stockAlerts = emptyList(), tasteMemory = emptyList(), accountError = null,
            )
        }
        if (token != null) viewModelScope.launch {
            if (email != null) PushRegistrationManager.unregister(getApplication(), token, email)
            accounts.logout(token)
        }
    }

    fun refreshAccount() {
        val token = tokenStore.read() ?: return
        accountAction { loadAccount(token, accounts.profile(token)) }
    }

    fun refreshCustomerLibrary() {
        val token = tokenStore.read() ?: return
        viewModelScope.launch {
            runCatching { accounts.fetchCustomerLibrary(token) }
                .onSuccess { library ->
                    mutableState.update { current ->
                        current.copy(
                            favoriteProductIds = library.favorites,
                            recentlyViewedProductIds = library.recentlyViewed,
                            brewJournal = library.brewJournal,
                        ).also(::persistCustomerLibraryCache)
                    }
                }
        }
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
        coffeeData.saveJournal(entry, mutableState.value.profile?.id.orEmpty())
        TallaTelemetry.track("brew_completed", properties = mapOf(
            "method" to entry.method,
            "duration_seconds" to entry.brewTimeSeconds,
            "rating" to entry.rating,
        ))
        TallaTelemetry.track("brew_rated", properties = mapOf("rating" to entry.rating))
        tokenStore.read()?.let { token ->
            viewModelScope.launch { runCatching { accounts.saveBrewJournal(token, entry) } }
        }
    }

    fun deleteBrewJournalEntry(id: String) {
        mutableState.update { current ->
            current.copy(brewJournal = BrewJournalPolicy.remove(current.brewJournal, id)).also(::persistBrewJournal)
        }
        coffeeData.tombstone(mutableState.value.profile?.id.orEmpty(), CoffeeEntityType.BREW_SESSION, id)
        tokenStore.read()?.let { token ->
            viewModelScope.launch { runCatching { accounts.deleteBrewJournal(token, id) } }
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

    fun scanForScales() = scales.scan()
    fun connectScale(address: String) = scales.connect(address)
    fun disconnectScale() = scales.disconnect()
    fun tareScale() = scales.perform(ScaleAction.Tare)
    fun startScaleTimer() = scales.perform(ScaleAction.StartTimer)
    fun pauseScaleTimer() = scales.perform(ScaleAction.PauseTimer)
    fun stopScaleTimer() = scales.perform(ScaleAction.StopTimer)
    fun clearScaleError() = scales.clearError()

    fun deleteAccount() {
        val token = tokenStore.read() ?: return
        accountAction {
            accounts.deleteAccount(token)
            tokenStore.clear()
            mutableState.update {
                TallaUiState(
                    products = it.products,
                    loading = it.loading,
                    error = it.error,
                    remoteSettings = it.remoteSettings,
                )
            }
        }
    }

    fun addPurchasedCoffee(name: String, quantityGrams: Double, roastDate: Long?) {
        val ownerId = mutableState.value.profile?.id.orEmpty()
        coffeeData.savePurchasedCoffee(
            PurchasedCoffee(
                productName = name.trim(),
                roastDate = roastDate,
                purchasedAt = System.currentTimeMillis(),
                initialQuantityGrams = quantityGrams,
                remainingQuantityGrams = quantityGrams,
            ),
            ownerId,
        )
        refreshCoffeeDataState(ownerId)
    }

    fun updateRemainingCoffee(id: String, remainingGrams: Double) {
        val ownerId = mutableState.value.profile?.id.orEmpty()
        coffeeData.updateRemainingQuantity(ownerId, id, remainingGrams)
        refreshCoffeeDataState(ownerId)
    }

    fun resolveCoffeeConflict(conflict: CoffeeConflict, keepLocal: Boolean) {
        coffeeData.resolveConflict(conflict, keepLocal)
        refreshCoffeeDataState(conflict.ownerId)
    }

    override fun onCleared() {
        scales.stopScanning()
        scales.disconnect()
    }

    private fun restoreAccount() {
        val token = tokenStore.read() ?: return
        accountAction {
            val current = runCatching { token to accounts.profile(token) }.getOrElse {
                val refreshToken = tokenStore.readRefreshToken() ?: throw it
                val refreshed = accounts.refreshSession(refreshToken)
                tokenStore.save(refreshed.accessToken, refreshed.refreshToken)
                refreshed.accessToken to accounts.profile(refreshed.accessToken)
            }
            loadAccount(current.first, current.second)
        }
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
        val current = mutableState.value
        val migrationKey = "customer_library_migrated_${profile.id}"
        val cacheOwner = preferences.getString("customer_library_cache_owner", "").orEmpty()
        val library = runCatching {
            if (preferences.getBoolean(migrationKey, false) || (cacheOwner.isNotEmpty() && cacheOwner != profile.id)) {
                accounts.fetchCustomerLibrary(token)
            } else {
                accounts.mergeCustomerLibrary(token, current.favoriteProductIds, current.recentlyViewedProductIds, current.brewJournal)
                    .also { preferences.edit { putBoolean(migrationKey, true) } }
            }
        }.getOrNull()
        mutableState.update {
            it.copy(
                profile = profile, loyalty = loyalty, orders = orders, addresses = addresses, vouchers = vouchers,
                stockAlerts = stockAlerts, tasteMemory = tasteMemory,
                favoriteProductIds = library?.favorites ?: it.favoriteProductIds,
                recentlyViewedProductIds = library?.recentlyViewed ?: it.recentlyViewedProductIds,
                brewJournal = library?.brewJournal ?: it.brewJournal,
                accountLoading = false, accountError = null,
            ).also(::persistCustomerLibraryCache)
        }
        runCatching { PushRegistrationManager.syncForSession(getApplication(), token, profile.email) }
        runCatching {
            coffeeData.synchronize(profile.id, token)
            refreshCoffeeDataState(profile.id)
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
        coffeeData.replaceJournal(state.brewJournal, state.profile?.id.orEmpty())
    }

    private fun persistCustomerLibraryCache(state: TallaUiState) {
        preferences.edit {
            putStringSet("favorites", state.favoriteProductIds)
            putString("recent", JSONArray(state.recentlyViewedProductIds).toString())
            state.profile?.id?.takeIf(String::isNotBlank)?.let { putString("customer_library_cache_owner", it) }
        }
        persistBrewJournal(state)
    }

    private fun loadBrewJournal(): List<BrewJournalEntry> = coffeeData.loadJournal()

    private fun refreshCoffeeDataState(ownerId: String = mutableState.value.profile?.id.orEmpty()) {
        mutableState.update {
            it.copy(
                brewJournal = coffeeData.loadJournal(ownerId),
                coffeeInventory = coffeeData.purchasedCoffee(ownerId),
                coffeeConflicts = coffeeData.conflicts(ownerId),
            )
        }
    }
}
