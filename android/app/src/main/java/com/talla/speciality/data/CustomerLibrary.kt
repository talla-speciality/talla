package com.talla.speciality.data

data class CustomerLibrary(
    val favorites: Set<String> = emptySet(),
    val recentlyViewed: List<String> = emptyList(),
    val brewJournal: List<BrewJournalEntry> = emptyList(),
)
