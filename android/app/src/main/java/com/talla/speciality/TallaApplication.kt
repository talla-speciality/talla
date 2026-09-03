package com.talla.speciality

import android.app.Application
import com.talla.speciality.notifications.TallaNotifications
import com.talla.speciality.security.PlayIntegrityClient
import com.talla.speciality.data.CoffeeDataStore

class TallaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CoffeeDataStore(this) // Opens the offline store and performs idempotent legacy migration.
        TallaNotifications.createChannels(this)
        PlayIntegrityClient.prepare(this)
    }
}
