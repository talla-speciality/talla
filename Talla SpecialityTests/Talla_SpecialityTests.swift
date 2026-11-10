import Foundation
import CoreGraphics
import Testing
import SwiftData
@testable import Talla_Speciality

@MainActor
struct Talla_SpecialityTests {

    @Test func brewTimerUsesMonotonicUptimeAndClampsAtZero() {
        #expect(monotonicBrewTimerRemainingSeconds(endUptime: 125.2, nowUptime: 120.0) == 6)
        #expect(monotonicBrewTimerRemainingSeconds(endUptime: 120.0, nowUptime: 125.0) == 0)
    }

    @Test func orderDeepLinkParsesExactOrderIdentifiers() {
        #expect(TallaOrderDeepLink.parse(URL(string: "talla://orders/order-123")!) == .order(id: "order-123"))
        #expect(TallaOrderDeepLink.parse(URL(string: "talla://orders?order=order-456")!) == .order(id: "order-456"))
        #expect(TallaOrderDeepLink.parse(URL(string: "https://talla.me/account/orders/order-789")!) == .order(id: "order-789"))
        #expect(TallaOrderDeepLink.parse(URL(string: "https://www.talla.me/account/orders?orderId=order-999")!) == .order(id: "order-999"))
        #expect(TallaOrderDeepLink.parse(URL(string: "https://talla.me/app/orders/Order-ABC")!) == .order(id: "Order-ABC"))
    }

    @Test func orderDeepLinkFallsBackToOrderHistoryRoot() {
        #expect(TallaOrderDeepLink.parse(URL(string: "https://talla.me/account/orders")!) == .orders)
        #expect(TallaOrderDeepLink.parse(URL(string: "https://example.com/account/orders/order-123")!) == nil)
        #expect(TallaOrderDeepLink.parse(URL(string: "https://talla.me/products/coffee?order=order-123")!) == nil)
    }

    @Test func duoLayoutContextIdentifiesVerticalDisplayDivision() {
        #expect(
            DuoLayoutContext(
                divisionFrames: [CGRect(x: 390, y: 0, width: 12, height: 844)],
                hingeAngle: nil,
                hingeStatus: .fullyOpen
            ).hasVerticalDivision
        )
        #expect(
            !DuoLayoutContext(
                divisionFrames: [CGRect(x: 0, y: 390, width: 844, height: 12)],
                hingeAngle: nil,
                hingeStatus: .fullyOpen
            ).hasVerticalDivision
        )
    }

    @Test func duoLayoutContextPreservesHingeStateWithoutDivision() {
        let context = DuoLayoutContext(divisionFrames: [], hingeAngle: 1.2, hingeStatus: .partiallyOpen)
        #expect(context.divisionFrames.isEmpty)
        #expect(context.hingeAngle == 1.2)
        #expect(context.hingeStatus == .partiallyOpen)
    }

    @Test func catalogCacheRoundTripsProducts() throws {
        let variant = ContentView.Product.Variant(
            id: "cache-variant",
            title: "Standard",
            price: "5.000 BHD",
            isAvailableForSale: true,
            requiresShipping: true,
            weightGrams: 250
        )
        let product = ContentView.Product(
            id: "cache-product",
            handle: "cache-product",
            variantID: variant.id,
            variants: [variant],
            name: "Cache Test Coffee",
            price: "5.000 BHD",
            categoryKey: "coffee",
            categoryLabel: "Coffee",
            imageURL: URL(string: "https://example.com/coffee.png"),
            desc: "A cache test product",
            tag: "Test",
            tags: ["test"],
            countryOfOrigin: "Bahrain",
            isAvailableForSale: true
        )

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try TallaCatalogCache.save([product], languageCode: "en", directory: directory)
        let restored = try #require(TallaCatalogCache.load(languageCode: "en", directory: directory))
        #expect(restored == [product])
        #expect(TallaCatalogCache.load(languageCode: "ar", directory: directory) == nil)
        try TallaCatalogCache.save([], languageCode: "ar", directory: directory)
        #expect(TallaCatalogCache.load(languageCode: "ar", directory: directory) == [])
        #expect(TallaCatalogCache.load(languageCode: "en", directory: directory) == [product])
    }

    @Test func soldOutProductsBecomeVisibleOnlyWhenARefreshReportsStock() {
        let unavailableVariant = ContentView.Product.Variant(
            id: "stock-variant",
            title: "Standard",
            price: "5.000 BHD",
            isAvailableForSale: false,
            requiresShipping: true,
            weightGrams: 250
        )
        let soldOut = ContentView.Product(
            id: "stock-product",
            handle: "stock-product",
            variantID: unavailableVariant.id,
            variants: [unavailableVariant],
            name: "Stock Test Coffee",
            price: "5.000 BHD",
            categoryKey: "coffee-beans",
            categoryLabel: "Coffee",
            imageURL: nil,
            desc: "",
            tag: nil,
            countryOfOrigin: nil,
            isAvailableForSale: false
        )
        #expect(!soldOut.isPurchasable)

        let availableVariant = ContentView.Product.Variant(
            id: unavailableVariant.id,
            title: unavailableVariant.title,
            price: unavailableVariant.price,
            isAvailableForSale: true,
            requiresShipping: unavailableVariant.requiresShipping,
            weightGrams: unavailableVariant.weightGrams
        )
        let restocked = ContentView.Product(
            id: soldOut.id,
            handle: soldOut.handle,
            variantID: availableVariant.id,
            variants: [availableVariant],
            name: soldOut.name,
            price: soldOut.price,
            categoryKey: soldOut.categoryKey,
            categoryLabel: soldOut.categoryLabel,
            imageURL: nil,
            desc: "",
            tag: nil,
            countryOfOrigin: nil,
            isAvailableForSale: true
        )
        #expect(restocked.isPurchasable)
    }

    @Test func remoteSettingsCacheRoundTripsRawJSON() throws {
        let data = Data(#"{"release":{"latestVersion":"1.0.0"}}"#.utf8)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try TallaRemoteSettingsCache.saveAppSettings(data, directory: directory)
        #expect(TallaRemoteSettingsCache.loadAppSettings(directory: directory) == data)
    }

    private func conciergeProduct(
        id: String,
        name: String,
        price: String,
        categoryKey: String,
        desc: String
    ) -> ContentView.Product {
        let variant = ContentView.Product.Variant(
            id: "\(id)-variant",
            title: "Standard",
            price: price,
            isAvailableForSale: true,
            requiresShipping: true,
            weightGrams: nil
        )
        return ContentView.Product(
            id: id,
            handle: id,
            variantID: variant.id,
            variants: [variant],
            name: name,
            price: price,
            categoryKey: categoryKey,
            categoryLabel: categoryKey,
            imageURL: nil,
            desc: desc,
            tag: nil,
            tags: [],
            countryOfOrigin: nil,
            isAvailableForSale: true
        )
    }

    @Test func conciergeRanksChocolateGiftWithinBudgetAndOffersCartBuild() async {
        let products = [
            conciergeProduct(id: "chocolate-gift", name: "Chocolate Gift Box", price: "18.000 BHD", categoryKey: "gifts", desc: "Chocolate for sharing"),
            conciergeProduct(id: "coffee-set", name: "Coffee Set", price: "24.000 BHD", categoryKey: "gifts", desc: "A larger gift set")
        ]

        let result = await CoffeeConciergeService.recommend(
            request: "add a gift under 20 BHD for my friend who likes chocolate",
            products: products,
            localeIdentifier: "en"
        )

        #expect(result.productIDs == ["chocolate-gift"])
        #expect(result.canBuildCart)
        #expect(!result.giftMessageSuggestions.isEmpty)
    }

    @Test func conciergeDoesNotAttachCoffeeProductsToEquipmentAdvice() async {
        let products = [
            conciergeProduct(id: "durrat", name: "Durrat Al-Bahrain", price: "5.000 BHD", categoryKey: "coffee", desc: "Sweet and balanced coffee"),
            conciergeProduct(id: "v60-filters", name: "V60 Filters", price: "2.000 BHD", categoryKey: "coffee", desc: "Paper filters")
        ]

        let result = await CoffeeConciergeService.recommend(
            request: "What's the best espresso grinder?",
            products: products,
            localeIdentifier: "en",
            allowWebResearch: false
        )

        #expect(result.productIDs.isEmpty)
        #expect(!result.canBuildCart)
    }

    @Test func conciergeAnswersEquipmentRecommendationsWithEquipment() async {
        let result = await CoffeeConciergeService.recommend(
            request: "What's the best pour over grinder?",
            products: [],
            localeIdentifier: "en",
            allowWebResearch: false
        )

        #expect(result.message.contains("Fellow Ode Gen 2"))
        #expect(result.message.contains("1Zpresso K-Ultra"))
        #expect(result.productIDs.isEmpty)
        #expect(!result.canBuildCart)
    }

    @Test func socialCoffeeLinksAcceptPublishedPagesAndLegacyRoutes() {
        let id = "0123456789abcdef"
        let invite = "0123456789abcdef0123456789abcdef"
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://talla.me/pages/group-coffee-order?id=\(id)&invite=\(invite)")!) == .group(id: id, inviteCode: invite))
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://www.talla.me/app/group-order?id=\(id)&invite=\(invite)")!) == .group(id: id, inviteCode: invite))
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://talla.me/pages/coffee-gift?order=checkout_1234")!) == .gift(orderID: "checkout_1234", token: nil))
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://talla.me/app/suspended-coffee?order=checkout_1234")!) == .gift(orderID: "checkout_1234", token: nil))
        let token = String(repeating: "a", count: 64)
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://talla.me/pages/coffee-gift?order=checkout_1234#\(token)")!) == .gift(orderID: "checkout_1234", token: token))
    }

    @Test func socialCoffeeLinksRejectForeignHostsAndMalformedInvites() {
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://other.example/pages/coffee-gift?order=checkout_1234")!) == nil)
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://talla.me/pages/group-coffee-order?id=bad&invite=bad")!) == nil)
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://talla.me/pages/coffee-gift?order=x")!) == nil)
        #expect(SocialCoffeeSharedLink.parse(URL(string: "https://talla.me/pages/coffee-gift?order=checkout_1234#bad")!) == nil)
    }

    @Test func caffeineEstimateUsesDoseAndBrewStyle() {
        #expect(TallaCaffeineEstimator.estimate(milligramsForDoseGrams: 20, method: "V60") == 200)
        #expect(TallaCaffeineEstimator.estimate(milligramsForDoseGrams: 18, method: "Espresso") == 117)
        #expect(TallaCaffeineEstimator.estimate(milligramsForDoseGrams: nil, method: "V60") == nil)
    }

    private func smartInput(
        brewMode: String = "Hot",
        brewerID: String = "v60",
        process: String = "Washed",
        tasteGoal: String = "balanced",
        dose: Double = 20,
        ratio: Double = 16
    ) -> SmartBrewInput {
        SmartBrewInput(
            coffeeGrams: dose,
            ratio: ratio,
            brewerID: brewerID,
            brewMode: brewMode,
            roast: "Light",
            process: process,
            tasteGoal: tasteGoal,
            altitudeMeters: 1_900,
            daysOffRoast: 14,
            grinder: "Fellow Ode Gen 2",
            bloomPreference: "Auto",
            requestedPourCount: 3,
            controlMode: "Manual"
        )
    }

    @Test func smartRecipeKeepsDoseRatioInvariantAndAvoidsSixtyGramBloom() {
        let recipe = SmartBrewRecipeEngine.generate(smartInput())

        #expect(recipe.totalWaterGrams == 320)
        #expect(recipe.brewingWaterGrams == 320)
        #expect(recipe.iceGrams == 0)
        #expect(recipe.bloomWaterGrams == 50)
        #expect(recipe.steps.first(where: { $0.title == "Bloom" })?.cumulativeWater == 50)
    }

    @Test func smartRecipeUsesCoffeeSpecificBloomInsteadOfFixedSixtyGrams() {
        let natural = SmartBrewRecipeEngine.generate(smartInput(process: "Anaerobic Natural"))
        let darkInput = SmartBrewInput(coffeeGrams: 18, ratio: 16, brewerID: "v60", brewMode: "Hot", roast: "Dark", process: "Natural", tasteGoal: "body", altitudeMeters: nil, daysOffRoast: 10, grinder: "Comandante C40", bloomPreference: "1:2", requestedPourCount: 3, controlMode: "Manual")
        let dark = SmartBrewRecipeEngine.generate(darkInput)

        #expect(natural.bloomWaterGrams == 45)
        #expect(dark.bloomWaterGrams == 36)
    }

    @Test func icedRecipeAddsIceFirstAndGuidesOnlyHotWaterTargets() {
        let recipe = SmartBrewRecipeEngine.generate(smartInput(brewMode: "Iced"))

        #expect(recipe.totalWaterGrams == 320)
        #expect(recipe.brewingWaterGrams == 192)
        #expect(recipe.iceGrams == 128)
        #expect(recipe.steps.first?.title == "Add ice")
        #expect(recipe.steps.first?.instruction.contains("128 g") == true)
        #expect(recipe.steps.compactMap(\.cumulativeWater).max() == 192)
    }

    @Test func processAndBrewerGeometryChangeTheGeneratedRecipe() {
        let washedCone = SmartBrewRecipeEngine.generate(smartInput(process: "Washed"))
        let fermentedFlat = SmartBrewRecipeEngine.generate(smartInput(brewerID: "kalita", process: "Extended Anaerobic"))

        #expect(washedCone.bloomDurationSeconds != fermentedFlat.bloomDurationSeconds)
        #expect(washedCone.temperatureC != fermentedFlat.temperatureC)
        #expect(washedCone.steps != fermentedFlat.steps)
        #expect(fermentedFlat.steps.contains(where: { $0.instruction.contains("do not swirl") }))
    }

    @Test func grinderCatalogProducesUsableSetting() {
        let recipe = SmartBrewRecipeEngine.generate(smartInput())

        #expect(recipe.grinderSetting.contains("Ode"))
        #expect(recipe.grinderSetting.contains("μm"))
    }

    @Test func tallaDialInCalibrationChangesFutureRecipesForThatCoffee() {
        let baseline = SmartBrewRecipeEngine.generate(smartInput())
        let input = SmartBrewInput(
            coffeeGrams: 20,
            ratio: 16,
            brewerID: "v60",
            brewMode: "Hot",
            roast: "Light",
            process: "Washed",
            tasteGoal: "balanced",
            altitudeMeters: 1_900,
            daysOffRoast: 14,
            grinder: "Fellow Ode Gen 2",
            bloomPreference: "Auto",
            requestedPourCount: 3,
            controlMode: "Manual",
            calibration: SmartBrewCalibration(
                grindMicronOffset: 35,
                temperatureOffset: -1,
                pourCountOffset: 1,
                preferredAgitation: "Gentle",
                brewCount: 2,
                lastFeedback: ["Dry or astringent"]
            )
        )
        let calibrated = SmartBrewRecipeEngine.generate(input)

        #expect(calibrated.grindMicrons == baseline.grindMicrons + 35)
        #expect(calibrated.temperatureC == baseline.temperatureC - 1)
        #expect(calibrated.agitation == "Gentle")
        #expect(calibrated.steps.count == baseline.steps.count + 1)
    }

    @Test func smartScaleAdvancesWhenARealPourCrossesItsTarget() {
        #expect(SmartScaleGuidanceRules.shouldAdvance(
            isConnected: true,
            isRunning: true,
            waterAdded: 100,
            stepTitle: "Pour 1",
            previousWeight: 147,
            currentWeight: 149.5,
            targetWeight: 150
        ))
    }

    @Test func smartScaleNeverSkipsBloomWaitOrPreparationSteps() {
        #expect(!SmartScaleGuidanceRules.shouldAdvance(isConnected: true, isRunning: true, waterAdded: 50, stepTitle: "Bloom", previousWeight: 48, currentWeight: 50, targetWeight: 50))
        #expect(!SmartScaleGuidanceRules.shouldAdvance(isConnected: true, isRunning: true, waterAdded: nil, stepTitle: "Add ice", previousWeight: 0, currentWeight: 128, targetWeight: 128))
        #expect(!SmartScaleGuidanceRules.shouldAdvance(isConnected: false, isRunning: true, waterAdded: 100, stepTitle: "Pour 1", previousWeight: 149, currentWeight: 150, targetWeight: 150))
    }

    @Test func generatedScaleGuidanceUsesBrewerSpecificFlowRates() {
        let cone = SmartBrewRecipeEngine.generate(smartInput())
        let flat = SmartBrewRecipeEngine.generate(smartInput(brewerID: "kalita"))
        let conePour = cone.steps.first { $0.title == "Pour 1" }
        let flatPour = flat.steps.first { $0.title == "Pour 1" }

        #expect(conePour?.flowRate == "2–3 g/s")
        #expect(flatPour?.flowRate == "3–4 g/s")
    }

    @Test func icedRecipeSplitsTotalWaterWithoutChangingTheRequestedRatio() {
        let split = BrewRecipeMath.waterSplit(totalWater: 320, isIced: true)

        #expect(split.brewingWater == 192)
        #expect(split.ice == 128)
        #expect(split.brewingWater + split.ice == 320)
    }

    @Test func automaticBloomAvoidsGenericSixtyGramFirstPour() {
        let multiplier = BrewRecipeMath.suggestedBloomMultiplier(
            roast: "Light",
            process: "Washed",
            tasteGoal: "balanced"
        )

        #expect(multiplier == 2.5)
        #expect(20 * multiplier == 50)
    }

    @Test func automaticBloomIsGentlerForDarkAndHighlySolubleCoffees() {
        #expect(BrewRecipeMath.suggestedBloomMultiplier(roast: "Dark", process: "Washed", tasteGoal: "balanced") == 2)
        #expect(BrewRecipeMath.suggestedBloomMultiplier(roast: "Light", process: "Natural", tasteGoal: "balanced") == 2.25)
    }

    @Test func freeDrinkRewardDoesNotDiscountNonDrinks() {
        let discount = LoyaltyVoucherRules.freeDrinkDiscount(lines: [
            (categoryKey: "coffee-beans", unitPrice: 6.500, quantity: 1),
            (categoryKey: "coffee-equipment", unitPrice: 18.000, quantity: 1)
        ])

        #expect(discount == 0)
    }

    @Test func freeDrinkRewardDiscountsOneHighestPricedEligibleDrink() {
        let discount = LoyaltyVoucherRules.freeDrinkDiscount(lines: [
            (categoryKey: "coffee-beans", unitPrice: 6.500, quantity: 1),
            (categoryKey: "ready-made-drinks", unitPrice: 1.800, quantity: 2),
            (categoryKey: "summer-drinks", unitPrice: 12.000, quantity: 1)
        ])

        #expect(discount == 1.800)
    }

    @Test func freeDrinkRewardDiscountsOnlyOneUnit() {
        let discount = LoyaltyVoucherRules.freeDrinkDiscount(lines: [
            (categoryKey: "ready-made-drinks", unitPrice: 1.500, quantity: 4)
        ])

        #expect(discount == 1.500)
    }

    @Test func excludesGiftCardsFromCatalog() {
        #expect(ProductCatalogRules.shouldInclude(title: "Gift Card", productType: "", tags: [] ) == false)
        #expect(ProductCatalogRules.shouldInclude(title: "House Beans", productType: "Coffee", tags: [] ) == true)
    }

    @Test func mapsGiftBoxesToGiftsCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: ["Seasonal"],
            title: "Mini Box"
        )

        #expect(key == "gifts")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Talla Boxes")
    }

    @Test func mapsSeasonalGiftProductsToGiftsCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Seasonal Gifts",
            tags: ["Majlis"],
            title: "Morning Gift Box"
        )

        #expect(key == "gifts")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Talla Boxes")
    }

    @Test func mapsTeaToDrinks() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Tea",
            tags: [],
            title: "Karak Tea"
        )

        #expect(key == "ready-made-drinks")
        #expect(ProductCatalogRules.categoryLabel(productType: "Tea", fallbackKey: key) == "Drinks")
    }

    @Test func mapsDessertSignalsToDessertsCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: ["gift"],
            title: "Date Cookies"
        )

        #expect(key == "desserts")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "CRMB")
    }

    @Test func mapsFudgeAndCremeCaramelToDessertsBeforeBoxes() {
        let fudgeKey = ProductCatalogRules.categoryKey(
            productType: "Gift Box",
            tags: ["gift"],
            title: "Chocolate Fudge"
        )
        let caramelKey = ProductCatalogRules.categoryKey(
            productType: "Seasonal Gifts",
            tags: ["box"],
            title: "Creme Caramel"
        )

        #expect(fudgeKey == "desserts")
        #expect(caramelKey == "desserts")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: fudgeKey) == "CRMB")
    }

    @Test func mapsSpreadsSeparatelyFromDesserts() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: ["jar"],
            title: "Pistachio Spread"
        )

        #expect(key == "spreads")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Spreads")
    }

    @Test func mapsCupsToCups() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Drink Cups",
            tags: [],
            title: "Talla Ceramic Cup"
        )

        #expect(key == "cups")
        #expect(ProductCatalogRules.categoryLabel(productType: "Drink Cups", fallbackKey: key) == "Cups")
    }

    @Test func mapsBottledProductsToDrinks() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Ready Made Drinks",
            tags: [],
            title: "Bottled Karak"
        )

        #expect(key == "ready-made-drinks")
        #expect(ProductCatalogRules.categoryLabel(productType: "Ready Made Drinks", fallbackKey: key) == "Drinks")
    }

    @Test func mapsOnlySummerDrinkProductTypeToSummerBoxes() {
        let boxKey = ProductCatalogRules.categoryKey(
            productType: "Summer Drinks",
            tags: [],
            title: "Iced Coffee Box"
        )
        let coldBrewKey = ProductCatalogRules.categoryKey(
            productType: "Drinks",
            tags: ["summer"],
            title: "Cold Brew"
        )

        #expect(boxKey == "summer-drinks")
        #expect(ProductCatalogRules.categoryLabel(productType: "Summer Drinks", fallbackKey: boxKey) == "Summer Boxes")
        #expect(coldBrewKey == "ready-made-drinks")
    }

    @Test func mapsWinterProductsToWinterCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Winter",
            tags: [],
            title: "Winter Collection"
        )

        #expect(key == "winter")
        #expect(ProductCatalogRules.categoryLabel(productType: "Winter", fallbackKey: key) == "Winter")
    }

    @Test func mapsEquipmentSignalsToEquipmentCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Accessories",
            tags: ["V60"],
            title: "Ceramic Dripper"
        )

        #expect(key == "coffee-equipment")
        #expect(ProductCatalogRules.categoryLabel(productType: "Accessories", fallbackKey: key) == "Equipment")
    }

    @Test func mapsHotChocolateDrinkToWinterCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: ["Cocoa"],
            title: "Classic Hot Chocolate"
        )

        #expect(key == "winter")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Winter")
        #expect(ProductCatalogRules.categoryKey(productType: "Ready Made Drinks", tags: ["app-category:ready-made-drinks"], title: "Hot Chocolate") == "winter")
        #expect(ProductCatalogRules.matchesShopCategory("winter", productCategory: key, name: "Classic Hot Chocolate", handle: "classic-hot-chocolate"))
        #expect(ProductCatalogRules.matchesShopCategory("winter", productCategory: "ready-made-drinks", name: "Hot Chocolate", handle: "hot-chocolate"))
        #expect(ProductCatalogRules.matchesShopCategory("ready-made-drinks", productCategory: "ready-made-drinks", name: "Hot Chocolate", handle: "hot-chocolate"))
        #expect(!ProductCatalogRules.matchesShopCategory("winter", productCategory: "ready-made-drinks", name: "Latte", handle: "latte"))
    }

    @Test func mapsSingleServeCoffeeProductsToCoffeeCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: ["single serve"],
            title: "Ethiopia Drip Bags"
        )

        #expect(key == "coffee-beans")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Coffee")
        #expect(ProductCatalogRules.shopCategoryKey(for: "drip-bags") == "coffee-beans")
        #expect(ProductCatalogRules.shopCategoryKey(for: "coffee-beans") == "coffee-beans")
        #expect(ProductCatalogRules.subscriptionPlanType(detectedPlan: key, requestedPlan: "drip-bags") == "drip-bags")

        let capsuleKey = ProductCatalogRules.categoryKey(
            productType: "Coffee Capsules",
            tags: ["Nespresso"],
            title: "House Capsules"
        )
        #expect(capsuleKey == "coffee-beans")
        #expect(ProductCatalogRules.shopCategoryKey(for: "coffee-capsules") == "coffee-beans")
    }

    @Test func appCategoryTagOverridesAutomaticCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Gift Box",
            tags: ["app-category:cups"],
            title: "Iced Bottle Gift Set"
        )

        #expect(key == "cups")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Cups")
    }

    @Test func appCategoryTagCanForceDrinksCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Gift Box",
            tags: ["app-category:drinks"],
            title: "Ceramic Cup Set"
        )

        #expect(key == "ready-made-drinks")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Drinks")
    }

    @Test func plainShopifyTagsCanForceCupsAndDrinksCategories() {
        let cupsKey = ProductCatalogRules.categoryKey(
            productType: "Gift Box",
            tags: ["Cups"],
            title: "Ceramic Set"
        )
        let drinksKey = ProductCatalogRules.categoryKey(
            productType: "Gift Box",
            tags: ["Drinks"],
            title: "Bottled Set"
        )

        #expect(cupsKey == "cups")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: cupsKey) == "Cups")
        #expect(drinksKey == "ready-made-drinks")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: drinksKey) == "Drinks")
    }

    @Test func appCategoryTagSupportsAliases() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Coffee",
            tags: ["app_category=CRMB"],
            title: "House Roast"
        )

        #expect(key == "desserts")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "CRMB")
    }

    @Test func defaultsToCoffeeBeansLabel() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: [],
            title: "House Roast"
        )

        #expect(key == "coffee-beans")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Coffee")
    }

    @Test func subscriptionProductRoutingKeepsProductsInTheChosenPlan() {
        #expect(ProductCatalogRules.subscriptionPlanType(detectedPlan: "arabic-coffee", requestedPlan: "arabic-coffee") == "arabic-coffee")
        #expect(ProductCatalogRules.subscriptionPlanType(detectedPlan: "beans", requestedPlan: "arabic-coffee") == nil)
        #expect(ProductCatalogRules.subscriptionPlanType(detectedPlan: "arabic-coffee", requestedPlan: "office") == "office")
        #expect(ProductCatalogRules.subscriptionPlanType(detectedPlan: "drip-bags", requestedPlan: "office") == nil)
        #expect(ProductCatalogRules.subscriptionPlanType(detectedPlan: "filters", requestedPlan: "equipment") == nil)
        #expect(ProductCatalogRules.subscriptionPlanType(detectedPlan: "seasonal-box", requestedPlan: "seasonal-box") == "seasonal-box")
    }

    @Test func identifiesArabicCoffeeEvenWhenCatalogCategoryIsGeneric() {
        #expect(ProductCatalogRules.isArabicCoffeeProduct("Qahwa Bahrain · Coffee Beans · app-category:coffee-beans"))
        #expect(ProductCatalogRules.isArabicCoffeeProduct("Shamali Coffee"))
        #expect(ProductCatalogRules.isArabicCoffeeProduct("قهوة عربية"))
        #expect(!ProductCatalogRules.isArabicCoffeeProduct("Arabica Ethiopia Natural"))
        #expect(!ProductCatalogRules.isArabicCoffeeProduct("Colombia Washed Coffee Beans"))
    }

    @Test func mapsHawarIslandsToCoffeeBeansDespiteConflictingTags() {
        let coffeeKey = ProductCatalogRules.categoryKey(
            productType: "CRMB",
            tags: ["app-category:crmb"],
            title: "Hawar Islands"
        )
        let dripBagKey = ProductCatalogRules.categoryKey(
            productType: "CRMB",
            tags: ["app-category:crmb"],
            title: "Hawar Islands Drip Bags"
        )

        #expect(coffeeKey == "coffee-beans")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: coffeeKey) == "Coffee")
        #expect(dripBagKey == "coffee-beans")
    }

    @Test func picksPreferredMerchandisingTag() {
        #expect(ProductCatalogRules.productTag(from: ["local", "new"]) == "NEW")
        #expect(ProductCatalogRules.productTag(from: ["single-origin"]) == nil)
    }

    @Test func readsCountryOfOriginFromShopifyTags() {
        #expect(ProductCatalogRules.countryOfOriginLabel(from: ["Greece"]) == "Greece")
        #expect(ProductCatalogRules.countryOfOriginLabel(from: ["United Arab Emirates"]) == "United Arab Emirates")
        #expect(ProductCatalogRules.countryOfOriginLabel(from: ["Cups"]) == nil)
    }

    @Test func summarizesProductsWithMultipleOrigins() {
        #expect(ProductCatalogRules.countryOfOriginLabel(from: ["Brazil", "Colombia", "Ethiopia", "Yemen"]) == "Brazil +3")
        #expect(ProductCatalogRules.countryOfOriginLabel(from: ["Colombia", "Yemen"]) == "Colombia +1")
    }

    @MainActor @Test func coffeeRecipeEditsCreateImmutableVersions() throws {
        let store = CoffeeDataStore(inMemory: true)
        let recipeID = UUID()
        let first: [[String: Any]] = [[
            "id": recipeID.uuidString, "name": "V60", "category": "Pour Over",
            "coffeeGrams": 20, "waterGrams": 320
        ]]
        var second = first
        second[0]["waterGrams"] = 300

        try store.replaceLegacyRecords(entityType: "recipe", objects: first)
        try store.replaceLegacyRecords(entityType: "recipe", objects: second)
        try store.replaceLegacyRecords(entityType: "recipe", objects: second)

        let versions = store.legacyObjects(entityType: "recipeVersion")
        #expect(versions.count == 2)
        #expect(Set(versions.compactMap { ($0["versionNumber"] as? NSNumber)?.intValue }) == Set([1, 2]))
        #expect(Set(versions.compactMap { $0["id"] as? String }).count == 2)
    }

    @MainActor @Test func completedSessionPersistsEverySampleKind() throws {
        let store = CoffeeDataStore(inMemory: true)
        let sessionID = UUID()
        let samples = SampleKind.allCases.enumerated().map { index, kind in
            CoffeeSampleInput(kind: kind, elapsedMilliseconds: index * 250, value: Double(index + 1), unit: kind.rawValue)
        }
        try store.recordCompletedBrew(
            id: sessionID, title: "Espresso", method: "Espresso", coffeeGrams: 18,
            waterGrams: 36, durationSeconds: 28, rating: 5, notes: "Sweet", samples: samples
        )

        let kinds = Set(store.legacyObjects(entityType: "sample").compactMap { $0["kind"] as? String })
        #expect(kinds == Set(SampleKind.allCases.map(\.rawValue)))
    }

    @Test func shelfDoseEstimatorUsesValidRecentHistoryAndSafeFallback() {
        #expect(CoffeeDoseEstimator.averageDoseGrams([18, 20, 22]) == 20)
        #expect(CoffeeDoseEstimator.averageDoseGrams([2, .infinity, 140], fallback: 18) == 18)
    }

    @MainActor @Test func shelfBrewsUseRecordedDoseHistory() throws {
        let store = CoffeeDataStore(inMemory: true)
        try store.recordCompletedBrew(
            id: UUID(), title: "V60", method: "V60", coffeeGrams: 20,
            waterGrams: 320, durationSeconds: 180, rating: 4, notes: "Good"
        )
        try store.recordCompletedBrew(
            id: UUID(), title: "V60", method: "V60", coffeeGrams: 22,
            waterGrams: 352, durationSeconds: 180, rating: 4, notes: "Good"
        )

        #expect(store.averageBrewDoseGrams() == 21)
    }

    @MainActor @Test func completedBrewRetryIsIdempotentForShelfConsumption() throws {
        let store = CoffeeDataStore(inMemory: true)
        try store.addPurchasedCoffee(name: "Retry Coffee", roaster: "Talla", roastDate: nil, quantityGrams: 250)
        let purchase = try #require(store.inventory().first)
        let sessionID = UUID()

        try store.recordCompletedBrew(
            id: sessionID, title: "Retry Coffee", method: "V60", coffeeGrams: 20,
            waterGrams: 320, durationSeconds: 180, rating: 4, notes: "Good"
        )
        try store.recordCompletedBrew(
            id: sessionID, title: "Retry Coffee", method: "V60", coffeeGrams: 20,
            waterGrams: 320, durationSeconds: 180, rating: 4, notes: "Good"
        )

        let remaining = try #require(store.inventory().first?.remainingQuantityGrams)
        #expect(remaining == 230)
        #expect(store.legacyObjects(entityType: "brewSession").count == 1)
        #expect(store.legacyObjects(entityType: "doseUsage").count == 1)
        #expect(purchase.initialQuantityGrams == 250)
    }

    @MainActor @Test func selectedEmptyBagDoesNotConsumeAnotherBag() throws {
        let store = CoffeeDataStore(inMemory: true)
        try store.addPurchasedCoffee(name: "Empty", roaster: "Talla", roastDate: nil, quantityGrams: 10)
        let emptyID = try #require(store.inventory().first?.id)
        try store.addPurchasedCoffee(name: "Other", roaster: "Talla", roastDate: nil, quantityGrams: 250)
        try store.consumeCoffeeForBrew(sessionID: UUID(), purchasedCoffeeID: emptyID, grams: 20)
        #expect(store.inventory().first(where: { $0.id == emptyID })?.remainingQuantityGrams == 0)
        let otherID = try #require(store.inventory().first(where: { $0.id != emptyID })?.id)
        try store.consumeCoffeeForBrew(sessionID: UUID(), purchasedCoffeeID: emptyID, grams: 20)
        #expect(store.inventory().first(where: { $0.id == otherID })?.remainingQuantityGrams == 250)
        #expect(store.usedGrams(emptyID) == 10)
    }

    @MainActor @Test func shelfDoseAndRemainingQuantityCommitTogether() throws {
        let store = CoffeeDataStore(inMemory: true)
        try store.addPurchasedCoffee(name: "House Bag", roaster: "Talla", roastDate: nil, quantityGrams: 100)
        let bagID = try #require(store.inventory().first?.id)
        let abandonedSession = UUID()
        #expect(try store.recordDose(sessionID: abandonedSession, purchaseID: bagID, grams: 20))
        store.container.mainContext.rollback()
        #expect(store.usedGrams(bagID) == 0)
        #expect(store.inventory().first?.remainingQuantityGrams == 100)

        let completedSession = UUID()
        try store.consumeCoffeeForBrew(sessionID: completedSession, purchasedCoffeeID: bagID, grams: 20)
        try store.consumeCoffeeForBrew(sessionID: completedSession, purchasedCoffeeID: bagID, grams: 20)
        #expect(store.usedGrams(bagID) == 20)
        #expect(store.inventory().first?.remainingQuantityGrams == 80)
        #expect(store.legacyObjects(entityType: "doseUsage").count == 1)
    }

    @MainActor @Test func undoShelfDoseRestoresBagOnlyOnce() throws {
        let store = CoffeeDataStore(inMemory: true)
        try store.addPurchasedCoffee(name: "Undo Bag", roaster: "Talla", roastDate: nil, quantityGrams: 100)
        let bagID = try #require(store.inventory().first?.id)
        let sessionID = UUID()
        try store.consumeCoffeeForBrew(sessionID: sessionID, purchasedCoffeeID: bagID, grams: 25)
        #expect(store.inventory().first?.remainingQuantityGrams == 75)
        #expect(store.latestDoseUsage(for: bagID)?.id == sessionID)
        try store.undoDoseUsage(sessionID: sessionID)
        try store.undoDoseUsage(sessionID: sessionID)
        #expect(store.inventory().first?.remainingQuantityGrams == 100)
        #expect(store.usedGrams(bagID) == 0)
        #expect(store.latestDoseUsage(for: bagID) == nil)
    }

    @MainActor @Test func purchasedCoffeeImportUsesVariantIdentityBeforeProductTitle() throws {
        func product(id: String, name: String, variantID: String, grams: Double) -> ContentView.Product {
            let variant = ContentView.Product.Variant(
                id: variantID, title: "Default", price: "8.500",
                isAvailableForSale: true, requiresShipping: true, weightGrams: grams
            )
            return ContentView.Product(
                id: id, handle: name.lowercased(), variantID: variantID, variants: [variant],
                name: name, price: "8.500", categoryKey: "coffee-beans", categoryLabel: "Coffee Beans",
                imageURL: nil, desc: "", tag: nil, countryOfOrigin: "Bahrain", isAvailableForSale: true
            )
        }
        let catalog = [
            product(id: "product-house", name: "House Coffee", variantID: "gid://shopify/ProductVariant/111", grams: 250),
            product(id: "product-other", name: "Other Coffee", variantID: "gid://shopify/ProductVariant/222", grams: 500)
        ]
        let orderJSON = #"[{"id":"order-variant","title":"Order","total":"8.500","status":"confirmed","items":[{"name":"House Coffee","productTitle":"House Coffee","variantId":"gid://shopify/ProductVariant/222","quantity":1}],"createdAt":"2026-11-06T10:00:00Z"}]"#
        let orders = try JSONDecoder().decode([ContentView.AccountOrder].self, from: Data(orderJSON.utf8))
        let store = CoffeeDataStore(inMemory: true)
        try store.importPurchasedCoffee(from: orders, catalog: catalog, ownerID: nil)
        let lot = try #require(store.beanLots().first)
        #expect(lot.productID == "product-other")
        #expect(lot.variantID == "gid://shopify/ProductVariant/222")
        #expect(store.inventory().first?.initialQuantityGrams == 500)

        let legacyJSON = #"[{"id":"order-legacy","title":"Order","total":"8.500","status":"confirmed","items":[{"name":"House Coffee","quantity":1}],"createdAt":"2026-11-06T10:00:00Z"}]"#
        let legacyOrders = try JSONDecoder().decode([ContentView.AccountOrder].self, from: Data(legacyJSON.utf8))
        let legacyStore = CoffeeDataStore(inMemory: true)
        try legacyStore.importPurchasedCoffee(from: legacyOrders, catalog: catalog, ownerID: nil)
        #expect(legacyStore.beanLots().first?.productID == "product-house")
        #expect(legacyStore.beanLots().first?.variantID == nil)
    }

    @Test func roastAgeGuidanceUsesPersonalPreferenceAndUnknownDates() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 12)))
        let dayTwenty = try #require(calendar.date(byAdding: .day, value: -20, to: now))
        let dayTwentyOne = try #require(calendar.date(byAdding: .day, value: -21, to: now))
        #expect(CoffeeRoastAgeGuidance.evaluate(roastDate: nil, preferredDays: 21, now: now, calendar: calendar).status == .unknown)
        #expect(CoffeeRoastAgeGuidance.evaluate(roastDate: dayTwenty, preferredDays: 21, now: now, calendar: calendar).status == .withinPreference)
        let reminder = CoffeeRoastAgeGuidance.evaluate(roastDate: dayTwentyOne, preferredDays: 21, now: now, calendar: calendar)
        #expect(reminder.status == .review)
        #expect(reminder.daysSinceRoast == 21)
        #expect(CoffeeRoastAgeGuidance.evaluate(roastDate: dayTwenty, preferredDays: 14, now: now, calendar: calendar).status == .review)
        #expect(CoffeeRoastAgeGuidance.evaluate(roastDate: dayTwenty, preferredDays: 999, now: now, calendar: calendar).preferredDays == 21)
        #expect(CoffeeRoastAgeGuidance.evaluate(roastDate: now.addingTimeInterval(2 * 86_400), preferredDays: 21, now: now, calendar: calendar).status == .unknown)
    }

    @MainActor @Test func completedBrewPersistsTasteSignalsForBrewCoach() throws {
        let store = CoffeeDataStore(inMemory: true)
        let sessionID = UUID()

        try store.recordCompletedBrew(
            id: sessionID, title: "Ethiopia Natural", method: "V60", coffeeGrams: 20,
            waterGrams: 320, durationSeconds: 190, rating: 4, notes: "More sweetness next time",
            feedbackTags: ["Sweet", "Too acidic"],
            samples: [
                CoffeeSampleInput(kind: .weight, elapsedMilliseconds: 0, value: 0, unit: "g"),
                CoffeeSampleInput(kind: .weight, elapsedMilliseconds: 190_000, value: 318, unit: "g"),
                CoffeeSampleInput(kind: .flow, elapsedMilliseconds: 190_000, value: 2.4, unit: "g/s")
            ]
        )

        let feedback = try #require(store.legacyObjects(entityType: "tasteFeedback").first)
        #expect(feedback["tags"] as? [String] == ["Sweet", "Too acidic"])
        #expect(feedback["notes"] as? String == "More sweetness next time")

        let context = store.brewCoachHistoryContext()
        #expect(context.contains("Ethiopia Natural"))
        #expect(context.contains("signals: Sweet, Too acidic"))
        #expect(context.contains("rating 4/5"))
        #expect(context.contains("curve: final 318.0 g, 2.4 g/s recent flow"))
        #expect(store.brewCoachFallbackAdjustment() == "Recent brews leaned acidic, so start the next cup slightly finer or with a little more contact time.")
    }

    @MainActor @Test func brewCoachTurnsTasteSignalsIntoOneNextAction() throws {
        let store = CoffeeDataStore(inMemory: true)

        #expect(store.brewCoachImmediateAction(for: ["Too weak"])?.title == "Make the brew stronger")
        #expect(store.brewCoachImmediateAction(for: ["Sweet", "Too acidic"])?.title == "Grind finer")

        try store.recordCompletedBrew(
            id: UUID(), title: "Morning V60", method: "V60", coffeeGrams: 20,
            waterGrams: 320, durationSeconds: 190, rating: 3, notes: "",
            feedbackTags: ["Too sour"]
        )
        #expect(store.brewCoachState().nextAction?.title == "Grind finer")

        try store.recordCompletedBrew(
            id: UUID(), title: "Morning V60", method: "V60", coffeeGrams: 20,
            waterGrams: 320, durationSeconds: 190, rating: 3, notes: "",
            feedbackTags: ["Too bitter"]
        )
        #expect(store.brewCoachState().nextAction?.title == "Grind coarser")

        try store.recordCompletedBrew(
            id: UUID(), title: "Morning V60", method: "V60", coffeeGrams: 20,
            waterGrams: 320, durationSeconds: 190, rating: 4, notes: "",
            feedbackTags: ["Sweet", "Too acidic"]
        )
        #expect(store.brewCoachState().nextAction?.title == "Grind finer")
    }

    @MainActor @Test func brewCoachComparesOnlyRepeatBrewsOfTheLatestRecipe() throws {
        let store = CoffeeDataStore(inMemory: true)
        #expect(store.brewCoachComparison() == nil)
        try store.recordCompletedBrew(
            id: UUID(), title: "House V60", method: "V60", coffeeGrams: 20,
            waterGrams: 320, durationSeconds: 190, rating: 3, notes: ""
        )
        #expect(store.brewCoachComparison() == nil)
        try store.recordCompletedBrew(
            id: UUID(), title: "Other recipe", method: "AeroPress", coffeeGrams: 18,
            waterGrams: 250, durationSeconds: 120, rating: 4, notes: ""
        )
        #expect(store.brewCoachComparison() == nil)
        try store.recordCompletedBrew(
            id: UUID(), title: "House V60", method: "V60", coffeeGrams: 20,
            waterGrams: 300, durationSeconds: 180, rating: 5, notes: ""
        )
        let comparison = try #require(store.brewCoachComparison())
        #expect(comparison.title == "House V60")
        #expect(comparison.previous.waterGrams == 320)
        #expect(comparison.latest.waterGrams == 300)
        #expect(comparison.previous.rating == 3)
        #expect(comparison.latest.rating == 5)
    }

    @MainActor @Test func brewCoachPromotesLovedBrewsAndRecommendsAfterThreeWins() throws {
        let store = CoffeeDataStore(inMemory: true)

        for index in 0..<3 {
            try store.recordCompletedBrew(
                id: UUID(), title: "House Cup " + String(index), method: "V60", coffeeGrams: 20,
                waterGrams: 320, durationSeconds: 190, rating: 5, notes: "",
                feedbackTags: ["I like this"]
            )
        }

        let state = store.brewCoachState()
        #expect(state.greatBrewCount == 3)
        #expect(state.nextAction?.kind == .exploreNextCoffee)
        #expect(state.nextAction?.recommendation?.contains("washed Ethiopian") == true)
    }

    @MainActor @Test func legacyCoffeeJSONMigratesOnce() throws {
        let suite = "TallaCoffeeMigrationTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("[{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"name\":\"V60\",\"coffeeGrams\":20,\"waterGrams\":320}]", forKey: "brewRecipes.saved")
        defaults.set("[{\"id\":\"550e8400-e29b-41d4-a716-446655440001\",\"title\":\"Morning\",\"method\":\"V60\",\"rating\":4}]", forKey: "brewJournal.saved")
        defaults.set("Ode Gen 2", forKey: "talla.brewing.equipmentGrinder.v1")

        let store = CoffeeDataStore(inMemory: true)
        try store.migrateLegacyJSON(defaults: defaults)
        try store.migrateLegacyJSON(defaults: defaults)

        #expect(store.legacyObjects(entityType: "recipe").count == 1)
        #expect(store.legacyObjects(entityType: "recipeVersion").count == 1)
        #expect(store.legacyObjects(entityType: "brewSession").count == 1)
        #expect(store.legacyObjects(entityType: "equipment").count == 1)
        #expect(defaults.bool(forKey: CoffeeDataStore.migrationKey))
    }

    @MainActor @Test func coffeeSyncBatchesDirtyChangesBelowServerLimit() async throws {
        final class Recorder {
            var changeCounts: [Int] = []

            func respond(to request: URLRequest) throws -> (Data, URLResponse) {
                let body = try #require(request.httpBody)
                let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
                let changes = json["changes"] as? [[String: Any]] ?? []
                changeCounts.append(changes.count)
                let records = changes.map { change -> [String: Any] in
                    [
                        "entityType": change["entityType"] as? String ?? "maintenance",
                        "id": change["id"] as? String ?? UUID().uuidString,
                        "payload": change["payload"] as? [String: Any] ?? [:],
                        "revision": 1,
                        "updatedAt": "2026-09-07T12:00:00.000Z",
                        "deletedAt": NSNull()
                    ]
                }
                let payload: [String: Any] = [
                    "cursor": String(changeCounts.count),
                    "records": records,
                    "conflicts": [],
                    "hasMore": false
                ]
                let data = try JSONSerialization.data(withJSONObject: payload)
                let response = try #require(HTTPURLResponse(
                    url: request.url ?? URL(string: "https://example.test")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                ))
                return (data, response)
            }
        }

        let recorder = Recorder()
        let suite = "TallaCoffeeBatchTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CoffeeDataStore(inMemory: true, storageDefaults: defaults) { request in
            try recorder.respond(to: request)
        }
        let records = (0..<1_201).map { index -> [String: Any] in
            ["id": UUID().uuidString, "equipmentID": UUID().uuidString, "kind": "Cleaning \(index)"]
        }
        try store.replaceLegacyRecords(entityType: "maintenance", objects: records)

        try await store.synchronize(
            ownerID: "customer@example.test",
            bearerToken: "access-token",
            baseURL: URL(string: "https://example.test")!
        )

        #expect(recorder.changeCounts == [500, 500, 201])
        #expect(recorder.changeCounts.allSatisfy { $0 <= CoffeeDataStore.maximumChangesPerRequest })
        #expect(store.syncStatus != .syncing)
    }

    @MainActor @Test func coffeeSyncConsumesEveryRemotePage() async throws {
        final class Pager {
            var cursors: [String] = []

            func respond(to request: URLRequest) throws -> (Data, URLResponse) {
                let body = try #require(request.httpBody)
                let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
                cursors.append(json["cursor"] as? String ?? "")
                let page = cursors.count
                let recordID = page == 1
                    ? "550e8400-e29b-41d4-a716-446655440010"
                    : "550e8400-e29b-41d4-a716-446655440011"
                let payload: [String: Any] = [
                    "cursor": String(page),
                    "records": [[
                        "entityType": "coffeeLot",
                        "id": recordID,
                        "payload": ["id": recordID, "name": "Remote lot \(page)"],
                        "revision": 1,
                        "updatedAt": "2026-09-07T12:00:00.000Z",
                        "deletedAt": NSNull()
                    ]],
                    "conflicts": [],
                    "hasMore": page == 1
                ]
                let data = try JSONSerialization.data(withJSONObject: payload)
                let response = try #require(HTTPURLResponse(
                    url: request.url ?? URL(string: "https://example.test")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                ))
                return (data, response)
            }
        }

        let pager = Pager()
        let suite = "TallaCoffeePagingTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CoffeeDataStore(inMemory: true, storageDefaults: defaults) { request in
            try pager.respond(to: request)
        }
        try await store.synchronize(
            ownerID: "customer@example.test",
            bearerToken: "access-token",
            baseURL: URL(string: "https://example.test")!
        )

        #expect(pager.cursors == ["0", "1"])
        #expect(store.legacyObjects(entityType: "coffeeLot").count == 2)
    }

    @MainActor @Test func coffeeCacheCannotCrossAccountBoundary() throws {
        let suite = "TallaCoffeeOwnerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CoffeeDataStore(inMemory: true, storageDefaults: defaults)

        try store.addPurchasedCoffee(
            name: "Private offline coffee",
            roaster: "Talla",
            roastDate: .now,
            quantityGrams: 250
        )
        try store.associateLocalStorage(with: "first@example.test")
        #expect(store.inventory().count == 1)

        try store.associateLocalStorage(with: "second@example.test")

        #expect(store.inventory().isEmpty)
        #expect(store.legacyObjects(entityType: "purchasedCoffee").isEmpty)
        #expect(defaults.string(forKey: CoffeeDataStore.storageOwnerKey) == "second@example.test")
    }

    @MainActor @Test func markingPurchasedCoffeeOpenedPersistsOpenedDate() throws {
        let store = CoffeeDataStore(inMemory: true)
        try store.addPurchasedCoffee(
            name: "Opened-state test coffee",
            roaster: "Talla",
            roastDate: nil,
            quantityGrams: 250
        )
        let coffee = try #require(store.inventory().first)
        #expect(coffee.openedAt == nil)

        let openedAt = Date(timeIntervalSince1970: 1_735_689_600)
        try store.markOpened(coffee.id, date: openedAt)

        let updated = try #require(store.inventory().first)
        #expect(updated.openedAt != nil)
        #expect(abs((updated.openedAt ?? .distantPast).timeIntervalSince1970 - openedAt.timeIntervalSince1970) < 1)
    }

    @MainActor @Test func reviewedCoffeeRoundTripsWithoutInventingRoastDate() throws {
        let store = CoffeeDataStore(inMemory: true)
        let id = try store.addPurchasedCoffee(
            name: "Reviewed Guji",
            roaster: "Talla",
            origin: "Ethiopia",
            tastingNotes: "Jasmine and peach",
            roastDate: nil,
            quantityGrams: 200
        )

        let coffee = try #require(store.inventory().first { $0.id == id })
        #expect(coffee.roastDate == nil)
        #expect(coffee.tastingNotes == "Jasmine and peach")
        #expect(coffee.remainingQuantityGrams == 200)
        #expect(throws: CoffeeDataError.self) {
            try store.updateRemainingQuantity(recordID: id, remainingGrams: .nan)
        }
        #expect(store.inventory().first { $0.id == id }?.remainingQuantityGrams == 200)
    }
}
