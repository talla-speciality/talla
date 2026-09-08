import SwiftUI
import UniformTypeIdentifiers

struct AdminCustomersView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var customers: [AdminValue] = []
    @State private var search = ""
    @State private var tier = "All"
    @State private var account = "All"
    @State private var voucher = "Any"
    @State private var orders = "Any"
    @State private var alerts = "Any"
    @State private var minimum = ""
    @State private var sort = "Newest"
    @State private var loading = false
    @State private var loaded = false
    @State private var error: String?
    @State private var message: String?
    @State private var export: AdminCSVDocument?
    @State private var exporting = false
    private var visible: [AdminValue] {
        customers.filter { row in
            (search.isEmpty || "\(row["firstName"].text) \(row["lastName"].text) \(row["email"].text)".localizedCaseInsensitiveContains(search)) &&
            (tier == "All" || row["loyaltyTier"].text == tier) &&
            (account == "All" || (account == "Active") == (row["isActive"] != .bool(false))) &&
            (minimum.isEmpty || row["pointsBalance"].number >= (Double(minimum) ?? 0)) &&
            matches(voucher, row["hasActiveVoucher"].flag) && matches(orders, row["hasOrders"].flag) && matches(alerts, row["hasStockAlerts"].flag)
        }.sorted { a, b in
            switch sort {
            case "Highest points": return a["pointsBalance"].number > b["pointsBalance"].number
            case "Lowest points": return a["pointsBalance"].number < b["pointsBalance"].number
            case "Name": return a["firstName"].text.localizedStandardCompare(b["firstName"].text) == .orderedAscending
            default: return a["createdAt"].text > b["createdAt"].text
            }
        }
    }
    private func matches(_ choice: String, _ value: Bool) -> Bool { choice == "Any" || (choice == "Yes") == value }
    var body: some View {
        List {
            Section {
                Picker("Accounts", selection: $account) { ForEach(["All", "Active", "Deactivated"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                DisclosureGroup("Filters and sorting") {
                    Picker("Loyalty tier", selection: $tier) { ForEach(["All", "Bronze", "Silver", "Gold"], id: \.self) { Text($0) } }
                    Picker("Active voucher", selection: $voucher) { ForEach(["Any", "Yes", "No"], id: \.self) { Text($0) } }
                    Picker("Has orders", selection: $orders) { ForEach(["Any", "Yes", "No"], id: \.self) { Text($0) } }
                    Picker("Stock alerts", selection: $alerts) { ForEach(["Any", "Yes", "No"], id: \.self) { Text($0) } }
                    TextField("Minimum points", text: $minimum).keyboardType(.numberPad)
                    Picker("Sort", selection: $sort) { ForEach(["Newest", "Highest points", "Lowest points", "Name"], id: \.self) { Text($0) } }
                }
            }
            Section("\(visible.count) customers") {
                if loading && !loaded { ProgressView("Loading customers…") }
                else if visible.isEmpty { ContentUnavailableView("No matching customers", systemImage: "person.2", description: Text("Try another search or filter, or refresh the directory.")) }
                ForEach(visible, id: \.emailID) { customer in
                    NavigationLink {
                        AdminCustomerDetailView(email: customer["email"].text, onChanged: { Task { await load() } })
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(customer.customerName).font(.headline)
                            Text(customer["email"].text).font(.subheadline).foregroundStyle(.secondary)
                            Text("\(customer["loyaltyTier"].text) · \(customer["pointsBalance"].text) Beans\(customer["isActive"] == .bool(false) ? " · Deactivated" : "")").font(.caption).foregroundStyle(TallaAdminStyle.caramel)
                        }.padding(.vertical, 7)
                    }
                }
            }
            if !visible.isEmpty {
                Section("Filtered customers") {
                    NavigationLink("Grant vouchers to \(visible.count) customers") {
                        AdminActionForm(title: "Bulk Vouchers", endpoint: "/admin/api/customers/bulk-voucher", groups: [.init("Voucher", AdminCustomerDetailView.voucherFields)], confirmation: "Grant this voucher to the \(visible.count) customers in this filtered selection.", onSaved: { response in message = "Created \(response["createdCount"].text) vouchers for \(response["requestedCount"].text) requested customers."; Task { await load() } }, document: .object(["emails": .array(visible.map { $0["email"] }), "expiresInDays": .number(30), "points": .number(50)]))
                    }
                    Button("Export filtered customers as CSV") { Task { await exportCSV() } }.disabled(loading)
                }
            }
        }.adminBackground().navigationTitle("Customers").searchable(text: $search, prompt: "Name or email")
        .task { if !loaded { await load() } }.refreshable { await load() }
        .toolbar { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }.disabled(loading).accessibilityLabel("Refresh customers") }
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: message) }
        .fileExporter(isPresented: $exporting, document: export, contentType: .commaSeparatedText, defaultFilename: "talla-customers") { result in
            if case .failure(let failure) = result { error = failure.localizedDescription }
        }
    }
    @MainActor private func load() async {
        guard !loading else { return }; loading = true; error = nil
        defer { loading = false }
        do { customers = try await session.api.document("/admin/api/customers")["customers"].array; loaded = true }
        catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
    @MainActor private func exportCSV() async {
        loading = true; error = nil; defer { loading = false }
        do {
            let data = try await session.api.request("/admin/api/customers/export", method: "POST", body: ["emails": visible.map { $0["email"].text }])
            export = AdminCSVDocument(data: data); exporting = true
        } catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
}

extension AdminValue {
    var emailID: String { self["email"].text }
    var customerName: String {
        let name = "\(self["firstName"].text) \(self["lastName"].text)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? self["email"].text : name
    }
}
struct AdminCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct AdminCustomerDetailView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.dismiss) private var dismiss
    @State var email: String
    let onChanged: () -> Void
    @State private var customer: AdminValue = .object([:])
    @State private var loading = false
    @State private var error: String?
    @State private var message: String?
    @State private var action: CustomerAction?
    private var profile: AdminValue { customer["profile"] }
    static let voucherFields: [AdminField] = [.init("reward", "Reward title", required: true), .init("points", "Points value", .integer), .init("detail", "Detail", .multiline), .init("expiresInDays", "Expires in days", .integer)]
    static let addressFields: [AdminField] = [.init("label", "Label", required: true), .init("fullName", "Full name", required: true), .init("phone", "Phone", required: true), .init("line1", "Address", required: true), .init("city", "City", required: true), .init("notes", "Notes", .multiline), .init("isPreferred", "Preferred address", .toggle)]
    var body: some View {
        List {
            if profile.object.isEmpty {
                if loading { ProgressView("Loading customer…") }
                else { Button("Reload Customer") { Task { await load() } } }
            } else {
                Section("Profile") {
                    AdminRecordRows(record: profile, fields: [.init("firstName", "First name"), .init("lastName", "Last name"), .init("email", "Email"), .init("isActive", "Active")])
                    NavigationLink("Edit profile") {
                        AdminActionForm(title: "Customer Profile", endpoint: "/admin/api/customer/update", groups: [.init("Profile", [.init("firstName", "First name", required: true), .init("lastName", "Last name", required: true), .init("nextEmail", "Email", required: true)])], confirmation: "Save this customer’s profile and email address.", onSaved: { response in email = response["profile"]["email"].text; changed(response) }, document: profile.merging(["currentEmail": .string(email), "nextEmail": .string(email)]))
                    }
                }
                loyaltySection
                addressSection
                Section("Orders") {
                    if customer["orders"].array.isEmpty { Text("No orders yet").foregroundStyle(.secondary) }
                    ForEach(customer["orders"].array, id: \.objectID) { order in
                        NavigationLink {
                            OrderDetailView(orderID: order["id"].text)
                        } label: { VStack(alignment: .leading) { Text(order.title); Text("\(order["total"].text) · \(order["status"].text)").font(.caption).foregroundStyle(.secondary) } }
                    }
                }
                securitySection
                ForEach(Self.historyGroups) { group in
                    let records = customer[group.path].array
                    Section(group.title) {
                        if records.isEmpty { Text("No records yet").foregroundStyle(.secondary) }
                        ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                            DisclosureGroup(record.title) { AdminRecordRows(record: record, fields: group.fields) }
                        }
                    }
                }
            }
        }.adminBackground().navigationTitle(profile.object.isEmpty ? "Customer" : profile.customerName).navigationBarTitleDisplayMode(.inline)
        .disabled(loading)
        .task { if profile.object.isEmpty { await load() } }.refreshable { await load() }
        .toolbar { Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }.disabled(loading).accessibilityLabel("Refresh customer") }
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: message) }
        .confirmationDialog(action?.title ?? "Confirm action", isPresented: Binding(get: { action != nil }, set: { if !$0 { action = nil } }), titleVisibility: .visible, presenting: action) { pending in
            Button(pending.title, role: pending.destructive ? .destructive : nil) { Task { await perform(pending) } }
        } message: { pending in Text(pending.message + "\n\n" + email) }
    }
    private var loyaltySection: some View {
        Section("Loyalty and vouchers") {
            AdminRecordRows(record: customer["loyalty"], fields: [.init("tier", "Tier"), .init("pointsBalance", "Beans"), .init("memberID", "Member ID"), .init("nextReward", "Next reward")])
            NavigationLink("Adjust loyalty Beans") {
                AdminActionForm(title: "Adjust Beans", endpoint: "/admin/api/loyalty/adjust", groups: [.init("Adjustment", [.init("points", "Beans to add or remove", .integer), .init("note", "Reason", required: true)])], confirmation: "Positive amounts add Beans; negative amounts remove them from \(email).", onSaved: changed, document: .object(["email": .string(email), "points": .number(0)]))
            }
            NavigationLink("Create voucher") {
                AdminActionForm(title: "Create Voucher", endpoint: "/admin/api/vouchers/create", groups: [.init("Voucher", Self.voucherFields)], confirmation: "Grant this voucher to \(email).", onSaved: changed, document: .object(["email": .string(email), "points": .number(50), "expiresInDays": .number(30)]))
            }
            ForEach(customer["vouchers"].array, id: \.voucherID) { voucher in
                DisclosureGroup(voucher["reward"].text) {
                    AdminRecordRows(record: voucher, fields: [.init("code", "Code"), .init("detail", "Detail"), .init("status", "Status"), .init("expiresAt", "Expires"), .init("usedAt", "Used")])
                    if voucher["status"].text == "active" { Button("Revoke voucher", role: .destructive) { action = .init(title: "Revoke Voucher", endpoint: "/admin/api/vouchers/revoke", body: voucher.selecting(["code"]), message: "The customer will no longer be able to use this voucher.", destructive: true) } }
                }
            }
        }
    }
    private var addressSection: some View {
        Section("Saved addresses") {
            ForEach(customer["addresses"].array, id: \.objectID) { address in
                NavigationLink(address["label"].text + (address["isPreferred"].flag ? " · Preferred" : "")) {
                    AdminActionForm(title: "Edit Address", endpoint: "/admin/api/customer/address/save", groups: [.init("Address", Self.addressFields)], confirmation: "Update the saved address for \(email).", onSaved: changed, document: address.merging(["email": .string(email), "addressID": address["id"]]))
                }.swipeActions { Button("Delete", role: .destructive) { action = .init(title: "Delete Address", endpoint: "/admin/api/customer/address/delete", body: .object(["email": .string(email), "addressID": address["id"]]), message: "Remove this saved address?", destructive: true) } }
            }
            NavigationLink("Add address") {
                AdminActionForm(title: "Add Address", endpoint: "/admin/api/customer/address/save", groups: [.init("Address", Self.addressFields)], confirmation: "Add this saved address to \(email).", onSaved: changed, document: .object(["email": .string(email), "addressID": .null, "isPreferred": .bool(false)]))
            }
        }
    }
    private var securitySection: some View {
        Section("Account and security") {
            Button("Send Password Reset Email") { action = .init(title: "Send Reset Email", endpoint: "/admin/api/customer/send-reset", body: .object(["email": .string(email)]), message: "Send a password reset email to this customer.") }
            ForEach(customer["sessions"].array, id: \.objectID) { value in
                DisclosureGroup("Session \(value["id"].text)") {
                    AdminRecordRows(record: value, fields: [.init("createdAt", "Created"), .init("expiresAt", "Expires")])
                    Button("Revoke Session", role: .destructive) { action = .init(title: "Revoke Session", endpoint: "/admin/api/customer/session/revoke", body: .object(["email": .string(email), "sessionID": value["id"]]), message: "Sign this session out.", destructive: true) }
                }
            }
            let active = profile["isActive"] != .bool(false)
            Button(active ? "Deactivate Account" : "Reactivate Account", role: active ? .destructive : nil) {
                action = .init(title: active ? "Deactivate Account" : "Reactivate Account", endpoint: "/admin/api/customer/deactivate", body: .object(["email": .string(email), "isActive": .bool(!active)]), message: active ? "Block sign-in and revoke active sessions." : "Allow this customer to sign in again.", destructive: active)
            }
            Button("Delete Customer Account", role: .destructive) {
                action = .init(title: "Delete Account Permanently", endpoint: "/admin/api/customer/delete", body: .object(["email": .string(email)]), message: "Permanently remove the profile, loyalty history, vouchers, orders, addresses, alerts, inbox, and sessions. This cannot be undone.", destructive: true, deletesAccount: true)
            }
        }
    }
    @MainActor private func load() async {
        guard !loading else { return }; loading = true; error = nil; defer { loading = false }
        do { customer = try await session.api.document(adminCustomerPath(email: email)) }
        catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
    private func changed(_ response: AdminValue) { message = "Changes saved."; onChanged(); Task { await load() } }
    @MainActor private func perform(_ action: CustomerAction) async {
        loading = true; error = nil
        do {
            _ = try await session.api.document(action.endpoint, body: action.body)
            loading = false; onChanged()
            if action.deletesAccount { dismiss() } else { await load(); message = "\(action.title) completed." }
        } catch { loading = false; self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
    struct CustomerAction {
        let title: String
        let endpoint: String
        let body: AdminValue
        let message: String
        var destructive = false
        var deletesAccount = false
    }
    static let historyGroups: [AdminHistoryGroup] = [
        .init(path: "tasteMemory", title: "Taste memory", fields: [.init("productName", "Product"), .init("reaction", "Reaction"), .init("updatedAt", "Updated")]),
        .init(path: "timeline", title: "Customer timeline", fields: [.init("title", "Activity"), .init("kind", "Type"), .init("detail", "Detail"), .init("createdAt", "Date")]),
        .init(path: "alerts", title: "Stock alerts", fields: [.init("productName", "Product"), .init("status", "Status")]),
        .init(path: "inbox", title: "Alert inbox", fields: [.init("title", "Title"), .init("detail", "Message")]),
        .init(path: "auditLogs", title: "Admin audit trail", fields: [.init("detail", "Action"), .init("adminUsername", "Admin"), .init("createdAt", "Date")])
    ]
}
extension AdminValue { var voucherID: String { self["code"].text } }
struct AdminHistoryGroup: Identifiable {
    let path: String
    let title: String
    let fields: [AdminField]
    var id: String { path }
}
