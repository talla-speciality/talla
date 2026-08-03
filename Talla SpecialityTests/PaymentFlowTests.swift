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
        #expect(Set(TallaPaymentMethod.allCases) == Set([.benefit, .card, .applePay, .clickToPay]))
        #expect(TallaPaymentService.applePayMerchantIdentifier == "merchant.talla.me")
    }

    @Test func paymentMethodsUseTheRequiredDisplayOrder() {
        #expect(PaymentMethodSelectorView.visibleMethods(applePayAvailable: true) == [.applePay, .benefit, .card, .clickToPay])
        #expect(PaymentMethodSelectorView.visibleMethods(applePayAvailable: false) == [.benefit, .card, .clickToPay])
        #expect(!PaymentMethodSelectorView.visibleMethods(applePayAvailable: false).contains(.applePay))
    }

    @Test func everyPaymentMethodUsesItsExistingRoute() {
        #expect(TallaPaymentMethod.benefit.route == .benefitHosted)
        #expect(TallaPaymentMethod.card.route == .cardGateway)
        #expect(TallaPaymentMethod.applePay.route == .applePayGateway)
        #expect(TallaPaymentMethod.clickToPay.route == .clickToPayHosted)
    }

    @Test func cardMessagingIncludesAmericanExpress() {
        #expect(TallaPaymentMethod.card.subtitle.contains("American Express"))
        #expect(TallaPaymentMethod.clickToPay.supportingText?.contains("American Express") == true)
    }

    @Test func sheetMessagingIsCompactAndSpecific() {
        #expect(TallaPaymentMethod.benefit.sheetSubtitle == "For Bahrain-issued debit cards")
        #expect(TallaPaymentMethod.clickToPay.sheetSubtitle == "Use supported saved cards for faster checkout")
    }

    @Test func actionCopyMatchesTheSelectedMethod() {
        #expect(TallaPaymentMethod.benefit.actionTitle == "Continue to BENEFIT")
        #expect(TallaPaymentMethod.card.actionTitle == "Enter card details")
        #expect(TallaPaymentMethod.clickToPay.actionTitle == "Continue with Click to Pay")
    }

    @Test func currencyUsesThreeDecimalBHDFormatting() {
        #expect(CheckoutCurrencyFormatter.bhd(8.5) == "BHD 8.500")
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
