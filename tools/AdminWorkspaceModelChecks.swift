import Foundation

@main
struct AdminWorkspaceModelChecks {
    static func main() throws {
        var checks = 0
        func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
            precondition(condition(), name); checks += 1
        }
        func rejects(_ value: AdminValue, _ field: AdminField) {
            do { _ = try adminValidated(value, fields: [field]); preconditionFailure("Accepted invalid \(field.label)") }
            catch { checks += 1 }
        }
        let raw = Data(#"{"enabled":true,"count":1,"balance":0,"title":"Coffee","optional":null,"unknown":{"futureFlag":false},"fulfillment":{"rate":2,"tiers":[{"weight":500,"rate":5.5}]}}"#.utf8)
        var value = try JSONDecoder().decode(AdminValue.self, from: raw)
        expect(value["enabled"] == .bool(true), "Booleans remain booleans")
        expect(value["count"] == .number(1), "Numbers must not become booleans")
        expect(value["optional"] == .null, "Preserve explicit nulls")
        value.set("fulfillment.rate", .string("3.125"))
        expect(value.at("fulfillment.tiers").array.count == 1, "Nested edits preserve sibling arrays")
        let validated = try adminValidated(value, fields: [.init("fulfillment.rate", "Rate", .number)])
        expect(validated.at("fulfillment.rate") == .number(3.125), "Convert decimal edits to JSON numbers")
        expect(validated.at("unknown.futureFlag") == .bool(false), "Unknown server fields survive edits")
        let roundTrip = try JSONDecoder().decode(AdminValue.self, from: JSONEncoder().encode(validated))
        expect(roundTrip == validated, "Settings round-trip without data loss")
        rejects(.object(["title": .string(" \n ")]), .init("title", "Title", required: true))
        rejects(.object(["quantity": .string("-1")]), .init("quantity", "Quantity", .integer))
        rejects(.object(["quantity": .string("1.5")]), .init("quantity", "Quantity", .integer))
        rejects(.object(["price": .string("NaN")]), .init("price", "Price", .number))
        rejects(.object(["price": .string("inf")]), .init("price", "Price", .number))
        rejects(.object(["price": .string("-1")]), .init("price", "Price", .number))
        rejects(.object(["price": .string("abc")]), .init("price", "Price", .number))
        rejects(.object(["expiresInDays": .number(0)]), .init("expiresInDays", "Expiry", .integer))
        rejects(.object(["url": .string("javascript:alert(1)")]), .init("url", "Link"))
        rejects(.object(["url": .string("http://example.com")]), .init("url", "Link"))
        rejects(.object(["url": .string("https:")]), .init("url", "Link"))
        let zero = try adminValidated(.object(["quantity": .string("0")]), fields: [.init("quantity", "Quantity", .integer)])
        expect(zero["quantity"] == .number(0), "Zero inventory is valid")
        let deduction = try adminValidated(.object(["points": .string("-25")]), fields: [.init("points", "Beans", .integer)])
        expect(deduction["points"] == .number(-25), "Negative loyalty adjustments remain valid")
        for link in ["", "https://example.com/path", "talla://orders"] {
            _ = try adminValidated(.object(["url": .string(link)]), fields: [.init("url", "Link")]); checks += 1
        }
        let shipping = try adminValidated(.object(["rate": .number(5.5)]), fields: [.init("rate", "Rate", .number)])
        expect(shipping["rate"] == .number(5.5), "Existing numeric values stay valid")
        expect(adminDate("2026-09-08T12:00:00.123Z") != nil, "Parse backend timestamps with fractional seconds")
        expect(adminDate("2026-09-08T12:00:00Z") != nil, "Parse second-resolution timestamps")
        rejects(.object(["release": .object(["latestVersion": .string("next")])]), .init("release.latestVersion", "Version"))
        rejects(.object(["accentHex": .string("blue")]), .init("accentHex", "Accent"))
        expect(adminCustomerPath(email: "coffee+test@example.com").contains("%2B"), "Plus-addressed emails survive URLSearchParams decoding")
        expect(!adminCustomerPath(email: "a&b@example.com").contains("&b"), "Customer emails cannot inject query parameters")
        let oldItem = try JSONDecoder().decode(AdminOrderItem.self, from: Data(#"{"name":"Coffee - Large","quantity":1}"#.utf8))
        expect(oldItem.displayName == "Coffee - Large", "Legacy order names remain visible")
        expect(oldItem.variantDescription == nil, "Do not invent variants for old orders")
        let sizedItem = try JSONDecoder().decode(AdminOrderItem.self, from: Data(#"{"name":"Cup - Large","productTitle":"Cup","quantity":2,"variantTitle":"Large","selectedOptions":[{"name":"Size","value":"Large"}]}"#.utf8))
        expect(sizedItem.displayName == "Cup", "Product name does not repeat variant")
        expect(sizedItem.variantDescription == "Size: Large", "Show purchased size by name")
        let coffee = AdminOrderItem(name: "Coffee", quantity: 1, variantTitle: "250g / Whole Bean")
        expect(coffee.variantDescription == "250g / Whole Bean", "Shopify order snapshot title is displayed")
        let plain = AdminOrderItem(name: "Coffee", quantity: 1, variantTitle: "Default Title", selectedOptions: [.init(name: "Title", value: "Default Title")])
        expect(plain.variantDescription == nil, "Hide default variant placeholders")
        let options = AdminOrderItem(name: "Coffee", quantity: 1, selectedOptions: [.init(name: "Weight", value: "250g"), .init(name: "Grind", value: "Whole Bean")])
        expect(options.variantDescription == "Weight: 250g · Grind: Whole Bean", "Show all purchased options")
        print("Passed \(checks) native admin model checks.")
    }
}
