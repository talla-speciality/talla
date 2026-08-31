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
import androidx.compose.foundation.layout.size
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
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.ThumbDown
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Badge
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import androidx.core.net.toUri
import androidx.core.content.FileProvider
import androidx.core.content.ContextCompat
import com.talla.speciality.R
import com.talla.speciality.data.CartLine
import com.talla.speciality.data.BrewRecipeEngine
import com.talla.speciality.data.BrewJournalEntry
import com.talla.speciality.data.BrewRecipe
import com.talla.speciality.data.CoffeeBagScanResult
import com.talla.speciality.data.CustomerOrder
import com.talla.speciality.data.Product
import com.talla.speciality.data.ScaleFamily
import com.talla.speciality.data.ScaleUiState
import com.talla.speciality.data.TasteMemoryRecord
import com.talla.speciality.ui.theme.Coffee
import com.talla.speciality.ui.theme.Sand
import com.talla.speciality.ui.theme.Sage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.net.URL
import java.io.File

private enum class TallaTab(val labelRes: Int, val icon: ImageVector) {
    Home(R.string.home, Icons.Default.Home),
    Shop(R.string.shop, Icons.Default.Storefront),
    Brewing(R.string.brewing, Icons.Default.Science),
    Account(R.string.account, Icons.Default.Person),
}

private enum class CheckoutMethod(val labelRes: Int, val detailRes: Int) {
    CashOnDelivery(R.string.cash_on_delivery, R.string.cash_on_delivery_detail),
    Benefit(R.string.pay_with_benefit_card, R.string.benefit_card_detail),
    ClickToPay(R.string.pay_with_click_to_pay, R.string.click_to_pay_detail),
    BenefitPay(R.string.pay_with_benefitpay, R.string.benefitpay_detail),
}

@Composable
fun TallaApp(viewModel: TallaViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var tab by remember { mutableStateOf(TallaTab.Home) }
    var cartOpen by remember { mutableStateOf(false) }
    var selectedProduct by remember { mutableStateOf<Product?>(null) }

    LaunchedEffect(state.checkoutUrl) {
        state.checkoutUrl?.let { url ->
            context.startActivity(Intent(Intent.ACTION_VIEW, url.toUri()))
            viewModel.consumeCheckoutUrl()
        }
    }

    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        viewModel.checkHostedBenefitStatus()
        viewModel.checkClickToPayStatus()
    }

    val openProduct: (Product) -> Unit = { product ->
        viewModel.markViewed(product.id)
        selectedProduct = product
    }

    Scaffold(
        topBar = {
            TallaTopBar(
                cartCount = state.cartCount,
                onCartClick = { cartOpen = true },
            )
        },
        bottomBar = {
            NavigationBar {
                TallaTab.entries.forEach { destination ->
                    NavigationBarItem(
                        selected = tab == destination,
                        onClick = { tab = destination },
                        icon = { Icon(destination.icon, contentDescription = stringResource(destination.labelRes)) },
                        label = { Text(stringResource(destination.labelRes)) },
                    )
                }
            }
        },
    ) { padding ->
        when (tab) {
            TallaTab.Home -> HomeScreen(state, viewModel::refresh, viewModel::addToCart, openProduct, Modifier.padding(padding))
            TallaTab.Shop -> ShopScreen(state, viewModel::refresh, viewModel::addToCart, openProduct, Modifier.padding(padding))
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
                modifier = Modifier.padding(padding),
            )
            TallaTab.Account -> AccountScreen(
                state = state,
                onLogin = viewModel::login,
                onRegister = viewModel::register,
                onLogout = viewModel::logout,
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
private fun TallaTopBar(cartCount: Int, onCartClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier.size(42.dp).clip(CircleShape).background(Sand),
            contentAlignment = Alignment.Center,
        ) {
            Image(
                painter = painterResource(R.drawable.talla_logo),
                contentDescription = "Talla",
                modifier = Modifier.size(38.dp),
            )
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text("TALLA", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Black)
            Text(stringResource(R.string.speciality_coffee), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        IconButton(onClick = onCartClick) {
            BadgedBox(badge = { if (cartCount > 0) Badge { Text(cartCount.toString()) } }) {
                Icon(Icons.Default.ShoppingBag, contentDescription = stringResource(R.string.shopping_bag))
            }
        }
    }
}

@Composable
private fun HomeScreen(state: TallaUiState, retry: () -> Unit, add: (Product) -> Unit, open: (Product) -> Unit, modifier: Modifier = Modifier) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        item { HeroCard() }
        item {
            SectionHeading(stringResource(R.string.fresh_from_talla), stringResource(R.string.shop_all))
            ProductStatus(state, retry) {
                LazyRow(contentPadding = PaddingValues(horizontal = 20.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    items(state.products.take(8), key = { it.id }) { product ->
                        ProductCard(product, add, open, product.id in state.favoriteProductIds, Modifier.width(220.dp))
                    }
                }
            }
        }
        item {
            Card(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp),
                colors = CardDefaults.cardColors(containerColor = Sage),
                shape = RoundedCornerShape(28.dp),
            ) {
                Column(Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(stringResource(R.string.brew_with_intention), color = androidx.compose.ui.graphics.Color.White, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    Text(stringResource(R.string.brew_card_detail), color = androidx.compose.ui.graphics.Color.White.copy(alpha = .82f))
                }
            }
        }
    }
}

@Composable
private fun HeroCard() {
    Card(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp),
        colors = CardDefaults.cardColors(containerColor = Coffee),
        shape = RoundedCornerShape(32.dp),
    ) {
        Column(Modifier.padding(28.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(stringResource(R.string.hero_title), color = androidx.compose.ui.graphics.Color.White, style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Black)
            Text(stringResource(R.string.hero_detail), color = androidx.compose.ui.graphics.Color.White.copy(alpha = .8f))
            Icon(Icons.Default.Coffee, contentDescription = null, tint = Sand, modifier = Modifier.size(72.dp).align(Alignment.End))
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
private fun ShopScreen(state: TallaUiState, retry: () -> Unit, add: (Product) -> Unit, open: (Product) -> Unit, modifier: Modifier = Modifier) {
    var query by remember { mutableStateOf("") }
    var category by remember { mutableStateOf<String?>(null) }
    val categories = state.products.map { it.category }.distinct().sorted()
    val visibleProducts = state.products.filter { product ->
        (category == null || product.category == category) &&
            (query.isBlank() || product.name.contains(query, ignoreCase = true) || product.description.contains(query, ignoreCase = true))
    }
    Column(modifier.fillMaxSize()) {
        SectionHeading(stringResource(R.string.the_shop))
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
            placeholder = { Text(stringResource(R.string.search_hint)) },
            leadingIcon = { Icon(Icons.Default.Search, null) },
            singleLine = true,
            shape = RoundedCornerShape(18.dp),
        )
        LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            item { FilterChip(selected = category == null, onClick = { category = null }, label = { Text(stringResource(R.string.all)) }) }
            items(categories) { item -> FilterChip(selected = category == item, onClick = { category = item }, label = { Text(item) }) }
        }
        Spacer(Modifier.height(8.dp))
        ProductStatus(state, retry) {
            LazyVerticalGrid(
                modifier = Modifier.fillMaxSize(),
                columns = GridCells.Adaptive(170.dp),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(visibleProducts, key = { it.id }) { product ->
                    ProductCard(product, add, open, product.id in state.favoriteProductIds)
                }
            }
        }
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
private fun ProductCard(product: Product, add: (Product) -> Unit, open: (Product) -> Unit, favorite: Boolean, modifier: Modifier = Modifier) {
    Card(onClick = { open(product) }, modifier = modifier, shape = RoundedCornerShape(24.dp)) {
        RemoteImage(product.imageUrl, product.name, Modifier.fillMaxWidth().height(170.dp))
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(product.category.uppercase(), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.secondary)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(product.name, modifier = Modifier.weight(1f), maxLines = 2, overflow = TextOverflow.Ellipsis, fontWeight = FontWeight.Bold)
                if (favorite) Icon(Icons.Default.Favorite, null, tint = Sand, modifier = Modifier.size(18.dp))
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(product.priceLabel, modifier = Modifier.weight(1f), style = MaterialTheme.typography.labelLarge)
                IconButton(onClick = { add(product) }, enabled = product.defaultVariant?.available == true) {
                    Icon(Icons.Default.Add, contentDescription = "Add ${product.name}")
                }
            }
        }
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
    modifier: Modifier = Modifier,
) {
    val methods = listOf("V60", "Kalita", "AeroPress", "French press", "Espresso", "Cold brew")
    var brewer by remember { mutableStateOf("V60") }
    var dose by remember { mutableFloatStateOf(20f) }
    var ratio by remember { mutableFloatStateOf(15f) }
    var elapsed by remember { mutableIntStateOf(0) }
    var running by remember { mutableStateOf(false) }
    val recipe = remember(brewer, dose, ratio) { BrewRecipeEngine.generate(brewer, dose.toInt(), ratio.toDouble()) }
    val activeStepIndex = recipe.steps.indexOfLast { it.startSeconds <= elapsed }.coerceAtLeast(0)

    LaunchedEffect(running) {
        while (running) {
            delay(1_000)
            elapsed += 1
        }
    }

    LazyColumn(modifier.fillMaxSize(), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        item { Text(stringResource(R.string.brewing_studio), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black) }
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
private fun CoffeeScaleCard(
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
private fun AccountScreen(
    state: TallaUiState,
    onLogin: (String, String) -> Unit,
    onRegister: (String, String, String, String) -> Unit,
    onLogout: () -> Unit,
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
    val languageTag = AppCompatDelegate.getApplicationLocales().toLanguageTags()
    LazyColumn(modifier.fillMaxSize(), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(stringResource(R.string.hello_name, profile.firstName), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
                    Text(profile.email, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                IconButton(onClick = onRefresh) { Icon(Icons.Default.Refresh, "Refresh account") }
            }
        }
        state.loyalty?.let { loyalty ->
            item {
                Card(colors = CardDefaults.cardColors(containerColor = Coffee), shape = RoundedCornerShape(28.dp)) {
                    Column(Modifier.fillMaxWidth().padding(22.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                        Text(loyalty.tier.uppercase(), color = Sand, style = MaterialTheme.typography.labelLarge)
                        Text(pluralStringResource(R.plurals.beans_count, loyalty.pointsBalance, loyalty.pointsBalance), color = androidx.compose.ui.graphics.Color.White, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
                        Text(loyalty.nextReward, color = androidx.compose.ui.graphics.Color.White.copy(alpha = .78f))
                        Text(stringResource(R.string.member_id, loyalty.memberId), color = androidx.compose.ui.graphics.Color.White.copy(alpha = .6f), style = MaterialTheme.typography.labelSmall)
                    }
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
                FilterChip(selected = languageTag.startsWith("ar"), onClick = { AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags("ar")) }, label = { Text(stringResource(R.string.arabic)) })
            }
        }
        item { TextButton(onClick = onLogout) { Text(stringResource(R.string.sign_out)) } }
    }
    if (addingAddress) {
        AddAddressDialog(onDismiss = { addingAddress = false }) { label, name, phone, line1, city, country ->
            onSaveAddress(label, name, phone, line1, city, country)
            addingAddress = false
        }
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
private fun SignedOutAccount(
    state: TallaUiState,
    onLogin: (String, String) -> Unit,
    onRegister: (String, String, String, String) -> Unit,
    modifier: Modifier = Modifier,
) {
    var registering by remember { mutableStateOf(false) }
    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    LazyColumn(modifier.fillMaxSize(), contentPadding = PaddingValues(20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        item { Text(stringResource(if (registering) R.string.join_talla else R.string.welcome_back), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black) }
        item { Text(stringResource(R.string.signin_detail), color = MaterialTheme.colorScheme.onSurfaceVariant) }
        if (registering) {
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(firstName, { firstName = it }, Modifier.weight(1f), label = { Text(stringResource(R.string.first_name)) }, singleLine = true)
                    OutlinedTextField(lastName, { lastName = it }, Modifier.weight(1f), label = { Text(stringResource(R.string.last_name)) }, singleLine = true)
                }
            }
        }
        item { OutlinedTextField(email, { email = it }, Modifier.fillMaxWidth(), label = { Text(stringResource(R.string.email)) }, singleLine = true) }
        item {
            OutlinedTextField(
                password, { password = it }, Modifier.fillMaxWidth(), label = { Text(stringResource(R.string.password)) }, singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
            )
        }
        state.accountError?.let { message -> item { Text(message, color = MaterialTheme.colorScheme.error) } }
        item {
            Button(
                onClick = { if (registering) onRegister(firstName, lastName, email, password) else onLogin(email, password) },
                enabled = !state.accountLoading && email.isNotBlank() && password.length >= 5 && (!registering || firstName.isNotBlank() && lastName.isNotBlank()),
                modifier = Modifier.fillMaxWidth(),
            ) {
                if (state.accountLoading) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                else Text(stringResource(if (registering) R.string.create_account else R.string.sign_in))
            }
        }
        item { TextButton(onClick = { registering = !registering }) { Text(stringResource(if (registering) R.string.already_account else R.string.new_to_talla)) } }
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
    ModalBottomSheet(onDismissRequest = onDismiss) {
        LazyColumn(
            modifier = Modifier.fillMaxWidth(),
            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item { RemoteImage(product.imageUrl, product.name, Modifier.fillMaxWidth().height(300.dp).clip(RoundedCornerShape(28.dp))) }
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(product.category.uppercase(), style = MaterialTheme.typography.labelMedium, color = Sand)
                        Text(product.name, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Black)
                    }
                    IconButton(onClick = onFavorite) {
                        Icon(if (favorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder, "Favourite", tint = if (favorite) Sand else MaterialTheme.colorScheme.onSurface)
                    }
                }
            }
            if (product.description.isNotBlank()) item { Text(product.description, color = MaterialTheme.colorScheme.onSurfaceVariant) }
            if (product.variants.size > 1) {
                item { Text(stringResource(R.string.choose_option), fontWeight = FontWeight.Bold) }
                items(product.variants, key = { it.id }) { variant ->
                    Card(onClick = { if (variant.available) selectedVariantId = variant.id }, shape = RoundedCornerShape(16.dp)) {
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
                ) { Text(if (selectedVariant == null) "Unavailable" else "Add to bag · ${selectedVariant.currencyCode} ${selectedVariant.price}") }
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
private fun CartSheet(
    lines: List<CartLine>,
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
) {
    var fulfillment by remember { mutableStateOf("delivery") }
    var checkoutMethod by remember { mutableStateOf(CheckoutMethod.CashOnDelivery) }
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 32.dp)) {
            Text(stringResource(R.string.your_bag), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Black)
            Spacer(Modifier.height(12.dp))
            if (lines.isEmpty()) Text(stringResource(R.string.empty_bag), color = MaterialTheme.colorScheme.onSurfaceVariant)
            lines.forEach { line ->
                Row(Modifier.fillMaxWidth().padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) { Text(line.product.name, fontWeight = FontWeight.Bold); Text(line.product.priceLabel) }
                    IconButton(onClick = { onRemove(line) }) { Icon(Icons.Default.Remove, "Remove one") }
                    Text(line.quantity.toString())
                    IconButton(onClick = { onAdd(line) }) { Icon(Icons.Default.Add, "Add one") }
                }
                HorizontalDivider()
            }
            if (lines.isNotEmpty()) {
                Spacer(Modifier.height(16.dp))
                Text(stringResource(R.string.fulfilment), fontWeight = FontWeight.Bold)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    RadioButton(selected = fulfillment == "delivery", onClick = { fulfillment = "delivery" })
                    Text(stringResource(R.string.delivery))
                    Spacer(Modifier.width(18.dp))
                    RadioButton(selected = fulfillment == "pickup", onClick = { fulfillment = "pickup" })
                    Text(stringResource(R.string.pickup_riffa))
                }
                Spacer(Modifier.height(12.dp))
                Text(stringResource(R.string.payment_method), fontWeight = FontWeight.Bold)
                CheckoutMethod.entries.forEach { method ->
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 3.dp),
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
                    enabled = !loading,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    if (loading) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                    else Text(stringResource(R.string.continue_to_payment))
                }
            }
        }
    }
}
