import Testing
@testable import Talla_Speciality

@MainActor
struct PaymentFlowTests {
    @Test func stateModelPreventsRepeatedStarts() {
        let model = PaymentFlowModel()
        #expect(model.state == .idle)
        #expect(model.begin())
        #expect(model.state == .creatingSession)
        #expect(!model.begin())
        model.transition(to: .awaitingCustomer)
        #expect(!model.begin())
    }

    @Test func cancellationAndRetryAreExplicit() {
        let model = PaymentFlowModel()
        #expect(model.begin())
        model.cancel()
        #expect(model.state == .cancelled)
        #expect(model.begin())
        model.transition(to: .failed, error: "Declined")
        #expect(model.state == .failed)
        #expect(model.errorMessage == "Declined")
    }

    @Test func selectorContainsAllRequiredMethods() {
        #expect(Set(TallaPaymentMethod.allCases) == Set([.benefit, .card, .applePay, .clickToPay]))
        #expect(TallaPaymentService.applePayMerchantIdentifier == "merchant.talla.me")
    }
}
