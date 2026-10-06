import Foundation
import SwiftUI
import StoreKit
#if canImport(Security)
import Security
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

extension ContentView {
    var selectedPickupLocation: ContentView.AppSettings.Fulfillment.Location? {
        guard let locations = remoteAppSettings?.fulfillment?.locations, !locations.isEmpty else { return nil }
        return locations.first(where: { $0.id == selectedPickupLocationID }) ?? locations.first
    }

    var pickupTimeSlots: [String] {
        if let slots = selectedPickupLocation?.pickupSlots, !slots.isEmpty {
            return slots.filter { $0.remaining > 0 }.map { isArabicInterface ? $0.labelAR : $0.labelEN }
        }
        if let slots = remoteAppSettings?.fulfillment?.pickupSlots, !slots.isEmpty {
            return slots.filter { $0.remaining > 0 }.map { isArabicInterface ? $0.labelAR : $0.labelEN }
        }
        return ["10:00–12:00", "12:00–14:00", "14:00–16:00", "16:00–18:00", "18:00–20:00"]
    }

    var pickupTemporarilyClosed: Bool {
        if let location = selectedPickupLocation {
            let closure = isArabicInterface ? location.temporaryClosureAR : location.temporaryClosureEN
            if !(closure ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        }
        let closure = isArabicInterface
            ? remoteAppSettings?.fulfillment?.temporaryClosureAR
            : remoteAppSettings?.fulfillment?.temporaryClosureEN
        return !(closure ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var pickupClosureMessage: String? {
        if let location = selectedPickupLocation {
            let locationClosure = isArabicInterface ? location.temporaryClosureAR : location.temporaryClosureEN
            let value = locationClosure?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty { return value }
        }
        let closure = isArabicInterface
            ? remoteAppSettings?.fulfillment?.temporaryClosureAR
            : remoteAppSettings?.fulfillment?.temporaryClosureEN
        let value = closure?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var cartCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var customerPriceMultiplier: Double {
        preferredAddress?.country.rawValue == "BH" || preferredAddress == nil ? 1.0 : 1.10
    }

    func customerPriceValue(from price: String) -> Double {
        priceValue(from: price) * customerPriceMultiplier
    }

    var cartRequiresPickup: Bool {
        cartItems.contains { item in
            ["ready-made-drinks", "summer-drinks", "desserts"].contains(item.product.categoryKey)
        }
    }

    var cartSingleShipmentSubtotal: Double {
        cartItems.reduce(0) { partialResult, item in
            partialResult + (customerPriceValue(from: item.variant.price) * Double(item.quantity))
        }
    }

    var cartSubtotal: Double {
        if isCafePassActive {
            return cartItems.reduce(0) { $0 + priceValue(from: $1.variant.price) * Double($1.quantity) } * Double(cafePassCreditCount)
        }
        return cartSingleShipmentSubtotal * Double(coffeeClubShipmentCount)
    }

    var configuredCoffeeClubShipmentCount: Int {
        remoteAppSettings?.coffeeClub?.shipmentCount ?? 3
    }

    var configuredCoffeeClubIntervalWeeks: Int {
        remoteAppSettings?.coffeeClub?.intervalWeeks ?? 4
    }

    var coffeeClubPlanType: String {
        guard let first = cartItems.first.flatMap({ prepaidPlanType(for: $0.product) }) else { return "beans" }
        return cartItems.allSatisfy({ prepaidPlanType(for: $0.product) == first }) ? first : "beans"
    }

    func prepaidPlanType(for product: Product) -> String? {
        let detectedPlan = defaultPrepaidPlanType(for: product)
        return ProductCatalogRules.subscriptionPlanType(
            detectedPlan: detectedPlan,
            requestedPlan: requestedSubscriptionPlanType
        )
    }

    func defaultPrepaidPlanType(for product: Product) -> String? {
        let name = product.name.lowercased()
        // Gift boxes may contain Arabic coffee, but the subscription belongs
        // to the Discovery Box plan rather than Qahwa replenishment.
        if product.categoryKey == "gifts" {
            return ["box", "discovery", "seasonal", "صندوق", "علبة"].contains(where: { name.contains($0) }) ? "seasonal-box" : nil
        }
        if product.categoryKey == "arabic-coffee-beans"
            || ProductCatalogRules.isArabicCoffeeProduct(product.catalogClassificationText) {
            return "arabic-coffee"
        }
        switch product.categoryKey {
        case "coffee-beans": return "beans"
        case "arabic-coffee-beans": return "arabic-coffee"
        case "drip-bags": return "drip-bags"
        case "coffee-equipment":
            if Self.isCoffeeFilterPack(product) { return "filters" }
            return isEquipmentConsumable(product) ? "equipment" : nil
        default: return nil
        }
    }

    func isEquipmentConsumable(_ product: Product) -> Bool {
        let text = product.catalogClassificationText.lowercased()
        let consumableTerms = ["filter", "paper refill", "cleaning tablet", "cleaner", "descaler", "descaling", "backflush", "water cartridge", "فلاتر", "فلتر", "منظف", "تنظيف"]
        return consumableTerms.contains(where: text.contains)
    }

    static func isCoffeeFilterPack(_ product: Product) -> Bool {
        guard product.categoryKey == "coffee-equipment" else { return false }
        let text = product.catalogClassificationText.lowercased()
        let hasFilter = ["filter", "فلاتر", "فلتر"].contains(where: text.contains)
        guard hasFilter else { return false }
        return ["coffee", "v60", "aeropress", "kalita", "chemex", "فلاتر", "فلتر"].contains(where: text.contains)
    }

    var prepaidPlanDisplayName: String {
        switch coffeeClubPlanType {
        case "drip-bags": return "Weekly Drip Bag Plan"
        case "filters": return "Filter Replenishment Plan"
        case "equipment": return "Equipment Consumables Plan"
        case "office": return "Office Coffee Plan"
        case "arabic-coffee": return "Arabic Coffee Replenishment Plan"
        case "seasonal-box": return "Seasonal Discovery Box Plan"
        default: return "Talla Coffee Club"
        }
    }

    var coffeeClubIntervalWeeks: Int {
        switch coffeeClubPlanType {
        case "drip-bags": return 1
        case "filters": return 12
        case "equipment": return 12
        case "seasonal-box": return 13
        default: return configuredCoffeeClubIntervalWeeks
        }
    }

    var configuredCoffeeClubDiscountPercent: Int {
        remoteAppSettings?.coffeeClub?.discountPercent ?? 10
    }

    var coffeeClubShipmentCount: Int {
        isCoffeeClubActive ? configuredCoffeeClubShipmentCount : 1
    }

    var isCoffeeClubEligible: Bool {
        guard !isCafePassActive else { return false }
        guard (remoteAppSettings?.coffeeClub?.enabled ?? false), !cartItems.isEmpty else { return false }
        guard let first = cartItems.first.flatMap({ prepaidPlanType(for: $0.product) }) else { return false }
        guard cartItems.allSatisfy({ prepaidPlanType(for: $0.product) == first }) else { return false }
        return first != "office" || cartItems.reduce(0) { $0 + $1.quantity } >= 2
    }

    var isCoffeeClubActive: Bool {
        isCoffeeClubPrepaid && isCoffeeClubEligible
    }

    var isCafePassEligible: Bool {
        !cartItems.isEmpty && cartItems.count == 1
            && cartItems[0].quantity == 1
            && ["ready-made-drinks", "summer-drinks"].contains(cartItems[0].product.categoryKey)
    }

    var isCafePassActive: Bool { isCafePassPrepaid && isCafePassEligible }

    var coffeeClubDiscount: Double {
        isCoffeeClubActive ? (cartSubtotal * Double(configuredCoffeeClubDiscountPercent) / 100) : 0
    }

    var cartDeliveryTitle: String {
        if isDigitalGiftCardOnlyCart {
            return isArabicInterface ? "إرسال رقمي" : "Digital delivery"
        }
        if fulfillmentMethod == .pickup {
            return AppLocalization.text("pickup", fallback: "Pickup")
        }
        let isKhaleejiCashOnDelivery = preferredAddress.map { $0.country.isKhaleeji && $0.country != .bahrain } == true
            && paymentFlow.selectedMethod == .cashOnDelivery
        let baseTitle = isKhaleejiCashOnDelivery
            ? AppLocalization.text("delivery_with_cod", fallback: "Delivery + COD fee")
            : AppLocalization.text("delivery", fallback: "Delivery")
        return isCoffeeClubActive
            ? String(format: AppLocalization.text("coffee_club_delivery_count", fallback: "%@ · %d shipments"), baseTitle, configuredCoffeeClubShipmentCount)
            : baseTitle
    }

    var cartOrderSummaryRows: [(title: String, value: String, emphasized: Bool)] {
        var rows: [(title: String, value: String, emphasized: Bool)] = [
            (AppLocalization.text("subtotal", fallback: "Subtotal"), formattedCustomerCurrency(cartSubtotal), false),
            (cartDeliveryTitle, cartShippingLabel, false)
        ]
        if isCoffeeClubActive {
            rows.insert((
                prepaidPlanDisplayName,
                String(
                    format: AppLocalization.text("coffee_club_three_shipments", fallback: "%d shipments · every %d weeks"),
                    configuredCoffeeClubShipmentCount,
                    coffeeClubIntervalWeeks
                ),
                false
            ), at: 0)
        }
        if isDigitalGiftCardOnlyCart {
            rows.append((isArabicInterface ? "المستلم" : "Recipient", giftRecipientEmail.trimmingCharacters(in: .whitespacesAndNewlines), false))
        } else if fulfillmentMethod == .pickup {
            rows.append((
                AppLocalization.text("pickup_location", fallback: "Pickup location"),
                managedPickupName,
                false
            ))
        } else if preferredAddress.map({ $0.country.isKhaleeji && $0.country != .bahrain }) == true {
            rows.append((
                AppLocalization.text("transit_time", fallback: "Transit time"),
                AppLocalization.text("khaleeji_transit_time", fallback: shippingConfiguration.khaleejiTransitTime),
                false
            ))
        }
        rows.append((
            AppLocalization.text("discount", fallback: "Discount"),
            cartDiscount > 0 ? "-\(formattedCustomerCurrency(cartDiscount))" : AppLocalization.text("none_dash", fallback: "—"),
            false
        ))
        rows.append((AppLocalization.text("total", fallback: "Total"), formattedCustomerCurrency(cartTotal), true))
        return rows
    }

    // Present provider UI only after checkout's full-screen dismissal finishes.
    // Updating both presentations in one render can drop the provider sheet.
    func presentPayment(_ presentation: PaymentPresentation) {
        pendingPaymentPresentation = presentation
        if isCheckoutPresented {
            isCheckoutPresented = false
        } else {
            presentPendingPayment()
        }
    }

    func presentPendingPayment() {
        guard let presentation = pendingPaymentPresentation else { return }
        pendingPaymentPresentation = nil
        switch presentation {
        case .hosted(let session): checkoutSession = session
        case .benefitPay(let session): benefitPaySession = session
        case .mastercard(let context): mastercardPaymentContext = context
        }
    }

    var cartDrawer: some View {
        CartDrawerView(
            scrimColor: scrimColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            elevatedSurfaceColor: elevatedSurfaceColor,
            accentColor: TallaTheme.Colors.accent,
            hasItems: !cartItems.isEmpty,
            emptyState: AnyView(cartEmptyState),
            reviewContent: AnyView(cartReviewContent),
            footerContent: AnyView(cartBagFooterContent),
            closeAction: {
                cartOpen = false
            }
        )
    }

    var cartEmptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("your_bag_is_empty", fallback: "Your bag is empty."))
                .font(titleFont(size: 22))
                .foregroundColor(primaryTextColor)

            Text(AppLocalization.text("cart_empty_guidance", fallback: "Start with coffee, tools, or gifts. Your selected items will appear here before checkout."))
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                cartOpen = false
                openShop()
            } label: {
                Text(AppLocalization.text("browse_products", fallback: "Browse Products"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(AppLocalization.letterSpacing(1.8))
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var cartReviewContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            cartItemsListSection
            if isCafePassEligible { cafePassOfferSection }
            if isCoffeeClubEligible {
                coffeeClubOfferSection
                if isCoffeeClubActive {
                    coffeeClubTermsSection
                }
            }
            if !isCoffeeClubActive && !isCafePassActive {
                cartPromoSection
            }
            giftOptionsSection
        }
    }

    var cafePassOfferSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isCafePassPrepaid) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suspendedCoffeePass && isGiftOrder ? "A prepaid coffee gift" : suspendedCoffeePass ? "Suspended coffees for the community" : "Daily cup café pass")
                        .font(labelFont(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    Text("Prepay \(cafePassCreditCount) of this drink at its current menu price. Valid for 30 days after payment; no discount.")
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                }
            }
            .tint(readableBrandGoldColor)
            .disabled(suspendedCoffeePass && isGiftOrder)
            .onChange(of: isCafePassPrepaid) { _, enabled in
                if enabled {
                    isCoffeeClubPrepaid = false
                    coffeeClubTermsAccepted = false
                } else {
                    suspendedCoffeePass = false
                }
            }
            if isCafePassPrepaid && !(suspendedCoffeePass && isGiftOrder) {
                Stepper("Drinks to sponsor: \(cafePassCreditCount)", value: $cafePassCreditCount, in: 1...20)
                    .font(bodyFont(size: 12))
            }
        }
        .padding(14)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 14))
    }

    var giftOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isGiftOrder) {
                Label(
                    AppLocalization.text("gift_order_title", fallback: "This is a gift"),
                    systemImage: "gift.fill"
                )
                .font(labelFont(size: 13, weight: .bold))
                .foregroundColor(primaryTextColor)
            }
            .tint(readableBrandGoldColor)
            .disabled(suspendedCoffeePass && isGiftOrder)
            .accessibilityIdentifier("checkout.gift.toggle")

            if isGiftOrder {
                VStack(alignment: .leading, spacing: 10) {
                    TextField(AppLocalization.text("gift_recipient_name", fallback: "Recipient name"), text: $giftRecipientName)
                        .textContentType(.name)
                        .textFieldStyle(.talla)
                        .accessibilityIdentifier("checkout.gift.recipient")
                    TextField(AppLocalization.text("gift_recipient_phone", fallback: "Recipient phone"), text: $giftRecipientPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .textFieldStyle(.talla)
                        .accessibilityIdentifier("checkout.gift.phone")
                    TextField(AppLocalization.text("gift_message", fallback: "Add a message (optional)"), text: $giftMessage, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.talla)
                        .accessibilityIdentifier("checkout.gift.message")
                }
                .padding(12)
                .background(cardFillColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            if cartItems.contains(where: { $0.product.isGiftCardProduct }) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Gift card recipient email", text: $giftRecipientEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textFieldStyle(.talla)
                    Text("Shopify sends the gift card code to this email after the order is fulfilled.")
                        .font(bodyFont(size: 11)).foregroundColor(secondaryTextColor)
                }
                .padding(12)
                .background(cardFillColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(14)
        .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.08 : 0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var coffeeClubOfferTitle: String {
        switch coffeeClubPlanType {
        case "beans":
            return "Prepaid bean deliveries"
        case "drip-bags":
            return "Weekly drip-bag plan"
        case "filters":
            return "Coffee filter replenishment"
        case "equipment":
            return "Coffee care replenishment"
        case "office":
            return "Office coffee plan"
        case "arabic-coffee":
            return "Arabic coffee replenishment"
        case "seasonal-box":
            return "Seasonal discovery box"
        default:
            return "Prepaid coffee plan"
        }
    }

    var coffeeClubOfferDetail: String {
        switch coffeeClubPlanType {
        case "drip-bags":
            return "Save \(configuredCoffeeClubDiscountPercent)% on every shipment. Delivery is charged for all \(configuredCoffeeClubShipmentCount) shipments. No renewal."
        case "filters":
            return "One filter shipment every 12 weeks. Delivery is charged for all \(configuredCoffeeClubShipmentCount) shipments. No automatic renewal."
        case "equipment":
            return "One consumables shipment every 12 weeks. Delivery is charged for all shipments. No automatic renewal."
        case "office":
            return "Multi-bag office supply every \(coffeeClubIntervalWeeks) weeks. Prepaid and manually renewed; choose at least two bags per shipment for your team."
        case "arabic-coffee":
            return "\(configuredCoffeeClubShipmentCount) deliveries every \(coffeeClubIntervalWeeks) weeks. Prepaid; no automatic renewal."
        case "seasonal-box":
            return "One discovery box every season. Delivery is charged for all \(configuredCoffeeClubShipmentCount) shipments. No automatic renewal."
        default:
            return String(
                format: AppLocalization.text(
                    "coffee_club_prepaid_detail",
                    fallback: "Save %d%% on every bag. One shipment every %d weeks; delivery is charged for all %d shipments. No renewal."
                ),
                configuredCoffeeClubDiscountPercent,
                coffeeClubIntervalWeeks,
                configuredCoffeeClubShipmentCount
            )
        }
    }

    var coffeeClubOfferSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isCoffeeClubPrepaid) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coffeeClubOfferTitle)
                        .font(labelFont(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    Text(coffeeClubOfferDetail)
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                    if coffeeClubPlanType == "office", cartItems.reduce(0, { $0 + $1.quantity }) < 2 {
                        Text("Office plans start at two bags per shipment.")
                            .font(labelFont(size: 11, weight: .semibold))
                            .foregroundColor(readableBrandGoldColor)
                    }
                }
            }
            .tint(readableBrandGoldColor)
            .onChange(of: isCoffeeClubPrepaid) { _, enabled in
                withAnimation(.easeInOut(duration: 0.18)) {
                    if enabled {
                        appliedVoucher = nil
                        voucherCodeInput = ""
                        voucherError = nil
                        if paymentFlow.selectedMethod == .cashOnDelivery {
                            paymentFlow.clearSelection()
                        }
                    } else {
                        coffeeClubTermsAccepted = false
                    }
                }
            }
            .disabled(coffeeClubPlanType == "office" && cartItems.reduce(0) { $0 + $1.quantity } < 2)
            .accessibilityIdentifier("cart.coffeeClubPrepaid")
            .accessibilityValue(isCoffeeClubPrepaid ? "Selected" : "Not selected")
        }
        .padding(14)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var coffeeClubTermsSection: some View {
        Button {
            coffeeClubTermsAccepted.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: coffeeClubTermsAccepted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(readableBrandGoldColor)
                Text(coffeeClubPlanType != "beans"
                    ? "I agree this plan is prepaid and does not renew automatically. Delivery is charged for every shipment. Changes apply only to undelivered shipments; cancellations or refunds require Talla approval."
                    : AppLocalization.text(
                        "coffee_club_terms_consent",
                        fallback: "I agree that Coffee Club is prepaid, does not renew automatically, delivery is charged for every shipment, future changes apply only to undelivered shipments, and cancellations or refunds require Talla approval."
                    ))
                .font(bodyFont(size: 11))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(TallaTheme.Colors.accent.opacity(coffeeClubTermsAccepted ? 0.42 : 0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("cart.coffeeClubTerms")
        .accessibilityValue(coffeeClubTermsAccepted ? "Accepted" : "Not accepted")
    }

    var cartPromoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isVoucherCodeEntryExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Label(
                        AppLocalization.text("add_voucher_discount_code", fallback: "Promo or reward"),
                        systemImage: "ticket"
                    )
                    .font(labelFont(size: 11, weight: .bold))
                    .foregroundColor(primaryTextColor)

                    Spacer()

                    if let appliedVoucher {
                        Text(appliedVoucher.code)
                            .font(bodyFont(size: 11))
                            .foregroundColor(readableBrandGoldColor)
                    }

                    Image(systemName: isVoucherCodeEntryExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(readableBrandGoldColor)
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            if isVoucherCodeEntryExpanded {
                HStack(spacing: 10) {
                    TextField(
                        AppLocalization.text("enter_voucher_code", fallback: "Enter code"),
                        text: $voucherCodeInput
                    )
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .font(bodyFont(size: 14))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .background(cardFillColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        Task { await applyVoucher() }
                    } label: {
                        Text(isApplyingVoucher ? "…" : AppLocalization.text("apply", fallback: "Apply"))
                            .font(labelFont(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 16)
                            .frame(minHeight: 48)
                            .background(TallaTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isApplyingVoucher || voucherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let appliedVoucher {
                    HStack {
                        Text(String(
                            format: AppLocalization.text("voucher_applied_summary", fallback: "Voucher %@ applied"),
                            appliedVoucher.code
                        ))
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)

                        Spacer()

                        Button(AppLocalization.text("remove", fallback: "Remove")) {
                            removeAppliedVoucher()
                        }
                        .font(bodyFont(size: 12))
                        .foregroundColor(readableBrandGoldColor)
                    }
                }

                if customerProfile != nil {
                    Button {
                        isCartRewardsPresented = true
                    } label: {
                        Label(AppLocalization.text("view_rewards", fallback: "View available rewards"), systemImage: "sparkles")
                            .font(bodyFont(size: 12))
                            .foregroundColor(readableBrandGoldColor)
                    }
                    .buttonStyle(.plain)
                }

                if let voucherError {
                    Text(voucherError)
                        .font(bodyFont(size: 12))
                        .foregroundColor(.red.opacity(0.85))
                }
            }
        }
    }

    var checkoutView: some View {
        NavigationStack {
            GeometryReader { _ in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        SecurityReassurance(
                            text: AppLocalization.text(
                                "payment_encrypted_secure",
                                fallback: "Your payment is encrypted and processed securely."
                            ),
                            accentColor: TallaTheme.Colors.accent,
                            textColor: secondaryTextColor
                        )

                        if let payments = remoteAppSettings?.payments {
                            let notice = isArabicInterface ? payments.noticeAR : payments.noticeEN
                            if !notice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Label(notice, systemImage: "info.circle.fill")
                                    .font(bodyFont(size: 13))
                                    .foregroundColor(secondaryTextColor)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(cardFillColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        if !isDigitalGiftCardOnlyCart && !isCafePassActive {
                            cartFulfillmentMethodSection
                            checkoutDestinationSection
                        }
                        if isCoffeeClubActive && coffeeClubPlanType == "office" {
                            officeCoffeeDetailsSection
                        }
                        cartPaymentMethodsSection
                        cartOrderSummarySection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
                .background(pageBackgroundColor.ignoresSafeArea())
                .navigationTitle(AppLocalization.text("checkout", fallback: "Checkout"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isCheckoutPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                cartOpen = true
                            }
                        } label: {
                            Label(
                                AppLocalization.text("your_cart", fallback: "Bag"),
                                systemImage: appLanguage.layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left"
                            )
                            .font(bodyFont(size: 13))
                            .foregroundColor(readableBrandGoldColor)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    // Keep the payment action reachable after rotation. SwiftUI
                    // automatically shortens the ScrollView above this inset.
                    cartFooterContent
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
        .accessibilityIdentifier("checkout.screen")
        .sheet(isPresented: $isPaymentMethodSheetPresented) {
            PaymentMethodSelectionSheet(
                selectedMethod: paymentFlow.selectedMethod,
                applePayAvailable: isApplePaySupported,
                gatewaySDKAvailable: MastercardSDKAvailability.isAvailable,
                availability: paymentAvailability,
                disabledMethods: (isCoffeeClubActive || isCafePassActive || cartItems.contains(where: { $0.product.isGiftCardProduct })) ? [.cashOnDelivery] : [],
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor,
                accentColor: TallaTheme.Colors.accent,
                surfaceColor: elevatedSurfaceColor
            ) { method in
                guard !((isCoffeeClubActive || isCafePassActive || cartItems.contains(where: { $0.product.isGiftCardProduct })) && method == .cashOnDelivery) else { return }
                paymentFlow.select(method)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isCheckoutAddressSheetPresented) {
            checkoutAddressSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    var officeCoffeeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Business order details", systemImage: "building.2.fill")
                .font(labelFont(size: 14, weight: .bold))
                .foregroundColor(primaryTextColor)
            Text("Prepaid now for all plan shipments. These details will be attached to your order for business records; this plan does not renew automatically.")
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
            TextField("Company legal name (required)", text: $officeCompanyName)
                .textContentType(.organizationName)
                .textFieldStyle(.talla)
            TextField("VAT registration number (optional)", text: $officeVATNumber)
                .textFieldStyle(.talla)
            TextField("Commercial registration number (optional)", text: $officeCommercialRegistrationNumber)
                .textFieldStyle(.talla)
            TextField("Purchase order reference (optional)", text: $officePurchaseOrderReference)
                .textFieldStyle(.talla)
        }
        .padding(14)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var checkoutDestinationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(fulfillmentMethod == .pickup
                ? AppLocalization.text("pickup_location", fallback: "Pickup location")
                : AppLocalization.text("delivery_address", fallback: "Delivery address"))
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

            if fulfillmentMethod == .pickup {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(managedPickupName)
                            .font(.body.weight(.semibold))
                            .foregroundColor(primaryTextColor)
                        Text(managedPickupAddress)
                            .font(.footnote)
                            .foregroundColor(secondaryTextColor)
                    }
                } icon: {
                    Image(systemName: "storefront.fill")
                        .foregroundColor(readableBrandGoldColor)
                }
            } else if let address = preferredAddress {
                Button {
                    isCheckoutAddressSheetPresented = true
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(readableBrandGoldColor)
                            .frame(width: 36, height: 36)
                            .background(TallaTheme.Colors.accent.opacity(0.10))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(address.label)
                                .font(.body.weight(.semibold))
                                .foregroundColor(primaryTextColor)
                            Text("\(address.line1), \(address.city), \(address.country.name)")
                                .font(.footnote)
                                .foregroundColor(secondaryTextColor)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 8)

                        Text(AppLocalization.text("change", fallback: "Change"))
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(readableBrandGoldColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(TallaTheme.Colors.accent.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(AppLocalization.text("choose_delivery_address", fallback: "Choose delivery address"))
            } else if customerProfile != nil {
                Button {
                    isCheckoutAddressSheetPresented = true
                } label: {
                    Label(AppLocalization.text("add_delivery_address", fallback: "Add delivery address"), systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundColor(readableBrandGoldColor)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    isCheckoutPresented = false
                    openAccountSection(AccountSectionView.ScrollTarget.library)
                } label: {
                    Label(AppLocalization.text("sign_in_before_checkout", fallback: "Sign in to add a delivery address"), systemImage: "person.crop.circle")
                        .font(.body.weight(.semibold))
                        .foregroundColor(readableBrandGoldColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var checkoutAddressSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if !addresses.isEmpty {
                        HStack {
                            Text(AppLocalization.text("choose_delivery_address", fallback: "Choose a saved address"))
                                .font(.headline)
                                .foregroundColor(primaryTextColor)
                            Spacer()
                            Text("\(addresses.count)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(readableBrandGoldColor)
                        }

                        ForEach(addresses) { address in
                            Button {
                                Task {
                                    if await makePreferredAddress(address) {
                                        isCheckoutAddressSheetPresented = false
                                    }
                                }
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    if selectingAddressID == address.id {
                                        ProgressView()
                                            .tint(readableBrandGoldColor)
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: address.id == preferredAddress?.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(readableBrandGoldColor)
                                            .frame(width: 24, height: 24)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(address.label)
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(primaryTextColor)
                                        Text("\(address.line1), \(address.city), \(address.country.name)")
                                            .font(.footnote)
                                            .foregroundColor(secondaryTextColor)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                                .background(
                                    address.id == preferredAddress?.id
                                        ? TallaTheme.Colors.accent.opacity(0.08)
                                        : cardFillColor,
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            TallaTheme.Colors.accent.opacity(address.id == preferredAddress?.id ? 0.32 : 0.12),
                                            lineWidth: 1
                                        )
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(selectingAddressID != nil)
                            .accessibilityLabel("\(address.label), \(address.city), \(address.country.name)")
                            .accessibilityHint(AppLocalization.text("use_this_address", fallback: "Use this address"))
                        }

                        Divider().overlay(TallaTheme.Colors.accent.opacity(0.16))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label(AppLocalization.text("add_delivery_address", fallback: "Add a new address"), systemImage: "location.badge.plus")
                            .font(.headline)
                            .foregroundColor(primaryTextColor)

                        addressFormTextField(AppLocalization.text("label", fallback: "Label"), text: $addressLabel, capitalization: .words)
                        addressFormTextField(AppLocalization.text("full_name", fallback: "Full name"), text: $addressFullName, capitalization: .words)

                        HStack(spacing: 8) {
                            if !addressCountry.phonePrefix.isEmpty {
                                Text(addressCountry.phonePrefix)
                                    .font(labelFont(size: 12, weight: .bold))
                                    .foregroundColor(readableBrandGoldColor)
                                    .frame(minWidth: 42, alignment: .leading)
                            }
                            TextField(
                                addressCountry.phonePrefix.isEmpty
                                    ? AppLocalization.text("phone_with_country_code", fallback: "Phone with +country code")
                                    : AppLocalization.text("phone", fallback: "Phone"),
                                text: $addressPhone
                            )
                            .keyboardType(.phonePad)
                            .font(bodyFont(size: 14))
                            .foregroundColor(primaryTextColor)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 52)
                        .background(cardFillColor)
                        .overlay(addressFieldBorder)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        addressFormTextField(AppLocalization.text("address_line", fallback: "Address line"), text: $addressLine1, capitalization: .words)
                        deliveryCountrySelector

                        addressFormTextField(AppLocalization.text("city", fallback: "City"), text: $addressCity, capitalization: .words)
                        addressFormTextField(AppLocalization.text("notes", fallback: "Delivery notes (optional)"), text: $addressNotes, capitalization: .sentences)
                    }
                    .padding(16)
                    .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.045 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(TallaTheme.Colors.accent.opacity(0.16), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button {
                        Task {
                            let addressCount = addresses.count
                            await saveAddress()
                            if addresses.count > addressCount {
                                isCheckoutAddressSheetPresented = false
                            }
                        }
                    } label: {
                        HStack(spacing: 9) {
                            if isSavingAddress {
                                ProgressView()
                                    .tint(Color(hex: 0x0A0804))
                            }
                            Text(isSavingAddress
                                ? AppLocalization.text("saving", fallback: "Saving…")
                                : AppLocalization.text("save_address", fallback: "Save address"))
                                .font(.headline)
                        }
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(TallaTheme.Colors.accent, in: Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingAddress)
                    .opacity(isSavingAddress ? 0.72 : 1)
                }
                .padding(18)
            }
            .background(pageBackgroundColor.ignoresSafeArea())
            .navigationTitle(AppLocalization.text("delivery_address", fallback: "Delivery address"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("cancel", fallback: "Cancel")) {
                        isCheckoutAddressSheetPresented = false
                    }
                }
            }
        }
    }

    var postPaymentOrder: AccountOrder? {
        if !postPaymentOrderID.isEmpty,
           let matchingOrder = orderHistory.first(where: { $0.id == postPaymentOrderID }) {
            return matchingOrder
        }

        guard paymentFlow.state == .succeeded else { return nil }
        return orderHistory.max { orderDate(from: $0.createdAt) < orderDate(from: $1.createdAt) }
    }

    var postPaymentOrderNumber: String? {
        let source = postPaymentOrder?.title ?? postPaymentOrderID
        guard !source.isEmpty else { return nil }
        let digits = source.filter(\.isNumber)
        let identifier = digits.isEmpty ? String(source.suffix(8)) : String(digits.suffix(8))
        return String(format: AppLocalization.text("order_number_format", fallback: "Order #%@"), identifier)
    }

    var postPaymentCoffeeGiftURL: URL? {
        guard let order = postPaymentOrder,
              order.isPaidForCafePass,
              let pass = order.details?.cafePass,
              pass.giftedCoffee == true,
              pass.status == "active",
              pass.remainingCredits > 0,
              let token = pass.giftToken,
              token.range(of: "^[a-fA-F0-9]{64}$", options: .regularExpression) != nil else { return nil }
        var components = URLComponents(string: "https://talla.me/pages/coffee-gift")
        components?.queryItems = [URLQueryItem(name: "order", value: order.id)]
        components?.fragment = token
        return components?.url
    }

    var postPaymentCoffeeGiftWhatsAppURL: URL? {
        guard let giftURL = postPaymentCoffeeGiftURL else { return nil }
        var components = URLComponents(string: "https://wa.me/")
        components?.queryItems = [URLQueryItem(name: "text", value: "I sent you a coffee from Talla ☕️ Show staff the gift code in this link: \(giftURL.absoluteString)")]
        return components?.url
    }

    var postPaymentView: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 18)

                    postPaymentStatusHero

                    if paymentFlow.state == .succeeded {
                        postPaymentReceiptCard
                    }

                    postPaymentActions
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
            .background(pageBackgroundColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismissPostPayment()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 34, height: 34)
                            .background(cardFillColor, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
                }
            }
        }
        .interactiveDismissDisabled(paymentFlow.state.isBusy)
    }

    @ViewBuilder
    var postPaymentStatusHero: some View {
        VStack(spacing: 16) {
            if paymentFlow.state == .succeeded {
                ZStack {
                    Circle()
                        .fill(TallaTheme.Colors.accent.opacity(0.13))
                        .frame(width: 104, height: 104)
                    Circle()
                        .stroke(TallaTheme.Colors.accent.opacity(0.28), lineWidth: 1)
                        .frame(width: 84, height: 84)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(TallaTheme.Colors.accent)
                }
                .accessibilityHidden(true)

                Text(AppLocalization.text("order_confirmed", fallback: "Order confirmed"))
                    .font(displayFont(size: 34))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("checkout.result")

                Text(customerProfile.map {
                    String(format: AppLocalization.text("thank_you_name", fallback: "Thank you, %@."), $0.displayName)
                } ?? AppLocalization.text("thank_you_order", fallback: "Thank you for your order."))
                    .font(bodyFont(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
            } else if paymentFlow.state == .failed || paymentFlow.state == .cancelled {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.09))
                        .frame(width: 96, height: 96)
                    Image(systemName: paymentFlow.state == .cancelled ? "xmark" : "exclamationmark")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.red.opacity(0.82))
                }
                .accessibilityHidden(true)

                Text(paymentFlow.state == .cancelled
                    ? AppLocalization.text("payment_cancelled_title", fallback: "Payment cancelled")
                    : AppLocalization.text("payment_failed_title", fallback: "Payment unsuccessful"))
                    .font(displayFont(size: 32))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)

                Text(paymentFlow.errorMessage
                    ?? AppLocalization.text("payment_failed_detail", fallback: "No order was placed. You can try again or choose another payment method."))
                    .font(bodyFont(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ZStack {
                    Circle()
                        .fill(TallaTheme.Colors.accent.opacity(0.12))
                        .frame(width: 96, height: 96)
                    ProgressView()
                        .controlSize(.large)
                        .tint(TallaTheme.Colors.accent)
                }

                Text(AppLocalization.text("confirming_payment", fallback: "Confirming your payment"))
                    .font(displayFont(size: 32))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)

                Text(AppLocalization.text(
                    "confirming_payment_detail",
                    fallback: "This usually takes only a moment. You can safely close this page while verification continues."
                ))
                .font(bodyFont(size: 15))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var postPaymentReceiptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let postPaymentOrderNumber {
                Text(postPaymentOrderNumber)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
            }

            Divider().overlay(TallaTheme.Colors.accent.opacity(0.16))

            if !postPaymentFulfillmentTitle.isEmpty {
                postPaymentReceiptRow(
                    title: postPaymentFulfillmentTitle,
                    value: postPaymentDestination,
                    systemImage: fulfillmentMethod == .pickup ? "storefront.fill" : "mappin.and.ellipse"
                )
            }

            postPaymentReceiptRow(
                title: AppLocalization.text("payment_method", fallback: "Payment"),
                value: postPaymentMethodTitle,
                systemImage: "wallet.bifold"
            )

            HStack(alignment: .firstTextBaseline) {
                Text(AppLocalization.text("total", fallback: "Total"))
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                Spacer()
                Text(postPaymentOrder?.total ?? postPaymentTotal)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                    .monospacedDigit()
            }

            if let points = postPaymentOrder?.pointsAwarded, points > 0 {
                Divider().overlay(TallaTheme.Colors.accent.opacity(0.16))
                Label {
                    Text(String(format: AppLocalization.text("beans_earned_format", fallback: "+%d Beans earned"), points))
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "sparkles")
                }
                .foregroundColor(readableBrandGoldColor)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.09), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    func postPaymentReceiptRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(readableBrandGoldColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(secondaryTextColor)
                if !value.isEmpty {
                    Text(value)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    var postPaymentActions: some View {
        VStack(spacing: 11) {
            if paymentFlow.state == .succeeded {
                if let giftURL = postPaymentCoffeeGiftURL {
                    ShareLink(item: giftURL, subject: Text("A coffee from Talla"), message: Text("Your paid coffee gift is ready to share ☕️")) {
                        Label("Share paid coffee gift", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TallaTheme.Colors.accent)
                    if let whatsAppURL = postPaymentCoffeeGiftWhatsAppURL {
                        Button { openURL(whatsAppURL) } label: {
                            Label("Send gift on WhatsApp", systemImage: "message.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .tint(TallaTheme.Colors.accent)
                    }
                }
                Button {
                    dismissPostPayment(openOrders: true)
                } label: {
                    Text(AppLocalization.text("track_order", fallback: "Track order"))
                        .font(.headline)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(TallaTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    dismissPostPayment(openShop: true)
                } label: {
                    Text(AppLocalization.text("continue_shopping", fallback: "Continue shopping"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(primaryTextColor)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.plain)
            } else if paymentFlow.state == .failed || paymentFlow.state == .cancelled {
                Button {
                    retryPostPayment()
                } label: {
                    Text(AppLocalization.text("retry_payment", fallback: "Try payment again"))
                        .font(.headline)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(TallaTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(AppLocalization.text("close", fallback: "Close")) {
                    dismissPostPayment()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(secondaryTextColor)
            } else {
                Button(AppLocalization.text("close_for_now", fallback: "Close for now")) {
                    isPostPaymentPresented = false
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(secondaryTextColor)
            }
        }
    }

    var cartFulfillmentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("fulfillment_method", fallback: "How would you like your order?"))
                .font(labelFont(size: 10, weight: .bold))
                .tracking(AppLocalization.letterSpacing(1.3))
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

            HStack(spacing: 8) {
                if !cartRequiresPickup && remoteAppSettings?.fulfillment?.deliveryEnabled != false {
                    fulfillmentMethodButton(
                        .delivery,
                        title: AppLocalization.text("delivery", fallback: "Delivery"),
                        systemImage: "truck.box.fill"
                    )
                }
                if remoteAppSettings?.fulfillment?.pickupEnabled != false && !pickupTemporarilyClosed {
                    fulfillmentMethodButton(
                        .pickup,
                        title: AppLocalization.text("pickup", fallback: "Pickup"),
                        systemImage: "storefront.fill"
                    )
                }
            }

            if cartRequiresPickup {
                Text(AppLocalization.text("pickup_only_drinks_desserts", fallback: "Drinks and desserts are available for pickup only."))
                    .font(bodyFont(size: 11))
                    .foregroundColor(tertiaryTextColor)
            }

            if fulfillmentMethod == .pickup {
                if let pickupClosureMessage {
                    Label(pickupClosureMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(bodyFont(size: 12))
                        .foregroundColor(.orange)
                }
                if let locations = remoteAppSettings?.fulfillment?.locations, !locations.isEmpty {
                    Picker(AppLocalization.text("pickup_location", fallback: "Pickup location"), selection: $selectedPickupLocationID) {
                        ForEach(locations) { location in
                            Text(isArabicInterface ? location.nameAR : location.nameEN).tag(location.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Label(
                    managedPickupAddress,
                    systemImage: "mappin.and.ellipse"
                )
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)

                Picker(AppLocalization.text("pickup_time", fallback: "Pickup time"), selection: $selectedPickupSlot) {
                    ForEach(pickupTimeSlots, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)

                Text(AppLocalization.text("pickup_time_detail", fallback: "We will prepare your order for this collection window."))
                    .font(bodyFont(size: 11))
                    .foregroundColor(tertiaryTextColor)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func fulfillmentMethodButton(
        _ method: TallaFulfillmentMethod,
        title: String,
        systemImage: String
    ) -> some View {
        let isSelected = fulfillmentMethod == method
        return Button {
            fulfillmentMethod = method
            checkoutError = nil
        } label: {
            Label(title, systemImage: systemImage)
                .font(labelFont(size: 11, weight: .bold))
                .foregroundStyle(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    isSelected ? TallaTheme.Colors.accent : cardFillColor,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isSelected ? 0 : 0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    var cartOrderingGuideSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCheckoutNoteExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(AppLocalization.text("how_checkout_works", fallback: "How checkout works"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(1.6))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                    Spacer()

                    Image(systemName: isCheckoutNoteExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(readableBrandGoldColor)
                }
            }
            .buttonStyle(.plain)

            if isCheckoutNoteExpanded {
                Text(AppLocalization.text("checkout_note_detail", fallback: "Payment is completed securely through Shopify. Return to Talla afterwards to track your order and receive Beans."))
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var cartBagFooterContent: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(AppLocalization.text("subtotal", fallback: "Subtotal"))
                    .font(.footnote)
                    .foregroundColor(secondaryTextColor)

                Spacer()

                Text(formattedCustomerCurrency(cartSubtotal))
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                    .monospacedDigit()
            }

            if isCoffeeClubActive {
                HStack(alignment: .firstTextBaseline) {
                    Text(AppLocalization.text("coffee_club_saving", fallback: "Coffee Club saving"))
                        .font(.footnote)
                        .foregroundColor(secondaryTextColor)
                    Spacer()
                        Text("-\(formattedCustomerCurrency(coffeeClubDiscount))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(readableBrandGoldColor)
                        .monospacedDigit()
                }
            }

            Button(action: prepareCheckout) {
                HStack {
                    Text(AppLocalization.text("checkout", fallback: "Checkout"))
                        .font(.headline)
                    Spacer()
                        Text(formattedCustomerCurrency(max(cartSubtotal - cartDiscount, 0)))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundColor(Color(hex: 0x0A0804))
                .padding(.horizontal, 17)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(TallaTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(cartItems.isEmpty)
        }
    }

    var cartFooterContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let checkoutError {
                Text(checkoutError)
                    .font(bodyFont(size: 13))
                    .foregroundColor(Color.red.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !isDigitalGiftCardOnlyCart && fulfillmentMethod == .delivery && preferredAddress == nil {
                Button {
                    checkoutError = nil
                    if customerProfile == nil {
                        isCheckoutPresented = false
                        openAccountSection(AccountSectionView.ScrollTarget.library)
                    } else {
                        isCheckoutAddressSheetPresented = true
                    }
                } label: {
                    HStack {
                        Text(AppLocalization.text("add_address_to_continue", fallback: "Add address to continue"))
                            .font(.headline)
                        Spacer()
                        Image(systemName: appLanguage.layoutDirection == .rightToLeft ? "arrow.left" : "arrow.right")
                    }
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .padding(.horizontal, 17)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(TallaTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("add_address_to_continue", fallback: "Add address to continue"))
            } else {
                CheckoutActionBar(
                    method: paymentFlow.selectedMethod,
                    amountText: cartCheckoutAmountText,
                    state: paymentFlow.state,
                    enabled: !cartItems.isEmpty && !isCheckingOut && paymentFlow.canStart && canStartCheckoutWithShipping,
                    applePayAvailable: isApplePayAvailable,
                    accentColor: TallaTheme.Colors.accent,
                    hostedCheckoutTitle: cartItems.contains(where: { $0.product.isGiftCardProduct })
                        ? (isArabicInterface ? "المتابعة إلى دفع Shopify" : "Continue to Shopify Checkout")
                        : nil
                ) {
                    checkoutError = nil
                    Task {
                        await beginCheckout()
                    }
                }
            }
        }
    }

    var cartOrderSummarySection: some View {
        let itemKey = cartCount == 1 ? "cart_item_count_singular" : "cart_item_count_plural"
        let itemFallback = cartCount == 1 ? "%d item" : "%d items"
        let thumbnail: AnyView = {
            if let firstItem = cartItems.first {
                return AnyView(ProductThumbnail(imageURL: firstItem.product.imageURL, size: 44, cornerRadius: 10))
            }
            return AnyView(
                Image(systemName: "bag.fill")
                    .foregroundStyle(TallaTheme.Colors.accent)
                    .frame(width: 44, height: 44)
                    .background(TallaTheme.Colors.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            )
        }()
        return CompactOrderSummary(
            thumbnail: thumbnail,
            itemCountText: String(format: AppLocalization.text(itemKey, fallback: itemFallback), cartCount),
            rows: cartOrderSummaryRows,
            primaryColor: primaryTextColor,
            secondaryColor: secondaryTextColor,
            accentColor: TallaTheme.Colors.accent,
            surfaceColor: cardFillColor
        )
    }

    var cartPaymentMethodsSection: some View {
        VStack(spacing: 10) {
            if cartItems.contains(where: { $0.product.isGiftCardProduct }) {
                Label(
                    isArabicInterface
                        ? "اختر طريقة الدفع المتاحة في صفحة دفع Shopify الآمنة. بطاقات الهدايا لا تدعم الدفع عند الاستلام."
                        : "Choose an available online payment method in secure Shopify Checkout. Cash on delivery is unavailable for gift cards.",
                    systemImage: "lock.shield.fill"
                )
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                CompactPaymentMethodRow(
                selectedMethod: paymentFlow.selectedMethod,
                enabled: paymentFlow.canChangeMethod,
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor,
                accentColor: TallaTheme.Colors.accent,
                surfaceColor: cardFillColor
            ) {
                isPaymentMethodSheetPresented = true
            }
            }

            if usesShopifyCalculatedShipping {
                Text(AppLocalization.text(
                    "international_checkout_payment_hint",
                    fallback: "For destinations outside the GCC, choose Cash on Delivery to continue to Shopify Checkout. Shopify will show the shipping rate and payment methods available for your country."
                ))
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            }

            if isCoffeeClubActive {
                Label(
                    AppLocalization.text(
                        "coffee_club_payment_note",
                        fallback: "This is one prepaid purchase, not an automatic renewal. Cash on Delivery is unavailable."
                    ),
                    systemImage: "checkmark.shield.fill"
                )
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            }

            PaymentStatusView(
                state: paymentFlow.state,
                accentColor: TallaTheme.Colors.accent,
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor
            )
        }
    }

    func paymentMethodChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))

            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .tracking(AppLocalization.letterSpacing(1))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundColor(primaryTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(elevatedSurfaceColor)
        .overlay(
            Capsule(style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
        )
        .clipShape(Capsule(style: .continuous))
        .accessibilityValue(AppLocalization.text("available_in_secure_checkout", fallback: "Available in secure checkout"))
    }

    var cartItemsListSection: some View {
        ForEach($cartItems) { $item in
            HStack(alignment: .center, spacing: 10) {
                ProductThumbnail(imageURL: item.product.imageURL, size: 44, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)

                    if let variantTitle = cartVariantDisplayTitle(for: item) {
                        Text(variantTitle)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text(displayedProductPrice(item.variant.price))
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(readableBrandGoldColor)
                }

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        if item.quantity > 1 {
                            item.quantity -= 1
                            checkoutError = nil
                        } else {
                            requestRemoveFromCart(id: item.id)
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("decrease_quantity", fallback: "Decrease quantity"))

                    Text("\(item.quantity)")
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 28, height: 36)
                        .accessibilityLabel("\(AppLocalization.text("quantity", fallback: "Quantity")) \(item.quantity)")

                    Button {
                        item.quantity += 1
                        checkoutError = nil
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isCafePassActive)
                    .accessibilityLabel(AppLocalization.text("increase_quantity", fallback: "Increase quantity"))
                }
                .foregroundColor(readableBrandGoldColor)
                .background(cardFillColor)
                .overlay(
                    Capsule()
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.18 : 0.1), lineWidth: 1)
                )
                .clipShape(Capsule())

                Button {
                    requestRemoveFromCart(id: item.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(TallaTheme.Colors.accent.opacity(0.2), lineWidth: 1)
                        )
                        .foregroundColor(TallaTheme.Colors.accent.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            .overlay(
                Rectangle()
                    .fill(TallaTheme.Colors.accent.opacity(0.08))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }

    var cartRewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("rewards_voucher", fallback: "Rewards & Vouchers"))
                .font(labelFont(size: 11, weight: .bold))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

            Text(AppLocalization.text("rewards_voucher_detail", fallback: "Apply a reward before opening checkout, or continue without one."))
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isVoucherCodeEntryExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(AppLocalization.text("add_voucher_discount_code", fallback: "Add voucher or discount code"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(1.4))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                    Spacer()

                    Image(systemName: isVoucherCodeEntryExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(readableBrandGoldColor)
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            if isVoucherCodeEntryExpanded {
                HStack(spacing: 10) {
                    TextField(AppLocalization.text("enter_voucher_code", fallback: "Enter voucher code"), text: $voucherCodeInput)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button {
                        Task {
                            await applyVoucher()
                        }
                    } label: {
                        Text(isApplyingVoucher ? "..." : AppLocalization.text("apply", fallback: "Apply"))
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(1.5))
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(TallaTheme.Colors.accent)
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isApplyingVoucher || voucherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let appliedVoucher {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(appliedVoucher.code)
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(1.2))
                            .foregroundColor(readableBrandGoldColor)

                        Spacer()

                        Button(AppLocalization.text("remove", fallback: "Remove")) {
                            removeAppliedVoucher()
                        }
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .buttonStyle(.plain)
                    }

                    Text(formattedVoucherDetail(for: appliedVoucher))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                        Text(String(format: AppLocalization.text("discount_expires", fallback: "Discount: %@ • Expires %@"), formattedCustomerCurrency(cartDiscount), appliedVoucher.expiresAt.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "")))
                        .font(bodyFont(size: 12))
                        .foregroundColor(tertiaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if let voucherError {
                Text(voucherError)
                    .font(bodyFont(size: 12))
                    .foregroundColor(Color.red.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let profile = customerProfile {
                VStack(alignment: .leading, spacing: 10) {
                    if availableVouchers.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "ticket")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(readableBrandGoldColor)
                                .frame(width: 20, height: 20)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text(AppLocalization.text("no_active_vouchers", fallback: "No active vouchers"))
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(AppLocalization.letterSpacing(1.2))
                                        .textCase(.uppercase)
                                        .foregroundColor(primaryTextColor)

                                    if isLoadingAvailableVouchers {
                                        ProgressView()
                                            .scaleEffect(0.75)
                                            .tint(TallaTheme.Colors.accent)
                                    }
                                }

                                Text(AppLocalization.text("active_vouchers_empty", fallback: "Redeem Beans in The Talla Club to unlock one."))
                                    .font(bodyFont(size: 12))
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button {
                                    isCartRewardsPresented = true
                                    Task {
                                        await loadLoyaltyAccount()
                                    }
                                } label: {
                                    Label(AppLocalization.text("view_rewards", fallback: "View Rewards"), systemImage: appLanguage.layoutDirection == .rightToLeft ? "arrow.left" : "arrow.right")
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(AppLocalization.letterSpacing(1.3))
                                        .textCase(.uppercase)
                                        .foregroundColor(readableBrandGoldColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        HStack {
                            Text(AppLocalization.text("your_active_vouchers", fallback: "Your Active Vouchers"))
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(AppLocalization.letterSpacing(1.6))
                                .textCase(.uppercase)
                                .foregroundColor(readableBrandGoldColor)

                            Spacer()

                            if isLoadingAvailableVouchers {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(TallaTheme.Colors.accent)
                            }
                        }

                        ForEach(availableVouchers.prefix(3)) { voucher in
                            Button {
                                voucherCodeInput = voucher.code
                                Task {
                                    await applyVoucher()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(voucher.code)
                                            .font(labelFont(size: 10, weight: .bold))
                                            .tracking(AppLocalization.letterSpacing(1.2))
                                            .foregroundColor(readableBrandGoldColor)

                                        Spacer()

                                        Text(formattedDiscountLabel(for: voucher))
                                            .font(bodyFont(size: 11))
                                            .foregroundColor(primaryTextColor)
                                    }

                                    Text(voucher.detail)
                                        .font(bodyFont(size: 12))
                                        .foregroundColor(secondaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(cardFillColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .task(id: profile.email + String(cartOpen)) {
                    guard cartOpen else { return }
                    await loadAvailableVouchers(for: profile.email)
                }
            }
        }
    }

    var cartSaveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCartSaveEntryExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Label(AppLocalization.text("save_cart_later", fallback: "Save this bag for later"), systemImage: "bookmark")
                        .font(labelFont(size: 12, weight: .semibold))
                        .foregroundColor(primaryTextColor)

                    Spacer()

                    Image(systemName: isCartSaveEntryExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(readableBrandGoldColor)
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            if isCartSaveEntryExpanded {
                HStack(spacing: 10) {
                    TextField(AppLocalization.text("save_cart_placeholder", fallback: "Weekend beans, gifting run, office order..."), text: $cartSaveName)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button {
                        saveCurrentCart()
                    } label: {
                        Text(AppLocalization.text("save", fallback: "Save"))
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(1.5))
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(TallaTheme.Colors.accent)
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(TallaTheme.Colors.accent)

            Text(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
                .font(.system(size: 12, weight: .medium))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    var homeSurprisePickSkeleton: some View {
        HStack(alignment: .center, spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(skeletonFillColor)
                .frame(width: isCompact ? 82 : 96, height: isCompact ? 82 : 96)

            VStack(alignment: .leading, spacing: 9) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(skeletonFillColor)
                    .frame(width: 92, height: 10)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(skeletonFillColor)
                    .frame(height: 20)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(skeletonFillColor)
                    .frame(width: 130, height: 20)

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(skeletonFillColor)
                        .frame(width: 72, height: 34)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(skeletonFillColor)
                        .frame(width: 94, height: 34)
                }
            }
        }
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
        .accessibilityLabel(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
    }

    func productSkeletonGrid(count: Int) -> some View {
        LazyVGrid(columns: productGridColumns, spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                productSkeletonCard
            }
        }
        .accessibilityLabel(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
    }

    var productSkeletonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(skeletonFillColor)
                .frame(height: 184)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(skeletonFillColor)
                .frame(width: 92, height: 10)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(skeletonFillColor)
                .frame(height: 22)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(skeletonFillColor)
                .frame(width: 150, height: 22)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(skeletonFillColor)
                .frame(width: 78, height: 14)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(skeletonFillColor)
                .frame(height: 38)
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    var skeletonFillColor: Color {
        isLightAppearance ? TallaTheme.Colors.accent.opacity(0.13) : Color.white.opacity(0.08)
    }

    var emptySection: some View {
        VStack(spacing: 12) {
            Text(AppLocalization.text("no_products", fallback: "No products match this category right now."))
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(secondaryTextColor)

            Button {
                activeCategory = "all"
            } label: {
                Text(AppLocalization.text("show_all_products", fallback: "Show All Products"))
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(AppLocalization.letterSpacing(3))
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(TallaTheme.Colors.accent)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    func errorSection(message: String) -> some View {
        VStack(spacing: 14) {
            Text(AppLocalization.text("shop_load_failed", fallback: "We couldn’t load the shop."))
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(primaryTextColor)

            Text(message)
                .font(.system(size: 12, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(secondaryTextColor)

            Button {
                Task {
                    await loadProducts(force: true)
                }
            } label: {
                Text(AppLocalization.text("retry", fallback: "Retry"))
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(AppLocalization.letterSpacing(3))
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(TallaTheme.Colors.accent)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

}
