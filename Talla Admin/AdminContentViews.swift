import SwiftUI

enum AdminContentArea: String, CaseIterable, Identifiable {
    case home = "App Home", controls = "Live Controls", events = "Seasonal Events", passport = "Coffee Passport", espresso = "Espresso", education = "Coffee Education", gulfCoffeeMap = "Gulf Coffee Map"
    var id: Self { self }
    var endpoint: String {
        switch self {
        case .home: "/admin/api/home/signature-roasts"
        case .controls: "/admin/api/app-settings"
        case .events: "/admin/api/events"
        case .passport: "/admin/api/passport-settings"
        case .espresso: "/admin/api/app-settings"
        case .education: "/admin/api/education-content"
        case .gulfCoffeeMap: "/admin/api/gulf-coffee-map"
        }
    }
    var icon: String {
        switch self { case .home: "house.fill"; case .controls: "slider.horizontal.3"; case .events: "sparkles"; case .passport: "globe.europe.africa.fill"; case .espresso: "dial.medium"; case .education: "book.closed.fill"; case .gulfCoffeeMap: "map.fill" }
    }
    var groups: [AdminFieldGroup] {
        switch self {
        case .home: return [
            .init("English hero", [
                .init("heroEyebrow", "Eyebrow"),
                .init("heroTitle", "Title"),
                .init("heroSubtitle", "Subtitle", .multiline),
                .init("heroBadge", "Badge"),
                .init("primaryButtonTitle", "Primary button"),
                .init("secondaryButtonTitle", "Secondary button")
            ]),
            .init("Arabic hero", [
                .init("heroEyebrowAR", "Eyebrow"),
                .init("heroTitleAR", "Title"),
                .init("heroSubtitleAR", "Subtitle", .multiline),
                .init("heroBadgeAR", "Badge"),
                .init("primaryButtonTitleAR", "Primary button"),
                .init("secondaryButtonTitleAR", "Secondary button")
            ]),
            .init("Featured products", [.init("signatureRoastProductIDs", "Signature roasts", .products(4, false)), .init("quickDrinkProductIDs", "Talla Express drinks", .products(6, true)), .init("funPickProductID", "Today's fun pick", .product)])
        ]
        case .passport: return [.init("Completion reward", [.init("completionRewardTitle", "Reward title"), .init("completionRewardDetail", "Reward detail", .multiline)])]
        case .events: return []
        case .controls: return Self.controlGroups
        case .espresso: return [.init("Default targets", [.init("espresso.defaultDoseGrams", "Default dose (g)", .number), .init("espresso.defaultYieldGrams", "Default yield (g)", .number), .init("espresso.defaultTemperatureC", "Default temperature (°C)", .integer), .init("espresso.targetTimeMinSeconds", "Minimum target time (s)", .integer), .init("espresso.targetTimeMaxSeconds", "Maximum target time (s)", .integer), .init("espresso.targetFirstDripSeconds", "Target first drip (s)", .integer)]), .init("Guidance", [.init("espresso.positiveRatingThreshold", "Positive rating threshold", .integer), .init("espresso.recommendationStep", "Grind recommendation step", .number), .init("espresso.targetYieldAlertsEnabled", "Target-yield alerts enabled", .toggle), .init("espresso.watchControlsEnabled", "Watch controls enabled", .toggle)])]
        case .education: return []
        case .gulfCoffeeMap: return []
        }
    }
}

struct AdminArraySpec: Identifiable {
    let path: String
    let title: String
    let groups: [AdminFieldGroup]
    let blank: AdminValue
    var id: String { path }
}

struct AdminSeasonalEventPreset: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbols: [String]
    let accentHex: String
    let secondaryHex: String

    static let all: [AdminSeasonalEventPreset] = [
        .init(id: "ramadan", title: "Ramadan", subtitle: "Moon, stars, and warm night tones", symbols: ["moon.stars.fill", "moon.fill", "sparkles", "star.fill"], accentHex: "#D3AF62", secondaryHex: "#25352C"),
        .init(id: "eid", title: "Eid", subtitle: "Gifts, stars, and celebration", symbols: ["moon.stars.fill", "gift.fill", "sparkles", "star.fill", "bag.fill"], accentHex: "#D6A667", secondaryHex: "#26372D"),
        .init(id: "christmas", title: "Christmas", subtitle: "Snow, gifts, and festive sparkle", symbols: ["snowflake", "gift.fill", "sparkles", "star.fill", "heart.fill"], accentHex: "#D8C7A0", secondaryHex: "#365342"),
        .init(id: "winter", title: "Winter", subtitle: "Warm drinks, chocolate, and coffee for cooler days", symbols: ["snowflake", "mug.fill", "sparkles", "flame.fill", "heart.fill"], accentHex: "#C8965A", secondaryHex: "#2A1D14"),
        .init(id: "halloween", title: "Halloween", subtitle: "Moonlight, fire, and playful magic", symbols: ["moon.fill", "flame.fill", "sparkles", "wand.and.stars", "face.smiling.fill"], accentHex: "#F08A3C", secondaryHex: "#261A2B"),
        .init(id: "general", title: "General celebration", subtitle: "A flexible festive starting point", symbols: ["sparkles", "party.popper.fill", "gift.fill", "star.fill", "cup.and.saucer.fill"], accentHex: "#C8965A", secondaryHex: "#2A1D14")
    ]

    func makeEvent() -> AdminValue {
        .object([
            "id": .string("\(id)-\(UUID().uuidString.lowercased())"), "presetID": .string(id), "name": .string(title), "enabled": .bool(false), "priority": .number(0),
            "titleEN": .string(title), "titleAR": .string(id == "winter" ? "الشتاء" : ""), "subtitleEN": .string(""), "subtitleAR": .string(""), "badgeEN": .string("Seasonal"), "badgeAR": .string(id == "winter" ? "موسمي" : ""),
            "ctaEN": .string("Explore collection"), "ctaAR": .string(id == "winter" ? "اكتشف المجموعة" : ""), "categoryTitleEN": .string(title), "categoryTitleAR": .string(id == "winter" ? "الشتاء" : ""), "categorySubtitleEN": .string(""), "categorySubtitleAR": .string(""),
            "startAt": .null, "endAt": .null, "imageURL": .string(""), "symbol": .string(symbols[0]), "symbols": .array(symbols.map(AdminValue.string)),
            "accentHex": .string(accentHex), "secondaryHex": .string(secondaryHex), "productIDs": .array([])
        ])
    }
}

extension AdminContentArea {
    var arrays: [AdminArraySpec] {
        switch self {
        case .home: return []
        case .passport: return [
            .init(path: "origins", title: "Origins", groups: [.init("Origin", [
            .init("id", "Origin identifier", required: true), .init("title", "Name", required: true), .init("emoji", "Flag or emoji"), .init("keywords", "Matching keywords", .words), .init("rewardLabel", "Reward label")
        ])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "title": .string("New origin"), "keywords": .array([])])),
            .init(path: "brewGuides", title: "Brew guides", groups: [.init("Guide", [
                .init("id", "Guide identifier", required: true),
                .init("productKeywords", "Product matching keywords", .words),
                .init("origin", "Origin", required: true),
                .init("profile", "Cup profile", .multiline),
                .init("notes", "Tasting notes", .multiline),
                .init("method", "Method", required: true),
                .init("dose", "Dose"), .init("water", "Water"),
                .init("temperature", "Temperature"), .init("grind", "Grind"), .init("brewTime", "Target brew time")
            ])], blank: .object([
                "id": .string(UUID().uuidString.lowercased()), "productKeywords": .array([]), "origin": .string("New origin"),
                "profile": .string(""), "notes": .string(""), "method": .string("V60 / pour-over"), "dose": .string("15 g coffee"),
                "water": .string("250 g water"), "temperature": .string("93°C"), "grind": .string("Medium-fine"), "brewTime": .string("2:45–3:15")
            ]))
        ]
        case .events: return [.init(path: "events", title: "Events", groups: [
            .init("Event", [.init("id", "Event identifier", required: true), .init("name", "Name", required: true), .init("enabled", "Enabled", .toggle), .init("priority", "Display priority", .integer)]),
            .init("English content", [.init("titleEN", "Title", required: true), .init("subtitleEN", "Subtitle", .multiline), .init("badgeEN", "Badge"), .init("ctaEN", "Button label"), .init("categoryTitleEN", "Category title"), .init("categorySubtitleEN", "Category subtitle", .multiline)]),
            .init("Arabic content", [.init("titleAR", "Title"), .init("subtitleAR", "Subtitle", .multiline), .init("badgeAR", "Badge"), .init("ctaAR", "Button label"), .init("categoryTitleAR", "Category title"), .init("categorySubtitleAR", "Category subtitle", .multiline)]),
            .init("Schedule", [.init("startAt", "Start date", .date), .init("endAt", "End date", .date)]),
            .init("Appearance", [.init("presetID", "Preset"), .init("imageURL", "Image URL"), .init("symbol", "Primary symbol name"), .init("symbols", "More symbols", .words), .init("accentHex", "Accent color (hex)"), .init("secondaryHex", "Secondary color (hex)")]),
            .init("Collection", [.init("productIDs", "Products", .products(40, false))])
        ], blank: .object(["id": .string(UUID().uuidString.lowercased()), "name": .string("New event"), "enabled": .bool(false), "priority": .number(0), "titleEN": .string("New event"), "productIDs": .array([]), "symbol": .string("sparkles"), "symbols": .array([.string("sparkles")]), "accentHex": .string("#C8965A"), "secondaryHex": .string("#2A1D14")]))]
        case .controls: return [
            .init(path: "coffeeClub.plans", title: "Subscription plans", groups: [
                .init("Plan", [
                    .init("id", "Plan identifier", required: true),
                    .init("enabled", "Enabled", .toggle),
                    .init("group", "Section", .choice(["home", "day"])),
                    .init("icon", "Icon name"),
                    .init("titleEN", "English title", required: true),
                    .init("titleAR", "Arabic title"),
                    .init("detailEN", "English detail", .multiline),
                    .init("detailAR", "Arabic detail", .multiline),
                    .init("categoryKey", "Shop category", .choice(["coffee-beans", "arabic-coffee-beans", "drip-bags", "gifts", "coffee-equipment"])),
                    .init("productIDs", "Plan products", .products(100, false))
                ])
            ], blank: .object(["id": .string("new-plan"), "enabled": .bool(false), "group": .string("home"), "icon": .string("shippingbox"), "titleEN": .string("New subscription plan"), "categoryKey": .string("coffee-beans"), "productIDs": .array([])])),
            .init(path: "fulfillment.khaleejiTiers", title: "GCC shipping tiers", groups: [.init("Shipping tier", [.init("maximumWeightGrams", "Maximum weight (grams)", .integer), .init("rate", "Rate (BHD)", .number)])], blank: .object(["maximumWeightGrams": .number(500), "rate": .number(5.5)])),
            .init(path: "fulfillment.locations", title: "Locations and pickup slots", groups: [.init("Location", [
                .init("id", "Location identifier", required: true), .init("nameEN", "English name", required: true), .init("nameAR", "Arabic name", required: true),
                .init("addressEN", "English address", required: true), .init("addressAR", "Arabic address", required: true), .init("mapsURL", "Map link"), .init("enabled", "Enabled", .toggle),
                .init("openingHoursEN", "English opening hours", .multiline), .init("openingHoursAR", "Arabic opening hours", .multiline),
                .init("temporaryClosureEN", "English temporary closure", .multiline), .init("temporaryClosureAR", "Arabic temporary closure", .multiline),
                .init("pickupSlots", "Pickup slots JSON", .json)
            ])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "nameEN": .string("New location"), "enabled": .bool(true), "pickupSlots": .array([])])),
            .init(path: "loyalty.rewards", title: "Loyalty rewards", groups: [.init("Reward", [.init("id", "Reward identifier", required: true), .init("enabled", "Enabled", .toggle), .init("points", "Points required", .integer), .init("reward", "Reward type", .choice(["free drink", "pastry pairing", "coffee bag credit"]), required: true), .init("titleEN", "English title", required: true), .init("titleAR", "Arabic title"), .init("detailEN", "English detail", .multiline), .init("detailAR", "Arabic detail", .multiline)])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "enabled": .bool(true), "points": .number(50), "reward": .string("free drink"), "titleEN": .string("New reward")]))
        ]
        case .espresso: return [
            .init(path: "machines", title: "Machines", groups: [.init("Machine", [.init("id", "Identifier", required: true), .init("name", "Name", required: true), .init("enabled", "Enabled", .toggle)])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "name": .string("New machine"), "enabled": .bool(true)])),
            .init(path: "grinders", title: "Grinders", groups: [.init("Grinder", [.init("id", "Identifier", required: true), .init("name", "Name", required: true), .init("burrOptions", "Burr options", .words), .init("enabled", "Enabled", .toggle)])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "name": .string("New grinder"), "burrOptions": .array([]), "enabled": .bool(true)])),
            .init(path: "baskets", title: "Baskets", groups: [.init("Basket", [.init("id", "Identifier", required: true), .init("name", "Name", required: true), .init("doseMinGrams", "Minimum dose (g)", .number), .init("doseMaxGrams", "Maximum dose (g)", .number), .init("enabled", "Enabled", .toggle)])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "name": .string("New basket"), "doseMinGrams": .number(17), "doseMaxGrams": .number(19), "enabled": .bool(true)])),
            .init(path: "portafilters", title: "Portafilters", groups: [.init("Portafilter", [.init("id", "Identifier", required: true), .init("name", "Name", required: true), .init("enabled", "Enabled", .toggle)])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "name": .string("New portafilter"), "enabled": .bool(true)]))
        ]
        case .education: return [.init(path: "questions", title: "Quiz questions", groups: [.init("Question", [
            .init("id", "Question identifier", required: true),
            .init("prompt", "Question", .multiline, required: true),
            .init("options", "Answer options", .words, required: true),
            .init("correctAnswer", "Correct answer", required: true),
            .init("explanation", "Explanation", .multiline)
        ])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "prompt": .string("New coffee question"), "options": .array([.string("Option A"), .string("Option B")]), "correctAnswer": .string("Option A"), "explanation": .string("Explain why this is correct.")]))]
        case .gulfCoffeeMap: return [.init(path: "directory", title: "Directory listings", groups: [
            .init("Identity", [
                .init("id", "Listing identifier", required: true),
                .init("name", "Name", required: true),
                .init("city", "City or Online", required: true),
                .init("country", "Country or GCC", required: true),
                .init("neighborhood", "Neighborhood / listing type"),
                .init("categories", "Categories", .words),
                .init("tags", "Tags", .words)
            ]),
            .init("Location", [
                .init("websiteURL", "Website or map link"),
                .init("sourceURL", "Verification source URL"),
                .init("logoURL", "Logo image URL (optional)"),
                .init("address", "Address", .multiline),
                .init("phone", "Phone"),
                .init("hours", "Opening hours", .multiline)
            ]),
            .init("Trust and freshness", [
                .init("verificationStatus", "Verification status", .choice(["unverified", "link-provided", "link-verified", "manually-verified", "verified"])),
                .init("verifiedBy", "Verified by"),
                .init("verifiedAt", "Verified at (ISO date)"),
                .init("lastCheckedAt", "Last checked at (ISO date)")
            ]),
            .init("Bilingual profile", [
                .init("description", "English and Arabic description JSON", .json),
                .init("tastingNotes", "English and Arabic tasting notes JSON", .json)
            ]),
            .init("Coffee knowledge", [
                .init("offerings", "Drinks, beans, and workshops JSON", .json),
                .init("events", "Cuppings and local events JSON", .json)
            ])
        ], blank: .object(["id": .string(UUID().uuidString.lowercased()), "name": .string("New listing"), "city": .string(""), "country": .string(""), "categories": .array([]), "tags": .array([]), "offerings": .array([]), "events": .array([]), "description": .object(["en": .string(""), "ar": .string("")]), "tastingNotes": .object(["en": .string(""), "ar": .string("")]), "verificationStatus": .string("unverified"), "logoURL": .string("")]))]
        }
}

}

struct AdminContentView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.dismiss) private var dismiss
    let area: AdminContentArea
    @State private var document: AdminValue = .object([:])
    @State private var baseline: AdminValue?
    @State private var products: [AdminValue] = []
    @State private var busy = false
    @State private var error: String?
    @State private var message: String?
    @State private var publish = false
    @State private var discard = false
    @State private var leaving = false
    private var dirty: Bool { baseline != nil && baseline != document }
    var body: some View {
        Form {
            if baseline == nil {
                Section {
                    if busy { ProgressView("Loading \(area.rawValue.lowercased())…") }
                    else { Button("Load \(area.rawValue)") { Task { await load() } } }
                }
            } else {
                Section {
                    Label(dirty ? "Unpublished changes" : "Published settings", systemImage: dirty ? "pencil.circle" : "checkmark.circle")
                    Text("Edit the sections below, then tap Publish to update the customer app.").font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(area.groups) { group in
                    Section(group.title) { ForEach(group.fields) { AdminFieldRow(field: $0, document: $document, products: products) } }
                }
                ForEach(area.arrays) { spec in
                    Section {
                        NavigationLink {
                            AdminArrayEditor(spec: spec, rows: Binding(get: { document.at(spec.path).array }, set: { document.set(spec.path, .array($0)) }), products: products)
                        } label: { LabeledContent(spec.title, value: "\(document.at(spec.path).array.count)") }
                    }
                }
            }
        }
        .adminBackground().navigationTitle(area.rawValue).navigationBarTitleDisplayMode(.inline)
        .disabled(busy)
        .navigationBarBackButtonHidden(dirty || busy)
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: message) }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if dirty || busy { Button { leaving = true } label: { Label("Back", systemImage: "chevron.left") }.disabled(busy) }
            }
            ToolbarItem(placement: .topBarTrailing) { Button { if dirty { discard = true } else { Task { await load() } } } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Reload settings").disabled(busy) }
            ToolbarItem(placement: .topBarTrailing) { Button(busy ? "Working…" : "Publish") { publish = true }.disabled(busy || !dirty) }
        }
        .task { if baseline == nil { await load() } }
        .confirmationDialog("Publish \(area.rawValue)?", isPresented: $publish, titleVisibility: .visible) {
            Button("Publish Changes") { Task { await save() } }
        } message: { Text("These changes will be visible to customers when their app refreshes.") }
        .confirmationDialog("Leave without publishing?", isPresented: $leaving, titleVisibility: .visible) {
            Button("Discard Changes", role: .destructive) { dismiss() }
        }
        .confirmationDialog("Discard unpublished changes?", isPresented: $discard, titleVisibility: .visible) {
            Button("Discard and Reload", role: .destructive) { Task { await load() } }
        }
    }
    @MainActor private func load() async {
        busy = true; error = nil; message = nil
        defer { busy = false }
        do { document = try await session.api.document(area.endpoint); baseline = document }
        catch { handle(error); return }
        if area == .home || area == .controls || area == .events {
            do { products = try await session.api.document("/admin/api/products?limit=250")["products"].array }
            catch { self.error = "Settings loaded, but products could not load: \(error.localizedDescription)" }
        }
    }
    @MainActor private func save() async {
        busy = true; error = nil; message = nil
        defer { busy = false }
        do {
            var body = try adminValidated(document, fields: area.groups.flatMap(\.fields))
            for spec in area.arrays {
                let rows = try document.at(spec.path).array.map { try adminValidated($0, fields: spec.groups.flatMap(\.fields)) }
                let ids = rows.map { $0["id"].text }.filter { !$0.isEmpty }
                guard Set(ids).count == ids.count else { throw AdminAPIError.server("Each \(spec.title.lowercased()) identifier must be unique.") }
                body.set(spec.path, .array(rows))
            }
            if area == .controls {
                guard body.at("fulfillment.deliveryEnabled").flag || body.at("fulfillment.pickupEnabled").flag else { throw AdminAPIError.server("Keep delivery or pickup enabled.") }
                guard body.at("loyalty.goldThreshold").number > body.at("loyalty.silverThreshold").number else { throw AdminAPIError.server("Gold must have a higher points threshold than Silver.") }
                guard body.at("loyalty.reserveThreshold").number > body.at("loyalty.goldThreshold").number else { throw AdminAPIError.server("Reserve must have a higher points threshold than Gold.") }
                guard !body.at("fulfillment.khaleejiTiers").array.isEmpty, !body.at("loyalty.rewards").array.isEmpty else { throw AdminAPIError.server("Keep at least one shipping tier and loyalty reward.") }
                guard (2...12).contains(Int(body.at("coffeeClub.shipmentCount").number)) else { throw AdminAPIError.server("Coffee Club shipments must be between 2 and 12.") }
                guard (1...12).contains(Int(body.at("coffeeClub.intervalWeeks").number)) else { throw AdminAPIError.server("Coffee Club interval must be between 1 and 12 weeks.") }
                guard (0...30).contains(Int(body.at("coffeeClub.discountPercent").number)) else { throw AdminAPIError.server("Coffee Club discount must be between 0% and 30%.") }
            }
            if area == .controls {
                let tiers = body.at("fulfillment.khaleejiTiers").array
                let weights = tiers.map { $0["maximumWeightGrams"].number }
                guard Set(weights).count == weights.count, weights == weights.sorted() else { throw AdminAPIError.server("Shipping tiers must have unique, increasing weight limits.") }
                if body.at("announcement.enabled").flag && (body.at("announcement.title").text.isEmpty || body.at("announcement.message").text.isEmpty) { throw AdminAPIError.server("Add an announcement title and message before enabling it.") }
                for reward in body.at("loyalty.rewards").array where reward["points"].number <= 0 { throw AdminAPIError.server("Loyalty reward points must be greater than zero.") }
            }
            if area == .events {
                for event in body["events"].array {
                    if let start = adminDate(event["startAt"].text), let end = adminDate(event["endAt"].text), end <= start { throw AdminAPIError.server("\(event.title): end date must be after the start date.") }
                }
            }
            // These APIs replace a whole settings document. Refuse to overwrite a newer admin's edits.
            let current = try await session.api.document(area.endpoint)
            guard current == baseline else { throw AdminAPIError.server("Another admin changed these settings. Reload and review the latest version before publishing.") }
            document = try await session.api.document(area.endpoint, body: body)
            baseline = document; message = "\(area.rawValue) published."
        } catch { handle(error) }
    }
    @MainActor private func handle(_ error: Error) {
        self.error = error.localizedDescription
        if case AdminAPIError.unauthorized = error { session.handle(error) }
    }
}

struct AdminArrayEditor: View {
    let spec: AdminArraySpec
    @Binding var rows: [AdminValue]
    let products: [AdminValue]
    @State private var search = ""
    @State private var filter = "All"
    var body: some View {
        List {
            Section { Text("Changes are kept in this draft. Return to the previous screen and tap Publish to make them live.").font(.footnote).foregroundStyle(.secondary) }
            if spec.path == "events" {
                Picker("Event status", selection: $filter) { ForEach(["All", "Live", "Scheduled", "Ended", "Off"], id: \.self) { Text($0) } }
            }
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]
                if (search.isEmpty || row.title.localizedCaseInsensitiveContains(search)) && (filter == "All" || eventStatus(row) == filter) {
                    NavigationLink {
                        Form {
                            ForEach(spec.groups) { group in
                                Section(group.title) { ForEach(group.fields) { AdminFieldRow(field: $0, document: $rows[index], products: products) } }
                            }
                        }.adminBackground().navigationTitle(row.title).navigationBarTitleDisplayMode(.inline)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(row.title == "Details" ? "Tier \(index + 1)" : row.title)
                            if spec.path == "events" { Text(eventStatus(row)).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    .swipeActions {
                        Button("Remove", role: .destructive) { rows.remove(at: index) }
                        if spec.path == "events" {
                            Button("Duplicate") { rows.append(row.merging(["id": .string(UUID().uuidString.lowercased()), "name": .string(row.title + " Copy"), "enabled": .bool(false)])) }.tint(TallaAdminStyle.caramel)
                        }
                    }
                }
            }
            if spec.path == "events" {
                Section("Start from a preset") {
                    ForEach(AdminSeasonalEventPreset.all) { preset in
                        Button {
                            rows.append(preset.makeEvent())
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: preset.symbols[0]).foregroundStyle(TallaAdminStyle.caramel).frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(preset.title)
                                    Text(preset.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill").foregroundStyle(TallaAdminStyle.caramel)
                            }
                        }
                    }
                }
            }
            Button { var entry = spec.blank; if !entry["id"].text.isEmpty { entry["id"] = .string(UUID().uuidString.lowercased()) }; rows.append(entry) } label: { Label("Add \(spec.title == "Events" ? "event" : "entry")", systemImage: "plus.circle.fill") }
        }.adminBackground().navigationTitle(spec.title).searchable(text: $search)
    }
    private func eventStatus(_ row: AdminValue) -> String {
        guard row["enabled"].flag else { return "Off" }
        if let end = adminDate(row["endAt"].text), end <= .now { return "Ended" }
        if let start = adminDate(row["startAt"].text), start > .now { return "Scheduled" }
        return "Live"
    }
}

extension AdminContentArea {
    static var controlGroups: [AdminFieldGroup] { [
        .init("Announcement", [
            .init("announcement.enabled", "Enabled", .toggle),
            .init("announcement.title", "Title", .text),
            .init("announcement.message", "Message", .multiline),
            .init("announcement.actionLabel", "Button label", .text),
            .init("announcement.actionURL", "Button link", .text)
        ]),
        .init("Home sections", [
            .init("homeSections.showQuickDrinks", "Talla Express drinks", .toggle),
            .init("homeSections.showFunPick", "Today’s fun pick", .toggle),
            .init("homeSections.showSignatureRoasts", "Signature roasts", .toggle),
            .init("homeSections.showPassport", "Coffee passport", .toggle),
            .init("ui.homeSectionOrder", "Home section order", .words),
            .init("ui.hiddenHomeSections", "Hidden Home sections", .words)
        ]),
        .init("Navigation labels", [
            .init("ui.tabLabels.home", "Home label"),
            .init("ui.tabLabels.shop", "Shop label"),
            .init("ui.tabLabels.brew", "Brew label"),
            .init("ui.tabLabels.discover", "Discover label"),
            .init("ui.tabLabels.account", "Account label")
        ]),
        .init("Customer features", [
            .init("appFeatures.showBrewingGuides", "Brewing guides", .toggle),
            .init("appFeatures.showCommunityRecipes", "Community recipes", .toggle),
            .init("appFeatures.showEspressoWorkspace", "Espresso workspace", .toggle),
            .init("appFeatures.showGulfCoffeeMap", "Gulf Coffee Map", .toggle)
        ]),
        .init("Payment methods", [
            .init("payments.applePayEnabled", "Apple Pay", .toggle),
            .init("payments.benefitPayEnabled", "BenefitPay", .toggle),
            .init("payments.benefitEnabled", "Benefit", .toggle),
            .init("payments.cardEnabled", "Card", .toggle),
            .init("payments.clickToPayEnabled", "Click to Pay", .toggle),
            .init("payments.cashOnDeliveryEnabled", "Cash on delivery", .toggle),
            .init("payments.noticeEN", "English payment notice", .multiline),
            .init("payments.noticeAR", "Arabic payment notice", .multiline)
        ]),
        .init("Coffee Club", [
            .init("coffeeClub.enabled", "Available in customer app", .toggle),
            .init("coffeeClub.shipmentCount", "Prepaid shipments", .integer),
            .init("coffeeClub.intervalWeeks", "Weeks between shipments", .integer),
            .init("coffeeClub.discountPercent", "Coffee discount (%)", .integer),
            .init("coffeeClub.productIDs", "Coffee Club products", .products(100, false))
        ]),
        .init("Coffee memory", [
            .init("coffeeMemory.enabled", "Coffee memory enabled", .toggle),
            .init("coffeeMemory.automaticPurchaseImport", "Import Shopify coffee purchases", .toggle),
            .init("coffeeMemory.roastDateOCR", "Roast-date scanning", .toggle),
            .init("coffeeMemory.replacementRecommendations", "Replacement recommendations", .toggle)
        ]),
        .init("Delivery and pickup", [
            .init("fulfillment.deliveryEnabled", "Delivery enabled", .toggle),
            .init("fulfillment.pickupEnabled", "Pickup enabled", .toggle),
            .init("fulfillment.pickupNameEN", "English pickup name", .text),
            .init("fulfillment.pickupNameAR", "Arabic pickup name", .text),
            .init("fulfillment.pickupAddressEN", "English pickup address", .text),
            .init("fulfillment.pickupAddressAR", "Arabic pickup address", .text),
            .init("fulfillment.pickupMapsURL", "Pickup map link", .text),
            .init("fulfillment.openingHoursEN", "English opening hours", .text),
            .init("fulfillment.openingHoursAR", "Arabic opening hours", .text),
            .init("fulfillment.khaleejiTransitEN", "English GCC transit time", .text),
            .init("fulfillment.khaleejiTransitAR", "Arabic GCC transit time", .text),
            .init("fulfillment.bahrainRate", "Bahrain delivery rate (BHD)", .number),
            .init("fulfillment.khaleejiCashOnDeliverySurcharge", "GCC cash-on-delivery surcharge (BHD)", .number),
            .init("fulfillment.maximumKhaleejiWeightGrams", "Maximum GCC weight (grams)", .integer),
            .init("fulfillment.gulfMarkets", "GCC market delivery and packaging settings (JSON)", .json)
        ]),
        .init("Temporary closures", [
            .init("fulfillment.temporaryClosureEN", "English closure message", .multiline),
            .init("fulfillment.temporaryClosureAR", "Arabic closure message", .multiline)
        ]),
        .init("Maintenance and updates", [
            .init("release.maintenanceEnabled", "App maintenance", .toggle),
            .init("release.checkoutMaintenanceEnabled", "Checkout maintenance", .toggle),
            .init("release.minimumSupportedVersion", "Minimum supported version", .text),
            .init("release.latestVersion", "Latest version", .text),
            .init("release.appStoreURL", "App Store link", .text),
            .init("release.titleEN", "English maintenance title", .text),
            .init("release.titleAR", "Arabic maintenance title", .text),
            .init("release.messageEN", "English maintenance message", .text),
            .init("release.messageAR", "Arabic maintenance message", .text),
            .init("release.updateMessageEN", "English update message", .text),
            .init("release.updateMessageAR", "Arabic update message", .text)
        ]),
        .init("Loyalty rules", [
            .init("loyalty.pointsPerBHD", "Points per BHD", .number),
            .init("loyalty.silverThreshold", "Silver threshold", .integer),
            .init("loyalty.goldThreshold", "Gold threshold", .integer),
            .init("loyalty.reserveThreshold", "Reserve threshold", .integer),
            .init("loyalty.rewardStep", "Reward step", .integer),
            .init("loyalty.doubleBeanDays", "Double-Beans weekdays (0=Sunday)", .words),
            .init("loyalty.freeDeliveryThresholds.Silver", "Silver free delivery threshold", .number),
            .init("loyalty.freeDeliveryThresholds.Gold", "Gold free delivery threshold", .number),
            .init("loyalty.freeDeliveryThresholds.Reserve", "Reserve free delivery threshold", .number),
            .init("loyalty.earlyAccessEnabled", "Limited-lot early access", .toggle),
            .init("loyalty.earlyAccessMinimumTier", "Limited-lot minimum tier", .text)
        ]),
        .init("Support and policies", [
            .init("support.whatsappURL", "WhatsApp link", .text),
            .init("support.privacyURL", "Privacy policy link", .text),
            .init("support.termsURL", "Terms link", .text)
        ]),
    ] }
}
