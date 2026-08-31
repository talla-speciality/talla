package com.talla.speciality.notifications

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.talla.speciality.MainActivity
import com.talla.speciality.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class TallaFirebaseMessagingService : FirebaseMessagingService() {
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onRegistered(installationId: String) {
        PushRegistrationManager.saveRegistrationId(this, installationId)
        serviceScope.launch { PushRegistrationManager.syncWithStoredSession(this@TallaFirebaseMessagingService) }
    }

    override fun onUnregistered(installationId: String) {
        PushRegistrationManager.clearRegistrationId(this, installationId)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val title = message.notification?.title ?: message.data["title"] ?: "Talla"
        val body = message.notification?.body ?: message.data["body"] ?: return
        val type = message.data["type"].orEmpty()
        val destination = when (type) {
            "order_ready", "order_out_for_delivery", "delivery_arriving" -> "rewards"
            else -> "shop"
        }
        val intent = Intent(this, MainActivity::class.java).apply {
            data = Uri.parse("talla://$destination")
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            message.messageId?.hashCode() ?: System.currentTimeMillis().toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val channel = if (type.startsWith("order_") || type == "delivery_arriving") {
            TallaNotifications.ORDERS_CHANNEL
        } else {
            TallaNotifications.UPDATES_CHANNEL
        }
        val notification = NotificationCompat.Builder(this, channel)
            .setSmallIcon(R.drawable.talla_mark)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        runCatching { NotificationManagerCompat.from(this).notify(pendingIntent.hashCode(), notification) }
    }
}
