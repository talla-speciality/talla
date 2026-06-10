import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
#if canImport(Vision) && canImport(UIKit)
import UIKit
import Vision
#endif

struct CoffeeConciergeResult: Equatable {
    let message: String
    let productIDs: [String]
    let usedAppleIntelligence: Bool
}

enum CoffeeConciergeService {
    private enum ConciergeError: Error {
        case unavailable
    }

    private struct ImageAnalysis: Sendable {
        let labels: [String]
        let signals: [String]

        var summary: String {
            let usefulTerms = (signals.isEmpty ? labels : signals).prefix(6)
            return usefulTerms.joined(separator: ", ")
        }

        var searchText: String {
            (labels + signals).joined(separator: " ")
        }
    }

    static func recommend(
        request: String,
        products: [ContentView.Product],
        localeIdentifier: String,
        imageData: Data? = nil
    ) async -> CoffeeConciergeResult {
        let trimmedRequest = request.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageAnalysis = await analyzeImage(imageData)
        let rankingRequest = recommendationRequest(text: trimmedRequest, imageAnalysis: imageAnalysis)
        let fallback = fallbackRecommendation(
            request: trimmedRequest,
            rankingRequest: rankingRequest,
            products: products,
            imageAnalysis: imageAnalysis
        )

#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if let message = try? await foundationModelMessage(
                request: trimmedRequest,
                rankingRequest: rankingRequest,
                products: products,
                localeIdentifier: localeIdentifier,
                imageAnalysis: imageAnalysis
            ) {
                return CoffeeConciergeResult(
                    message: message,
                    productIDs: fallback.productIDs,
                    usedAppleIntelligence: true
                )
            }
        }
#endif

        return fallback
    }

    private static func fallbackRecommendation(
        request: String,
        rankingRequest: String,
        products: [ContentView.Product],
        imageAnalysis: ImageAnalysis?
    ) -> CoffeeConciergeResult {
        let ranked = rankedProducts(for: rankingRequest, products: products)
        let picks = Array(ranked.prefix(3))
        let hasImage = imageAnalysis != nil

        guard !picks.isEmpty else {
            return CoffeeConciergeResult(
                message: hasImage
                    ? "Image added. Tell me what you want from it: match a roast, find a gift, pair chocolate, or stay within a budget."
                    : "Tell me what you like: espresso, Arabic coffee, gift boxes, chocolate, tools, or a budget.",
                productIDs: [],
                usedAppleIntelligence: false
            )
        }

        let names = picks.map(\.name).joined(separator: ", ")
        let lead = request.isEmpty
            ? (hasImage ? "Based on your image, start with these Talla picks" : "Start with these Talla picks")
            : "For \"\(request)\", I would start with"
        let reason = fallbackReason(for: rankingRequest, products: picks, imageAnalysis: imageAnalysis)

        return CoffeeConciergeResult(
            message: "\(lead) \(names). \(reason)",
            productIDs: picks.map(\.id),
            usedAppleIntelligence: false
        )
    }

    private static func rankedProducts(
        for request: String,
        products: [ContentView.Product]
    ) -> [ContentView.Product] {
        let normalized = request.lowercased()
        let terms = normalized
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)

        return products
            .filter(\.isAvailableForSale)
            .sorted { lhs, rhs in
                let lhsScore = score(product: lhs, terms: terms, request: normalized)
                let rhsScore = score(product: rhs, terms: terms, request: normalized)

                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private static func score(
        product: ContentView.Product,
        terms: [String],
        request: String
    ) -> Int {
        let haystack = [
            product.name,
            product.categoryLabel,
            product.categoryKey,
            product.desc,
            product.tag ?? "",
            product.variants.map { "\($0.title) \($0.price)" }.joined(separator: " ")
        ]
        .joined(separator: " ")
        .lowercased()

        var score = 0
        for term in terms where term.count > 1 {
            if haystack.contains(term) { score += 6 }
        }

        if request.contains("gift") || request.contains("هدية") {
            if product.categoryKey.contains("gift") { score += 14 }
            if haystack.contains("box") { score += 8 }
        }

        if request.contains("arabic") || request.contains("عربي") || request.contains("مجلس") {
            if product.categoryKey.contains("arabic") { score += 14 }
            if haystack.contains("arabic") { score += 8 }
        }

        if request.contains("drip") || request.contains("travel") || request.contains("office") {
            if product.categoryKey.contains("drip") { score += 12 }
        }

        if request.contains("tool") || request.contains("brew") || request.contains("equipment") {
            if product.categoryKey.contains("equipment") { score += 12 }
        }

        if request.contains("chocolate") || request.contains("sweet") || request.contains("حلو") {
            if product.categoryKey.contains("chocolate") { score += 12 }
            if product.categoryKey.contains("bakery") { score += 8 }
        }

        if request.contains("cup") || request.contains("drink") {
            if product.categoryKey.contains("drink") || product.categoryKey.contains("cup") { score += 12 }
        }

        if product.tag?.lowercased().contains("new") == true { score += 2 }
        if score == 0 && product.categoryKey.contains("coffee") { score += 1 }
        return score
    }

    private static func fallbackReason(
        for request: String,
        products: [ContentView.Product],
        imageAnalysis: ImageAnalysis?
    ) -> String {
        let categories = Set(products.map(\.categoryKey))
        let normalized = request.lowercased()

        if normalized.contains("gift") || normalized.contains("هدية") {
            return "They fit gifting and hosting without making the choice complicated."
        }

        if normalized.contains("arabic") || normalized.contains("عربي") || normalized.contains("مجلس") {
            return "They lean into traditional coffee moments and majlis service."
        }

        if let imageAnalysis, !imageAnalysis.summary.isEmpty {
            return "I matched the photo signals (\(imageAnalysis.summary)) with products that are available now."
        }

        if categories.contains(where: { $0.contains("equipment") }) {
            return "They are useful if the goal is better brewing at home."
        }

        return "They are available now and give you a balanced place to start."
    }

    private static func recommendationRequest(text: String, imageAnalysis: ImageAnalysis?) -> String {
        guard let imageAnalysis, !imageAnalysis.searchText.isEmpty else { return text }
        if text.isEmpty {
            return imageAnalysis.searchText
        }
        return "\(text) \(imageAnalysis.searchText)"
    }

    private static func analyzeImage(_ imageData: Data?) async -> ImageAnalysis? {
        guard let imageData, !imageData.isEmpty else { return nil }

#if canImport(Vision) && canImport(UIKit)
        return await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
                return ImageAnalysis(labels: [], signals: ["photo"])
            }

            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
                let labels = (request.results ?? [])
                    .filter { $0.confidence >= 0.12 }
                    .prefix(6)
                    .map { cleanVisionLabel($0.identifier) }
                let signals = visualSignals(from: labels)
                return ImageAnalysis(labels: labels, signals: signals)
            } catch {
                return ImageAnalysis(labels: [], signals: ["photo"])
            }
        }.value
#else
        return ImageAnalysis(labels: [], signals: ["photo"])
#endif
    }

    nonisolated private static func cleanVisionLabel(_ label: String) -> String {
        label
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    nonisolated private static func visualSignals(from labels: [String]) -> [String] {
        var signals: [String] = []

        func add(_ values: String...) {
            for value in values where !signals.contains(value) {
                signals.append(value)
            }
        }

        for label in labels {
            if label.contains("coffee") || label.contains("espresso") || label.contains("cappuccino") || label.contains("latte") {
                add("coffee", "coffee beans")
            }
            if label.contains("cup") || label.contains("mug") || label.contains("beverage") || label.contains("drink") {
                add("cup", "ready made drinks")
            }
            if label.contains("chocolate") || label.contains("cocoa") {
                add("chocolate", "hot chocolate")
            }
            if label.contains("cake") || label.contains("pastry") || label.contains("dessert") || label.contains("bread") || label.contains("cookie") {
                add("sweet", "bakery")
            }
            if label.contains("box") || label.contains("package") || label.contains("bag") || label.contains("gift") {
                add("gift", "talla box")
            }
            if label.contains("kettle") || label.contains("grinder") || label.contains("scale") || label.contains("filter") {
                add("brew", "equipment")
            }
        }

        return signals
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private static func foundationModelMessage(
        request: String,
        rankingRequest: String,
        products: [ContentView.Product],
        localeIdentifier: String,
        imageAnalysis: ImageAnalysis?
    ) async throws -> String {
        let model = SystemLanguageModel.default
        guard model.isAvailable else { throw ConciergeError.unavailable }
        guard model.supportsLocale(Locale(identifier: localeIdentifier)) else { throw ConciergeError.unavailable }

        let catalog = products
            .filter(\.isAvailableForSale)
            .prefix(24)
            .map { product in
                "- \(product.name) | \(product.categoryLabel) | \(product.price) | \(product.desc.prefix(90))"
            }
            .joined(separator: "\n")

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are Talla Speciality's coffee concierge. Recommend only products from the supplied catalog. Keep the answer friendly, specific, and under 55 words. Do not invent products, prices, discounts, or policies. If the request is Arabic, answer in Arabic.
            """
        )

        let imageContext = imageAnalysis?.summary.isEmpty == false
            ? "Local Vision detected these shopping signals: \(imageAnalysis?.summary ?? ""). Use them as hints only, and recommend only catalog products."
            : "No useful image signals."

        let prompt = """
        Customer request: \(request.isEmpty ? "Recommend a good starting point" : request)
        Ranked request context: \(rankingRequest)
        Image context: \(imageContext)

        Available catalog:
        \(catalog)
        """

        let response = try await session.respond(to: prompt)
        let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { throw ConciergeError.unavailable }
        return content
    }
#endif
}
