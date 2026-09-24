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
                || order.items.contains {
                    $0.displayName.localizedCaseInsensitiveContains(searchText)
                        || ($0.variantDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
                        || ($0.sku?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
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

            if let club = order.coffeeClub {
                Label(
                    "Coffee Club · \(club.deliveredShipments) delivered · \(club.remainingShipments) remaining",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(TallaAdminStyle.caramel)

                ProgressView(value: Double(club.deliveredShipments), total: Double(max(1, club.shipmentCount)))
                    .tint(TallaAdminStyle.caramel)
            }

            if !order.items.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(order.items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.displayName)
                                if let variant = item.variantDescription {
                                    Text(variant).font(.caption).foregroundStyle(TallaAdminStyle.caramel)
                                }
                            }
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

struct OrderDetailView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.openURL) private var openURL
    let orderID: String

    @State private var selectedStatus = ""
    @State private var pendingStatus: String?
    @State private var isSaving = false
    @State private var isNotifying = false
    @State private var showStatusConfirmation = false
    @State private var showNotifyConfirmation = false
    @State private var pendingShipmentAction: String?
    @State private var isUpdatingShipment = false
    @State private var coffeeClubNote = ""
    @State private var refundAmount = ""
    @State private var isEditingClubPreferences = false

    private var order: AdminOrder? { session.orders.first { $0.id == orderID } }

    var body: some View {
        Group {
            if let order {
                ScrollView {
                    VStack(spacing: 16) {
                        overview(order)
                        if order.coffeeClub != nil { coffeeClubSection(order) }
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
                .confirmationDialog(
                    coffeeClubConfirmationTitle,
                    isPresented: Binding(
                        get: { pendingShipmentAction != nil },
                        set: { if !$0 { pendingShipmentAction = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button(coffeeClubConfirmationActionTitle, role: pendingShipmentAction == "cancel" ? .destructive : nil) {
                        updateShipment(order, action: pendingShipmentAction ?? "")
                    }
                    Button("Cancel", role: .cancel) { pendingShipmentAction = nil }
                } message: {
                    if let club = order.coffeeClub {
                        Text(coffeeClubConfirmationMessage(club))
                    }
                }
            } else {
                ContentUnavailableView(
                    "Order unavailable",
                    systemImage: "shippingbox",
                    description: Text("Refresh Orders and try again.")
                )
            }
        }
        .task(id: orderID) { await session.refreshOrderDetail(id: orderID) }
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

    private func coffeeClubSection(_ order: AdminOrder) -> some View {
        AdminDetailCard(title: "Coffee Club", icon: "cup.and.saucer.fill") {
            if let club = order.coffeeClub {
                detailRow("Plan", "\(club.shipmentCount) prepaid shipments")
                detailRow("Schedule", "Every \(club.intervalWeeks) weeks")
                detailRow("Coffee saving", "\(club.discountPercent)%")
                detailRow("Delivered", "\(club.deliveredShipments)")
                detailRow("Remaining", "\(club.remainingShipments)")
                detailRow("Status", club.status.replacingOccurrences(of: "_", with: " ").capitalized)
                if let nextDate = club.nextShipmentDate, club.remainingShipments > 0 {
                    detailRow(
                        club.isOverdue ? "Overdue shipment" : "Next shipment",
                        "#\(club.nextShipmentNumber ?? club.deliveredShipments + 1) · \(nextDate.formatted(date: .abbreviated, time: .omitted))"
                    )
                }
                detailRow("Renewal", "No automatic renewal")
                if club.coffeeItems.isEmpty,
                   let coffee = club.preference?.coffeeName,
                   !coffee.isEmpty {
                    detailRow("Future coffee", coffee)
                }
                if !club.coffeeItems.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("Next shipment coffees")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TallaAdminStyle.espresso)
                        ForEach(Array(club.coffeeItems.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: "cup.and.saucer")
                                    .foregroundStyle(TallaAdminStyle.caramel)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.coffeeName ?? "Coffee")
                                    if let variant = item.variantId, !variant.isEmpty {
                                        Text(variant)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text("×\(item.quantity)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TallaAdminStyle.caramel)
                            }
                        }
                    }
                    .padding(12)
                    .background(TallaAdminStyle.paper, in: RoundedRectangle(cornerRadius: 14))
                }
                if let fulfillment = club.fulfillmentOverride {
                    detailRow("Future fulfilment", displayFulfillmentMethod(fulfillment.method, fallback: "Delivery"))
                    if let slot = fulfillment.pickupSlot, !slot.isEmpty {
                        detailRow("Pickup slot", slot)
                    }
                    if let name = fulfillment.fullName, !name.isEmpty {
                        detailRow("Future recipient", name)
                    }
                    if let address = fulfillment.addressText {
                        detailRow("Future address", address, selectable: true)
                    }
                    if let notes = fulfillment.notes, !notes.isEmpty {
                        detailRow("Future notes", notes, selectable: true)
                    }
                }
                if let effectiveShipment = club.changesEffectiveFromShipment {
                    detailRow("Changes start", "Shipment #\(effectiveShipment)")
                }
                if club.isOverdue {
                    Label("This shipment is overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }

                ProgressView(value: Double(club.deliveredShipments), total: Double(max(1, club.shipmentCount)))
                    .tint(TallaAdminStyle.caramel)

                Button("Edit Future Shipment", systemImage: "slider.horizontal.3") {
                    isEditingClubPreferences = true
                }
                .buttonStyle(.bordered)
                .disabled(isUpdatingShipment || club.remainingShipments <= 0)

                if ["active", "cancel_requested"].contains(club.status), club.remainingShipments > 0 {
                    let nextIsPrepared = club.shipments.contains {
                        $0.number == (club.nextShipmentNumber ?? club.deliveredShipments + 1)
                            && $0.preparedAt != nil && $0.deliveredAt == nil
                    }
                    if !nextIsPrepared {
                        Button("Mark Next Shipment Preparing", systemImage: "flame.fill") {
                            pendingShipmentAction = "prepare"
                        }
                        .buttonStyle(.bordered)
                        .disabled(isUpdatingShipment)
                    }

                    Button {
                        pendingShipmentAction = "deliver"
                    } label: {
                        if isUpdatingShipment { ProgressView().frame(maxWidth: .infinity) }
                        else {
                            Label(
                                club.remainingShipments == 1 ? "Mark Final Shipment Delivered" : "Mark Next Shipment Delivered",
                                systemImage: "shippingbox.and.arrow.backward.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isUpdatingShipment)
                }

                if club.deliveredShipments > 0 {
                    Button("Undo Last Delivery", systemImage: "arrow.uturn.backward") {
                        pendingShipmentAction = "undo"
                    }
                    .buttonStyle(.bordered)
                    .disabled(isUpdatingShipment)
                }

                if let latest = club.shipments.filter({ $0.deliveredAt != nil }).max(by: { $0.number < $1.number }) {
                    detailRow(
                        "Latest delivery",
                        latest.deliveredDate?.formatted(date: .abbreviated, time: .shortened) ?? latest.deliveredAt ?? "Recorded"
                    )
                }

                Divider()
                TextField("Cancellation or refund note", text: $coffeeClubNote, axis: .vertical)

                HStack {
                    if club.status == "paused" {
                        Button("Resume", systemImage: "play.fill") { pendingShipmentAction = "resume" }
                    } else if club.status == "active" {
                        Button("Pause", systemImage: "pause.fill") { pendingShipmentAction = "pause" }
                    }
                    if !["cancelled", "completed"].contains(club.status) {
                        Button("Cancel Plan", systemImage: "xmark.circle", role: .destructive) {
                            pendingShipmentAction = "cancel"
                        }
                    }
                }
                .buttonStyle(.bordered)

                if club.refundStatus != "recorded" {
                    HStack {
                        TextField("Refund BHD", text: $refundAmount)
                            .keyboardType(.decimalPad)
                        Button(club.refundStatus == "none" ? "Review Refund" : "Mark Refund Recorded") {
                            pendingShipmentAction = club.refundStatus == "none" ? "refund_pending" : "record_refund"
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    detailRow("Refund", "BHD \(club.refundAmount.formatted(.number.precision(.fractionLength(3)))) recorded")
                }

                Text("Refund controls record the provider-confirmed refund. They do not move money automatically; complete the refund in the original payment provider first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Delivery is charged separately for every shipment. Shipment progress is visible to the customer in their order history.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $isEditingClubPreferences) {
            if let club = order.coffeeClub {
                AdminCoffeeClubPreferencesEditor(order: order, club: club) { coffeeItems, fulfillment in
                    isEditingClubPreferences = false
                    isUpdatingShipment = true
                    Task {
                        await session.updateCoffeeClubShipment(
                            order,
                            action: "update_preferences",
                            coffeeItems: coffeeItems,
                            fulfillment: fulfillment
                        )
                        isUpdatingShipment = false
                    }
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
                        Text(item.displayName).fontWeight(.semibold)
                        if let variant = item.variantDescription {
                            Text(variant).font(.subheadline).foregroundStyle(TallaAdminStyle.caramel)
                        }
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

    private func updateShipment(_ order: AdminOrder, action: String) {
        let actions = ["prepare", "deliver", "undo", "pause", "resume", "cancel", "refund_pending", "record_refund"]
        guard actions.contains(action) else { return }
        let amount = Double(refundAmount.replacingOccurrences(of: ",", with: "."))
        if action == "record_refund", amount == nil {
            session.errorMessage = "Enter the confirmed refund amount in BHD."
            pendingShipmentAction = nil
            return
        }
        pendingShipmentAction = nil
        isUpdatingShipment = true
        Task {
            await session.updateCoffeeClubShipment(
                order,
                action: action,
                reason: action == "cancel" ? coffeeClubNote : nil,
                note: action.hasPrefix("refund") ? coffeeClubNote : nil,
                amount: action == "record_refund" ? amount : nil
            )
            isUpdatingShipment = false
        }
    }

    private var coffeeClubConfirmationTitle: String {
        switch pendingShipmentAction {
        case "prepare": "Mark shipment as preparing?"
        case "deliver": "Mark this shipment delivered?"
        case "undo": "Undo the latest delivery?"
        case "pause": "Pause this Coffee Club plan?"
        case "resume": "Resume this Coffee Club plan?"
        case "cancel": "Cancel this Coffee Club plan?"
        case "refund_pending": "Start refund review?"
        case "record_refund": "Record the confirmed refund?"
        default: "Update Coffee Club?"
        }
    }

    private var coffeeClubConfirmationActionTitle: String {
        switch pendingShipmentAction {
        case "prepare": "Mark Preparing"
        case "deliver": "Mark Delivered"
        case "undo": "Undo Delivery"
        case "pause": "Pause Plan"
        case "resume": "Resume Plan"
        case "cancel": "Cancel Plan"
        case "refund_pending": "Start Review"
        case "record_refund": "Record Refund"
        default: "Update"
        }
    }

    private func coffeeClubConfirmationMessage(_ club: AdminCoffeeClub) -> String {
        switch pendingShipmentAction {
        case "prepare": "Shipment \(club.nextShipmentNumber ?? club.deliveredShipments + 1) will be marked as preparing and the customer will be notified."
        case "deliver": "Shipment \(club.deliveredShipments + 1) of \(club.shipmentCount) will be recorded as delivered and the customer will be notified."
        case "undo": "Shipment \(club.deliveredShipments) will return to the remaining count."
        case "pause": "The schedule stops until this plan is resumed."
        case "resume": "Future due dates will move forward by the paused duration."
        case "cancel": "Remaining shipments will be cancelled. Record any provider refund separately."
        case "record_refund": "This records a BHD \(refundAmount) refund already completed in the payment provider."
        default: "This Coffee Club plan will be updated."
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

private struct AdminClubItemDraft: Identifiable, Hashable {
    let id: UUID
    var coffeeName: String
    var variantID: String
    var quantity: Int

    init(id: UUID = UUID(), coffeeName: String = "", variantID: String = "", quantity: Int = 1) {
        self.id = id
        self.coffeeName = coffeeName
        self.variantID = variantID
        self.quantity = quantity
    }
}

private struct AdminCoffeeClubPreferencesEditor: View {
    @Environment(\.dismiss) private var dismiss

    let order: AdminOrder
    let club: AdminCoffeeClub
    let onSave: ([[String: Any]], [String: Any]?) -> Void

    @State private var items: [AdminClubItemDraft]
    @State private var fulfillmentMethod: String
    @State private var fullName: String
    @State private var phone: String
    @State private var line1: String
    @State private var city: String
    @State private var countryCode: String
    @State private var notes: String
    @State private var pickupSlot: String

    init(order: AdminOrder, club: AdminCoffeeClub, onSave: @escaping ([[String: Any]], [String: Any]?) -> Void) {
        self.order = order
        self.club = club
        self.onSave = onSave

        let sourceItems = club.coffeeItems.isEmpty
            ? [AdminCoffeeClubItem(coffeeName: club.preference?.coffeeName, variantId: club.preference?.variantId, quantity: 1)]
            : club.coffeeItems
        _items = State(initialValue: sourceItems.map {
            AdminClubItemDraft(
                coffeeName: $0.coffeeName ?? "",
                variantID: $0.variantId ?? "",
                quantity: max(1, $0.quantity)
            )
        })

        let override = club.fulfillmentOverride
        _fulfillmentMethod = State(initialValue: override?.method?.lowercased().contains("pickup") == true ? "pickup" : "delivery")
        _fullName = State(initialValue: override?.fullName ?? order.customer?.fullName ?? "")
        _phone = State(initialValue: override?.phone ?? order.customer?.phone ?? "")
        _line1 = State(initialValue: override?.line1 ?? "")
        _city = State(initialValue: override?.city ?? "")
        _countryCode = State(initialValue: override?.countryCode ?? "BH")
        _notes = State(initialValue: override?.notes ?? "")
        _pickupSlot = State(initialValue: override?.pickupSlot ?? "")
    }

    private var canSave: Bool {
        !items.isEmpty && items.allSatisfy { !$0.coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(items.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 9) {
                            TextField("Coffee name", text: $items[index].coffeeName)
                            TextField("Variant / bag size ID", text: $items[index].variantID)
                            Stepper(value: $items[index].quantity, in: 1...12) {
                                HStack {
                                    Text("Quantity")
                                    Spacer()
                                    Text("×\(items[index].quantity)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if items.count > 1 {
                                Button("Remove coffee", systemImage: "minus.circle", role: .destructive) {
                                    items.remove(at: index)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Button("Add another coffee", systemImage: "plus.circle") {
                        items.append(AdminClubItemDraft())
                    }
                } header: {
                    Text("Next eligible shipment")
                } footer: {
                    Text("Changes apply to the next shipment that has not been prepared. If it is already prepared, they start with the following shipment.")
                }

                Section("Fulfilment") {
                    Picker("Method", selection: $fulfillmentMethod) {
                        Text("Delivery").tag("delivery")
                        Text("Pickup").tag("pickup")
                    }
                    .pickerStyle(.segmented)

                    TextField("Recipient name", text: $fullName)
                    TextField("Phone", text: $phone)

                    if fulfillmentMethod == "pickup" {
                        TextField("Pickup slot", text: $pickupSlot)
                    } else {
                        TextField("Address", text: $line1)
                        TextField("City", text: $city)
                        TextField("Country code", text: $countryCode)
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Edit Coffee Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let coffeeItems: [[String: Any]] = items.map { item in
            [
                "coffeeName": item.coffeeName.trimmingCharacters(in: .whitespacesAndNewlines),
                "variantId": item.variantID.trimmingCharacters(in: .whitespacesAndNewlines),
                "quantity": item.quantity
            ]
        }
        var fulfillment: [String: Any] = [
            "method": fulfillmentMethod,
            "fullName": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "phone": phone.trimmingCharacters(in: .whitespacesAndNewlines),
            "notes": notes.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        if fulfillmentMethod == "pickup" {
            fulfillment["pickupSlot"] = pickupSlot.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            fulfillment["line1"] = line1.trimmingCharacters(in: .whitespacesAndNewlines)
            fulfillment["city"] = city.trimmingCharacters(in: .whitespacesAndNewlines)
            fulfillment["countryCode"] = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
        onSave(coffeeItems, fulfillment)
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
