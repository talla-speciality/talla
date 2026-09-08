import Foundation

// Preserve unknown server fields when editing a document, including nested objects.
indirect enum AdminValue: Codable, Equatable {
    case object([String: AdminValue]), array([AdminValue]), string(String), number(Double), bool(Bool), null
    init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        if box.decodeNil() { self = .null }
        else if let v = try? box.decode(Bool.self) { self = .bool(v) }
        else if let v = try? box.decode(Double.self) { self = .number(v) }
        else if let v = try? box.decode(String.self) { self = .string(v) }
        else if let v = try? box.decode([String: AdminValue].self) { self = .object(v) }
        else { self = .array(try box.decode([AdminValue].self)) }
    }
    func encode(to encoder: Encoder) throws {
        var box = encoder.singleValueContainer()
        switch self {
        case .object(let v): try box.encode(v)
        case .array(let v): try box.encode(v)
        case .string(let v): try box.encode(v)
        case .number(let v): try box.encode(v)
        case .bool(let v): try box.encode(v)
        case .null: try box.encodeNil()
        }
    }
    subscript(_ key: String) -> AdminValue {
        get { if case .object(let v) = self { return v[key] ?? .null }; return .null }
        set { var v = object; v[key] = newValue; self = .object(v) }
    }
    var object: [String: AdminValue] { if case .object(let v) = self { return v }; return [:] }
    var array: [AdminValue] { if case .array(let v) = self { return v }; return [] }
    var text: String {
        switch self {
        case .string(let v): return v
        case .number(let v): return v.formatted(.number.locale(Locale(identifier: "en_US_POSIX")).grouping(.never).precision(.fractionLength(0...8)))
        case .bool(let v): return v ? "Yes" : "No"
        default: return ""
        }
    }
    var flag: Bool { if case .bool(let v) = self { return v }; return false }
    var number: Double { if case .number(let v) = self { return v }; return Double(text) ?? 0 }
    var title: String {
        for key in ["title", "name", "productName", "reward", "detail", "email", "label", "id"] {
            if !self[key].text.isEmpty { return self[key].text }
        }
        return "Details"
    }
    func at(_ path: String) -> AdminValue { path.split(separator: ".").reduce(self) { $0[String($1)] } }
    mutating func set(_ path: String, _ value: AdminValue) {
        var keys = path.split(separator: ".").map(String.init)
        guard let first = keys.first else { self = value; return }
        keys.removeFirst()
        if keys.isEmpty { self[first] = value }
        else { var child = self[first]; child.set(keys.joined(separator: "."), value); self[first] = child }
    }
    func selecting(_ keys: [String]) -> AdminValue {
        .object(Dictionary(uniqueKeysWithValues: keys.map { ($0, self[$0]) }))
    }
    func merging(_ values: [String: AdminValue]) -> AdminValue { .object(object.merging(values) { _, new in new }) }
}

struct AdminField: Identifiable {
    enum Kind { case text, multiline, number, integer, toggle, choice([String]), products(Int, Bool), product, date, words }
    let path: String
    let label: String
    var kind: Kind = .text
    var required = false
    var id: String { path }
    init(_ path: String, _ label: String, _ kind: Kind = .text, required: Bool = false) {
        self.path = path; self.label = label; self.kind = kind; self.required = required
    }
}

struct AdminFieldGroup: Identifiable {
    let title: String
    let fields: [AdminField]
    var id: String { title }
    init(_ title: String, _ fields: [AdminField]) { self.title = title; self.fields = fields }
}

func adminValidated(_ document: AdminValue, fields: [AdminField]) throws -> AdminValue {
    var result = document
    for field in fields {
        let value = document.at(field.path)
        if field.required && value.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AdminAPIError.server("Enter \(field.label.lowercased()).")
        }
        switch field.kind {
        case .number, .integer:
            guard let number = Double(value.text), number.isFinite else { throw AdminAPIError.server("Enter a valid number for \(field.label.lowercased()).") }
            if case .integer = field.kind, number.rounded() != number { throw AdminAPIError.server("\(field.label) must be a whole number.") }
            if ["price", "quantity", "rate", "fulfillment.bahrainRate", "fulfillment.khaleejiCashOnDeliverySurcharge"].contains(field.path), number < 0 { throw AdminAPIError.server("\(field.label) cannot be negative.") }
            if ["expiresInDays", "maximumWeightGrams", "fulfillment.maximumKhaleejiWeightGrams", "loyalty.rewardStep"].contains(field.path), number <= 0 { throw AdminAPIError.server("\(field.label) must be greater than zero.") }
            result.set(field.path, .number(number))
        default: break
        }
        if ["release.minimumSupportedVersion", "release.latestVersion"].contains(field.path), !value.text.isEmpty,
           value.text.range(of: #"^\d+(?:\.\d+){0,3}$"#, options: .regularExpression) == nil {
            throw AdminAPIError.server("\(field.label) must use numbers and dots, such as 2.4.0.")
        }
        if ["accentHex", "secondaryHex"].contains(field.path), !value.text.isEmpty,
           value.text.range(of: #"^#[0-9a-fA-F]{6}$"#, options: .regularExpression) == nil {
            throw AdminAPIError.server("\(field.label) must be a six-digit hex color, such as #C8965A.")
        }
        if field.path.lowercased().contains("url"), !value.text.isEmpty {
            guard let url = URL(string: value.text), ["https", "talla"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else {
                throw AdminAPIError.server("\(field.label) must start with https:// or talla://.")
            }
        }
    }
    return result
}


func adminDate(_ text: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: text) { return date }
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: text)
}

func adminCustomerPath(email: String) -> String {
    var components = URLComponents()
    components.queryItems = [URLQueryItem(name: "email", value: email)]
    // URLSearchParams on the server treats a literal plus as a space.
    return "/admin/api/customer?" + (components.percentEncodedQuery ?? "").replacingOccurrences(of: "+", with: "%2B")
}
