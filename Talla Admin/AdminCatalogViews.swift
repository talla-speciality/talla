import SwiftUI

struct AdminProductsView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var products: [AdminValue] = []
    @State private var search = ""
    @State private var status = "All"
    @State private var category = "All"
    @State private var sort = "Recently updated"
    @State private var loading = false
    @State private var error: String?
    @State private var loaded = false
    @State private var create = false
    private var visible: [AdminValue] {
        let result = products.filter { product in
            (status == "All" || product["status"].text == status.uppercased()) &&
            (category == "All" || product["productType"].text == category) &&
            (search.isEmpty || product.title.localizedCaseInsensitiveContains(search))
        }
        switch sort {
        case "Name": return result.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case "Lowest price": return result.sorted { $0["price"].number < $1["price"].number }
        case "Lowest stock": return result.sorted { $0["availableQuantity"].number < $1["availableQuantity"].number }
        default: return result
        }
    }
    var body: some View {
        List {
            Section {
                Picker("Status", selection: $status) { ForEach(["All", "Active", "Draft", "Archived"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                Picker("Category", selection: $category) { ForEach(["All"] + Array(Set(products.map { $0["productType"].text })).sorted(), id: \.self) { Text($0) } }
                Picker("Sort", selection: $sort) { ForEach(["Recently updated", "Name", "Lowest price", "Lowest stock"], id: \.self) { Text($0) } }
            }
            Section("\(visible.count) products") {
                if loading && !loaded { ProgressView("Loading products…") }
                else if visible.isEmpty { ContentUnavailableView(search.isEmpty ? "No products" : "No matching products", systemImage: "bag", description: Text(error == nil ? "Try another filter or add a product." : "Reload to try again.")) }
                ForEach(visible, id: \.objectID) { product in
                    NavigationLink {
                        AdminProductDetailView(product: product, onChanged: { Task { await load() } })
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "bag.fill").font(.title2).foregroundStyle(TallaAdminStyle.caramel).frame(width: 35)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(product.title).font(.headline)
                                Text("\(product["productType"].text) · \(product["status"].text.capitalized)").font(.caption).foregroundStyle(.secondary)
                                Text("\(product["price"].text) · \(product["availableQuantity"].text.isEmpty ? "Stock unavailable" : product["availableQuantity"].text + " in stock")").font(.subheadline)
                            }
                        }.padding(.vertical, 7)
                    }
                }
            }
        }.adminBackground().navigationTitle("Products").searchable(text: $search, prompt: "Find a product")
        .refreshable { await load() }
        .task { if !loaded { await load() } }
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: nil) }
        .toolbar {
            Button { Task { await load() } } label: { Image(systemName: "arrow.clockwise") }.disabled(loading).accessibilityLabel("Refresh products")
            Button { create = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add product")
        }
        .sheet(isPresented: $create) {
            NavigationStack {
                AdminActionForm(title: "Add Product", endpoint: "/admin/api/products", groups: [.init("Product", [.init("title", "Title", required: true), .init("productType", "Category", .choice(AdminProductDetailView.categories), required: true), .init("price", "Price", .number, required: true)])], confirmation: "Create this product in the live catalog. Storefront visibility depends on your Shopify publication settings.", onSaved: { _ in Task { await load() } }, document: .object(["price": .string(""), "productType": .string("Coffee Beans")]))
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { create = false } } }
            }
        }
    }
    @MainActor private func load() async {
        guard !loading else { return }; loading = true; error = nil
        defer { loading = false }
        do { products = try await session.api.document("/admin/api/products?limit=250")["products"].array; loaded = true }
        catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
    }
}

struct AdminProductDetailView: View {
    @EnvironmentObject private var session: AdminSession
    @Environment(\.dismiss) private var dismiss
    @State var product: AdminValue
    let onChanged: () -> Void
    @State private var deleting = false
    @State private var busy = false
    @State private var error: String?
    static let categories = ["Coffee Beans", "Arabic Coffee", "Drip Bags", "Cups", "Drinks", "CRMB", "Summer Drinks", "Spreads", "Hot Chocolate", "Coffee Equipment", "Gifts"]
    var body: some View {
        List {
            Section("Overview") {
                AdminRecordRows(record: product, fields: [.init("title", "Product"), .init("productType", "Category"), .init("status", "Status"), .init("price", "Price"), .init("availableQuantity", "Available stock"), .init("availableForSale", "Available for sale"), .init("badge", "Badge")])
            }
            Section("Manage product") {
                NavigationLink("Product details and price") {
                    AdminActionForm(title: "Edit Product", endpoint: "/admin/api/products/update", groups: [.init("Details", productFields)], confirmation: "Save these changes to the live Shopify product.", onSaved: updated, document: editPayload)
                }
                NavigationLink("Add product image") {
                    AdminActionForm(title: "Product Image", endpoint: "/admin/api/products/image", groups: [.init("Image", [.init("imageURL", "Image URL", required: true), .init("altText", "Image description")])], confirmation: "Add this image to the product.", onSaved: updated, document: .object(["id": product["id"]]))
                }
                if !product["inventoryItemID"].text.isEmpty && !product["inventoryLocationID"].text.isEmpty {
                    NavigationLink("Update inventory") {
                        AdminActionForm(title: "Inventory", endpoint: "/admin/api/products/inventory", groups: [.init("Stock", [.init("quantity", "Available quantity", .integer)])], confirmation: "Replace the available quantity at this product’s inventory location. A concurrent stock change will require a refresh.", onSaved: updated, document: .object(["id": product["id"], "inventoryItemID": product["inventoryItemID"], "locationID": product["inventoryLocationID"], "quantity": product["availableQuantity"], "compareQuantity": product["availableQuantity"]]))
                    }
                } else { Text("Inventory editing is unavailable for this product’s location.").font(.footnote).foregroundStyle(.secondary) }
            }
            Section { Button("Delete Product", role: .destructive) { deleting = true } }
        }.adminBackground().navigationTitle(product.title).navigationBarTitleDisplayMode(.inline)
        .disabled(busy)
        .safeAreaInset(edge: .bottom) { AdminFeedback(error: error, message: nil) }
        .confirmationDialog("Permanently delete \(product.title)?", isPresented: $deleting, titleVisibility: .visible) {
            Button("Delete Product", role: .destructive) { Task {
                busy = true; defer { busy = false }
                do { _ = try await session.api.document("/admin/api/products/delete", body: product.selecting(["id"])); onChanged(); dismiss() }
                catch { self.error = error.localizedDescription; if case AdminAPIError.unauthorized = error { session.handle(error) } }
            } }
        } message: { Text("This removes the product from Shopify and cannot be undone.") }
    }
    private var editPayload: AdminValue {
        var result = product.selecting(["id", "title", "productType", "status", "badge", "descriptionHTML", "defaultVariantID"])
        result["existingTags"] = product["tags"]
        if !product["defaultVariantID"].text.isEmpty { result["price"] = product["price"] }
        return result
    }
    private var productFields: [AdminField] {
        var fields: [AdminField] = [.init("title", "Title", required: true), .init("productType", "Category", .choice(Self.categories)), .init("status", "Status", .choice(["ACTIVE", "DRAFT", "ARCHIVED"])), .init("badge", "Badge", .choice(["", "NEW", "BESTSELLER", "LIMITED", "STAFF PICK"])), .init("descriptionHTML", "Description (HTML)", .multiline)]
        if !product["defaultVariantID"].text.isEmpty { fields.append(.init("price", "Price", .number)) }
        return fields
    }
    private func updated(_ response: AdminValue) {
        if !response["product"].object.isEmpty { product = .object(product.object.merging(response["product"].object) { _, new in new }) }
        onChanged()
    }
}
