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
    var cartDrawer: some View {
        CartDrawerView(
            scrimColor: scrimColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            elevatedSurfaceColor: elevatedSurfaceColor,
            accentColor: Color(hex: 0xC8965A),
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
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var cartReviewContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            cartItemsListSection
            cartPromoSection
        }
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
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
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
                            .background(Color(hex: 0xC8965A), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    SecurityReassurance(
                        text: AppLocalization.text(
                            "payment_encrypted_secure",
                            fallback: "Your payment is encrypted and processed securely."
                        ),
                        accentColor: Color(hex: 0xC8965A),
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

                    cartFulfillmentMethodSection
                    checkoutDestinationSection
                    cartPaymentMethodsSection
                    cartOrderSummarySection
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 24)
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
                cartFooterContent
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $isPaymentMethodSheetPresented) {
            PaymentMethodSelectionSheet(
                selectedMethod: paymentFlow.selectedMethod,
                applePayAvailable: isApplePaySupported,
                gatewaySDKAvailable: MastercardSDKAvailability.isAvailable,
                availability: paymentAvailability,
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor,
                accentColor: Color(hex: 0xC8965A),
                surfaceColor: elevatedSurfaceColor
            ) { method in
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
                            .background(Color(hex: 0xC8965A).opacity(0.10))
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
                            .background(Color(hex: 0xC8965A).opacity(0.10))
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
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
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
                                        ? Color(hex: 0xC8965A).opacity(0.08)
                                        : cardFillColor,
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            Color(hex: 0xC8965A).opacity(address.id == preferredAddress?.id ? 0.32 : 0.12),
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

                        Divider().overlay(Color(hex: 0xC8965A).opacity(0.16))
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
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.045 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(hex: 0xC8965A).opacity(0.16), lineWidth: 1)
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
                        .background(Color(hex: 0xC8965A), in: Capsule())
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
                        .fill(Color(hex: 0xC8965A).opacity(0.13))
                        .frame(width: 104, height: 104)
                    Circle()
                        .stroke(Color(hex: 0xC8965A).opacity(0.28), lineWidth: 1)
                        .frame(width: 84, height: 84)
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(Color(hex: 0xC8965A))
                }
                .accessibilityHidden(true)

                Text(AppLocalization.text("order_confirmed", fallback: "Order confirmed"))
                    .font(displayFont(size: 34))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)

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
                        .fill(Color(hex: 0xC8965A).opacity(0.12))
                        .frame(width: 96, height: 96)
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color(hex: 0xC8965A))
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

            Divider().overlay(Color(hex: 0xC8965A).opacity(0.16))

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
                Divider().overlay(Color(hex: 0xC8965A).opacity(0.16))
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
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.09), lineWidth: 1)
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
                Button {
                    dismissPostPayment(openOrders: true)
                } label: {
                    Text(AppLocalization.text("track_order", fallback: "Track order"))
                        .font(.headline)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(hex: 0xC8965A), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                        .background(Color(hex: 0xC8965A), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                .tracking(1.3)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

            HStack(spacing: 8) {
                if remoteAppSettings?.fulfillment?.deliveryEnabled != false {
                    fulfillmentMethodButton(
                        .delivery,
                        title: AppLocalization.text("delivery", fallback: "Delivery"),
                        systemImage: "truck.box.fill"
                    )
                }
                if remoteAppSettings?.fulfillment?.pickupEnabled != false {
                    fulfillmentMethodButton(
                        .pickup,
                        title: AppLocalization.text("pickup", fallback: "Pickup"),
                        systemImage: "storefront.fill"
                    )
                }
            }

            if fulfillmentMethod == .pickup {
                Label(
                    managedPickupAddress,
                    systemImage: "mappin.and.ellipse"
                )
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
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
                    isSelected ? Color(hex: 0xC8965A) : cardFillColor,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isSelected ? 0 : 0.22), lineWidth: 1)
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
                        .tracking(1.6)
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
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
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

                Text(formattedBHD(cartSubtotal))
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                    .monospacedDigit()
            }

            Button(action: prepareCheckout) {
                HStack {
                    Text(AppLocalization.text("checkout", fallback: "Checkout"))
                        .font(.headline)
                    Spacer()
                    Text(formattedBHD(cartSubtotal))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundColor(Color(hex: 0x0A0804))
                .padding(.horizontal, 17)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color(hex: 0xC8965A), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
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

            if fulfillmentMethod == .delivery && preferredAddress == nil {
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
                    .background(Color(hex: 0xC8965A), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
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
                    accentColor: Color(hex: 0xC8965A)
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
                    .foregroundStyle(Color(hex: 0xC8965A))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: 0xC8965A).opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            )
        }()
        return CompactOrderSummary(
            thumbnail: thumbnail,
            itemCountText: String(format: AppLocalization.text(itemKey, fallback: itemFallback), cartCount),
            rows: cartOrderSummaryRows,
            primaryColor: primaryTextColor,
            secondaryColor: secondaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            surfaceColor: cardFillColor
        )
    }

    var cartPaymentMethodsSection: some View {
        VStack(spacing: 10) {
            CompactPaymentMethodRow(
                selectedMethod: paymentFlow.selectedMethod,
                enabled: paymentFlow.canChangeMethod,
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor,
                accentColor: Color(hex: 0xC8965A),
                surfaceColor: cardFillColor
            ) {
                isPaymentMethodSheetPresented = true
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

            PaymentStatusView(
                state: paymentFlow.state,
                accentColor: Color(hex: 0xC8965A),
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
                .tracking(1)
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
                .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
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

                    Text(item.variant.price)
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
                    .accessibilityLabel(AppLocalization.text("increase_quantity", fallback: "Increase quantity"))
                }
                .foregroundColor(readableBrandGoldColor)
                .background(cardFillColor)
                .overlay(
                    Capsule()
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.18 : 0.1), lineWidth: 1)
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
                                .stroke(Color(hex: 0xC8965A).opacity(0.2), lineWidth: 1)
                        )
                        .foregroundColor(Color(hex: 0xC8965A).opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            .overlay(
                Rectangle()
                    .fill(Color(hex: 0xC8965A).opacity(0.08))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }

    var cartRewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("rewards_voucher", fallback: "Rewards & Vouchers"))
                .font(labelFont(size: 11, weight: .bold))
                .tracking(2)
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
                        .tracking(1.4)
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
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
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
                                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button {
                        Task {
                            await applyVoucher()
                        }
                    } label: {
                        Text(isApplyingVoucher ? "..." : AppLocalization.text("apply", fallback: "Apply"))
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(hex: 0xC8965A))
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
                            .tracking(1.2)
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

                    Text(String(format: AppLocalization.text("discount_expires", fallback: "Discount: %@ • Expires %@"), formattedBHD(cartDiscount), appliedVoucher.expiresAt.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "")))
                        .font(bodyFont(size: 12))
                        .foregroundColor(tertiaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
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
                                        .tracking(1.2)
                                        .textCase(.uppercase)
                                        .foregroundColor(primaryTextColor)

                                    if isLoadingAvailableVouchers {
                                        ProgressView()
                                            .scaleEffect(0.75)
                                            .tint(Color(hex: 0xC8965A))
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
                                        .tracking(1.3)
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
                                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        HStack {
                            Text(AppLocalization.text("your_active_vouchers", fallback: "Your Active Vouchers"))
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundColor(readableBrandGoldColor)

                            Spacer()

                            if isLoadingAvailableVouchers {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Color(hex: 0xC8965A))
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
                                            .tracking(1.2)
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
                                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
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
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
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
                                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button {
                        saveCurrentCart()
                    } label: {
                        Text(AppLocalization.text("save", fallback: "Save"))
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(hex: 0xC8965A))
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
                .tint(Color(hex: 0xC8965A))

            Text(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
                .font(.system(size: 12, weight: .medium))
                .tracking(2)
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
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    var skeletonFillColor: Color {
        isLightAppearance ? Color(hex: 0xC8965A).opacity(0.13) : Color.white.opacity(0.08)
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
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(hex: 0xC8965A))
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
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(hex: 0xC8965A))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    func productCard(product: Product, showDescription: Bool) -> some View {
        let tasteSummary = productTasteSummary(for: product)
        let cardMinimumHeight: CGFloat = showDescription ? (isCompact ? 340 : 360) : (isCompact ? 396 : 416)
        let shouldShowAlertButton = !product.isAvailableForSale || isAlertEnabled(product)

        return VStack(alignment: .leading, spacing: showDescription ? 8 : 10) {
            ZStack(alignment: .topTrailing) {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 10)
                    .frame(height: showDescription ? (isCompact ? 138 : 152) : (isCompact ? 176 : 184))

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(productBadges(for: product), id: \.self) { badge in
                        productBadge(badge)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)

                VStack(alignment: .trailing, spacing: 8) {
                    Button {
                        toggleFavorite(product: product)
                    } label: {
                        Image(systemName: isFavorite(product) ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isFavorite(product) ? Color(hex: 0xC8965A) : primaryTextColor)
                            .symbolEffect(.bounce, value: isFavorite(product))
                            .frame(width: 34, height: 34)
                            .background(cardFillColor.opacity(0.92))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavorite(product)
                        ? AppLocalization.text("remove_from_favorites", fallback: "Remove from favourites")
                        : AppLocalization.text("add_to_favorites", fallback: "Add to favourites"))

                    if shouldShowAlertButton {
                        Button {
                            Task {
                                await toggleAlert(product: product)
                            }
                        } label: {
                            Image(systemName: isAlertEnabled(product) ? "bell.fill" : "bell")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isAlertEnabled(product) ? Color(hex: 0xC8965A) : primaryTextColor)
                                .symbolEffect(.bounce, value: isAlertEnabled(product))
                                .frame(width: 34, height: 34)
                                .background(cardFillColor.opacity(0.92))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isAlertEnabled(product)
                            ? AppLocalization.text("remove_alert", fallback: "Remove alert")
                            : AppLocalization.text("notify_when_available", fallback: "Notify when available"))
                    }

                    if let tag = product.tag {
                        Text(tag)
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(Color(hex: 0xC8965A))
                            .foregroundColor(Color(hex: 0x0A0804))
                            .cornerRadius(2)
                            .frame(maxWidth: 86, alignment: .trailing)
                    }
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text(product.categoryLabel)
                        .font(labelFont(size: 10, weight: .semibold))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundColor(tertiaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer(minLength: 2)

                    if let countryOfOrigin = productCountryOfOrigin(for: product) {
                        Label(countryOfOrigin, systemImage: "globe.europe.africa.fill")
                            .font(labelFont(size: 9, weight: .semibold))
                            .foregroundColor(readableBrandGoldColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .accessibilityLabel("\(AppLocalization.text("country_of_origin", fallback: "Country of origin")): \(countryOfOrigin)")
                    }
                }
                .frame(height: 13, alignment: .leading)

                Text(product.name)
                    .font(titleFont(size: showDescription ? (isCompact ? 16 : 18) : (isCompact ? 18 : 20)))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .minimumScaleFactor(0.78)
                    .frame(height: showDescription ? 40 : 48, alignment: .topLeading)

                if showDescription {
                    Text(tasteSummary)
                        .font(bodyFont(size: isCompact ? 11 : 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, minHeight: 16, alignment: .leading)
                }
            }

            Spacer(minLength: 0)

            if !showDescription {
                if product.hasVariantChoices, let variant = selectedVariant(for: product) {
                    Text("\(AppLocalization.text("selected_variant", fallback: "Variant:")) \(variant.title)")
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                } else {
                    Text(" ")
                        .font(bodyFont(size: 12))
                        .lineLimit(1)
                        .frame(height: 20)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(product.price)
                    .font(labelFont(size: isCompact ? 14 : 15, weight: .bold))
                    .foregroundColor(product.isAvailableForSale ? Color(hex: 0xC8965A) : tertiaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 18, alignment: .leading)

                Button {
                    if product.hasVariantChoices {
                        recordRecentlyViewed(product)
                        selectedProduct = product
                    } else {
                        addToCart(product: product)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: product.hasVariantChoices ? "slider.horizontal.3" : "plus")
                            .font(.system(size: 11, weight: .bold))

                        Text(product.isAvailableForSale ? (product.hasVariantChoices ? AppLocalization.text("options", fallback: "Options") : AppLocalization.text("add", fallback: "Add")) : AppLocalization.text("sold_out", fallback: "Sold Out"))
                            .font(labelFont(size: isCompact ? 9 : 10, weight: .bold))
                            .tracking(isCompact ? 0.4 : 0.8)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 18)
                    .foregroundColor(product.isAvailableForSale ? Color(hex: 0x0A0804) : tertiaryTextColor)
                    .padding(.horizontal, isCompact ? 10 : 12)
                    .padding(.vertical, 10)
                    .glassEffect(
                        product.isAvailableForSale
                            ? .regular.tint(Color(hex: 0xC8965A)).interactive()
                            : .clear,
                        in: .capsule
                    )
                }
                .buttonStyle(.plain)
                .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)
            }
            .frame(maxWidth: .infinity, minHeight: showDescription ? 68 : 74, alignment: .bottom)
        }
        .padding(showDescription ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardFillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, minHeight: cardMinimumHeight, alignment: .topLeading)
        .hoverEffect(.lift)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture {
            recordRecentlyViewed(product)
            selectedProduct = product
        }
    }

    func signatureRoastCard(_ product: Product) -> some View {
        let notes = productTasteNotes(for: product)
        let compactCardWidth: CGFloat = 176

        return VStack(alignment: .leading, spacing: 7) {
            ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 14)
                .frame(maxWidth: .infinity)
                .frame(height: isCompact ? 122 : 146)

            VStack(alignment: .leading, spacing: 4) {
                Text(productOriginLabel(for: product))
                    .font(labelFont(size: 8, weight: .bold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(customerFacingProductName(for: product))
                    .font(titleFont(size: isCompact ? 15 : 16))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .minimumScaleFactor(0.78)
                    .frame(height: 38, alignment: .topLeading)

                HStack(spacing: 5) {
                    ForEach(notes.prefix(2), id: \.self) { note in
                        Text(note)
                            .font(labelFont(size: 8, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .foregroundColor(primaryTextColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 22, alignment: .leading)
            }

            HStack(spacing: 8) {
                Text(product.price)
                    .font(labelFont(size: 11, weight: .bold))
                    .foregroundColor(product.isAvailableForSale ? Color(hex: 0xC8965A) : tertiaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Button {
                    if product.hasVariantChoices {
                        recordRecentlyViewed(product)
                        selectedProduct = product
                    } else {
                        addToCart(product: product)
                    }
                } label: {
                    Text(signatureRoastActionTitle(for: product))
                        .font(labelFont(size: 8, weight: .bold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .foregroundColor(product.isAvailableForSale ? Color(hex: 0x0A0804) : tertiaryTextColor)
                        .frame(width: 82)
                        .padding(.vertical, 7)
                        .glassEffect(
                            product.isAvailableForSale
                                ? .regular.tint(Color(hex: 0xC8965A)).interactive()
                                : .clear,
                            in: .capsule
                        )
                }
                .buttonStyle(.plain)
                .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)
            }
            .frame(height: 30, alignment: .center)
        }
        .padding(10)
        .frame(width: isCompact ? compactCardWidth : nil, height: isCompact ? 258 : 288, alignment: .topLeading)
        .frame(maxWidth: isCompact ? nil : .infinity, alignment: .topLeading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            recordRecentlyViewed(product)
            selectedProduct = product
        }
        .hoverEffect(.lift)
    }

    func signatureRoastActionTitle(for product: Product) -> String {
        if !product.isAvailableForSale {
            return AppLocalization.text("sold_out", fallback: "Sold Out")
        }

        return product.hasVariantChoices
            ? AppLocalization.text("options", fallback: "Options")
            : AppLocalization.text("add", fallback: "Add")
    }

    func productPreviewDescription(for product: Product) -> String {
        let plainDescription = product.desc
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let fallback = product.categoryLabel.isEmpty
            ? AppLocalization.text("shop_product_preview_fallback", fallback: "Tap for full details.")
            : product.categoryLabel
        let cleanedDescription = customerFacingText(plainDescription)
        let description = cleanedDescription.isEmpty ? fallback : cleanedDescription
        let maxLength = isCompact ? 74 : 112

        guard description.count > maxLength else { return description }

        let endIndex = description.index(description.startIndex, offsetBy: maxLength)
        return description[..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    func customerFacingProductName(for product: Product) -> String {
        let cleanedName = customerFacingText(product.name)
        return cleanedName.isEmpty ? AppLocalization.text("this_product", fallback: "this product") : cleanedName
    }

    func customerFacingText(_ text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let prefixes = [
            "Product Description:",
            "Description:",
            "Product Details:",
            "Product Experience:",
            "Product Quality:"
        ]

        var removedPrefix = true
        while removedPrefix {
            removedPrefix = false
            for prefix in prefixes where cleaned.range(of: prefix, options: [.caseInsensitive, .anchored]) != nil {
                cleaned = String(cleaned.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                removedPrefix = true
            }
        }

        return cleaned
    }

    func recommendationCopy(source: Product, recommended: Product) -> String {
        let sourceName = customerFacingProductName(for: source)
        let recommendedName = customerFacingProductName(for: recommended)
        return String(format: AppLocalization.text("similar_order_recommendation_plain", fallback: "Loved %@? Try %@ for your next gathering."), sourceName, recommendedName)
    }

    func productOriginLabel(for product: Product) -> String {
        if let countryOfOrigin = productCountryOfOrigin(for: product) {
            return countryOfOrigin
        }

        return product.categoryLabel.isEmpty
            ? AppLocalization.text("signature_roast_origin_fallback", fallback: "Signature Roast")
            : product.categoryLabel
    }

    func productCountryOfOrigin(for product: Product) -> String? {
        if let countryOfOrigin = product.countryOfOrigin {
            return countryOfOrigin
        }

        return firstMatchedValue(in: normalizedSearchText(for: product), matches: [
            ("ethiopia", "Ethiopia"),
            ("colombia", "Colombia"),
            ("brazil", "Brazil"),
            ("yemen", "Yemen"),
            ("kenya", "Kenya"),
            ("guatemala", "Guatemala"),
            ("costa rica", "Costa Rica"),
            ("greece", "Greece"),
            ("qatar", "Qatar"),
            ("united arab emirates", "United Arab Emirates"),
            ("emirati", "United Arab Emirates"),
            ("kuwait", "Kuwait")
        ])
    }

    func productTasteNotes(for product: Product) -> [String] {
        let notes = productTasteSummary(for: product)
            .components(separatedBy: " - ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if notes.isEmpty {
            return [
                AppLocalization.text("taste_note_balanced", fallback: "Balanced"),
                AppLocalization.text("taste_note_sweet", fallback: "Sweet")
            ]
        }

        if notes.count == 1 {
            return notes + [AppLocalization.text("taste_note_clean", fallback: "Clean")]
        }

        return Array(notes.prefix(2))
    }

    func productTasteSummary(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)
        let matchedNotes = orderedUniqueValues(tasteNoteMatches(in: searchableText))

        if !matchedNotes.isEmpty {
            return matchedNotes.prefix(3).joined(separator: " - ")
        }

        if product.categoryKey == "coffee-beans" || product.categoryKey == "drip-bags" {
            return AppLocalization.text("coffee_card_default_taste", fallback: "Balanced - Sweet - Clean")
        }

        switch product.categoryKey {
        case "ready-made-drinks":
            return AppLocalization.text("ready_drink_card_summary", fallback: "Ready to drink")
        case "summer-drinks":
            return AppLocalization.text("summer_box_card_summary", fallback: "Seasonal drink box")
        case "cups":
            return AppLocalization.text("cups_card_summary", fallback: "Reusable cup")
        case "coffee-equipment":
            return AppLocalization.text("equipment_card_summary", fallback: "Brewing gear")
        case "gifts":
            return AppLocalization.text("gifts_card_summary", fallback: "Gift box")
        case "arabic-coffee":
            return AppLocalization.text("arabic_card_summary", fallback: "Arabic coffee")
        default:
            return product.categoryLabel.isEmpty
                ? AppLocalization.text("product_card_summary_fallback", fallback: "Talla pick")
                : product.categoryLabel
        }
    }

    func tasteNoteMatches(in searchableText: String) -> [String] {
        let notes: [(keyword: String, note: String)] = [
            (keyword: "berry", note: "Berries"),
            (keyword: "berries", note: "Berries"),
            (keyword: "floral", note: "Floral"),
            (keyword: "jasmine", note: "Floral"),
            (keyword: "chocolate", note: "Chocolate"),
            (keyword: "cocoa", note: "Chocolate"),
            (keyword: "caramel", note: "Caramel"),
            (keyword: "citrus", note: "Citrus"),
            (keyword: "orange", note: "Citrus"),
            (keyword: "fruit", note: "Fruity"),
            (keyword: "nut", note: "Nutty"),
            (keyword: "honey", note: "Honey"),
            (keyword: "vanilla", note: "Vanilla")
        ]

        return notes.compactMap { pair in
            searchableText.contains(pair.keyword) ? pair.note : nil
        }
    }

    func productBrewRecommendation(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)

        if product.categoryKey == "ready-made-drinks" {
            return AppLocalization.text("best_ready_to_drink", fallback: "Best served chilled and ready to drink.")
        }

        if product.categoryKey == "summer-drinks" {
            return AppLocalization.text("best_summer_box", fallback: "A chilled seasonal box made for sharing.")
        }

        if product.categoryKey == "cups" {
            return AppLocalization.text("best_for_cups", fallback: "Best for serving hot and cold drinks.")
        }

        if product.categoryKey == "coffee-equipment" {
            return AppLocalization.text("best_for_home_brewing", fallback: "Best for your home brewing setup.")
        }

        if searchableText.contains("arabic") {
            return AppLocalization.text("best_for_arabic_coffee", fallback: "Best for Arabic coffee and sharing.")
        }

        if searchableText.contains("espresso") {
            return AppLocalization.text("best_for_espresso", fallback: "Best for espresso and milk drinks.")
        }

        if searchableText.contains("iced") || searchableText.contains("cold") {
            return AppLocalization.text("best_for_iced_v60", fallback: "Best for V60 and iced coffee.")
        }

        if searchableText.contains("drip") {
            return AppLocalization.text("best_for_drip_bags", fallback: "Best for easy travel brewing.")
        }

        return AppLocalization.text("best_for_v60", fallback: "Best for V60 and filter brewing.")
    }

    func productMetadataChips(for product: Product) -> [(icon: String, title: String)] {
        let searchableText = normalizedSearchText(for: product)
        var chips: [(icon: String, title: String)] = []

        if let roast = firstMatchedValue(in: searchableText, matches: [
            ("light roast", "Light"),
            ("medium roast", "Medium"),
            ("dark roast", "Dark"),
            ("light", "Light"),
            ("medium", "Medium"),
            ("dark", "Dark")
        ]) {
            chips.append(("flame.fill", roast))
        }

        if let process = firstMatchedValue(in: searchableText, matches: [
            ("anaerobic", "Anaerobic"),
            ("natural", "Natural"),
            ("washed", "Washed"),
            ("honey", "Honey")
        ]) {
            chips.append(("sparkles", process))
        }

        if let origin = firstMatchedValue(in: searchableText, matches: [
            ("ethiopia", "Ethiopia"),
            ("colombia", "Colombia"),
            ("brazil", "Brazil"),
            ("yemen", "Yemen"),
            ("kenya", "Kenya"),
            ("guatemala", "Guatemala"),
            ("costa rica", "Costa Rica"),
            ("arabic", "Arabic")
        ]) {
            chips.append(("globe.europe.africa.fill", origin))
        }

        chips.append(("drop.fill", productBrewChipTitle(for: product)))

        if chips.count < 4 {
            chips.append(("tag.fill", product.categoryLabel))
        }

        return Array(chips.prefix(4))
    }

    func productMetadataChip(icon: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))

            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundColor(readableBrandGoldColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.14))
        .clipShape(Capsule())
    }

    func productBrewChipTitle(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)

        if product.categoryKey == "ready-made-drinks" { return "Chilled" }
        if product.categoryKey == "summer-drinks" { return "Share" }
        if product.categoryKey == "cups" { return "Serve" }
        if product.categoryKey == "coffee-equipment" { return "Gear" }
        if searchableText.contains("espresso") { return "Espresso" }
        if searchableText.contains("arabic") { return "Arabic" }
        if searchableText.contains("drip") { return "Drip" }
        return "V60"
    }

    func normalizedSearchText(for product: Product) -> String {
        "\(product.name) \(product.categoryLabel) \(product.tag ?? "") \(productPreviewDescription(for: product))"
            .lowercased()
    }

    func coffeePassportOriginKey(in text: String) -> String? {
        let normalizedText = text.lowercased()
        if let origin = remotePassportSettings?.origins.first(where: { origin in
            origin.keywords.contains { keyword in
                normalizedText.contains(keyword.lowercased())
            }
        }) {
            return origin.id
        }

        return defaultCoffeePassportOrigins.first { origin in
            normalizedText.contains(origin.id) || normalizedText.contains(origin.title.lowercased())
        }?.id
    }

    func firstMatchedValue(in text: String, matches: [(needle: String, value: String)]) -> String? {
        matches.first { text.contains($0.needle) }?.value
    }

    func orderedUniqueValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    func productBadges(for product: Product) -> [String] {
        var badges: [String] = []
        let normalizedTag = product.tag?.lowercased() ?? ""
        let normalizedName = product.name.lowercased()

        if !product.isAvailableForSale {
            badges.append(AppLocalization.text("back_soon", fallback: "Back soon"))
        } else if normalizedTag.contains("new") {
            badges.append(AppLocalization.text("new", fallback: "New"))
        } else if normalizedTag.contains("limited") {
            badges.append(AppLocalization.text("limited", fallback: "Limited"))
        } else if normalizedTag.contains("staff") {
            badges.append(AppLocalization.text("staff_pick", fallback: "Staff Pick"))
        } else if normalizedTag.contains("popular") || normalizedTag.contains("best") {
            badges.append(AppLocalization.text("popular", fallback: "Popular"))
        }

        if product.categoryKey == "gifts" || product.categoryKey == "summer-drinks" {
            badges.append(AppLocalization.text("gift_ready", fallback: "Gift ready"))
        }

        if product.categoryKey.contains("coffee") && product.isAvailableForSale {
            badges.append(AppLocalization.text("reward_eligible", fallback: "Reward eligible"))
        }

        if normalizedName.contains("cold") || normalizedName.contains("iced") {
            badges.append(AppLocalization.text("cold_pick", fallback: "Cold pick"))
        }

        return Array(badges.prefix(2))
    }

    func productBadge(_ title: String) -> some View {
        Text(title)
            .font(labelFont(size: 8, weight: .bold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(Color(hex: 0x0A0804))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(hex: 0xC8965A))
            .clipShape(Capsule(style: .continuous))
    }

    func productDetailSheet(product: Product) -> some View {
        let selectedVariant = selectedVariant(for: product)

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 22)
                    .frame(height: 280)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.categoryLabel)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        Text(product.name)
                            .font(titleFont(size: 28))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if let tag = product.tag {
                        Text(tag)
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(1.8)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(hex: 0xC8965A))
                            .clipShape(Capsule())
                    }
                }

                Text(selectedVariant?.price ?? product.price)
                    .font(displayFont(size: 24))
                    .foregroundColor((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? Color(hex: 0xC8965A) : tertiaryTextColor)

                if product.hasVariantChoices {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalization.text("variants", fallback: "VARIANTS"))
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        ForEach(product.variants) { variant in
                            Button {
                                selectedVariantIDs[product.id] = variant.id
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(variant.title)
                                            .font(bodyFont(size: 14))
                                            .foregroundColor(primaryTextColor)
                                        Text(variant.price)
                                            .font(labelFont(size: 10, weight: .bold))
                                            .tracking(1.4)
                                            .foregroundColor(readableBrandGoldColor)
                                    }

                                    Spacer()

                                    Text(variant.isAvailableForSale ? AppLocalization.text("available", fallback: "Available") : AppLocalization.text("sold_out", fallback: "Sold Out"))
                                        .font(labelFont(size: 9, weight: .bold))
                                        .tracking(1.4)
                                        .textCase(.uppercase)
                                        .foregroundColor(variant.isAvailableForSale ? primaryTextColor : tertiaryTextColor)

                                    Image(systemName: selectedVariant?.id == variant.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedVariant?.id == variant.id ? Color(hex: 0xC8965A) : tertiaryTextColor)
                                }
                                .padding(14)
                                .background(cardFillColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            (selectedVariant?.id == variant.id ? Color(hex: 0xC8965A) : Color(hex: 0xC8965A).opacity(0.14)),
                                            lineWidth: 1
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    DetailStatusCardView(
                        title: AppLocalization.text("availability", fallback: "Availability"),
                        detail: product.isAvailableForSale ? AppLocalization.text("ready_to_order", fallback: "Ready to order now") : AppLocalization.text("currently_sold_out", fallback: "Currently sold out"),
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: Color(hex: 0xC8965A),
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                    DetailStatusCardView(
                        title: AppLocalization.text("category", fallback: "Category"),
                        detail: product.categoryLabel,
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: Color(hex: 0xC8965A),
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                }

                VStack(spacing: 12) {
                    if isBrewableCoffee(product) {
                        Button {
                            startBrewing(product: product)
                        } label: {
                            Label(
                                AppLocalization.text("brew_this_coffee", fallback: "Start Brewing This Coffee"),
                                systemImage: "cup.and.saucer.fill"
                            )
                                .font(labelFont(size: 11, weight: .bold))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0x0A0804))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: 0xC8965A))
                                .clipShape(Capsule(style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 12) {
                        Button {
                            toggleFavorite(product: product)
                        } label: {
                            Label(isFavorite(product) ? "Saved" : "Save", systemImage: isFavorite(product) ? "heart.fill" : "heart")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.4)
                                .textCase(.uppercase)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(cardFillColor)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        if !product.isAvailableForSale || isAlertEnabled(product) {
                            Button {
                                Task {
                                    await toggleAlert(product: product)
                                }
                            } label: {
                                Label(
                                    isAlertEnabled(product)
                                        ? AppLocalization.text("notification_on", fallback: "Notification On")
                                        : AppLocalization.text("notify_when_available", fallback: "Notify When Available"),
                                    systemImage: isAlertEnabled(product) ? "bell.fill" : "bell"
                                )
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.4)
                                    .textCase(.uppercase)
                                    .foregroundColor(primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(cardFillColor)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        addToCart(product: product)
                        selectedProduct = nil
                    } label: {
                        Text((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? AppLocalization.text("add_to_bag", fallback: "Add to Bag") : AppLocalization.text("sold_out", fallback: "Sold Out"))
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? Color(hex: 0x0A0804) : tertiaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassEffect(
                                (selectedVariant?.isAvailableForSale ?? product.isAvailableForSale)
                                    ? .regular.tint(Color(hex: 0xC8965A)).interactive()
                                    : .clear,
                                in: .capsule
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!(selectedVariant?.isAvailableForSale ?? false))
                }
            }
            .padding(20)
        }
        .background(backgroundGradientColors[0].ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    func isBrewableCoffee(_ product: Product) -> Bool {
        ["coffee-beans", "arabic-coffee-beans", "drip-bags"].contains(product.categoryKey)
    }

    func collectionTile(eyebrow: String, name: String, desc: String, accent: String, systemImage: String, color: Color, categoryKey: String) -> some View {
        Button {
            openShop(category: categoryKey)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(eyebrow)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2.4)
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        Text(name)
                            .font(titleFont(size: 22))
                            .foregroundColor(primaryTextColor)
                    }

                    Spacer()

                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(readableBrandGoldColor)
                }

                Text(desc)
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack(alignment: .center) {
                    Text(accent)
                        .font(bodyFont(size: 12))
                        .foregroundColor(tertiaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 10)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0xC8965A).opacity(0.72))
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.78), color.opacity(0.56)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func featureItem(symbol: String, eyebrow: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: eyebrow.isEmpty ? 0 : 8) {
                    if !eyebrow.isEmpty {
                        Text(eyebrow)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2.4)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xA46A31))
                    }

                    Text(title)
                        .font(titleFont(size: 17))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: 0xF4E6D2).opacity(isLightAppearance ? 0.95 : 0.12))
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: 0xA46A31))
                }
                .frame(width: 38, height: 38)
            }

            Text(detail)
                .font(bodyFont(size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isLightAppearance
                            ? [
                                Color(hex: 0xFFF9F1),
                                Color(hex: 0xF2E0C7)
                            ]
                            : (isOLEDAppearance
                                ? [.black, .black]
                                : [
                                    Color(hex: 0x241A12).opacity(0.94),
                                    elevatedSurfaceColor.opacity(0.96)
                                ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.18 : 0.08), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: 0xD8AE72).opacity(isLightAppearance ? 0.16 : 0.08))
                .frame(width: 68, height: 68)
                .blur(radius: 10)
                .offset(x: 14, y: -10)
        }
    }

    func heroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(value)
                .font(titleFont(size: 22))
                .foregroundColor(primaryTextColor)

            Text(label)
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Capsule(style: .continuous)
                .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.22 : 0.14))
                .frame(width: 34, height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isLightAppearance
                            ? [
                                Color.white.opacity(0.88),
                                Color(hex: 0xF3E3CC).opacity(0.94)
                            ]
                            : (isOLEDAppearance
                                ? [.black, .black]
                                : [
                                    Color.white.opacity(0.03),
                                    Color(hex: 0x2A1D14).opacity(0.82)
                                ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.18 : 0.09), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: 0xD6A667).opacity(isLightAppearance ? 0.16 : 0.08))
                .frame(width: 42, height: 42)
                .blur(radius: 8)
                .offset(x: 6, y: -6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func loyaltyBenefit(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(labelFont(size: 11, weight: .bold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

            Text(detail)
                .font(bodyFont(size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func loyaltyRewardsActions(account: LoyaltyAccount) -> some View {
        LoyaltyRewardsActionsView(
            account: account,
            configuration: remoteAppSettings?.loyalty,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: Color(hex: 0xC8965A),
            isLightAppearance: isLightAppearance,
            isRedeemingReward: isRedeemingReward,
            redeemAction: { points, reward in
                Task {
                    await redeemReward(points: points, reward: reward)
                }
            }
        )
    }

    func loyaltyProgressCard(title: String, accent: String, current: Int, target: Int, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)

                Spacer()

                Text("\(current)/\(target)")
                    .font(bodyFont(size: 12))
                    .foregroundColor(secondaryTextColor)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.10))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xC8965A), Color(hex: 0x8A5E30)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(proxy.size.width * fraction, 10))
                }
            }
            .frame(height: 10)

            Text(accent)
                .font(bodyFont(size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var expiringRewardsSection: some View {
        ExpiringRewardsSectionView(
            vouchers: expiringVouchers,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            expiryLabel: { voucher in
                voucherExpiryLabel(for: voucher)
            },
            expiresSoon: { voucher in
                voucherExpiresSoon(voucher)
            }
        )
    }

    func loyaltyTransactionsSection(account: LoyaltyAccount) -> some View {
        LoyaltyTransactionsSectionView(
            account: account,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance
        )
    }

    var walletCallToAction: some View {
        LoyaltyWalletCallToActionView(
            isLoadingWalletPass: isLoadingWalletPass,
            isWalletPassAdded: isLoyaltyPassInWallet,
            tertiaryTextColor: tertiaryTextColor,
            action: {
                Task {
                    await addLoyaltyPassToWallet()
                }
            }
        )
    }

    func infoChip(symbol: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundColor(readableBrandGoldColor)

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(secondaryTextColor)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: 0xC8965A).opacity(0.15), lineWidth: 1)
        )
    }

    func infoTile(title: String, detail: String, actionTitle: String, destination: URL) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(titleFont(size: 20))
                    .foregroundColor(primaryTextColor)

                Text(detail)
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                openURL(destination)
            } label: {
                HStack(spacing: 6) {
                    Text(actionTitle)
                    Image(systemName: "arrow.up.right")
                }
                .font(labelFont(size: 11, weight: .bold))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    func socialChip(label: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(label)
        }
        .font(.system(size: 10, weight: .medium))
        .tracking(2)
        .textCase(.uppercase)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: 0xC8965A).opacity(0.2), lineWidth: 1)
        )
        .foregroundColor(primaryTextColor)
    }

    func formattedRatioValue(_ value: Double) -> String {
        if value == 0 {
            return "0"
        }

        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }

    func displayFont(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .largeTitle)
    }

    func titleFont(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .title3)
    }

    func bodyFont(size: CGFloat) -> Font {
        .custom("AvenirNext-Regular", size: size, relativeTo: .body)
    }

    func labelFont(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
        case .bold:
            return .custom("AvenirNext-Bold", size: size, relativeTo: .caption)
        case .semibold:
            return .custom("AvenirNext-DemiBold", size: size, relativeTo: .caption)
        default:
            return .custom("AvenirNext-Medium", size: size, relativeTo: .caption)
        }
    }

    func addToCart(product: Product) {
        guard let variant = selectedVariant(for: product), variant.isAvailableForSale else {
            showToast(message: String(format: AppLocalization.text("product_unavailable_toast", fallback: "%@ is unavailable"), product.name))
            return
        }

        recordRecentlyViewed(product)

        let cartItemID = cartItemIdentifier(productID: product.id, variantID: variant.id)

        if let index = cartItems.firstIndex(where: { $0.id == cartItemID }) {
            updateCartItemQuantity(at: index, quantity: cartItems[index].quantity + 1)
        } else {
            cartItems.append(CartItem(id: cartItemID, product: product, variant: variant, quantity: 1))
        }

        checkoutError = nil
        triggerCartCelebration()
        let variantSuffix = product.hasVariantChoices ? " (\(variant.title))" : ""
        showToast(message: String(format: AppLocalization.text("product_added_to_cart", fallback: "%@%@ added to bag"), product.name, variantSuffix))
    }

    func triggerCartCelebration() {
        cartCelebrationID += 1
        delightFeedbackTrigger += 1

        withAnimation(.spring(response: 0.26, dampingFraction: 0.48)) {
            showingCartCelebration = true
        }

        let celebrationID = cartCelebrationID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard cartCelebrationID == celebrationID else { return }

            withAnimation(.easeOut(duration: 0.18)) {
                showingCartCelebration = false
            }
        }
    }

    func removeFromCart(id: String) {
        cartItems.removeAll { $0.id == id }
        checkoutError = nil
    }

    func requestRemoveFromCart(id: String) {
        if cartItems.count == 1 {
            pendingCartRemovalID = id
            isConfirmingEmptyBag = true
        } else {
            removeFromCart(id: id)
        }
    }

    func updateCartItemQuantity(at index: Int, quantity: Int) {
        guard cartItems.indices.contains(index) else { return }
        var updatedItem = cartItems[index]
        updatedItem.quantity = max(quantity, 1)
        cartItems[index] = updatedItem
    }

    func cartItemIdentifier(productID: String, variantID: String) -> String {
        "\(productID)::\(variantID)"
    }

    func selectedVariant(for product: Product) -> Product.Variant? {
        if let selectedVariantID = selectedVariantIDs[product.id],
           let variant = product.variants.first(where: { $0.id == selectedVariantID }) {
            return variant
        }

        return product.defaultVariant
    }

    func cartVariantDisplayTitle(for item: CartItem) -> String? {
        let title = item.variant.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard item.product.hasVariantChoices,
              !title.isEmpty,
              title.localizedCaseInsensitiveCompare("Default") != .orderedSame,
              title.localizedCaseInsensitiveCompare("Default Title") != .orderedSame else {
            return nil
        }

        return title
    }

    func isFavorite(_ product: Product) -> Bool {
        favoriteProductIDs.contains(product.id)
    }

    func isAlertEnabled(_ product: Product) -> Bool {
        alertProductIDs.contains(product.id)
    }

    func persistSavedCarts(_ carts: [SavedCart]) {
        guard let data = try? JSONEncoder().encode(carts),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedCartsPayload = json
    }

    func saveCurrentCart() {
        guard !cartItems.isEmpty else {
            showToast(message: AppLocalization.text("add_items_before_saving_cart", fallback: "Add items before saving a bag"))
            return
        }

        let trimmedName = cartSaveName.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedCart = SavedCart(
            id: UUID(),
            name: trimmedName.isEmpty ? defaultSavedCartName() : trimmedName,
            items: cartItems.map {
                SavedCart.Item(productID: $0.product.id, productName: $0.product.name, quantity: $0.quantity)
            },
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        persistSavedCarts([savedCart] + savedCarts)
        cartSaveName = ""
        isCartSaveEntryExpanded = false
        showToast(message: AppLocalization.text("cart_saved_toast", fallback: "Bag saved"))
    }

    func applySavedCart(_ savedCart: SavedCart) {
        let matchedItems = savedCart.items.compactMap { item -> (Product, Int)? in
            if let product = products.first(where: { $0.id == item.productID }) ?? matchingProduct(for: item.productName) {
                return (product, item.quantity)
            }

            return nil
        }

        guard !matchedItems.isEmpty else {
            showToast(message: AppLocalization.text("saved_cart_unavailable", fallback: "Saved bag items are unavailable right now"))
            return
        }

        cartItems = []
        for (product, quantity) in matchedItems {
            guard let variant = selectedVariant(for: product) else { continue }
            cartItems.append(
                CartItem(
                    id: cartItemIdentifier(productID: product.id, variantID: variant.id),
                    product: product,
                    variant: variant,
                    quantity: quantity
                )
            )
        }

        cartOpen = true
        showToast(message: String(format: AppLocalization.text("saved_cart_loaded_toast", fallback: "%@ loaded"), savedCart.name))
    }

    func deleteSavedCart(_ savedCart: SavedCart) {
        persistSavedCarts(savedCarts.filter { $0.id != savedCart.id })
        showToast(message: AppLocalization.text("saved_cart_deleted_toast", fallback: "Saved bag deleted"))
    }

    func defaultSavedCartName() -> String {
        let itemCount = cartItems.reduce(0) { $0 + $1.quantity }
        return "Cart \(itemCount) items"
    }

    func toggleFavorite(product: Product) {
        var updatedFavorites = favoriteProductIDs
        recordRecentlyViewed(product)
        let isFavorite: Bool

        if updatedFavorites.contains(product.id) {
            updatedFavorites.remove(product.id)
            isFavorite = false
            showToast(message: AppLocalization.text("removed_from_favorites", fallback: "Removed from favorites"))
        } else {
            updatedFavorites.insert(product.id)
            isFavorite = true
            showToast(message: AppLocalization.text("saved_to_favorites", fallback: "Saved to favorites"))
        }

        delightFeedbackTrigger += 1
        savedFavoriteProductIDs = updatedFavorites.sorted().joined(separator: ",")
        if customerProfile != nil {
            Task { _ = try? await AccountService.setFavorite(productID: product.id, favorite: isFavorite) }
        }
    }

    @MainActor
    func toggleAlert(product: Product) async {
        var updatedAlerts = alertProductIDs

        if updatedAlerts.contains(product.id) {
            updatedAlerts.remove(product.id)
            if let email = customerProfile?.email {
                try? await AccountService.removeStockAlert(email: email, productID: product.id)
                backendStockAlerts.removeAll { $0.productID == product.id }
            }
            showToast(message: AppLocalization.text("removed_from_alerts", fallback: "Removed from alerts"))
        } else {
            updatedAlerts.insert(product.id)
            recordRecentlyViewed(product)
            if let email = customerProfile?.email {
                let record = StockAlertRecord(
                    productID: product.id,
                    productName: product.name,
                    tag: product.tag,
                    isAvailableForSale: product.isAvailableForSale,
                    status: product.isAvailableForSale ? "Available now" : "Waiting for availability",
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
                if let stored = try? await AccountService.watchStockAlert(email: email, alert: record) {
                    backendStockAlerts.removeAll { $0.productID == stored.productID }
                    backendStockAlerts.insert(stored, at: 0)
                }
            }
            let granted = await requestNotificationAccessIfNeeded()
            if granted {
                showToast(message: AppLocalization.text("availability_notification_enabled", fallback: "We’ll notify you when this product is available."))
            } else {
                showToast(message: AppLocalization.text("added_to_alerts_notifications_off", fallback: "Alert saved. Notifications are not enabled."))
            }
        }

        delightFeedbackTrigger += 1
        savedAlertProductIDs = updatedAlerts.sorted().joined(separator: ",")
    }

    func recordRecentlyViewed(_ product: Product) {
        var updated = recentlyViewedProductIDs.filter { $0 != product.id }
        updated.insert(product.id, at: 0)
        updated = Array(updated.prefix(12))
        savedRecentlyViewedProductIDs = updated.joined(separator: ",")
        if customerProfile != nil {
            Task { _ = try? await AccountService.recordRecentlyViewed(productID: product.id) }
        }
    }

    func productAlertLabel(for product: Product) -> String {
        if !product.isAvailableForSale {
            return AppLocalization.text("waiting_for_availability", fallback: "Waiting for availability")
        }
        return AppLocalization.text("available_now", fallback: "Available now")
    }

    func stockAlertLabel(for product: Product) -> String {
        guard let status = backendStockAlertLookup[product.id]?.status,
              !status.localizedCaseInsensitiveContains("watch") else {
            return productAlertLabel(for: product)
        }
        return status
    }

    func buyAgain(order: AccountOrder) {
        guard let items = order.items, !items.isEmpty else { return }

        let matchedProducts = items.compactMap { item -> (Product, Int)? in
            guard let product = matchingProduct(for: item.name) else { return nil }
            return (product, item.quantity)
        }

        guard !matchedProducts.isEmpty else {
            showToast(message: AppLocalization.text("items_unavailable_currently", fallback: "Those items are currently unavailable"))
            return
        }

        for (product, quantity) in matchedProducts {
            guard let variant = selectedVariant(for: product) else { continue }
            let cartItemID = cartItemIdentifier(productID: product.id, variantID: variant.id)
            if let index = cartItems.firstIndex(where: { $0.id == cartItemID }) {
                updateCartItemQuantity(at: index, quantity: cartItems[index].quantity + quantity)
            } else {
                cartItems.append(CartItem(id: cartItemID, product: product, variant: variant, quantity: quantity))
            }
        }

        checkoutError = nil
        cartOpen = true

        if matchedProducts.count == items.count {
            showToast(message: AppLocalization.text("order_added_to_cart", fallback: "Order added to bag"))
        } else {
            showToast(message: AppLocalization.text("available_items_added_from_order", fallback: "Available items from that order were added"))
        }
    }

    func saveTasteMemory(order: AccountOrder, item: AccountOrder.Item, reaction: String, tags: [String]) {
        let record = TasteMemoryRecord(
            id: tasteMemoryKey(order: order, item: item),
            orderID: order.id,
            productName: item.name,
            reaction: reaction,
            tags: tags,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil
        )
        let existing = tasteMemoryRecords.filter { $0.id != record.id }
        let updated = Array(([record] + existing).prefix(80))

        persistTasteMemoryRecords(updated)
        delightFeedbackTrigger += 1
        showToast(message: AppLocalization.text("taste_memory_saved", fallback: "Taste memory saved"))

        if let profile = customerProfile {
            Task {
                do {
                    _ = try await AccountService.saveTasteMemory(
                        email: profile.email,
                        orderID: order.id,
                        productName: item.name,
                        reaction: reaction,
                        tags: tags
                    )
                    let remoteTasteMemory = try await AccountService.fetchTasteMemory(email: profile.email)
                    await MainActor.run {
                        persistTasteMemoryRecords(remoteTasteMemory)
                    }
                } catch {
                    return
                }
            }
        }
    }

    func persistTasteMemoryRecords(_ records: [TasteMemoryRecord]) {
        let sortedRecords = records
            .sorted {
                let lhsDate = ISO8601DateFormatter().date(from: $0.updatedAt ?? $0.createdAt) ?? .distantPast
                let rhsDate = ISO8601DateFormatter().date(from: $1.updatedAt ?? $1.createdAt) ?? .distantPast
                return lhsDate > rhsDate
            }
        var seenRecordIDs = Set<String>()
        let uniqueRecords = Array(sortedRecords.filter { record in
            guard !seenRecordIDs.contains(record.id) else { return false }
            seenRecordIDs.insert(record.id)
            return true
        }.prefix(80))

        guard let data = try? JSONEncoder().encode(uniqueRecords),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedTasteMemory = json
    }

    func matchingProduct(for orderItemName: String) -> Product? {
        let normalizedOrderName = normalizedProductName(orderItemName)

        return products.first { normalizedProductName($0.name) == normalizedOrderName }
            ?? products.first {
                let normalizedProduct = normalizedProductName($0.name)
                return normalizedProduct.contains(normalizedOrderName) || normalizedOrderName.contains(normalizedProduct)
            }
    }

    func tasteMemoryKey(order: AccountOrder, item: AccountOrder.Item) -> String {
        "\(order.id)-\(normalizedProductName(item.name))"
    }

    func tastePreferenceScore(for product: Product) -> Int {
        let productText = normalizedSearchText(for: product)

        return tasteMemoryRecords.reduce(0) { score, record in
            let tagScore = record.tags.reduce(0) { partialResult, tag in
                partialResult + (productText.contains(tag.lowercased()) ? 3 : 0)
            }
            let reactionScore = record.reaction == "loved" ? tagScore : -tagScore
            let productPenalty = record.reaction == "not-for-me" && normalizedProductName(record.productName) == normalizedProductName(product.name) ? -8 : 0
            return score + reactionScore + productPenalty
        }
    }

    func daysSinceOrder(_ order: AccountOrder) -> Int {
        let startOfOrderDay = Calendar.current.startOfDay(for: orderDate(from: order.createdAt))
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return max(Calendar.current.dateComponents([.day], from: startOfOrderDay, to: startOfToday).day ?? 0, 0)
    }

    func orderDate(from value: String) -> Date {
        if let date = ISO8601DateFormatter().date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        if let date = formatter.date(from: value) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? .distantPast
    }

    func normalizedProductName(_ name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    @MainActor
    func applyVoucher() async {
        guard let profile = customerProfile else {
            voucherError = AppLocalization.text("sign_in_to_apply_voucher", fallback: "Sign in to apply a loyalty voucher.")
            return
        }

        let trimmedCode = voucherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedCode.isEmpty else {
            voucherError = AppLocalization.text("enter_voucher_code_first", fallback: "Enter a voucher code first.")
            return
        }

        isApplyingVoucher = true
        voucherError = nil

        do {
            let voucher = try await AccountService.previewVoucher(code: trimmedCode, email: profile.email)
            guard !LoyaltyVoucherRules.isFreeDrink(voucher.reward) || cartDiscountForFreeDrink > 0 else {
                throw LoyaltyServiceError.operationFailed(
                    AppLocalization.text(
                        "free_drink_requires_eligible_drink",
                        fallback: "Add a drink from the Drinks section before applying this reward."
                    )
                )
            }
            appliedVoucher = voucher
            voucherCodeInput = trimmedCode
            await loadAvailableVouchers(for: profile.email)
            showToast(message: AppLocalization.text("voucher_applied_toast", fallback: "Voucher applied"))
        } catch {
            appliedVoucher = nil
            voucherError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("voucher_apply_failed", fallback: "This voucher could not be applied right now.")
            )
        }

        isApplyingVoucher = false
    }

    func removeAppliedVoucher() {
        appliedVoucher = nil
        voucherError = nil
        voucherCodeInput = ""
    }

    @MainActor
    func loadAvailableVouchers(for email: String) async {
        guard !email.isEmpty else { return }

        isLoadingAvailableVouchers = true

        do {
            availableVouchers = try await AccountService.fetchVouchers(email: email)
        } catch {
            availableVouchers = []
        }

        isLoadingAvailableVouchers = false
    }

    @MainActor
    func preparePostPaymentContext(orderID: String, method: TallaPaymentMethod) {
        postPaymentOrderID = orderID
        postPaymentTotal = formattedBHD(cartTotal)
        postPaymentMethodTitle = method.title
        if fulfillmentMethod == .pickup {
            postPaymentFulfillmentTitle = AppLocalization.text("pickup", fallback: "Pickup")
            postPaymentDestination = managedPickupName
        } else {
            postPaymentFulfillmentTitle = AppLocalization.text("delivery", fallback: "Delivery")
            postPaymentDestination = preferredAddress.map {
                "\($0.label) · \($0.line1), \($0.city), \($0.country.name)"
            } ?? ""
        }
    }

    @MainActor
    func presentPostPayment() {
        isCheckoutPresented = false
        isPostPaymentPresented = true
    }

    @MainActor
    func dismissPostPayment(openOrders: Bool = false, openShop shouldOpenShop: Bool = false) {
        isPostPaymentPresented = false

        if !paymentFlow.state.isBusy {
            paymentFlow.reset()
        }

        guard openOrders || shouldOpenShop else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if openOrders {
                openAccountSection(AccountSectionView.ScrollTarget.customer)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                    accountOrdersPresentationRequest += 1
                }
            } else if shouldOpenShop {
                openShop()
            }
        }
    }

    @MainActor
    func retryPostPayment() {
        isPostPaymentPresented = false
        paymentFlow.reset()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            prepareCheckout()
        }
    }

    @MainActor
    func prepareCheckout() {
        guard !cartItems.isEmpty else { return }

        guard remoteAppSettings?.release?.checkoutMaintenanceEnabled != true,
              remoteAppSettings?.release?.maintenanceEnabled != true else {
            checkoutError = isArabicInterface ? "الدفع غير متاح مؤقتاً." : "Checkout is temporarily unavailable."
            return
        }

        guard (fulfillmentMethod == .delivery && remoteAppSettings?.fulfillment?.deliveryEnabled != false)
                || (fulfillmentMethod == .pickup && remoteAppSettings?.fulfillment?.pickupEnabled != false) else {
            checkoutError = isArabicInterface ? "طريقة الاستلام هذه غير متاحة حالياً." : "This fulfillment method is currently unavailable."
            return
        }

        if paymentFlow.selectedMethod == nil {
            if isApplePayAvailable && MastercardSDKAvailability.isAvailable {
                paymentFlow.select(.applePay)
            } else if BenefitPaySDKConfiguration.isAvailable {
                paymentFlow.select(.benefitPay)
            } else {
                paymentFlow.select(.benefit)
            }
        }

        checkoutError = nil
        cartOpen = false
        isCheckoutPresented = true
    }

    @MainActor
    func beginCheckout() async {
        guard let selectedPaymentMethod = paymentFlow.selectedMethod else {
            isPaymentMethodSheetPresented = true
            return
        }

        guard paymentAvailability.isEnabled(selectedPaymentMethod) else {
            paymentFlow.transition(to: .failed)
            checkoutError = isArabicInterface ? "طريقة الدفع هذه غير متاحة حالياً." : "This payment method is currently unavailable."
            return
        }

        if selectedPaymentMethod == .applePay, !isApplePayAvailable {
#if canImport(PassKit)
            PKPassLibrary().openPaymentSetup()
#endif
            checkoutError = AppLocalization.text(
                "apple_pay_setup_required",
                fallback: "Add a supported card to Apple Wallet, then return to complete checkout with Apple Pay."
            )
            return
        }

        guard !isCheckingOut, paymentFlow.begin() else { return }

        guard !cartItems.isEmpty else {
            paymentFlow.transition(to: .failed)
            checkoutError = AppLocalization.text("cart_no_purchasable_items", fallback: "Your bag has no purchasable items.")
            return
        }

        guard let profile = customerProfile else {
            paymentFlow.transition(to: .failed)
            checkoutError = AppLocalization.text("sign_in_before_checkout", fallback: "Sign in before checkout.")
            return
        }

        guard canStartCheckoutWithShipping else {
            paymentFlow.transition(to: .failed)
            checkoutError = cartShipmentWeightGrams == nil
                ? AppLocalization.text("shipping_weight_missing_detail", fallback: "A product in your bag has no shipping weight. Please contact us before checkout.")
                : AppLocalization.text("shipping_weight_over_limit_detail", fallback: "Khaleeji delivery is available for shipments up to 4 kg. Please contact us for a larger order.")
            return
        }

        isCheckingOut = true
        checkoutError = nil
        preparePostPaymentContext(orderID: "", method: selectedPaymentMethod)

        do {
            if let appliedVoucher,
               LoyaltyVoucherRules.isFreeDrink(appliedVoucher.reward),
               cartDiscountForFreeDrink <= 0 {
                throw LoyaltyServiceError.operationFailed(
                    AppLocalization.text(
                        "free_drink_requires_eligible_drink",
                        fallback: "Add a drink from the Drinks section before using this reward."
                    )
                )
            }

            if selectedPaymentMethod.route == .shopifyCashOnDelivery {
                guard appliedVoucher == nil else {
                    throw LoyaltyServiceError.operationFailed(
                        AppLocalization.text(
                            "cash_on_delivery_remove_voucher",
                            fallback: "Remove the Talla voucher before using Shopify Checkout so the verified totals stay identical."
                        )
                    )
                }
                let lines = cartItems.map { ShopifyCheckoutLine(merchandiseId: $0.variant.id, quantity: $0.quantity) }
                let checkoutAddress = fulfillmentMethod == .delivery ? preferredAddress.map { address in
                    ShopifyCheckoutAddress(
                        email: profile.email,
                        fullName: address.fullName,
                        phone: address.phone,
                        address1: address.line1,
                        city: address.city,
                        country: address.country.rawValue
                    )
                } : nil
                let checkoutURL = try await ShopifyStorefrontClient.createCheckoutURL(
                    lines: lines,
                    customerEmail: profile.email,
                    checkoutAddress: checkoutAddress,
                    fulfillmentMethod: fulfillmentMethod
                )
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                isCheckoutPresented = false
                checkoutSession = CheckoutSession(url: checkoutURL)
                let checkoutPrompt = fulfillmentMethod == .pickup
                    ? AppLocalization.text(
                        "cash_on_pickup_shopify_prompt",
                        fallback: "Choose local pickup and Cash on Delivery in Shopify Checkout to place your order."
                    )
                    : AppLocalization.text(
                        "cash_on_delivery_shopify_prompt",
                        fallback: "Choose Cash on Delivery in Shopify Checkout to place your order."
                    )
                showToast(message: checkoutPrompt)
                isCheckingOut = false
                return
            }

            if let appliedVoucher {
                _ = try await AccountService.consumeVoucher(code: appliedVoucher.code, email: profile.email)
                await loadAvailableVouchers(for: profile.email)
            }

            let checkoutItems = cartItems.map { item in
                (
                    name: item.product.name,
                    quantity: item.quantity,
                    variantID: item.variant.id
                )
            }
            let checkoutStart = try await AccountService.recordCheckoutStarted(
                email: profile.email,
                items: checkoutItems,
                total: cartTotal,
                fulfillmentMethod: fulfillmentMethod
            )
            orderHistory = checkoutStart.orders
            preparePostPaymentContext(orderID: checkoutStart.orderID, method: selectedPaymentMethod)

            switch selectedPaymentMethod.route {
            case .benefitHosted:
                let paymentURL = try await AccountService.createBenefitPayment(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                isCheckoutPresented = false
                checkoutSession = CheckoutSession(url: paymentURL)
            case .benefitPaySDK:
                guard BenefitPaySDKConfiguration.isAvailable else {
                    throw PaymentServiceError.gateway("BenefitPay is not configured in this build.")
                }
                let session = try await BenefitPayService.createSession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                isCheckoutPresented = false
                benefitPaySession = session
            case .cardGateway:
                guard MastercardSDKAvailability.isAvailable else {
                    throw PaymentServiceError.gateway("Gateway.xcframework and uSDK.xcframework are required for card entry and 3-D Secure.")
                }
                let session = try await TallaPaymentService.createCardSession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                isCheckoutPresented = false
                mastercardPaymentContext = MastercardPaymentContext(
                    localOrderID: checkoutStart.orderID,
                    session: session,
                    kind: .card
                )
            case .applePayGateway:
                guard isApplePayAvailable else {
                    throw PaymentServiceError.gateway("Apple Pay is unavailable on this device.")
                }
                guard MastercardSDKAvailability.isAvailable else {
                    throw PaymentServiceError.gateway("Gateway.xcframework and uSDK.xcframework are required for Apple Pay gateway tokenization.")
                }
                let session = try await TallaPaymentService.createApplePaySession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                isCheckoutPresented = false
                mastercardPaymentContext = MastercardPaymentContext(
                    localOrderID: checkoutStart.orderID,
                    session: session,
                    kind: .applePay
                )
            case .shopifyCashOnDelivery:
                break
            }
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            showToast(message: AppLocalization.text("checkout_opened_toast", fallback: "Checkout opened. Return to Talla after payment."))
        } catch {
            paymentFlow.transition(to: .failed, error: error.localizedDescription)
            if isExpiredCustomerSessionError(error) {
                signOutCustomer(clearError: false)
                checkoutError = AppLocalization.text(
                    "checkout_session_expired",
                    fallback: "Your session expired. Sign in again to continue checkout."
                )
            } else {
                checkoutError = customerFacingServiceMessage(
                    for: error,
                    fallback: AppLocalization.text("checkout_start_failed", fallback: "Checkout could not be started right now. Your bag is still saved.")
                )
            }
        }

        isCheckingOut = false
    }

    func showToast(message: String) {
        toastMessage = nil
    }

    func categoryDefinition(for key: String) -> ShopCategory {
        if let event = eventForCategory(key) {
            return ShopCategory(
                key: key,
                title: eventCategoryTitle(event),
                subtitle: eventCategorySubtitle(event),
                symbol: event.symbol.isEmpty ? "sparkles" : event.symbol
            )
        }

        if key == "tea" || key == "drinks" {
            return categoryDefinition(for: "ready-made-drinks")
        }

        if key == "drink-cups" || key == "mugs" || key == "drinkware" {
            return categoryDefinition(for: "cups")
        }

        if key == "northern-coffee" {
            return categoryDefinition(for: "arabic-coffee-beans")
        }

        if key == "bread" || key == "crmb-tallas-speciality-bakery" {
            return categoryDefinition(for: "desserts")
        }

        if key == "other" {
            return categoryDefinition(for: "arabic-coffee-beans")
        }

        if let category = categoryCatalog.first(where: { $0.key == key }) {
            return localizedCategory(category)
        }

        let normalizedKey = key.replacingOccurrences(of: "_", with: "-")

        return ShopCategory(
            key: key,
            title: categoryLabel(for: key),
            subtitle: normalizedKey.contains("drink") ? "Ready-to-enjoy picks" : "Curated Talla selection",
            symbol: categorySymbol(for: normalizedKey)
        )
    }

    func categoryLabel(for key: String) -> String {
        guard key != "all" else { return AppLocalization.text("category_all", fallback: "All") }
        if let event = eventForCategory(key) {
            return eventCategoryTitle(event)
        }
        if key == "summer-drinks" {
            return AppLocalization.text("category_summer_drinks", fallback: "Summer Boxes")
        }
        if key == "coffee-beans" {
            return AppLocalization.text("category_coffee_beans", fallback: "Coffee Beans")
        }
        if key == "arabic-coffee-beans" || key == "northern-coffee" || key == "other" {
            return AppLocalization.text("category_arabic_coffee", fallback: "Arabic & Shamali Coffee")
        }
        if key == "drip-bags" {
            return AppLocalization.text("category_drip_bags", fallback: "Drip Bags")
        }
        if key == "coffee-equipment" {
            return AppLocalization.text("category_equipment", fallback: "Equipment")
        }
        if key == "ready-made-drinks" || key == "tea" || key == "drinks" {
            return AppLocalization.text("category_ready_drinks", fallback: "Drinks")
        }
        if key == "cups" || key == "drink-cups" || key == "mugs" || key == "drinkware" {
            return AppLocalization.text("category_cups", fallback: "Cups")
        }
        if key == "crmb-tallas-speciality-bakery" || key == "desserts" || key == "bread" {
            return AppLocalization.text("category_desserts", fallback: "CRMB")
        }
        if key == "spreads" {
            return AppLocalization.text("category_spreads", fallback: "Spreads")
        }
        if key == "hot-chocolate" {
            return AppLocalization.text("category_hot_chocolate", fallback: "Hot Chocolate")
        }
        if key == "gifts" {
            return AppLocalization.text("category_gifts", fallback: "Talla Boxes")
        }
        return key
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    func categorySymbol(for key: String) -> String {
        if key.contains("summer") {
            return "sun.max.fill"
        }

        if key.contains("bean") || key.contains("coffee") {
            return "leaf.fill"
        }

        if key.contains("drip") {
            return "drop.fill"
        }

        if key.contains("equipment") {
            return "flask.fill"
        }

        if key.contains("cup") {
            return "mug.fill"
        }

        if key.contains("drink") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("tea") {
            return "teapot.fill"
        }

        if key.contains("dessert") || key.contains("bread") {
            return "birthday.cake.fill"
        }

        if key.contains("spread") || key.contains("jam") || key.contains("butter") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("chocolate") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("gift") {
            return "gift.fill"
        }

        return "shippingbox.fill"
    }

    func bundledLoyaltyPass() -> PKPass? {
        guard let passURL = Bundle.main.url(forResource: "TallaLoyalty", withExtension: "pkpass"),
              let data = try? Data(contentsOf: passURL),
              let pass = try? PKPass(data: data) else {
            return nil
        }

        return pass
    }

    func priceValue(from price: String) -> Double {
        let sanitized = price
            .replacingOccurrences(of: "BHD", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(sanitized) ?? 0
    }

    func formattedBHD(_ value: Double) -> String {
        String(format: "BHD %.3f", value)
    }

    func voucherExpiresSoon(_ voucher: VoucherRecord) -> Bool {
        guard let expiryDate = ISO8601DateFormatter().date(from: voucher.expiresAt) else { return false }
        return expiryDate.timeIntervalSinceNow <= 3 * 24 * 60 * 60
    }

    func voucherExpiryLabel(for voucher: VoucherRecord) -> String {
        guard let expiryDate = ISO8601DateFormatter().date(from: voucher.expiresAt) else {
            return "Active"
        }

        let days = max(Int(ceil(expiryDate.timeIntervalSinceNow / (24 * 60 * 60))), 0)
        if days <= 0 {
            return "Expires today"
        }
        if days == 1 {
            return "1 day left"
        }
        return "\(days) days left"
    }

    func formattedDiscountLabel(for voucher: VoucherRecord) -> String {
        switch voucher.reward.lowercased() {
        case "free drink":
            return AppLocalization.text("one_eligible_drink", fallback: "1 eligible drink")
        case "pastry pairing":
            return "BHD 2.000"
        case "bag discount":
            return "10% off"
        case "brew bar credit":
            return "BHD 3.000"
        case "talla box reward":
            return "15% off"
        case "roastery gold reward":
            return "20% off"
        default:
            return voucher.detail
        }
    }

    func formattedVoucherDetail(for voucher: VoucherRecord) -> String {
        if LoyaltyVoucherRules.isFreeDrink(voucher.reward) {
            return AppLocalization.text("free_drink_reward_detail", fallback: "One drink of your choice from the Drinks section.")
        }
        return voucher.detail
    }

    var cartDiscountForFreeDrink: Double {
        LoyaltyVoucherRules.freeDrinkDiscount(
            lines: cartItems.map {
                (
                    categoryKey: $0.product.categoryKey,
                    unitPrice: priceValue(from: $0.product.price),
                    quantity: $0.quantity
                )
            }
        )
    }

}
