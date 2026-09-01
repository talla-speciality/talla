import SwiftUI

struct AdminRootView: View {
    enum Tab: Hashable { case orders, console, settings }

    @EnvironmentObject private var session: AdminSession
    @State private var selection: Tab = .orders

    var body: some View {
        TabView(selection: $selection) {
            OrderQueueView()
                .tabItem { Label("Orders", systemImage: "shippingbox.fill") }
                .badge(session.orders.filter { !["Completed", "Fulfilled", "Delivered", "Cancelled"].contains($0.status) }.count)
                .tag(Tab.orders)

            AdminConsoleView(url: session.api.baseURL.appending(path: "admin/"))
                .tabItem { Label("Full Admin", systemImage: "rectangle.3.group.fill") }
                .tag(Tab.console)

            AdminSettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: AdminPush.tokenDidChange)) { notification in
            guard let token = notification.object as? String else { return }
            Task { await session.registerPushToken(token) }
        }
        .onReceive(NotificationCenter.default.publisher(for: AdminPush.orderDidArrive)) { _ in
            Task { await session.refreshOrders() }
        }
        .onReceive(NotificationCenter.default.publisher(for: AdminPush.openOrders)) { _ in
            selection = .orders
            Task { await session.refreshOrders() }
        }
        .onOpenURL { url in
            if url.host == "orders" { selection = .orders }
        }
    }
}

private struct AdminSettingsView: View {
    @EnvironmentObject private var session: AdminSession

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Signed in as", value: session.username)
                    LabeledContent("Backend", value: session.api.baseURL.host ?? session.api.baseURL.absoluteString)
                }

                Section("Order notifications") {
                    HStack {
                        Label(session.notificationsEnabled ? "Notifications enabled" : "Notifications off",
                              systemImage: session.notificationsEnabled ? "bell.badge.fill" : "bell.slash.fill")
                        Spacer()
                        Circle()
                            .fill(session.notificationsEnabled ? TallaAdminStyle.success : .secondary)
                            .frame(width: 9, height: 9)
                    }
                    if !session.notificationsEnabled {
                        Button("Enable New-Order Alerts") {
                            Task { await session.enableNotifications() }
                        }
                    }
                    Text("Each admin iPhone registers separately. New orders use the Talla Admin bundle and do not affect customer notifications.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let message = session.message {
                    Section { Label(message, systemImage: "checkmark.circle.fill").foregroundStyle(TallaAdminStyle.success) }
                }
                if let error = session.errorMessage {
                    Section { Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                }

                Section {
                    Button("Sign Out", role: .destructive) { Task { await session.logout() } }
                }
            }
            .navigationTitle("Admin Settings")
        }
    }
}
