import SwiftUI

struct AdminWorkspaceView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var search = ""
    private func includes(_ text: String) -> Bool { search.isEmpty || text.localizedCaseInsensitiveContains(search) }
    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Admin workspace").font(.title2.bold()).foregroundStyle(TallaAdminStyle.espresso)
                            Text("Keep the day-to-day work in the tabs below. Use this space for configuration, content, and reporting.")
                                .font(.subheadline).foregroundStyle(.secondary)
                            HStack {
                                metric("Active", session.orders.filter(\.isActive).count)
                                metric("Completed", session.orders.filter(\.isCompleted).count)
                                metric("Cancelled", session.orders.filter(\.isCancelled).count)
                            }
                        }.padding(.vertical, 8)
                    }
                }
                Section("Customer app content") {
                    ForEach(AdminContentArea.allCases.filter { $0 != .espresso && includes($0.rawValue) }) { area in
                        NavigationLink { AdminContentView(area: area) } label: { row(area.rawValue, subtitle(area), area.icon) }
                    }
                }
                Section("Customer engagement") {
                    if includes("Coffee memory beans lots sync recommendations") { NavigationLink { AdminCoffeeMemoryView() } label: { row("Coffee Memory", "Lots, imports, sync health, and customer support", "cup.and.saucer.fill") } }
                    if includes("Community recipes moderation edit approve reject") { NavigationLink { AdminCommunityRecipesView() } label: { row("Community Recipes", "Edit and moderate customer-submitted recipes", "book.and.wrench.fill") } }
                    if includes("Notifications push messages") { NavigationLink { AdminNotificationComposer() } label: { row("Notifications", "Compose a customer push notification", "bell.badge.fill") } }
                }
                Section("Insights") {
                    ForEach(AdminReport.allCases.filter { includes($0.rawValue) }) { report in
                        NavigationLink { AdminReportView(report: report) } label: { row(report.rawValue, report.subtitle, report.icon) }
                    }
                }
                Section("System") {
                    if includes("Espresso machine grinder burr basket portafilter dial in") { NavigationLink { AdminContentView(area: .espresso) } label: { row("Espresso setup", "Targets, machines, grinders, baskets, and portafilters", "dial.medium") } }
                }
            }.adminBackground().navigationTitle("Admin").searchable(text: $search, prompt: "Find an admin section")
        }
    }
    private func row(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(TallaAdminStyle.caramel).frame(width: 32)
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }.padding(.vertical, 8)
    }
    private func metric(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text("\(value)").font(.title2.bold()); Text(title).font(.caption).foregroundStyle(.secondary) }
            .frame(maxWidth: .infinity, alignment: .leading).padding(10).background(TallaAdminStyle.cream, in: RoundedRectangle(cornerRadius: 12))
    }
    private func subtitle(_ area: AdminContentArea) -> String {
        switch area { case .home: "Hero content and featured products"; case .controls: "Payments, delivery, maintenance, and loyalty"; case .events: "Collections, bilingual content, and schedules"; case .passport: "Origins and completion rewards"; case .espresso: "Targets, equipment profiles, and dial-in guidance"; case .education: "Lessons, flavour knowledge, and quiz questions" }
    }
}

extension AdminAPI {
    func updateCommunityRecipe(_ document: AdminValue) async throws -> AdminValue {
        try await self.document("/admin/api/community-recipes/update", body: document.selecting(["id", "title", "method", "detail"]))
    }

    func moderateCommunityRecipe(id: String, status: String) async throws -> AdminValue {
        try await self.document("/admin/api/community-recipes/moderate", body: .object(["id": .string(id), "status": .string(status)]))
    }
}

struct AdminCommunityRecipesView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var recipes: [AdminValue] = []
    @State private var search = ""
    @State private var filter = "All"
    @State private var loading = false
    @State private var error: String?

    private var visibleRecipes: [(Int, AdminValue)] {
        recipes.enumerated().filter { _, recipe in
            let matchesSearch = search.isEmpty || [recipe["title"].text, recipe["method"].text, recipe["detail"].text, recipe["author"].text].joined(separator: " ").localizedCaseInsensitiveContains(search)
            let matchesFilter = filter == "All" || recipe["status"].text.caseInsensitiveCompare(filter) == .orderedSame
            return matchesSearch && matchesFilter
        }.map { ($0.offset, $0.element) }
    }

    var body: some View {
        List {
            Picker("Status", selection: $filter) {
                ForEach(["All", "Pending", "Approved", "Rejected"], id: \.self) { Text($0) }
            }.pickerStyle(.segmented)
            if loading { ProgressView("Loading recipes…") }
            if !loading && recipes.isEmpty { ContentUnavailableView("No community recipes", systemImage: "book.closed", description: Text("Customer-submitted recipes will appear here.")) }
            ForEach(visibleRecipes, id: \.0) { index, recipe in
                NavigationLink {
                    AdminCommunityRecipeEditor(document: recipe) { updated in recipes[index] = updated }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe["title"].text.isEmpty ? "Untitled recipe" : recipe["title"].text).font(.headline)
                        Text("\(recipe["method"].text.isEmpty ? "Method not specified" : recipe["method"].text) · \(recipe["author"].text.isEmpty ? recipe["authorEmail"].text : recipe["author"].text)").font(.caption).foregroundStyle(.secondary)
                        Text(recipe["status"].text.capitalized).font(.caption.weight(.semibold)).foregroundStyle(TallaAdminStyle.caramel)
                    }.padding(.vertical, 5)
                }
            }
        }.adminBackground().navigationTitle("Community Recipes").searchable(text: $search, prompt: "Find a recipe")
        .task { await load() }.refreshable { await load() }
        .toolbar { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }.disabled(loading).accessibilityLabel("Refresh recipes") }
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: nil) }
    }

    @MainActor private func load() async {
        guard !loading else { return }; loading = true; error = nil; defer { loading = false }
        do { recipes = try await session.api.document("/admin/api/community-recipes")["recipes"].array }
        catch let caughtError {
            error = caughtError.localizedDescription
            if case AdminAPIError.unauthorized = caughtError {
                session.handle(caughtError)
            }
        }
    }
}

struct AdminCommunityRecipeEditor: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.dismiss) private var dismiss
    @State private var document: AdminValue
    @State private var busy = false
    @State private var error: String?
    @State private var message: String?
    let onSaved: (AdminValue) -> Void
    private let fields: [AdminField] = [
        .init("title", "Title", required: true),
        .init("method", "Method"),
        .init("detail", "Recipe and notes", .multiline, required: true)
    ]

    init(document: AdminValue, onSaved: @escaping (AdminValue) -> Void) {
        _document = State(initialValue: document)
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section("Recipe") { ForEach(fields) { AdminFieldRow(field: $0, document: $document) } }
            Section("Moderation") {
                Picker("Status", selection: Binding(get: { document["status"].text }, set: { document["status"] = .string($0) })) {
                    ForEach(["pending", "approved", "rejected"], id: \.self) { Text($0.capitalized).tag($0) }
                }
                if !document["authorEmail"].text.isEmpty { LabeledContent("Author", value: document["authorEmail"].text) }
            }
            Section { Button(busy ? "Saving…" : "Save Recipe") { Task { await save() } }.disabled(busy) }
        }.adminBackground().navigationTitle("Edit Recipe").navigationBarTitleDisplayMode(.inline).disabled(busy)
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: message) }
    }

    @MainActor private func save() async {
        do {
            document = try adminValidated(document, fields: fields)
            guard !document["id"].text.isEmpty else { throw AdminAPIError.server("Recipe id is missing.") }
            busy = true; error = nil; message = nil
            let updated = try await session.api.updateCommunityRecipe(document)
            if document["status"].text != updated["status"].text {
                _ = try await session.api.moderateCommunityRecipe(id: updated["id"].text, status: document["status"].text)
            }
            let refreshed = try await session.api.document("/admin/api/community-recipes")["recipes"].array.first { $0["id"].text == updated["id"].text } ?? updated
            document = refreshed; onSaved(refreshed); message = "Recipe saved."
        } catch let caughtError {
            error = caughtError.localizedDescription
            if case AdminAPIError.unauthorized = caughtError {
                session.handle(caughtError)
            }
        }
        busy = false
    }
}

enum AdminReport: String, CaseIterable, Identifiable {
    case analytics = "Analytics", operations = "Operations", taste = "Taste Memory", audit = "Recent Admin Actions"
    var id: Self { self }
    var endpoint: String {
        switch self { case .analytics: "/admin/api/analytics/summary"; case .operations: "/admin/api/ops/summary"; case .taste: "/admin/api/taste-memory"; case .audit: "/admin/api/audit/recent?limit=100" }
    }
    var icon: String {
        switch self { case .analytics: "chart.bar.fill"; case .operations: "waveform.path.ecg"; case .taste: "cup.and.saucer.fill"; case .audit: "clock.arrow.circlepath" }
    }
    var subtitle: String {
        switch self { case .analytics: "Customers, orders, and loyalty performance"; case .operations: "Service health and recent errors"; case .taste: "Customer reactions and coffee preferences"; case .audit: "A history of admin changes" }
    }
    var metrics: [AdminField] {
        switch self {
        case .analytics: [
            .init("totals.customers", "Customers"), .init("totals.totalOrders", "Total orders"),
            .init("totals.customersWithOrders", "Customers with orders"), .init("totals.repeatCustomers", "Repeat customers"),
            .init("totals.repeatPurchaseRatePercent", "Repeat purchase rate %"),
            .init("totals.activeCoffeeClubPlans", "Active Coffee Club plans"),
            .init("totals.checkoutStartedLast30Days", "Checkout starts · 30 days"),
            .init("totals.purchasesCompletedLast30Days", "Purchases · 30 days"),
            .init("totals.checkoutConversionPercent", "Checkout conversion %"),
            .init("totals.paymentFailuresLast30Days", "Payment failures · 30 days"),
            .init("totals.pendingOrders", "Pending orders"), .init("totals.activeVouchers", "Active vouchers"),
            .init("totals.usedVouchers", "Used vouchers"), .init("totals.averagePoints", "Average Beans")
        ]
        case .operations: [.init("totals.requestsLastHour", "Requests / hour"), .init("totals.errorsLastHour", "Server errors / hour"), .init("totals.rateLimitedLastHour", "Rate limits / hour"), .init("totals.avgDurationMs", "Average duration (ms)")]
        default: []
        }
    }
    var groups: [AdminHistoryGroup] {
        let customer: [AdminField] = [.init("firstName", "First name"), .init("lastName", "Last name"), .init("email", "Email"), .init("pointsBalance", "Beans"), .init("loyaltyTier", "Tier"), .init("createdAt", "Created")]
        switch self {
        case .analytics: return [.init(path: "topCustomers", title: "Top customers by Beans", fields: customer), .init(path: "newestCustomers", title: "Newest accounts", fields: customer)]
        case .operations: return ["recentErrors", "recentRateLimits"].map { .init(path: $0, title: $0 == "recentErrors" ? "Recent server errors" : "Recent rate limits", fields: [.init("method", "Method"), .init("path", "Path"), .init("statusCode", "Status"), .init("durationMs", "Duration (ms)"), .init("ipAddress", "IP address"), .init("createdAt", "Date")]) }
        case .taste: return [.init(path: "tasteMemory", title: "Customer feedback", fields: [.init("productName", "Product"), .init("email", "Customer"), .init("reaction", "Reaction"), .init("updatedAt", "Updated"), .init("createdAt", "Created")])]
        case .audit: return [.init(path: "auditLogs", title: "Recent actions", fields: [.init("detail", "Detail"), .init("action", "Action"), .init("adminUsername", "Admin"), .init("targetEmail", "Customer"), .init("createdAt", "Date")])]
        }
    }
}

struct AdminReportView: View {
    @EnvironmentObject private var session: AdminSession
    let report: AdminReport
    @State private var document: AdminValue?
    @State private var loading = false
    @State private var error: String?
    @State private var search = ""
    @State private var reaction = "All"
    @State private var refreshed: Date?
    var body: some View {
        List {
            if let document {
                if report == .operations && !document["enabled"].flag {
                    ContentUnavailableView("Operations unavailable", systemImage: report.icon, description: Text("Request logging must be enabled on the server to show service health."))
                } else {
                    if !report.metrics.isEmpty {
                        Section("Overview") { AdminRecordRows(record: document, fields: report.metrics) }
                    }
                    if report == .analytics {
                        Section("Loyalty tiers") {
                            ForEach(document["tierCounts"].object.keys.sorted(), id: \.self) { tier in LabeledContent(tier, value: document["tierCounts"][tier].text) }
                        }
                    }
                    if report == .taste { Picker("Reaction", selection: $reaction) { ForEach(["All", "Loved", "Not for me"], id: \.self) { Text($0) } }.pickerStyle(.segmented) }
                    ForEach(report.groups) { group in
                        let records = document[group.path].array.filter { row in
                            (search.isEmpty || group.fields.contains { row.at($0.path).text.localizedCaseInsensitiveContains(search) }) && (report != .taste || reaction == "All" || (reaction == "Loved") == (row["reaction"].text == "loved"))
                        }
                        Section(group.title) {
                            if records.isEmpty { Text("No matching records").foregroundStyle(.secondary) }
                            ForEach(Array(records.enumerated()), id: \.offset) { _, row in
                                DisclosureGroup(row.title) {
                                    AdminRecordRows(record: row, fields: group.fields)
                                    if !row["tags"].array.isEmpty { Text(row["tags"].array.map(\.text).joined(separator: " · ")).font(.caption) }
                                    if !row["email"].text.isEmpty { NavigationLink("Open customer") { AdminCustomerDetailView(email: row["email"].text, onChanged: {}) } }
                                }
                            }
                        }
                    }
                }
                if let refreshed { Section { Text("Refreshed \(refreshed.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary) } }
            } else if loading { ProgressView("Loading \(report.rawValue.lowercased())…") }
            else { Button("Try Again") { Task { await load() } } }
        }.adminBackground().navigationTitle(report.rawValue).navigationBarTitleDisplayMode(.inline).searchable(text: $search)
        .task { if document == nil { await load() } }.refreshable { await load() }
        .toolbar { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }.disabled(loading).accessibilityLabel("Refresh report") }
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: nil) }
    }
    @MainActor private func load() async {
        guard !loading else { return }; loading = true; error = nil; defer { loading = false }
        do { document = try await session.api.document(report.endpoint); refreshed = .now }
        catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
}

struct AdminNotificationComposer: View {
    @EnvironmentObject private var session: AdminSession
    @State private var document: AdminValue = .object([:])
    @State private var confirm = false
    @State private var sending = false
    @State private var error: String?
    @State private var message: String?
    private let fields: [AdminField] = [.init("title", "Title", required: true), .init("body", "Message", .multiline, required: true), .init("url", "Optional destination link")]
    var body: some View {
        Form {
            Section("Compose") { ForEach(fields) { AdminFieldRow(field: $0, document: $document) } }
            Section("Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Talla Speciality", systemImage: "cup.and.saucer.fill").font(.caption).foregroundStyle(TallaAdminStyle.caramel)
                    Text(document["title"].text.isEmpty ? "Notification title" : document["title"].text).font(.headline)
                    Text(document["body"].text.isEmpty ? "Your message will appear here." : document["body"].text)
                }.padding(.vertical, 8)
            }
            Section {
                Text("Audience: all eligible customer devices.").font(.footnote).foregroundStyle(.secondary)
                Button(sending ? "Sending…" : "Review and Send") {
                    do { document = try adminValidated(document, fields: fields); confirm = true }
                    catch { self.error = error.localizedDescription }
                }
            }
        }.adminBackground().navigationTitle("Notifications").disabled(sending)
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: message) }
        .confirmationDialog("Send to all customer devices?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Send Notification") { Task { await send() } }
        } message: { Text("\(document["title"].text)\n\n\(document["body"].text)\n\nThis sends immediately.") }
    }
    @MainActor private func send() async {
        sending = true; error = nil; message = nil; defer { sending = false }
        do {
            let response = try await session.api.document("/admin/api/notifications/push/send-all", body: document)
            guard response["configured"].flag else { throw AdminAPIError.server("Customer push is not configured. No notifications were sent.") }
            message = "Sent to \(response["sentCount"].text) of \(response["targetCount"].text) devices."
        } catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
}
