package com.talla.speciality.data

import kotlin.math.roundToInt

data class BrewStep(
    val title: String,
    val startSeconds: Int,
    val targetWaterGrams: Int?,
    val instruction: String,
)

data class BrewRecipe(
    val brewer: String,
    val coffeeGrams: Int,
    val waterGrams: Int,
    val temperatureC: Int,
    val grind: String,
    val targetTime: String,
    val steps: List<BrewStep>,
)

object BrewRecipeEngine {
    fun generate(brewer: String, coffeeGrams: Int, ratio: Double): BrewRecipe {
        val dose = coffeeGrams.coerceIn(5, 100)
        val normalizedRatio = ratio.coerceIn(10.0, 20.0)
        val water = (dose * normalizedRatio).roundToInt()
        return when (brewer.lowercase()) {
            "espresso" -> espresso(dose)
            "cold brew" -> cold(dose, water)
            "aeropress" -> immersion("AeroPress", dose, water, 90, "Medium-fine", 120)
            "french press" -> immersion("French press", dose, water, 93, "Coarse", 240)
            "kalita" -> pourOver("Kalita", dose, water, 92, "Medium", flatBed = true)
            else -> pourOver("V60", dose, water, 93, "Medium-fine", flatBed = false)
        }
    }

    private fun pourOver(name: String, dose: Int, water: Int, temperature: Int, grind: String, flatBed: Boolean): BrewRecipe {
        val bloom = (dose * 2.5).roundToInt().coerceAtMost((water * .4).roundToInt())
        val first = bloom + ((water - bloom) * if (flatBed) .45 else .38).roundToInt()
        val second = first + ((water - bloom) * if (flatBed) .35 else .32).roundToInt()
        val steps = listOf(
            BrewStep("Prepare", 0, null, "Rinse the filter, discard the rinse water, and add $dose g coffee."),
            BrewStep("Bloom", 10, bloom, "Pour to $bloom g, wet every ground, and wait 40 seconds."),
            BrewStep("First pour", 50, first, "Pour steadily to $first g at 2–3 g/s."),
            BrewStep("Second pour", 85, second, "Continue with controlled circles to $second g."),
            BrewStep("Final pour", 120, water, "Finish at $water g and keep the bed level."),
            BrewStep("Drawdown", 175, water, "Let the bed drain and stop at slow drips."),
        )
        return BrewRecipe(name, dose, water, temperature, grind, "2:40–3:15", steps)
    }

    private fun immersion(name: String, dose: Int, water: Int, temperature: Int, grind: String, steep: Int): BrewRecipe = BrewRecipe(
        name, dose, water, temperature, grind,
        if (steep >= 240) "4:00–4:30" else "1:45–2:15",
        listOf(
            BrewStep("Add coffee", 0, null, "Add $dose g coffee to the brewer."),
            BrewStep("Add water", 5, water, "Pour $water g water and saturate all grounds."),
            BrewStep("Steep", 20, water, "Steep without disturbing the coffee."),
            BrewStep(if (name == "AeroPress") "Press" else "Plunge", steep, water, "Finish slowly and serve immediately."),
        ),
    )

    private fun espresso(dose: Int) = BrewRecipe(
        "Espresso", dose, dose * 2, 93, "Fine", "0:25–0:32",
        listOf(
            BrewStep("Prepare puck", 0, null, "Dose $dose g, distribute evenly, and tamp level."),
            BrewStep("Extract", 5, null, "Start the shot and watch for an even flow."),
            BrewStep("Stop", 30, dose * 2, "Stop near ${dose * 2} g yield, then taste before adjusting."),
        ),
    )

    private fun cold(dose: Int, water: Int) = BrewRecipe(
        "Cold brew", dose, water, 20, "Coarse", "12–16 hr",
        listOf(
            BrewStep("Add coffee", 0, null, "Add $dose g coarse coffee to a clean vessel."),
            BrewStep("Add water", 10, water, "Pour $water g room-temperature water and stir once."),
            BrewStep("Steep", 60, water, "Cover and steep for 12–16 hours."),
            BrewStep("Filter", 43_200, water, "Filter fully, refrigerate, and dilute to taste."),
        ),
    )
}
