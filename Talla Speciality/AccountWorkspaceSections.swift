import SwiftUI

struct ProfileManagementSectionView: View {
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let isLightAppearance: Bool
    @Binding var firstName: String
    @Binding var lastName: String
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
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Spacer(minLength: 8)

                if hasSavedName && !isEditingName {
                    Button {
                        isEditingName = true
                    } label: {
                        Label(AppLocalization.text("edit_name", fallback: "Edit Name"), systemImage: "pencil")
                            .font(Font.custom("AvenirNext-DemiBold", size: 10))
                            .foregroundColor(accentColor)
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
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0x0A0804))
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
                        .foregroundColor(accentColor)

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
                    .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
            )
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
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

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
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(cardFillColor)
                    .overlay(
                        Capsule()
                            .stroke(accentColor.opacity(0.18), lineWidth: 1)
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
                    .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct OrderHistorySectionView: View {
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
    let buyAgainAction: (ContentView.AccountOrder) -> Void
    let saveTasteMemoryAction: (ContentView.AccountOrder, ContentView.AccountOrder.Item, String, [String]) -> Void
    let pickupDirectionsAction: () -> Void
    let browseProductsAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("order_history", fallback: "Order History"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

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
                            .tracking(1.5)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
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
                        .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(orders.prefix(4)) { order in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(orderStatusTitle(order.status))
                                    .font(Font.custom("AvenirNext-Bold", size: 11))
                                    .tracking(1.5)
                                    .foregroundColor(primaryTextColor)

                                Text(formattedOrderDate(order.createdAt))
                                    .font(Font.custom("AvenirNext-Regular", size: 12))
                                    .foregroundColor(tertiaryTextColor)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                Text(order.total)
                                    .font(Font.custom("AvenirNext-Bold", size: 11))
                                    .foregroundColor(accentColor)

                                orderStatusBadge(order.status)
                            }
                        }

                        if let items = order.items, !items.isEmpty {
                            Text(items.map { "\($0.name) x\($0.quantity)" }.joined(separator: " • "))
                                .font(Font.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(orderNumberLabel(for: order))
                                .font(Font.custom("AvenirNext-Bold", size: 12))
                                .foregroundColor(primaryTextColor)

                            Text(orderTimingLabel(for: order))
                                .font(Font.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(secondaryTextColor)
                        }

                        orderProgressRow(status: order.status)

                        if isReadyForPickup(status: order.status) {
                            pickupDirectionsCard
                        }

                        if order.beansAwarded == true, let pointsAwarded = order.pointsAwarded, pointsAwarded > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11, weight: .bold))
                                Text(String(format: AppLocalization.text("order_beans_awarded", fallback: "%d Beans awarded"), pointsAwarded))
                                    .font(Font.custom("AvenirNext-DemiBold", size: 12))
                            }
                            .foregroundColor(accentColor)
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
                                    .tracking(1.5)
                                    .textCase(.uppercase)
                                    .foregroundColor(Color(hex: 0x0A0804))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(accentColor)
                                    .clipShape(Capsule(style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var pickupDirectionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
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
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
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
                .stroke(accentColor.opacity(isLightAppearance ? 0.18 : 0.12), lineWidth: 1)
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
                    .foregroundColor(Color(hex: 0x0A0804))
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
                .tracking(1.0)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
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
                .tracking(0.8)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? accentColor : accentColor.opacity(isLightAppearance ? 0.10 : 0.14))
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func orderProgressRow(status: String) -> some View {
        let currentIndex = orderStatusStepIndex(status)
        let steps = orderStatusSteps(for: status)

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
                                        .foregroundColor(Color(hex: 0x0A0804))
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

    private func orderStatusSteps(for status: String) -> [(key: String, title: String)] {
        var steps = [
            ("received", AppLocalization.text("order_step_received", fallback: "Received")),
            ("roasting", AppLocalization.text("order_step_roasting", fallback: "Roasting")),
            ("resting", AppLocalization.text("order_step_resting", fallback: "Resting")),
            ("packed", AppLocalization.text("order_step_packed", fallback: "Packed")),
            ("on-the-way", AppLocalization.text("order_step_on_the_way", fallback: "On its way"))
        ]

        if isReadyForPickup(status: status) {
            steps[4] = ("pickup-ready", AppLocalization.text("order_status_ready_pickup", fallback: "Ready for pickup"))
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
        case "ready", "completed", "fulfilled", "shipped", "on its way", "out for delivery", "delivered":
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
                .fill(Color(hex: 0x0A0804).opacity(0.12))
                .frame(width: 16, height: 4)
                .offset(y: -8)

            Image(systemName: "leaf.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: 0x0A0804))
                .offset(y: 3)
        }
        .frame(width: 28, height: 30)
    }

    private func orderStatusBadge(_ status: String) -> some View {
        let normalized = status.trimmingCharacters(in: .whitespacesAndNewlines)
        let color = orderStatusColor(normalized)

        return Text(orderStatusTitle(normalized))
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(color.opacity(isLightAppearance ? 0.12 : 0.18))
            .clipShape(Capsule(style: .continuous))
    }

    private func orderStatusTitle(_ status: String) -> String {
        switch status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
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
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMMM yyyy · h:mm a"
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
        if isReadyForPickup(status: order.status) {
            return AppLocalization.text("pickup_ready_now", fallback: "Pickup available now")
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
        case "completed", "fulfilled":
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
