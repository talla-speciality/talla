import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ProfileManagementSectionView: View {
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let isLightAppearance: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var birthdayMonth: String
    @Binding var birthdayDay: String
    let isSaving: Bool
    let saveAction: () async -> Bool
    @State private var isEditingName = false

    private var hasSavedName: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var savedFullName: String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(hasSavedName
                    ? AppLocalization.text("profile", fallback: "Profile")
                    : AppLocalization.text("complete_profile", fallback: "Complete Profile"))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(AppLocalization.letterSpacing(2))
                    .textCase(.uppercase)
                    .foregroundColor(TallaTheme.Colors.ink)

                Spacer(minLength: 8)

                if hasSavedName && !isEditingName {
                    Button {
                        isEditingName = true
                    } label: {
                        Label(AppLocalization.text("edit_name", fallback: "Edit Name"), systemImage: "pencil")
                            .font(Font.custom("AvenirNext-DemiBold", size: 10))
                            .foregroundColor(TallaTheme.Colors.ink)
                    }
                    .buttonStyle(.plain)
                }
            }

            if isEditingName || !hasSavedName {
                HStack(spacing: 10) {
                    styledTextField(AppLocalization.text("first_name", fallback: "First name"), text: $firstName)
                    styledTextField(AppLocalization.text("last_name", fallback: "Last name"), text: $lastName)
                }

                Button {
                    Task {
                        if await saveAction() {
                            isEditingName = false
                        }
                    }
                } label: {
                    Text(isSaving
                        ? AppLocalization.text("saving", fallback: "SAVING...")
                        : AppLocalization.text("save_profile", fallback: "SAVE PROFILE"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(AppLocalization.letterSpacing(2))
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .tallaGlassCapsule(tint: accentColor)
                }
                .buttonStyle(.plain)
                .disabled(isSaving || firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(TallaTheme.Colors.ink)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(savedFullName)
                            .font(Font.custom("AvenirNext-DemiBold", size: 16))
                            .foregroundColor(primaryTextColor)

                        Text(AppLocalization.text("name_saved_detail", fallback: "Saved to your account and used automatically when you sign in."))
                            .font(Font.custom("AvenirNext-Regular", size: 12))
                            .foregroundColor(secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Birthday rewards")
                    .font(Font.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundColor(primaryTextColor)
                HStack(spacing: 10) {
                    styledNumberField("Month", text: $birthdayMonth)
                    styledNumberField("Day", text: $birthdayDay)
                }
                Text("Save your month and day to unlock the birthday reward on the correct date.")
                    .font(Font.custom("AvenirNext-Regular", size: 11))
                    .foregroundColor(secondaryTextColor)
            }
        }
        .onAppear {
            if !hasSavedName {
                isEditingName = true
            }
        }
    }

    private func styledTextField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .font(Font.custom("AvenirNext-Regular", size: 15))
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func styledNumberField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .keyboardType(.numberPad)
            .font(Font.custom("AvenirNext-Regular", size: 15))
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(cardFillColor)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

}

struct PasswordResetSectionView: View {
    let primaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let isLightAppearance: Bool
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    let isResetting: Bool
    let resetAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("password", fallback: "Password"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(TallaTheme.Colors.ink)

            secureField(AppLocalization.text("current_password", fallback: "Current password"), text: $currentPassword)

            HStack(spacing: 10) {
                secureField(AppLocalization.text("new_password", fallback: "New password"), text: $newPassword)
                secureField(AppLocalization.text("confirm_new", fallback: "Confirm new"), text: $confirmPassword)
            }

            Button(action: resetAction) {
                Text(isResetting
                    ? AppLocalization.text("updating", fallback: "UPDATING...")
                    : AppLocalization.text("update_password", fallback: "UPDATE PASSWORD"))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(AppLocalization.letterSpacing(2))
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(cardFillColor)
                    .overlay(
                        Capsule()
                            .stroke(TallaTheme.Colors.ink.opacity(0.18), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isResetting || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
        }
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(Font.custom("AvenirNext-Regular", size: 15))
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct OrderHistorySectionView: View {
    @Environment(\.openURL) private var openURL
    let orders: [ContentView.AccountOrder]
    let isLoadingOrders: Bool
    let ordersError: String?
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let isLightAppearance: Bool
    let tasteMemoryLookup: [String: ContentView.TasteMemoryRecord]
    let coffeeClubProducts: [ContentView.Product]
    let cafePassProducts: [ContentView.Product]
    let deliveryAddresses: [ContentView.DeliveryAddress]
    let buyAgainAction: (ContentView.AccountOrder) -> Void
    let saveTasteMemoryAction: (ContentView.AccountOrder, ContentView.AccountOrder.Item, String, [String]) -> Void
    let pickupDirectionsAction: () -> Void
    let browseProductsAction: () -> Void
    let orderSupportAction: (ContentView.AccountOrder) -> Void
    let customerOrderAction: (ContentView.AccountOrder, String) async -> Bool
    let manageCoffeeClubAction: (ContentView.AccountOrder, String, String?, String?, String?, [(name: String, variantID: String, quantity: Int)], ContentView.DeliveryAddress?, TallaFulfillmentMethod) async -> Bool
    let swapCafePassAction: (ContentView.AccountOrder, String) async -> Bool

    @State private var managedCoffeeClubOrder: ContentView.AccountOrder?
    @State private var selectedCoffeeName = ""
    @State private var selectedCoffeeVariantID = ""
    @State private var selectedClubCoffees: [EditableClubCoffee] = []
    @State private var selectedAddressID = ""
    @State private var selectedFulfillment: TallaFulfillmentMethod = .delivery
    @State private var managementNote = ""
    @State private var isManagingCoffeeClub = false

    private struct EditableClubCoffee: Identifiable {
        var variantID: String
        var productName: String
        var quantity: Int
        var id: String { variantID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("order_history", fallback: "Order History"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(TallaTheme.Colors.ink)

            if isLoadingOrders {
                Text(AppLocalization.text("loading_orders", fallback: "Loading orders..."))
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
            } else if let ordersError {
                Text(ordersError)
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            } else if orders.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppLocalization.text("no_saved_orders", fallback: "No saved orders yet."))
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: browseProductsAction) {
                        Text(AppLocalization.text("browse_products", fallback: "Browse Products"))
                            .font(Font.custom("AvenirNext-Bold", size: 10))
                            .tracking(AppLocalization.letterSpacing(1.5))
                            .textCase(.uppercase)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(accentColor)
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(orders.prefix(4)) { order in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(orderStatusTitle(order.historyStatus))
                                    .font(Font.custom("AvenirNext-Bold", size: 11))
                                    .tracking(AppLocalization.letterSpacing(1.5))
                                    .foregroundColor(primaryTextColor)

                                Text(formattedOrderDate(order.createdAt))
                                    .font(Font.custom("AvenirNext-Regular", size: 12))
                                    .foregroundColor(tertiaryTextColor)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                Text(order.total)
                                    .font(Font.custom("AvenirNext-Bold", size: 11))
                                    .foregroundColor(TallaTheme.Colors.ink)

                                orderStatusBadge(order.historyStatus)
                                if order.isRefunded {
                                    Text("Refunded")
                                        .font(Font.custom("AvenirNext-DemiBold", size: 10))
                                        .foregroundColor(TallaTheme.Colors.ink)
                                }
                            }
                        }

                        if let items = order.items, !items.isEmpty {
                            Text(items.map { "\($0.name) x\($0.quantity)" }.joined(separator: " • "))
                                .font(Font.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let club = order.details?.coffeeClub {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(
                                    String(
                                        format: AppLocalization.text(
                                            "coffee_club_order_summary",
                                            fallback: "%d prepaid shipments · every %d weeks · %d%% saved"
                                        ),
                                        club.shipmentCount,
                                        club.intervalWeeks,
                                        club.discountPercent
                                    ),
                                    systemImage: "checkmark.seal.fill"
                                )
                                .font(Font.custom("AvenirNext-DemiBold", size: 12))
                                .foregroundColor(TallaTheme.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)

                                ProgressView(value: Double(club.deliveredCount), total: Double(max(1, club.shipmentCount)))
                                    .tint(TallaTheme.Colors.ink)

                                HStack {
                                    Label(
                                        String(
                                            format: AppLocalization.text("coffee_club_delivered_count", fallback: "%d delivered"),
                                            club.deliveredCount
                                        ),
                                        systemImage: "checkmark.circle.fill"
                                    )
                                    Spacer()
                                    Label(
                                        String(
                                            format: AppLocalization.text("coffee_club_remaining_count", fallback: "%d remaining"),
                                            club.remainingCount
                                        ),
                                        systemImage: "shippingbox"
                                    )
                                }
                                .font(Font.custom("AvenirNext-DemiBold", size: 11))
                                .foregroundColor(secondaryTextColor)

                                if let nextShipmentAt = club.nextShipmentAt,
                                   club.remainingCount > 0,
                                   club.lifecycleStatus != "cancelled" {
                                    Label(
                                        String(
                                            format: AppLocalization.text(
                                                club.isOverdue == true ? "coffee_club_overdue" : "coffee_club_next_shipment",
                                                fallback: club.isOverdue == true ? "Shipment %d is overdue · %@" : "Next shipment %d · %@"
                                            ),
                                            club.nextShipmentNumber ?? (club.deliveredCount + 1),
                                            formattedOrderDate(nextShipmentAt)
                                        ),
                                        systemImage: club.isOverdue == true ? "exclamationmark.triangle.fill" : "calendar.badge.clock"
                                    )
                                    .font(Font.custom("AvenirNext-DemiBold", size: 11))
                                    .foregroundColor(club.isOverdue == true ? .orange : secondaryTextColor)
                                }

                                Text(coffeeClubStatusText(club))
                                    .font(Font.custom("AvenirNext-DemiBold", size: 10))
                                    .foregroundColor(TallaTheme.Colors.ink)

                                if let coffeeName = club.preference?.coffeeName, !coffeeName.isEmpty {
                                    Label(coffeeName, systemImage: "cup.and.saucer.fill")
                                        .font(Font.custom("AvenirNext-Regular", size: 11))
                                        .foregroundColor(secondaryTextColor)
                                }

                                if !["cancelled", "completed"].contains(club.lifecycleStatus) {
                                    Button {
                                        prepareCoffeeClubManagement(order)
                                    } label: {
                                        Label(
                                            AppLocalization.text("manage_coffee_club", fallback: "Manage Coffee Club"),
                                            systemImage: "slider.horizontal.3"
                                        )
                                        .font(Font.custom("AvenirNext-Bold", size: 10))
                                        .tracking(AppLocalization.letterSpacing(1.1))
                                        .textCase(.uppercase)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.tallaSecondary)
                                    .tint(TallaTheme.Colors.ink)
                                }
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel(
                                String(
                                    format: AppLocalization.text(
                                        "coffee_club_progress_accessibility",
                                        fallback: "Coffee Club: %d of %d shipments delivered, %d remaining"
                                    ),
                                    club.deliveredCount,
                                    club.shipmentCount,
                                    club.remainingCount
                                )
                            )
                        }

                        if let pass = order.details?.cafePass {
                            VStack(alignment: .leading, spacing: 5) {
                                Label("\(pass.giftedCoffee == true ? "Coffee gift" : pass.suspendedCoffee == true ? "Suspended coffee" : "Daily cup café pass") · \(pass.remainingCredits) of \(pass.creditCount) drinks remaining", systemImage: "cup.and.saucer.fill")
                                    .font(Font.custom("AvenirNext-DemiBold", size: 12))
                                    .foregroundColor(TallaTheme.Colors.ink)
                                Text("\(pass.drinkName) · \(pass.status.replacingOccurrences(of: "_", with: " ").capitalized)\(pass.expiresAt.flatMap { formattedOrderDate($0).isEmpty ? nil : " · Expires \(formattedOrderDate($0))" } ?? "")")
                                    .font(Font.custom("AvenirNext-Regular", size: 11))
                                    .foregroundColor(secondaryTextColor)
                                if pass.status == "active", pass.remainingCredits > 0, pass.suspendedCoffee != true, !cafePassProducts.isEmpty {
                                    Menu {
                                        ForEach(cafePassProducts) { product in
                                            ForEach(product.variants.filter { variant in
                                                guard variant.isAvailableForSale,
                                                      let maximumPriceFils = pass.unitPriceFils,
                                                      maximumPriceFils > 0,
                                                      let candidatePriceFils = priceInFils(variant.price) else { return false }
                                                return candidatePriceFils <= maximumPriceFils
                                            }) { variant in
                                                Button(cafePassSwapTitle(product: product, variant: variant)) {
                                                    Task { _ = await swapCafePassAction(order, variant.id) }
                                                }
                                            }
                                        }
                                    } label: {
                                        Label("Swap drink for remaining credits", systemImage: "arrow.triangle.swap")
                                            .font(Font.custom("AvenirNext-Bold", size: 10))
                                    }
                                    .tint(TallaTheme.Colors.ink)
                                }
                                if order.isPaidForCafePass, pass.suspendedCoffee == true, pass.status == "active", pass.remainingCredits > 0 {
                                    HStack(spacing: 12) {
                                        SuspendedCoffeePassQR(orderID: order.id).frame(width: 116, height: 116)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(pass.giftedCoffee == true
                                                ? "Send this link after payment. The recipient shows the code at the Talla counter to redeem one coffee."
                                                : "Show this QR at the Talla counter. Staff will look up the pass and redeem one drink per guest.")
                                                .font(Font.custom("AvenirNext-Regular", size: 11)).foregroundColor(secondaryTextColor)
                                            ShareLink(item: suspendedCoffeeGiftLink(orderID: order.id, token: pass.giftToken), subject: Text("A coffee from Talla"), message: Text("A \(pass.drinkName) is waiting for you at the Talla counter. Show staff gift code \(order.id) to redeem it.")) {
                                                Label(pass.giftedCoffee == true ? "Share paid coffee gift" : "Share counter code", systemImage: "square.and.arrow.up").font(Font.custom("AvenirNext-DemiBold", size: 11))
                                            }.tint(TallaTheme.Colors.ink)
                                            if pass.giftedCoffee == true,
                                               let whatsappURL = coffeeGiftWhatsAppURL(orderID: order.id, drinkName: pass.drinkName, token: pass.giftToken) {
                                                Button {
                                                    openURL(whatsappURL)
                                                } label: {
                                                    Label("Send gift on WhatsApp", systemImage: "message.fill")
                                                        .font(Font.custom("AvenirNext-DemiBold", size: 11))
                                                }.tint(TallaTheme.Colors.ink)
                                            }
                                        }
                                    }
                                    .padding(10)
                                    .background(cardFillColor, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(orderNumberLabel(for: order))
                                .font(Font.custom("AvenirNext-Bold", size: 12))
                                .foregroundColor(primaryTextColor)

                            Text(orderTimingLabel(for: order))
                                .font(Font.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(secondaryTextColor)
                        }

                        Label(
                            order.isPickup
                                ? AppLocalization.text("order_method_pickup", fallback: "Pickup at Talla")
                                : AppLocalization.text("order_method_delivery", fallback: "Delivery"),
                            systemImage: order.isPickup ? "storefront.fill" : "shippingbox.fill"
                        )
                        .font(Font.custom("AvenirNext-DemiBold", size: 12))
                        .foregroundColor(TallaTheme.Colors.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(accentColor.opacity(isLightAppearance ? 0.10 : 0.16))
                        .clipShape(Capsule(style: .continuous))

                        orderProgressRow(status: order.historyStatus, isPickup: order.isPickup)

                        if let tracking = order.details?.tracking,
                           let value = tracking.url,
                           let url = URL(string: value) {
                            Link(destination: url) {
                                Label(
                                    tracking.company?.isEmpty == false
                                        ? String(format: AppLocalization.text("track_with_carrier", fallback: "Track with %@"), tracking.company ?? "")
                                        : AppLocalization.text("track_shipment", fallback: "Track Shipment"),
                                    systemImage: "shippingbox.and.arrow.backward.fill"
                                )
                                .font(Font.custom("AvenirNext-DemiBold", size: 11))
                            }
                            .buttonStyle(.tallaSecondary)
                        }

                        if order.isPickup && isReadyForPickup(status: order.historyStatus) {
                            pickupDirectionsCard
                        }

                        if let supportCase = order.details?.supportCase,
                           let status = supportCase.status,
                           !status.isEmpty {
                            Label("Case \(status.replacingOccurrences(of: "_", with: " ").capitalized)", systemImage: "checkmark.message.fill")
                                .font(Font.custom("AvenirNext-DemiBold", size: 11))
                                .foregroundColor(TallaTheme.Colors.ink)
                        }

                        if order.beansAwarded == true, let pointsAwarded = order.pointsAwarded, pointsAwarded > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .bold))
                                Text(String(format: AppLocalization.text("order_beans_awarded", fallback: "%d Beans awarded"), pointsAwarded))
                                    .font(Font.custom("AvenirNext-DemiBold", size: 12))
                            }
                            .foregroundColor(TallaTheme.Colors.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(accentColor.opacity(isLightAppearance ? 0.12 : 0.16))
                            .clipShape(Capsule(style: .continuous))
                        }

                        if let item = tasteMemoryItem(for: order) {
                            tasteMemoryPrompt(order: order, item: item)
                        }

                        if let items = order.items, !items.isEmpty {
                            Button {
                                buyAgainAction(order)
                            } label: {
                                Text(AppLocalization.text("buy_again", fallback: "Buy Again"))
                                    .font(Font.custom("AvenirNext-Bold", size: 10))
                                    .tracking(AppLocalization.letterSpacing(1.5))
                                    .textCase(.uppercase)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(accentColor)
                                    .clipShape(Capsule(style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                        Button { orderSupportAction(order) } label: {
                            Label(AppLocalization.text("help_with_order", fallback: "Help with this order"), systemImage: "message.fill")
                                .font(Font.custom("AvenirNext-DemiBold", size: 11))
                        }
                        .buttonStyle(.tallaSecondary)

                        if !["cancelled", "cancellation requested", "ready", "fulfilled", "delivered", "completed"].contains(order.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) {
                            Button {
                                Task { _ = await customerOrderAction(order, "request_cancellation") }
                            } label: {
                                Label("Request cancellation", systemImage: "xmark.circle")
                                    .font(Font.custom("AvenirNext-DemiBold", size: 11))
                            }
                            .buttonStyle(.tallaSecondary)
                        }
                    }
                    .padding(14)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .sheet(item: $managedCoffeeClubOrder) { order in
            coffeeClubManagementSheet(order)
        }
    }

    private func coffeeClubStatusText(_ club: CustomerCoffeeClub) -> String {
        switch club.lifecycleStatus {
        case "paused": return AppLocalization.text("coffee_club_status_paused", fallback: "Plan paused — schedule will move when resumed")
        case "cancel_requested": return AppLocalization.text("coffee_club_status_cancel_requested", fallback: "Cancellation requested — Talla will review it")
        case "cancelled": return AppLocalization.text("coffee_club_status_cancelled", fallback: "Plan cancelled")
        case "completed": return AppLocalization.text("coffee_club_status_completed", fallback: "All shipments completed")
        default: return AppLocalization.text("coffee_club_status_active", fallback: "Plan active")
        }
    }

    private func priceInFils(_ rawValue: String) -> Int? {
        let numeric = rawValue.replacingOccurrences(of: ",", with: "")
            .filter { $0.isNumber || $0 == "." }
        guard let amount = Double(numeric), amount >= 0 else { return nil }
        return Int((amount * 1_000).rounded())
    }

    private func cafePassSwapTitle(product: ContentView.Product, variant: ContentView.Product.Variant) -> String {
        guard product.hasVariantChoices,
              !variant.title.localizedCaseInsensitiveContains("default") else { return product.name }
        return "\(product.name) · \(variant.title)"
    }

    private func productsForCoffeeClub(_ order: ContentView.AccountOrder) -> [ContentView.Product] {
        if order.details?.coffeeClub?.planType == "office" {
            return coffeeClubProducts.filter { ["coffee-beans", "arabic-coffee-beans"].contains($0.categoryKey) }
        }
        if order.details?.coffeeClub?.planType == "arabic-coffee" {
            return coffeeClubProducts.filter { $0.categoryKey == "arabic-coffee-beans" }
        }
        if order.details?.coffeeClub?.planType == "equipment" {
            return coffeeClubProducts.filter {
                let text = $0.catalogClassificationText.lowercased()
                let consumableTerms = ["filter", "paper refill", "cleaning tablet", "cleaner", "descaler", "descaling", "backflush", "water cartridge", "فلاتر", "فلتر", "منظف", "تنظيف"]
                return $0.categoryKey == "coffee-equipment"
                    && consumableTerms.contains(where: text.contains)
            }
        }
        if order.details?.coffeeClub?.planType == "drip-bags" {
            return coffeeClubProducts.filter { $0.categoryKey == "drip-bags" }
        }
        if order.details?.coffeeClub?.planType == "filters" {
            return coffeeClubProducts.filter { ContentView.isCoffeeFilterPack($0) }
        }
        if order.details?.coffeeClub?.planType == "seasonal-box" {
            return coffeeClubProducts.filter { product in
                guard product.categoryKey == "gifts" else { return false }
                let name = product.name.lowercased()
                return ["box", "discovery", "seasonal", "صندوق", "علبة"].contains { name.contains($0) }
            }
        }
        guard order.details?.coffeeClub?.planType == "beans" || order.details?.coffeeClub?.planType == nil else {
            return []
        }
        return coffeeClubProducts.filter { ["coffee-beans", "arabic-coffee-beans"].contains($0.categoryKey) }
    }

    private func prepareCoffeeClubManagement(_ order: ContentView.AccountOrder) {
        guard let club = order.details?.coffeeClub else { return }
        selectedCoffeeName = club.preference?.coffeeName ?? ""
        selectedCoffeeVariantID = club.preference?.variantId ?? ""
        let storedItems = club.coffeeItems ?? []
        if storedItems.isEmpty {
            selectedClubCoffees = selectedCoffeeVariantID.isEmpty ? [] : [
                EditableClubCoffee(variantID: selectedCoffeeVariantID, productName: selectedCoffeeName, quantity: 1)
            ]
        } else {
            selectedClubCoffees = storedItems.compactMap { item in
                guard let variantID = item.variantId, !variantID.isEmpty else { return nil }
                return EditableClubCoffee(
                    variantID: variantID,
                    productName: item.coffeeName ?? "Coffee",
                    quantity: max(1, min(item.quantity ?? 1, 12))
                )
            }
        }
        selectedAddressID = deliveryAddresses.first(where: { address in
            address.line1 == club.fulfillmentOverride?.line1 && address.city == club.fulfillmentOverride?.city
        })?.id ?? deliveryAddresses.first(where: \.isPreferred)?.id ?? deliveryAddresses.first?.id ?? ""
        selectedFulfillment = order.isPickup ? .pickup : .delivery
        managementNote = club.cancellationReason ?? club.refundNote ?? ""
        managedCoffeeClubOrder = order
    }

    private func coffeeClubManagementSheet(_ order: ContentView.AccountOrder) -> some View {
        NavigationStack {
            Form {
                if let club = order.details?.coffeeClub {
                    Section(AppLocalization.text("coffee_club_schedule", fallback: "Schedule")) {
                        LabeledContent(AppLocalization.text("status", fallback: "Status"), value: coffeeClubStatusText(club))
                        if let office = club.officeDetails {
                            LabeledContent("Company", value: office.companyName ?? "—")
                            if let reference = office.purchaseOrderReference, !reference.isEmpty {
                                LabeledContent("Purchase order", value: reference)
                            }
                            if let vat = office.vatRegistrationNumber, !vat.isEmpty {
                                LabeledContent("VAT number", value: vat)
                            }
                            if let cr = office.commercialRegistrationNumber, !cr.isEmpty {
                                LabeledContent("Commercial registration", value: cr)
                            }
                        }
                        if let next = club.nextShipmentAt, club.remainingCount > 0 {
                            LabeledContent(
                                AppLocalization.text("next_shipment", fallback: "Next shipment"),
                                value: formattedOrderDate(next)
                            )
                        }
                    }

                    Section(AppLocalization.text("future_shipments", fallback: "Future shipments")) {
                        ForEach($selectedClubCoffees) { $coffee in
                            HStack(spacing: 10) {
                                Picker(AppLocalization.text("coffee", fallback: "Coffee"), selection: $coffee.variantID) {
                                    ForEach(productsForCoffeeClub(order)) { product in
                                        ForEach(product.variants.filter(\.isAvailableForSale)) { variant in
                                            Text(product.hasVariantChoices ? "\(product.name) · \(variant.title)" : product.name)
                                                .tag(variant.id)
                                        }
                                    }
                                }
                                Stepper("×\(coffee.quantity)", value: $coffee.quantity, in: 1...12)
                                    .labelsHidden()
                                Button {
                                    selectedClubCoffees.removeAll { $0.id == coffee.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(AppLocalization.text("remove_coffee", fallback: "Remove coffee"))
                            }
                        }

                        Button {
                            guard let nextVariant = productsForCoffeeClub(order)
                                .flatMap({ $0.variants.filter(\.isAvailableForSale) })
                                .first(where: { variant in !selectedClubCoffees.contains(where: { $0.variantID == variant.id }) }) else { return }
                            let productName = productsForCoffeeClub(order).first(where: { product in product.variants.contains(where: { $0.id == nextVariant.id }) })?.name ?? "Coffee"
                            selectedClubCoffees.append(EditableClubCoffee(variantID: nextVariant.id, productName: productName, quantity: 1))
                        } label: {
                            Label(AppLocalization.text("add_another_coffee", fallback: "Add another coffee"), systemImage: "plus.circle.fill")
                        }
                        .disabled(selectedClubCoffees.count >= 6)

                        Picker(AppLocalization.text("fulfillment", fallback: "Fulfilment"), selection: $selectedFulfillment) {
                            Text(AppLocalization.text("delivery", fallback: "Delivery")).tag(TallaFulfillmentMethod.delivery)
                            Text(AppLocalization.text("pickup_at_talla", fallback: "Pickup at Talla")).tag(TallaFulfillmentMethod.pickup)
                        }
                        .pickerStyle(.segmented)

                        if selectedFulfillment == .delivery && !deliveryAddresses.isEmpty {
                            Picker(AppLocalization.text("delivery_address", fallback: "Delivery address"), selection: $selectedAddressID) {
                                ForEach(deliveryAddresses.filter { $0.country == .bahrain }) { address in
                                    Text("\(address.label) · \(address.line1)").tag(address.id)
                                }
                            }
                        }

                        Text(selectedFulfillment == .pickup
                             ? AppLocalization.text("coffee_club_pickup_note", fallback: "Collect future shipments from Talla in Riffa when they are ready.")
                             : AppLocalization.text("coffee_club_delivery_note", fallback: "Future shipments will use your selected Bahrain address."))
                            .font(.caption)

                        Text(AppLocalization.text(
                            "coffee_club_future_changes_note",
                            fallback: "Coffee and address changes apply only to shipments that have not been prepared yet."
                        ))
                        .font(.caption)

                        if let effectiveShipment = club.changesEffectiveFromShipment {
                            Text(
                                String(
                                    format: AppLocalization.text(
                                        "coffee_club_changes_effective",
                                        fallback: "Your saved choices apply from shipment %d."
                                    ),
                                    effectiveShipment
                                )
                            )
                            .font(.caption.bold())
                            .foregroundColor(TallaTheme.Colors.ink)
                        }

                        Button(AppLocalization.text("save_future_choices", fallback: "Save Future Choices")) {
                            performCoffeeClubAction(order, action: "update_preferences")
                        }
                        .disabled(isManagingCoffeeClub || selectedClubCoffees.isEmpty)
                    }

                    Section(AppLocalization.text("plan_controls", fallback: "Plan controls")) {
                        if club.lifecycleStatus == "paused" {
                            Button(AppLocalization.text("resume_plan", fallback: "Resume Plan")) {
                                performCoffeeClubAction(order, action: "resume")
                            }
                        } else if club.lifecycleStatus == "active" {
                            Button(AppLocalization.text("skip_next_shipment", fallback: "Skip Next Shipment")) {
                                performCoffeeClubAction(order, action: "skip_next")
                            }
                            .disabled(isManagingCoffeeClub)

                            Button(AppLocalization.text("pause_plan", fallback: "Pause Plan")) {
                                performCoffeeClubAction(order, action: "pause")
                            }
                        }

                        TextField(
                            AppLocalization.text("request_reason", fallback: "Reason or note"),
                            text: $managementNote,
                            axis: .vertical
                        )

                        Button(AppLocalization.text("request_cancellation", fallback: "Request Cancellation"), role: .destructive) {
                            performCoffeeClubAction(order, action: "request_cancel")
                        }
                        .disabled(club.lifecycleStatus == "cancel_requested" || isManagingCoffeeClub)

                        Button(AppLocalization.text("request_refund", fallback: "Request Refund")) {
                            performCoffeeClubAction(order, action: "request_refund")
                        }
                        .disabled(club.refundStatus == "requested" || club.refundStatus == "pending" || club.refundStatus == "recorded" || isManagingCoffeeClub)

                        if let refundStatus = club.refundStatus, refundStatus != "none" {
                            LabeledContent(
                                AppLocalization.text("refund_status", fallback: "Refund status"),
                                value: refundStatus.replacingOccurrences(of: "_", with: " ").capitalized
                            )
                        }
                    }
                }
            }
            .navigationTitle(AppLocalization.text("manage_coffee_club", fallback: "Manage Coffee Club"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("done", fallback: "Done")) { managedCoffeeClubOrder = nil }
                }
            }
            .overlay { if isManagingCoffeeClub { ProgressView() } }
        }
    }

    private func performCoffeeClubAction(_ order: ContentView.AccountOrder, action: String) {
        guard !isManagingCoffeeClub else { return }
        isManagingCoffeeClub = true
        let address = selectedFulfillment == .delivery ? deliveryAddresses.first { $0.id == selectedAddressID } : nil
        Task {
            let coffeeItems = selectedClubCoffees.map { coffee in
                let productName = productsForCoffeeClub(order).first(where: { product in
                    product.variants.contains(where: { $0.id == coffee.variantID })
                })?.name ?? coffee.productName
                return (name: productName, variantID: coffee.variantID, quantity: coffee.quantity)
            }
            let firstCoffee = selectedClubCoffees.first
            let succeeded = await manageCoffeeClubAction(
                order,
                action,
                managementNote,
                firstCoffee?.productName ?? selectedCoffeeName,
                firstCoffee?.variantID ?? selectedCoffeeVariantID,
                coffeeItems,
                address,
                selectedFulfillment
            )
            await MainActor.run {
                isManagingCoffeeClub = false
                if succeeded { managedCoffeeClubOrder = nil }
            }
        }
    }

    private var pickupDirectionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("pickup_ready_title", fallback: "Ready for pickup at Talla"))
                        .font(Font.custom("AvenirNext-Bold", size: 13))
                        .foregroundColor(primaryTextColor)

                    Text(AppLocalization.text("pickup_address", fallback: "Villa 336, Street 1307, Riffa 913"))
                        .font(Font.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: pickupDirectionsAction) {
                Label(AppLocalization.text("open_directions", fallback: "Open Directions"), systemImage: "map.fill")
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(AppLocalization.letterSpacing(1.2))
                    .textCase(.uppercase)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(accentColor)
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(accentColor.opacity(isLightAppearance ? 0.08 : 0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.18 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func isReadyForPickup(status: String) -> Bool {
        status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "ready"
    }

    private func tasteMemoryItem(for order: ContentView.AccountOrder) -> ContentView.AccountOrder.Item? {
        guard isTasteMemoryEligible(status: order.status), let items = order.items else { return nil }
        return items.first
    }

    private func tasteMemoryPrompt(order: ContentView.AccountOrder, item: ContentView.AccountOrder.Item) -> some View {
        let key = tasteMemoryKey(order: order, item: item)
        let existing = tasteMemoryLookup[key]

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: AppLocalization.text("taste_memory_question", fallback: "How was your %@?"), item.name))
                        .font(Font.custom("AvenirNext-Bold", size: 13))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(existing == nil
                        ? AppLocalization.text("taste_memory_detail", fallback: "Your answer helps Talla improve future recommendations.")
                        : AppLocalization.text("taste_memory_saved_detail", fallback: "Saved. Talla will use this for future recommendations."))
                        .font(Font.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                tasteReactionButton(
                    title: AppLocalization.text("loved_it", fallback: "Loved it"),
                    systemImage: "heart.fill",
                    isSelected: existing?.reaction == "loved"
                ) {
                    saveTasteMemoryAction(order, item, "loved", existing?.tags ?? [])
                }

                tasteReactionButton(
                    title: AppLocalization.text("not_for_me", fallback: "Not for me"),
                    systemImage: "hand.thumbsdown.fill",
                    isSelected: existing?.reaction == "not-for-me"
                ) {
                    saveTasteMemoryAction(order, item, "not-for-me", existing?.tags ?? [])
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 7)], spacing: 7) {
                ForEach(tasteTagOptions, id: \.self) { tag in
                    tasteTagButton(tag: tag, isSelected: existing?.tags.contains(tag) == true) {
                        let currentTags = existing?.tags ?? []
                        let updatedTags = currentTags.contains(tag)
                            ? currentTags.filter { $0 != tag }
                            : currentTags + [tag]
                        saveTasteMemoryAction(order, item, existing?.reaction ?? "loved", updatedTags)
                    }
                }
            }
        }
        .padding(12)
        .background(accentColor.opacity(isLightAppearance ? 0.08 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var tasteTagOptions: [String] {
        ["Chocolate", "Fruity", "Floral", "Caramel", "Citrus", "Nutty"]
    }

    private func tasteReactionButton(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(AppLocalization.letterSpacing(1.0))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(isSelected ? Color(hex: 0x151515) : primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? accentColor : cardFillColor)
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func tasteTagButton(tag: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(tag)
                .font(Font.custom("AvenirNext-Bold", size: 9))
                .tracking(AppLocalization.letterSpacing(0.8))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(isSelected ? .white : TallaTheme.Colors.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? accentColor : accentColor.opacity(isLightAppearance ? 0.10 : 0.14))
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func orderProgressRow(status: String, isPickup: Bool) -> some View {
        let currentIndex = orderStatusStepIndex(status)
        let steps = orderStatusSteps(for: status, isPickup: isPickup)

        return VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                let trackWidth = max(proxy.size.width - 28, 1)
                let progress = CGFloat(currentIndex) / CGFloat(max(steps.count - 1, 1))
                let bagOffset = trackWidth * progress

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(secondaryTextColor.opacity(0.16))
                        .frame(height: 5)
                        .padding(.horizontal, 14)

                    Capsule(style: .continuous)
                        .fill(accentColor.opacity(0.82))
                        .frame(width: 28 + bagOffset, height: 5)
                        .padding(.leading, 14)
                        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: currentIndex)

                    HStack(spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.element.key) { index, _ in
                            ZStack {
                                Circle()
                                    .fill(index <= currentIndex ? accentColor : cardFillColor)
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Circle()
                                            .stroke(index <= currentIndex ? accentColor : secondaryTextColor.opacity(0.26), lineWidth: 1)
                                    )

                                if index < currentIndex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    coffeeBagMarker
                        .offset(x: bagOffset, y: -15)
                        .animation(.spring(response: 0.42, dampingFraction: 0.72), value: currentIndex)
                }
            }
            .frame(height: 42)

            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.key) { index, step in
                    Text(step.title)
                        .font(Font.custom("AvenirNext-DemiBold", size: 8))
                        .foregroundColor(index <= currentIndex ? primaryTextColor : tertiaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(accentColor.opacity(isLightAppearance ? 0.07 : 0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel(AppLocalization.text("order_status_progress", fallback: "Order status progress"))
        .accessibilityValue(orderStatusTitle(status))
    }

    private func orderStatusSteps(for status: String, isPickup: Bool) -> [(key: String, title: String)] {
        var steps = [
            ("received", AppLocalization.text("order_step_received", fallback: "Received")),
            ("roasting", AppLocalization.text("order_step_roasting", fallback: "Roasting")),
            ("resting", AppLocalization.text("order_step_resting", fallback: "Resting")),
            ("packed", AppLocalization.text("order_step_packed", fallback: "Packed")),
            ("on-the-way", AppLocalization.text("order_step_on_the_way", fallback: "On its way"))
        ]

        if isPickup {
            steps[4] = ("pickup-ready", AppLocalization.text("order_status_ready_pickup", fallback: "Ready for pickup"))
        }

        if isPickup && status == "collected" {
            steps[4] = ("collected", AppLocalization.text("order_status_collected", fallback: "Collected"))
        }
        return steps
    }

    private func orderStatusStepIndex(_ status: String) -> Int {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "confirmed", "preparing", "roasting", "in progress":
            return 1
        case "resting":
            return 2
        case "packed":
            return 3
        case "collected", "ready", "completed", "fulfilled", "shipped", "on its way", "out for delivery", "delivered":
            return 4
        case "cancelled", "canceled":
            return 0
        default:
            return 0
        }
    }

    private func isTasteMemoryEligible(status: String) -> Bool {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "completed", "fulfilled", "delivered":
            return true
        default:
            return false
        }
    }

    private func tasteMemoryKey(order: ContentView.AccountOrder, item: ContentView.AccountOrder.Item) -> String {
        "\(order.id)-\(normalizedProductName(item.name))"
    }

    private func normalizedProductName(_ name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private var coffeeBagMarker: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(accentColor)
                .frame(width: 28, height: 30)
                .shadow(color: Color.black.opacity(isLightAppearance ? 0.12 : 0.30), radius: 6, x: 0, y: 4)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: 0x151515).opacity(0.12))
                .frame(width: 16, height: 4)
                .offset(y: -8)

            Image(systemName: "leaf.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: 0x151515))
                .offset(y: 3)
        }
        .frame(width: 28, height: 30)
    }

    private func orderStatusBadge(_ status: String) -> some View {
        let normalized = status.trimmingCharacters(in: .whitespacesAndNewlines)
        let color = orderStatusColor(normalized)

        return Text(orderStatusTitle(normalized))
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .tracking(AppLocalization.letterSpacing(1.2))
            .textCase(.uppercase)
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(color.opacity(isLightAppearance ? 0.12 : 0.18))
            .clipShape(Capsule(style: .continuous))
    }

    private func orderStatusTitle(_ status: String) -> String {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "collected":
            return AppLocalization.text("order_status_collected", fallback: "Collected")
        case "pending":
            return AppLocalization.text("order_status_placed", fallback: "Order placed")
        case "confirmed":
            return AppLocalization.text("order_status_confirmed", fallback: "Confirmed")
        case "preparing", "roasting", "resting":
            return AppLocalization.text("order_status_preparing", fallback: "Preparing")
        case "packed":
            return AppLocalization.text("order_step_packed", fallback: "Packed")
        case "on its way", "out for delivery", "shipped":
            return AppLocalization.text("order_step_on_the_way", fallback: "On its way")
        case "ready":
            return AppLocalization.text("order_status_ready_pickup", fallback: "Ready for pickup")
        case "completed", "fulfilled":
            return AppLocalization.text("order_status_completed", fallback: "Completed")
        case "delivered":
            return AppLocalization.text("delivered", fallback: "Delivered")
        case "cancelled", "canceled":
            return AppLocalization.text("order_status_cancelled", fallback: "Cancelled")
        default:
            return AppLocalization.text("order_status_received", fallback: "Order received")
        }
    }

    private func formattedOrderDate(_ value: String) -> String {
        let normalized = value
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = .current

        for format in ["yyyy-MM-dd HH:mm:ss.SSS", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
            parser.dateFormat = format
            if let date = parser.date(from: normalized) {
                return displayOrderDate(date)
            }
        }

        let isoParser = ISO8601DateFormatter()
        isoParser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoParser.date(from: value) {
            return displayOrderDate(date)
        }

        return normalized
    }

    private func displayOrderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppLocalization.currentLanguage.localeIdentifier)
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy h:mm a")
        return formatter.string(from: date)
    }

    private func orderNumberLabel(for order: ContentView.AccountOrder) -> String {
        for candidate in [order.title, order.id] {
            let digits = candidate.filter(\.isNumber)
            if !digits.isEmpty {
                return String(format: AppLocalization.text("order_number_format", fallback: "Order #%@"), String(digits.suffix(6)))
            }
        }

        return String(format: AppLocalization.text("order_number_format", fallback: "Order #%@"), String(order.id.prefix(6)))
    }

    private func orderTimingLabel(for order: ContentView.AccountOrder) -> String {
        if order.isPickup {
            switch order.historyStatus {
            case "ready":
                return AppLocalization.text("pickup_ready_now", fallback: "Pickup available now")
            case "collected":
                return AppLocalization.text("order_pickup_collected", fallback: "Collected from Talla")
            case "cancelled", "canceled":
                return AppLocalization.text("order_status_cancelled", fallback: "Cancelled")
            default:
                return AppLocalization.text("order_pickup_wait", fallback: "We'll let you know when your order is ready for pickup.")
            }
        }

        return String(
            format: AppLocalization.text("estimated_delivery_format", fallback: "Estimated delivery: %@"),
            estimatedDeliveryLabel(for: order)
        )
    }

    private func estimatedDeliveryLabel(for order: ContentView.AccountOrder) -> String {
        switch order.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "completed", "fulfilled", "delivered":
            return AppLocalization.text("delivered", fallback: "Delivered")
        case "cancelled", "canceled":
            return AppLocalization.text("order_status_cancelled", fallback: "Cancelled")
        default:
            return AppLocalization.text("tomorrow", fallback: "Tomorrow")
        }
    }

    private func orderStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "collected", "completed", "fulfilled":
            return Color(hex: 0x4F8A5B)
        case "ready":
            return Color(hex: 0x2F7E8B)
        case "preparing", "confirmed":
            return accentColor
        case "cancelled", "canceled":
            return Color.red.opacity(0.8)
        default:
            return secondaryTextColor
        }
    }
}

private func suspendedCoffeeGiftLink(orderID: String, token: String? = nil) -> URL {
    var components = URLComponents(string: "https://talla.me/pages/coffee-gift")!
    components.queryItems = [URLQueryItem(name: "order", value: orderID)]
    if let token, !token.isEmpty { components.fragment = token }
    return components.url!
}

private func coffeeGiftWhatsAppURL(orderID: String, drinkName: String, token: String?) -> URL? {
    var components = URLComponents(string: "https://wa.me/")
    components?.queryItems = [URLQueryItem(
        name: "text",
        value: "I sent you a \(drinkName) from Talla ☕️ Show staff gift code \(orderID) at the counter: \(suspendedCoffeeGiftLink(orderID: orderID, token: token).absoluteString)"
    )]
    return components?.url
}

private struct SuspendedCoffeePassQR: View {
    let orderID: String

    private var code: CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(orderID.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else { return nil }
        return CIContext().createCGImage(output, from: output.extent)
    }

    var body: some View {
        Group {
            if let code { Image(decorative: code, scale: 1).interpolation(.none).resizable().scaledToFit().padding(5).background(.white, in: RoundedRectangle(cornerRadius: 8)) }
            else { Image(systemName: "qrcode").resizable().scaledToFit().padding(20) }
        }
        .accessibilityLabel("Suspended coffee counter code for order \(orderID)")
    }
}
