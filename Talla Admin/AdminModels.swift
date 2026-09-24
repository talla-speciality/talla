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
    let coffeeClub: AdminCoffeeClub?
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

struct AdminCoffeeClub: Codable, Hashable {
    let shipmentCount: Int
    let intervalWeeks: Int
    let discountPercent: Int
    let deliveredShipments: Int
    let remainingShipments: Int
    let shipments: [AdminCoffeeClubShipment]
    let status: String
    let startedAt: String?
    let nextShipmentAt: String?
    let nextShipmentNumber: Int?
    let changesEffectiveFromShipment: Int?
    let isOverdue: Bool
    let cancellationRequestedAt: String?
    let cancellationReason: String?
    let refundStatus: String
    let refundAmount: Double
    let refundNote: String?
    let coffeeItems: [AdminCoffeeClubItem]
    let preference: AdminCoffeeClubPreference?
    let fulfillmentOverride: AdminCoffeeClubFulfillment?

    init(
        shipmentCount: Int,
        intervalWeeks: Int,
        discountPercent: Int,
        deliveredShipments: Int = 0,
        remainingShipments: Int? = nil,
        shipments: [AdminCoffeeClubShipment] = [],
        status: String = "active",
        startedAt: String? = nil,
        nextShipmentAt: String? = nil,
        nextShipmentNumber: Int? = nil,
        changesEffectiveFromShipment: Int? = nil,
        isOverdue: Bool = false,
        cancellationRequestedAt: String? = nil,
        cancellationReason: String? = nil,
        refundStatus: String = "none",
        refundAmount: Double = 0,
        refundNote: String? = nil,
        coffeeItems: [AdminCoffeeClubItem] = [],
        preference: AdminCoffeeClubPreference? = nil,
        fulfillmentOverride: AdminCoffeeClubFulfillment? = nil
    ) {
        self.shipmentCount = shipmentCount
        self.intervalWeeks = intervalWeeks
        self.discountPercent = discountPercent
        self.deliveredShipments = min(shipmentCount, max(0, deliveredShipments))
        self.remainingShipments = min(
            shipmentCount,
            max(0, remainingShipments ?? (shipmentCount - self.deliveredShipments))
        )
        self.shipments = shipments
        self.status = status
        self.startedAt = startedAt
        self.nextShipmentAt = nextShipmentAt
        self.nextShipmentNumber = nextShipmentNumber
        self.changesEffectiveFromShipment = changesEffectiveFromShipment
        self.isOverdue = isOverdue
        self.cancellationRequestedAt = cancellationRequestedAt
        self.cancellationReason = cancellationReason
        self.refundStatus = refundStatus
        self.refundAmount = refundAmount
        self.refundNote = refundNote
        self.coffeeItems = coffeeItems
        self.preference = preference
        self.fulfillmentOverride = fulfillmentOverride
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let count = try values.decode(Int.self, forKey: .shipmentCount)
        self.init(
            shipmentCount: count,
            intervalWeeks: try values.decode(Int.self, forKey: .intervalWeeks),
            discountPercent: try values.decode(Int.self, forKey: .discountPercent),
            deliveredShipments: try values.decodeIfPresent(Int.self, forKey: .deliveredShipments) ?? 0,
            remainingShipments: try values.decodeIfPresent(Int.self, forKey: .remainingShipments),
            shipments: try values.decodeIfPresent([AdminCoffeeClubShipment].self, forKey: .shipments) ?? [],
            status: try values.decodeIfPresent(String.self, forKey: .status) ?? "active",
            startedAt: try values.decodeIfPresent(String.self, forKey: .startedAt),
            nextShipmentAt: try values.decodeIfPresent(String.self, forKey: .nextShipmentAt),
            nextShipmentNumber: try values.decodeIfPresent(Int.self, forKey: .nextShipmentNumber),
            changesEffectiveFromShipment: try values.decodeIfPresent(Int.self, forKey: .changesEffectiveFromShipment),
            isOverdue: try values.decodeIfPresent(Bool.self, forKey: .isOverdue) ?? false,
            cancellationRequestedAt: try values.decodeIfPresent(String.self, forKey: .cancellationRequestedAt),
            cancellationReason: try values.decodeIfPresent(String.self, forKey: .cancellationReason),
            refundStatus: try values.decodeIfPresent(String.self, forKey: .refundStatus) ?? "none",
            refundAmount: try values.decodeIfPresent(Double.self, forKey: .refundAmount) ?? 0,
            refundNote: try values.decodeIfPresent(String.self, forKey: .refundNote),
            coffeeItems: try values.decodeIfPresent([AdminCoffeeClubItem].self, forKey: .coffeeItems) ?? [],
            preference: try values.decodeIfPresent(AdminCoffeeClubPreference.self, forKey: .preference),
            fulfillmentOverride: try values.decodeIfPresent(AdminCoffeeClubFulfillment.self, forKey: .fulfillmentOverride)
        )
    }

    var nextShipmentDate: Date? { nextShipmentAt.flatMap { ISO8601DateFormatter().date(from: $0) } }
}

struct AdminCoffeeClubShipment: Codable, Hashable {
    let number: Int
    let scheduledAt: String?
    let preparedAt: String?
    let preparedBy: String?
    let deliveredAt: String?
    let deliveredBy: String?

    init(number: Int, scheduledAt: String? = nil, preparedAt: String? = nil, preparedBy: String? = nil, deliveredAt: String? = nil, deliveredBy: String? = nil) {
        self.number = number
        self.scheduledAt = scheduledAt
        self.preparedAt = preparedAt
        self.preparedBy = preparedBy
        self.deliveredAt = deliveredAt
        self.deliveredBy = deliveredBy
    }

    var deliveredDate: Date? { deliveredAt.flatMap { ISO8601DateFormatter().date(from: $0) } }
    var preparedDate: Date? { preparedAt.flatMap { ISO8601DateFormatter().date(from: $0) } }
}

struct AdminCoffeeClubItem: Codable, Hashable, Identifiable {
    let coffeeName: String?
    let variantId: String?
    let quantity: Int

    var id: String {
        "\(coffeeName ?? "coffee")-\(variantId ?? "default")"
    }
}

struct AdminCoffeeClubPreference: Codable, Hashable {
    let coffeeName: String?
    let variantId: String?
}

struct AdminCoffeeClubFulfillment: Codable, Hashable {
    let method: String?
    let fullName: String?
    let phone: String?
    let line1: String?
    let city: String?
    let countryCode: String?
    let notes: String?
    let pickupSlot: String?

    init(
        method: String? = nil,
        fullName: String? = nil,
        phone: String? = nil,
        line1: String? = nil,
        city: String? = nil,
        countryCode: String? = nil,
        notes: String? = nil,
        pickupSlot: String? = nil
    ) {
        self.method = method
        self.fullName = fullName
        self.phone = phone
        self.line1 = line1
        self.city = city
        self.countryCode = countryCode
        self.notes = notes
        self.pickupSlot = pickupSlot
    }

    var addressText: String? {
        let text = [line1, city, countryCode].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        return text.isEmpty ? nil : text
    }
}

struct AdminOrderItem: Codable, Hashable {
    let name: String
    let quantity: Int
    let variantID: String?
    let sku: String?
    let unitPrice: String?
    let productTitle: String?
    let variantTitle: String?
    let selectedOptions: [AdminOrderItemOption]?

    var displayName: String {
        let title = productTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? name : title
    }

    var variantDescription: String? {
        let options = (selectedOptions ?? []).compactMap { option -> String? in
            let name = option.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = option.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !value.isEmpty else { return nil }
            if name.lowercased() == "title" { return value.lowercased() == "default title" ? nil : value }
            return "\(name): \(value)"
        }
        if !options.isEmpty { return options.joined(separator: " · ") }
        let title = variantTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty || title.lowercased() == "default title" ? nil : title
    }

    init(name: String, quantity: Int, variantID: String? = nil, sku: String? = nil, unitPrice: String? = nil, productTitle: String? = nil, variantTitle: String? = nil, selectedOptions: [AdminOrderItemOption]? = nil) {
        self.name = name
        self.quantity = quantity
        self.variantID = variantID
        self.sku = sku
        self.unitPrice = unitPrice
        self.productTitle = productTitle
        self.variantTitle = variantTitle
        self.selectedOptions = selectedOptions
    }

    private enum CodingKeys: String, CodingKey {
        case name, quantity, sku, unitPrice, productTitle, variantTitle, selectedOptions
        case variantID = "variantId"
    }
}

struct AdminOrderItemOption: Codable, Hashable {
    let name: String
    let value: String
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
