import Foundation
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "The customer's coffee intent extracted from natural language.")
private struct ConciergeIntent {
    @Guide(description: "The coffee question or goal, such as choosing beans, fixing sour espresso, or dialing in pour-over.")
    let coffeeGoal: String?
    @Guide(description: "The equipment type, such as grinder, scale, dripper, kettle, espresso machine, brewer, filter, or water system. Use nil when absent.")
    let equipmentType: String?
    @Guide(description: "The equipment brand and model, such as Fellow Ode, Fellow Opus, Timemore Black Mirror, Comandante C40, V60, or Flair. Use nil when absent.")
    let equipmentModel: String?
    @Guide(description: "The brew method, such as espresso, V60, French press, AeroPress, moka pot, or cold brew. Use nil when absent.")
    let brewMethod: String?
    @Guide(description: "The grind size or adjustment requested. Use nil when absent.")
    let grind: String?
    @Guide(description: "The water temperature in Celsius if stated or clearly requested. Use nil when absent.")
    let waterTemperatureC: Double?
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
    let sourceURLs: [String]

    init(
        message: String,
        productIDs: [String],
        usedAppleIntelligence: Bool,
        giftMessageSuggestions: [String],
        canBuildCart: Bool,
        sourceURLs: [String] = []
    ) {
        self.message = message
        self.productIDs = productIDs
        self.usedAppleIntelligence = usedAppleIntelligence
        self.giftMessageSuggestions = giftMessageSuggestions
        self.canBuildCart = canBuildCart
        self.sourceURLs = sourceURLs
    }
}

private struct ConciergeMemoryEntry: Codable {
    let question: String
    let answer: String
    let feedback: Int?
}

enum CoffeeConciergeService {
    private static let memoryKey = "talla.concierge.memory.v1"

    static func recordInteraction(request: String, result: CoffeeConciergeResult, feedback: Int? = nil) {
        let question = request.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        var entries = loadMemory()
        entries.removeAll { $0.question.caseInsensitiveCompare(question) == .orderedSame }
        entries.insert(ConciergeMemoryEntry(question: question, answer: result.message, feedback: feedback), at: 0)
        entries = Array(entries.prefix(20))
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: memoryKey)
    }

    static func recordFeedback(request: String, result: CoffeeConciergeResult, feedback: Int) {
        recordInteraction(request: request, result: result, feedback: feedback)
    }

    private static func loadMemory() -> [ConciergeMemoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: memoryKey),
              let entries = try? JSONDecoder().decode([ConciergeMemoryEntry].self, from: data) else { return [] }
        return entries
    }

    private static func memoryContext(for request: String) -> String {
        let terms = Set(request.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 2 })
        let relevant = loadMemory().filter { entry in
            !terms.isDisjoint(with: Set(entry.question.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)))
        }.prefix(3)
        guard !relevant.isEmpty else { return "No previous customer examples are relevant." }
        return relevant.map { "Previous customer question: \($0.question)\nPrevious answer: \($0.answer)\( $0.feedback == 1 ? "\nCustomer liked this answer." : $0.feedback == -1 ? "\nCustomer did not like this answer; improve it." : "")" }.joined(separator: "\n---\n")
    }
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

    private static let equipmentKnowledge = """
    Equipment reference (use as a starting point, never as a substitute for the exact manual):
    - Grinders: Fellow Ode Gen 1/2 are brewed-coffee grinders, not espresso grinders; Fellow Opus spans espresso through cold brew. Baratza Encore is a common entry filter grinder, Encore ESP targets espresso, and Virtuoso+ adds finer adjustment. Eureka Mignon families are primarily espresso-oriented; Niche Zero, DF64/DF83, and Mazzer families vary by burr geometry, retention, and workflow. Comandante C40 and 1Zpresso J-series are hand grinders; Timemore C and Sculptor families vary by burr and brew range.
    - Scales: Acaia Pearl/Lunar, Timemore Black Mirror, Hario, and Felicita differ in size, response, timer, flow-rate, Bluetooth, and water resistance. Always use grams, tare, protect charging ports, and verify the exact model before claiming waterproofing.
    - Kettles: Fellow Stagg EKG, Brewista Artisan, Bonavita, Hario Buono, and Timemore Fish differ in temperature control, spout flow, and interface. A gooseneck improves pour control; it does not automatically improve extraction.
    - Espresso machines: Breville/Sage and De’Longhi emphasize convenience; Gaggia and Rancilio offer traditional workflows; Lelit, Profitec, Rocket, and La Marzocco span heat-exchanger and dual-boiler designs; Ascaso includes thermoblock designs; Flair is manual and pump-free. Never generalize pressure, temperature, or service steps across models.
    - Brewers: AeroPress/Clever are immersion-paper systems; French press uses metal filtration; Chemex uses thick paper; V60/Origami are cone brewers; Kalita is flat-bottom; moka pot uses steam pressure and must not be tamped; Tricolate, siphon, batch brewers, and cezve each require their own recipe logic.
    - Consumables and water: filter fit, paper flow, roast level, processing, mineral content, alkalinity, and freshness can outweigh brand. Use manufacturer manuals for descaling, electrical safety, pressure, and disassembly.
    """

    static func recommend(
        request: String,
        products: [ContentView.Product],
        localeIdentifier: String,
        imageData: Data? = nil,
        allowWebResearch: Bool = true
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

        if let equipmentRecommendation = equipmentRecommendationFallback(for: trimmedRequest) {
            return CoffeeConciergeResult(
                message: equipmentRecommendation,
                productIDs: [],
                usedAppleIntelligence: false,
                giftMessageSuggestions: [],
                canBuildCart: false
            )
        }

        if shouldUseLocalModel(for: trimmedRequest),
           let localResult = await localModelResearch(
               for: trimmedRequest,
               context: [equipmentKnowledge, memoryContext(for: trimmedRequest)].joined(separator: "\n\n")
           ) {
            return CoffeeConciergeResult(
                message: localResult.answer,
                productIDs: [],
                usedAppleIntelligence: false,
                giftMessageSuggestions: [],
                canBuildCart: false
            )
        }

        if allowWebResearch, shouldUseWebResearch(for: trimmedRequest),
           let webResult = await webResearch(for: trimmedRequest) {
            let webRankedProducts = requestLooksLikeProductRecommendation(trimmedRequest, hasImage: imageAnalysis != nil)
                && !isEquipmentQuestion(trimmedRequest)
                ? Array(rankedProducts(for: rankingRequest, products: products).prefix(3)).map(\.id)
                : []
            return CoffeeConciergeResult(
                message: webResult.answer,
                productIDs: webRankedProducts,
                usedAppleIntelligence: false,
                giftMessageSuggestions: [],
                canBuildCart: requestLooksLikeCartBuild(trimmedRequest) && !isEquipmentQuestion(trimmedRequest),
                sourceURLs: webResult.sources.map(\.url)
            )
        }

        return fallback
    }

    private static func fallbackRecommendation(
        request: String,
        rankingRequest: String,
        products: [ContentView.Product],
        imageAnalysis: ImageAnalysis?
    ) -> CoffeeConciergeResult {
        let wantsProducts = requestLooksLikeProductRecommendation(request, hasImage: imageAnalysis != nil)
            && !isEquipmentQuestion(request)
        guard wantsProducts else {
            return CoffeeConciergeResult(
                message: coffeeKnowledgeFallback(for: request, imageAnalysis: imageAnalysis),
                productIDs: [],
                usedAppleIntelligence: false,
                giftMessageSuggestions: [],
                canBuildCart: false
            )
        }

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

    private struct WebResearchResponse: Decodable {
        struct Source: Decodable { let url: String }
        let answer: String
        let sources: [Source]
    }

    private struct LocalModelResponse: Decodable {
        let answer: String
        let model: String?
        let source: String?
        let usedUserContext: Bool?
    }

    private static func localModelResearch(for question: String, context: String) async -> LocalModelResponse? {
        guard let baseURL = BackendConfiguration.coffeeAIBaseURL else { return nil }
        var request = URLRequest(url: baseURL.appending(path: "/ai/coffee-concierge"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body: [String: String] = ["question": question, "context": context]
        guard let encodedBody = try? JSONEncoder().encode(body) else { return nil }
        request.httpBody = encodedBody
        do {
            let (data, response) = try await TallaSecureSession.data(for: request)
            guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else { return nil }
            let result = try JSONDecoder().decode(LocalModelResponse.self, from: data)
            return result.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : result
        } catch {
            return nil
        }
    }

    private static func shouldUseLocalModel(for request: String) -> Bool {
        let normalized = request.lowercased()
        let coffeeTerms = ["coffee", "espresso", "brew", "grind", "grinder", "bean", "roast", "v60", "pour over", "aeropress", "chemex", "kalita", "origami", "kettle", "dripper", "scale", "barista", "caffeine", "decaf", "latte", "cappuccino", "water", "filter", "dose", "yield", "extraction", "قهوة", "إسبريسو", "تحضير", "طحن", "حبوب", "تحميص", "مقطرة", "ميزان", "كافيين", "ماء"]
        guard coffeeTerms.contains(where: normalized.contains) else { return false }
        let liveOrCatalogTerms = ["latest", "current", "new", "price", "available", "buy", "cart", "shop", "catalog", "live", "الأحدث", "السعر", "متاح", "شراء"]
        return !liveOrCatalogTerms.contains(where: normalized.contains)
    }

    private static func shouldUseWebResearch(for request: String) -> Bool {
        let normalized = request.lowercased()
        let coffeeTerms = ["coffee", "espresso", "brew", "grind", "grinder", "bean", "roast", "v60", "pour over", "aeropress", "chemex", "kalita", "origami", "kettle", "dripper", "scale", "barista", "caffeine", "decaf", "latte", "cappuccino", "water", "filter", "dose", "yield", "extraction", "قهوة", "إسبريسو", "تحضير", "طحن", "حبوب", "تحميص", "مقطرة", "ميزان", "كافيين", "ماء"]
        guard coffeeTerms.contains(where: normalized.contains) else { return false }
        return ["best", "latest", "current", "new", "spec", "model", "recommend", "compare", "price", "available", "أفضل", "الأحدث", "مواصفات", "موديل", "قارن"].contains { normalized.contains($0) }
    }

    private static func webResearch(for question: String) async -> WebResearchResponse? {
        guard let baseURL = BackendConfiguration.serviceBaseURL else { return nil }
        var request = URLRequest(url: baseURL.appending(path: "/ai/research"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let body = try? JSONSerialization.data(withJSONObject: ["question": question]) else { return nil }
        request.httpBody = body
        do {
            let (data, response) = try await TallaSecureSession.data(for: request)
            guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else { return nil }
            return try JSONDecoder().decode(WebResearchResponse.self, from: data)
        } catch {
            return nil
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

    private static func requestLooksLikeProductRecommendation(_ request: String, hasImage: Bool) -> Bool {
        if hasImage && request.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        let normalized = request.lowercased()
        let recommendationVerbs = [
            "recommend", "suggest", "which coffee", "which bean", "what bean", "buy", "shop", "product",
            "gift", "under ", "budget", "choose beans", "pick for me", "compare", "where can i get", "best ",
            "أرشح", "اقترح", "أي قهوة", "شراء", "هدية", "قارن"
        ]
        if recommendationVerbs.contains(where: { normalized.contains($0) }) { return true }
        return normalized.contains("which grinder")
            || normalized.contains("what grinder")
            || normalized.contains("which brewer")
            || normalized.contains("what brewer")
            || normalized.contains("what kettle")
            || normalized.contains("best v60")
            || normalized.contains("best dripper")
            || normalized.contains("أفضل v60")
    }

    /// Equipment advice should not be converted into Talla bean/product cards.
    /// The catalog currently contains coffee and gift products, while equipment
    /// questions are answered from the Coffee AI knowledge base or web research.
    private static func isEquipmentQuestion(_ request: String) -> Bool {
        let normalized = request.lowercased()
        let equipmentTerms = [
            "grinder", "grinders", "scale", "scales", "dripper", "drippers", "brewer", "brewers",
            "kettle", "espresso machine", "coffee machine", "frothed", "frother", "milk frother",
            "equipment", "gear", "burr", "portafilter", "tamper", "filter holder", "v60", "chemex",
            "kalita", "origami", "aeropress", "french press", "moka pot", "مطحنة", "طاحونة", "ميزان",
            "معدات", "مقطرة", "ماكينة اسبريسو", "إسبريسو"
        ]
        guard equipmentTerms.contains(where: normalized.contains) else { return false }

        let explicitTallaPurchaseTerms = [
            "talla product", "talla item", "from talla", "in the shop", "in your shop", "catalog",
            "buy this", "add this", "add to cart", "اشتري", "أضف للسلة", "من تالا"
        ]
        return !explicitTallaPurchaseTerms.contains(where: normalized.contains)
    }

    private static func coffeeKnowledgeFallback(for request: String, imageAnalysis: ImageAnalysis?) -> String {
        let normalized = request.lowercased()
        if normalized.contains("timemore") || normalized.contains("acaia") || normalized.contains("felicita") || normalized.contains("hario scale") || normalized.contains("black mirror") {
            return "For scales, the brand changes features more than the brewing logic: Acaia Lunar/Pearl emphasize fast response and flow-rate tools; Timemore Black Mirror models are common value options; Hario scales are simple recipe timers; Felicita models vary by size and water resistance. Use grams, tare the vessel, start the timer consistently, and validate unstable readings with a known weight. Keep water away from ports and check the exact model’s waterproof rating before rinsing. What model, brew method, and reading problem do you have?"
        }
        if normalized.contains("fellow") || normalized.contains("brewista") || normalized.contains("hario buono") || normalized.contains("bonavita") || normalized.contains("timemore kettle") || normalized.contains("brewista kettle") {
            return "Kettle guidance depends on control and temperature stability: Fellow Stagg EKG and Brewista Artisan offer temperature control with different flow and interfaces; Hario Buono is a manual-control classic; Bonavita is a straightforward gooseneck; Timemore Fish models emphasize controlled pouring. A gooseneck helps pour-over, while a regular spout is fine for immersion. Verify temperature with a reference thermometer, descale mineral buildup, and never run an electric kettle dry. Which model and brew method are you using?"
        }
        if normalized.contains("sage") || normalized.contains("breville") || normalized.contains("delonghi") || normalized.contains("gaggia") || normalized.contains("rancilio") || normalized.contains("la marzocco") || normalized.contains("rocket") || normalized.contains("profitec") || normalized.contains("lelit") || normalized.contains("flair") || normalized.contains("caf el") || normalized.contains("ascaso") {
            return "For espresso machines, the brand is only the starting point: Breville/Sage models often expose automated temperature and pre-infusion controls; De’Longhi focuses on convenience; Gaggia and Rancilio commonly use more traditional workflows; Lelit, Profitec, Rocket, and La Marzocco span heat-exchanger and dual-boiler designs; Flair is manual and has no pump. Diagnose with dose, yield, time, temperature, pressure, basket, and puck prep before changing settings. Never open a hot or pressurized machine. What exact model, basket size, dose, yield, and shot time are you using?"
        }
        if normalized.contains("comandante") || normalized.contains("1zpresso") || normalized.contains("1zpresso") || normalized.contains("baratza") || normalized.contains("mazzer") || normalized.contains("df64") || normalized.contains("niche") || normalized.contains("eureka") || normalized.contains("timemore grinder") || normalized.contains("kingrinder") {
            return "Grinder advice is model-specific. Comandante and 1Zpresso hand grinders are portable and tactile; Baratza is known for serviceable home grinders; Eureka models often target espresso with stepless adjustment; Niche, DF, and Mazzer families differ in burr size, workflow, retention, and alignment. Never transfer a dial number between brands. Calibrate from the manual’s zero/reference point, change one variable at a time, and purge carefully after large adjustments. What exact grinder, burr type, brew method, and symptom are you seeing?"
        }
        if normalized.contains("aeropress") || normalized.contains("french press") || normalized.contains("moka") || normalized.contains("chemex") || normalized.contains("origami") || normalized.contains("kalita") || normalized.contains("clever") || normalized.contains("tricolate") || normalized.contains("siphon") {
            return "Brewer geometry and filter design matter: AeroPress and Clever use immersion with paper filtration; French press uses metal filtration and more body; moka pot uses steam pressure and should not be tamped; Chemex uses a thick paper filter and a clean cup; V60 and Origami are cone-style and sensitive to pour pattern; Kalita is flat-bottom and often more forgiving; siphon and Tricolate have their own flow and agitation behavior. Start with a known ratio, then adjust grind and agitation one at a time. Which brewer and filter are you using?"
        }
        if normalized.contains("fellow") && normalized.contains("grinder") {
            return "If this is a Fellow Ode, that is probably the limitation: Ode Gen 1 and Gen 2 are intended for filter coffee and are not espresso grinders. Do not force the burrs. Check for beans or a foreign object blocking the burrs, unplug it, brush and purge the chamber, then try again. If it is a Fellow Opus, use its espresso range and recalibrate the burrs. Which Fellow model and setting are you using?"
        }
        if normalized.contains("scale") || normalized.contains("weigh") || normalized.contains("ميزان") {
            return "For a coffee scale, place it on a stable level surface, confirm the units are grams, tare the brewer and vessel separately, and start the timer consistently. If readings jump, remove drafts and vibration, check the battery, clean liquid from the buttons, and test with a known weight. For espresso, use dose and yield; for pour-over, track dose, water, time, and final yield. What scale model and symptom are you seeing?"
        }
        if normalized.contains("dripper") || normalized.contains("v60") || normalized.contains("kalita") || normalized.contains("chemex") || normalized.contains("origami") {
            return "Dripper geometry changes flow: cone brewers concentrate flow at the tip, while flat-bottom brewers spread the bed. Start with a 1:16 ratio, rinse the filter, use water around 93–96°C, bloom for 30–45 seconds, and pour steadily. Fast drawdown usually needs a finer grind or less agitation; slow drawdown needs a coarser grind or gentler pouring. Which dripper and filter are you using?"
        }
        if normalized.contains("kettle") || normalized.contains("gooseneck") || normalized.contains("غلاية") {
            return "A gooseneck kettle gives better control over flow and agitation. Keep the pour gentle for a cleaner cup and increase agitation only when extraction is low. Check temperature accuracy with a reference thermometer, descale mineral buildup, and never run an electric kettle dry. What brew method and temperature are you targeting?"
        }
        if normalized.contains("espresso machine") || normalized.contains("pressure") || normalized.contains("bar") {
            return "For espresso-machine diagnosis, separate the variables: dose, grind, yield, time, temperature, and pressure. Start with a consistent 18 g dose and 36 g yield, then change only grind. Low flow can come from a fine grind, clogged basket, poor distribution, or a dirty group; low pressure can indicate too little resistance, a leak, or a pump issue. What machine, basket, dose, yield, and shot time do you have?"
        }
        if normalized.contains("water") || normalized.contains("hard") || normalized.contains("tds") || normalized.contains("alkalinity") {
            return "Water affects extraction and machine health. For coffee, aim for balanced mineral content rather than zero-mineral water; excessive alkalinity can flatten acidity, while very hard water causes scale. Use filtered water appropriate for your machine, measure consistently, and descale according to the manufacturer—not by taste alone. What water source and brew method are you using?"
        }
        if normalized.contains("clean") || normalized.contains("descal") || normalized.contains("maintenance") || normalized.contains("service") {
            return "Coffee equipment needs different maintenance: brush grinder burrs and purge retention, backflush espresso groups as specified by the manufacturer, rinse and dry brewers, replace filters when flow changes, and descale only when the machine supports it. Never use water or chemicals inside a grinder motor. Which equipment are you maintaining?"
        }
        if normalized.contains("sour") || request.contains("حامض") || request.contains("حامضة") {
            return "Sour coffee usually means under-extraction. Try one change at a time: grind finer, raise water temperature to about 94–96°C, or extend brew time. For espresso, slow the shot slightly; for pour-over, pour more slowly and keep the bed evenly saturated."
        }
        if normalized.contains("bitter") || request.contains("مر") || request.contains("مرة") {
            return "Bitter coffee is often over-extracted. Try a slightly coarser grind, cooler water around 90–93°C, or a shorter brew. Also check that the coffee is fresh and that the dose-to-water ratio is not too strong."
        }
        if normalized.contains("weak") || normalized.contains("watery") || request.contains("خفيف") {
            return "For a weak or watery cup, keep the grind the same and increase the dose slightly, or reduce the water. A good starting point is a 1:16 coffee-to-water ratio, then adjust to taste."
        }
        if normalized.contains("espresso") {
            return "Start with a 1:2 espresso ratio—for example, 18 g in and about 36 g out—in roughly 25–32 seconds. If it tastes sour, grind finer or increase contact time; if bitter, grind coarser or shorten the shot."
        }
        if normalized.contains("pour over") || normalized.contains("v60") || normalized.contains("filter") || normalized.contains("brew") {
            return "For a balanced filter brew, start around 1:16 coffee to water, 93–96°C water, and a medium-fine grind. Bloom with about twice the coffee weight for 30–45 seconds, then pour steadily. Adjust grind before changing everything else."
        }
        if normalized.contains("store") || normalized.contains("fresh") || normalized.contains("storage") {
            return "Keep coffee in an airtight, opaque container away from heat, light, and moisture. Buy an amount you can finish while it is fresh, and grind immediately before brewing. Avoid storing beans in the refrigerator because condensation can damage them."
        }
        if normalized.contains("caffeine") {
            return "Caffeine depends mainly on dose, bean type, and brew method—not simply roast level. Use a smaller dose or a lower-caffeine bean if you want less; decaf is the most reliable reduction."
        }
        if let imageAnalysis, !imageAnalysis.summary.isEmpty {
            return "I can use the image as a coffee clue, but I need one detail to give useful advice: are you trying to identify the beans, reproduce the drink, or fix a brewing problem?"
        }
        return "I can help you diagnose a cup, choose a recipe, understand beans and roasting, or improve your equipment setup. Tell me your brew method, coffee dose, water amount, time, and what the cup tastes like."
    }

    private static func equipmentRecommendationFallback(for request: String) -> String? {
        let normalized = request.lowercased()
        let asksForRecommendation = [
            "best", "recommend", "recommendation", "which", "what should i buy", "compare", "top",
            "أفضل", "أرشح", "ترشيح", "أي", "قارن"
        ].contains { normalized.contains($0) }
        guard asksForRecommendation else { return nil }

        if normalized.contains("grinder") || normalized.contains("grinders") || normalized.contains("مطحنة") || normalized.contains("طاحونة") {
            if normalized.contains("espresso") || normalized.contains("إسبريسو") {
                return "For espresso, start with the Baratza Encore ESP for a budget-friendly choice, the DF54 for a strong single-dose flat-burr option, or the Eureka Mignon Specialita for a quieter timed workflow. Choose the Niche Zero when low-retention single dosing matters most. Tell me your budget and whether you prefer single dosing or a hopper."
            }
            if normalized.contains("pour over") || normalized.contains("pourover") || normalized.contains("filter") || normalized.contains("drip") {
                return "For pour-over, the Fellow Ode Gen 2 is a strong clarity-focused electric choice, the Timemore Sculptor 078 is a premium option, and the Baratza Encore is a dependable budget pick. For manual grinding, consider the 1Zpresso K-Ultra or KINGrinder K6. The Ode and most filter grinders are not suitable for espresso. Tell me your budget and whether you want electric or manual."
            }
            return "For one grinder that covers multiple methods, consider the 1Zpresso K-Ultra for manual use, the Baratza Encore ESP for a lower-cost electric option, or the DF54 for single dosing and espresso flexibility. Choose based on your main brew method, budget, and whether you prefer speed or portability."
        }

        if normalized.contains("scale") || normalized.contains("scales") || normalized.contains("ميزان") {
            return "For pour-over, the BOOKOO Themis Ultra is the most feature-rich option, the Timemore Black Mirror is a strong everyday value, and the OXO Precision Scale is a simple budget choice. For espresso, choose the compact Acaia Lunar or a Timemore Nano-style scale that fits your drip tray. Prioritize 0.1 g resolution, fast response, a timer, and water resistance."
        }

        if normalized.contains("dripper") || normalized.contains("v60") || normalized.contains("chemex") || normalized.contains("kalita") {
            return "For pour-over, choose the Hario V60 for clarity and control, the Kalita Wave 185 for a more forgiving balanced brew, the Hario Switch for immersion plus pour-over, or the Chemex when serving several people. The V60 is the best starting point if you want to learn pouring and dialing-in."
        }

        if normalized.contains("espresso machine") || normalized.contains("coffee machine") || normalized.contains("ماكينة") {
            return "For home espresso, the Breville Bambino Plus is a compact beginner-friendly choice, the Gaggia Classic Pro offers a more traditional workflow, and the Lelit Bianca is a high-end dual-boiler option with flow control. Choose based on milk drinks, workflow, budget, and whether you want a built-in grinder."
        }

        return nil
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

    nonisolated private static func cleanModelMessage(_ content: String) -> String? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let data = trimmed.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return trimmed
        }

        for key in ["message", "answer", "response", "description"] {
            if let value = dictionary[key] as? String {
                let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty { return cleaned }
            }
        }
        return nil
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
            You are Talla AI, an expert coffee coach, roaster, barista, and equipment technician. Answer only coffee-related questions. Build answers from first principles and model-specific knowledge across beans, origins, varietals, processing, roasting, freshness, storage, grinding, burr geometry, grinder calibration, retention, alignment, static, espresso, pour-over, V60, Kalita, Chemex, Origami, French press, AeroPress, moka pot, cezve, batch brewers, cold brew, immersion, siphon, recipes, dose, ratio, yield, brew time, agitation, water chemistry, temperature, filters, kettles, goosenecks, scales, timers, refractometers, espresso machines, boilers, pumps, pressure, flow control, portafilters, baskets, tampers, distribution, puck prep, steam wands, milk, cleaning, descaling, maintenance, and sensory tasting. Recognize major equipment families and brands when the customer names them, including Fellow, Baratza, Eureka, Niche, Mazzer, DF, Comandante, 1Zpresso, Timemore, Acaia, Felicita, Hario, Brewista, Bonavita, Breville/Sage, De’Longhi, Gaggia, Rancilio, Lelit, Profitec, Rocket, La Marzocco, Ascaso, Flair, AeroPress, Chemex, Hario, Kalita, Origami, Clever, Tricolate, and Bunn. Never invent a model specification; if a model generation matters, say so and ask for the exact model.
            If the request is not coffee-related, politely say you can help only with coffee. When the customer asks for the best, a recommendation, or a product comparison, answer directly with the best matching catalog item first, explain why in one or two sentences, then ask at most one optional follow-up question. Do not make the customer provide dose, water, time, or taste details before answering a simple product question. Keep answers practical, specific, and under 100 words. Do not invent products, prices, discounts, stock, policies, or medical claims. If the request is Arabic, answer in Arabic.
            Think like a skilled barista, roaster, and service technician: identify likely causes, explain the mechanism, give a safe ordered test, state what result to expect, and ask one focused follow-up question when equipment model or measurements are missing. Never claim a setting is universal across models. For scales, cover tare, auto-start, timer, flow-rate, Bluetooth, battery, waterproofing, calibration, and measurement error. For grinders, cover burrs, calibration, grind range, retention, clogging, alignment, and motor safety. For drippers, cover geometry, bypass, filter fit, agitation, drawdown, and recipe adjustment. The catalog is authoritative only when product recommendations are requested.
            Use Celsius values appropriate for coffee brewing; normal V60 water is roughly 90–96°C, never 205°C.
            Think like a skilled barista: diagnose the likely cause, explain why, give an ordered experiment, include useful ratios/temperatures/times when relevant, and ask one focused follow-up question when key information is missing. Use the customer's brew method, dose, water, time, and taste. The catalog is authoritative only when product recommendations are requested.
            """
        )

        let imageContext = imageAnalysis?.summary.isEmpty == false
            ? "Local Vision detected these shopping signals: \(imageAnalysis?.summary ?? ""). Use them as hints only, and recommend only catalog products."
            : "No useful image signals."

        let prompt = """
        Customer request: \(request.isEmpty ? "Recommend a good starting point" : request)
        Ranked request context: \(rankingRequest)
        Image context: \(imageContext)
        The customer asked one question. Answer that question directly. Do not add unrelated recommendations, shopping, gift ideas, or background information unless the question asks for them.
        If this is a product question, use the available catalog and name the best matching catalog item in the first sentence. Never answer a product question with only a request for more brewing measurements.
        If the request is ambiguous, ask one short clarifying question instead of guessing.
        Relevant local learning from earlier conversations (use only when it matches the current question):
        \(memoryContext(for: request))

        Research-backed baseline guidance:
        - A useful starting point for filter brewing is about 55 g coffee per litre of water, then adjust to taste; this is a baseline, not a universal recipe.
        - Water quality matters: balanced mineral content and moderate alkalinity support extraction; very hard water can cause scale and very low-mineral water can taste flat.
        - Fellow Ode is designed for brewed coffee and is not an espresso grinder; Fellow Opus is designed to cover espresso through cold brew. Never force a grinder burr or put fingers near powered burrs.
        - For equipment safety, distinguish user-safe checks from disassembly or electrical repairs and direct the customer to the manufacturer when needed.

        Brand and equipment reference:
        \(equipmentKnowledge)

        Available catalog:
        \(catalog)
        """

        let response = try await session.respond(to: prompt)
        guard let content = cleanModelMessage(response.content) else { throw ConciergeError.unavailable }
        guard isRelevant(content, to: request) else { throw ConciergeError.unavailable }
        let fallbackMessages = giftMessageSuggestions(for: request)
        return (content, fallbackMessages, requestLooksLikeCartBuild(request), rankingRequest.split(separator: " ").map(String.init))
    }

    private static func isRelevant(_ answer: String, to request: String) -> Bool {
        let questionTerms = Set(request.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 3 })
        guard !questionTerms.isEmpty else { return true }
        let answerTerms = Set(answer.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init))
        let coffeeTerms = ["coffee", "espresso", "brew", "grind", "water", "temperature", "filter", "ratio", "dose", "yield", "roast", "bean", "machine", "kettle", "scale", "dripper", "قهوة", "إسبريسو", "طحن", "ماء"]
        return !questionTerms.isDisjoint(with: answerTerms) || coffeeTerms.contains { answer.lowercased().contains($0) }
    }

    private static func isGenericDeflection(_ answer: String) -> Bool {
        let normalized = answer.lowercased()
        return normalized.hasPrefix("i can help only with coffee")
            || normalized == "i can help with coffee questions."
            || (normalized.contains("to determine the best") && normalized.contains("must first clarify"))
    }
#endif
}
