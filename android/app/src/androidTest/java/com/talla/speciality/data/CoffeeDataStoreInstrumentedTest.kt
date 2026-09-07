package com.talla.speciality.data

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.json.JSONArray
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class CoffeeDataStoreInstrumentedTest {
    private lateinit var context: Context

    @Before fun resetStorage() {
        context = ApplicationProvider.getApplicationContext()
        context.deleteDatabase("talla_coffee.db")
        context.getSharedPreferences("talla_state", Context.MODE_PRIVATE).edit().clear().commit()
    }

    @After fun cleanStorage() {
        context.deleteDatabase("talla_coffee.db")
        context.getSharedPreferences("talla_state", Context.MODE_PRIVATE).edit().clear().commit()
    }

    @Test fun recipeEditsCreateImmutableVersions() {
        val store = CoffeeDataStore(context)
        val recipe = CoffeeRecipe(id = "550e8400-e29b-41d4-a716-446655440000", title = "V60", type = SessionType.FILTER)
        store.saveRecipe(recipe, RecipeVersion(recipeId = recipe.id, versionNumber = 0, coffeeGrams = 20.0, waterGrams = 320.0))
        store.saveRecipe(recipe, RecipeVersion(recipeId = recipe.id, versionNumber = 0, coffeeGrams = 20.0, waterGrams = 300.0))
        store.saveRecipe(recipe, RecipeVersion(recipeId = recipe.id, versionNumber = 0, coffeeGrams = 20.0, waterGrams = 300.0))

        val versions = store.recipeVersions(recipeId = recipe.id)
        assertEquals(listOf(1, 2), versions.map(RecipeVersion::versionNumber))
        assertEquals(300.0, versions.last().waterGrams ?: 0.0, 0.001)
        assertEquals(versions.last().id, store.recipes().single().currentVersionId)
    }

    @Test fun sessionPersistsEveryTelemetrySampleKind() {
        val store = CoffeeDataStore(context)
        val session = CoffeeBrewSession(id = "550e8400-e29b-41d4-a716-446655440001", type = SessionType.ESPRESSO)
        val samples = SampleType.entries.mapIndexed { index, type ->
            BrewSample(sessionId = session.id, type = type, elapsedMilliseconds = index * 250, value = index + 1.0, unit = type.name)
        }
        store.saveSession(session, samples, CoffeeTasteFeedback(sessionId = session.id, rating = 5))

        val persistedKinds = store.records(type = CoffeeEntityType.SAMPLE).map { it.payload.getString("kind") }.toSet()
        assertEquals(SampleType.entries.map { it.name.lowercase() }.toSet(), persistedKinds)
    }

    @Test fun legacyJsonMigrationCoversJournalRecipesEquipmentAndCalibrations() {
        val equipmentID = "550e8400-e29b-41d4-a716-446655440002"
        context.getSharedPreferences("talla_state", Context.MODE_PRIVATE).edit()
            .putString("brew_journal", JSONArray().put(JSONObject()
                .put("id", "550e8400-e29b-41d4-a716-446655440003").put("title", "Morning brew")
                .put("method", "V60").put("coffeeGrams", 20).put("ratio", 16).put("waterGrams", 320)
                .put("brewTimeSeconds", 180).put("rating", 4).put("notes", "Sweet")).toString())
            .putString("brew_recipes", JSONArray().put(JSONObject()
                .put("id", "550e8400-e29b-41d4-a716-446655440004").put("name", "Daily V60")
                .put("coffeeGrams", 20).put("waterGrams", 320).put("temperatureC", 94)).toString())
            .putString("coffee_equipment", JSONArray().put(JSONObject()
                .put("id", equipmentID).put("kind", "grinder").put("name", "Ode")).toString())
            .putString("coffee_calibrations", JSONArray().put(JSONObject()
                .put("id", "550e8400-e29b-41d4-a716-446655440005").put("equipmentID", equipmentID)
                .put("setting", "4.2").put("measuredValue", 4.2)).toString())
            .commit()

        val store = CoffeeDataStore(context)
        assertEquals(1, store.loadJournal().size)
        assertEquals(1, store.recipes().size)
        assertEquals(1, store.recipeVersions(recipeId = "550e8400-e29b-41d4-a716-446655440004").size)
        assertEquals(1, store.equipment().size)
        assertEquals(1, store.calibrations().size)
        assertTrue(context.getSharedPreferences("talla_state", Context.MODE_PRIVATE).getBoolean("coffee_data_migrated_v1", false))
    }
}
