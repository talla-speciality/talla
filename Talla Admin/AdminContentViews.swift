import SwiftUI

enum AdminContentArea: String, CaseIterable, Identifiable {
    case home = "App Home", controls = "Live Controls", events = "Seasonal Events", passport = "Coffee Passport"
    var id: Self { self }
    var endpoint: String {
        switch self {
        case .home: "/admin/api/home/signature-roasts"
        case .controls: "/admin/api/app-settings"
        case .events: "/admin/api/events"
        case .passport: "/admin/api/passport-settings"
        }
    }
    var icon: String {
        switch self { case .home: "house.fill"; case .controls: "slider.horizontal.3"; case .events: "sparkles"; case .passport: "globe.europe.africa.fill" }
    }
    var groups: [AdminFieldGroup] {
        switch self {
        case .home: return [
            .init("Hero", [.init("heroEyebrow", "Eyebrow"), .init("heroTitle", "Title"), .init("heroSubtitle", "Subtitle", .multiline), .init("heroBadge", "Badge"), .init("primaryButtonTitle", "Primary button"), .init("secondaryButtonTitle", "Secondary button")]),
            .init("Featured products", [.init("signatureRoastProductIDs", "Signature roasts", .products(4, false)), .init("quickDrinkProductIDs", "Talla Express drinks", .products(6, true)), .init("funPickProductID", "Today's fun pick", .product)])
        ]
        case .passport: return [.init("Completion reward", [.init("completionRewardTitle", "Reward title"), .init("completionRewardDetail", "Reward detail", .multiline)])]
        case .events: return []
        case .controls: return Self.controlGroups
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

extension AdminContentArea {
    var arrays: [AdminArraySpec] {
        switch self {
        case .home: return []
        case .passport: return [.init(path: "origins", title: "Origins", groups: [.init("Origin", [
            .init("id", "Origin identifier", required: true), .init("title", "Name", required: true), .init("emoji", "Flag or emoji"), .init("keywords", "Matching keywords", .words), .init("rewardLabel", "Reward label")
        ])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "title": .string("New origin"), "keywords": .array([])]))]
        case .events: return [.init(path: "events", title: "Events", groups: [
            .init("Event", [.init("id", "Event identifier", required: true), .init("name", "Name", required: true), .init("enabled", "Enabled", .toggle), .init("priority", "Display priority", .integer)]),
            .init("English content", [.init("titleEN", "Title", required: true), .init("subtitleEN", "Subtitle", .multiline), .init("badgeEN", "Badge"), .init("ctaEN", "Button label"), .init("categoryTitleEN", "Category title"), .init("categorySubtitleEN", "Category subtitle", .multiline)]),
            .init("Arabic content", [.init("titleAR", "Title"), .init("subtitleAR", "Subtitle", .multiline), .init("badgeAR", "Badge"), .init("ctaAR", "Button label"), .init("categoryTitleAR", "Category title"), .init("categorySubtitleAR", "Category subtitle", .multiline)]),
            .init("Schedule", [.init("startAt", "Start date", .date), .init("endAt", "End date", .date)]),
            .init("Appearance", [.init("imageURL", "Image URL"), .init("symbol", "Symbol name"), .init("accentHex", "Accent color (hex)"), .init("secondaryHex", "Secondary color (hex)")]),
            .init("Collection", [.init("productIDs", "Products", .products(40, false))])
        ], blank: .object(["id": .string(UUID().uuidString.lowercased()), "name": .string("New event"), "enabled": .bool(false), "priority": .number(0), "titleEN": .string("New event"), "productIDs": .array([]), "symbol": .string("sparkles"), "accentHex": .string("#C8965A"), "secondaryHex": .string("#2A1D14")]))]
        case .controls: return [
            .init(path: "fulfillment.khaleejiTiers", title: "GCC shipping tiers", groups: [.init("Shipping tier", [.init("maximumWeightGrams", "Maximum weight (grams)", .integer), .init("rate", "Rate (BHD)", .number)])], blank: .object(["maximumWeightGrams": .number(500), "rate": .number(5.5)])),
            .init(path: "loyalty.rewards", title: "Loyalty rewards", groups: [.init("Reward", [.init("id", "Reward identifier", required: true), .init("enabled", "Enabled", .toggle), .init("points", "Points required", .integer), .init("reward", "Reward name", required: true), .init("titleEN", "English title", required: true), .init("titleAR", "Arabic title"), .init("detailEN", "English detail", .multiline), .init("detailAR", "Arabic detail", .multiline)])], blank: .object(["id": .string(UUID().uuidString.lowercased()), "enabled": .bool(true), "points": .number(50), "reward": .string("New reward"), "titleEN": .string("New reward")]))
        ]
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
        if area == .home || area == .events {
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
                guard !body.at("fulfillment.khaleejiTiers").array.isEmpty, !body.at("loyalty.rewards").array.isEmpty else { throw AdminAPIError.server("Keep at least one shipping tier and loyalty reward.") }
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
            .init("homeSections.showPassport", "Coffee passport", .toggle)
        ]),
        .init("Payment methods", [
            .init("payments.applePayEnabled", "Apple Pay", .toggle),
            .init("payments.benefitPayEnabled", "BenefitPay", .toggle),
            .init("payments.benefitEnabled", "Benefit", .toggle),
            .init("payments.cardEnabled", "Card", .toggle),
            .init("payments.cashOnDeliveryEnabled", "Cash on delivery", .toggle),
            .init("payments.noticeEN", "English payment notice", .multiline),
            .init("payments.noticeAR", "Arabic payment notice", .multiline)
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
            .init("fulfillment.maximumKhaleejiWeightGrams", "Maximum GCC weight (grams)", .integer)
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
            .init("loyalty.pointsPerBHD", "Points per BHD", .integer),
            .init("loyalty.silverThreshold", "Silver threshold", .integer),
            .init("loyalty.goldThreshold", "Gold threshold", .integer),
            .init("loyalty.rewardStep", "Reward step", .integer)
        ]),
        .init("Support and policies", [
            .init("support.whatsappURL", "WhatsApp link", .text),
            .init("support.privacyURL", "Privacy policy link", .text),
            .init("support.termsURL", "Terms link", .text)
        ]),
    ] }
}
