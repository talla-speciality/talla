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
                            Text("Your roastery, in one place.").font(.title2.bold()).foregroundStyle(TallaAdminStyle.espresso)
                            HStack {
                                metric("Active", session.orders.filter(\.isActive).count)
                                metric("Completed", session.orders.filter(\.isCompleted).count)
                                metric("Cancelled", session.orders.filter(\.isCancelled).count)
                            }
                        }.padding(.vertical, 8)
                    }
                }
                Section("Store") {
                    if includes("Products catalog inventory") { NavigationLink { AdminProductsView() } label: { row("Products & Inventory", "Catalog, pricing, images, and stock", "bag.fill") } }
                    if includes("Customers loyalty vouchers addresses") { NavigationLink { AdminCustomersView() } label: { row("Customers & Loyalty", "Accounts, Beans, vouchers, and addresses", "person.2.fill") } }
                }
                Section("Customer app") {
                    ForEach(AdminContentArea.allCases.filter { includes($0.rawValue) }) { area in
                        NavigationLink { AdminContentView(area: area) } label: { row(area.rawValue, subtitle(area), area.icon) }
                    }
                    if includes("Notifications push messages") { NavigationLink { AdminNotificationComposer() } label: { row("Notifications", "Compose a customer push notification", "bell.badge.fill") } }
                }
                Section("Insights") {
                    ForEach(AdminReport.allCases.filter { includes($0.rawValue) }) { report in
                        NavigationLink { AdminReportView(report: report) } label: { row(report.rawValue, report.subtitle, report.icon) }
                    }
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
        switch area { case .home: "Hero content and featured products"; case .controls: "Payments, delivery, maintenance, and loyalty"; case .events: "Collections, bilingual content, and schedules"; case .passport: "Origins and completion rewards" }
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
        case .analytics: [.init("totals.customers", "Customers"), .init("totals.totalOrders", "Total orders"), .init("totals.activeVouchers", "Active vouchers"), .init("totals.averagePoints", "Average Beans"), .init("totals.customersWithOrders", "Customers with orders"), .init("totals.pendingOrders", "Pending orders"), .init("totals.usedVouchers", "Used vouchers")]
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
