import SwiftUI
import UIKit

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
                                    NavigationLink {
                                        OrderDetailView(orderID: order.id)
                                    } label: {
                                        OrderCard(order: order)
                                    }
                                    .buttonStyle(.plain)
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
    let order: AdminOrder

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

            HStack {
                Label(order.payment?.method ?? "Payment details", systemImage: "creditcard.fill")
                Spacer()
                Text("View order")
                Image(systemName: "chevron.right")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TallaAdminStyle.caramel)
        }
        .padding(16)
        .background(TallaAdminStyle.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(TallaAdminStyle.border.opacity(0.4)))
        .shadow(color: TallaAdminStyle.espresso.opacity(0.05), radius: 10, y: 4)
    }

    private var statusColor: Color {
        switch order.status.lowercased() {
        case "ready", "completed", "fulfilled", "delivered": TallaAdminStyle.success
        case "cancelled", "canceled": .red
        case "pending": TallaAdminStyle.warning
        default: TallaAdminStyle.caramel
        }
    }

}

private struct OrderDetailView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.openURL) private var openURL
    let orderID: String

    @State private var selectedStatus = ""
    @State private var pendingStatus: String?
    @State private var isSaving = false
    @State private var isNotifying = false
    @State private var showStatusConfirmation = false
    @State private var showNotifyConfirmation = false

    private var order: AdminOrder? { session.orders.first { $0.id == orderID } }

    var body: some View {
        Group {
            if let order {
                ScrollView {
                    VStack(spacing: 16) {
                        overview(order)
                        customerSection(order)
                        fulfillmentSection(order)
                        paymentSection(order)
                        itemsSection(order)
                        statusSection(order)
                        identifiersSection(order)
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await session.refreshOrders()
                    await session.refreshOrderDetail(id: orderID)
                }
                .background(TallaAdminStyle.background)
                .navigationTitle(order.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                UIPasteboard.general.string = order.id
                                session.message = "Order number copied."
                            } label: {
                                Label("Copy order number", systemImage: "doc.on.doc")
                            }
                            Button { Task { await session.refreshOrders() } } label: {
                                Label("Refresh order", systemImage: "arrow.clockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .task(id: orderID) { await session.refreshOrderDetail(id: orderID) }
                .onAppear { selectedStatus = order.status }
                .onChange(of: order.status) { _, value in selectedStatus = value }
                .confirmationDialog(
                    statusDialogTitle,
                    isPresented: $showStatusConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(statusActionTitle, role: pendingStatusIsDestructive ? .destructive : nil) {
                        applyPendingStatus(to: order)
                    }
                    Button("Cancel", role: .cancel) { pendingStatus = nil }
                } message: {
                    Text(statusDialogMessage(for: order))
                }
                .confirmationDialog(
                    "Send pickup-ready notification?",
                    isPresented: $showNotifyConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Send Notification") { notifyCustomer(order) }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This sends a notification to \(order.customer?.fullName ?? order.email). It does not change the order status.")
                }
            } else {
                ContentUnavailableView(
                    "Order unavailable",
                    systemImage: "shippingbox",
                    description: Text("Refresh Orders and try again.")
                )
            }
        }
        .safeAreaInset(edge: .bottom) { OrderFeedbackBanner() }
    }

    private func overview(_ order: AdminOrder) -> some View {
        AdminDetailCard(title: "Order overview", icon: "receipt.fill") {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.title)
                        .font(.title3.bold())
                    Text(order.createdDate?.formatted(date: .long, time: .shortened) ?? order.createdAt)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(order.total)
                    .font(.headline)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(TallaAdminStyle.cream, in: Capsule())
            }
            HStack {
                statusBadge(order.status)
                Spacer()
                Label("\(order.itemCount) item\(order.itemCount == 1 ? "" : "s")", systemImage: "bag.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("Completion is manual. A successful payment confirms an order but does not complete it.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func customerSection(_ order: AdminOrder) -> some View {
        let customer = order.customer
        return AdminDetailCard(title: "Customer", icon: "person.crop.circle.fill") {
            detailRow("Name", customer?.fullName ?? "Not provided")
            detailRow("Email", customer?.email ?? order.email, selectable: true)
            detailRow("Phone", customer?.phone ?? order.fulfillment?.phone ?? "Not provided", selectable: true)

            HStack(spacing: 10) {
                if let emailURL = URL(string: "mailto:\(customer?.email ?? order.email)") {
                    Button { openURL(emailURL) } label: { Label("Email", systemImage: "envelope.fill") }
                        .buttonStyle(.bordered)
                }
                if let phone = customer?.phone ?? order.fulfillment?.phone,
                   let phoneURL = telephoneURL(phone) {
                    Button { openURL(phoneURL) } label: { Label("Call", systemImage: "phone.fill") }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private func fulfillmentSection(_ order: AdminOrder) -> some View {
        let fulfillment = order.fulfillment
        return AdminDetailCard(title: "Fulfilment", icon: fulfillmentIcon(fulfillment?.method)) {
            detailRow("Method", displayFulfillmentMethod(fulfillment?.method, fallback: order.title))
            if let name = fulfillment?.fullName, !name.isEmpty { detailRow("Recipient", name) }
            if let address = fulfillment?.addressText { detailRow("Address", address, selectable: true) }
            if let notes = fulfillment?.notes, !notes.isEmpty { detailRow("Delivery notes", notes, selectable: true) }
            if let address = fulfillment?.addressText,
               let mapURL = mapsURL(address) {
                Button { openURL(mapURL) } label: { Label("Open in Maps", systemImage: "map.fill") }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func paymentSection(_ order: AdminOrder) -> some View {
        AdminDetailCard(title: "Payment", icon: "creditcard.fill") {
            if let payment = order.payment {
                detailRow("Method", payment.method ?? "Not recorded")
                detailRow("Payment status", payment.status ?? "Not recorded")
                if let provider = payment.provider, !provider.isEmpty { detailRow("Provider", provider) }
                if let amount = payment.amount {
                    detailRow("Amount", [payment.currency, amount].compactMap { $0 }.joined(separator: " "))
                }
                if let reference = payment.reference, !reference.isEmpty {
                    detailRow("Reference", reference, selectable: true)
                }
                if let paidDate = payment.paidDate {
                    detailRow("Paid", paidDate.formatted(date: .abbreviated, time: .shortened))
                }
            } else {
                detailRow("Method", "Not recorded for this order")
                detailRow("Order total", order.total)
            }
        }
    }

    private func itemsSection(_ order: AdminOrder) -> some View {
        AdminDetailCard(title: "Products", icon: "bag.fill") {
            ForEach(Array(order.items.enumerated()), id: \.offset) { index, item in
                if index > 0 { Divider() }
                HStack(alignment: .top, spacing: 12) {
                    Text("\(item.quantity)×")
                        .font(.headline)
                        .foregroundStyle(TallaAdminStyle.caramel)
                        .frame(minWidth: 30, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name).fontWeight(.semibold)
                        if let sku = item.sku, !sku.isEmpty { Text("SKU \(sku)").font(.caption).foregroundStyle(.secondary) }
                        if let price = item.unitPrice, !price.isEmpty { Text(price).font(.caption).foregroundStyle(.secondary) }
                    }
                    Spacer()
                }
            }
        }
    }

    private func statusSection(_ order: AdminOrder) -> some View {
        AdminDetailCard(title: "Manage order", icon: "slider.horizontal.3") {
            Picker("New status", selection: $selectedStatus) {
                ForEach(AdminOrderStatus.all, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)

            Button {
                pendingStatus = selectedStatus
                showStatusConfirmation = true
            } label: {
                if isSaving { ProgressView().frame(maxWidth: .infinity) }
                else { Label("Apply Status Change", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving || isNotifying || selectedStatus == order.status)

            if order.isActive {
                Button { showNotifyConfirmation = true } label: {
                    if isNotifying { ProgressView().frame(maxWidth: .infinity) }
                    else { Label("Send Pickup-Ready Notification", systemImage: "bell.fill").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isSaving || isNotifying)
            }
        }
    }

    private func identifiersSection(_ order: AdminOrder) -> some View {
        AdminDetailCard(title: "Record", icon: "number.square.fill") {
            detailRow("Order number", order.id, selectable: true)
            detailRow("Source", order.source ?? (order.id.hasPrefix("shopify_") ? "Shopify" : "Talla app"))
            detailRow("Created", order.createdDate?.formatted(date: .complete, time: .standard) ?? order.createdAt)
            if let updated = order.updatedDate {
                detailRow("Last updated", updated.formatted(date: .complete, time: .standard))
            }
            detailRow("Loyalty awarded", order.beansAwarded == true ? "Yes — \(order.pointsAwarded ?? 0) Beans" : "No")
        }
    }

    private func applyPendingStatus(to order: AdminOrder) {
        guard let status = pendingStatus, !isSaving else { return }
        isSaving = true
        Task {
            await session.updateOrder(order, status: status)
            pendingStatus = nil
            isSaving = false
        }
    }

    private func notifyCustomer(_ order: AdminOrder) {
        guard !isNotifying else { return }
        isNotifying = true
        Task {
            await session.notifyReady(order)
            isNotifying = false
        }
    }

    private var pendingStatusIsDestructive: Bool {
        guard let status = pendingStatus?.lowercased() else { return false }
        return status == "cancelled" || status == "canceled"
    }

    private var statusDialogTitle: String {
        switch pendingStatus?.lowercased() {
        case "completed", "fulfilled", "delivered": "Mark this order complete?"
        case "cancelled", "canceled": "Cancel this order?"
        default: "Change order status?"
        }
    }

    private var statusActionTitle: String {
        pendingStatus.map { "Change to \($0)" } ?? "Change Status"
    }

    private func statusDialogMessage(for order: AdminOrder) -> String {
        if ["completed", "fulfilled", "delivered"].contains(pendingStatus?.lowercased() ?? "") {
            return "Only confirm after the order is actually finished. This may award loyalty Beans and move it to Completed."
        }
        return "\(order.title) will move from \(order.status) to \(pendingStatus ?? selectedStatus)."
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(.caption.weight(.bold))
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor(status).opacity(0.12), in: Capsule())
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "ready", "completed", "fulfilled", "delivered": TallaAdminStyle.success
        case "cancelled", "canceled": .red
        case "pending": TallaAdminStyle.warning
        default: TallaAdminStyle.caramel
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String, selectable: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            if selectable {
                Text(value).multilineTextAlignment(.trailing).textSelection(.enabled)
            } else {
                Text(value).multilineTextAlignment(.trailing)
            }
        }
        .font(.subheadline)
    }

    private func displayFulfillmentMethod(_ method: String?, fallback: String) -> String {
        let value = (method ?? "").lowercased()
        if value.contains("pickup") || fallback.lowercased().contains("pickup") { return "Pickup" }
        if value.contains("delivery") || fallback.lowercased().contains("delivery") { return "Delivery" }
        return method?.capitalized ?? "Not recorded"
    }

    private func fulfillmentIcon(_ method: String?) -> String {
        (method ?? "").lowercased().contains("pickup") ? "storefront.fill" : "truck.box.fill"
    }

    private func telephoneURL(_ phone: String) -> URL? {
        let allowed = phone.filter { $0.isNumber || $0 == "+" }
        return allowed.isEmpty ? nil : URL(string: "tel:\(allowed)")
    }

    private func mapsURL(_ address: String) -> URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "q", value: address)]
        return components?.url
    }
}

private struct AdminDetailCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(TallaAdminStyle.espresso)
            Divider()
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(TallaAdminStyle.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(TallaAdminStyle.border.opacity(0.4)))
    }
}
