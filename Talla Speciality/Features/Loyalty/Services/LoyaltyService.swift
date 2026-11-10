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
        let scope = "\(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(reward.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
#if canImport(CryptoKit)
        let scopeID = SHA256.hash(data: Data(scope.utf8)).map { String(format: "%02x", $0) }.joined()
#else
        let scopeID = Data(scope.utf8).base64EncodedString()
#endif
        let pendingKey = "talla.loyalty.pendingRedemption.v1.\(scopeID)"
        let idempotencyKey = UserDefaults.standard.string(forKey: pendingKey) ?? "redeem:\(UUID().uuidString.lowercased())"
        UserDefaults.standard.set(idempotencyKey, forKey: pendingKey)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "reward": reward,
            "idempotencyKey": idempotencyKey
        ])

        let account = try await performLoyaltyRequest(request)
        UserDefaults.standard.removeObject(forKey: pendingKey)
        return account
    }

    static func claimEducationReward(email: String, lessonIDs: [String], answers: [EducationAnswerProof]) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else { throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.") }
        var request = URLRequest(url: baseURL.appending(path: "/loyalty/activities/education-claim"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        do {
            return try await performLoyaltyRequest(request)
        } catch ContentView.LoyaltyServiceError.insufficientPoints {
            for lessonID in lessonIDs { try await recordEducationLesson(email: email, lessonID: lessonID) }
            for proof in answers {
                guard try await recordEducationAnswer(email: email, proof: proof).correct else {
                    throw ContentView.LoyaltyServiceError.educationProofRequired
                }
            }
            do {
                return try await performLoyaltyRequest(request)
            } catch ContentView.LoyaltyServiceError.insufficientPoints {
                throw ContentView.LoyaltyServiceError.educationProofRequired
            }
        }
    }

    static func recordEducationLesson(email: String, lessonID: String) async throws {
        _ = try await postEducationActivity("education-lesson", body: ["email": email, "lessonID": lessonID])
    }

    struct EducationAnswerResult: Decodable {
        let correct: Bool
        let explanation: String
    }

    static func recordEducationAnswer(email: String, proof: EducationAnswerProof) async throws -> EducationAnswerResult {
        let data = try await postEducationActivity("education-answer", body: ["email": email, "questionID": proof.id, "answer": proof.answer])
        return try JSONDecoder().decode(EducationAnswerResult.self, from: data)
    }

    private static func postEducationActivity(_ path: String, body: [String: String]) async throws -> Data {
        guard let baseURL else { throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.") }
        var request = URLRequest(url: baseURL.appending(path: "/loyalty/activities/\(path)"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await AccountService.data(for: request)
        if path == "education-answer",
           (response as? HTTPURLResponse)?.statusCode == 429,
           let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           (payload["retryAfterSeconds"] as? Int ?? 0) > 0 {
            throw ContentView.LoyaltyServiceError.educationQuizCooldown
        }
        guard let status = (response as? HTTPURLResponse)?.statusCode, 200..<300 ~= status else {
            throw ContentView.LoyaltyServiceError.operationFailed("Education progress could not be saved.")
        }
        return data
    }

    static func recordGulfCoffeeVisit(spotID: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else { throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.") }
        var request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map/visits"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["spotID": spotID])
        struct Envelope: Decodable { let loyalty: ContentView.LoyaltyAccount }
        let (data, response) = try await AccountService.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The visit could not be saved.")
        }
        return try JSONDecoder().decode(Envelope.self, from: data).loyalty
    }

    static func fetchGulfCoffeeVisits() async throws -> [String] {
        guard let baseURL else { throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.") }
        var request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map/visits"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try AccountService.authorize(&request)
        let (data, response) = try await AccountService.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The passport could not be loaded.")
        }
        struct Envelope: Decodable { let visitedSpotIDs: [String] }
        return try JSONDecoder().decode(Envelope.self, from: data).visitedSpotIDs
    }

    static func fetchGulfCoffeeEventRSVPs() async throws -> [String] {
        guard let baseURL else { throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.") }
        var request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map/events/rsvps"))
        request.httpMethod = "GET"
        try AccountService.authorize(&request)
        let (data, response) = try await AccountService.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw ContentView.LoyaltyServiceError.operationFailed("The event list could not be loaded.") }
        struct RSVP: Decodable { let eventID: String }
        struct Envelope: Decodable { let rsvps: [RSVP] }
        return try JSONDecoder().decode(Envelope.self, from: data).rsvps.map(\.eventID)
    }

    static func rsvpGulfCoffeeEvent(eventID: String, spotID: String) async throws {
        guard let baseURL else { throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.") }
        var request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map/events/rsvp"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["eventID": eventID, "spotID": spotID])
        let (_, response) = try await AccountService.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw ContentView.LoyaltyServiceError.operationFailed("The RSVP could not be saved.") }
    }

    static func performLoyaltyRequest(_ request: URLRequest) async throws -> ContentView.LoyaltyAccount {
        let (data, response) = try await AccountService.data(for: request)

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
