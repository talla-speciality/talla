import SwiftUI
import Foundation

extension AdminAPI {
    func document(_ path: String, body: AdminValue? = nil) async throws -> AdminValue {
        let payload: [String: Any]?
        if let body {
            guard case .object = body else { throw AdminAPIError.invalidResponse }
            payload = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: Any]
        } else { payload = nil }
        let data = try await request(path, method: body == nil ? "GET" : "POST", body: payload)
        return try JSONDecoder().decode(AdminValue.self, from: data)
    }
}

struct AdminFieldRow: View {
    let field: AdminField
    @Binding var document: AdminValue
    var products: [AdminValue] = []
    private var value: AdminValue { document.at(field.path) }
    private var text: Binding<String> {
        Binding(get: { value.text }, set: { document.set(field.path, .string($0)) })
    }
    var body: some View {
        switch field.kind {
        case .toggle:
            Toggle(field.label, isOn: Binding(get: { value.flag }, set: { document.set(field.path, .bool($0)) }))
        case .choice(let choices):
            Picker(field.label, selection: text) {
                if !choices.contains(value.text) { Text(value.text.isEmpty ? "Choose…" : value.text).tag(value.text) }
                ForEach(choices, id: \.self) { Text($0.isEmpty ? "None" : $0).tag($0) }
            }
        case .products(let limit, let drinksOnly):
            NavigationLink {
                AdminProductPicker(title: field.label, selection: Binding(get: { value.array.map(\.text) }, set: { document.set(field.path, .array($0.map(AdminValue.string))) }), products: products, limit: limit, drinksOnly: drinksOnly)
            } label: { LabeledContent(field.label, value: "\(value.array.count) selected") }
        case .product:
            Picker(field.label, selection: text) {
                Text("Automatic daily pick").tag("")
                if !value.text.isEmpty && !products.contains(where: { $0["id"].text == value.text }) { Text("Previously selected product").tag(value.text) }
                ForEach(products, id: \.objectID) { Text($0["title"].text).tag($0["id"].text) }
            }
        case .date:
            Toggle(field.label, isOn: Binding(get: { !value.text.isEmpty }, set: { document.set(field.path, $0 ? .string(ISO8601DateFormatter().string(from: .now)) : .null) }))
            if !value.text.isEmpty {
                DatePicker(field.label, selection: Binding(get: { adminDate(value.text) ?? .now }, set: { document.set(field.path, .string(ISO8601DateFormatter().string(from: $0))) }))
            }
        case .words:
            VStack(alignment: .leading) {
                Text(field.label).font(.caption).foregroundStyle(.secondary)
                TextField("Comma-separated keywords", text: Binding(get: { value.array.map(\.text).joined(separator: ", ") }, set: { document.set(field.path, .array($0.split(separator: ",").map { .string($0.trimmingCharacters(in: .whitespaces)) })) }), axis: .vertical)
            }
        default:
            VStack(alignment: .leading, spacing: 6) {
                Text(field.label).font(.caption).foregroundStyle(.secondary)
                TextField(field.label, text: text, axis: .vertical)
                    .lineLimit(isMultiline ? 3...8 : 1...3)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(keyboard == .URL || keyboard == .emailAddress ? .never : .sentences)
                    .autocorrectionDisabled(keyboard == .URL || keyboard == .emailAddress)
            }.padding(.vertical, 3)
        }
    }
    private var isMultiline: Bool { if case .multiline = field.kind { return true }; return false }
    private var keyboard: UIKeyboardType {
        switch field.kind {
        case .number: return .decimalPad
        case .integer: return .numbersAndPunctuation
        default: return field.path.lowercased().contains("url") ? .URL : field.path.lowercased().contains("email") ? .emailAddress : .default
        }
    }
}

struct AdminProductPicker: View {
    let title: String
    @Binding var selection: [String]
    let products: [AdminValue]
    let limit: Int
    let drinksOnly: Bool
    @State private var search = ""
    var body: some View {
        List {
            Section {
                Text("\(selection.count) of \(limit) selected").foregroundStyle(.secondary)
                if products.isEmpty { Text("Products are unavailable. Go back and reload to try again. Your current selections are preserved.") }
                ForEach(selection.filter { id in !products.contains { $0["id"].text == id } }, id: \.self) { id in
                    Button("Remove unavailable product: \(id)", role: .destructive) { selection.removeAll { $0 == id } }
                }
                ForEach(products.filter { product in
                    (!drinksOnly || ["drinks", "summer drinks"].contains(product["productType"].text.lowercased())) && (search.isEmpty || product.title.localizedCaseInsensitiveContains(search))
                }, id: \.objectID) { product in
                    let id = product["id"].text
                    Toggle(isOn: Binding(get: { selection.contains(id) }, set: { selected in
                        if selected && !selection.contains(id) && selection.count < limit { selection.append(id) }
                        else if !selected { selection.removeAll { $0 == id } }
                    })) {
                        VStack(alignment: .leading) {
                            Text(product.title)
                            Text(product["productType"].text).font(.caption).foregroundStyle(.secondary)
                        }
                    }.disabled(!selection.contains(id) && selection.count >= limit)
                }
            }
        }.navigationTitle(title).searchable(text: $search).adminBackground()
    }
}

extension AdminValue { var objectID: String { self["id"].text.isEmpty ? title : self["id"].text } }

struct AdminFeedback: View {
    let error: String?
    let message: String?
    var body: some View {
        if let text = error ?? message {
            Label(text, systemImage: error == nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.footnote).foregroundStyle(error == nil ? TallaAdminStyle.success : .red)
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial).accessibilityIdentifier("admin-feedback")
        }
    }
}

extension View {
    func adminBackground() -> some View { scrollContentBackground(.hidden).background(TallaAdminStyle.background) }
}

// Presents only explicit, human-readable fields; never exposes raw API documents.
struct AdminRecordRows: View {
    let record: AdminValue
    let fields: [AdminField]
    var body: some View {
        ForEach(fields) { field in
            let value = record.at(field.path)
            if !value.text.isEmpty {
                LabeledContent(field.label) { Text(display(value, field: field)).multilineTextAlignment(.trailing).textSelection(.enabled) }
            }
        }
    }
    private func display(_ value: AdminValue, field: AdminField) -> String {
        if field.path.hasSuffix("At"), let date = adminDate(value.text) { return date.formatted(date: .abbreviated, time: .shortened) }
        if field.path == "reaction" { return value.text == "loved" ? "Loved it" : "Not for me" }
        return value.text
    }
}

struct AdminActionForm: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.dismiss) private var dismiss
    let title: String
    let endpoint: String
    let groups: [AdminFieldGroup]
    let confirmation: String
    var onSaved: (AdminValue) -> Void = { _ in }
    @State var document: AdminValue
    @State private var error: String?
    @State private var saving = false
    @State private var confirming = false
    var body: some View {
        Form {
            ForEach(groups) { group in
                Section(group.title) { ForEach(group.fields) { AdminFieldRow(field: $0, document: $document) } }
            }
            Section { Text(confirmation).font(.footnote).foregroundStyle(.secondary) }
        }
        .adminBackground().navigationTitle(title).navigationBarTitleDisplayMode(.inline)
        .disabled(saving)
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: nil) }
        .toolbar { Button(saving ? "Saving…" : "Save") {
            do { document = try adminValidated(document, fields: groups.flatMap(\.fields)); confirming = true }
            catch { self.error = error.localizedDescription }
        }.disabled(saving) }
        .confirmationDialog(title, isPresented: $confirming, titleVisibility: .visible) {
            Button("Confirm") { Task { await save() } }
        } message: { Text(confirmation) }
        .interactiveDismissDisabled(saving)
    }
    @MainActor private func save() async {
        saving = true; error = nil
        defer { saving = false }
        do {
            if endpoint.contains("voucher"), document["points"].number <= 0 { throw AdminAPIError.server("Voucher points must be greater than zero.") }
            if endpoint.hasSuffix("loyalty/adjust"), document["points"].number == 0 { throw AdminAPIError.server("Enter a positive or negative Beans adjustment.") }
            let result = try await session.api.document(endpoint, body: document); onSaved(result); dismiss()
        }
        catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
}
