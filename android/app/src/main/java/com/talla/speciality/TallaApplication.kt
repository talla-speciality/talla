package com.talla.speciality

import android.app.Application
import com.talla.speciality.notifications.TallaNotifications
import com.talla.speciality.security.PlayIntegrityClient
import com.talla.speciality.data.CoffeeDataStore
import com.talla.speciality.telemetry.TallaTelemetry

class TallaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        TallaTelemetry.initialize(this)
        CoffeeDataStore(this) // Opens the offline store and performs idempotent legacy migration.
        TallaNotifications.createChannels(this)
        PlayIntegrityClient.prepare(this)
    }
}
