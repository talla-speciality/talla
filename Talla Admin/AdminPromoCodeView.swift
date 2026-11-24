import SwiftUI

struct AdminPromoCodesView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var promoCodes: [AdminValue] = []
    @State private var loading = false
    @State private var error: String?
    @State private var showingCreate = false
    @State private var revokeCode: String?

    private var activeCodes: [AdminValue] { promoCodes.filter { $0["status"].text == "active" } }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    metric("Active", activeCodes.count, "ticket.fill")
                    metric("Total", promoCodes.count, "clock.arrow.circlepath")
                }
                Text("Create public discounts customers can enter in the cart. Codes are validated again at checkout.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Promo codes") {
                if loading && promoCodes.isEmpty { ProgressView("Loading promo codes…") }
                else if promoCodes.isEmpty { ContentUnavailableView("No promo codes", systemImage: "ticket", description: Text("Create your first percentage or fixed BHD discount.")) }
                else { ForEach(promoCodes, id: \.objectID) { promo in promoRow(promo) } }
            }
        }
        .adminBackground().navigationTitle("Promo codes")
        .refreshable { await load() }.task { if promoCodes.isEmpty { await load() } }
        .toolbar {
            Button { showingCreate = true } label: { Image(systemName: "plus") }.accessibilityLabel("Create promo code")
            Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }.disabled(loading).accessibilityLabel("Refresh promo codes")
        }
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: nil) }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                AdminActionForm(title: "Create Promo Code", endpoint: "/admin/api/promo-codes/create", groups: [
                    .init("Discount", [
                        .init("code", "Code", required: true),
                        .init("discountType", "Discount type", .choice(["percentage", "fixed"]), required: true),
                        .init("discountValue", "Discount value", .number, required: true),
                        .init("detail", "Customer-facing detail", .multiline),
                        .init("expiresInDays", "Expires in days", .integer, required: true)
                    ])
                ], confirmation: "Create this public promo code. Percentage values must be 100 or less; fixed values are in BHD.", onSaved: { _ in Task { await load() } }, document: .object(["discountType": .string("percentage"), "discountValue": .number(10), "expiresInDays": .number(30)]))
            }
        }
        .confirmationDialog("Revoke promo code?", isPresented: Binding(get: { revokeCode != nil }, set: { if !$0 { revokeCode = nil } }), titleVisibility: .visible) {
            Button("Revoke", role: .destructive) { guard let code = revokeCode else { return }; revokeCode = nil; Task { await revoke(code) } }
            Button("Cancel", role: .cancel) { revokeCode = nil }
        } message: { Text("This will stop the code from being applied to new checkouts.") }
    }

    private func metric(_ title: String, _ value: Int, _ icon: String) -> some View {
        Label { VStack(alignment: .leading) { Text("\(value)").font(.title3.bold()); Text(title).font(.caption).foregroundStyle(.secondary) } } icon: { Image(systemName: icon).foregroundStyle(TallaAdminStyle.caramel) }
            .frame(maxWidth: .infinity, alignment: .leading).padding(12).background(TallaAdminStyle.cream, in: RoundedRectangle(cornerRadius: 14))
    }

    private func promoRow(_ promo: AdminValue) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Text(promo["code"].text).font(.headline.monospaced()); Spacer(); Text(promo["status"].text.capitalized).font(.caption.bold()).foregroundStyle(promo["status"].text == "active" ? TallaAdminStyle.success : .secondary) }
            HStack(spacing: 8) { Text(discountText(for: promo)).font(.subheadline.bold()).foregroundStyle(TallaAdminStyle.caramel); Text("•").foregroundStyle(.secondary); Text(promo["detail"].text).font(.subheadline).foregroundStyle(.secondary).lineLimit(1) }
            HStack { Text("Expires \(formattedDate(promo["expiresAt"].text))").font(.caption).foregroundStyle(.secondary); Spacer(); if promo["status"].text == "active" { Button("Revoke", role: .destructive) { revokeCode = promo["code"].text }.font(.caption.bold()) } }
        }.padding(.vertical, 5)
    }

    private func discountText(for promo: AdminValue) -> String { promo["discountType"].text == "percentage" ? "\(promo["discountValue"].text)% off" : "BHD \(promo["discountValue"].text) off" }
    private func formattedDate(_ text: String) -> String { guard let date = adminDate(text) else { return text.isEmpty ? "unknown" : text }; return date.formatted(date: .abbreviated, time: .omitted) }

    @MainActor private func load() async {
        guard !loading else { return }; loading = true; error = nil; defer { loading = false }
        do { promoCodes = try await session.api.document("/admin/api/promo-codes")["promoCodes"].array }
        catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }

    @MainActor private func revoke(_ code: String) async {
        do { _ = try await session.api.document("/admin/api/promo-codes/revoke", body: .object(["code": .string(code)])); await load() }
        catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
}
