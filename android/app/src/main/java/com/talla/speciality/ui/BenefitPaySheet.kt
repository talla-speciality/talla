package com.talla.speciality.ui

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.talla.speciality.BuildConfig
import com.talla.speciality.data.BenefitPaySession
import mobi.foo.benefitinapp.data.Transaction
import mobi.foo.benefitinapp.listener.BenefitInAppButtonListener
import mobi.foo.benefitinapp.listener.CheckoutListener
import mobi.foo.benefitinapp.utils.BenefitInAppButton
import mobi.foo.benefitinapp.utils.BenefitInAppCheckout

@Composable
@OptIn(ExperimentalMaterial3Api::class)
internal fun BenefitPaySheet(
    session: BenefitPaySession,
    loading: Boolean,
    onSuccess: () -> Unit,
    onFailure: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    val activity = LocalContext.current.findActivity()
    val secret = BuildConfig.BENEFITPAY_SDK_SECRET.trim()
    ModalBottomSheet(onDismissRequest = { if (!loading) onDismiss() }) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("BenefitPay", style = MaterialTheme.typography.headlineSmall)
            Text("BHD ${session.amount}", style = MaterialTheme.typography.titleLarge)
            Text(
                "Continue in the BenefitPay app. Talla verifies the transaction before completing your order.",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(4.dp))
            when {
                loading -> CircularProgressIndicator(Modifier.size(30.dp))
                secret.isEmpty() -> {
                    Text(
                        "BenefitPay is connected, but the production SDK credential has not been installed on this build.",
                        color = MaterialTheme.colorScheme.error,
                    )
                    Button(onClick = { onFailure("BenefitPay needs its production SDK credential") }) { Text("Close") }
                }
                activity == null -> Text("BenefitPay cannot open from this screen.", color = MaterialTheme.colorScheme.error)
                else -> AndroidView(
                    modifier = Modifier.size(width = 258.dp, height = 60.dp),
                    factory = { context ->
                        BenefitInAppButton(context).apply {
                            setListener(object : BenefitInAppButtonListener {
                                override fun onButtonClicked() {
                                    BenefitInAppCheckout.newInstance(
                                        activity, session.appId, session.referenceId, session.merchantId, secret,
                                        session.amount, session.countryCode, session.currencyCode,
                                        session.merchantCategoryCode, session.merchantName, session.merchantCity,
                                        object : CheckoutListener {
                                            override fun onTransactionSuccess(transaction: Transaction) = onSuccess()
                                            override fun onTransactionFail(transaction: Transaction) {
                                                onFailure(transaction.transactionMessage?.takeIf(String::isNotBlank) ?: "BenefitPay did not complete the payment")
                                            }
                                        },
                                    )
                                }

                                override fun onFail(reason: Int) = onFailure("BenefitPay could not start (reason $reason)")
                            })
                        }
                    },
                )
            }
            TextButton(onClick = onDismiss, enabled = !loading) { Text("Cancel") }
        }
    }
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}
