import SwiftUI

struct ProfileManagementSectionView: View {
    let primaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let isLightAppearance: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    let isSaving: Bool
    let saveAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            HStack(spacing: 10) {
                styledTextField("First name", text: $firstName)
                styledTextField("Last name", text: $lastName)
            }

            Button(action: saveAction) {
                Text(isSaving ? "SAVING..." : "SAVE PROFILE")
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .glassEffect(.regular.tint(accentColor).interactive(), in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(isSaving || firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            Text("Password")
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            secureField("Current password", text: $currentPassword)

            HStack(spacing: 10) {
                secureField("New password", text: $newPassword)
                secureField("Confirm new", text: $confirmPassword)
            }

            Button(action: resetAction) {
                Text(isResetting ? "UPDATING..." : "UPDATE PASSWORD")
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
    let buyAgainAction: (ContentView.AccountOrder) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order History")
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            if isLoadingOrders {
                Text("Loading orders...")
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
            } else if let ordersError {
                Text(ordersError)
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            } else if orders.isEmpty {
                Text("No saved orders yet.")
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
            } else {
                ForEach(orders.prefix(4)) { order in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.title)
                                    .font(Font.custom("AvenirNext-Bold", size: 11))
                                    .tracking(1.5)
                                    .foregroundColor(primaryTextColor)

                                Text(order.createdAt.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: ""))
                                    .font(Font.custom("AvenirNext-Regular", size: 12))
                                    .foregroundColor(tertiaryTextColor)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(order.total)
                                    .font(Font.custom("AvenirNext-Bold", size: 11))
                                    .foregroundColor(accentColor)
                                Text(order.status)
                                    .font(Font.custom("AvenirNext-Regular", size: 12))
                                    .foregroundColor(secondaryTextColor)
                            }
                        }

                        if let items = order.items, !items.isEmpty {
                            Text(items.map { "\($0.name) x\($0.quantity)" }.joined(separator: " • "))
                                .font(Font.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let items = order.items, !items.isEmpty {
                            Button {
                                buyAgainAction(order)
                            } label: {
                                Text("Buy Again")
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
}
