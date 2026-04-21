import SwiftUI
#if canImport(PassKit)
import PassKit
#endif

struct NativeCheckoutView: View {
    enum FulfillmentOption: String, CaseIterable, Identifiable {
        case delivery
        case pickup

        var id: String { rawValue }

        var title: String {
            switch self {
            case .delivery:
                return "Delivery"
            case .pickup:
                return "Pickup"
            }
        }

        var detail: String {
            switch self {
            case .delivery:
                return "Send the order to your saved address."
            case .pickup:
                return "Collect it from the cafe after payment."
            }
        }
    }

    struct CheckoutLine: Identifiable {
        let id: String
        let title: String
        let detail: String
        let total: String
    }

    let primaryTextColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let elevatedSurfaceColor: Color
    let titleFont: Font
    let bodyFont: Font
    let labelFont: Font
    let lines: [CheckoutLine]
    let subtotal: String
    let discount: String?
    let total: String
    let voucherCode: String?
    let customerName: String
    let customerEmail: String
    let preferredAddress: ContentView.DeliveryAddress?
    let isSubmitting: Bool
    let errorMessage: String?
    let applePayContent: AnyView
    let dismissAction: () -> Void
    let editAddressAction: () -> Void
    let confirmAction: (FulfillmentOption) -> Void

    @State private var fulfillmentOption: FulfillmentOption = .delivery

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroSection
                    contactSection
                    fulfillmentSection
                    summarySection
                    applePaySection
                    confirmSection
                }
                .padding(20)
            }
            .background(elevatedSurfaceColor.ignoresSafeArea())
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", action: dismissAction)
                        .foregroundColor(accentColor)
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REVIEW ORDER")
                .font(labelFont)
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            Text("Keep the checkout flow in the app, then hand off to secure payment only at the end.")
                .font(titleFont)
                .foregroundColor(primaryTextColor)

            Text("You can confirm your fulfillment preference, delivery details, and totals here before payment.")
                .font(bodyFont)
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accentColor.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Customer")

            VStack(alignment: .leading, spacing: 6) {
                Text(customerName)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(primaryTextColor)

                Text(customerEmail)
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var fulfillmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Fulfillment")

            ForEach(FulfillmentOption.allCases) { option in
                Button {
                    fulfillmentOption = option
                } label: {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: fulfillmentOption == option ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title)
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundColor(primaryTextColor)

                            Text(option.detail)
                                .font(bodyFont)
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(accentColor.opacity(fulfillmentOption == option ? 0.28 : 0.10), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if fulfillmentOption == .delivery {
                deliveryAddressCard
            } else {
                pickupCard
            }
        }
    }

    private var deliveryAddressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Delivery Address")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryTextColor)

                Spacer()

                Button("Edit", action: editAddressAction)
                    .font(labelFont)
                    .foregroundColor(accentColor)
            }

            if let preferredAddress {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(preferredAddress.fullName) • \(preferredAddress.phone)")
                        .font(bodyFont)
                        .foregroundColor(primaryTextColor)

                    Text("\(preferredAddress.line1), \(preferredAddress.city)")
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)

                    if let notes = preferredAddress.notes, !notes.isEmpty {
                        Text(notes)
                            .font(bodyFont)
                            .foregroundColor(secondaryTextColor)
                    }
                }
            } else {
                Text("Add a preferred address before completing a delivery order.")
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var pickupCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pickup Window")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(primaryTextColor)

            Text("You’ll choose your pickup timing after secure payment. We’ll keep your order details tied to this customer account.")
                .font(bodyFont)
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Order")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(lines) { line in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(primaryTextColor)

                            Text(line.detail)
                                .font(bodyFont)
                                .foregroundColor(secondaryTextColor)
                        }

                        Spacer()

                        Text(line.total)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                    }
                }

                Divider()

                valueRow("Subtotal", subtotal)

                if let discount {
                    valueRow("Voucher", "-\(discount)")
                }

                if let voucherCode, !voucherCode.isEmpty {
                    valueRow("Applied Code", voucherCode)
                }

                valueRow("Total", total, emphasized: true)
            }
            .padding(16)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var confirmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let errorMessage {
                Text(errorMessage)
                    .font(bodyFont)
                    .foregroundColor(.red.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                confirmAction(fulfillmentOption)
            } label: {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .tint(Color(hex: 0x0A0804))
                        }

                        Text(isSubmitting ? "PREPARING..." : "CONTINUE TO SECURE PAYMENT")
                    }
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .tracking(1.8)

                    Text(fulfillmentOption == .delivery
                        ? "We’ll pass your reviewed delivery details into the secure payment step."
                        : "We’ll keep you in the app flow until the secure payment handoff.")
                        .font(.system(size: 11, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: 0x0A0804).opacity(0.82))
                }
                .foregroundColor(Color(hex: 0x0A0804))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSubmitDisabled)
        }
    }

    private var applePaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Apple Pay")
            applePayContent
        }
    }

    private var isSubmitDisabled: Bool {
        isSubmitting || (fulfillmentOption == .delivery && preferredAddress == nil)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(labelFont)
            .tracking(2.2)
            .textCase(.uppercase)
            .foregroundColor(accentColor)
    }

    private func valueRow(_ title: String, _ value: String, emphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .system(size: 14, weight: .bold) : bodyFont)
                .foregroundColor(emphasized ? primaryTextColor : secondaryTextColor)

            Spacer()

            Text(value)
                .font(emphasized ? .system(size: 14, weight: .bold) : bodyFont)
                .foregroundColor(emphasized ? accentColor : primaryTextColor)
        }
    }
}
