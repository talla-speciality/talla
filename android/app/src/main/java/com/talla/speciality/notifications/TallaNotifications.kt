package com.talla.speciality.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

object TallaNotifications {
    const val UPDATES_CHANNEL = "updates"
    const val ORDERS_CHANNEL = "orders"

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannels(
            listOf(
                NotificationChannel(UPDATES_CHANNEL, "Talla updates", NotificationManager.IMPORTANCE_DEFAULT).apply {
                    description = "Product availability and Talla news"
                },
                NotificationChannel(ORDERS_CHANNEL, "Order updates", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "Time-sensitive order status updates"
                },
            )
        )
    }
}
