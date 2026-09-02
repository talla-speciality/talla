import SwiftUI

enum AdminOrderQueue: String, CaseIterable, Identifiable {
    case active
    case completed
    case cancelled

    var id: Self { self }

    var label: String {
        switch self {
        case .active: "Active"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }

    var emptyTitle: String {
        switch self {
        case .active: "No active orders"
        case .completed: "No completed orders"
        case .cancelled: "No cancelled orders"
        }
    }

    var emptyDescription: String {
        switch self {
        case .active: "New orders will appear here automatically."
        case .completed: "Completed, fulfilled, and delivered orders are kept here."
        case .cancelled: "Orders marked Cancelled are kept here."
        }
    }

    var icon: String {
        switch self {
        case .active: "shippingbox"
        case .completed: "checkmark.circle"
        case .cancelled: "archivebox"
        }
    }
}

struct OrderQueueView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.scenePhase) private var scenePhase
    @State private var searchText = ""
    @State private var queue: AdminOrderQueue = .active

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-admin-preview-completed") {
            _queue = State(initialValue: .completed)
        } else if ProcessInfo.processInfo.arguments.contains("-admin-preview-cancelled") {
            _queue = State(initialValue: .cancelled)
        }
        #endif
    }

    private var queueOrders: [AdminOrder] {
        switch queue {
        case .active: session.orders.filter(\.isActive)
        case .completed: session.orders.filter(\.isCompleted)
        case .cancelled: session.orders.filter(\.isCancelled)
        }
    }

    private var filteredOrders: [AdminOrder] {
        guard !searchText.isEmpty else { return queueOrders }
        return queueOrders.filter { order in
            order.title.localizedCaseInsensitiveContains(searchText)
                || order.email.localizedCaseInsensitiveContains(searchText)
                || order.id.localizedCaseInsensitiveContains(searchText)
                || order.items.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Order queue", selection: $queue) {
                    ForEach(AdminOrderQueue.allCases) { value in
                        Text(value.label).tag(value)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Group {
                    if session.isLoadingOrders && session.orders.isEmpty {
                        ProgressView("Loading orders…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredOrders.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? queue.emptyTitle : "No matching orders",
                            systemImage: queue.icon,
                            description: Text(searchText.isEmpty ? queue.emptyDescription : "Try another order number, email, or item.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                QueueHeader(queue: queue, orders: queueOrders, lastRefreshAt: session.lastRefreshAt)
                                ForEach(filteredOrders) { order in
                                    OrderCard(order: order)
                                }
                            }
                            .padding(16)
                            .padding(.bottom, 8)
                        }
                        .refreshable { await session.refreshOrders() }
                        .overlay(alignment: .top) {
                            if session.isLoadingOrders {
                                ProgressView()
                                    .padding(9)
                                    .background(.regularMaterial, in: Circle())
                                    .padding(.top, 8)
                            }
                        }
                    }
                }
                .background(TallaAdminStyle.background)
            }
            .navigationTitle("Orders")
            .searchable(text: $searchText, prompt: "Order number, email, or item")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await session.refreshOrders() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(session.isLoadingOrders)
                    .accessibilityLabel("Refresh orders")
                }
            }
            .safeAreaInset(edge: .bottom) {
                OrderFeedbackBanner()
            }
            .animation(.easeInOut(duration: 0.2), value: queue)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await session.refreshOrders() } }
        }
    }
}

private struct QueueHeader: View {
    let queue: AdminOrderQueue
    let orders: [AdminOrder]
    let lastRefreshAt: Date?

    private var pending: Int { orders.filter { $0.status.caseInsensitiveCompare("Pending") == .orderedSame }.count }
    private var ready: Int { orders.filter { $0.status.caseInsensitiveCompare("Ready") == .orderedSame }.count }
    private var items: Int { orders.reduce(0) { $0 + $1.itemCount } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if queue == .active {
                HStack(spacing: 10) {
                    metric("Pending", value: pending, icon: "clock.fill")
                    metric("Ready", value: ready, icon: "checkmark.seal.fill")
                    metric("Items", value: items, icon: "bag.fill")
                }
            }

            HStack {
                Text("\(orders.count) \(orders.count == 1 ? "order" : "orders")")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let lastRefreshAt {
                    Label(lastRefreshAt.formatted(date: .omitted, time: .shortened), systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func metric(_ title: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(TallaAdminStyle.caramel)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(TallaAdminStyle.espresso)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(TallaAdminStyle.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(TallaAdminStyle.border.opacity(0.35)))
    }
}

private struct OrderFeedbackBanner: View {
    @EnvironmentObject private var session: AdminSession

    var body: some View {
        if let text = session.errorMessage ?? session.message {
            HStack(spacing: 10) {
                Image(systemName: session.errorMessage == nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                Text(text)
                    .font(.footnote.weight(.medium))
                    .lineLimit(3)
                Spacer(minLength: 4)
                Button { session.clearFeedback() } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                }
                .accessibilityLabel("Dismiss message")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(session.errorMessage == nil ? TallaAdminStyle.success : Color.red, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private struct OrderCard: View {
    @EnvironmentObject private var session: AdminSession
    let order: AdminOrder
    @State private var selectedStatus: String
    @State private var isSaving = false
    @State private var isNotifying = false
    @State private var showNotifyConfirmation = false

    init(order: AdminOrder) {
        self.order = order
        _selectedStatus = State(initialValue: order.status)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(order.title)
                        .font(.headline)
                        .foregroundStyle(TallaAdminStyle.espresso)
                    Text(order.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 8)
                Text(order.total)
                    .font(.subheadline.bold())
                    .foregroundStyle(TallaAdminStyle.espresso)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(TallaAdminStyle.cream, in: Capsule())
            }

            HStack {
                Text(order.status)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.12), in: Capsule())
                Spacer()
                Label("\(order.itemCount)", systemImage: "bag.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !order.items.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(order.items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name)
                            Spacer()
                            Text("×\(item.quantity)")
                                .fontWeight(.semibold)
                                .foregroundStyle(TallaAdminStyle.caramel)
                        }
                    }
                }
                .font(.subheadline)
                .padding(12)
                .background(TallaAdminStyle.paper, in: RoundedRectangle(cornerRadius: 14))
            }

            HStack(spacing: 12) {
                Label(order.createdDate?.formatted(date: .abbreviated, time: .shortened) ?? order.createdAt,
                      systemImage: "clock")
                Spacer()
                Text(order.id)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 10) {
                Picker("Status", selection: $selectedStatus) {
                    ForEach(AdminOrderStatus.all, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

                Button { saveStatus() } label: {
                    if isSaving { ProgressView() } else { Text("Save") }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSaving || isNotifying || selectedStatus == order.status)

                if order.isActive {
                    Button {
                        showNotifyConfirmation = true
                    } label: {
                        if isNotifying {
                            ProgressView()
                        } else {
                            Label("Alert", systemImage: "bell.fill")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isSaving || isNotifying)
                    .accessibilityLabel("Send pickup-ready alert")
                }
            }
        }
        .padding(16)
        .background(TallaAdminStyle.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(TallaAdminStyle.border.opacity(0.4)))
        .shadow(color: TallaAdminStyle.espresso.opacity(0.05), radius: 10, y: 4)
        .onChange(of: order.status) { _, value in selectedStatus = value }
        .confirmationDialog(
            "Notify this customer?",
            isPresented: $showNotifyConfirmation,
            titleVisibility: .visible
        ) {
            Button("Send Pickup-Ready Alert") { notifyCustomer() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This sends a push notification to \(order.email).")
        }
    }

    private var statusColor: Color {
        switch order.status.lowercased() {
        case "ready", "completed", "fulfilled", "delivered": TallaAdminStyle.success
        case "cancelled", "canceled": .red
        case "pending": TallaAdminStyle.warning
        default: TallaAdminStyle.caramel
        }
    }

    private func saveStatus() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            await session.updateOrder(order, status: selectedStatus)
            isSaving = false
        }
    }

    private func notifyCustomer() {
        guard !isNotifying else { return }
        isNotifying = true
        Task {
            await session.notifyReady(order)
            isNotifying = false
        }
    }
}
