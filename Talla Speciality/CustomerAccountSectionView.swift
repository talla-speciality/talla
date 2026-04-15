import SwiftUI

struct CustomerAccountSectionView: View {
    let isCompact: Bool
    let isLightAppearance: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let cardFillColor: Color
    let elevatedSurfaceColor: Color
    let accentColor: Color
    let labelFont: Font
    let titleFont: Font
    let bodyFont: Font
    let sectionTitleFont: Font
    @Binding var accountAuthMode: ContentView.AccountAuthMode
    @Binding var accountFirstName: String
    @Binding var accountLastName: String
    @Binding var accountEmail: String
    @Binding var accountPassword: String
    @Binding var accountConfirmPassword: String
    let isSigningIn: Bool
    let isCreatingAccount: Bool
    let isLoadingCustomer: Bool
    let customerAuthError: String?
    let customerProfile: ContentView.ShopifyCustomerProfile?
    let primaryActionTitle: String
    let toggleModeAction: (ContentView.AccountAuthMode) -> Void
    let submitAction: () -> Void
    let signedInContent: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Account")
                .font(labelFont)
                .tracking(4)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            VStack(alignment: .leading, spacing: 12) {
                Text("CUSTOMER SIGN IN")
                    .font(titleFont)
                    .foregroundColor(primaryTextColor)

                Text(accountAuthMode == .createAccount
                    ? "Create one account for checkout, rewards, and saved details."
                    : "Sign in once to access rewards, saved addresses, and order history.")
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if customerProfile != nil {
                signedInContent
            } else {
                signInForm
            }

            if let customerAuthError {
                Text(customerAuthError)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(22)
        .background(elevatedSurfaceColor.opacity(isLightAppearance ? 0.86 : 0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .glassEffect(
            .regular.tint(Color(hex: 0x3D1F00).opacity(0.18)),
            in: .rect(cornerRadius: 28)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var signInForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                accountModeButton(title: "Sign In", mode: .signIn)
                accountModeButton(title: "Create Account", mode: .createAccount)
            }

            if accountAuthMode == .createAccount {
                HStack(spacing: 10) {
                    styledTextField("First name", text: $accountFirstName, capitalization: .words)
                    styledTextField("Last name", text: $accountLastName, capitalization: .words)
                }
            }

            styledTextField("Email address", text: $accountEmail, capitalization: .never, keyboardType: .emailAddress)

            SecureField("Password", text: $accountPassword)
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

            if accountAuthMode == .createAccount {
                SecureField("Confirm password", text: $accountConfirmPassword)
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

            Button(action: submitAction) {
                Text(primaryActionTitle)
                    .font(Font.custom("AvenirNext-Bold", size: 12))
                    .tracking(2.5)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassEffect(.regular.tint(accentColor).interactive(), in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitDisabled)

            HStack(spacing: 16) {
                Button(accountAuthMode == .createAccount ? "Already Have an Account?" : "Create Account") {
                    toggleModeAction(accountAuthMode == .createAccount ? .signIn : .createAccount)
                }
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(accentColor)
                .buttonStyle(.plain)

                if accountAuthMode == .signIn {
                    Text("Fast access for checkout and rewards")
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.8)
                        .foregroundColor(secondaryTextColor)
                }
            }
        }
    }

    private var isSubmitDisabled: Bool {
        isSigningIn ||
        isCreatingAccount ||
        isLoadingCustomer ||
        accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        accountPassword.isEmpty ||
        (accountAuthMode == .createAccount && (
            accountFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            accountLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            accountConfirmPassword.isEmpty
        ))
    }

    private func accountModeButton(title: String, mode: ContentView.AccountAuthMode) -> some View {
        let isSelected = accountAuthMode == mode

        return Button {
            toggleModeAction(mode)
        } label: {
            Text(title)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : secondaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isSelected ? accentColor : cardFillColor)
                )
                .overlay(
                    Capsule()
                        .stroke(accentColor.opacity(isSelected ? 0 : 0.16), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func styledTextField(
        _ title: String,
        text: Binding<String>,
        capitalization: TextInputAutocapitalization,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(capitalization)
            .keyboardType(keyboardType)
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
