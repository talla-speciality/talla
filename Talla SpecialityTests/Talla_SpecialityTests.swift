import Testing
@testable import Talla_Speciality

struct Talla_SpecialityTests {

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

    @Test func mapsTeaToReadyMadeDrinks() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Tea",
            tags: [],
            title: "Karak Tea"
        )

        #expect(key == "ready-made-drinks")
        #expect(ProductCatalogRules.categoryLabel(productType: "Tea", fallbackKey: key) == "Ready-Made Drinks")
    }

    @Test func mapsBakerySignalsToBakeryCategory() {
        let key = ProductCatalogRules.categoryKey(
            productType: "",
            tags: ["butter"],
            title: "Date Cookies"
        )

        #expect(key == "crmb-tallas-speciality-bakery")
        #expect(ProductCatalogRules.categoryLabel(productType: "", fallbackKey: key) == "CRMB Talla's Speciality Bakery")
    }

    @Test func mapsCupsToReadyMadeDrinks() {
        let key = ProductCatalogRules.categoryKey(
            productType: "Drink Cups",
            tags: [],
            title: "Talla Iced Latte Cup"
        )

        #expect(key == "ready-made-drinks")
        #expect(ProductCatalogRules.categoryLabel(productType: "Drink Cups", fallbackKey: key) == "Ready-Made Drinks")
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
