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

    var createdDate: Date? { ISO8601DateFormatter().date(from: createdAt) }
    var itemCount: Int { items.reduce(0) { $0 + max(0, $1.quantity) } }
}

struct AdminOrderItem: Codable, Hashable {
    let name: String
    let quantity: Int
}

struct AdminOrdersResponse: Codable {
    let orders: [AdminOrder]
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
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The admin server returned an invalid response."
        case .server(let message): message
        }
    }
}
