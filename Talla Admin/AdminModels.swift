import Foundation

struct AdminOrder: Codable, Identifiable, Hashable {
    let id: String
    let email: String
    let title: String
    let total: String
    var status: String
    let items: [AdminOrderItem]
    let createdAt: String
    let beansAwarded: Bool?
    let pointsAwarded: Int?
    let customer: AdminOrderCustomer?
    let fulfillment: AdminOrderFulfillment?
    let payment: AdminOrderPayment?
    let source: String?
    let updatedAt: String?

    var createdDate: Date? { ISO8601DateFormatter().date(from: createdAt) }
    var updatedDate: Date? { updatedAt.flatMap { ISO8601DateFormatter().date(from: $0) } }
    var itemCount: Int { items.reduce(0) { $0 + max(0, $1.quantity) } }
    var isCancelled: Bool {
        let normalized = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "cancelled" || normalized == "canceled"
    }
    var isCompleted: Bool {
        ["completed", "fulfilled", "delivered"].contains(
            status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        )
    }
    var isActive: Bool { !isCancelled && !isCompleted }
}

struct AdminOrderItem: Codable, Hashable {
    let name: String
    let quantity: Int
    let variantID: String?
    let sku: String?
    let unitPrice: String?

    init(name: String, quantity: Int, variantID: String? = nil, sku: String? = nil, unitPrice: String? = nil) {
        self.name = name
        self.quantity = quantity
        self.variantID = variantID
        self.sku = sku
        self.unitPrice = unitPrice
    }

    private enum CodingKeys: String, CodingKey {
        case name, quantity, sku, unitPrice
        case variantID = "variantId"
    }
}

struct AdminOrderCustomer: Codable, Hashable {
    let fullName: String?
    let email: String
    let phone: String?
}

struct AdminOrderFulfillment: Codable, Hashable {
    let method: String?
    let fullName: String?
    let phone: String?
    let line1: String?
    let city: String?
    let countryCode: String?
    let notes: String?

    var addressText: String? {
        let parts = [line1, city, countryCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct AdminOrderPayment: Codable, Hashable {
    let method: String?
    let provider: String?
    let status: String?
    let amount: String?
    let currency: String?
    let reference: String?
    let paidAt: String?

    var paidDate: Date? { paidAt.flatMap { ISO8601DateFormatter().date(from: $0) } }
}

struct AdminOrdersResponse: Codable {
    let orders: [AdminOrder]
}

struct AdminOrderDetailResponse: Codable {
    let order: AdminOrder
}

struct AdminLoginResponse: Codable {
    let authenticated: Bool
    let username: String?
    let expiresAt: String?
}

struct AdminStatusUpdateResponse: Codable {
    let order: AdminOrder?
    let orders: [AdminOrder]?
}

struct AdminNotifyReadyResponse: Codable {
    let push: AdminPushDeliveryResult
}

struct AdminPushDeliveryResult: Codable {
    let configured: Bool
    let targetCount: Int
    let sentCount: Int
}

struct AdminPushRegistrationResponse: Codable {
    let status: String
    let configured: Bool?
}

enum AdminOrderStatus {
    static let all = [
        "Pending", "Confirmed", "Preparing", "Roasting", "Resting", "Packed",
        "On its way", "Ready", "Completed", "Fulfilled", "Delivered", "Cancelled"
    ]
}

enum AdminAPIError: LocalizedError {
    case unauthorized
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: "Your admin session expired. Please sign in again."
        case .invalidResponse: "The admin server returned an invalid response."
        case .server(let message): message
        }
    }
}
