package com.talla.speciality.telemetry

import android.content.Context
import android.os.SystemClock
import com.talla.speciality.BuildConfig
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import java.util.concurrent.Executors

object TallaTelemetry {
    private const val PREFERENCES = "talla_telemetry"
    private const val QUEUE = "pending_events_v1"
    private const val INSTALL_ID = "install_id"
    private const val ACTIVE_LAUNCH = "active_launch"
    private const val RETENTION_DAY = "retention_day"
    private const val MAX_EVENTS = 200
    private lateinit var appContext: Context
    private val executor = Executors.newSingleThreadExecutor()
    private val sessionId = UUID.randomUUID().toString()
    private val launchStartedAt = SystemClock.elapsedRealtime()

    fun initialize(context: Context) {
        appContext = context.applicationContext
        val preferences = preferences()
        if (preferences.getBoolean(ACTIVE_LAUNCH, false)) {
            track("crash_detected", "crash", mapOf("source" to "unclean_foreground_exit"))
        }
        preferences.edit().putBoolean(ACTIVE_LAUNCH, true).apply()
        installCrashHandler()
        track("app_opened")

        val today = LocalDate.now().toString()
        if (preferences.getString(RETENTION_DAY, null) != today) {
            preferences.edit().putString(RETENTION_DAY, today).apply()
            track("retention_active", properties = mapOf("day" to today))
        }
        flush()
    }

    fun appReady() {
        track(
            "app_launch_performance",
            "performance",
            mapOf("duration_ms" to (SystemClock.elapsedRealtime() - launchStartedAt)),
        )
    }

    fun enteredForeground() {
        if (!::appContext.isInitialized) return
        preferences().edit().putBoolean(ACTIVE_LAUNCH, true).apply()
        flush()
    }

    fun enteredBackground() {
        if (!::appContext.isInitialized) return
        preferences().edit().putBoolean(ACTIVE_LAUNCH, false).apply()
        flush()
    }

    fun track(name: String, category: String = "analytics", properties: Map<String, Any?> = emptyMap()) {
        if (!::appContext.isInitialized) return
        synchronized(this) {
            val queue = queue()
            queue.put(
                JSONObject()
                    .put("id", UUID.randomUUID().toString())
                    .put("eventName", name)
                    .put("category", category)
                    .put("platform", "android")
                    .put("anonymousId", installId())
                    .put("sessionId", sessionId)
                    .put("appVersion", BuildConfig.VERSION_NAME)
                    .put("occurredAt", Instant.now().toString())
                    .put("properties", JSONObject(properties.filterValues { it is String || it is Number || it is Boolean }))
            )
            while (queue.length() > MAX_EVENTS) queue.remove(0)
            preferences().edit().putString(QUEUE, queue.toString()).commit()
        }
        flush()
    }

    private fun installCrashHandler() {
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            track(
                "uncaught_exception",
                "crash",
                mapOf("thread" to thread.name.take(80), "exception_type" to throwable.javaClass.simpleName.take(120)),
            )
            previous?.uncaughtException(thread, throwable)
        }
    }

    private fun flush() {
        executor.execute {
            val batch = synchronized(this) {
                val queued = queue()
                JSONArray().apply { repeat(minOf(50, queued.length())) { put(queued.getJSONObject(it)) } }
            }
            if (batch.length() == 0 || BuildConfig.BACKEND_URL.isBlank()) return@execute
            val connection = (URL(BuildConfig.BACKEND_URL.trimEnd('/') + "/telemetry/events").openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 10_000
                readTimeout = 15_000
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
            }
            runCatching {
                connection.outputStream.use { it.write(JSONObject().put("events", batch).toString().toByteArray()) }
                if (connection.responseCode in 200..299) {
                    synchronized(this) {
                        val current = queue()
                        repeat(minOf(batch.length(), current.length())) { current.remove(0) }
                        preferences().edit().putString(QUEUE, current.toString()).commit()
                    }
                }
            }
            connection.disconnect()
        }
    }

    private fun preferences() = appContext.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    private fun queue() = runCatching { JSONArray(preferences().getString(QUEUE, "[]")) }.getOrElse { JSONArray() }

    private fun installId(): String {
        val preferences = preferences()
        return preferences.getString(INSTALL_ID, null) ?: UUID.randomUUID().toString().also {
            preferences.edit().putString(INSTALL_ID, it).commit()
        }
    }
}
