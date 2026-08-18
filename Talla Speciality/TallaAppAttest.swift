import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(DeviceCheck)
import DeviceCheck
#endif

enum TallaSecureSession {
    static func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard TallaAppAttest.protectedPaths.contains(request.url?.path ?? "") else {
            return try await URLSession.shared.data(for: request)
        }

        var securedRequest = request
        if let headers = try await TallaAppAttest.shared.assertionHeaders(for: request) {
            headers.forEach { securedRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        }
        return try await URLSession.shared.data(for: securedRequest)
    }
}

actor TallaAppAttest {
    static let shared = TallaAppAttest()
    static let protectedPaths: Set<String> = [
        "/orders/checkout-started",
        "/api/payments/apple-pay/session",
        "/api/payments/apple-pay/authorize",
        "/api/payments/card/session",
        "/api/payments/card/authentication/initiate",
        "/api/payments/card/authentication/complete",
        "/api/payments/card/complete",
        "/api/payments/click-to-pay/create",
        "/api/payments/benefitpay/session",
        "/api/payments/benefitpay/confirm",
        "/api/payments/benefit/create",
        "/api/payments/eazy/shopify/session",
        "/addresses/save",
        "/addresses/preferred",
        "/addresses/delete",
        "/loyalty/transactions/redeem",
        "/loyalty/transactions/earn",
        "/vouchers/consume",
        "/notifications/push/register",
        "/notifications/push/unregister",
        "/accounts/profile/update",
        "/accounts/password/change"
    ]

    private let keyIDKey = "security.appAttest.keyID"
    private let registeredKey = "security.appAttest.registered"

    func assertionHeaders(for request: URLRequest) async throws -> [String: String]? {
#if canImport(DeviceCheck) && canImport(CryptoKit) && os(iOS)
        let service = DCAppAttestService.shared
        guard service.isSupported else { return nil }
        guard let baseURL = await BackendConfiguration.serviceBaseURL else { return nil }
        let keyID = try await registeredKeyID(service: service, baseURL: baseURL)
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        let challenge = try await fetchChallenge(
            baseURL: baseURL,
            purpose: "assertion",
            method: method,
            path: path
        )
        let hash = Data(SHA256.hash(data: try challenge.data))
        let assertion = try await generateAssertion(service: service, keyID: keyID, clientDataHash: hash)
        return [
            "X-Talla-App-Attest-Key-ID": keyID,
            "X-Talla-App-Attest-Challenge": challenge.encoded,
            "X-Talla-App-Attest-Assertion": assertion.base64EncodedString()
        ]
#else
        return nil
#endif
    }

#if canImport(DeviceCheck) && canImport(CryptoKit) && os(iOS)
    private struct Challenge: Decodable {
        let challenge: String

        var encoded: String { challenge }
        var data: Data {
            get throws {
                guard let data = Data(base64Encoded: challenge), data.count == 32 else {
                    throw AttestError.invalidChallenge
                }
                return data
            }
        }
    }

    private enum AttestError: Error {
        case invalidChallenge
        case invalidResponse
    }

    private func registeredKeyID(service: DCAppAttestService, baseURL: URL) async throws -> String {
        let defaults = UserDefaults.standard
        let keyID: String
        if let existing = defaults.string(forKey: keyIDKey), !existing.isEmpty {
            keyID = existing
        } else {
            keyID = try await generateKey(service: service)
            defaults.set(keyID, forKey: keyIDKey)
            defaults.set(false, forKey: registeredKey)
        }

        guard !defaults.bool(forKey: registeredKey) else { return keyID }
        let challenge = try await fetchChallenge(baseURL: baseURL, purpose: "attestation")
        let clientDataHash = Data(SHA256.hash(data: try challenge.data))
        let attestation = try await attestKey(service: service, keyID: keyID, clientDataHash: clientDataHash)

        var registration = URLRequest(url: baseURL.appending(path: "/app-attest/register"))
        registration.httpMethod = "POST"
        registration.setValue("application/json", forHTTPHeaderField: "Content-Type")
        registration.httpBody = try JSONSerialization.data(withJSONObject: [
            "keyId": keyID,
            "challenge": challenge.encoded,
            "attestationObject": attestation.base64EncodedString()
        ])
        let (_, response) = try await URLSession.shared.data(for: registration)
        guard let response = response as? HTTPURLResponse, 200 ..< 300 ~= response.statusCode else {
            throw AttestError.invalidResponse
        }
        defaults.set(true, forKey: registeredKey)
        return keyID
    }

    private func fetchChallenge(
        baseURL: URL,
        purpose: String,
        method: String = "POST",
        path: String = ""
    ) async throws -> Challenge {
        var components = URLComponents(url: baseURL.appending(path: "/app-attest/challenge"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "purpose", value: purpose),
            URLQueryItem(name: "method", value: method),
            URLQueryItem(name: "path", value: path)
        ]
        guard let url = components?.url else { throw AttestError.invalidResponse }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, 200 ..< 300 ~= response.statusCode else {
            throw AttestError.invalidResponse
        }
        let challenge = try JSONDecoder().decode(Challenge.self, from: data)
        _ = try challenge.data
        return challenge
    }

    private func generateKey(service: DCAppAttestService) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            service.generateKey { keyID, error in
                if let keyID { continuation.resume(returning: keyID) }
                else { continuation.resume(throwing: error ?? AttestError.invalidResponse) }
            }
        }
    }

    private func attestKey(service: DCAppAttestService, keyID: String, clientDataHash: Data) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            service.attestKey(keyID, clientDataHash: clientDataHash) { data, error in
                if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: error ?? AttestError.invalidResponse) }
            }
        }
    }

    private func generateAssertion(service: DCAppAttestService, keyID: String, clientDataHash: Data) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            service.generateAssertion(keyID, clientDataHash: clientDataHash) { data, error in
                if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: error ?? AttestError.invalidResponse) }
            }
        }
    }
#endif
}
