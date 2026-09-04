import Foundation
import SwiftUI
import StoreKit
#if canImport(Security)
import Security
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

enum LoyaltyService {
    static let baseURL = BackendConfiguration.serviceBaseURL

    static func fetchAccount(email: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Loyalty service"))
        }

        var components = URLComponents(url: baseURL.appending(path: "/loyalty/account"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try AccountService.authorize(&request)

        return try await performLoyaltyRequest(request)
    }

    static func redeemReward(email: String, points: Int, reward: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/loyalty/transactions/redeem"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "reward": reward
        ])

        return try await performLoyaltyRequest(request)
    }

    static func earnPoints(email: String, points: Int, note: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/loyalty/transactions/earn"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "note": note
        ])

        return try await performLoyaltyRequest(request)
    }

    static func performLoyaltyRequest(_ request: URLRequest) async throws -> ContentView.LoyaltyAccount {
        let (data, response) = try await TallaSecureSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service returned an invalid response.")
        }

        if httpResponse.statusCode == 404 {
            throw ContentView.LoyaltyServiceError.missingAccount
        }

        if httpResponse.statusCode == 409 {
            throw ContentView.LoyaltyServiceError.insufficientPoints
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            do {
                return try JSONDecoder().decode(ContentView.LoyaltyAccount.self, from: data)
            } catch {
                throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service returned an invalid response.")
            }
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service could not complete your request.")
    }
}

#if canImport(PassKit) && canImport(UIKit)
struct WalletPassView: UIViewControllerRepresentable {
    let pass: PKPass

    func makeUIViewController(context: Context) -> UIViewController {
        guard let controller = PKAddPassesViewController(pass: pass) else {
            return UIViewController()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
#endif
