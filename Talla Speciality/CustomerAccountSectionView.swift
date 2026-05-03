import SwiftUI
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

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
    let isResettingPassword: Bool
    let isRequestingPasswordResetLink: Bool
    let isSigningInWithApple: Bool
    let isLoadingCustomer: Bool
    let customerAuthError: String?
    let customerProfile: ContentView.ShopifyCustomerProfile?
    let primaryActionTitle: String
    let toggleModeAction: (ContentView.AccountAuthMode) -> Void
    let submitAction: () -> Void
    let requestPasswordResetLinkAction: () -> Void
#if canImport(AuthenticationServices)
    let configureAppleSignInRequest: (ASAuthorizationAppleIDRequest) -> Void
    let handleAppleSignInResult: (Result<ASAuthorization, Error>) -> Void
#endif
    let signedInContent: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(AppLocalization.text("account_title", fallback: "Account"))
                .font(labelFont)
                .tracking(4)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            VStack(alignment: .leading, spacing: 12) {
                Text(AppLocalization.text("customer_sign_in", fallback: "CUSTOMER SIGN IN"))
                    .font(titleFont)
                    .foregroundColor(primaryTextColor)

                Text(accountAuthMode == .createAccount
                    ? AppLocalization.text("account_create_copy", fallback: "Create one account for checkout, rewards, and saved details.")
                    : accountAuthMode == .changePassword
                        ? AppLocalization.text("account_change_password_copy", fallback: "Change your password without restoring a signed-in session first.")
                        : AppLocalization.text("account_sign_in_copy", fallback: "Sign in once to access rewards, saved addresses, and order history."))
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
                accountModeButton(title: AppLocalization.text("sign_in", fallback: "Sign In"), mode: .signIn)
                accountModeButton(title: AppLocalization.text("create_account", fallback: "Create Account"), mode: .createAccount)
                accountModeButton(title: AppLocalization.text("change_password", fallback: "Change Password"), mode: .changePassword)
            }

            if accountAuthMode == .createAccount {
                HStack(spacing: 10) {
                    styledTextField(AppLocalization.text("first_name", fallback: "First name"), text: $accountFirstName, capitalization: .words)
                    styledTextField(AppLocalization.text("last_name", fallback: "Last name"), text: $accountLastName, capitalization: .words)
                }
            }

            styledTextField(AppLocalization.text("email_address", fallback: "Email address"), text: $accountEmail, capitalization: .never, keyboardType: .emailAddress)

            SecureField(accountAuthMode == .changePassword ? AppLocalization.text("current_password", fallback: "Current password") : AppLocalization.text("password", fallback: "Password"), text: $accountPassword)
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

            if accountAuthMode != .signIn {
                SecureField(accountAuthMode == .changePassword ? AppLocalization.text("new_password", fallback: "New password") : AppLocalization.text("confirm_password", fallback: "Confirm password"), text: $accountConfirmPassword)
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

#if canImport(AuthenticationServices)
            if accountAuthMode != .changePassword {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(accentColor.opacity(0.16))
                            .frame(height: 1)

                        Text(AppLocalization.text("or_continue_with", fallback: "or continue with"))
                            .font(Font.custom("AvenirNext-Regular", size: 11))
                            .foregroundColor(secondaryTextColor)

                        Rectangle()
                            .fill(accentColor.opacity(0.16))
                            .frame(height: 1)
                    }

                    SignInWithAppleButton(accountAuthMode == .createAccount ? .signUp : .signIn) { request in
                        configureAppleSignInRequest(request)
                    } onCompletion: { result in
                        handleAppleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(isLightAppearance ? .black : .white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(isAppleSignInDisabled)

                    if isSigningInWithApple {
                        Text(AppLocalization.text("signing_in_with_apple", fallback: "Signing in with Apple..."))
                            .font(Font.custom("AvenirNext-Regular", size: 11))
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }
#endif

            HStack(spacing: 16) {
                if accountAuthMode == .signIn {
                    Text(AppLocalization.text("fast_access_checkout", fallback: "Fast access for checkout and rewards"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.8)
                        .foregroundColor(secondaryTextColor)

                    Spacer(minLength: 0)

                    Button(isRequestingPasswordResetLink ? AppLocalization.text("sending_link", fallback: "Sending Link...") : AppLocalization.text("email_reset_link", fallback: "Email Reset Link")) {
                        requestPasswordResetLinkAction()
                    }
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
                    .buttonStyle(.plain)
                    .disabled(isResetLinkDisabled)
                } else {
                    Button(accountAuthMode == .createAccount ? AppLocalization.text("already_have_account", fallback: "Already Have an Account?") : AppLocalization.text("back_to_sign_in", fallback: "Back to Sign In")) {
                        toggleModeAction(.signIn)
                    }
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var isSubmitDisabled: Bool {
        isSigningIn ||
        isSigningInWithApple ||
        isResettingPassword ||
        isRequestingPasswordResetLink ||
        isCreatingAccount ||
        isLoadingCustomer ||
        accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        accountPassword.isEmpty ||
        (accountAuthMode != .signIn && accountConfirmPassword.isEmpty) ||
        (accountAuthMode == .createAccount && (
            accountFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            accountLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ))
    }

    private var isResetLinkDisabled: Bool {
        isSigningIn ||
        isSigningInWithApple ||
        isCreatingAccount ||
        isResettingPassword ||
        isRequestingPasswordResetLink ||
        isLoadingCustomer ||
        accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

#if canImport(AuthenticationServices)
    private var isAppleSignInDisabled: Bool {
        isSigningIn ||
        isSigningInWithApple ||
        isCreatingAccount ||
        isResettingPassword ||
        isRequestingPasswordResetLink ||
        isLoadingCustomer
    }
#endif
}
