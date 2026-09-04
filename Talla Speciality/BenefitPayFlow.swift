import Foundation
import SwiftUI
#if canImport(BenefitInAppSDK) && canImport(UIKit)
import BenefitInAppSDK
import UIKit
#endif

struct BenefitPaySession: Decodable, Identifiable {
    let appId: String
    let merchantId: String
    let merchantName: String
    let merchantCity: String
    let merchantCategoryCode: String
    let countryCode: String
    let currencyCode: String
    let amount: String
    let referenceId: String
    let callbackTag: String
    let paymentToken: String
    let orderId: String

    var id: String { referenceId }
}

struct BenefitPayConfirmation: Decodable {
    let status: String
    let orderId: String
    let duplicate: Bool
}

enum BenefitPaySDKConfiguration {
    static let callbackScheme = "tallabenefitpay"

    static var secretKey: String? {
        let value = (Bundle.main.object(forInfoDictionaryKey: "BenefitPaySDKSecretKey") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !value.isEmpty, !value.contains("$(") else { return nil }
        return value
    }

    static var isAvailable: Bool {
#if canImport(BenefitInAppSDK) && canImport(UIKit)
        secretKey != nil
#else
        false
#endif
    }
}

enum BenefitPayService {

    static func createSession(orderID: String) async throws -> BenefitPaySession {
        try await post(
            path: "/api/payments/benefitpay/session",
            payload: ["orderID": orderID]
        )
    }

    static func confirm(session: BenefitPaySession) async throws -> BenefitPayConfirmation {
        let payload = [
            "orderID": session.orderId,
            "referenceID": session.referenceId,
            "paymentToken": session.paymentToken
        ]
        let retryDelays: [UInt64] = [0, 1, 2, 3, 4]
        for delay in retryDelays {
            if delay > 0 {
                try await Task.sleep(for: .seconds(delay))
            }
            let confirmation: BenefitPayConfirmation = try await post(
                path: "/api/payments/benefitpay/confirm",
                payload: payload
            )
            if confirmation.status != "pending" {
                return confirmation
            }
        }
        throw PaymentServiceError.gateway("BenefitPay is still confirming your payment. Please check your order again shortly.")
    }

    private static func post<Response: Decodable>(
        path: String,
        payload: [String: Any]
    ) async throws -> Response {
        guard let baseURL = BackendConfiguration.serviceBaseURL else {
            throw PaymentServiceError.unavailable
        }
        let accessToken = AccountService.accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accessToken.isEmpty else {
            throw PaymentServiceError.authenticationRequired
        }
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await AccountService.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentServiceError.unavailable
        }
        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let message = (try? JSONDecoder().decode(BenefitPayErrorResponse.self, from: data).error)
                ?? "BenefitPay could not complete the payment."
            throw PaymentServiceError.gateway(message)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct BenefitPayErrorResponse: Decodable {
    let error: String
}

#if canImport(BenefitInAppSDK) && canImport(UIKit)
struct BenefitPayCheckoutSheet: View {
    let session: BenefitPaySession
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image("BenefitPayLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 7) {
                    Text(AppLocalization.text("pay_with_benefitpay", fallback: "Pay with BenefitPay"))
                        .font(.title2.weight(.semibold))
                    Text(String(format: AppLocalization.text("benefitpay_amount_format", fallback: "BHD %@"), session.amount))
                        .font(.title3.monospacedDigit().weight(.medium))
                    Text(AppLocalization.text("benefitpay_continue_detail", fallback: "Continue in the BenefitPay app. Talla verifies the transaction with BenefitPay before completing your order."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                BenefitPaySDKButton(session: session)
                    .frame(width: 258, height: 60)

                Spacer()
            }
            .padding(24)
            .background(Color(red: 0.98, green: 0.965, blue: 0.935).ignoresSafeArea())
            .navigationTitle(AppLocalization.text("benefitpay", fallback: "BenefitPay"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("cancel", fallback: "Cancel"), action: onCancel)
                }
            }
        }
    }
}

private struct BenefitPaySDKButton: UIViewRepresentable {
    let session: BenefitPaySession

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    func makeUIView(context: Context) -> BPInAppButton {
        let button = BPInAppButton(frame: CGRect(x: 0, y: 0, width: 258, height: 60))
        button.delegate = context.coordinator
        return button
    }

    func updateUIView(_ uiView: BPInAppButton, context: Context) {
        context.coordinator.session = session
        uiView.delegate = context.coordinator
    }

    final class Coordinator: NSObject, BPInAppButtonDelegate {
        var session: BenefitPaySession

        init(session: BenefitPaySession) {
            self.session = session
        }

        func bpInAppConfiguration() -> BPInAppConfiguration! {
            guard let secretKey = BenefitPaySDKConfiguration.secretKey else { return nil }
            return BPInAppConfiguration(
                appId: session.appId,
                andSecretKey: secretKey,
                andAmount: session.amount,
                andCurrencyCode: session.currencyCode,
                andMerchantId: session.merchantId,
                andMerchantName: session.merchantName,
                andMerchantCity: session.merchantCity,
                andCountryCode: session.countryCode,
                andMerchantCategoryId: session.merchantCategoryCode,
                andReferenceId: session.referenceId,
                andCallBackTag: session.callbackTag
            )
        }
    }
}

enum BenefitPayCallbackParser {
    static func referenceID(from url: URL) -> String? {
        BPDLPaymentCallBackItem(deepLinkURL: url)?.referenceId
    }
}
#else
struct BenefitPayCheckoutSheet: View {
    let session: BenefitPaySession
    let onCancel: () -> Void

    var body: some View {
        Text(AppLocalization.text("benefitpay_sdk_unavailable", fallback: "BenefitPay is unavailable on this device."))
    }
}

enum BenefitPayCallbackParser {
    static func referenceID(from url: URL) -> String? { nil }
}
#endif
