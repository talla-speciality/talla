package com.talla.speciality.data

data class BrewJournalEntry(
    val id: String,
    val title: String,
    val method: String,
    val coffeeGrams: Int,
    val ratio: Double,
    val waterGrams: Int,
    val brewTimeSeconds: Int,
    val rating: Int,
    val notes: String,
    val createdAt: Long,
)

object BrewJournalPolicy {
    const val MAX_ENTRIES = 20

    fun add(entries: List<BrewJournalEntry>, entry: BrewJournalEntry): List<BrewJournalEntry> =
        (listOf(entry.copy(rating = entry.rating.coerceIn(1, 5))) + entries.filterNot { it.id == entry.id })
            .take(MAX_ENTRIES)

    fun remove(entries: List<BrewJournalEntry>, id: String): List<BrewJournalEntry> =
        entries.filterNot { it.id == id }
}
