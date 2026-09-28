const espressoMachineCatalog = [
    { id: "decent-de1", name: "Decent DE1 / DE1XL", manufacturer: "Decent Espresso", supportLevel: "officialCompanionApp", accessMode: "readOnly", streams: ["pressure", "flow", "temperature"], notes: "Read-only telemetry through a local Decaid gateway." },
    { id: "linea-mini", name: "La Marzocco Linea Mini / Mini R", manufacturer: "La Marzocco", supportLevel: "officialCompanionApp", accessMode: "officialControl", streams: ["temperature"] },
    { id: "home-connect-coffee", name: "Home Connect coffee machines", manufacturer: "BSH Home Connect", supportLevel: "officialCloudAPI", accessMode: "officialControl", streams: ["temperature"] },
    { id: "jura-smart-connect", name: "JURA Smart Connect / Wi-Fi Connect", manufacturer: "JURA", supportLevel: "officialCompanionApp", accessMode: "officialControl", streams: ["temperature"] },
    { id: "victoria-arduino-e1-prima", name: "Victoria Arduino E1 Prima", manufacturer: "Victoria Arduino", supportLevel: "officialCompanionApp", accessMode: "officialControl", streams: ["temperature"] },
    { id: "acaia-lunar-pearl", name: "Acaia Lunar / Pearl", manufacturer: "Acaia", supportLevel: "officialSDK", accessMode: "readOnly", streams: ["flow"] },
    { id: "bookoo-mini", name: "BOOKOO Mini Scale", manufacturer: "BOOKOO", supportLevel: "officialSDK", accessMode: "readOnly", streams: ["flow"] },
    { id: "goat-story-gina", name: "GOAT STORY GINA", manufacturer: "GOAT STORY", supportLevel: "officialSDK", accessMode: "readOnly", streams: ["flow"] },
    { id: "hiroia-jimmy", name: "HIROIA JIMMY", manufacturer: "HIROIA", supportLevel: "officialSDK", accessMode: "readOnly", streams: ["flow"] },
    { id: "mantabrew-scale", name: "MANTABREW Scale", manufacturer: "MANTABREW", supportLevel: "officialSDK", accessMode: "readOnly", streams: ["flow"] },
    { id: "timemore-dot", name: "TIMEMORE Black Mirror / Dot", manufacturer: "TIMEMORE", supportLevel: "officialSDK", accessMode: "readOnly", streams: ["flow"] },
    { id: "rocket-profitec-ecm", name: "Rocket / Profitec / ECM", manufacturer: "Multiple manufacturers", supportLevel: "manualOnly", accessMode: "readOnly", streams: [] },
    { id: "rancilio-nuova-simonelli", name: "Rancilio / Nuova Simonelli", manufacturer: "Multiple manufacturers", supportLevel: "manualOnly", accessMode: "readOnly", streams: [] }
];

module.exports = { espressoMachineCatalog };
