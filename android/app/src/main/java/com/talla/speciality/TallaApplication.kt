package com.talla.speciality

import android.app.Application
import com.talla.speciality.notifications.TallaNotifications
import com.talla.speciality.security.PlayIntegrityClient

class TallaApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        TallaNotifications.createChannels(this)
        PlayIntegrityClient.prepare(this)
    }
}
