package com.talla.speciality.notifications

import android.content.Context
import androidx.core.content.edit
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.talla.speciality.data.AccountRepository
import com.talla.speciality.data.SecureTokenStore
import kotlinx.coroutines.tasks.await

object PushRegistrationManager {
    private const val PREFERENCES = "talla_push"
    private const val REGISTRATION_ID = "fcm_registration_id"

    fun saveRegistrationId(context: Context, registrationId: String) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit { putString(REGISTRATION_ID, registrationId) }
    }

    fun clearRegistrationId(context: Context, registrationId: String) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        if (preferences.getString(REGISTRATION_ID, null) == registrationId) {
            preferences.edit { remove(REGISTRATION_ID) }
        }
    }

    fun savedRegistrationId(context: Context): String? =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(REGISTRATION_ID, null)

    suspend fun syncForSession(context: Context, accessToken: String, email: String) {
        val registrationId = currentRegistrationId(context) ?: return
        AccountRepository(context.applicationContext).registerPushToken(accessToken, email, registrationId)
    }

    suspend fun unregister(context: Context, accessToken: String, email: String) {
        val registrationId = savedRegistrationId(context) ?: return
        runCatching { AccountRepository(context.applicationContext).unregisterPushToken(accessToken, email, registrationId) }
    }

    suspend fun syncWithStoredSession(context: Context) {
        val accessToken = SecureTokenStore(context).read() ?: return
        val repository = AccountRepository(context.applicationContext)
        val profile = runCatching { repository.profile(accessToken) }.getOrNull() ?: return
        syncForSession(context, accessToken, profile.email)
    }

    private suspend fun currentRegistrationId(context: Context): String? {
        savedRegistrationId(context)?.let { return it }
        if (FirebaseApp.getApps(context).isEmpty()) return null
        runCatching { FirebaseMessaging.getInstance().register().await() }
        return savedRegistrationId(context)
    }
}
