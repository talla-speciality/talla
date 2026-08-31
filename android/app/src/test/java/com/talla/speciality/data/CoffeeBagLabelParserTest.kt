package com.talla.speciality.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CoffeeBagLabelParserTest {
    @Test
    fun parsesLabelledEnglishCoffeeBag() {
        val result = CoffeeBagLabelParser.parse(
            listOf(
                "Coffee: Gatta Anaerobic",
                "Roasted by Talla Speciality",
                "Origin: Ethiopia",
                "Region: Sidama",
                "Altitude: 1,950–2,100 masl",
                "Variety: 74110",
                "Process: Anaerobic Natural",
                "Tasting notes: Strawberry, cacao, jasmine",
            )
        )

        assertEquals("Gatta Anaerobic", result.name)
        assertEquals("Talla Speciality", result.roaster)
        assertEquals("Ethiopia", result.origin)
        assertEquals("Sidama", result.region)
        assertEquals("1,950–2,100 masl", result.altitude)
        assertEquals("Anaerobic Natural", result.process)
        assertEquals("Strawberry, cacao, jasmine", result.tastingNotes)
        assertEquals(8, result.populatedFieldCount)
    }

    @Test
    fun infersCountryProcessAltitudeAndHeaderName() {
        val result = CoffeeBagLabelParser.parse(
            listOf("La Esperanza", "Colombia", "Natural process", "1800 m", "Peach and caramel")
        )

        assertEquals("La Esperanza", result.name)
        assertEquals("Colombia", result.origin)
        assertEquals("Natural", result.process)
        assertEquals("1800 m", result.altitude)
    }

    @Test
    fun parsesArabicLabelsWhenRecognizedTextIsAvailable() {
        val result = CoffeeBagLabelParser.parse(
            listOf("اسم القهوة: شمس", "المنشأ: اليمن", "المعالجة: طبيعية", "الإيحاءات: شوكولاتة وفواكه")
        )

        assertEquals("شمس", result.name)
        assertEquals("اليمن", result.origin)
        assertEquals("طبيعية", result.process)
        assertEquals("شوكولاتة وفواكه", result.tastingNotes)
        assertTrue(result.journalNotes().contains("اليمن"))
    }
}
