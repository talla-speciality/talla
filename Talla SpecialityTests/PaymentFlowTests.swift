import Foundation
import SwiftUI
import Testing
@testable import Talla_Speciality

@MainActor
@Suite(.serialized)
struct PaymentFlowTests {
    @Test func clickToPayCanBeSwitchedIndependentlyOfCards() {
        var availability = TallaPaymentAvailability()
        availability.clickToPayEnabled = false
        var methods = PaymentMethodSelectorView.visibleMethods(applePayAvailable: true, availability: availability)
        #expect(methods.contains(.card))
        #expect(!methods.contains(.clickToPay))
        availability.cardEnabled = false
        availability.clickToPayEnabled = true
        methods = PaymentMethodSelectorView.visibleMethods(applePayAvailable: true, availability: availability)
        #expect(!methods.contains(.card))
        #expect(methods.contains(.clickToPay))
    }

    @Test func paymentSettingsAcceptClickToPayAndLegacyPayloads() throws {
        let legacy = Data(#"{"applePayEnabled":true,"benefitPayEnabled":true,"benefitEnabled":true,"cardEnabled":false,"cashOnDeliveryEnabled":true,"noticeEN":"","noticeAR":""}"#.utf8)
        let payments = try JSONDecoder().decode(ContentView.AppSettings.Payments.self, from: legacy)
        #expect(payments.clickToPayEnabled == nil)
        #expect((payments.clickToPayEnabled ?? payments.cardEnabled) == false)
        var payload = try JSONSerialization.jsonObject(with: legacy) as! [String: Any]
        payload["clickToPayEnabled"] = true
        let enabled = try JSONDecoder().decode(ContentView.AppSettings.Payments.self, from: JSONSerialization.data(withJSONObject: payload))
        #expect(enabled.clickToPayEnabled == true)
        #expect(!enabled.cardEnabled)
    }

    @Test func stateModelPreventsRepeatedStarts() {
        let model = PaymentFlowModel()
        #expect(model.state == .idle)
        #expect(model.selectedMethod == nil)
        #expect(!model.begin())
        model.select(.benefit)
        #expect(model.begin())
        #expect(model.state == .creatingSession)
        #expect(!model.begin())
        model.transition(to: .awaitingCustomer)
        #expect(!model.begin())
    }

    @Test func cancellationAndRetryAreExplicit() {
        let model = PaymentFlowModel(selectedMethod: .card)
        #expect(model.begin())
        model.cancel()
        #expect(model.state == .cancelled)
        #expect(model.begin())
        model.transition(to: .failed, error: "Declined")
        #expect(model.state == .failed)
        #expect(model.errorMessage == "Declined")
    }

    @Test func paymentMethodRequiresExplicitConfirmation() {
        let model = PaymentFlowModel()
        #expect(model.selectedMethod == nil)
        #expect(!model.canStart)

        model.select(.applePay)
        #expect(model.selectedMethod == .applePay)
        #expect(model.canStart)

        model.select(.benefit)
        #expect(model.selectedMethod == .benefit)
    }

    @Test func selectorContainsAllRequiredMethods() {
        #expect(Set(TallaPaymentMethod.allCases) == Set([.benefitPay, .benefit, .card, .clickToPay, .applePay, .cashOnDelivery]))
        #expect(TallaPaymentService.applePayMerchantIdentifier == "merchant.talla.me")
    }

    @Test func paymentMethodsUseTheRequiredDisplayOrder() {
        #expect(PaymentMethodSelectorView.visibleMethods(applePayAvailable: true) == [.applePay, .benefitPay, .benefit, .card, .clickToPay, .cashOnDelivery])
        #expect(PaymentMethodSelectorView.visibleMethods(applePayAvailable: false) == [.benefitPay, .benefit, .card, .clickToPay, .cashOnDelivery])
        #expect(!PaymentMethodSelectorView.visibleMethods(applePayAvailable: false).contains(.applePay))
    }

    @Test func everyPaymentMethodUsesItsExistingRoute() {
        #expect(TallaPaymentMethod.benefit.route == .benefitHosted)
        #expect(TallaPaymentMethod.benefitPay.route == .benefitPaySDK)
        #expect(TallaPaymentMethod.card.route == .cardGateway)
        #expect(TallaPaymentMethod.clickToPay.route == .clickToPayHosted)
        #expect(TallaPaymentMethod.applePay.route == .applePayGateway)
        #expect(TallaPaymentMethod.cashOnDelivery.route == .shopifyCashOnDelivery)
    }

    @Test func cardMessagingIncludesAmericanExpress() {
        #expect(TallaPaymentMethod.card.subtitle.contains("American Express"))
        #expect(TallaPaymentMethod.clickToPay.subtitle.contains("Mastercard"))
        #expect(TallaPaymentMethod.cashOnDelivery.supportingText?.contains("cash") == true)
    }

    @Test func sheetMessagingIsCompactAndSpecific() {
        #expect(TallaPaymentMethod.benefit.sheetSubtitle == "For Bahrain-issued debit cards")
        #expect(TallaPaymentMethod.cashOnDelivery.sheetSubtitle == "Complete your order through Shopify Checkout")
    }

    @Test func actionCopyMatchesTheSelectedMethod() {
        #expect(TallaPaymentMethod.benefit.actionTitle == "Continue to BENEFIT")
        #expect(TallaPaymentMethod.card.actionTitle == "Enter card details")
        #expect(TallaPaymentMethod.clickToPay.actionTitle == "Continue to Click to Pay")
        #expect(TallaPaymentMethod.cashOnDelivery.actionTitle == "Continue with Cash on Delivery")
    }

    @Test func currencyUsesThreeDecimalBHDFormatting() {
        #expect(CheckoutCurrencyFormatter.bhd(8.5) == "BHD 8.500")
    }

    @Test func customersCanChooseDeliveryOrPickup() {
        #expect(TallaFulfillmentMethod.allCases == [.delivery, .pickup])
        #expect(TallaFulfillmentMethod.pickup.rawValue == "pickup")
    }

    @Test func bahrainShippingIsFixedRegardlessOfWeightOrPaymentMethod() {
        #expect(TallaShippingRates.rate(countryCode: "BH", weightGrams: 0, cashOnDelivery: false) == 2.000)
        #expect(TallaShippingRates.rate(countryCode: "bh", weightGrams: 4_000, cashOnDelivery: true) == 2.000)
    }

    @Test func khaleejiShippingUsesContinuousWeightTiers() {
        #expect(TallaShippingRates.rate(countryCode: "SA", weightGrams: 500, cashOnDelivery: false) == 5.500)
        #expect(TallaShippingRates.rate(countryCode: "KW", weightGrams: 500.1, cashOnDelivery: false) == 6.500)
        #expect(TallaShippingRates.rate(countryCode: "AE", weightGrams: 1_000.1, cashOnDelivery: false) == 7.500)
        #expect(TallaShippingRates.rate(countryCode: "QA", weightGrams: 1_500.1, cashOnDelivery: false) == 8.500)
        #expect(TallaShippingRates.rate(countryCode: "OM", weightGrams: 2_000.1, cashOnDelivery: false) == 9.500)
        #expect(TallaShippingRates.rate(countryCode: "SA", weightGrams: 2_500.1, cashOnDelivery: false) == 10.500)
        #expect(TallaShippingRates.rate(countryCode: "KW", weightGrams: 3_000.1, cashOnDelivery: false) == 11.500)
        #expect(TallaShippingRates.rate(countryCode: "AE", weightGrams: 3_500.1, cashOnDelivery: false) == 12.500)
    }

    @Test func khaleejiCashOnDeliveryAddsTwoBHDAndOverweightIsRejected() {
        #expect(TallaShippingRates.rate(countryCode: "AE", weightGrams: 1_200, cashOnDelivery: true) == 9.500)
        #expect(TallaShippingRates.rate(countryCode: "OM", weightGrams: 4_001, cashOnDelivery: false) == nil)
        #expect(TallaShippingRates.rate(countryCode: "US", weightGrams: 500, cashOnDelivery: false) == nil)
        #expect(TallaShippingRates.khaleejiTransitTime == "3 to 5 business days")
    }

    @Test func deliveryCountriesIncludeGCCAndInternationalDestinations() {
        let countryCodes = Set(ContentView.SupportedDeliveryCountry.allCases.map(\.rawValue))
        #expect(countryCodes.isSuperset(of: ["BH", "SA", "KW", "AE", "QA", "OM", "US", "GB"]))
        #expect(ContentView.SupportedDeliveryCountry(code: "sa") == .saudiArabia)
        #expect(ContentView.SupportedDeliveryCountry(code: "US")?.isKhaleeji == false)
        #expect(ContentView.SupportedDeliveryCountry(code: "AE")?.phonePrefix == "+971")
    }

    @Test func accessibilitySummaryDescribesTheMethod() {
        #expect(TallaPaymentMethod.benefit.accessibilitySummary.contains("Bahraini debit cards"))
        #expect(TallaPaymentMethod.card.accessibilitySummary.contains("Visa"))
    }

    @Test func arabicCopyUsesRightToLeftLayout() {
        let previousLanguage = UserDefaults.standard.string(forKey: "app.language")
        defer { UserDefaults.standard.set(previousLanguage, forKey: "app.language") }
        UserDefaults.standard.set(AppLanguage.arabic.rawValue, forKey: "app.language")
        #expect(AppLocalization.currentLanguage.layoutDirection == .rightToLeft)
        #expect(TallaPaymentMethod.benefit.title == "بنفت")
        #expect(TallaPaymentMethod.card.actionTitle == "إدخال بيانات البطاقة")
    }

    @Test func successPresentationRequiresConfirmedState() {
        let unconfirmedStates: [TallaPaymentState] = [
            .idle, .creatingSession, .awaitingCustomer, .authenticating, .processing, .failed, .cancelled
        ]
        for state in unconfirmedStates {
            #expect(!state.canPresentConfirmedSuccess)
        }
        #expect(TallaPaymentState.succeeded.canPresentConfirmedSuccess)
    }
}

@MainActor
struct OrderHistoryFulfillmentTests {
    private func order(status: String, title: String = "Order #123", method: String? = nil) throws -> ContentView.AccountOrder {
        var payload: [String: Any] = [
            "id": "123", "title": title, "total": "BHD 5.000",
            "status": status, "createdAt": "2026-09-09"
        ]
        if let method { payload["details"] = ["fulfillment": ["method": method]] }
        return try JSONDecoder().decode(ContentView.AccountOrder.self, from: JSONSerialization.data(withJSONObject: payload))
    }

    @Test func pickupSnapshotIsUsedBeforeReady() throws {
        for status in ["Pending", "Confirmed", "Preparing", "Packed", "Cancelled"] {
            #expect(try order(status: status, method: "pickup").isPickup)
        }
    }

    @Test func completedPickupIsCollectedAndNeverInTransit() throws {
        for status in ["Completed", "Fulfilled", "Delivered"] {
            #expect(try order(status: status, method: "pickup").historyStatus == "collected")
        }
        for status in ["Shipped", "On its way", "Out for delivery"] {
            #expect(try order(status: status, method: "pickup").historyStatus == "packed")
        }
    }

    @Test func deliverySnapshotTakesPrecedenceOverLegacyHints() throws {
        let delivery = try order(status: "Delivered", title: "Pickup order", method: "delivery")
        #expect(!delivery.isPickup)
        #expect(delivery.historyStatus == "delivered")
        #expect(try !order(status: "Ready", method: "delivery").isPickup)
    }

    @Test func legacyOrdersStillDecode() throws {
        #expect(try order(status: "Pending", title: "Pickup order").isPickup)
        #expect(try order(status: "Ready").isPickup)
        #expect(try !order(status: "Pending").isPickup)
        #expect(try order(status: "Pending", method: " PICKUP ").isPickup)
    }
}


@MainActor
@Suite(.serialized)
struct ArabicLocalizationTests {
    private func inArabic(_ action: () -> Void) {
        let previous = UserDefaults.standard.object(forKey: "app.language")
        UserDefaults.standard.set(AppLanguage.arabic.rawValue, forKey: "app.language")
        defer {
            if let previous { UserDefaults.standard.set(previous, forKey: "app.language") }
            else { UserDefaults.standard.removeObject(forKey: "app.language") }
        }
        action()
    }

    @Test func arabicHeroOverridesAndEmptyFallback() throws {
        let data = Data(#"{"heroTitle":"English title","heroTitleAR":"  قهوتك اليومية  ","heroSubtitleAR":"وصف","heroBadgeAR":"طازج","heroEyebrowAR":"المحمصة","primaryButtonTitleAR":"تسوق","secondaryButtonTitleAR":"حضّر"}"#.utf8)
        let settings = try JSONDecoder().decode(ContentView.HomeSettings.self, from: data)
        #expect(settings.heroSubtitleAR == "وصف")
        #expect(settings.heroBadgeAR == "طازج")
        #expect(settings.heroEyebrowAR == "المحمصة")
        #expect(settings.primaryButtonTitleAR == "تسوق")
        #expect(settings.secondaryButtonTitleAR == "حضّر")
        inArabic {
            #expect(AppLocalization.homeText(settings.heroTitle, arabicValue: settings.heroTitleAR, key: "hero_title", fallback: "Coffee") == "قهوتك اليومية")
            #expect(AppLocalization.homeText("English", arabicValue: "  ", key: "hero_title", fallback: "Coffee") == AppLocalization.text("hero_title", fallback: "Coffee"))
        }
        let legacy = try JSONDecoder().decode(ContentView.HomeSettings.self, from: Data(#"{"heroTitle":"Coffee"}"#.utf8))
        #expect(legacy.heroTitleAR == nil)
        let previous = UserDefaults.standard.object(forKey: "app.language")
        UserDefaults.standard.set(AppLanguage.english.rawValue, forKey: "app.language")
        defer {
            if let previous { UserDefaults.standard.set(previous, forKey: "app.language") }
            else { UserDefaults.standard.removeObject(forKey: "app.language") }
        }
        #expect(AppLocalization.homeText(settings.heroTitle, arabicValue: settings.heroTitleAR, key: "hero_title", fallback: "Coffee") == "English title")
    }

    @Test func englishRemoteHeroDoesNotOverrideArabic() {
        inArabic {
            #expect(AppLocalization.homeText("Fresh coffee today", key: "hero_title", fallback: "Coffee") == "قهوة مختصة،\nنحمّصها بعناية")
            #expect(AppLocalization.homeText("محصول جديد", key: "hero_title", fallback: "Coffee") == "محصول جديد")
            #expect(AppLocalization.letterSpacing(2) == 0)
        }
    }

    @Test func catalogFallbackKeepsPublishedArabicAndRejectsStaleCopy() {
        inArabic {
            #expect(AppLocalization.catalogText("Riffa", source: "Riffa", key: "catalog_riffa_name") == "الرفاع")
            #expect(AppLocalization.catalogText("رفاع جديد", source: "Riffa", key: "catalog_riffa_name") == "رفاع جديد")
            #expect(AppLocalization.catalogText("Riffa Reserve", source: "Riffa Reserve", key: "catalog_riffa_name") == "Riffa Reserve")
        }
    }

    @Test func variantsAndCategoriesAreArabicWithoutChangingTechnicalSizes() {
        inArabic {
            #expect(AppLocalization.catalogOption("250 G / Whole bean") == "٢٥٠ غ / حبوب كاملة")
            #expect(AppLocalization.catalogOption("Hawar islands / Riffa") == "جزر حوار / الرفاع")
            #expect(AppLocalization.catalogOption("50 / 02") == "50 / 02")
            #expect(ProductCatalogRules.categoryLabel(productType: "Coffee", fallbackKey: "coffee-beans") == "البن")
        }
    }

    @Test func checkoutAndEquipmentLabelsHaveArabicCopy() {
        inArabic {
            #expect(AppLocalization.text("checkout", fallback: "Checkout") == "إتمام الطلب")
            #expect(AppLocalization.text("library_save_calibration", fallback: "Save calibration") == "حفظ المعايرة")
            #expect(AppLocalization.text("delivery_address", fallback: "Delivery address") == "عنوان التوصيل")
        }
    }
    @Test func arabicCatalogDoesNotChangeNumericCheckoutPrices() {
        inArabic {
            let price = ContentView.Product.formattedPrice(from: ShopifyProductNode.Money(amount: "8.500", currencyCode: "BHD"))
            #expect(ContentView().priceValue(from: price) == 8.5)
        }
    }
}
