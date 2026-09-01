function normalizeCustomerProductIDs(values, limit = 200) {
    return [...new Set((Array.isArray(values) ? values : [])
        .map((value) => String(value || "").trim())
        .filter((value) => value && value.length <= 300))]
        .slice(0, limit);
}

function normalizeBrewJournalEntry(input) {
    const id = String(input?.id || "").trim();
    const title = String(input?.title || "").trim().slice(0, 160);
    const method = String(input?.method || "").trim().slice(0, 120);
    const notes = String(input?.notes || "").trim().slice(0, 4000);
    const submittedCreatedAt = input?.createdAt ? new Date(input.createdAt) : null;
    const optionalNumber = (value, minimum, maximum) => {
        if (value === null || value === undefined || value === "") return null;
        const number = Number(value);
        return Number.isFinite(number) && number >= minimum && number <= maximum ? number : null;
    };

    if (!id || id.length > 120 || !title || !method) return null;

    return {
        id,
        title,
        method,
        coffeeGrams: optionalNumber(input.coffeeGrams, 0, 10_000),
        ratio: optionalNumber(input.ratio, 0, 1_000),
        waterGrams: optionalNumber(input.waterGrams, 0, 100_000),
        brewTimeSeconds: optionalNumber(input.brewTimeSeconds, 0, 86_400),
        rating: Math.max(1, Math.min(5, Math.round(Number(input.rating) || 1))),
        notes,
        createdAt: submittedCreatedAt && Number.isFinite(submittedCreatedAt.getTime())
            ? submittedCreatedAt.toISOString()
            : new Date().toISOString()
    };
}

function emptyCustomerLibrary() {
    return { favorites: [], recentlyViewed: [], brewJournal: [] };
}

function mergeCustomerLibraryRecords(current, input) {
    const base = current || emptyCustomerLibrary();
    const favorites = normalizeCustomerProductIDs([
        ...(Array.isArray(input?.favorites) ? input.favorites : []),
        ...(Array.isArray(base.favorites) ? base.favorites : [])
    ]);
    const recentlyViewed = normalizeCustomerProductIDs([
        ...(Array.isArray(input?.recentlyViewed) ? input.recentlyViewed : []),
        ...(Array.isArray(base.recentlyViewed) ? base.recentlyViewed : [])
    ], 20);
    const journalByID = new Map();
    [...(Array.isArray(input?.brewJournal) ? input.brewJournal : []), ...(Array.isArray(base.brewJournal) ? base.brewJournal : [])]
        .map(normalizeBrewJournalEntry)
        .filter(Boolean)
        .forEach((entry) => {
            const existing = journalByID.get(entry.id);
            if (!existing || new Date(entry.createdAt).getTime() >= new Date(existing.createdAt).getTime()) {
                journalByID.set(entry.id, entry);
            }
        });
    const brewJournal = [...journalByID.values()]
        .sort((first, second) => new Date(second.createdAt).getTime() - new Date(first.createdAt).getTime())
        .slice(0, 20);
    return { favorites, recentlyViewed, brewJournal };
}

module.exports = {
    emptyCustomerLibrary,
    mergeCustomerLibraryRecords,
    normalizeBrewJournalEntry,
    normalizeCustomerProductIDs
};
