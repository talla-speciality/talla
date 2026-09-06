package com.talla.speciality.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Coffee
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Contrast
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.ThumbDown
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Badge
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Slider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import androidx.core.net.toUri
import androidx.core.content.FileProvider
import androidx.core.content.ContextCompat
import androidx.core.content.edit
import com.talla.speciality.R
import com.talla.speciality.data.CartLine
import com.talla.speciality.data.BrewRecipeEngine
import com.talla.speciality.data.BrewJournalEntry
import com.talla.speciality.data.BrewRecipe
import com.talla.speciality.data.CoffeeBagScanResult
import com.talla.speciality.data.CoffeeConflict
import com.talla.speciality.data.PurchasedCoffee
import com.talla.speciality.data.CoffeeEquipment
import com.talla.speciality.data.EquipmentCalibration
import com.talla.speciality.data.MaintenanceEvent
import com.talla.speciality.data.EquipmentType
import com.talla.speciality.data.CustomerOrder
import com.talla.speciality.data.Product
import com.talla.speciality.data.ScaleFamily
import com.talla.speciality.data.ScaleUiState
import com.talla.speciality.data.TallaAppSettings
import com.talla.speciality.data.TasteMemoryRecord
import com.talla.speciality.ui.theme.Coffee
import com.talla.speciality.ui.theme.Ink
import com.talla.speciality.ui.theme.Sand
import com.talla.speciality.ui.theme.Sage
import com.talla.speciality.ui.theme.TallaCard
import com.talla.speciality.ui.theme.TallaGoldText
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.net.URL
import java.io.File

private enum class TallaTab(val labelRes: Int, val icon: ImageVector) {
    Home(R.string.home, Icons.Default.Home),
    Shop(R.string.shop, Icons.Default.GridView),
    Brewing(R.string.brewing, Icons.Default.WaterDrop),
    Account(R.string.account, Icons.Default.Person),
}

private enum class CheckoutMethod(val labelRes: Int, val detailRes: Int) {
    CashOnDelivery(R.string.cash_on_delivery, R.string.cash_on_delivery_detail),
    Benefit(R.string.pay_with_benefit_card, R.string.benefit_card_detail),
    ClickToPay(R.string.pay_with_click_to_pay, R.string.click_to_pay_detail),
    BenefitPay(R.string.pay_with_benefitpay, R.string.benefitpay_detail),
}

@Composable
fun TallaApp(
    viewModel: TallaViewModel = viewModel(),
    deepLinkDestination: String? = null,
    onDeepLinkConsumed: () -> Unit = {},
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var tab by remember { mutableStateOf(TallaTab.Home) }
    var cartOpen by remember { mutableStateOf(false) }
    var selectedProduct by remember { mutableStateOf<Product?>(null) }
    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { }

    LaunchedEffect(state.profile?.email) {
        if (state.profile != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val notificationPreferences = context.getSharedPreferences("talla_notifications", 0)
            val alreadyAsked = notificationPreferences.getBoolean("permission_asked", false)
            val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            if (!granted && !alreadyAsked) {
                notificationPreferences.edit { putBoolean("permission_asked", true) }
                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    LaunchedEffect(deepLinkDestination) {
        when (deepLinkDestination) {
            "shop" -> tab = TallaTab.Shop
            "brewing" -> tab = TallaTab.Brewing
            "rewards" -> tab = TallaTab.Account
        }
        if (deepLinkDestination != null) onDeepLinkConsumed()
    }

    LaunchedEffect(state.checkoutUrl) {
        state.checkoutUrl?.let { url ->
            context.startActivity(Intent(Intent.ACTION_VIEW, url.toUri()))
            viewModel.consumeCheckoutUrl()
        }
    }

    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        viewModel.checkHostedBenefitStatus()
        viewModel.checkClickToPayStatus()
        viewModel.refreshCustomerLibrary()
    }

    val openProduct: (Product) -> Unit = { product ->
        viewModel.markViewed(product.id)
        selectedProduct = product
    }

    Scaffold(
        topBar = {
            TallaTopBar(
                cartCount = state.cartCount,
                profileName = state.profile?.firstName,
                showCart = tab == TallaTab.Home || tab == TallaTab.Shop,
                onCartClick = { cartOpen = true },
            )
        },
        bottomBar = {
            NavigationBar(
                modifier = Modifier.navigationBarsPadding().height(64.dp),
                containerColor = MaterialTheme.colorScheme.surface.copy(alpha = .96f),
                tonalElevation = 0.dp,
                windowInsets = androidx.compose.foundation.layout.WindowInsets(0),
            ) {
                TallaTab.entries.forEach { destination ->
                    NavigationBarItem(
                        selected = tab == destination,
                        onClick = { tab = destination },
                        modifier = Modifier.testTag("tab.${destination.name.lowercase()}"),
                        icon = { Icon(destination.icon, contentDescription = stringResource(destination.labelRes)) },
                        label = { Text(stringResource(destination.labelRes)) },
                    )
                }
            }
        },
    ) { padding ->
        when (tab) {
            TallaTab.Home -> HomeScreen(
                state = state,
                retry = viewModel::refresh,
                add = viewModel::addToCart,
                open = openProduct,
                openShop = { tab = TallaTab.Shop },
                openBrewing = { tab = TallaTab.Brewing },
                modifier = Modifier.padding(padding),
            )
            TallaTab.Shop -> ShopScreen(
                state = state,
                retry = viewModel::refresh,
                add = viewModel::addToCart,
                open = openProduct,
                toggleFavorite = viewModel::toggleFavorite,
                modifier = Modifier.padding(padding),
            )
            TallaTab.Brewing -> BrewingScreen(
                journalEntries = state.brewJournal,
                scanResult = state.coffeeBagScan,
                scanning = state.coffeeBagScanning,
                scanError = state.coffeeBagScanError,
                onScanCoffeeBag = viewModel::scanCoffeeBag,
                onClearScan = viewModel::clearCoffeeBagScan,
                scaleState = state.scale,
                onScanScales = viewModel::scanForScales,
                onConnectScale = viewModel::connectScale,
                onDisconnectScale = viewModel::disconnectScale,
                onTareScale = viewModel::tareScale,
                onStartScaleTimer = viewModel::startScaleTimer,
                onPauseScaleTimer = viewModel::pauseScaleTimer,
                onStopScaleTimer = viewModel::stopScaleTimer,
                onClearScaleError = viewModel::clearScaleError,
                onSaveJournal = viewModel::saveBrewJournalEntry,
                onDeleteJournal = viewModel::deleteBrewJournalEntry,
                inventory = state.coffeeInventory,
                equipment = state.coffeeEquipment,
                calibrations = state.coffeeCalibrations,
                maintenance = state.coffeeMaintenance,
                conflicts = state.coffeeConflicts,
                onAddCoffee = viewModel::addPurchasedCoffee,
                onUpdateRemaining = viewModel::updateRemainingCoffee,
                onSaveEquipment = viewModel::saveCoffeeEquipment,
                onSaveCalibration = viewModel::saveCoffeeCalibration,
                onSaveMaintenance = viewModel::saveCoffeeMaintenance,
                onDeleteEquipment = viewModel::deleteCoffeeEquipment,
                onDeleteCalibration = viewModel::deleteCoffeeCalibration,
                onDeleteMaintenance = viewModel::deleteCoffeeMaintenance,
                onResolveConflict = viewModel::resolveCoffeeConflict,
                modifier = Modifier.padding(padding),
            )
            TallaTab.Account -> AccountScreen(
                state = state,
                onLogin = viewModel::login,
                onRegister = viewModel::register,
                onLogout = viewModel::logout,
                onDeleteAccount = viewModel::deleteAccount,
                onRefresh = viewModel::refreshAccount,
                onSaveAddress = viewModel::saveAddress,
                onDeleteAddress = viewModel::deleteAddress,
                onSaveTasteMemory = viewModel::saveTasteMemory,
                openProduct = openProduct,
                modifier = Modifier.padding(padding),
            )
        }
    }

    if (cartOpen) {
        CartSheet(
            lines = state.cart.values.toList(),
            settings = state.remoteSettings.app,
            onAdd = { viewModel.addToCart(it.product) },
            onRemove = { viewModel.removeFromCart(it.variant.id) },
            loading = state.checkoutLoading,
            error = state.checkoutError,
            onCheckout = viewModel::beginCheckout,
            onHostedBenefit = viewModel::beginHostedBenefit,
            onClickToPay = viewModel::beginClickToPay,
            onBenefitPay = viewModel::beginBenefitPay,
            onClearError = viewModel::clearCheckoutError,
            onDismiss = { cartOpen = false },
        )
    }

    if (state.remoteSettings.app.release.maintenanceEnabled) {
        val isArabic = LocalConfiguration.current.locales[0].language == "ar"
        AlertDialog(
            onDismissRequest = {},
            confirmButton = {},
            icon = { Image(painterResource(R.drawable.talla_logo), null, Modifier.size(58.dp)) },
            title = { Text(if (isArabic) state.remoteSettings.app.release.titleAr else state.remoteSettings.app.release.titleEn, style = MaterialTheme.typography.titleLarge) },
            text = { Text(if (isArabic) state.remoteSettings.app.release.messageAr else state.remoteSettings.app.release.messageEn) },
        )
    }

    state.benefitPaySession?.let { session ->
        BenefitPaySheet(
            session = session,
            loading = state.checkoutLoading,
            onSuccess = { viewModel.confirmBenefitPay(session) },
            onFailure = viewModel::failBenefitPay,
            onDismiss = viewModel::dismissBenefitPay,
        )
    }

    state.paymentMessage?.let { message ->
        AlertDialog(
            onDismissRequest = viewModel::clearPaymentMessage,
            confirmButton = { TextButton(onClick = viewModel::clearPaymentMessage) { Text(stringResource(R.string.done)) } },
            title = { Text(stringResource(R.string.payment_confirmed)) },
            text = { Text(message) },
        )
    }

    selectedProduct?.let { product ->
        ProductDetailsSheet(
            product = product,
            favorite = product.id in state.favoriteProductIds,
            watchingStock = state.stockAlerts.any { it.productId == product.id },
            onFavorite = { viewModel.toggleFavorite(product.id) },
            onStockAlert = { viewModel.toggleStockAlert(product) },
            onAdd = { variantId -> viewModel.addToCart(product, variantId) },
            onDismiss = { selectedProduct = null },
        )
    }
}

@Composable
private fun TallaTopBar(cartCount: Int, profileName: String?, showCart: Boolean, onCartClick: () -> Unit) {
    var settingsOpen by remember { mutableStateOf(false) }
    val languageTag = AppCompatDelegate.getApplicationLocales().toLanguageTags()
    Row(
        modifier = Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surface.copy(alpha = .96f))
            .statusBarsPadding().padding(horizontal = 18.dp).padding(top = 14.dp, bottom = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            painter = painterResource(R.drawable.talla_logo),
            contentDescription = "Talla",
            modifier = Modifier.size(if (profileName == null) 52.dp else 44.dp),
        )
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            if (profileName == null) {
                Text("TALLA", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, letterSpacing = androidx.compose.ui.unit.TextUnit.Unspecified)
            } else {
                Text(stringResource(R.string.welcome_back), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                Text(profileName, style = MaterialTheme.typography.titleLarge, maxLines = 1)
            }
        }
        if (showCart) {
            IconButton(onClick = onCartClick, modifier = Modifier.size(40.dp).clip(CircleShape).background(TallaCard)) {
                BadgedBox(badge = { if (cartCount > 0) Badge(containerColor = Sand) { Text(cartCount.toString(), color = Ink) } }) {
                    Icon(Icons.Default.ShoppingBag, contentDescription = stringResource(R.string.shopping_bag), tint = TallaGoldText)
                }
            }
        }
        Spacer(Modifier.width(8.dp))
        Box(Modifier.size(40.dp).clip(CircleShape).background(TallaCard).clickable { settingsOpen = true }, contentAlignment = Alignment.Center) {
            Icon(Icons.Default.Contrast, contentDescription = stringResource(R.string.appearance_and_language), tint = TallaGoldText, modifier = Modifier.size(19.dp))
            DropdownMenu(expanded = settingsOpen, onDismissRequest = { settingsOpen = false }) {
                DropdownMenuItem(text = { Text("System appearance") }, onClick = { AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM); settingsOpen = false })
                DropdownMenuItem(text = { Text("Light appearance") }, onClick = { AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO); settingsOpen = false })
                DropdownMenuItem(text = { Text("Dark appearance") }, onClick = { AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES); settingsOpen = false })
                HorizontalDivider()
                DropdownMenuItem(text = { Text(if (languageTag.isBlank()) "✓  System language" else "System language") }, onClick = { AppCompatDelegate.setApplicationLocales(LocaleListCompat.getEmptyLocaleList()); settingsOpen = false })
                DropdownMenuItem(text = { Text(if (languageTag.startsWith("en")) "✓  English" else "English") }, onClick = { AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("en")); settingsOpen = false })
                DropdownMenuItem(text = { Text(if (languageTag.startsWith("ar")) "✓  العربية" else "العربية") }, onClick = { AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("ar")); settingsOpen = false })
            }
        }
    }
}

@Composable
private fun HomeScreen(
    state: TallaUiState,
    retry: () -> Unit,
    add: (Product) -> Unit,
    open: (Product) -> Unit,
    openShop: () -> Unit,
    openBrewing: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val home = state.remoteSettings.home
    val app = state.remoteSettings.app
    val quickDrinks = productsInAdminOrder(state.products, home.quickDrinkProductIds, 6)
    val signatureRoasts = productsInAdminOrder(state.products, home.signatureRoastProductIds, 4)
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 4.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        item { HeroCard(home, openShop, openBrewing) }
        if (app.announcement.enabled && app.announcement.title.isNotBlank() && app.announcement.message.isNotBlank()) {
            item { AnnouncementCard(app.announcement) }
        }
        if (state.remoteSettings.events.isNotEmpty()) {
            item {
                Text("SEASONAL AT TALLA", modifier = Modifier.padding(horizontal = 18.dp, vertical = 10.dp), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                LazyRow(contentPadding = PaddingValues(horizontal = 18.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(state.remoteSettings.events, key = { it.id }) { event -> SeasonalEventCard(event, openShop) }
                }
                Spacer(Modifier.height(18.dp))
            }
        }
        if (app.homeSections.showQuickDrinks && (quickDrinks.isNotEmpty() || state.loading)) {
            item {
                HomeSectionHeader(stringResource(R.string.talla_express), stringResource(R.string.quick_drinks_title), stringResource(R.string.see_all), openShop)
                ProductStatus(state, retry) {
                    LazyRow(contentPadding = PaddingValues(horizontal = 18.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        items(quickDrinks.ifEmpty { state.products.take(6) }, key = { it.id }) { product ->
                            QuickDrinkCard(product, add, open)
                        }
                    }
                }
                Spacer(Modifier.height(18.dp))
            }
        }
        if (app.homeSections.showSignatureRoasts) {
            item {
                HomeSectionHeader(stringResource(R.string.roastery_selection), stringResource(R.string.signature_roasts), stringResource(R.string.browse_shop), openShop)
                ProductStatus(state, retry) {
                    LazyRow(contentPadding = PaddingValues(horizontal = 18.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        items(signatureRoasts.ifEmpty { state.products.take(4) }, key = { it.id }) { product ->
                            SignatureRoastCard(product, add, open)
                        }
                    }
                }
                Spacer(Modifier.height(14.dp))
            }
        }
        item { MoreFromTallaSection(state, add, open, openShop) }
    }
}

@Composable
private fun HeroCard(home: com.talla.speciality.data.HomeSettings, openShop: () -> Unit, openBrewing: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 4.dp)
            .clip(RoundedCornerShape(24.dp))
            .background(Brush.linearGradient(listOf(Color(0xFFFFF7ED), Color(0xFFEAD9C3))))
            .border(1.dp, Sand.copy(alpha = .16f), RoundedCornerShape(24.dp))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(home.heroEyebrow ?: stringResource(R.string.roastery), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                Text(stringResource(R.string.coffee_daily_rituals), style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
            }
            Text(
                "✦  ${(home.heroBadge ?: stringResource(R.string.fresh_roast)).uppercase()}",
                modifier = Modifier.clip(CircleShape).background(Color(0xFFF3DFC2)).padding(horizontal = 10.dp, vertical = 6.dp),
                style = MaterialTheme.typography.labelMedium,
                color = Color(0xFF8B5B2A),
            )
        }
        Text(home.heroTitle ?: "Specialty coffee,\nroasted with intention", style = MaterialTheme.typography.displaySmall, color = Ink)
        Text(home.heroSubtitle ?: "Thoughtful coffees, roasted in Bahrain for expressive cups and everyday rituals.", style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Button(
                onClick = openShop,
                modifier = Modifier.weight(1f).height(40.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF0A0804)),
                shape = RoundedCornerShape(14.dp),
                contentPadding = PaddingValues(horizontal = 8.dp),
            ) { Text((home.primaryButtonTitle ?: stringResource(R.string.explore_coffees)).uppercase(), style = MaterialTheme.typography.labelLarge, maxLines = 1) }
            Button(
                onClick = openBrewing,
                modifier = Modifier.weight(1f).height(40.dp).border(1.dp, Sand.copy(alpha = .18f), RoundedCornerShape(14.dp)),
                colors = ButtonDefaults.buttonColors(containerColor = TallaCard, contentColor = Ink),
                shape = RoundedCornerShape(14.dp),
                contentPadding = PaddingValues(horizontal = 8.dp),
            ) { Text((home.secondaryButtonTitle ?: stringResource(R.string.brewing_guide)).uppercase(), style = MaterialTheme.typography.labelLarge, maxLines = 1) }
        }
    }
}

private fun productsInAdminOrder(products: List<Product>, ids: List<String>, limit: Int): List<Product> {
    if (ids.isEmpty()) return emptyList()
    val byId = products.associateBy { it.id }
    return ids.mapNotNull(byId::get).take(limit)
}

@Composable
private fun AnnouncementCard(announcement: com.talla.speciality.data.TallaAnnouncement) {
    val context = LocalContext.current
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 7.dp)
            .clip(RoundedCornerShape(20.dp)).background(TallaCard)
            .border(1.dp, Sand.copy(alpha = .24f), RoundedCornerShape(20.dp))
            .clickable(enabled = announcement.actionUrl.isNotBlank()) {
                runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(announcement.actionUrl))) }
            }.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text("📣  ${announcement.title}", style = MaterialTheme.typography.titleMedium, color = Ink)
        Text(announcement.message, style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
        if (announcement.actionLabel.isNotBlank()) Text(announcement.actionLabel.uppercase(), style = MaterialTheme.typography.labelLarge, color = TallaGoldText)
    }
}

@Composable
private fun SeasonalEventCard(event: com.talla.speciality.data.SeasonalEvent, openShop: () -> Unit) {
    val isArabic = LocalConfiguration.current.locales[0].language == "ar"
    val title = if (isArabic && event.titleAr.isNotBlank()) event.titleAr else event.titleEn
    val subtitle = if (isArabic && event.subtitleAr.isNotBlank()) event.subtitleAr else event.subtitleEn
    val badge = if (isArabic && event.badgeAr.isNotBlank()) event.badgeAr else event.badgeEn
    val cta = if (isArabic && event.ctaAr.isNotBlank()) event.ctaAr else event.ctaEn
    val accent = parseHexColor(event.accentHex, Sand)
    val secondary = parseHexColor(event.secondaryHex, Color(0xFF2A1D14))
    Column(
        Modifier.width(326.dp).height(220.dp).clip(RoundedCornerShape(24.dp))
            .background(Brush.linearGradient(listOf(secondary, secondary.copy(alpha = .88f), accent.copy(alpha = .78f))))
            .border(1.dp, accent.copy(alpha = .38f), RoundedCornerShape(24.dp))
            .clickable(onClick = openShop).padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        if (badge.isNotBlank()) Text(badge.uppercase(), modifier = Modifier.clip(CircleShape).background(accent).padding(horizontal = 9.dp, vertical = 5.dp), style = MaterialTheme.typography.labelMedium, color = secondary)
        Text(title, style = MaterialTheme.typography.titleLarge, color = Color.White, maxLines = 2)
        Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = Color.White.copy(alpha = .82f), maxLines = 3)
        Spacer(Modifier.weight(1f))
        Text((cta.ifBlank { "Explore" }) + "  →", style = MaterialTheme.typography.labelLarge, color = accent)
    }
}

private fun parseHexColor(value: String, fallback: Color): Color = runCatching {
    Color(android.graphics.Color.parseColor(value))
}.getOrDefault(fallback)

@Composable
private fun HomeSectionHeader(eyebrow: String, title: String, action: String, onAction: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 8.dp), verticalAlignment = Alignment.Bottom) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(eyebrow, style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
            Text(title, style = MaterialTheme.typography.headlineSmall, color = Ink)
        }
        Text(action, modifier = Modifier.clickable(onClick = onAction).padding(8.dp), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
    }
}

@Composable
private fun QuickDrinkCard(product: Product, add: (Product) -> Unit, open: (Product) -> Unit) {
    Column(
        Modifier.width(154.dp).clip(RoundedCornerShape(18.dp)).background(TallaCard)
            .border(1.dp, Sand.copy(alpha = .16f), RoundedCornerShape(18.dp)).padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        RemoteImage(product.imageUrl, product.name, Modifier.fillMaxWidth().height(106.dp).clip(RoundedCornerShape(14.dp)).clickable { open(product) })
        Text(product.name, style = MaterialTheme.typography.titleMedium, color = Ink, maxLines = 2, modifier = Modifier.height(42.dp))
        Text(product.priceLabel, style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
        Button(
            onClick = { if (product.variants.size > 1) open(product) else add(product) },
            modifier = Modifier.fillMaxWidth().height(36.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF0A0804)),
            shape = CircleShape,
            contentPadding = PaddingValues(horizontal = 6.dp),
        ) { Text(stringResource(if (product.variants.size > 1) R.string.choose else R.string.buy_now).uppercase(), style = MaterialTheme.typography.labelMedium) }
    }
}

@Composable
private fun SignatureRoastCard(
    product: Product,
    add: (Product) -> Unit,
    open: (Product) -> Unit,
) {
    Column(
        Modifier.width(176.dp).height(258.dp).clip(RoundedCornerShape(18.dp)).background(TallaCard)
            .border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(18.dp))
            .clickable { open(product) }.padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        RemoteImage(product.imageUrl, product.name, Modifier.fillMaxWidth().height(122.dp).clip(RoundedCornerShape(14.dp)))
        Text(product.category.uppercase(), style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = TallaGoldText, maxLines = 1)
        Text(
            product.name,
            modifier = Modifier.fillMaxWidth().height(38.dp),
            style = MaterialTheme.typography.titleMedium.copy(fontSize = 15.sp),
            color = Ink,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text(product.priceLabel, Modifier.weight(1f), style = MaterialTheme.typography.labelLarge, color = TallaGoldText, maxLines = 1)
            Button(
                onClick = { if (product.variants.size > 1) open(product) else add(product) },
                enabled = product.defaultVariant?.available == true,
                modifier = Modifier.width(82.dp).height(30.dp),
                contentPadding = PaddingValues(horizontal = 5.dp, vertical = 0.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF0A0804)),
                shape = CircleShape,
            ) {
                Text(stringResource(if (product.variants.size > 1) R.string.options else R.string.add).uppercase(), style = MaterialTheme.typography.labelSmall, maxLines = 1)
            }
        }
    }
}

@Composable
private fun MoreFromTallaSection(
    state: TallaUiState,
    add: (Product) -> Unit,
    open: (Product) -> Unit,
    openShop: () -> Unit,
) {
    var expanded by remember { mutableStateOf(false) }
    var pickOffset by remember { mutableIntStateOf(0) }
    val configuredPick = state.remoteSettings.home.funPickProductId?.let { id -> state.products.firstOrNull { it.id == id } }
    val pickPool = state.products.filter { it.defaultVariant?.available == true }
    val hotPick = configuredPick ?: pickPool.getOrNull(if (pickPool.isEmpty()) 0 else pickOffset.mod(pickPool.size))
    val favorites = state.products.filter { it.id in state.favoriteProductIds }
    val recent = state.recentlyViewedProductIds.mapNotNull { id -> state.products.firstOrNull { it.id == id } }
    val defaultOrigins = listOf(
        com.talla.speciality.data.PassportOrigin("ethiopia", "Ethiopia", "🇪🇹", listOf("ethiopia", "ethiopian"), null),
        com.talla.speciality.data.PassportOrigin("yemen", "Yemen", "🇾🇪", listOf("yemen", "yemeni"), null),
        com.talla.speciality.data.PassportOrigin("colombia", "Colombia", "🇨🇴", listOf("colombia", "colombian"), null),
        com.talla.speciality.data.PassportOrigin("brazil", "Brazil", "🇧🇷", listOf("brazil", "brazilian"), null),
    )
    val origins = state.remoteSettings.passport.origins.ifEmpty { defaultOrigins }
    val purchasedText = state.orders.flatMap { it.items }.joinToString(" ") { it.name }.lowercase()
    val stamped = origins.filter { origin ->
        (origin.keywords + origin.title).any { keyword -> keyword.isNotBlank() && purchasedText.contains(keyword.lowercase()) }
    }.map { it.id }.toSet()

    Column(
        Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 4.dp)
            .clip(RoundedCornerShape(22.dp)).background(TallaCard)
            .border(1.dp, Sand.copy(alpha = .18f), RoundedCornerShape(22.dp))
            .clickable { expanded = !expanded }.padding(15.dp),
        verticalArrangement = Arrangement.spacedBy(13.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(stringResource(R.string.more_from_talla), style = MaterialTheme.typography.titleMedium, color = Ink)
                Text(stringResource(R.string.more_from_talla_summary), style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
            }
            Text(if (expanded) "⌃" else "⌄", style = MaterialTheme.typography.titleLarge, color = TallaGoldText)
        }
        if (expanded) {
            if (state.remoteSettings.app.homeSections.showFunPick && hotPick != null) {
                HorizontalDivider(color = Sand.copy(alpha = .14f))
                Text(stringResource(R.string.todays_hot_pick), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Sand.copy(alpha = .09f))
                        .clickable { open(hotPick) }.padding(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    RemoteImage(hotPick.imageUrl, hotPick.name, Modifier.size(74.dp).clip(RoundedCornerShape(14.dp)))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(hotPick.name, style = MaterialTheme.typography.titleMedium, color = Ink, maxLines = 2)
                        Text(hotPick.priceLabel, style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                        Text(stringResource(R.string.hot_pick_detail), style = MaterialTheme.typography.bodySmall, color = Ink.copy(alpha = .68f), maxLines = 2)
                    }
                }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = { if (pickPool.isNotEmpty()) pickOffset += 1 }, modifier = Modifier.weight(1f)) {
                        Icon(Icons.Default.Refresh, null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(5.dp))
                        Text(stringResource(R.string.surprise_me))
                    }
                    Button(
                        onClick = { if (hotPick.variants.size > 1) open(hotPick) else add(hotPick) },
                        modifier = Modifier.weight(1f), shape = CircleShape,
                        colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF0A0804)),
                    ) { Text(stringResource(R.string.buy_now).uppercase()) }
                }
            }

            if (state.remoteSettings.app.homeSections.showPassport && origins.isNotEmpty()) {
                HorizontalDivider(color = Sand.copy(alpha = .14f))
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                    Text("☕", modifier = Modifier.size(38.dp).clip(CircleShape).background(Sand).padding(8.dp), color = Color(0xFF0A0804))
                    Column(Modifier.weight(1f)) {
                        Text(stringResource(R.string.talla_passport), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                        Text(stringResource(R.string.passport_progress, stamped.size, origins.size), style = MaterialTheme.typography.titleSmall, color = Ink)
                    }
                }
                LinearProgressIndicator(
                    progress = { if (origins.isEmpty()) 0f else stamped.size.toFloat() / origins.size },
                    modifier = Modifier.fillMaxWidth().height(7.dp).clip(CircleShape),
                    color = Sage,
                    trackColor = Sand.copy(alpha = .15f),
                )
                Text(
                    if (stamped.size == origins.size) state.remoteSettings.passport.completionRewardTitle ?: stringResource(R.string.passport_complete)
                    else stringResource(R.string.passport_reward_hint),
                    style = MaterialTheme.typography.bodySmall, color = Ink.copy(alpha = .68f),
                )
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    origins.take(4).forEach { origin ->
                        Column(
                            Modifier.weight(1f).clip(RoundedCornerShape(12.dp))
                                .background(if (origin.id in stamped) Sage.copy(alpha = .18f) else Sand.copy(alpha = .08f)).padding(7.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            Text(origin.emoji.ifBlank { "☕" })
                            Text(origin.title, style = MaterialTheme.typography.labelSmall, color = Ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }
                }
            }

            if (favorites.isNotEmpty()) {
                HorizontalDivider(color = Sand.copy(alpha = .14f))
                HomeSectionHeader(stringResource(R.string.saved), stringResource(R.string.favorites), stringResource(R.string.shop_all), openShop)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(favorites, key = { it.id }) { product -> QuickDrinkCard(product, add, open) }
                }
            }
            if (recent.isNotEmpty()) {
                HorizontalDivider(color = Sand.copy(alpha = .14f))
                Text(stringResource(R.string.recently_viewed), style = MaterialTheme.typography.titleMedium, color = Ink)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(recent.take(8), key = { it.id }) { product -> QuickDrinkCard(product, add, open) }
                }
            }
        }
    }
}

@Composable
private fun SectionHeading(title: String, action: String? = null) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(title, modifier = Modifier.weight(1f), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        if (action != null) Text(action, color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
private fun ShopScreen(
    state: TallaUiState,
    retry: () -> Unit,
    add: (Product) -> Unit,
    open: (Product) -> Unit,
    toggleFavorite: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    var query by remember { mutableStateOf("") }
    var category by remember { mutableStateOf<String?>(null) }
    val categories = state.products.map { it.category }.distinct().sorted()
    val visibleProducts = state.products.filter { product ->
        (category == null || product.category == category) &&
            (query.isBlank() || product.name.contains(query, ignoreCase = true) || product.description.contains(query, ignoreCase = true))
    }
    Column(modifier.fillMaxSize().padding(horizontal = 18.dp)) {
        Column(Modifier.padding(top = 14.dp, bottom = 12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(stringResource(R.string.shop_eyebrow).uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
            Text(stringResource(R.string.shop_heading), style = MaterialTheme.typography.displaySmall.copy(fontSize = 28.sp, lineHeight = 32.sp), color = Ink)
        }
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Search summer boxes, cups, CRMB...") },
            leadingIcon = { Icon(Icons.Default.Search, null, tint = TallaGoldText) },
            singleLine = true,
            shape = RoundedCornerShape(18.dp),
        )
        Text(stringResource(R.string.categories).uppercase(), modifier = Modifier.padding(top = 16.dp, bottom = 8.dp), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
        LazyRow(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
            item { TallaCategoryChip(stringResource(R.string.all), category == null) { category = null } }
            items(categories) { item -> TallaCategoryChip(item, category == item) { category = item } }
        }
        Row(
            Modifier.fillMaxWidth().padding(top = 12.dp, bottom = 12.dp)
                .clip(RoundedCornerShape(18.dp)).background(TallaCard)
                .border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(18.dp)).padding(horizontal = 14.dp, vertical = 11.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text((category ?: stringResource(R.string.all_products)).uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                Text(if (query.isBlank()) stringResource(R.string.products_count, visibleProducts.size) else "${visibleProducts.size} results for “$query”", style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
            }
            Text("SORT: FEATURED  ⌄", style = MaterialTheme.typography.labelMedium, color = Ink, modifier = Modifier.clip(CircleShape).border(1.dp, Sand.copy(alpha = .18f), CircleShape).padding(horizontal = 12.dp, vertical = 9.dp))
        }
        ProductStatus(state, retry) {
            LazyVerticalGrid(
                modifier = Modifier.fillMaxSize(),
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(top = 4.dp, bottom = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                items(visibleProducts, key = { it.id }) { product ->
                    ProductCard(product, add, open, product.id in state.favoriteProductIds) { toggleFavorite(product.id) }
                }
            }
        }
    }
}

@Composable
private fun TallaCategoryChip(title: String, selected: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.height(40.dp).clip(RoundedCornerShape(16.dp)).background(TallaCard)
            .border(if (selected) 2.dp else 1.dp, Sand.copy(alpha = if (selected) .82f else .18f), RoundedCornerShape(16.dp))
            .clickable(onClick = onClick).padding(horizontal = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        Icon(Icons.Default.LocalCafe, null, tint = TallaGoldText, modifier = Modifier.size(16.dp))
        Text(title.uppercase(), style = MaterialTheme.typography.labelMedium, color = Ink)
        if (selected) Text("✓", style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
    }
}

@Composable
private fun ProductStatus(state: TallaUiState, retry: () -> Unit, content: @Composable () -> Unit) {
    when {
        state.loading -> Box(Modifier.fillMaxWidth().height(180.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        state.error != null -> Column(Modifier.fillMaxWidth().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(state.error, color = MaterialTheme.colorScheme.error)
            TextButton(onClick = retry) { Icon(Icons.Default.Refresh, null); Spacer(Modifier.width(6.dp)); Text(stringResource(R.string.try_again)) }
        }
        else -> content()
    }
}

@Composable
private fun ProductCard(
    product: Product,
    add: (Product) -> Unit,
    open: (Product) -> Unit,
    favorite: Boolean,
    modifier: Modifier = Modifier,
    onFavorite: (() -> Unit)? = null,
) {
    Column(
        modifier.height(340.dp).clip(RoundedCornerShape(22.dp)).background(TallaCard)
            .border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(22.dp))
            .clickable { open(product) }.padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(Modifier.fillMaxWidth().height(138.dp)) {
            RemoteImage(product.imageUrl, product.name, Modifier.fillMaxSize().clip(RoundedCornerShape(10.dp)))
            if (onFavorite != null) {
                IconButton(
                    onClick = onFavorite,
                    modifier = Modifier.align(Alignment.TopEnd).padding(8.dp).size(34.dp).clip(CircleShape).background(TallaCard.copy(alpha = .94f)),
                ) {
                    Icon(if (favorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder, stringResource(R.string.favorites), tint = if (favorite) Sand else Ink, modifier = Modifier.size(17.dp))
                }
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(product.category.uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText, maxLines = 1)
            Text(product.name, modifier = Modifier.fillMaxWidth().height(40.dp), maxLines = 2, overflow = TextOverflow.Ellipsis, style = MaterialTheme.typography.titleMedium.copy(fontSize = 16.sp), color = Ink)
            Text(product.description.ifBlank { " " }, maxLines = 1, overflow = TextOverflow.Ellipsis, style = MaterialTheme.typography.bodyMedium.copy(fontSize = 11.sp), color = Ink.copy(alpha = .72f), modifier = Modifier.fillMaxWidth().height(16.dp))
        }
        Spacer(Modifier.weight(1f))
        Text(product.priceLabel, style = MaterialTheme.typography.labelLarge.copy(fontSize = 14.sp), color = if (product.defaultVariant?.available == true) TallaGoldText else Ink.copy(alpha = .5f), maxLines = 1)
        Button(
            onClick = { if (product.variants.size > 1) open(product) else add(product) },
            enabled = product.defaultVariant?.available == true,
            colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF0A0804)),
            contentPadding = PaddingValues(horizontal = 10.dp),
            modifier = Modifier.fillMaxWidth().height(38.dp),
            shape = CircleShape,
        ) { Text(stringResource(if (product.variants.size > 1) R.string.options else R.string.add).uppercase(), style = MaterialTheme.typography.labelMedium) }
    }
}

@Composable
private fun RemoteImage(url: String?, description: String, modifier: Modifier = Modifier) {
    val bitmap by produceState<android.graphics.Bitmap?>(null, url) {
        value = if (url == null) null else withContext(Dispatchers.IO) {
            runCatching { URL(url).openStream().use(BitmapFactory::decodeStream) }.getOrNull()
        }
    }
    Box(modifier.background(Sand.copy(alpha = .22f)), contentAlignment = Alignment.Center) {
        if (bitmap == null) Icon(Icons.Default.LocalCafe, null, tint = Sand, modifier = Modifier.size(56.dp))
        else Image(bitmap!!.asImageBitmap(), description, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
    }
}

@Composable
private fun BrewingScreen(
    journalEntries: List<BrewJournalEntry>,
    scanResult: CoffeeBagScanResult?,
    scanning: Boolean,
    scanError: String?,
    onScanCoffeeBag: (Uri) -> Unit,
    onClearScan: () -> Unit,
    scaleState: ScaleUiState,
    onScanScales: () -> Unit,
    onConnectScale: (String) -> Unit,
    onDisconnectScale: () -> Unit,
    onTareScale: () -> Unit,
    onStartScaleTimer: () -> Unit,
    onPauseScaleTimer: () -> Unit,
    onStopScaleTimer: () -> Unit,
    onClearScaleError: () -> Unit,
    onSaveJournal: (String, String, Int, Double, Int, Int, Int, String) -> Unit,
    onDeleteJournal: (String) -> Unit,
    inventory: List<PurchasedCoffee>,
    equipment: List<CoffeeEquipment>,
    calibrations: List<EquipmentCalibration>,
    maintenance: List<MaintenanceEvent>,
    conflicts: List<CoffeeConflict>,
    onAddCoffee: (String, Double, Long?) -> Unit,
    onUpdateRemaining: (String, Double) -> Unit,
    onSaveEquipment: (String?, EquipmentType, String, String?, String?) -> Unit,
    onSaveCalibration: (String?, String, String, Double?, String?, String?) -> Unit,
    onSaveMaintenance: (String?, String, String, String?) -> Unit,
    onDeleteEquipment: (String) -> Unit,
    onDeleteCalibration: (String) -> Unit,
    onDeleteMaintenance: (String) -> Unit,
    onResolveConflict: (CoffeeConflict, Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val methods = listOf("V60", "Kalita", "AeroPress", "French press", "Espresso", "Cold brew")
    var brewer by remember { mutableStateOf("V60") }
    var dose by remember { mutableFloatStateOf(20f) }
    var ratio by remember { mutableFloatStateOf(15f) }
    var elapsed by remember { mutableIntStateOf(0) }
    var running by remember { mutableStateOf(false) }
    var showBrewWorkspace by remember { mutableStateOf(false) }
    val recipe = remember(brewer, dose, ratio) { BrewRecipeEngine.generate(brewer, dose.toInt(), ratio.toDouble()) }
    val activeStepIndex = recipe.steps.indexOfLast { it.startSeconds <= elapsed }.coerceAtLeast(0)

    LaunchedEffect(running) {
        while (running) {
            delay(1_000)
            elapsed += 1
        }
    }

    if (!showBrewWorkspace) {
        BrewingDashboard(
            latestEntry = journalEntries.firstOrNull(),
            onCreateRecipe = { showBrewWorkspace = true },
            onScanBag = { showBrewWorkspace = true },
            onOpenTool = { showBrewWorkspace = true },
            modifier = modifier,
        )
        return
    }

    LazyColumn(modifier.fillMaxSize(), contentPadding = PaddingValues(horizontal = 18.dp, vertical = 28.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        item {
            TextButton(onClick = { showBrewWorkspace = false }, contentPadding = PaddingValues(0.dp)) { Text("←  BREWING METHODS", style = MaterialTheme.typography.labelMedium, color = TallaGoldText) }
        }
        item {
            CoffeeBagScannerCard(
                result = scanResult,
                scanning = scanning,
                error = scanError,
                onScan = onScanCoffeeBag,
                onClear = onClearScan,
            )
        }
        item {
            CoffeeInventoryCard(
                inventory = inventory,
                equipment = equipment,
                calibrations = calibrations,
                maintenance = maintenance,
                conflicts = conflicts,
                onAddCoffee = onAddCoffee,
                onUpdateRemaining = onUpdateRemaining,
                onSaveEquipment = onSaveEquipment,
                onSaveCalibration = onSaveCalibration,
                onSaveMaintenance = onSaveMaintenance,
                onDeleteEquipment = onDeleteEquipment,
                onDeleteCalibration = onDeleteCalibration,
                onDeleteMaintenance = onDeleteMaintenance,
                onResolveConflict = onResolveConflict,
            )
        }
        item {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(methods) { method -> FilterChip(selected = brewer == method, onClick = { brewer = method; elapsed = 0; running = false }, label = { Text(method) }) }
            }
        }
        item {
            Card(shape = RoundedCornerShape(22.dp)) {
                Column(Modifier.fillMaxWidth().padding(18.dp)) {
                    Text("Coffee · ${dose.toInt()} g", fontWeight = FontWeight.Bold)
                    Slider(value = dose, onValueChange = { dose = it; elapsed = 0 }, valueRange = 10f..60f, steps = 49)
                    if (brewer != "Espresso") {
                        Text("Ratio · 1:${"%.1f".format(ratio)}", fontWeight = FontWeight.Bold)
                        Slider(value = ratio, onValueChange = { ratio = it; elapsed = 0 }, valueRange = 10f..20f, steps = 19)
                    }
                }
            }
        }
        item {
            Card(colors = CardDefaults.cardColors(containerColor = Coffee), shape = RoundedCornerShape(24.dp)) {
                Row(Modifier.fillMaxWidth().padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text("${recipe.coffeeGrams} g → ${recipe.waterGrams} g", color = androidx.compose.ui.graphics.Color.White, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Black)
                        Text("${recipe.temperatureC} °C · ${recipe.grind} · ${recipe.targetTime}", color = androidx.compose.ui.graphics.Color.White.copy(alpha = .75f))
                    }
                    Icon(Icons.Default.Coffee, null, tint = Sand, modifier = Modifier.size(42.dp))
                }
            }
        }
        item {
            CoffeeScaleCard(
                state = scaleState,
                targetGrams = recipe.waterGrams,
                onScan = onScanScales,
                onConnect = onConnectScale,
                onDisconnect = onDisconnectScale,
                onTare = onTareScale,
                onStartTimer = onStartScaleTimer,
                onPauseTimer = onPauseScaleTimer,
                onStopTimer = onStopScaleTimer,
                onClearError = onClearScaleError,
            )
        }
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("%d:%02d".format(elapsed / 60, elapsed % 60), Modifier.weight(1f), style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Black)
                TextButton(onClick = { elapsed = 0; running = false }) { Text(stringResource(R.string.reset)) }
                Button(onClick = { running = !running }) { Text(stringResource(if (running) R.string.pause else R.string.start)) }
            }
        }
        items(recipe.steps.indices.toList()) { index ->
            val step = recipe.steps[index]
            val active = index == activeStepIndex
            Card(
                colors = CardDefaults.cardColors(containerColor = if (active) Sand.copy(alpha = .28f) else MaterialTheme.colorScheme.surface),
                shape = RoundedCornerShape(18.dp),
            ) {
                Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.Top) {
                    Box(Modifier.size(34.dp).clip(CircleShape).background(if (active) Coffee else Sand.copy(alpha = .3f)), contentAlignment = Alignment.Center) {
                        Text((index + 1).toString(), color = if (active) androidx.compose.ui.graphics.Color.White else Coffee, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(step.title, fontWeight = FontWeight.Bold)
                        Text(step.instruction, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Text("%d:%02d".format(step.startSeconds / 60, step.startSeconds % 60), style = MaterialTheme.typography.labelMedium)
                }
            }
        }
        item {
            BrewJournalCard(
                recipe = recipe,
                elapsedSeconds = elapsed,
                entries = journalEntries,
                scanResult = scanResult,
                onSave = onSaveJournal,
                onDelete = onDeleteJournal,
            )
        }
    }
}

@Composable
internal fun CoffeeInventoryCard(
    inventory: List<PurchasedCoffee>,
    equipment: List<CoffeeEquipment>,
    calibrations: List<EquipmentCalibration>,
    maintenance: List<MaintenanceEvent>,
    conflicts: List<CoffeeConflict>,
    onAddCoffee: (String, Double, Long?) -> Unit,
    onUpdateRemaining: (String, Double) -> Unit,
    onSaveEquipment: (String?, EquipmentType, String, String?, String?) -> Unit,
    onSaveCalibration: (String?, String, String, Double?, String?, String?) -> Unit,
    onSaveMaintenance: (String?, String, String, String?) -> Unit,
    onDeleteEquipment: (String) -> Unit,
    onDeleteCalibration: (String) -> Unit,
    onDeleteMaintenance: (String) -> Unit,
    onResolveConflict: (CoffeeConflict, Boolean) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var quantity by remember { mutableStateOf("250") }
    var error by remember { mutableStateOf<String?>(null) }
    var equipmentId by remember { mutableStateOf<String?>(null) }
    var equipmentType by remember { mutableStateOf(EquipmentType.BREWER) }
    var equipmentName by remember { mutableStateOf("") }
    var manufacturer by remember { mutableStateOf("") }
    var model by remember { mutableStateOf("") }
    var calibrationId by remember { mutableStateOf<String?>(null) }
    var calibrationSetting by remember { mutableStateOf("") }
    var calibrationValue by remember { mutableStateOf("") }
    var calibrationUnit by remember { mutableStateOf("") }
    var calibrationNotes by remember { mutableStateOf("") }
    var maintenanceId by remember { mutableStateOf<String?>(null) }
    var maintenanceType by remember { mutableStateOf("Cleaning") }
    var maintenanceNotes by remember { mutableStateOf("") }
    var equipmentMenuExpanded by remember { mutableStateOf(false) }
    var typeMenuExpanded by remember { mutableStateOf(false) }
    LaunchedEffect(equipment) { if (equipmentId == null) equipmentId = equipment.firstOrNull()?.id }
    Card(shape = RoundedCornerShape(24.dp)) {
        Column(
            Modifier.fillMaxWidth().padding(18.dp).testTag("coffee.inventory"),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("Coffee inventory", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Black)
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                modifier = Modifier.fillMaxWidth().testTag("coffee.inventory.name"),
                label = { Text("Coffee name") },
                singleLine = true,
            )
            OutlinedTextField(
                value = quantity,
                onValueChange = { quantity = it.filter { character -> character.isDigit() || character == '.' } },
                modifier = Modifier.fillMaxWidth().testTag("coffee.inventory.quantity"),
                label = { Text("Quantity (g)") },
                singleLine = true,
            )
            Button(
                onClick = {
                    val grams = quantity.toDoubleOrNull()
                    if (name.isBlank() || grams == null || grams <= 0) {
                        error = "Enter a coffee name and quantity."
                    } else {
                        onAddCoffee(name.trim(), grams, System.currentTimeMillis())
                        name = ""
                        quantity = "250"
                        error = null
                    }
                },
                modifier = Modifier.testTag("coffee.inventory.save"),
            ) { Text("Save coffee") }
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }

            inventory.forEach { coffee ->
                Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text(coffee.productName, fontWeight = FontWeight.Bold)
                    Text("${coffee.remainingQuantityGrams.toInt()} g remaining", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(
                            onClick = { onUpdateRemaining(coffee.id, (coffee.remainingQuantityGrams - 5).coerceAtLeast(0.0)) },
                            modifier = Modifier.testTag("coffee.inventory.consume.${coffee.id}"),
                        ) { Text("Use 5 g") }
                        TextButton(onClick = { onUpdateRemaining(coffee.id, coffee.initialQuantityGrams) }) { Text("Refill") }
                    }
                }
                HorizontalDivider()
            }

            Text("Equipment", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Box {
                    TextButton(onClick = { typeMenuExpanded = true }) { Text(equipmentType.name.lowercase().replaceFirstChar(Char::uppercase)) }
                    DropdownMenu(expanded = typeMenuExpanded, onDismissRequest = { typeMenuExpanded = false }) {
                        EquipmentType.entries.forEach { type ->
                            DropdownMenuItem(text = { Text(type.name.lowercase().replaceFirstChar(Char::uppercase)) }, onClick = { equipmentType = type; typeMenuExpanded = false })
                        }
                    }
                }
                OutlinedTextField(value = equipmentName, onValueChange = { equipmentName = it }, modifier = Modifier.weight(1f).testTag("coffee.equipment.name"), label = { Text("Name") }, singleLine = true)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = manufacturer, onValueChange = { manufacturer = it }, modifier = Modifier.weight(1f), label = { Text("Manufacturer") }, singleLine = true)
                OutlinedTextField(value = model, onValueChange = { model = it }, modifier = Modifier.weight(1f), label = { Text("Model") }, singleLine = true)
            }
            Button(onClick = {
                if (equipmentName.isBlank()) error = "Enter an equipment name."
                else { onSaveEquipment(equipmentId, equipmentType, equipmentName, manufacturer, model); equipmentId = null; equipmentName = ""; manufacturer = ""; model = ""; error = null }
            }, modifier = Modifier.testTag("coffee.equipment.save")) { Text("Save equipment") }
            equipment.forEach { item ->
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(item.name, fontWeight = FontWeight.Bold)
                        Text(listOf(item.type.name.lowercase().replaceFirstChar(Char::uppercase), item.manufacturer, item.model).filterNot { it.isNullOrBlank() }.joinToString(" · "), style = MaterialTheme.typography.bodySmall)
                    }
                    TextButton(onClick = { equipmentId = item.id; equipmentType = item.type; equipmentName = item.name; manufacturer = item.manufacturer.orEmpty(); model = item.model.orEmpty() }) { Text("Edit") }
                    IconButton(onClick = { onDeleteEquipment(item.id) }, modifier = Modifier.testTag("coffee.equipment.delete.${item.id}")) { Icon(Icons.Default.Delete, "Delete equipment") }
                }
            }

            Text("Calibrations", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Box {
                TextButton(onClick = { equipmentMenuExpanded = true }) { Text(equipment.firstOrNull { it.id == equipmentId }?.name ?: "Select equipment") }
                DropdownMenu(expanded = equipmentMenuExpanded, onDismissRequest = { equipmentMenuExpanded = false }) {
                    equipment.forEach { item -> DropdownMenuItem(text = { Text(item.name) }, onClick = { equipmentId = item.id; equipmentMenuExpanded = false }) }
                }
            }
            OutlinedTextField(value = calibrationSetting, onValueChange = { calibrationSetting = it }, modifier = Modifier.fillMaxWidth().testTag("coffee.calibration.setting"), label = { Text("Setting") }, singleLine = true)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = calibrationValue, onValueChange = { calibrationValue = it }, modifier = Modifier.weight(1f), label = { Text("Measured value") }, singleLine = true)
                OutlinedTextField(value = calibrationUnit, onValueChange = { calibrationUnit = it }, modifier = Modifier.weight(1f), label = { Text("Unit") }, singleLine = true)
            }
            OutlinedTextField(value = calibrationNotes, onValueChange = { calibrationNotes = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Notes") }, singleLine = true)
            Button(onClick = {
                if (equipmentId == null || calibrationSetting.isBlank()) error = "Select equipment and enter a setting."
                else { onSaveCalibration(calibrationId, equipmentId!!, calibrationSetting, calibrationValue.toDoubleOrNull(), calibrationUnit, calibrationNotes); calibrationId = null; calibrationSetting = ""; calibrationValue = ""; calibrationNotes = ""; error = null }
            }, modifier = Modifier.testTag("coffee.calibration.save")) { Text("Save calibration") }
            calibrations.forEach { item ->
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text(listOf(item.setting, item.measuredValue?.toString(), item.unit).filterNot { it.isNullOrBlank() }.joinToString(" · "), Modifier.weight(1f))
                    TextButton(onClick = { calibrationId = item.id; equipmentId = item.equipmentId; calibrationSetting = item.setting; calibrationValue = item.measuredValue?.toString().orEmpty(); calibrationUnit = item.unit.orEmpty(); calibrationNotes = item.notes.orEmpty() }) { Text("Edit") }
                    IconButton(onClick = { onDeleteCalibration(item.id) }, modifier = Modifier.testTag("coffee.calibration.delete.${item.id}")) { Icon(Icons.Default.Delete, "Delete calibration") }
                }
            }

            Text("Maintenance", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            OutlinedTextField(value = maintenanceType, onValueChange = { maintenanceType = it }, modifier = Modifier.fillMaxWidth().testTag("coffee.maintenance.type"), label = { Text("Maintenance type") }, singleLine = true)
            OutlinedTextField(value = maintenanceNotes, onValueChange = { maintenanceNotes = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Notes") }, singleLine = true)
            Button(onClick = {
                if (equipmentId == null || maintenanceType.isBlank()) error = "Select equipment and enter a maintenance type."
                else { onSaveMaintenance(maintenanceId, equipmentId!!, maintenanceType, maintenanceNotes); maintenanceId = null; maintenanceNotes = ""; error = null }
            }, modifier = Modifier.testTag("coffee.maintenance.save")) { Text("Record maintenance") }
            maintenance.forEach { item ->
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) { Text(item.type, fontWeight = FontWeight.Bold); item.notes?.takeIf(String::isNotBlank)?.let { Text(it, style = MaterialTheme.typography.bodySmall) } }
                    TextButton(onClick = { maintenanceId = item.id; equipmentId = item.equipmentId; maintenanceType = item.type; maintenanceNotes = item.notes.orEmpty() }) { Text("Edit") }
                    IconButton(onClick = { onDeleteMaintenance(item.id) }, modifier = Modifier.testTag("coffee.maintenance.delete.${item.id}")) { Icon(Icons.Default.Delete, "Delete maintenance") }
                }
            }

            conflicts.forEach { conflict ->
                Column(
                    Modifier.fillMaxWidth().background(Sand.copy(alpha = .15f), RoundedCornerShape(12.dp)).padding(12.dp)
                        .testTag("coffee.sync.conflict"),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text("Sync conflict · ${conflict.entityType}", fontWeight = FontWeight.Bold)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(onClick = { onResolveConflict(conflict, false) }) { Text("Keep server") }
                        TextButton(onClick = { onResolveConflict(conflict, true) }) { Text("Restore local") }
                    }
                }
            }
        }
    }
}

@Composable
private fun BrewingDashboard(
    latestEntry: BrewJournalEntry?,
    onCreateRecipe: () -> Unit,
    onScanBag: () -> Unit,
    onOpenTool: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val tools = listOf(
        stringResource(R.string.ratio_calculator) to stringResource(R.string.dose_and_water),
        stringResource(R.string.brew_timer) to stringResource(R.string.guided_pours),
        stringResource(R.string.coffee_journal) to stringResource(R.string.taste_notes_short),
        stringResource(R.string.brew_coach) to stringResource(R.string.tune_the_cup),
    )
    val methods = listOf(
        stringResource(R.string.pour_over), stringResource(R.string.immersion), stringResource(R.string.traditional),
        stringResource(R.string.cold_brew), stringResource(R.string.espresso),
    )
    LazyColumn(
        modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 28.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(stringResource(R.string.the_craft).uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                Text(stringResource(R.string.brewing_methods), style = MaterialTheme.typography.displaySmall, color = Ink)
                Text(stringResource(R.string.brewing_intro_dashboard), style = MaterialTheme.typography.bodyLarge, color = Ink.copy(alpha = .72f))
            }
        }
        item {
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(TallaCard)
                    .border(1.dp, Sand.copy(alpha = .18f), RoundedCornerShape(24.dp)).padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.Top) {
                    Box(Modifier.size(46.dp).clip(CircleShape).background(Sand), contentAlignment = Alignment.Center) { Text("✦", style = MaterialTheme.typography.titleLarge, color = Color(0xFF2B170F)) }
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(stringResource(R.string.create_brew_recipe), style = MaterialTheme.typography.titleLarge, color = Ink)
                        Text(stringResource(R.string.create_brew_recipe_detail), style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Button(onClick = onCreateRecipe, modifier = Modifier.weight(1f), colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF2B170F)), shape = CircleShape) { Text("＋ ${stringResource(R.string.create_recipe).uppercase()}", style = MaterialTheme.typography.labelMedium) }
                    Button(onClick = onScanBag, modifier = Modifier.weight(1f).border(1.dp, Sand.copy(alpha = .22f), CircleShape), colors = ButtonDefaults.buttonColors(containerColor = TallaCard, contentColor = Ink), shape = CircleShape) { Text(stringResource(R.string.scan_coffee_bag).uppercase(), style = MaterialTheme.typography.labelMedium) }
                }
            }
        }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(if (latestEntry == null) stringResource(R.string.brew_again).uppercase() else "CONTINUE BREW", style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(TallaCard)
                        .border(1.dp, Sand.copy(alpha = .16f), RoundedCornerShape(20.dp)).clickable(onClick = onOpenTool).padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(latestEntry?.title ?: "Balanced Filter", style = MaterialTheme.typography.headlineSmall, color = Ink)
                        Text(latestEntry?.let { "${it.method} · ${it.coffeeGrams} g · 1:${"%.1f".format(it.ratio)}" } ?: "V60 · 20 g · 1:15", style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
                    }
                    Text("→", style = MaterialTheme.typography.titleLarge, color = TallaGoldText)
                }
            }
        }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(stringResource(R.string.quick_tools).uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                tools.chunked(2).forEach { rowTools ->
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        rowTools.forEach { tool ->
                            Column(
                                Modifier.weight(1f).clip(RoundedCornerShape(18.dp)).background(TallaCard)
                                    .border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(18.dp)).clickable(onClick = onOpenTool).padding(14.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp),
                            ) {
                                Text(tool.first, style = MaterialTheme.typography.titleMedium, color = Ink)
                                Text(tool.second, style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
                            }
                        }
                    }
                }
            }
        }
        item {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(stringResource(R.string.browse_methods).uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                methods.chunked(2).forEach { rowMethods ->
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        rowMethods.forEach { method ->
                            Row(
                                Modifier.weight(1f).height(58.dp).clip(RoundedCornerShape(18.dp)).background(TallaCard)
                                    .border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(18.dp)).clickable(onClick = onOpenTool).padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) { Text(method, style = MaterialTheme.typography.titleMedium, color = Ink) }
                        }
                        if (rowMethods.size == 1) Spacer(Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

@Composable
internal fun CoffeeScaleCard(
    state: ScaleUiState,
    targetGrams: Int,
    onScan: () -> Unit,
    onConnect: (String) -> Unit,
    onDisconnect: () -> Unit,
    onTare: () -> Unit,
    onStartTimer: () -> Unit,
    onPauseTimer: () -> Unit,
    onStopTimer: () -> Unit,
    onClearError: () -> Unit,
) {
    val context = LocalContext.current
    val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
    } else arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
    var permissionDenied by remember { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { results ->
        if (permissions.all { results[it] == true }) {
            permissionDenied = false
            onScan()
        } else permissionDenied = true
    }
    val hasPermissions = permissions.all { ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED }

    Card(shape = RoundedCornerShape(24.dp)) {
        Column(Modifier.fillMaxWidth().padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Bluetooth, null, tint = Coffee)
                Spacer(Modifier.width(9.dp))
                Column(Modifier.weight(1f)) {
                    Text(stringResource(R.string.coffee_scale), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Black)
                    Text(stringResource(R.string.coffee_scale_detail), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (state.connectedAddress == null) {
                    Button(
                        onClick = { if (hasPermissions) onScan() else permissionLauncher.launch(permissions) },
                        enabled = !state.scanning,
                        modifier = Modifier.testTag("bluetooth.scan"),
                    ) {
                        if (state.scanning) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
                        else Text(stringResource(R.string.scan))
                    }
                }
            }

            if (permissionDenied) Text(stringResource(R.string.bluetooth_permission_required), color = MaterialTheme.colorScheme.error)
            state.error?.let { message ->
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(message, Modifier.weight(1f), color = MaterialTheme.colorScheme.error)
                    TextButton(onClick = onClearError) { Text(stringResource(R.string.dismiss)) }
                }
            }

            if (state.connectedAddress != null) {
                Text(state.connectedName ?: stringResource(R.string.connected_scale), fontWeight = FontWeight.Bold)
                Text(
                    stringResource(R.string.live_weight_grams, state.weightGrams),
                    style = MaterialTheme.typography.displaySmall,
                    fontWeight = FontWeight.Black,
                    color = Coffee,
                )
                LinearProgressIndicator(
                    progress = { (state.weightGrams / targetGrams.coerceAtLeast(1)).toFloat().coerceIn(0f, 1f) },
                    modifier = Modifier.fillMaxWidth(),
                )
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text(stringResource(R.string.target_weight, targetGrams), style = MaterialTheme.typography.labelMedium)
                    state.flowGramsPerSecond?.let { Text(stringResource(R.string.flow_rate, it), style = MaterialTheme.typography.labelMedium) }
                    state.timerSeconds?.let { Text("%d:%02d".format(it / 60, it % 60), style = MaterialTheme.typography.labelMedium) }
                }
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    item { Button(onClick = onTare) { Text(stringResource(R.string.tare)) } }
                    if (state.connectedFamily == ScaleFamily.Bookoo || state.connectedFamily == ScaleFamily.Mantabrew) {
                        item { TextButton(onClick = onStartTimer) { Text(stringResource(R.string.start_timer)) } }
                        item { TextButton(onClick = onPauseTimer) { Text(stringResource(R.string.pause_timer)) } }
                        item { TextButton(onClick = onStopTimer) { Text(stringResource(R.string.stop_timer)) } }
                    }
                    item { TextButton(onClick = onDisconnect) { Text(stringResource(R.string.disconnect)) } }
                }
            } else if (state.devices.isNotEmpty()) {
                Text(stringResource(R.string.nearby_scales), fontWeight = FontWeight.Bold)
                state.devices.forEach { device ->
                    Card(onClick = { onConnect(device.address) }, colors = CardDefaults.cardColors(containerColor = Sand.copy(alpha = .12f))) {
                        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(device.name, fontWeight = FontWeight.Bold)
                                Text("${device.family.displayName} · ${device.rssi} dBm", style = MaterialTheme.typography.bodySmall)
                            }
                            if (state.connectingAddress == device.address) CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
                            else Text(stringResource(R.string.connect), color = Coffee, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            } else if (!state.scanning) {
                Text(stringResource(R.string.supported_scales), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun CoffeeBagScannerCard(
    result: CoffeeBagScanResult?,
    scanning: Boolean,
    error: String?,
    onScan: (Uri) -> Unit,
    onClear: () -> Unit,
) {
    val context = LocalContext.current
    var pendingCameraUri by remember { mutableStateOf<Uri?>(null) }
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { captured ->
        if (captured) pendingCameraUri?.let(onScan)
    }
    val galleryLauncher = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        uri?.let(onScan)
    }

    Card(colors = CardDefaults.cardColors(containerColor = Sand.copy(alpha = .13f)), shape = RoundedCornerShape(24.dp)) {
        Column(Modifier.fillMaxWidth().padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.scan_coffee_bag), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Black)
            Text(stringResource(R.string.scan_coffee_bag_detail), color = MaterialTheme.colorScheme.onSurfaceVariant)
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(
                    onClick = {
                        val directory = File(context.cacheDir, "coffee-bag-scans").apply { mkdirs() }
                        val imageFile = File.createTempFile("coffee-bag-", ".jpg", directory)
                        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", imageFile)
                        pendingCameraUri = uri
                        cameraLauncher.launch(uri)
                    },
                    enabled = !scanning,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Default.CameraAlt, null)
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.camera))
                }
                TextButton(
                    onClick = { galleryLauncher.launch("image/*") },
                    enabled = !scanning,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Default.PhotoLibrary, null)
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.photo_library))
                }
            }
            if (scanning) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
                    Text(stringResource(R.string.reading_coffee_bag))
                }
            }
            error?.let { message -> Text(message, color = MaterialTheme.colorScheme.error) }
            result?.let { scan ->
                HorizontalDivider()
                Text(stringResource(R.string.detected_coffee), fontWeight = FontWeight.Bold)
                ScanResultRow(R.string.coffee_name, scan.name)
                ScanResultRow(R.string.roaster, scan.roaster)
                ScanResultRow(R.string.origin, scan.origin)
                ScanResultRow(R.string.region, scan.region)
                ScanResultRow(R.string.altitude, scan.altitude)
                ScanResultRow(R.string.variety, scan.variety)
                ScanResultRow(R.string.process, scan.process)
                ScanResultRow(R.string.tasting_notes, scan.tastingNotes)
                Text(stringResource(R.string.scan_added_to_journal), style = MaterialTheme.typography.bodySmall, color = Coffee)
                TextButton(onClick = onClear) { Text(stringResource(R.string.clear_scan)) }
            }
        }
    }
}

@Composable
private fun ScanResultRow(labelRes: Int, value: String?) {
    if (!value.isNullOrBlank()) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(labelRes), Modifier.width(110.dp), style = MaterialTheme.typography.labelMedium, color = Coffee)
            Text(value, Modifier.weight(1f))
        }
    }
}

@Composable
private fun BrewJournalCard(
    recipe: BrewRecipe,
    elapsedSeconds: Int,
    entries: List<BrewJournalEntry>,
    scanResult: CoffeeBagScanResult?,
    onSave: (String, String, Int, Double, Int, Int, Int, String) -> Unit,
    onDelete: (String) -> Unit,
) {
    var title by remember { mutableStateOf("") }
    var method by remember(recipe.brewer) { mutableStateOf(recipe.brewer) }
    var notes by remember { mutableStateOf("") }
    var rating by remember { mutableIntStateOf(4) }
    val recipeRatio = recipe.waterGrams.toDouble() / recipe.coffeeGrams.coerceAtLeast(1)

    LaunchedEffect(scanResult) {
        scanResult?.let { result ->
            title = result.name.orEmpty()
            notes = result.journalNotes()
        }
    }

    Card(shape = RoundedCornerShape(24.dp)) {
        Column(Modifier.fillMaxWidth().padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.coffee_journal), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Black)
            Text(stringResource(R.string.coffee_journal_detail), color = MaterialTheme.colorScheme.onSurfaceVariant)
            OutlinedTextField(
                value = title, onValueChange = { title = it }, modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.journal_title)) }, singleLine = true,
            )
            OutlinedTextField(
                value = method, onValueChange = { method = it }, modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.method)) }, singleLine = true,
            )
            Text(
                stringResource(
                    R.string.journal_recipe_detail,
                    recipe.coffeeGrams,
                    recipeRatio,
                    recipe.waterGrams,
                    "%d:%02d".format(elapsedSeconds / 60, elapsedSeconds % 60),
                ),
                style = MaterialTheme.typography.labelMedium,
                color = Coffee,
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                (1..5).forEach { star ->
                    IconButton(onClick = { rating = star }) {
                        Icon(
                            imageVector = if (star <= rating) Icons.Default.Star else Icons.Default.StarBorder,
                            contentDescription = stringResource(R.string.star_rating, star),
                            tint = Sand,
                        )
                    }
                }
            }
            OutlinedTextField(
                value = notes, onValueChange = { notes = it }, modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.tasting_notes)) }, minLines = 2, maxLines = 4,
            )
            Button(
                onClick = {
                    onSave(
                        title, method, recipe.coffeeGrams, recipeRatio, recipe.waterGrams,
                        elapsedSeconds, rating, notes,
                    )
                    title = ""
                    notes = ""
                },
                enabled = title.isNotBlank() || notes.isNotBlank(),
                modifier = Modifier.fillMaxWidth(),
            ) { Text(stringResource(R.string.save_journal_entry)) }

            if (entries.isNotEmpty()) {
                HorizontalDivider()
                Text(stringResource(R.string.recent_notes), fontWeight = FontWeight.Bold)
                entries.take(3).forEach { entry ->
                    Card(colors = CardDefaults.cardColors(containerColor = Sand.copy(alpha = .12f))) {
                        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.Top) {
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                Text(entry.title, fontWeight = FontWeight.Bold)
                                Text(
                                    stringResource(R.string.journal_method_rating, entry.method, entry.rating),
                                    style = MaterialTheme.typography.labelMedium,
                                    color = Coffee,
                                )
                                Text(
                                    stringResource(
                                        R.string.journal_recipe_detail,
                                        entry.coffeeGrams,
                                        entry.ratio,
                                        entry.waterGrams,
                                        "%d:%02d".format(entry.brewTimeSeconds / 60, entry.brewTimeSeconds % 60),
                                    ),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                                if (entry.notes.isNotBlank()) Text(entry.notes)
                            }
                            IconButton(onClick = { onDelete(entry.id) }) {
                                Icon(Icons.Default.Delete, stringResource(R.string.delete_journal_entry))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
internal fun AccountScreen(
    state: TallaUiState,
    onLogin: (String, String) -> Unit,
    onRegister: (String, String, String, String) -> Unit,
    onLogout: () -> Unit,
    onDeleteAccount: () -> Unit,
    onRefresh: () -> Unit,
    onSaveAddress: (String, String, String, String, String, String) -> Unit,
    onDeleteAddress: (String) -> Unit,
    onSaveTasteMemory: (String, String, String, List<String>) -> Unit,
    openProduct: (Product) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (state.profile == null) {
        SignedOutAccount(state, onLogin, onRegister, modifier)
        return
    }
    val profile = state.profile
    val favorites = state.products.filter { it.id in state.favoriteProductIds }
    var addingAddress by remember { mutableStateOf(false) }
    var confirmingDeletion by remember { mutableStateOf(false) }
    val languageTag = AppCompatDelegate.getApplicationLocales().toLanguageTags()
    LazyColumn(modifier.fillMaxSize(), contentPadding = PaddingValues(horizontal = 18.dp, vertical = 28.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        item {
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(TallaCard)
                    .border(1.dp, Sand.copy(alpha = .16f), RoundedCornerShape(22.dp)).padding(18.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Row(verticalAlignment = Alignment.Top) {
                    Box(Modifier.size(46.dp).clip(CircleShape).background(Sand.copy(alpha = .12f)), contentAlignment = Alignment.Center) { Icon(Icons.Default.Person, null, tint = TallaGoldText) }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("${profile.firstName} ${profile.lastName}".trim(), style = MaterialTheme.typography.displaySmall, color = Ink, maxLines = 1)
                        Text(profile.email, style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
                        Text("MEMBERSHIP: ${(state.loyalty?.tier ?: "Bronze").uppercase()}", style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                    }
                    IconButton(onClick = onRefresh) { Icon(Icons.Default.Refresh, "Refresh account", tint = TallaGoldText) }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    AccountMetric((state.loyalty?.pointsBalance ?: 0).toString(), "BEANS", Modifier.weight(1f))
                    val remaining = (50 - ((state.loyalty?.pointsBalance ?: 0) % 50)).let { if (it == 0) 50 else it }
                    AccountMetric(remaining.toString(), "UNTIL REWARD", Modifier.weight(1f))
                }
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                AccountQuickChip("Orders", "${state.orders.size} saved", Modifier.weight(1f))
                AccountQuickChip("Rewards", "${state.loyalty?.pointsBalance ?: 0} Beans", Modifier.weight(1f))
            }
            Spacer(Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                AccountQuickChip("Addresses", "${state.addresses.size} saved", Modifier.weight(1f))
                AccountQuickChip("Saved", "${favorites.size} picks", Modifier.weight(1f))
            }
        }
        state.loyalty?.let { loyalty ->
            item {
                Column(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(TallaCard)
                        .border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(18.dp)).padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(5.dp),
                ) {
                    Text("THE TALLA CLUB", style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                    Text(loyalty.nextReward, style = MaterialTheme.typography.titleMedium, color = Ink)
                    Text(stringResource(R.string.member_id, loyalty.memberId), style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .62f))
                }
            }
        }
        if (state.orders.isNotEmpty()) {
            item { Text(stringResource(R.string.recent_orders), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold) }
            items(state.orders.take(5), key = { it.id }) { order ->
                Card(shape = RoundedCornerShape(18.dp)) {
                    Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) { Text(order.title.ifBlank { order.id }, fontWeight = FontWeight.Bold); Text(order.status) }
                            Text("BHD ${"%.3f".format(order.total)}")
                        }
                        val item = order.items.firstOrNull()
                        if (item != null && order.status.lowercase() in setOf("completed", "fulfilled", "delivered")) {
                            val existing = state.tasteMemory.firstOrNull {
                                it.orderId == order.id && it.productName.equals(item.name, ignoreCase = true)
                            }
                            TasteMemoryPrompt(order, item.name, existing, onSaveTasteMemory)
                        }
                    }
                }
            }
        }
        if (state.addresses.isNotEmpty()) {
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(stringResource(R.string.addresses), Modifier.weight(1f), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    TextButton(onClick = { addingAddress = true }) { Text(stringResource(R.string.add)) }
                }
            }
            items(state.addresses, key = { it.id }) { address ->
                Card(shape = RoundedCornerShape(18.dp)) {
                    Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(if (address.isPreferred) "${address.label} · Preferred" else address.label, fontWeight = FontWeight.Bold)
                            Text("${address.line1}, ${address.city} · ${address.countryCode}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        IconButton(onClick = { onDeleteAddress(address.id) }) { Icon(Icons.Default.Delete, "Delete address") }
                    }
                }
            }
        } else {
            item { Button(onClick = { addingAddress = true }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.add_delivery_address)) } }
        }
        if (state.vouchers.isNotEmpty()) {
            item { Text(stringResource(R.string.active_rewards), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold) }
            items(state.vouchers, key = { it.code }) { voucher ->
                Card(colors = CardDefaults.cardColors(containerColor = Sand.copy(alpha = .2f)), shape = RoundedCornerShape(18.dp)) {
                    Column(Modifier.fillMaxWidth().padding(16.dp)) {
                        Text(voucher.reward, fontWeight = FontWeight.Bold)
                        Text(voucher.code, color = Coffee)
                        if (voucher.detail.isNotBlank()) Text(voucher.detail, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
        }
        if (state.stockAlerts.isNotEmpty()) {
            item { Text(stringResource(R.string.stock_alerts), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold) }
            items(state.stockAlerts, key = { it.productId }) { alert -> AccountRow(alert.productName, alert.status) }
        }
        if (favorites.isNotEmpty()) {
            item { Text(stringResource(R.string.your_shelf), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold) }
            item {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(favorites, key = { it.id }) { product -> ProductCard(product, {}, openProduct, true, Modifier.width(190.dp)) }
                }
            }
        }
        if (state.accountError != null) item { Text(state.accountError, color = MaterialTheme.colorScheme.error) }
        item {
            Text(stringResource(R.string.language), style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(selected = languageTag.isBlank(), onClick = { AppCompatDelegate.setApplicationLocales(LocaleListCompat.getEmptyLocaleList()) }, label = { Text(stringResource(R.string.system_language)) })
                FilterChip(selected = languageTag.startsWith("en"), onClick = { AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("en")) }, label = { Text(stringResource(R.string.english)) })
                FilterChip(
                    selected = languageTag.startsWith("ar"),
                    onClick = { AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("ar")) },
                    label = { Text(stringResource(R.string.arabic)) },
                    modifier = Modifier.testTag("language.arabic"),
                )
            }
        }
        item { TextButton(onClick = onLogout) { Text(stringResource(R.string.sign_out)) } }
        item {
            TextButton(
                onClick = { confirmingDeletion = true },
                modifier = Modifier.testTag("account.delete"),
            ) { Text("Delete account", color = MaterialTheme.colorScheme.error) }
        }
    }
    if (addingAddress) {
        AddAddressDialog(onDismiss = { addingAddress = false }) { label, name, phone, line1, city, country ->
            onSaveAddress(label, name, phone, line1, city, country)
            addingAddress = false
        }
    }
    if (confirmingDeletion) {
        AlertDialog(
            onDismissRequest = { confirmingDeletion = false },
            title = { Text("Delete account?") },
            text = { Text("Your profile, synced coffee data, loyalty history, and saved preferences will be permanently deleted.") },
            dismissButton = { TextButton(onClick = { confirmingDeletion = false }) { Text("Cancel") } },
            confirmButton = {
                TextButton(
                    onClick = { confirmingDeletion = false; onDeleteAccount() },
                    modifier = Modifier.testTag("account.delete.confirm"),
                ) { Text("Delete permanently", color = MaterialTheme.colorScheme.error) }
            },
        )
    }
}

@Composable
private fun AccountMetric(value: String, label: String, modifier: Modifier = Modifier) {
    Column(modifier.clip(RoundedCornerShape(16.dp)).background(Sand.copy(alpha = .08f)).padding(12.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(value, style = MaterialTheme.typography.titleLarge, color = Ink)
        Text(label, style = MaterialTheme.typography.labelMedium, color = Ink.copy(alpha = .72f))
    }
}

@Composable
private fun AccountQuickChip(title: String, detail: String, modifier: Modifier = Modifier) {
    Row(modifier.height(58.dp).clip(RoundedCornerShape(18.dp)).background(TallaCard).border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(18.dp)).padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(28.dp).clip(CircleShape).background(Sand.copy(alpha = .12f)), contentAlignment = Alignment.Center) { Text("✦", color = TallaGoldText) }
        Spacer(Modifier.width(10.dp))
        Column { Text(title, style = MaterialTheme.typography.labelLarge, color = Ink); Text(detail, style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f), maxLines = 1) }
    }
}

@Composable
private fun TasteMemoryPrompt(
    order: CustomerOrder,
    productName: String,
    existing: TasteMemoryRecord?,
    onSave: (String, String, String, List<String>) -> Unit,
) {
    val tags = listOf(
        "Chocolate" to R.string.taste_chocolate,
        "Fruity" to R.string.taste_fruity,
        "Floral" to R.string.taste_floral,
        "Caramel" to R.string.taste_caramel,
        "Citrus" to R.string.taste_citrus,
        "Nutty" to R.string.taste_nutty,
    )
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Sand.copy(alpha = .14f)).padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        Text(stringResource(R.string.taste_memory_question, productName), fontWeight = FontWeight.Bold)
        Text(
            stringResource(if (existing == null) R.string.taste_memory_detail else R.string.taste_memory_saved_detail),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(
                selected = existing?.reaction == "loved",
                onClick = { onSave(order.id, productName, "loved", existing?.tags.orEmpty()) },
                label = { Text(stringResource(R.string.loved_it)) },
                leadingIcon = { Icon(Icons.Default.Favorite, null, Modifier.size(18.dp)) },
            )
            FilterChip(
                selected = existing?.reaction == "not-for-me",
                onClick = { onSave(order.id, productName, "not-for-me", existing?.tags.orEmpty()) },
                label = { Text(stringResource(R.string.not_for_me)) },
                leadingIcon = { Icon(Icons.Default.ThumbDown, null, Modifier.size(18.dp)) },
            )
        }
        LazyRow(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
            items(tags, key = { it.first }) { (canonicalName, labelRes) ->
                val selected = canonicalName in existing?.tags.orEmpty()
                FilterChip(
                    selected = selected,
                    onClick = {
                        val updated = if (selected) existing?.tags.orEmpty() - canonicalName
                        else existing?.tags.orEmpty() + canonicalName
                        onSave(order.id, productName, existing?.reaction ?: "loved", updated)
                    },
                    label = { Text(stringResource(labelRes)) },
                )
            }
        }
    }
}

@Composable
private fun AddAddressDialog(
    onDismiss: () -> Unit,
    onSave: (String, String, String, String, String, String) -> Unit,
) {
    var label by remember { mutableStateOf("Home") }
    var name by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var line1 by remember { mutableStateOf("") }
    var city by remember { mutableStateOf("") }
    var country by remember { mutableStateOf("BH") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.delivery_address)) },
        text = {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                item { OutlinedTextField(label, { label = it }, label = { Text(stringResource(R.string.label)) }, singleLine = true) }
                item { OutlinedTextField(name, { name = it }, label = { Text(stringResource(R.string.full_name)) }, singleLine = true) }
                item { OutlinedTextField(phone, { phone = it }, label = { Text(stringResource(R.string.phone)) }, singleLine = true) }
                item { OutlinedTextField(line1, { line1 = it }, label = { Text(stringResource(R.string.address)) }) }
                item { OutlinedTextField(city, { city = it }, label = { Text(stringResource(R.string.city)) }, singleLine = true) }
                item { OutlinedTextField(country, { country = it.uppercase().take(2) }, label = { Text(stringResource(R.string.country_code)) }, singleLine = true) }
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onSave(label, name, phone, line1, city, country) },
                enabled = label.isNotBlank() && name.isNotBlank() && phone.isNotBlank() && line1.isNotBlank() && city.isNotBlank() && country.length == 2,
            ) { Text(stringResource(R.string.save)) }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.cancel)) } },
    )
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun SignedOutAccount(
    state: TallaUiState,
    onLogin: (String, String) -> Unit,
    onRegister: (String, String, String, String) -> Unit,
    modifier: Modifier = Modifier,
) {
    var accountAccessOpen by remember { mutableStateOf(false) }
    var registering by remember { mutableStateOf(false) }
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    LazyColumn(modifier.fillMaxSize(), contentPadding = PaddingValues(horizontal = 18.dp, vertical = 28.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        item {
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(TallaCard)
                    .border(1.dp, Sand.copy(alpha = .16f), RoundedCornerShape(22.dp)).clickable { accountAccessOpen = true }.padding(18.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(46.dp).clip(CircleShape).background(Sand.copy(alpha = .12f)), contentAlignment = Alignment.Center) { Icon(Icons.Default.Person, null, tint = TallaGoldText) }
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    Text(stringResource(R.string.welcome_to_talla), style = MaterialTheme.typography.titleLarge, color = Ink)
                    Text(stringResource(R.string.account_guest_summary), style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
                }
                Text("→", style = MaterialTheme.typography.titleLarge, color = Ink.copy(alpha = .55f))
            }
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                AccountQuickChip(stringResource(R.string.rewards), stringResource(R.string.check_rewards), Modifier.weight(1f))
                AccountQuickChip(stringResource(R.string.saved), stringResource(R.string.picks_count, state.favoriteProductIds.size), Modifier.weight(1f))
            }
        }
        item { AccountAreaCard(stringResource(R.string.account_and_settings).uppercase(), listOf(stringResource(R.string.new_to_talla) to stringResource(R.string.signin_detail), "Reset password" to "Get help accessing your account", "Support" to stringResource(R.string.appearance_and_language)), onFirst = { accountAccessOpen = true }) }
        item { AccountAreaCard(stringResource(R.string.shopping_tools).uppercase(), listOf(stringResource(R.string.saved_bags) to stringResource(R.string.resume_checkout), stringResource(R.string.back_in_stock_alerts) to stringResource(R.string.notify_when_available))) }
        item { AccountAreaCard(stringResource(R.string.brewing).uppercase(), listOf(stringResource(R.string.brew_archive) to stringResource(R.string.saved_recipes_journal))) }
    }

    if (accountAccessOpen) {
        ModalBottomSheet(onDismissRequest = { accountAccessOpen = false }) {
            Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text(stringResource(if (registering) R.string.join_talla else R.string.welcome_back), style = MaterialTheme.typography.displaySmall, color = Ink)
                Text(stringResource(R.string.signin_detail), style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f))
                if (registering) {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        OutlinedTextField(firstName, { firstName = it }, Modifier.weight(1f), label = { Text(stringResource(R.string.first_name)) }, singleLine = true)
                        OutlinedTextField(lastName, { lastName = it }, Modifier.weight(1f), label = { Text(stringResource(R.string.last_name)) }, singleLine = true)
                    }
                }
                OutlinedTextField(email, { email = it }, Modifier.fillMaxWidth(), label = { Text(stringResource(R.string.email)) }, singleLine = true)
                OutlinedTextField(password, { password = it }, Modifier.fillMaxWidth(), label = { Text(stringResource(R.string.password)) }, singleLine = true, visualTransformation = PasswordVisualTransformation())
                state.accountError?.let { Text(it, color = MaterialTheme.colorScheme.error) }
                Button(
                    onClick = { if (registering) onRegister(firstName, lastName, email, password) else onLogin(email, password) },
                    enabled = !state.accountLoading && email.isNotBlank() && password.length >= 5 && (!registering || firstName.isNotBlank() && lastName.isNotBlank()),
                    modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF0A0804)), shape = CircleShape,
                ) { if (state.accountLoading) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp) else Text(stringResource(if (registering) R.string.create_account else R.string.sign_in), style = MaterialTheme.typography.labelLarge) }
                TextButton(onClick = { registering = !registering }, modifier = Modifier.align(Alignment.CenterHorizontally)) { Text(stringResource(if (registering) R.string.already_account else R.string.new_to_talla), color = TallaGoldText) }
            }
        }
    }
}

@Composable
private fun AccountAreaCard(title: String, rows: List<Pair<String, String>>, onFirst: () -> Unit = {}) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(title, style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(TallaCard).border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(18.dp))) {
            rows.forEachIndexed { index, row ->
                Row(Modifier.fillMaxWidth().clickable(enabled = index == 0, onClick = onFirst).padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(34.dp).clip(CircleShape).background(Sand.copy(alpha = .10f)), contentAlignment = Alignment.Center) { Text("✦", color = TallaGoldText) }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) { Text(row.first, style = MaterialTheme.typography.labelLarge, color = Ink); Text(row.second, style = MaterialTheme.typography.bodyMedium, color = Ink.copy(alpha = .72f), maxLines = 1) }
                    Text("›", style = MaterialTheme.typography.titleLarge, color = Ink.copy(alpha = .45f))
                }
                if (index < rows.lastIndex) HorizontalDivider(Modifier.padding(start = 50.dp), color = Sand.copy(alpha = .10f))
            }
        }
    }
}

@Composable
private fun AccountRow(title: String, detail: String) {
    Card(shape = RoundedCornerShape(18.dp)) {
        Column(Modifier.fillMaxWidth().padding(18.dp)) { Text(title, fontWeight = FontWeight.Bold); Text(detail, color = MaterialTheme.colorScheme.onSurfaceVariant) }
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun ProductDetailsSheet(
    product: Product,
    favorite: Boolean,
    watchingStock: Boolean,
    onFavorite: () -> Unit,
    onStockAlert: () -> Unit,
    onAdd: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    var selectedVariantId by remember(product.id) { mutableStateOf(product.defaultVariant?.id) }
    val selectedVariant = product.variants.firstOrNull { it.id == selectedVariantId }
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = MaterialTheme.colorScheme.background) {
        LazyColumn(
            modifier = Modifier.fillMaxWidth(),
            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item { RemoteImage(product.imageUrl, product.name, Modifier.fillMaxWidth().height(260.dp).clip(RoundedCornerShape(24.dp))) }
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(product.category.uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                        Text(product.name, style = MaterialTheme.typography.displaySmall, color = Ink)
                    }
                    IconButton(onClick = onFavorite) {
                        Icon(if (favorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder, "Favourite", tint = if (favorite) Sand else MaterialTheme.colorScheme.onSurface)
                    }
                }
            }
            if (product.description.isNotBlank()) item { Text(product.description, style = MaterialTheme.typography.bodyLarge, color = Ink.copy(alpha = .72f)) }
            if (product.variants.size > 1) {
                item { Text(stringResource(R.string.choose_option), fontWeight = FontWeight.Bold) }
                items(product.variants, key = { it.id }) { variant ->
                    Card(onClick = { if (variant.available) selectedVariantId = variant.id }, shape = RoundedCornerShape(16.dp), colors = CardDefaults.cardColors(containerColor = TallaCard)) {
                        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                            RadioButton(selected = selectedVariantId == variant.id, onClick = { if (variant.available) selectedVariantId = variant.id }, enabled = variant.available)
                            Column(Modifier.weight(1f)) {
                                Text(variant.title, fontWeight = FontWeight.SemiBold)
                                if (!variant.available) Text(stringResource(R.string.sold_out), color = MaterialTheme.colorScheme.error)
                            }
                            Text("${variant.currencyCode} ${variant.price}")
                        }
                    }
                }
            }
            item {
                Button(
                    onClick = { selectedVariantId?.let(onAdd) },
                    enabled = selectedVariant?.available == true,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF0A0804)),
                    shape = CircleShape,
                ) { Text(if (selectedVariant == null) "UNAVAILABLE" else "ADD TO BAG · ${selectedVariant.currencyCode} ${selectedVariant.price}", style = MaterialTheme.typography.labelLarge) }
            }
            if (product.variants.none { it.available }) {
                item {
                    TextButton(onClick = onStockAlert, modifier = Modifier.fillMaxWidth()) {
                        Text(stringResource(if (watchingStock) R.string.stop_stock_alerts else R.string.notify_available))
                    }
                }
            }
            item { Spacer(Modifier.height(28.dp)) }
        }
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
internal fun CartSheet(
    lines: List<CartLine>,
    settings: TallaAppSettings,
    onAdd: (CartLine) -> Unit,
    onRemove: (CartLine) -> Unit,
    loading: Boolean,
    error: String?,
    onCheckout: (String) -> Unit,
    onHostedBenefit: (String) -> Unit,
    onClickToPay: (String) -> Unit,
    onBenefitPay: (String) -> Unit,
    onClearError: () -> Unit,
    onDismiss: () -> Unit,
    embeddedForTesting: Boolean = false,
) {
    val availableFulfillment = buildList {
        if (settings.fulfillment.deliveryEnabled) add("delivery")
        if (settings.fulfillment.pickupEnabled) add("pickup")
    }
    val availableMethods = CheckoutMethod.entries.filter { method ->
        when (method) {
            CheckoutMethod.CashOnDelivery -> settings.payments.cashOnDeliveryEnabled
            CheckoutMethod.Benefit -> settings.payments.benefitEnabled
            CheckoutMethod.ClickToPay -> settings.payments.cardEnabled
            CheckoutMethod.BenefitPay -> settings.payments.benefitPayEnabled
        }
    }
    var fulfillment by remember(settings.fulfillment) { mutableStateOf(availableFulfillment.firstOrNull().orEmpty()) }
    var checkoutMethod by remember(settings.payments) { mutableStateOf(availableMethods.firstOrNull() ?: CheckoutMethod.CashOnDelivery) }
    val isArabic = LocalConfiguration.current.locales[0].language == "ar"
    val subtotal = lines.sumOf { line -> (line.variant.price.toDoubleOrNull() ?: 0.0) * line.quantity }
    val content: @Composable () -> Unit = {
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(bottom = 32.dp)) {
            Text("YOUR BAG", style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
            Text("A good ritual starts here", style = MaterialTheme.typography.displaySmall, color = Ink)
            Spacer(Modifier.height(12.dp))
            if (lines.isEmpty()) Text(stringResource(R.string.empty_bag), color = MaterialTheme.colorScheme.onSurfaceVariant)
            lines.forEach { line ->
                Row(
                    Modifier.fillMaxWidth().padding(vertical = 6.dp).clip(RoundedCornerShape(18.dp)).background(TallaCard)
                        .border(1.dp, Sand.copy(alpha = .14f), RoundedCornerShape(18.dp)).padding(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    RemoteImage(line.product.imageUrl, line.product.name, Modifier.size(70.dp).clip(RoundedCornerShape(14.dp)))
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) { Text(line.product.name, style = MaterialTheme.typography.titleMedium, color = Ink); Text("${line.variant.currencyCode} ${line.variant.price}", style = MaterialTheme.typography.labelMedium, color = TallaGoldText) }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        IconButton(onClick = { onRemove(line) }, modifier = Modifier.size(34.dp)) { Icon(Icons.Default.Remove, "Remove one", Modifier.size(17.dp)) }
                        Text(line.quantity.toString(), style = MaterialTheme.typography.labelLarge)
                        IconButton(onClick = { onAdd(line) }, modifier = Modifier.size(34.dp)) { Icon(Icons.Default.Add, "Add one", Modifier.size(17.dp)) }
                    }
                }
            }
            if (lines.isNotEmpty()) {
                Row(Modifier.fillMaxWidth().padding(vertical = 14.dp)) {
                    Text("SUBTOTAL", Modifier.weight(1f), style = MaterialTheme.typography.labelMedium, color = Ink.copy(alpha = .72f))
                    Text("BHD ${"%.3f".format(subtotal)}", style = MaterialTheme.typography.titleMedium, color = Ink)
                }
                Spacer(Modifier.height(16.dp))
                Text(stringResource(R.string.fulfilment).uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (settings.fulfillment.deliveryEnabled) {
                        RadioButton(selected = fulfillment == "delivery", onClick = { fulfillment = "delivery" })
                        Text(stringResource(R.string.delivery))
                        Spacer(Modifier.width(18.dp))
                    }
                    if (settings.fulfillment.pickupEnabled) {
                        RadioButton(selected = fulfillment == "pickup", onClick = { fulfillment = "pickup" })
                        Text(if (isArabic) settings.fulfillment.pickupNameAr else settings.fulfillment.pickupNameEn)
                    }
                }
                if (fulfillment == "pickup") {
                    Text(if (isArabic) settings.fulfillment.pickupAddressAr else settings.fulfillment.pickupAddressEn, style = MaterialTheme.typography.bodySmall, color = Ink.copy(alpha = .72f))
                }
                Spacer(Modifier.height(12.dp))
                Text(stringResource(R.string.payment_method).uppercase(), style = MaterialTheme.typography.labelMedium, color = TallaGoldText)
                availableMethods.forEach { method ->
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp).clip(RoundedCornerShape(16.dp)).background(TallaCard)
                            .border(1.dp, Sand.copy(alpha = if (checkoutMethod == method) .45f else .12f), RoundedCornerShape(16.dp)).clickable { checkoutMethod = method }.padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(selected = checkoutMethod == method, onClick = { checkoutMethod = method })
                        Column(Modifier.weight(1f)) {
                            Text(stringResource(method.labelRes), fontWeight = FontWeight.SemiBold)
                            Text(
                                stringResource(method.detailRes),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                }
                val paymentNotice = if (isArabic) settings.payments.noticeAr else settings.payments.noticeEn
                if (paymentNotice.isNotBlank()) Text(paymentNotice, style = MaterialTheme.typography.bodySmall, color = TallaGoldText)
                if (settings.release.checkoutMaintenanceEnabled) Text(if (isArabic) "الدفع غير متاح مؤقتاً." else "Checkout is temporarily unavailable.", color = MaterialTheme.colorScheme.error)
                if (error != null) {
                    Text(error, color = MaterialTheme.colorScheme.error)
                    TextButton(onClick = onClearError) { Text(stringResource(R.string.dismiss)) }
                }
                Button(
                    onClick = {
                        when (checkoutMethod) {
                            CheckoutMethod.CashOnDelivery -> onCheckout(fulfillment)
                            CheckoutMethod.Benefit -> onHostedBenefit(fulfillment)
                            CheckoutMethod.ClickToPay -> onClickToPay(fulfillment)
                            CheckoutMethod.BenefitPay -> onBenefitPay(fulfillment)
                        }
                    },
                    enabled = !loading && availableFulfillment.isNotEmpty() && availableMethods.isNotEmpty() && !settings.release.checkoutMaintenanceEnabled,
                    modifier = Modifier.fillMaxWidth().testTag("checkout.continue"),
                    colors = ButtonDefaults.buttonColors(containerColor = Sand, contentColor = Color(0xFF0A0804)),
                    shape = CircleShape,
                ) {
                    if (loading) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                    else Text(stringResource(R.string.continue_to_payment).uppercase(), style = MaterialTheme.typography.labelLarge)
                }
            }
        }
    }
    if (embeddedForTesting) {
        content()
    } else {
        ModalBottomSheet(onDismissRequest = onDismiss, containerColor = MaterialTheme.colorScheme.background) { content() }
    }
}
