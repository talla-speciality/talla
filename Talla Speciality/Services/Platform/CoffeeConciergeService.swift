import Foundation
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "The customer's gifting and cart intent extracted from natural language.")
private struct ConciergeIntent {
    @Guide(description: "The recipient, such as friend, mother, colleague, or host. Use nil when absent.")
    let recipient: String?
    @Guide(description: "The occasion, such as birthday, thank-you, Ramadan, or hosting. Use nil when absent.")
    let occasion: String?
    @Guide(description: "The maximum budget in BHD, if the customer stated one.")
    let budgetBHD: Double?
    @Guide(description: "Whether the customer explicitly asked to add or buy the recommendations.")
    let wantsCart: Bool
    @Guide(description: "Short catalog item descriptions the customer wants added, without inventing products.")
    let itemRequests: [String]
    @Guide(description: "Up to three concise gift messages in the customer's language. Return an empty list when not relevant.")
    let giftMessageSuggestions: [String]
}
#endif
#if canImport(Vision) && canImport(UIKit)
import UIKit
import Vision
#endif

struct CoffeeConciergeResult: Equatable {
    let message: String
    let productIDs: [String]
    let usedAppleIntelligence: Bool
    let giftMessageSuggestions: [String]
    let canBuildCart: Bool
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
            if let modelOutput = try? await foundationModelOutput(
                request: trimmedRequest,
                rankingRequest: rankingRequest,
                products: products,
                localeIdentifier: localeIdentifier,
                imageAnalysis: imageAnalysis
            ) {
                let modelRankedProducts = rankedProducts(
                    for: [rankingRequest, modelOutput.itemRequests.joined(separator: " ")].joined(separator: " "),
                    products: products
                )
                return CoffeeConciergeResult(
                    message: modelOutput.message,
                    productIDs: Array(modelRankedProducts.prefix(3)).map(\.id).isEmpty ? fallback.productIDs : Array(modelRankedProducts.prefix(3)).map(\.id),
                    usedAppleIntelligence: true,
                    giftMessageSuggestions: modelOutput.giftMessageSuggestions.isEmpty ? fallback.giftMessageSuggestions : modelOutput.giftMessageSuggestions,
                    canBuildCart: modelOutput.wantsCart || fallback.canBuildCart
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
        let requestedBudget = budgetValue(from: rankingRequest)

        guard !picks.isEmpty else {
            return CoffeeConciergeResult(
                message: requestedBudget != nil
                    ? "I couldn't find an available catalog item within that budget. Try a slightly higher budget or ask me for another gift style."
                    : hasImage
                    ? "Image added. Tell me what you want from it: match a roast, find a gift, pair chocolate, or stay within a budget."
                    : "Tell me what you like: espresso, Arabic coffee, gift boxes, chocolate, tools, or a budget.",
                productIDs: [],
                usedAppleIntelligence: false,
                giftMessageSuggestions: giftMessageSuggestions(for: request),
                canBuildCart: requestLooksLikeCartBuild(request)
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
            usedAppleIntelligence: false,
            giftMessageSuggestions: giftMessageSuggestions(for: request),
            canBuildCart: requestLooksLikeCartBuild(request)
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
        let budget = budgetValue(from: normalized)

        let available = products.filter(\.isAvailableForSale)
        let budgetQualified = budget.map { limit in
            available.filter {
                let price = priceValue(from: $0.price)
                return price > 0 && price <= limit
            }
        } ?? []
        let candidates = budget == nil ? available : budgetQualified

        return candidates
            .sorted { lhs, rhs in
                let lhsScore = score(product: lhs, terms: terms, request: normalized, budget: budget)
                let rhsScore = score(product: rhs, terms: terms, request: normalized, budget: budget)

                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }

                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private static func score(
        product: ContentView.Product,
        terms: [String],
        request: String,
        budget: Double?
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
            if product.categoryKey.contains("coffee") { score += 3 }
        }

        if request.contains("birthday") || request.contains("عيد ميلاد"), product.categoryKey == "gifts" { score += 8 }
        if request.contains("thank") || request.contains("شكرا") || request.contains("شكرًا"), ["chocolate", "desserts", "gifts"].contains(product.categoryKey) { score += 6 }
        if request.contains("host") || request.contains("majlis") || request.contains("ضيافة"), ["arabic-coffee-beans", "gifts"].contains(product.categoryKey) { score += 7 }

        if request.contains("arabic") || request.contains("عربي") || request.contains("مجلس") {
            if product.categoryKey.contains("arabic") { score += 14 }
            if haystack.contains("arabic") { score += 8 }
        }

        if request.contains("drip") || request.contains("travel") || request.contains("office") || request.contains("work") {
            if product.categoryKey.contains("drip") { score += 12 }
            if product.categoryKey.contains("cup") || product.categoryKey.contains("drink") { score += 5 }
        }

        if request.contains("tool") || request.contains("brew") || request.contains("equipment") || request.contains("v60") || request.contains("filter") {
            if product.categoryKey.contains("equipment") { score += 12 }
            if product.categoryKey.contains("drip") { score += 5 }
        }

        if request.contains("chocolate") || request.contains("sweet") || request.contains("dessert") || request.contains("حلو") {
            if product.categoryKey.contains("chocolate") { score += 12 }
            if product.categoryKey.contains("bakery") { score += 8 }
            if product.categoryKey.contains("dessert") { score += 8 }
            if product.categoryKey.contains("spread") { score += 6 }
        }

        if request.contains("cup") || request.contains("drink") || request.contains("cold") || request.contains("summer") || request.contains("iced") {
            if product.categoryKey.contains("drink") || product.categoryKey.contains("cup") { score += 12 }
            if product.categoryKey.contains("summer") { score += 10 }
        }

        if request.contains("bean") || request.contains("beans") || request.contains("roast") || request.contains("espresso") || request.contains("filter") {
            if product.categoryKey.contains("coffee") { score += 10 }
            if haystack.contains("espresso") || haystack.contains("filter") { score += 4 }
        }

        if request.contains("beginner") || request.contains("easy") || request.contains("first") {
            if product.categoryKey.contains("drip") { score += 8 }
            if product.categoryKey.contains("coffee") { score += 4 }
        }

        if let budget {
            let price = priceValue(from: product.price)
            if price > 0, price <= budget {
                score += 10
                let closeness = max(0, 5 - Int((budget - price).rounded(.down)))
                score += closeness
            } else if price > budget {
                score -= 18
            }
        }

        if product.tag?.lowercased().contains("new") == true { score += 2 }
        if request.isEmpty && product.categoryKey.contains("coffee") { score += 3 }
        if score == 0 && product.categoryKey.contains("coffee") { score += 1 }
        return score
    }

    private static func budgetValue(from request: String) -> Double? {
        let budgetMarkers = ["under", "below", "less than", "up to", "budget", "أقل", "تحت"]
        guard budgetMarkers.contains(where: { request.contains($0) }) else { return nil }

        let normalized = request.replacingOccurrences(of: ",", with: ".")
        let matches = normalized.matches(of: /\d+(\.\d+)?/)
        return matches.compactMap { Double(String($0.output.0)) }.max()
    }

    private static func priceValue(from rawValue: String) -> Double {
        let normalized = rawValue.replacingOccurrences(of: ",", with: ".")
        let match = normalized.firstMatch(of: /\d+(\.\d+)?/)
        guard let value = match?.output.0 else { return 0 }
        return Double(String(value)) ?? 0
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

    private static func requestLooksLikeCartBuild(_ request: String) -> Bool {
        let normalized = request.lowercased()
        return ["add", "cart", "bag", "buy", "purchase", "put in", "أضف", "السلة", "اشتري"].contains { normalized.contains($0) }
    }

    private static func giftMessageSuggestions(for request: String) -> [String] {
        let normalized = request.lowercased()
        guard normalized.contains("gift") || request.contains("هدية") || normalized.contains("birthday") || normalized.contains("thank") || normalized.contains("occasion") else { return [] }
        let occasion: String
        if normalized.contains("birthday") || request.contains("ميلاد") { occasion = "birthday" }
        else if normalized.contains("thank") || request.contains("شكر") { occasion = "thank-you" }
        else { occasion = "special moment" }
        if request.contains("هدية") || request.contains("ميلاد") || request.contains("شكر") {
            return [
                "هدية صغيرة لك — أتمنى أن تجعل مناسبتك أحلى.",
                "أفكر بك وأرسل لك لحظة دافئة من تله.",
                "صُممت للمشاركة، مع أطيب تمنياتي لك."
            ]
        }
        return [
            "A little something for you — hope it makes your \(occasion) sweeter.",
            "Thinking of you and sending a warm Talla moment your way.",
            "Made for sharing, with best wishes from me to you."
        ]
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
    private static func foundationModelOutput(
        request: String,
        rankingRequest: String,
        products: [ContentView.Product],
        localeIdentifier: String,
        imageAnalysis: ImageAnalysis?
    ) async throws -> (message: String, giftMessageSuggestions: [String], wantsCart: Bool, itemRequests: [String]) {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { throw ConciergeError.unavailable }
        guard model.supportsLocale(Locale(identifier: localeIdentifier)) else { throw ConciergeError.unavailable }

        let catalog = products
            .filter(\.isAvailableForSale)
            .prefix(24)
            .map { product in
                "- id=\(product.id) | \(product.name) | \(product.categoryLabel) | \(product.price) | \(product.desc.prefix(90))"
            }
            .joined(separator: "\n")

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are Talla Speciality's coffee concierge. Recommend only products from the supplied catalog. Keep the answer friendly, specific, and under 55 words. Do not invent products, prices, discounts, or policies. If the request is Arabic, answer in Arabic.
            For gifting, use the recipient, budget, and occasion in the request to tailor the recommendation. You may suggest message wording, but never claim that stock, price, payment, redemption, or expiry is confirmed by the model; those remain server-authoritative.
            """
        )

        let imageContext = imageAnalysis?.summary.isEmpty == false
            ? "Local Vision detected these shopping signals: \(imageAnalysis?.summary ?? ""). Use them as hints only, and recommend only catalog products."
            : "No useful image signals."

        let intentResponse = try await session.respond(
            to: "Extract gifting and cart intent from this request. Do not choose products or make commerce decisions. Customer request: \(request)",
            generating: ConciergeIntent.self
        )
        let intent = intentResponse.content
        let recipient = intent.recipient ?? "not specified"
        let occasion = intent.occasion ?? "not specified"
        let budget = intent.budgetBHD.map { String($0) } ?? "not specified"
        let itemRequests = intent.itemRequests.joined(separator: ", ")
        let structuredContext = "Structured intent: recipient=\(recipient), occasion=\(occasion), budgetBHD=\(budget), wantsCart=\(intent.wantsCart), itemRequests=\(itemRequests)"

        let prompt = """
        Customer request: \(request.isEmpty ? "Recommend a good starting point" : request)
        Ranked request context: \(rankingRequest)
        Image context: \(imageContext)
        \(structuredContext)

        Available catalog:
        \(catalog)
        """

        let response = try await session.respond(to: prompt)
        let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { throw ConciergeError.unavailable }
        let fallbackMessages = giftMessageSuggestions(for: request)
        return (content, intent.giftMessageSuggestions.isEmpty ? fallbackMessages : intent.giftMessageSuggestions, intent.wantsCart, intent.itemRequests)
    }
#endif
}
