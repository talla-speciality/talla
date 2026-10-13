import Foundation

struct NextCupRecommendation: Codable, Identifiable, Equatable {
    struct Explanation: Codable, Equatable {
        let score: Int
        let reasons: [String]
        let summary: String
    }

    struct Action: Codable, Equatable {
        let kind: String
        let productID: String
    }

    let productID: String
    let title: String
    let price: String?
    let availableForSale: Bool
    let imageURL: URL?
    let recommendation: Explanation
    let actions: [Action]

    var id: String { productID }
}

struct NextCupRecommendationResponse: Codable, Equatable {
    let action: String
    let headline: String
    let recommendations: [NextCupRecommendation]
    let profile: Profile
    let freshness: Freshness
    let coffeeInsights: CoffeeInsights?

    struct Profile: Codable, Equatable {
        let lovedSignals: [String]
        let avoidedSignals: [String]
    }

    struct Freshness: Codable, Equatable {
        let state: String
        let days: Int?
    }

    struct CoffeeInsights: Codable, Equatable {
        struct Reorder: Codable, Equatable, Identifiable {
            let productID: String?
            let productName: String
            let estimatedBrews: Int
            let reason: String
            var id: String { "\(productID ?? productName)-\(estimatedBrews)" }
        }

        let reorder: [Reorder]
    }
}

enum NextCupRecommendationService {
    static func fetch(query: String? = nil, limit: Int = 3) async throws -> NextCupRecommendationResponse {
        guard let baseURL = BackendConfiguration.serviceBaseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The next-cup service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/recommendations/next-cup"), resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem(name: "limit", value: String(max(1, min(limit, 10))))]
        if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try AccountService.authorize(&request)
        let (data, response) = try await AccountService.data(for: request)
        guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The next-cup service could not complete your request.")
        }
        return try JSONDecoder().decode(NextCupRecommendationResponse.self, from: data)
    }

    static func record(action: String, productID: String, sessionID: String? = nil) async {
        guard let baseURL = BackendConfiguration.serviceBaseURL,
              !productID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var request = URLRequest(url: baseURL.appending(path: "/recommendations/next-cup/feedback"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard (try? AccountService.authorize(&request)) != nil else { return }
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "action": action,
            "productID": productID,
            "sessionID": sessionID ?? UUID().uuidString,
            "platform": "ios"
        ])
        _ = try? await AccountService.data(for: request)
    }
}
