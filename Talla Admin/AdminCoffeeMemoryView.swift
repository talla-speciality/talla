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
                    Section("Measured brews") {
                        let brews = document["brewInsights"].array ?? []
                        if brews.isEmpty { Text("No measured brews synced yet").foregroundStyle(.secondary) }
                        ForEach(brews, id: \.objectID) { brew in
                            DisclosureGroup(brew["title"].text.isEmpty ? "Measured brew" : brew["title"].text) {
                                AdminBrewCurveView(points: brew["curve"].array ?? [])
                                    .frame(height: 150)
                                    .padding(.vertical, 8)
                                AdminRecordRows(record: brew, fields: [
                                    .init("email", "Customer"), .init("method", "Method"), .init("sampleCount", "Samples"),
                                    .init("maxWeight", "Final weight (g)"), .init("averageFlow", "Average flow (g/s)"),
                                    .init("durationMilliseconds", "Measured duration (ms)"), .init("updatedAt", "Updated")
                                ])
                            }
                        }
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

private struct AdminBrewCurveView: View {
    let points: [AdminValue]

    var body: some View {
        GeometryReader { proxy in
            let weights = points.filter { $0["kind"].text == "weight" }
            let flows = points.filter { $0["kind"].text == "flow" }
            let maxWeight = max(weights.map { $0["value"].number }.max() ?? 1, 1)
            let maxFlow = max(flows.map { $0["value"].number }.max() ?? 1, 1)
            Canvas { context, size in
                drawLine(weights, maxValue: maxWeight, color: .orange, context: &context, size: size)
                drawLine(flows, maxValue: maxFlow, color: .blue, context: &context, size: size)
            }
            .overlay(alignment: .topLeading) {
                HStack(spacing: 12) {
                    Label("Weight", systemImage: "circle.fill").foregroundStyle(.orange)
                    Label("Flow", systemImage: "circle.fill").foregroundStyle(.blue)
                }
                .font(.caption2)
                .padding(6)
                .background(.thinMaterial, in: Capsule())
            }
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
        }
    }

    private func drawLine(_ values: [AdminValue], maxValue: Double, color: Color, context: inout GraphicsContext, size: CGSize) {
        guard values.count > 1 else { return }
        let maxTime = max(values.map { $0["elapsedMilliseconds"].number }.max() ?? 1, 1)
        var path = Path()
        for (index, point) in values.enumerated() {
            let x = CGFloat(point["elapsedMilliseconds"].number / maxTime) * size.width
            let y = size.height - CGFloat(point["value"].number / maxValue) * (size.height - 8) - 4
            if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        context.stroke(path, with: .color(color), lineWidth: 2)
    }
}
