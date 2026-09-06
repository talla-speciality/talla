package com.talla.speciality.data

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import com.talla.speciality.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID

enum class CoffeeEntityType(val wireName: String) {
    COFFEE_LOT("coffeeLot"), PURCHASED_COFFEE("purchasedCoffee"), EQUIPMENT("equipment"),
    CALIBRATION("calibration"), RECIPE("recipe"), RECIPE_VERSION("recipeVersion"),
    BREW_SESSION("brewSession"), SAMPLE("sample"), TASTE_FEEDBACK("tasteFeedback"),
    MAINTENANCE("maintenance")
}
enum class EquipmentType { BREWER, MACHINE, BASKET, GRINDER }
enum class SessionType { FILTER, ESPRESSO }
enum class SampleType { WEIGHT, FLOW, PRESSURE, TEMPERATURE }

data class CoffeeLot(val id: String = UUID.randomUUID().toString(), val name: String, val roaster: String = "", val origin: String? = null, val producer: String? = null, val variety: String? = null, val process: String? = null, val roastLevel: String? = null, val notes: String? = null)
data class PurchasedCoffee(val id: String = UUID.randomUUID().toString(), val lotId: String? = null, val productId: String? = null, val productName: String, val roastDate: Long? = null, val purchasedAt: Long? = null, val initialQuantityGrams: Double, val remainingQuantityGrams: Double, val currencyCode: String? = null, val priceMinor: Int? = null)
data class CoffeeEquipment(val id: String = UUID.randomUUID().toString(), val type: EquipmentType, val name: String, val manufacturer: String? = null, val model: String? = null, val parentEquipmentId: String? = null, val notes: String? = null)
data class EquipmentCalibration(val id: String = UUID.randomUUID().toString(), val equipmentId: String, val coffeeLotId: String? = null, val setting: String, val measuredValue: Double? = null, val unit: String? = null, val notes: String? = null)
data class CoffeeRecipe(val id: String = UUID.randomUUID().toString(), val title: String, val type: SessionType, val currentVersionId: String? = null)
data class RecipeVersion(val id: String = UUID.randomUUID().toString(), val recipeId: String, val versionNumber: Int, val coffeeGrams: Double, val waterGrams: Double? = null, val targetYieldGrams: Double? = null, val temperatureC: Double? = null, val targetSeconds: Int? = null, val grindSetting: String? = null, val pressureBar: Double? = null, val stepsJson: String = "[]", val notes: String? = null)
data class CoffeeBrewSession(val id: String = UUID.randomUUID().toString(), val type: SessionType, val recipeVersionId: String? = null, val purchasedCoffeeId: String? = null, val grinderId: String? = null, val brewerId: String? = null, val machineId: String? = null, val basketId: String? = null, val startedAt: Long = System.currentTimeMillis(), val endedAt: Long? = null, val doseGrams: Double? = null, val yieldGrams: Double? = null, val waterGrams: Double? = null, val notes: String? = null)
data class BrewSample(val id: String = UUID.randomUUID().toString(), val sessionId: String, val type: SampleType, val elapsedMilliseconds: Int, val value: Double, val unit: String)
data class CoffeeTasteFeedback(val id: String = UUID.randomUUID().toString(), val sessionId: String? = null, val purchasedCoffeeId: String? = null, val rating: Int, val tagsJson: String = "[]", val notes: String = "")
data class MaintenanceEvent(val id: String = UUID.randomUUID().toString(), val equipmentId: String, val type: String, val performedAt: Long = System.currentTimeMillis(), val usageCount: Int? = null, val notes: String? = null)

data class CoffeeRecord(val ownerId: String, val entityType: String, val id: String, val payload: JSONObject, val updatedAt: Long, val deletedAt: Long?, val revision: Long, val dirty: Boolean, val conflictPayload: JSONObject? = null)
data class CoffeeConflict(val ownerId: String, val entityType: String, val id: String, val localPayload: JSONObject, val serverPayload: JSONObject)

class CoffeeDataStore(context: Context) {
    private val appContext = context.applicationContext
    private val helper = Helper(appContext)
    private val legacy = appContext.getSharedPreferences("talla_state", Context.MODE_PRIVATE)

    init { migrateLegacyJson() }

    fun upsert(ownerId: String = "", type: CoffeeEntityType, id: String, payload: JSONObject, baseRevision: Long? = null) {
        val current = find(ownerId, type.wireName, id)
        if (current?.deletedAt == null && current?.payload?.toString() == payload.toString()) return
        val values = ContentValues().apply {
            put("owner_id", ownerId); put("entity_type", type.wireName); put("record_id", id.lowercase())
            put("payload", payload.toString()); put("updated_at", System.currentTimeMillis()); putNull("deleted_at")
            put("revision", baseRevision ?: current?.revision ?: 0); put("dirty", 1)
        }
        helper.writableDatabase.insertWithOnConflict("coffee_records", null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    fun tombstone(ownerId: String = "", type: CoffeeEntityType, id: String) {
        val current = find(ownerId, type.wireName, id)
        upsert(ownerId, type, id, current?.payload ?: JSONObject(), current?.revision ?: 0)
        helper.writableDatabase.execSQL("UPDATE coffee_records SET deleted_at=?, dirty=1 WHERE owner_id=? AND entity_type=? AND record_id=?", arrayOf<Any?>(System.currentTimeMillis(), ownerId, type.wireName, id.lowercase()))
        if (type == CoffeeEntityType.BREW_SESSION) {
            tombstone(ownerId, CoffeeEntityType.TASTE_FEEDBACK, id)
        }
    }

    fun records(ownerId: String = "", type: CoffeeEntityType, includeDeleted: Boolean = false): List<CoffeeRecord> {
        val where = if (includeDeleted) "owner_id=? AND entity_type=?" else "owner_id=? AND entity_type=? AND deleted_at IS NULL"
        return query(where, arrayOf(ownerId, type.wireName))
    }

    fun claimLocalRecords(ownerId: String) {
        helper.writableDatabase.execSQL("UPDATE OR IGNORE coffee_records SET owner_id=? WHERE owner_id=''", arrayOf(ownerId))
    }

    fun savePurchasedCoffee(value: PurchasedCoffee, ownerId: String = "") {
        val lotId = value.lotId ?: UUID.randomUUID().toString()
        if (value.lotId == null) {
            upsert(ownerId, CoffeeEntityType.COFFEE_LOT, lotId, JSONObject()
                .put("id", lotId).put("name", value.productName))
        }
        upsert(ownerId, CoffeeEntityType.PURCHASED_COFFEE, value.id, JSONObject()
            .put("id", value.id).put("lotID", lotId).put("productID", value.productId)
            .put("productName", value.productName).put("roastDate", value.roastDate)
            .put("purchasedAt", value.purchasedAt ?: System.currentTimeMillis())
            .put("initialQuantityGrams", value.initialQuantityGrams)
            .put("remainingQuantityGrams", value.remainingQuantityGrams)
            .put("currencyCode", value.currencyCode).put("priceMinor", value.priceMinor))
    }

    fun purchasedCoffee(ownerId: String = ""): List<PurchasedCoffee> = records(ownerId, CoffeeEntityType.PURCHASED_COFFEE).map { record ->
        val json = record.payload
        PurchasedCoffee(
            id = record.id,
            lotId = json.optNullableString("lotID"),
            productId = json.optNullableString("productID"),
            productName = json.optString("productName", "Coffee"),
            roastDate = json.optNullableLong("roastDate"),
            purchasedAt = json.optNullableLong("purchasedAt"),
            initialQuantityGrams = json.optDouble("initialQuantityGrams", 0.0),
            remainingQuantityGrams = json.optDouble("remainingQuantityGrams", 0.0),
            currencyCode = json.optNullableString("currencyCode"),
            priceMinor = json.optNullableInt("priceMinor"),
        )
    }

    fun updateRemainingQuantity(ownerId: String = "", id: String, remainingGrams: Double) {
        val current = find(ownerId, CoffeeEntityType.PURCHASED_COFFEE.wireName, id) ?: return
        val payload = JSONObject(current.payload.toString()).put("remainingQuantityGrams", remainingGrams.coerceAtLeast(0.0))
        upsert(ownerId, CoffeeEntityType.PURCHASED_COFFEE, id, payload, current.revision)
    }

    fun saveEquipment(value: CoffeeEquipment, ownerId: String = "") {
        upsert(ownerId, CoffeeEntityType.EQUIPMENT, value.id, JSONObject()
            .put("id", value.id).put("kind", value.type.name.lowercase())
            .put("name", value.name).put("manufacturer", value.manufacturer)
            .put("model", value.model).put("parentEquipmentID", value.parentEquipmentId)
            .put("notes", value.notes))
    }

    fun equipment(ownerId: String = ""): List<CoffeeEquipment> = records(ownerId, CoffeeEntityType.EQUIPMENT).map { record ->
        val json = record.payload
        CoffeeEquipment(
            id = record.id,
            type = runCatching { EquipmentType.valueOf(json.optString("kind").uppercase()) }.getOrDefault(EquipmentType.BREWER),
            name = json.optString("name", "Equipment"),
            manufacturer = json.optNullableString("manufacturer"),
            model = json.optNullableString("model"),
            parentEquipmentId = json.optNullableString("parentEquipmentID"),
            notes = json.optNullableString("notes"),
        )
    }

    fun saveCalibration(value: EquipmentCalibration, ownerId: String = "") {
        upsert(ownerId, CoffeeEntityType.CALIBRATION, value.id, JSONObject()
            .put("id", value.id).put("equipmentID", value.equipmentId)
            .put("coffeeLotID", value.coffeeLotId).put("setting", value.setting)
            .put("measuredValue", value.measuredValue).put("unit", value.unit)
            .put("notes", value.notes))
    }

    fun calibrations(ownerId: String = ""): List<EquipmentCalibration> = records(ownerId, CoffeeEntityType.CALIBRATION).map { record ->
        val json = record.payload
        EquipmentCalibration(
            id = record.id,
            equipmentId = json.optString("equipmentID"),
            coffeeLotId = json.optNullableString("coffeeLotID"),
            setting = json.optString("setting"),
            measuredValue = if (json.isNull("measuredValue")) null else json.optDouble("measuredValue"),
            unit = json.optNullableString("unit"),
            notes = json.optNullableString("notes"),
        )
    }

    fun maintenance(ownerId: String = ""): List<MaintenanceEvent> = records(ownerId, CoffeeEntityType.MAINTENANCE).map { record ->
        val json = record.payload
        MaintenanceEvent(
            id = record.id,
            equipmentId = json.optString("equipmentID"),
            type = json.optString("kind", "Maintenance"),
            performedAt = json.optLong("performedAt", record.updatedAt),
            usageCount = json.optNullableInt("usageCount"),
            notes = json.optNullableString("notes"),
        )
    }

    fun delete(ownerId: String = "", type: CoffeeEntityType, id: String) {
        tombstone(ownerId, type, id)
    }

    fun saveMaintenance(value: MaintenanceEvent, ownerId: String = "") {
        upsert(ownerId, CoffeeEntityType.MAINTENANCE, value.id, JSONObject()
            .put("id", value.id).put("equipmentID", value.equipmentId).put("kind", value.type)
            .put("performedAt", value.performedAt).put("usageCount", value.usageCount).put("notes", value.notes))
    }

    fun conflicts(ownerId: String = ""): List<CoffeeConflict> = query("owner_id=? AND conflict_payload IS NOT NULL", arrayOf(ownerId)).mapNotNull { record ->
        record.conflictPayload?.let { CoffeeConflict(ownerId, record.entityType, record.id, it, record.payload) }
    }

    fun resolveConflict(conflict: CoffeeConflict, keepLocal: Boolean) {
        val values = ContentValues().apply {
            put("payload", (if (keepLocal) conflict.localPayload else conflict.serverPayload).toString())
            put("dirty", if (keepLocal) 1 else 0)
            putNull("conflict_payload")
            if (keepLocal) put("updated_at", System.currentTimeMillis())
        }
        helper.writableDatabase.update(
            "coffee_records", values,
            "owner_id=? AND entity_type=? AND record_id=?",
            arrayOf(conflict.ownerId, conflict.entityType, conflict.id.lowercase())
        )
    }

    fun saveJournal(entry: BrewJournalEntry, ownerId: String = "") {
        val payload = JSONObject().put("id", entry.id).put("title", entry.title).put("method", entry.method)
            .put("coffeeGrams", entry.coffeeGrams).put("ratio", entry.ratio).put("waterGrams", entry.waterGrams)
            .put("brewTimeSeconds", entry.brewTimeSeconds).put("rating", entry.rating.coerceIn(1, 5))
            .put("notes", entry.notes).put("createdAt", entry.createdAt)
        upsert(ownerId, CoffeeEntityType.BREW_SESSION, entry.id, payload)
        upsert(ownerId, CoffeeEntityType.TASTE_FEEDBACK, entry.id, JSONObject().put("id", entry.id).put("sessionID", entry.id).put("rating", entry.rating.coerceIn(1, 5)).put("notes", entry.notes).put("createdAt", entry.createdAt))
        val sampleId = UUID.nameUUIDFromBytes("${entry.id}:final-weight".toByteArray()).toString()
        upsert(ownerId, CoffeeEntityType.SAMPLE, sampleId, JSONObject()
            .put("id", sampleId).put("sessionID", entry.id).put("kind", SampleType.WEIGHT.name.lowercase())
            .put("elapsedMilliseconds", entry.brewTimeSeconds.coerceAtLeast(0) * 1_000)
            .put("value", entry.waterGrams).put("unit", "g"))
    }

    fun replaceJournal(entries: List<BrewJournalEntry>, ownerId: String = "") {
        helper.writableDatabase.beginTransaction()
        try { entries.forEach { saveJournal(it, ownerId) }; helper.writableDatabase.setTransactionSuccessful() }
        finally { helper.writableDatabase.endTransaction() }
    }

    fun loadJournal(ownerId: String = ""): List<BrewJournalEntry> = records(ownerId, CoffeeEntityType.BREW_SESSION)
        .mapNotNull { record -> record.payload.takeIf { it.has("rating") }?.let { json ->
            BrewJournalEntry(json.optString("id", record.id), json.optString("title"), json.optString("method"), json.optInt("coffeeGrams"), json.optDouble("ratio"), json.optInt("waterGrams"), json.optInt("brewTimeSeconds"), json.optInt("rating", 4).coerceIn(1, 5), json.optString("notes"), json.optLong("createdAt", record.updatedAt))
        }}.sortedByDescending(BrewJournalEntry::createdAt).take(BrewJournalPolicy.MAX_ENTRIES)

    suspend fun synchronize(ownerId: String, bearerToken: String) = withContext(Dispatchers.IO) {
        claimLocalRecords(ownerId)
        val cursorPrefs = appContext.getSharedPreferences("talla_coffee_sync", Context.MODE_PRIVATE)
        val cursor = cursorPrefs.getString("cursor_$ownerId", "1970-01-01T00:00:00.000Z")!!
        val dirty = query("owner_id=? AND dirty=1", arrayOf(ownerId))
        val changes = JSONArray().also { array -> dirty.forEach { record -> array.put(recordJson(record)) } }
        val body = JSONObject().put("deviceID", deviceId(cursorPrefs)).put("cursor", cursor).put("changes", changes)
        val connection = (URL(BuildConfig.BACKEND_URL.trimEnd('/') + "/coffee-data/sync").openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"; doOutput = true; connectTimeout = 15_000; readTimeout = 20_000
            setRequestProperty("Content-Type", "application/json"); setRequestProperty("Authorization", "Bearer $bearerToken")
        }
        connection.outputStream.use { it.write(body.toString().toByteArray()) }
        if (connection.responseCode !in 200..299) throw IllegalStateException("Coffee sync failed (${connection.responseCode})")
        val response = JSONObject(connection.inputStream.bufferedReader().use { it.readText() })
        val conflicts = response.optJSONArray("conflicts") ?: JSONArray()
        val conflictKeys = (0 until conflicts.length()).map { conflicts.getJSONObject(it) }.map { "${it.optString("entityType")}:${it.optString("id").lowercase()}" }.toSet()
        val records = response.optJSONArray("records") ?: JSONArray()
        helper.writableDatabase.beginTransaction()
        try {
            for (index in 0 until records.length()) applyRemote(ownerId, records.getJSONObject(index), conflictKeys)
            helper.writableDatabase.setTransactionSuccessful()
        } finally { helper.writableDatabase.endTransaction() }
        cursorPrefs.edit().putString("cursor_$ownerId", response.optString("cursor", cursor)).apply()
    }

    private fun migrateLegacyJson() {
        if (legacy.getBoolean("coffee_data_migrated_v1", false)) return
        runCatching {
            val array = JSONArray(legacy.getString("brew_journal", "[]") ?: "[]")
            for (index in 0 until array.length()) {
                val json = array.getJSONObject(index); val id = json.optString("id", UUID.randomUUID().toString())
                upsert(type = CoffeeEntityType.BREW_SESSION, id = id, payload = json)
            }
            legacy.edit().putBoolean("coffee_data_migrated_v1", true).apply()
        }
    }

    private fun applyRemote(ownerId: String, json: JSONObject, conflictKeys: Set<String>) {
        val type = json.getString("entityType"); val id = json.getString("id").lowercase(); val existing = find(ownerId, type, id)
        val key = "$type:$id"; val values = ContentValues().apply {
            put("owner_id", ownerId); put("entity_type", type); put("record_id", id); put("payload", json.optJSONObject("payload")?.toString() ?: "{}")
            put("updated_at", parseTimestamp(json.optString("updatedAt"))); if (json.isNull("deletedAt")) putNull("deleted_at") else put("deleted_at", parseTimestamp(json.optString("deletedAt")))
            put("revision", json.optLong("revision")); put("dirty", 0)
            if (key in conflictKeys && existing != null) put("conflict_payload", existing.payload.toString()) else putNull("conflict_payload")
        }
        helper.writableDatabase.insertWithOnConflict("coffee_records", null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    private fun find(ownerId: String, type: String, id: String) = query("owner_id=? AND entity_type=? AND record_id=?", arrayOf(ownerId, type, id.lowercase())).firstOrNull()
    private fun query(where: String, args: Array<String>): List<CoffeeRecord> = buildList {
        helper.readableDatabase.query("coffee_records", null, where, args, null, null, "updated_at DESC").use { cursor ->
            while (cursor.moveToNext()) add(CoffeeRecord(cursor.getString(0), cursor.getString(1), cursor.getString(2), JSONObject(cursor.getString(3)), cursor.getLong(4), cursor.getLongOrNull(5), cursor.getLong(6), cursor.getInt(7) != 0, cursor.getStringOrNull(8)?.let(::JSONObject)))
        }
    }
    private fun recordJson(record: CoffeeRecord) = JSONObject().put("entityType", record.entityType).put("id", record.id).put("payload", record.payload).put("updatedAt", record.updatedAt).put("deletedAt", record.deletedAt ?: JSONObject.NULL).put("baseRevision", record.revision)
    private fun deviceId(preferences: android.content.SharedPreferences): String = preferences.getString("device_id", null) ?: UUID.randomUUID().toString().also { preferences.edit().putString("device_id", it).apply() }
    private fun parseTimestamp(value: String): Long = runCatching { java.time.Instant.parse(value).toEpochMilli() }.getOrDefault(System.currentTimeMillis())
    private fun JSONObject.optNullableString(name: String) = if (isNull(name)) null else optString(name).takeIf(String::isNotBlank)
    private fun JSONObject.optNullableLong(name: String) = if (isNull(name) || !has(name)) null else optLong(name)
    private fun JSONObject.optNullableInt(name: String) = if (isNull(name) || !has(name)) null else optInt(name)
    private fun android.database.Cursor.getLongOrNull(index: Int) = if (isNull(index)) null else getLong(index)
    private fun android.database.Cursor.getStringOrNull(index: Int) = if (isNull(index)) null else getString(index)

    private class Helper(context: Context) : SQLiteOpenHelper(context, "talla_coffee.db", null, 1) {
        override fun onCreate(db: SQLiteDatabase) { db.execSQL("CREATE TABLE coffee_records(owner_id TEXT NOT NULL DEFAULT '', entity_type TEXT NOT NULL, record_id TEXT NOT NULL, payload TEXT NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER, revision INTEGER NOT NULL DEFAULT 0, dirty INTEGER NOT NULL DEFAULT 1, conflict_payload TEXT, PRIMARY KEY(owner_id, entity_type, record_id))"); db.execSQL("CREATE INDEX coffee_records_dirty ON coffee_records(owner_id, dirty)") }
        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
    }
}
