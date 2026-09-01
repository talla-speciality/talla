import SwiftUI

struct OrderQueueView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var searchText = ""

    private var filteredOrders: [AdminOrder] {
        guard !searchText.isEmpty else { return session.orders }
        return session.orders.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.email.localizedCaseInsensitiveContains(searchText)
                || $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if session.isLoadingOrders && session.orders.isEmpty {
                    ProgressView("Loading orders…")
                } else if filteredOrders.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No orders yet" : "No matching orders",
                        systemImage: "shippingbox",
                        description: Text(searchText.isEmpty ? "New backend orders will appear here automatically." : "Try another order number or customer email.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            OrderSummaryHeader(orders: session.orders)
                            ForEach(filteredOrders) { order in
                                OrderCard(order: order)
                            }
                        }
                        .padding(16)
                    }
                    .background(TallaAdminStyle.cream.opacity(0.55))
                    .refreshable { await session.refreshOrders() }
                }
            }
            .navigationTitle("Orders")
            .searchable(text: $searchText, prompt: "Order or customer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await session.refreshOrders() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(session.isLoadingOrders)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let message = session.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.red, in: Capsule())
                        .padding(.bottom, 6)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await session.refreshOrders() } }
        }
    }
}

private struct OrderSummaryHeader: View {
    let orders: [AdminOrder]

    private var active: Int { orders.filter { !["Completed", "Fulfilled", "Delivered", "Cancelled"].contains($0.status) }.count }
    private var ready: Int { orders.filter { $0.status == "Ready" }.count }

    var body: some View {
        HStack(spacing: 12) {
            metric("Active", value: active, icon: "flame.fill")
            metric("Ready", value: ready, icon: "checkmark.seal.fill")
            metric("Total", value: orders.count, icon: "shippingbox.fill")
        }
    }

    private func metric(_ title: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(TallaAdminStyle.caramel)
            Text("\(value)").font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TallaAdminStyle.paper, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct OrderCard: View {
    @EnvironmentObject private var session: AdminSession
    let order: AdminOrder
    @State private var selectedStatus: String
    @State private var isSaving = false

    init(order: AdminOrder) {
        self.order = order
        _selectedStatus = State(initialValue: order.status)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(order.title).font(.title3.bold()).foregroundStyle(TallaAdminStyle.espresso)
                    Text(order.email).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(order.total)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(TallaAdminStyle.cream, in: Capsule())
            }

            if !order.items.isEmpty {
                Text(order.items.map { "\($0.name) ×\($0.quantity)" }.joined(separator: "  •  "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(order.createdDate?.formatted(date: .abbreviated, time: .shortened) ?? order.createdAt,
                      systemImage: "clock")
                Spacer()
                Label("\(order.itemCount)", systemImage: "bag.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 10) {
                Picker("Status", selection: $selectedStatus) {
                    ForEach(AdminOrderStatus.all, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    isSaving = true
                    Task {
                        await session.updateOrder(order, status: selectedStatus)
                        isSaving = false
                    }
                } label: {
                    if isSaving { ProgressView() } else { Text("Save") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving || selectedStatus == order.status)

                Button {
                    Task { await session.notifyReady(order) }
                } label: {
                    Image(systemName: "bell.fill")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Notify customer that order is ready")
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.brown.opacity(0.1)))
    }
}
