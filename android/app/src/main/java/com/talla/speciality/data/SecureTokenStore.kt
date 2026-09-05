package com.talla.speciality.data

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.core.content.edit
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class SecureTokenStore(context: Context) {
    private val preferences = context.getSharedPreferences("talla_secure_session", Context.MODE_PRIVATE)
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    fun save(token: String, refreshToken: String? = null) {
        saveEncrypted("token", token)
        if (refreshToken != null) saveEncrypted("refresh_token", refreshToken)
    }

    private fun saveEncrypted(name: String, token: String) {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = cipher.doFinal(token.toByteArray(Charsets.UTF_8))
        preferences.edit {
            putString(name, Base64.encodeToString(encrypted, Base64.NO_WRAP))
            putString("${name}_iv", Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
        }
    }

    fun read(): String? = readEncrypted("token")

    fun readRefreshToken(): String? = readEncrypted("refresh_token")

    private fun readEncrypted(name: String): String? = runCatching {
        val encrypted = preferences.getString(name, null) ?: return null
        val iv = preferences.getString("${name}_iv", null)
            ?: preferences.getString("iv", null)
            ?: return null
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP)))
        String(cipher.doFinal(Base64.decode(encrypted, Base64.NO_WRAP)), Charsets.UTF_8)
    }.getOrNull()

    fun clear() = preferences.edit { clear() }

    private fun key(): SecretKey {
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build()
        )
        return generator.generateKey()
    }

    private companion object {
        const val KEY_ALIAS = "talla_customer_session"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
    }
}
