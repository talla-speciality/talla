import Foundation
import SwiftUI
import Combine
#if canImport(PassKit)
import PassKit
#endif

#if DEBUG
private struct PaymentExperiencePreview: View {
    @State private var selectedMethod: TallaPaymentMethod
    let applePayAvailable: Bool
    let state: TallaPaymentState

    init(
        selectedMethod: TallaPaymentMethod = .benefit,
        applePayAvailable: Bool = true,
        state: TallaPaymentState = .idle
    ) {
        _selectedMethod = State(initialValue: selectedMethod)
        self.applePayAvailable = applePayAvailable
        self.state = state
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                CheckoutHeader(
                    accentColor: Color(red: 0.78, green: 0.58, blue: 0.35),
                    primaryColor: .primary,
                    secondaryColor: .secondary
                )
                PaymentMethodSelectorView(
                    selectedMethod: $selectedMethod,
                    state: state,
                    applePayAvailable: applePayAvailable,
                    gatewaySDKAvailable: true,
                    primaryColor: .primary,
                    secondaryColor: .secondary,
                    accentColor: Color(red: 0.78, green: 0.58, blue: 0.35),
                    surfaceColor: Color.primary.opacity(0.025)
                )
                PaymentStatusView(
                    state: state,
                    accentColor: Color(red: 0.78, green: 0.58, blue: 0.35),
                    primaryColor: .primary,
                    secondaryColor: .secondary
                )
                CheckoutActionBar(
                    method: selectedMethod,
                    amountText: "BHD 8.500",
                    state: state,
                    enabled: true,
                    applePayAvailable: applePayAvailable,
                    accentColor: Color(red: 0.78, green: 0.58, blue: 0.35),
                    action: {}
                )
            }
            .padding(20)
        }
        .background(Color(red: 0.98, green: 0.965, blue: 0.935))
    }
}

#Preview("Apple Pay Available") { PaymentExperiencePreview(selectedMethod: .applePay) }
#Preview("Apple Pay Unavailable") { PaymentExperiencePreview(applePayAvailable: false) }
#Preview("BENEFIT Selected") { PaymentExperiencePreview(selectedMethod: .benefit) }
#Preview("Card Selected") { PaymentExperiencePreview(selectedMethod: .card) }
#Preview("Cash on Delivery Selected") { PaymentExperiencePreview(selectedMethod: .cashOnDelivery) }
#Preview("Loading") { PaymentExperiencePreview(selectedMethod: .card, state: .creatingSession) }
#Preview("Success") { PaymentExperiencePreview(selectedMethod: .card, state: .succeeded) }
#Preview("Failure") { PaymentExperiencePreview(selectedMethod: .card, state: .failed) }
#Preview("Arabic RTL") {
    PaymentExperiencePreview(selectedMethod: .benefit)
        .environment(\.locale, Locale(identifier: "ar"))
        .environment(\.layoutDirection, .rightToLeft)
}
#Preview("Dark Mode") {
    PaymentExperiencePreview(selectedMethod: .card)
        .preferredColorScheme(.dark)
}
#Preview("Large Dynamic Type") {
    PaymentExperiencePreview(selectedMethod: .benefit)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
#if canImport(Gateway) && canImport(uSDK) && canImport(UIKit)
import Gateway
import uSDK
import UIKit
#endif

enum TallaPaymentRoute: String, Equatable {
    case benefitHosted
    case benefitPaySDK
    case cardGateway
    case applePayGateway
    case shopifyCashOnDelivery
}

enum TallaPaymentMethod: String, CaseIterable, Identifiable {
    case benefit
    case benefitPay
    case card
    case applePay
    case cashOnDelivery

    var id: String { rawValue }

    var route: TallaPaymentRoute {
        switch self {
        case .benefit: return .benefitHosted
        case .benefitPay: return .benefitPaySDK
        case .card: return .cardGateway
        case .applePay: return .applePayGateway
        case .cashOnDelivery: return .shopifyCashOnDelivery
        }
    }

    var accessibilitySummary: String { "\(title), \(subtitle)" }

    var title: String {
        switch self {
        case .benefit: return AppLocalization.text("payment_benefit_title", fallback: "BENEFIT")
        case .benefitPay: return "BenefitPay"
        case .card: return AppLocalization.text("payment_card_title", fallback: "Credit or Debit Card")
        case .applePay: return "Apple Pay"
        case .cashOnDelivery:
            return AppLocalization.text("payment_cash_on_delivery_title", fallback: "Cash on Delivery")
        }
    }

    var subtitle: String {
        switch self {
        case .applePay:
            return AppLocalization.text("payment_apple_pay_subtitle", fallback: "Fast and secure checkout")
        case .benefit:
            return AppLocalization.text("payment_benefit_subtitle", fallback: "For Bahraini debit cards")
        case .benefitPay:
            return "Pay securely using the BenefitPay app"
        case .card:
            return AppLocalization.text("payment_card_subtitle", fallback: "Visa, Mastercard and American Express")
        case .cashOnDelivery:
            return AppLocalization.text("payment_cash_on_delivery_subtitle", fallback: "Pay when your order arrives")
        }
    }

    var sheetSubtitle: String {
        switch self {
        case .applePay:
            return AppLocalization.text("payment_apple_pay_subtitle", fallback: "Fast and secure checkout")
        case .benefit:
            return AppLocalization.text("payment_benefit_sheet_subtitle", fallback: "For Bahrain-issued debit cards")
        case .benefitPay:
            return "Use cards saved in your BenefitPay wallet"
        case .card:
            return AppLocalization.text("payment_card_subtitle", fallback: "Visa, Mastercard and American Express")
        case .cashOnDelivery:
            return AppLocalization.text("payment_cash_on_delivery_sheet_subtitle", fallback: "Complete your order through Shopify Checkout")
        }
    }

    var supportingText: String? {
        switch self {
        case .applePay:
            return nil
        case .benefit:
            return AppLocalization.text("payment_benefit_supporting", fallback: "Use your Bahrain-issued debit card and PIN.")
        case .benefitPay:
            return "Requires the BenefitPay app on this device."
        case .card:
            return AppLocalization.text("payment_card_supporting", fallback: "For Bahrain-issued credit cards and cards issued outside Bahrain.")
        case .cashOnDelivery:
            return AppLocalization.text("payment_cash_on_delivery_supporting", fallback: "Available where cash collection is supported.")
        }
    }

    var guidance: String {
        switch self {
        case .applePay:
            return AppLocalization.text("payment_apple_pay_guidance", fallback: "Pay using a card stored in Apple Wallet.")
        case .benefit:
            return AppLocalization.text("payment_benefit_guidance", fallback: "Choose this for a Bahrain-issued debit card.")
        case .benefitPay:
            return "Choose this to approve payment inside BenefitPay."
        case .card:
            return AppLocalization.text("payment_card_guidance", fallback: "Choose this for Visa, Mastercard or American Express credit/debit cards.")
        case .cashOnDelivery:
            return AppLocalization.text("payment_cash_on_delivery_guidance", fallback: "Choose Cash on Delivery in Shopify Checkout before placing your order.")
        }
    }

    var actionTitle: String {
        switch self {
        case .applePay:
            return AppLocalization.text("payment_complete_action", fallback: "Complete payment")
        case .benefit:
            return AppLocalization.text("payment_benefit_action", fallback: "Continue to BENEFIT")
        case .benefitPay:
            return "Continue with BenefitPay"
        case .card:
            return AppLocalization.text("payment_card_action", fallback: "Enter card details")
        case .cashOnDelivery:
            return AppLocalization.text("payment_cash_on_delivery_action", fallback: "Continue with Cash on Delivery")
        }
    }

    var systemImage: String {
        switch self {
        case .benefit: return "checkmark.shield.fill"
        case .benefitPay: return "iphone.and.arrow.forward"
        case .card: return "creditcard.fill"
        case .applePay: return "wallet.pass.fill"
        case .cashOnDelivery: return "banknote.fill"
        }
    }
}

enum TallaPaymentState: String, Equatable {
    case idle
    case creatingSession
    case awaitingCustomer
    case authenticating
    case processing
    case succeeded
    case failed
    case cancelled

    var isBusy: Bool {
        [.creatingSession, .authenticating, .processing].contains(self)
    }

    var canPresentConfirmedSuccess: Bool { self == .succeeded }
}

@MainActor
final class PaymentFlowModel: ObservableObject {
    @Published private(set) var selectedMethod: TallaPaymentMethod?
    @Published private(set) var state: TallaPaymentState = .idle
    @Published private(set) var errorMessage: String?

    var canChangeMethod: Bool { !state.isBusy && state != .awaitingCustomer }
    var canStart: Bool { selectedMethod != nil && canChangeMethod }

    init(selectedMethod: TallaPaymentMethod? = nil) {
        self.selectedMethod = selectedMethod
    }

    func select(_ method: TallaPaymentMethod) {
        guard canChangeMethod else { return }
        selectedMethod = method
        if state == .failed || state == .cancelled {
            transition(to: .idle)
        }
    }

    func transition(to nextState: TallaPaymentState, error: String? = nil) {
        guard nextState != state || error != errorMessage else { return }
        state = nextState
        errorMessage = error
    }

    func begin() -> Bool {
        guard canStart else { return false }
        transition(to: .creatingSession)
        return true
    }

    func cancel() {
        guard state != .succeeded else { return }
        transition(to: .cancelled)
    }

    func reset() {
        transition(to: .idle)
    }
}

enum MastercardSDKAvailability {
    static var isAvailable: Bool {
#if canImport(Gateway) && canImport(uSDK)
        true
#else
        false
#endif
    }
}

struct PaymentMethodSelectorView: View {
    @Binding var selectedMethod: TallaPaymentMethod
    let state: TallaPaymentState
    let applePayAvailable: Bool
    let gatewaySDKAvailable: Bool
    var availability = TallaPaymentAvailability()
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let surfaceColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var methods: [TallaPaymentMethod] {
        Self.visibleMethods(applePayAvailable: applePayAvailable, availability: availability)
    }

    static func visibleMethods(
        applePayAvailable: Bool,
        availability: TallaPaymentAvailability = TallaPaymentAvailability()
    ) -> [TallaPaymentMethod] {
        let methods: [TallaPaymentMethod] = applePayAvailable
            ? [.applePay, .benefitPay, .benefit, .card, .cashOnDelivery]
            : [.benefitPay, .benefit, .card, .cashOnDelivery]
        return methods.filter(availability.isEnabled)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(methods) { method in
                let enabled = method == .benefit
                    || (method == .benefitPay && BenefitPaySDKConfiguration.isAvailable)
                    || method == .cashOnDelivery
                    || gatewaySDKAvailable
                Button {
                    guard enabled, !state.isBusy else { return }
                    if reduceMotion {
                        selectedMethod = method
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedMethod = method
                        }
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        PaymentMethodBadge(method: method, accentColor: accentColor, enabled: enabled)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 7) {
                                Text(method.title)
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                    .foregroundStyle(enabled ? primaryColor : secondaryColor)
                                if method == .applePay && applePayAvailable {
                                    Text(AppLocalization.text("recommended", fallback: "Recommended"))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(accentColor)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(accentColor.opacity(0.1), in: Capsule())
                                }
                            }
                            Text(method.subtitle)
                                .font(.footnote)
                                .foregroundStyle(secondaryColor)
                                .fixedSize(horizontal: false, vertical: true)
                            if let supportingText = method.supportingText {
                                Text(supportingText)
                                    .font(.caption)
                                    .foregroundStyle(secondaryColor.opacity(0.86))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer()
                        if !enabled {
                            Text(AppLocalization.text("payment_unavailable", fallback: "Unavailable"))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(secondaryColor)
                        } else if selectedMethod == method {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(accentColor)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Circle()
                                .stroke(secondaryColor.opacity(0.45), lineWidth: 1)
                                .frame(width: 18, height: 18)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .frame(minHeight: 64)
                    .background(selectedMethod == method ? accentColor.opacity(0.075) : surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selectedMethod == method ? accentColor.opacity(0.55) : accentColor.opacity(0.1))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(
                        color: selectedMethod == method ? Color.black.opacity(0.045) : .clear,
                        radius: 8,
                        y: 3
                    )
                }
                .buttonStyle(.plain)
                .disabled(!enabled || state.isBusy)
                .padding(.vertical, 4)
                .accessibilityLabel(method.accessibilitySummary)
                .accessibilityHint(method.guidance)
                .accessibilityValue(selectedMethod == method
                    ? AppLocalization.text("selected", fallback: "Selected")
                    : AppLocalization.text("not_selected", fallback: "Not selected"))
            }

            SecurityReassurance(text: selectedMethod.guidance, accentColor: accentColor, textColor: secondaryColor)
                .padding(.top, 8)
        }
    }
}

struct PaymentMethodBadge: View {
    let method: TallaPaymentMethod
    let accentColor: Color
    let enabled: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(method == .benefit || method == .benefitPay
                    ? Color(red: 0.78, green: 0.1, blue: 0.18).opacity(0.1)
                    : method == .card ? Color.white : accentColor.opacity(0.09))
            if method == .applePay {
                HStack(spacing: 1) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 15, weight: .medium))
                    Text("Pay")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.primary)
            } else if method == .benefit {
                Image("BenefitLogo")
                    .resizable()
                    .scaledToFill()
            } else if method == .benefitPay {
                Image("BenefitPayLogo")
                    .resizable()
                    .scaledToFill()
            } else if method == .cashOnDelivery {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accentColor)
            } else {
                Image("CardBrandsLogo")
                    .resizable()
                    .scaledToFit()
                    .padding(3)
            }
        }
        .frame(width: method == .card ? 56 : 38, height: 38)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .opacity(enabled ? 1 : 0.45)
        .accessibilityHidden(true)
    }
}

struct CompactPaymentMethodRow: View {
    let selectedMethod: TallaPaymentMethod?
    let enabled: Bool
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let surfaceColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocalization.text("payment_method", fallback: "Payment method"))
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(accentColor)

                HStack(spacing: 12) {
                    if let selectedMethod {
                        PaymentMethodBadge(method: selectedMethod, accentColor: accentColor, enabled: enabled)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedMethod.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(primaryColor)
                            Text(selectedMethod.sheetSubtitle)
                                .font(.footnote)
                                .foregroundStyle(secondaryColor)
                                .lineLimit(1)
                        }
                    } else {
                        Image(systemName: "wallet.bifold")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(accentColor)
                            .frame(width: 38, height: 38)
                            .background(accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        Text(AppLocalization.text("choose_how_to_pay", fallback: "Choose how to pay"))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(primaryColor)
                    }

                    Spacer(minLength: 8)
                    Image(systemName: "chevron.forward")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(secondaryColor)
                        .accessibilityHidden(true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(surfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(selectedMethod?.accessibilitySummary ?? AppLocalization.text("choose_how_to_pay", fallback: "Choose how to pay"))
        .accessibilityHint(AppLocalization.text("payment_method_change_hint", fallback: "Opens payment method choices"))
    }
}

struct PaymentMethodSelectionSheet: View {
    let applePayAvailable: Bool
    let gatewaySDKAvailable: Bool
    let availability: TallaPaymentAvailability
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let surfaceColor: Color
    let onConfirm: (TallaPaymentMethod) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftMethod: TallaPaymentMethod?

    init(
        selectedMethod: TallaPaymentMethod?,
        applePayAvailable: Bool,
        gatewaySDKAvailable: Bool,
        availability: TallaPaymentAvailability = TallaPaymentAvailability(),
        primaryColor: Color,
        secondaryColor: Color,
        accentColor: Color,
        surfaceColor: Color,
        onConfirm: @escaping (TallaPaymentMethod) -> Void
    ) {
        self.applePayAvailable = applePayAvailable
        self.gatewaySDKAvailable = gatewaySDKAvailable
        self.availability = availability
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.surfaceColor = surfaceColor
        self.onConfirm = onConfirm
        let visibleMethods = PaymentMethodSelectorView.visibleMethods(applePayAvailable: applePayAvailable, availability: availability)
        _draftMethod = State(initialValue: selectedMethod.flatMap { visibleMethods.contains($0) ? $0 : nil })
    }

    private var methods: [TallaPaymentMethod] {
        PaymentMethodSelectorView.visibleMethods(applePayAvailable: applePayAvailable, availability: availability)
            .filter(isEnabled)
    }

    private func isEnabled(_ method: TallaPaymentMethod) -> Bool {
        method == .benefit
            || (method == .benefitPay && BenefitPaySDKConfiguration.isAvailable)
            || method == .cashOnDelivery
            || gatewaySDKAvailable
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(methods) { method in
                        let enabled = isEnabled(method)
                        Button {
                            guard enabled else { return }
                            draftMethod = method
                            onConfirm(method)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                PaymentMethodBadge(method: method, accentColor: accentColor, enabled: enabled)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 7) {
                                        Text(method.title)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(enabled ? primaryColor : secondaryColor)
                                        if method == .applePay && applePayAvailable {
                                            Text(AppLocalization.text("recommended", fallback: "Recommended"))
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(accentColor)
                                        }
                                    }
                                    Text(method.sheetSubtitle)
                                        .font(.footnote)
                                        .foregroundStyle(secondaryColor)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 8)
                                if !enabled {
                                    Text(AppLocalization.text("payment_unavailable", fallback: "Unavailable"))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(secondaryColor)
                                } else if draftMethod == method {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(accentColor)
                                } else {
                                    Circle()
                                        .stroke(secondaryColor.opacity(0.42), lineWidth: 1)
                                        .frame(width: 18, height: 18)
                                }
                            }
                            .padding(.horizontal, 13)
                            .frame(minHeight: 64)
                            .background(draftMethod == method ? accentColor.opacity(0.075) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(draftMethod == method ? accentColor.opacity(0.5) : accentColor.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!enabled)
                        .accessibilityLabel(method.accessibilitySummary)
                        .accessibilityValue(draftMethod == method
                            ? AppLocalization.text("selected", fallback: "Selected")
                            : AppLocalization.text("not_selected", fallback: "Not selected"))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .background(surfaceColor.ignoresSafeArea())
            .navigationTitle(AppLocalization.text("choose_how_to_pay", fallback: "Choose how to pay"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("cancel", fallback: "Cancel")) { dismiss() }
                }
            }
        }
    }
}

struct CheckoutHeader: View {
    let accentColor: Color
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(AppLocalization.text("choose_how_to_pay", fallback: "Choose how to pay"))
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(primaryColor)
            SecurityReassurance(
                text: AppLocalization.text("payment_encrypted_secure", fallback: "Your payment is encrypted and processed securely."),
                accentColor: accentColor,
                textColor: secondaryColor
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SecurityReassurance: View {
    let text: String
    let accentColor: Color
    let textColor: Color

    var body: some View {
        Label {
            Text(text)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "lock.shield.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
        }
        .foregroundStyle(textColor)
        .accessibilityElement(children: .combine)
    }
}

struct CompactOrderSummary: View {
    let thumbnail: AnyView
    let itemCountText: String
    let rows: [(title: String, value: String, emphasized: Bool)]
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let surfaceColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                thumbnail
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppLocalization.text("order_summary", fallback: "Order Summary"))
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(accentColor)
                    Text(itemCountText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(primaryColor)
                }
                Spacer()
            }
            Divider().overlay(accentColor.opacity(0.12))
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .firstTextBaseline) {
                    Text(row.title)
                        .font(row.emphasized ? .subheadline.weight(.semibold) : .footnote)
                        .foregroundStyle(row.emphasized ? primaryColor : secondaryColor)
                    Spacer()
                    Text(row.value)
                        .font(row.emphasized ? .headline : .footnote.weight(.medium))
                        .foregroundStyle(row.emphasized ? primaryColor : secondaryColor)
                        .monospacedDigit()
                }
            }
        }
        .padding(14)
        .background(surfaceColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(0.12), lineWidth: 1)
        )
    }
}

struct PaymentStatusView: View {
    let state: TallaPaymentState
    let accentColor: Color
    let primaryColor: Color
    let secondaryColor: Color

    private var copy: (icon: String, title: String, detail: String) {
        switch state {
        case .creatingSession:
            return ("lock.rotation", AppLocalization.text("payment_preparing", fallback: "Preparing secure checkout…"), "")
        case .authenticating:
            return ("checkmark.shield", AppLocalization.text("payment_verifying", fallback: "Verifying your payment…"), "")
        case .processing:
            return ("hourglass", AppLocalization.text("payment_processing", fallback: "Completing your order…"), "")
        case .succeeded:
            return ("checkmark.circle.fill", AppLocalization.text("payment_complete_title", fallback: "Payment complete"), AppLocalization.text("payment_complete_detail", fallback: "Your Talla order is confirmed."))
        case .cancelled:
            return ("xmark.circle", AppLocalization.text("payment_cancelled_title", fallback: "Payment cancelled"), AppLocalization.text("payment_cancelled_detail", fallback: "No charge was made."))
        case .failed:
            return ("exclamationmark.circle", AppLocalization.text("payment_failed_title", fallback: "We couldn’t complete the payment."), AppLocalization.text("payment_failed_detail", fallback: "Please check your details or try another payment method."))
        case .idle, .awaitingCustomer:
            return ("lock.shield", "", "")
        }
    }

    var body: some View {
        if state != .idle && state != .awaitingCustomer {
            HStack(spacing: 12) {
                if state.isBusy {
                    ProgressView().tint(accentColor)
                } else {
                    Image(systemName: copy.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(state == .succeeded ? Color.green : accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(copy.title).font(.subheadline.weight(.semibold)).foregroundStyle(primaryColor)
                    if !copy.detail.isEmpty {
                        Text(copy.detail).font(.caption).foregroundStyle(secondaryColor)
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }
}

struct CheckoutActionBar: View {
    let method: TallaPaymentMethod?
    let amountText: String
    let state: TallaPaymentState
    let enabled: Bool
    let applePayAvailable: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(AppLocalization.text("total", fallback: "Total"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(amountText)
                    .font(.headline)
                    .monospacedDigit()
            }

            if method == .applePay && applePayAvailable {
                TallaApplePayButton(action: action)
                    .frame(height: 50)
                    .allowsHitTesting(enabled && !state.isBusy)
                    .opacity(enabled && !state.isBusy ? 1 : 0.5)
                    .accessibilityLabel(
                        String(
                            format: AppLocalization.text(
                                "payment_apple_pay_amount_accessibility",
                                fallback: "Apple Pay, %@"
                            ),
                            amountText
                        )
                    )
            } else {
                Button(action: action) {
                    HStack(spacing: 8) {
                        if state.isBusy {
                            ProgressView().tint(Color.black.opacity(0.75))
                        }
                        Text(state.isBusy
                            ? AppLocalization.text("payment_preparing", fallback: "Preparing secure checkout…")
                            : method?.actionTitle ?? AppLocalization.text("choose_how_to_pay", fallback: "Choose how to pay"))
                            .font(.headline)
                        Spacer()
                        Text(amountText)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .foregroundStyle(Color(red: 0.08, green: 0.065, blue: 0.04))
                    .padding(.horizontal, 17)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!enabled || state.isBusy)
                .accessibilityLabel("\(method?.actionTitle ?? AppLocalization.text("choose_how_to_pay", fallback: "Choose how to pay")), \(amountText)")
            }

            Text(AppLocalization.text("payment_terms_reassurance", fallback: "By continuing, you agree to the order total shown above. Talla never stores your card details."))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if canImport(PassKit) && canImport(UIKit)
private struct TallaApplePayButton: UIViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .checkout, paymentButtonStyle: .automatic)
        button.cornerRadius = 13
        button.addTarget(context.coordinator, action: #selector(Coordinator.performAction), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        context.coordinator.action = action
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func performAction() { action() }
    }
}
#else
private struct TallaApplePayButton: View {
    let action: () -> Void
    var body: some View { EmptyView() }
}
#endif

enum CheckoutCurrencyFormatter {
    static func bhd(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        return String(format: "BHD %.3f", number.doubleValue)
    }
}

enum TallaFulfillmentMethod: String, CaseIterable, Identifiable {
    case delivery
    case pickup

    var id: String { rawValue }
}

struct TallaPaymentAvailability {
    var applePayEnabled = true
    var benefitPayEnabled = true
    var benefitEnabled = true
    var cardEnabled = true
    var cashOnDeliveryEnabled = true

    func isEnabled(_ method: TallaPaymentMethod) -> Bool {
        switch method {
        case .applePay: applePayEnabled
        case .benefitPay: benefitPayEnabled
        case .benefit: benefitEnabled
        case .card: cardEnabled
        case .cashOnDelivery: cashOnDeliveryEnabled
        }
    }
}

struct TallaShippingConfiguration {
    struct Tier {
        let maximumWeightGrams: Double
        let rate: Double
    }

    var bahrainRate = 2.0
    var khaleejiCashOnDeliverySurcharge = 2.0
    var maximumKhaleejiWeightGrams = 4_000.0
    var khaleejiTransitTime = "3 to 5 business days"
    var khaleejiTiers = [
        Tier(maximumWeightGrams: 500, rate: 5.5), Tier(maximumWeightGrams: 1_000, rate: 6.5),
        Tier(maximumWeightGrams: 1_500, rate: 7.5), Tier(maximumWeightGrams: 2_000, rate: 8.5),
        Tier(maximumWeightGrams: 2_500, rate: 9.5), Tier(maximumWeightGrams: 3_000, rate: 10.5),
        Tier(maximumWeightGrams: 3_500, rate: 11.5), Tier(maximumWeightGrams: 4_000, rate: 12.5)
    ]
}

enum TallaShippingRates {
    static let bahrainRate = 2.000
    static let khaleejiCashOnDeliverySurcharge = 2.000
    static let maximumKhaleejiWeightGrams = 4_000.0
    static let khaleejiTransitTime = "3 to 5 business days"

    private static let khaleejiCountryCodes: Set<String> = ["SA", "KW", "AE", "QA", "OM"]
    private static let khaleejiTiers: [(maximumWeightGrams: Double, rate: Double)] = [
        (500, 5.500),
        (1_000, 6.500),
        (1_500, 7.500),
        (2_000, 8.500),
        (2_500, 9.500),
        (3_000, 10.500),
        (3_500, 11.500),
        (4_000, 12.500)
    ]

    static func rate(
        countryCode: String,
        weightGrams: Double,
        cashOnDelivery: Bool,
        configuration: TallaShippingConfiguration = TallaShippingConfiguration()
    ) -> Double? {
        let normalizedCountryCode = countryCode.uppercased()
        if normalizedCountryCode == "BH" {
            return configuration.bahrainRate
        }

        guard khaleejiCountryCodes.contains(normalizedCountryCode),
              weightGrams > 0,
              weightGrams <= configuration.maximumKhaleejiWeightGrams,
              let tier = configuration.khaleejiTiers.first(where: { weightGrams <= $0.maximumWeightGrams }) else {
            return nil
        }

        return tier.rate + (cashOnDelivery ? configuration.khaleejiCashOnDeliverySurcharge : 0)
    }
}

enum TallaPaymentService {
    struct Session: Decodable {
        let sessionId: String
        let sessionVersion: String
        let apiVersion: String
        let merchantId: String
        let orderId: String
        let amount: String
        let currency: String
    }

    struct HostedCheckout: Decodable {
        let paymentUrl: URL
        let orderId: String
        let amount: String
        let currency: String
    }

    struct Completion: Decodable {
        let status: String
        let orderId: String
        let duplicate: Bool
    }

    struct AuthenticationRegistration: Decodable {
        let authenticationTransactionId: String
        let sdkManaged: Bool
    }

    static let applePayMerchantIdentifier = "merchant.talla.me"
    private static let accessTokenKey = "local.customerAccessToken"

    static func createCardSession(orderID: String) async throws -> Session {
        try await post(path: "/api/payments/card/session", payload: ["orderID": orderID])
    }

    static func createApplePaySession(orderID: String) async throws -> Session {
        try await post(path: "/api/payments/apple-pay/session", payload: ["orderID": orderID])
    }

    static func createClickToPay(orderID: String) async throws -> HostedCheckout {
        try await post(path: "/api/payments/click-to-pay/create", payload: ["orderID": orderID])
    }

    static func initiateAuthentication(orderID: String, sessionID: String) async throws -> Data {
        try await postData(
            path: "/api/payments/card/authentication/initiate",
            payload: ["orderID": orderID, "sessionId": sessionID]
        )
    }

    static func registerSDKAuthentication(
        orderID: String,
        sessionID: String,
        transactionID: String
    ) async throws -> AuthenticationRegistration {
        try await post(
            path: "/api/payments/card/authentication/initiate",
            payload: [
                "orderID": orderID,
                "sessionId": sessionID,
                "transactionId": transactionID,
                "sdkManaged": true
            ]
        )
    }

    static func authenticatePayer(orderID: String, sessionID: String) async throws -> Data {
        try await postData(
            path: "/api/payments/card/authentication/complete",
            payload: ["orderID": orderID, "sessionId": sessionID]
        )
    }

    static func completeCard(orderID: String, sessionID: String) async throws -> Completion {
        try await post(
            path: "/api/payments/card/complete",
            payload: ["orderID": orderID, "sessionId": sessionID]
        )
    }

    static func completeApplePay(orderID: String, sessionID: String) async throws -> Completion {
        try await post(
            path: "/api/payments/apple-pay/authorize",
            payload: ["orderID": orderID, "sessionId": sessionID]
        )
    }

    private static func post<Response: Decodable>(path: String, payload: [String: Any]) async throws -> Response {
        let data = try await postData(path: path, payload: payload)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private static func postData(path: String, payload: [String: Any]) async throws -> Data {
        guard let baseURL = BackendConfiguration.serviceBaseURL else {
            throw PaymentServiceError.unavailable
        }
        let token = UserDefaults.standard.string(forKey: accessTokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !token.isEmpty else { throw PaymentServiceError.authenticationRequired }
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await TallaSecureSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PaymentServiceError.unavailable
        }
        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let message = (try? JSONDecoder().decode(PaymentErrorResponse.self, from: data).error)
                ?? "Payment could not be completed."
            throw PaymentServiceError.gateway(message)
        }
        return data
    }
}

private struct PaymentErrorResponse: Decodable {
    let error: String
}

enum PaymentServiceError: LocalizedError {
    case unavailable
    case authenticationRequired
    case gateway(String)

    var errorDescription: String? {
        switch self {
        case .unavailable: return "The payment service is unavailable."
        case .authenticationRequired: return "Sign in again to continue."
        case .gateway(let message): return message
        }
    }
}

enum MastercardPaymentKind {
    case card
    case applePay
}

struct MastercardPaymentContext: Identifiable {
    let localOrderID: String
    let session: TallaPaymentService.Session
    let kind: MastercardPaymentKind

    var id: String { session.sessionId }
}

#if canImport(Gateway) && canImport(uSDK) && canImport(UIKit)
@MainActor
enum MastercardSDKClient {
    private static let gatewayRegion = GatewayRegion.other(
        id: "eazypay",
        name: "EazyPay",
        baseURL: "eazypay.gateway.mastercard.com"
    )

    static func configure(for session: TallaPaymentService.Session) {
        Gateway.loggingEnabled = false
        GatewaySDK.shared.initialize(
            merchantId: session.merchantId,
            region: gatewayRegion,
            locale: Locale.current.identifier
        )
    }

    static func updateCardSession(
        _ session: TallaPaymentService.Session,
        name: String,
        number: String,
        expiryMonth: String,
        expiryYear: String,
        securityCode: String
    ) async throws {
        var request = GatewayMap()
        request.set(.string(name), at: "sourceOfFunds.provided.card.nameOnCard")
        request.set(.string(number), at: "sourceOfFunds.provided.card.number")
        request.set(.string(securityCode), at: "sourceOfFunds.provided.card.securityCode")
        request.set(.string(expiryMonth), at: "sourceOfFunds.provided.card.expiry.month")
        request.set(.string(expiryYear), at: "sourceOfFunds.provided.card.expiry.year")
        try await update(session, request: request)
    }

    static func updateApplePaySession(
        _ session: TallaPaymentService.Session,
        paymentData: Data
    ) async throws {
        guard let paymentToken = String(data: paymentData, encoding: .utf8), !paymentToken.isEmpty else {
            throw PaymentServiceError.gateway("Apple Pay returned an invalid payment token.")
        }
        var request = GatewayMap()
        request.set(.string(paymentToken), at: "sourceOfFunds.provided.card.devicePayment.paymentToken")
        request.set(.string("APPLE_PAY"), at: "order.walletProvider")
        try await update(session, request: request)
    }

    private static func update(
        _ session: TallaPaymentService.Session,
        request: GatewayMap
    ) async throws {
        configure(for: session)
        let response = try await withCheckedThrowingContinuation { continuation in
            GatewayAPI.shared.updateSession(
                session.sessionId,
                apiVersion: session.apiVersion,
                payload: request
            ) { result in
                continuation.resume(with: result)
            }
        }
        if response.get("result").stringValue?.uppercased() == "ERROR" {
            throw PaymentServiceError.gateway("The gateway could not securely store the payment details.")
        }
    }

    static func authenticate(
        context: MastercardPaymentContext,
        navigationController: UINavigationController
    ) async throws -> AuthenticationResponse {
        configure(for: context.session)
        let proposedID = "AUTH\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let registration = try await TallaPaymentService.registerSDKAuthentication(
            orderID: context.localOrderID,
            sessionID: context.session.sessionId,
            transactionID: proposedID
        )
        let request = AuthenticationRequest(
            navController: navigationController,
            apiVersion: context.session.apiVersion,
            sessionId: context.session.sessionId,
            orderId: context.session.orderId,
            transactionId: registration.authenticationTransactionId
        )
        return await AuthenticationHandler.shared.authenticate(request)
    }
}

struct MastercardPaymentSheet: View {
    let context: MastercardPaymentContext
    @ObservedObject var flow: PaymentFlowModel

    @Environment(\.dismiss) private var dismiss
    @State private var cardholderName = ""
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var securityCode = ""
    @State private var validationMessage: String?
    @State private var authenticationContext: MastercardPaymentContext?
    @State private var applePayCoordinator: TallaApplePayCoordinator?
    @State private var hasStartedApplePay = false

    private var isCardInputValid: Bool {
        let digits = cardNumber.filter(\.isNumber)
        let month = Int(expiryMonth) ?? 0
        let year = expiryYear.filter(\.isNumber)
        let code = securityCode.filter(\.isNumber)
        return !cardholderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (12 ... 19).contains(digits.count)
            && (1 ... 12).contains(month)
            && (year.count == 2 || year.count == 4)
            && (3 ... 4).contains(code.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch context.kind {
                case .card:
                    cardForm
                case .applePay:
                    applePayProgress
                }
            }
            .navigationTitle(context.kind == .card
                ? AppLocalization.text("card_payment", fallback: "Card Payment")
                : AppLocalization.text("apple_pay", fallback: "Apple Pay"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("cancel", fallback: "Cancel")) {
                        flow.cancel()
                        dismiss()
                    }
                    .disabled(flow.state.isBusy)
                }
            }
        }
        .interactiveDismissDisabled(flow.state.isBusy)
        .fullScreenCover(item: $authenticationContext) { authenticationContext in
            MastercardAuthenticationView(context: authenticationContext) { result in
                self.authenticationContext = nil
                handleAuthentication(result)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            guard context.kind == .applePay, !hasStartedApplePay else { return }
            hasStartedApplePay = true
            startApplePay()
        }
    }

    private var cardForm: some View {
        Form {
            Section(AppLocalization.text("card_details", fallback: "Card details")) {
                TextField(AppLocalization.text("name_on_card", fallback: "Name on card"), text: $cardholderName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                TextField(AppLocalization.text("card_number", fallback: "Card number"), text: $cardNumber)
                    .keyboardType(.numberPad)
                    .textContentType(.creditCardNumber)
                HStack {
                    TextField("MM", text: $expiryMonth)
                        .keyboardType(.numberPad)
                    TextField("YY", text: $expiryYear)
                        .keyboardType(.numberPad)
                    SecureField("CVV", text: $securityCode)
                        .keyboardType(.numberPad)
                }
            }
            Section {
                Button {
                    submitCard()
                } label: {
                    HStack {
                        Spacer()
                        if flow.state.isBusy {
                            ProgressView()
                        } else {
                            Text(String(format: AppLocalization.text("pay_amount_bhd_format", fallback: "Pay %@ BHD"), context.session.amount))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isCardInputValid || flow.state.isBusy)
            } footer: {
                Text(AppLocalization.text("card_security_detail", fallback: "Card details go directly to Mastercard Gateway and are never sent to Talla's backend."))
            }
            if let message = validationMessage ?? flow.errorMessage {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var applePayProgress: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "apple.logo")
                .font(.system(size: 48, weight: .semibold))
            ProgressView()
            Text(AppLocalization.text("preparing_secure_apple_pay", fallback: "Preparing secure Apple Pay…"))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    private func submitCard() {
        guard isCardInputValid, !flow.state.isBusy else { return }
        validationMessage = nil
        flow.transition(to: .processing)
        let normalizedNumber = cardNumber.filter(\.isNumber)
        let normalizedMonth = String(format: "%02d", Int(expiryMonth) ?? 0)
        let normalizedYear = String(expiryYear.filter(\.isNumber).suffix(2))
        let normalizedCode = securityCode.filter(\.isNumber)
        Task {
            do {
                try await MastercardSDKClient.updateCardSession(
                    context.session,
                    name: cardholderName.trimmingCharacters(in: .whitespacesAndNewlines),
                    number: normalizedNumber,
                    expiryMonth: normalizedMonth,
                    expiryYear: normalizedYear,
                    securityCode: normalizedCode
                )
                cardNumber = ""
                securityCode = ""
                flow.transition(to: .authenticating)
                authenticationContext = context
            } catch {
                fail(error)
            }
        }
    }

    private func handleAuthentication(_ result: Result<AuthenticationResponse, Error>) {
        switch result {
        case .success(let response) where response.recommendation == .proceed:
            flow.transition(to: .processing)
            Task {
                do {
                    _ = try await TallaPaymentService.completeCard(
                        orderID: context.localOrderID,
                        sessionID: context.session.sessionId
                    )
                    succeed()
                } catch {
                    fail(error)
                }
            }
        case .success(let response):
            if let error = response.error {
                fail(error)
            } else {
                fail(PaymentServiceError.gateway("Card authentication was not approved."))
            }
        case .failure(let error):
            if let authenticationError = error as? AuthenticationError,
               authenticationError == .challengeCancelledByUser {
                flow.cancel()
                dismiss()
            } else {
                fail(error)
            }
        }
    }

    private func startApplePay() {
        flow.transition(to: .awaitingCustomer)
        let coordinator = TallaApplePayCoordinator(context: context) { result in
            applePayCoordinator = nil
            switch result {
            case .success:
                succeed()
            case .failure(let error):
                if let paymentError = error as? TallaApplePayError, paymentError == .cancelled {
                    flow.cancel()
                    dismiss()
                } else {
                    fail(error)
                }
            }
        }
        applePayCoordinator = coordinator
        coordinator.start()
    }

    private func succeed() {
        flow.transition(to: .succeeded)
        dismiss()
    }

    private func fail(_ error: Error) {
        validationMessage = error.localizedDescription
        flow.transition(to: .failed, error: error.localizedDescription)
    }
}

private struct MastercardAuthenticationView: UIViewControllerRepresentable {
    let context: MastercardPaymentContext
    let completion: (Result<AuthenticationResponse, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(context: context, completion: completion)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        viewController.view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor)
        ])
        let navigationController = UINavigationController(rootViewController: viewController)
        DispatchQueue.main.async {
            context.coordinator.start(using: navigationController)
        }
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator {
        private let context: MastercardPaymentContext
        private let completion: (Result<AuthenticationResponse, Error>) -> Void
        private var started = false

        init(
            context: MastercardPaymentContext,
            completion: @escaping (Result<AuthenticationResponse, Error>) -> Void
        ) {
            self.context = context
            self.completion = completion
        }

        @MainActor
        func start(using navigationController: UINavigationController) {
            guard !started else { return }
            started = true
            Task {
                do {
                    let response = try await MastercardSDKClient.authenticate(
                        context: context,
                        navigationController: navigationController
                    )
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}

private enum TallaApplePayError: LocalizedError, Equatable {
    case unavailable
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Apple Pay is unavailable on this device."
        case .cancelled: return "Apple Pay was cancelled."
        }
    }
}

@MainActor
private final class TallaApplePayCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
    private let context: MastercardPaymentContext
    private let completion: (Result<Void, Error>) -> Void
    private var authorizationController: PKPaymentAuthorizationController?
    private var completed = false
    private var hasFinished = false

    init(context: MastercardPaymentContext, completion: @escaping (Result<Void, Error>) -> Void) {
        self.context = context
        self.completion = completion
    }

    func start() {
        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard]) else {
            finish(.failure(TallaApplePayError.unavailable))
            return
        }
        let request = PKPaymentRequest()
        request.merchantIdentifier = TallaPaymentService.applePayMerchantIdentifier
        request.countryCode = "BH"
        request.currencyCode = "BHD"
        request.supportedNetworks = [.visa, .masterCard]
        request.merchantCapabilities = [.threeDSecure, .credit, .debit]
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: "Talla Speciality",
                amount: NSDecimalNumber(string: context.session.amount),
                type: .final
            )
        ]
        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        authorizationController = controller
        controller.present { [weak self] presented in
            guard !presented else { return }
            DispatchQueue.main.async { [weak self] in
                self?.finish(.failure(TallaApplePayError.unavailable))
            }
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        Task {
            do {
                try await MastercardSDKClient.updateApplePaySession(
                    context.session,
                    paymentData: payment.token.paymentData
                )
                _ = try await TallaPaymentService.completeApplePay(
                    orderID: context.localOrderID,
                    sessionID: context.session.sessionId
                )
                completed = true
                handler(PKPaymentAuthorizationResult(status: .success, errors: nil))
            } catch {
                handler(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
                finish(.failure(error))
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let coordinator = self else { return }
                if coordinator.completed {
                    coordinator.finish(.success(()))
                } else {
                    coordinator.finish(.failure(TallaApplePayError.cancelled))
                }
            }
        }
    }

    private func finish(_ result: Result<Void, Error>) {
        guard !hasFinished else { return }
        hasFinished = true
        authorizationController = nil
        completion(result)
    }
}
#endif
