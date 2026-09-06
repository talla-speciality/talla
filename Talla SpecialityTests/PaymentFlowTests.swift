import Foundation
import SwiftUI
import Testing
@testable import Talla_Speciality

@MainActor
@Suite(.serialized)
struct PaymentFlowTests {
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
