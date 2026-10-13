package com.talla.speciality.notifications

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.edit
import com.talla.speciality.MainActivity
import com.talla.speciality.R
import com.talla.speciality.data.PurchasedCoffee
import java.time.LocalDate

object ReorderReminderNotifier {
    private const val PREFERENCES = "talla_reorder_reminders"

    fun notifyIfLow(context: Context, coffee: PurchasedCoffee, doseGrams: Double = 18.0) {
        val notificationID = coffee.id.hashCode()
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val key = "last_notified_${coffee.id}"
        val brewsLeft = coffee.estimatedBrews(doseGrams)
        if (coffee.remainingQuantityGrams <= 0 || brewsLeft > 3) {
            preferences.edit { remove(key) }
            NotificationManagerCompat.from(context).cancel(notificationID)
            return
        }
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val today = LocalDate.now().toString()
        if (preferences.getString(key, null) == today) return

        val intent = Intent(context, MainActivity::class.java).apply {
            data = Uri.parse("talla://shop/coffee-beans")
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationID,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val body = "${coffee.productName} has about $brewsLeft brews left. Reorder before your next cup."
        val notification = NotificationCompat.Builder(context, TallaNotifications.UPDATES_CHANNEL)
            .setSmallIcon(R.drawable.talla_mark)
            .setContentTitle("Your coffee is running low")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        runCatching { NotificationManagerCompat.from(context).notify(notificationID, notification) }
        preferences.edit { putString(key, today) }
    }
}
