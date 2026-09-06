package com.talla.speciality.ui

import android.content.res.Configuration
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.unit.LayoutDirection
import com.talla.speciality.data.AccountProfile
import com.talla.speciality.data.CartLine
import com.talla.speciality.data.PaymentSettings
import com.talla.speciality.data.Product
import com.talla.speciality.data.ProductVariant
import com.talla.speciality.data.ScaleUiState
import com.talla.speciality.data.TallaAppSettings
import com.talla.speciality.ui.theme.TallaTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import java.util.Locale

class ReleaseHardeningJourneysTest {
    @get:Rule val compose = createComposeRule()

    private val product = Product(
        id = "coffee-1", handle = "coffee-1", name = "Test Coffee", description = "",
        imageUrl = null, category = "Coffee Beans",
        variants = listOf(ProductVariant("variant-1", "250 g", "8.500", "BHD", true, true, 250.0)),
    )

    @Test fun checkoutJourneyReachesSelectedPaymentHandler() {
        var fulfillment = ""
        compose.setContent {
            TallaTheme {
                CartSheet(
                    lines = listOf(CartLine(product, product.variants.first(), 1)),
                    settings = TallaAppSettings(), onAdd = {}, onRemove = {}, loading = false, error = null,
                    onCheckout = { fulfillment = it }, onHostedBenefit = {}, onClickToPay = {}, onBenefitPay = {},
                    onClearError = {}, onDismiss = {}, embeddedForTesting = true,
                )
            }
        }
        compose.onNodeWithTag("checkout.continue").performScrollTo().performClick()
        assertEquals("delivery", fulfillment)
    }

    @Test fun arabicCheckoutUsesArabicOperationalNoticeAndRtl() {
        val arabic = Locale.forLanguageTag("ar")
        val configuration = Configuration().apply { setLocale(arabic); setLayoutDirection(arabic) }
        compose.setContent {
            CompositionLocalProvider(
                LocalConfiguration provides configuration,
                LocalLayoutDirection provides LayoutDirection.Rtl,
            ) {
                TallaTheme {
                    CartSheet(
                        lines = listOf(CartLine(product, product.variants.first(), 1)),
                        settings = TallaAppSettings(payments = PaymentSettings(noticeAr = "اختبار الدفع الآمن")),
                        onAdd = {}, onRemove = {}, loading = false, error = null, onCheckout = {},
                        onHostedBenefit = {}, onClickToPay = {}, onBenefitPay = {}, onClearError = {}, onDismiss = {},
                        embeddedForTesting = true,
                    )
                }
            }
        }
        compose.onNodeWithText("اختبار الدفع الآمن").performScrollTo().assertIsDisplayed()
    }

    @Test fun accountDeletionRequiresExplicitConfirmation() {
        var deleted = false
        compose.setContent {
            TallaTheme {
                AccountScreen(
                    state = TallaUiState(profile = AccountProfile("customer-1", "Talla", "Customer", "customer@example.com")),
                    onLogin = { _, _ -> }, onRegister = { _, _, _, _ -> }, onLogout = {},
                    onDeleteAccount = { deleted = true }, onRefresh = {}, onSaveAddress = { _, _, _, _, _, _ -> },
                    onDeleteAddress = {}, onSaveTasteMemory = { _, _, _, _ -> }, openProduct = {},
                )
            }
        }
        compose.onNodeWithTag("account.delete").performScrollTo().performClick()
        assertTrue(!deleted)
        compose.onNodeWithTag("account.delete.confirm").performClick()
        assertTrue(deleted)
    }

    @Test fun offlineInventoryAcceptsLocalCoffeeWithoutNetwork() {
        var savedName = ""
        compose.setContent {
            TallaTheme {
                CoffeeInventoryCard(
                    inventory = emptyList(), equipment = emptyList(), calibrations = emptyList(), maintenance = emptyList(), conflicts = emptyList(),
                    onAddCoffee = { name, _, _ -> savedName = name },
                    onUpdateRemaining = { _, _ -> }, onSaveEquipment = { _, _, _, _, _ -> },
                    onSaveCalibration = { _, _, _, _, _, _ -> }, onSaveMaintenance = { _, _, _, _ -> },
                    onDeleteEquipment = {}, onDeleteCalibration = {}, onDeleteMaintenance = {}, onResolveConflict = { _, _ -> },
                )
            }
        }
        compose.onNodeWithTag("coffee.inventory.name").performClick()
        compose.onNodeWithTag("coffee.inventory.name").performTextInput("Offline Lot")
        compose.onNodeWithTag("coffee.inventory.save").performClick()
        assertEquals("Offline Lot", savedName)
    }

    @Test fun bluetoothInterruptionIsVisibleAndRecoverable() {
        var dismissed = false
        compose.setContent {
            TallaTheme {
                CoffeeScaleCard(
                    state = ScaleUiState(error = "Bluetooth connection interrupted"), targetGrams = 300,
                    onScan = {}, onConnect = {}, onDisconnect = {}, onTare = {}, onStartTimer = {},
                    onPauseTimer = {}, onStopTimer = {}, onClearError = { dismissed = true },
                )
            }
        }
        compose.onNodeWithText("Bluetooth connection interrupted").assertIsDisplayed()
        compose.onNodeWithText("Dismiss").performClick()
        assertTrue(dismissed)
    }
}
