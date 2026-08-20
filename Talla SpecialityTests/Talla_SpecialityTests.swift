import Testing
@testable import Talla_Speciality

struct Talla_SpecialityTests {

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
            title: "Mini Talla Box"
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

    @Test func mapsEquipmentSignalsToEquipmentCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Accessories",
            tags: ["V60"],
            title: "Ceramic Dripper"
        )

        #expect(key == "coffee-equipment")
        #expect(ProductCatalogRules.categoryLabel(productType: "Accessories", fallbackKey: key) == "Equipment")
    }

    @Test func mapsHotChocolateToHotChocolateCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: ["Cocoa"],
            title: "Classic Hot Chocolate"
        )

        #expect(key == "hot-chocolate")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Hot Chocolate")
    }

    @Test func mapsDripBagSignalsToDripBagsCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: ["single serve"],
            title: "Ethiopia Drip Bags"
        )

        #expect(key == "drip-bags")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Drip Bags")
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
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "Coffee Beans")
    }

    @Test func picksPreferredMerchandisingTag() {
        #expect(ProductCatalogRules.productTag(from: ["local", "new"]) == "NEW")
        #expect(ProductCatalogRules.productTag(from: ["single-origin"]) == nil)
    }
}
