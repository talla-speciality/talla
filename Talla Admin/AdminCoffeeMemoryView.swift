import SwiftUI

struct AdminCoffeeMemoryView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var document: AdminValue?
    @State private var search = ""
    @State private var loading = false
    @State private var error: String?
    @State private var message: String?

    private var records: [AdminValue] {
        (document?["recentRecords"].array ?? []).filter {
            search.isEmpty || $0["email"].text.localizedCaseInsensitiveContains(search)
                || $0["title"].text.localizedCaseInsensitiveContains(search)
                || $0["entityType"].text.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            if let document {
                if !document["configured"].flag {
                    ContentUnavailableView("Coffee memory unavailable", systemImage: "externaldrive.badge.xmark", description: Text("Postgres must be configured to manage synchronized coffee records."))
                } else {
                    Section("Overview") {
                        AdminRecordRows(record: document, fields: [
                            .init("totals.customers", "Customers"), .init("totals.lots", "Bean lots"),
                            .init("totals.purchasedBags", "Purchased bags"), .init("totals.shopifyImports", "Shopify imports"),
                            .init("totals.brewSessions", "Brew sessions"), .init("totals.doseRecords", "Dose records"),
                            .init("totals.lotsMissingMetadata", "Lots missing metadata"), .init("totals.lastSyncAt", "Last sync")
                        ])
                    }
                    Section("Customer support") {
                        AdminActionForm(title: "Re-import Purchases", endpoint: "/admin/api/coffee-memory/reimport",
                            groups: [.init("Customer", [.init("email", "Customer email", required: true)])],
                            confirmation: "Fetch this customer’s recent Shopify orders and safely import missing coffee bags.",
                            onSaved: { result in message = "Processed \(result["syncedCount"].text) orders."; Task { await load() } }, document: .object([:]))
                    }
                    Section("Recent synchronized records") {
                        if records.isEmpty { Text("No matching records").foregroundStyle(.secondary) }
                        ForEach(records, id: \.objectID) { record in
                            DisclosureGroup(record["title"].text) {
                                AdminRecordRows(record: record, fields: [
                                    .init("email", "Customer"), .init("entityType", "Type"), .init("source", "Source"),
                                    .init("revision", "Revision"), .init("updatedAt", "Updated"), .init("recordID", "Record ID")
                                ])
                                NavigationLink("Remove incorrect record") {
                                    AdminActionForm(title: "Remove Coffee Record", endpoint: "/admin/api/coffee-memory/delete",
                                        groups: [], confirmation: "Permanently remove this incorrect synchronized record. This action is audit logged.",
                                        onSaved: { _ in message = "Record removed."; Task { await load() } },
                                        document: record.selecting(["email", "entityType", "recordID"]))
                                }.foregroundStyle(.red)
                            }
                        }
                    }
                }
            } else if loading { ProgressView("Loading coffee memory…") }
            else { Button("Try Again") { Task { await load() } } }
        }
        .adminBackground().navigationTitle("Coffee Memory").searchable(text: $search, prompt: "Customer, lot, or record type")
        .task { await load() }.refreshable { await load() }
        .toolbar { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }.disabled(loading) }
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: message) }
    }

    @MainActor private func load() async {
        guard !loading else { return }
        loading = true; error = nil
        defer { loading = false }
        do { document = try await session.api.document("/admin/api/coffee-memory") }
        catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
}
