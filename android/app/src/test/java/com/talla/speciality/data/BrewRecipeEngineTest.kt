package com.talla.speciality.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BrewRecipeEngineTest {
    @Test fun v60TargetsRequestedRatio() {
        val recipe = BrewRecipeEngine.generate("V60", 20, 15.0)
        assertEquals(300, recipe.waterGrams)
        assertEquals(300, recipe.steps.last().targetWaterGrams)
    }

    @Test fun espressoUsesTwoToOneYield() {
        val recipe = BrewRecipeEngine.generate("Espresso", 18, 15.0)
        assertEquals(36, recipe.waterGrams)
        assertEquals("Fine", recipe.grind)
    }

    @Test fun inputsAreClampedToSafeRecipeRange() {
        val recipe = BrewRecipeEngine.generate("V60", 1, 100.0)
        assertEquals(5, recipe.coffeeGrams)
        assertEquals(100, recipe.waterGrams)
        assertTrue(recipe.steps.isNotEmpty())
    }
}
