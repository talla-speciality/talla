package com.talla.speciality.security

import android.content.Context
import android.util.Base64
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import com.talla.speciality.BuildConfig
import kotlinx.coroutines.tasks.await
import java.security.MessageDigest

object PlayIntegrityClient {
    @Volatile
    private var provider: StandardIntegrityManager.StandardIntegrityTokenProvider? = null
    @Volatile
    private var preparing = false

    val configured: Boolean get() = BuildConfig.PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER > 0

    fun prepare(context: Context) {
        if (!configured || provider != null || preparing) return
        synchronized(this) {
            if (provider != null || preparing) return
            preparing = true
            IntegrityManagerFactory.createStandard(context.applicationContext)
                .prepareIntegrityToken(
                    StandardIntegrityManager.PrepareIntegrityTokenRequest.builder()
                        .setCloudProjectNumber(BuildConfig.PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER)
                        .build()
                )
                .addOnSuccessListener { prepared ->
                    provider = prepared
                    preparing = false
                }
                .addOnFailureListener { preparing = false }
        }
    }

    suspend fun headers(context: Context, method: String, path: String, rawBody: String): Map<String, String> {
        if (!configured) return emptyMap()
        prepare(context)
        val prepared = provider ?: IntegrityManagerFactory.createStandard(context.applicationContext)
            .prepareIntegrityToken(
                StandardIntegrityManager.PrepareIntegrityTokenRequest.builder()
                    .setCloudProjectNumber(BuildConfig.PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER)
                    .build()
            ).await().also { provider = it }
        val hash = requestHash(method, path, rawBody)
        val token = prepared.request(
            StandardIntegrityManager.StandardIntegrityTokenRequest.builder()
                .setRequestHash(hash)
                .build()
        ).await().token()
        return mapOf("X-Talla-Play-Integrity-Token" to token)
    }

    internal fun requestHash(method: String, path: String, rawBody: String): String {
        val source = "${method.uppercase()}\n$path\n$rawBody"
        val digest = MessageDigest.getInstance("SHA-256").digest(source.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(digest, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
    }
}
