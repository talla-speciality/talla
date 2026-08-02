import Foundation
import SwiftUI
#if canImport(PassKit)
import PassKit
#endif

enum TallaPaymentMethod: String, CaseIterable, Identifiable {
    case benefit
    case card
    case applePay
    case clickToPay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .benefit: return "BENEFIT"
        case .card: return "Credit or Debit Card"
        case .applePay: return "Apple Pay"
        case .clickToPay: return "Click to Pay"
        }
    }

    var systemImage: String {
        switch self {
        case .benefit: return "checkmark.shield.fill"
        case .card: return "creditcard.fill"
        case .applePay: return "apple.logo"
        case .clickToPay: return "cursorarrow.click.2"
        }
    }
}

enum TallaPaymentState: String, Equatable {
    case idle
    case creatingSession
    case awaitingCustomer
    case authenticating
    case processing
    case succeeded
    case failed
    case cancelled

    var isBusy: Bool {
        [.creatingSession, .authenticating, .processing].contains(self)
    }
}

@MainActor
final class PaymentFlowModel: ObservableObject {
    @Published var selectedMethod: TallaPaymentMethod = .benefit
    @Published private(set) var state: TallaPaymentState = .idle
    @Published private(set) var errorMessage: String?

    var canStart: Bool { !state.isBusy && state != .awaitingCustomer }

    func transition(to nextState: TallaPaymentState, error: String? = nil) {
        guard nextState != state || error != errorMessage else { return }
        state = nextState
        errorMessage = error
    }

    func begin() -> Bool {
        guard canStart else { return false }
        transition(to: .creatingSession)
        return true
    }

    func cancel() {
        guard state != .succeeded else { return }
        transition(to: .cancelled)
    }

    func reset() {
        transition(to: .idle)
    }
}

enum MastercardSDKAvailability {
    static var isAvailable: Bool {
#if canImport(Gateway) && canImport(uSDK)
        true
#else
        false
#endif
    }
}

struct PaymentMethodSelectorView: View {
    @Binding var selectedMethod: TallaPaymentMethod
    let state: TallaPaymentState
    let applePayAvailable: Bool
    let gatewaySDKAvailable: Bool
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let surfaceColor: Color

    private var methods: [TallaPaymentMethod] {
        TallaPaymentMethod.allCases.filter { method in
            method != .applePay || applePayAvailable
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(methods) { method in
                let enabled = method == .benefit
                    || method == .clickToPay
                    || gatewaySDKAvailable
                Button {
                    guard enabled, !state.isBusy else { return }
                    selectedMethod = method
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: method.systemImage)
                            .frame(width: 22)
                        Text(method.title)
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        if !enabled {
                            Text("SDK REQUIRED")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                        } else if selectedMethod == method {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .foregroundStyle(enabled ? primaryColor : secondaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(selectedMethod == method ? accentColor.opacity(0.14) : surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selectedMethod == method ? accentColor.opacity(0.7) : accentColor.opacity(0.14))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!enabled || state.isBusy)
            }
        }
    }
}

enum TallaPaymentService {
    struct Session: Decodable {
        let sessionId: String
        let sessionVersion: String
        let apiVersion: String
        let merchantId: String
        let orderId: String
        let amount: String
        let currency: String
    }

    struct HostedCheckout: Decodable {
        let paymentUrl: URL
        let orderId: String
        let amount: String
        let currency: String
    }

    struct Completion: Decodable {
        let status: String
        let orderId: String
        let duplicate: Bool
    }

    static let applePayMerchantIdentifier = "merchant.talla.me"
    private static let accessTokenKey = "local.customerAccessToken"

    static func createCardSession(orderID: String) async throws -> Session {
        try await post(path: "/api/payments/card/session", payload: ["orderID": orderID])
    }

    static func createApplePaySession(orderID: String) async throws -> Session {
        try await post(path: "/api/payments/apple-pay/session", payload: ["orderID": orderID])
    }

    static func createClickToPay(orderID: String) async throws -> HostedCheckout {
        try await post(path: "/api/payments/click-to-pay/create", payload: ["orderID": orderID])
    }

    static func initiateAuthentication(orderID: String, sessionID: String) async throws -> Data {
        try await postData(
            path: "/api/payments/card/authentication/initiate",
            payload: ["orderID": orderID, "sessionId": sessionID]
        )
    }

    static func authenticatePayer(orderID: String, sessionID: String) async throws -> Data {
        try await postData(
            path: "/api/payments/card/authentication/complete",
            payload: ["orderID": orderID, "sessionId": sessionID]
        )
    }

    static func completeCard(orderID: String, sessionID: String) async throws -> Completion {
        try await post(
            path: "/api/payments/card/complete",
            payload: ["orderID": orderID, "sessionId": sessionID]
        )
    }

    static func completeApplePay(orderID: String, sessionID: String) async throws -> Completion {
        try await post(
            path: "/payments/apple-pay/authorize",
            payload: ["orderID": orderID, "sessionId": sessionID]
        )
    }

    private static func post<Response: Decodable>(path: String, payload: [String: Any]) async throws -> Response {
        let data = try await postData(path: path, payload: payload)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private static func postData(path: String, payload: [String: Any]) async throws -> Data {
        guard let baseURL = BackendConfiguration.serviceBaseURL else {
            throw PaymentServiceError.unavailable
        }
        let token = UserDefaults.standard.string(forKey: accessTokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !token.isEmpty else { throw PaymentServiceError.authenticationRequired }
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentServiceError.unavailable
        }
        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let message = (try? JSONDecoder().decode(PaymentErrorResponse.self, from: data).error)
                ?? "Payment could not be completed."
            throw PaymentServiceError.gateway(message)
        }
        return data
    }
}

private struct PaymentErrorResponse: Decodable {
    let error: String
}

enum PaymentServiceError: LocalizedError {
    case unavailable
    case authenticationRequired
    case gateway(String)

    var errorDescription: String? {
        switch self {
        case .unavailable: return "The payment service is unavailable."
        case .authenticationRequired: return "Sign in again to continue."
        case .gateway(let message): return message
        }
    }
}
