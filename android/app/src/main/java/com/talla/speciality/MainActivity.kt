package com.talla.speciality

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.talla.speciality.ui.TallaApp
import com.talla.speciality.ui.theme.TallaTheme
import com.talla.speciality.telemetry.TallaTelemetry
import mobi.foo.benefitinapp.utils.BenefitInAppHelper

class MainActivity : AppCompatActivity() {
    private var deepLinkDestination by mutableStateOf<String?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        deepLinkDestination = navigationDestination(intent)
        enableEdgeToEdge()
        setContent {
            TallaTheme {
                TallaApp(
                    deepLinkDestination = deepLinkDestination,
                    onDeepLinkConsumed = { deepLinkDestination = null },
                )
            }
        }
        window.decorView.post { TallaTelemetry.appReady() }
    }

    override fun onStop() {
        TallaTelemetry.enteredBackground()
        super.onStop()
    }

    override fun onStart() {
        super.onStart()
        TallaTelemetry.enteredForeground()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deepLinkDestination = navigationDestination(intent)
    }

    @Deprecated("Required by the supplied BenefitPay SDK callback contract")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == Activity.RESULT_OK && data != null) {
            BenefitInAppHelper.handleResult(data)
        }
    }

    private fun navigationDestination(intent: Intent?): String? = intent?.data?.takeIf {
        it.scheme.equals("talla", ignoreCase = true)
    }?.host?.lowercase()?.takeIf { it in setOf("shop", "brewing", "rewards") }
}
