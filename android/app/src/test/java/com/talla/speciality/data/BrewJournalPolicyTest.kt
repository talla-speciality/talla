package com.talla.speciality.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class BrewJournalPolicyTest {
    @Test
    fun newestEntryComesFirstAndHistoryIsLimited() {
        val existing = (1..BrewJournalPolicy.MAX_ENTRIES).map(::entry)
        val newest = entry(99).copy(rating = 8)

        val result = BrewJournalPolicy.add(existing, newest)

        assertEquals(BrewJournalPolicy.MAX_ENTRIES, result.size)
        assertEquals("99", result.first().id)
        assertEquals(5, result.first().rating)
        assertFalse(result.any { it.id == BrewJournalPolicy.MAX_ENTRIES.toString() })
    }

    @Test
    fun addingExistingEntryReplacesItWithoutDuplicates() {
        val original = entry(1)
        val updated = original.copy(title = "Updated")

        val result = BrewJournalPolicy.add(listOf(original, entry(2)), updated)

        assertEquals(listOf("1", "2"), result.map { it.id })
        assertEquals("Updated", result.first().title)
    }

    @Test
    fun removeDeletesOnlyRequestedEntry() {
        val result = BrewJournalPolicy.remove(listOf(entry(1), entry(2)), "1")

        assertEquals(listOf("2"), result.map { it.id })
    }

    private fun entry(index: Int) = BrewJournalEntry(
        id = index.toString(), title = "Brew $index", method = "V60", coffeeGrams = 20,
        ratio = 15.0, waterGrams = 300, brewTimeSeconds = 180, rating = 4,
        notes = "Sweet", createdAt = index.toLong(),
    )
}
