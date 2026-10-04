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
    @MainActor
    func loadProductsIfNeeded() async {
        guard !hasLoadedProducts else { return }
        async let productsTask: Void = loadProducts()
        async let methodsTask: Void = loadBrewingMethodsIfNeeded()
        await productsTask
        await methodsTask

        var customerTask: Task<Void, Never>?
        var loyaltyTask: Task<Void, Never>?
        if !savedCustomerAccessToken.isEmpty, customerProfile == nil {
            customerTask = Task { @MainActor in await loadCustomerProfile() }
        }

        if !savedLoyaltyEmail.isEmpty, loyaltyEmail.isEmpty {
            loyaltyEmail = savedLoyaltyEmail
            loyaltyTask = Task { @MainActor in await loadLoyaltyAccount() }
        }
        await customerTask?.value
        await loyaltyTask?.value
    }

    @MainActor
    func signInCustomer() async {
        let trimmedEmail = normalizedAccountEmail
        guard !trimmedEmail.isEmpty, !accountPassword.isEmpty else {
            customerAuthError = AppLocalization.text("enter_email_password", fallback: "Enter your customer email and password.")
            return
        }

        isSigningIn = true
        customerAuthError = nil
        defer { isSigningIn = false }

        do {
            let session = try await AccountService.signIn(email: trimmedEmail, password: accountPassword)
            applySignedInSession(session)
            accountPassword = ""
            showToast(message: AppLocalization.text("signed_in_toast", fallback: "Signed in"))
        } catch {
            customerProfile = nil
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

    }

#if canImport(AuthenticationServices)
    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomAppleNonce()
        appleSignInNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        Task {
            await handleAppleSignInResultAsync(result)
        }
    }

    @MainActor
    func handleAppleSignInResultAsync(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            appleSignInNonce = ""

            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                customerAuthError = nil
                isSigningInWithApple = false
                return
            }

            customerAuthError = friendlyCustomerAuthMessage(
                for: error,
                fallback: AppLocalization.text("apple_sign_in_unavailable", fallback: "Sign in with Apple is unavailable right now.")
            )
            isSigningInWithApple = false
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                customerAuthError = AppLocalization.text("apple_sign_in_invalid_credential", fallback: "Apple sign-in did not return a valid account credential.")
                isSigningInWithApple = false
                return
            }

            guard let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  !identityToken.isEmpty else {
                customerAuthError = AppLocalization.text("apple_sign_in_missing_token", fallback: "Apple sign-in did not return an identity token.")
                isSigningInWithApple = false
                return
            }

            let nonce = appleSignInNonce
            guard !nonce.isEmpty else {
                customerAuthError = AppLocalization.text("apple_sign_in_not_verified", fallback: "Apple sign-in could not be verified.")
                isSigningInWithApple = false
                return
            }

            isSigningInWithApple = true
            customerAuthError = nil

            do {
                let session = try await AccountService.signInWithApple(
                    identityToken: identityToken,
                    userIdentifier: credential.user,
                    email: credential.email,
                    firstName: credential.fullName?.givenName,
                    lastName: credential.fullName?.familyName,
                    nonce: nonce
                )
                applySignedInSession(session)
                accountPassword = ""
                accountConfirmPassword = ""
                showToast(message: AppLocalization.text("signed_in_with_apple_toast", fallback: "Signed in with Apple"))
            } catch {
                customerProfile = nil
                customerAuthError = friendlyCustomerAuthMessage(
                    for: error,
                    fallback: AppLocalization.text("apple_sign_in_unavailable", fallback: "Sign in with Apple is unavailable right now.")
                )
            }

            appleSignInNonce = ""
            isSigningInWithApple = false
        }
    }
#endif

    func switchAccountAuthMode(_ mode: AccountAuthMode) {
        accountAuthMode = mode
        customerAuthError = nil
        accountPassword = ""
        accountConfirmPassword = ""
        appleSignInNonce = ""
    }

    func startFirstRunAccountSetup() {
        hasSeenWelcome = true
        cartOpen = false
        openAccountSection(AccountSectionView.ScrollTarget.customer, authMode: .createAccount)
        showToast(message: AppLocalization.text("onboarding_account_started", fallback: "Create your account first. Delivery details come next."))
    }

    @MainActor
    func prepareNewCustomerAddressSetup(firstName: String, lastName: String) {
        if addressLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressLabel = AppLocalization.text("home_address_label", fallback: "Home")
        }

        if addressFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressFullName = [firstName, lastName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        isAccountOnboardingPresented = true
    }

    @MainActor
    func createCustomerAccount() async {
        let trimmedFirstName = accountFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = accountLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = normalizedAccountEmail

        guard !trimmedFirstName.isEmpty, !trimmedLastName.isEmpty, !trimmedEmail.isEmpty, !accountPassword.isEmpty else {
            customerAuthError = AppLocalization.text("complete_account_fields", fallback: "Complete your name, email, and password to create an account.")
            return
        }

        guard accountPassword == accountConfirmPassword else {
            customerAuthError = AppLocalization.text("password_confirmation_mismatch", fallback: "Your password confirmation does not match.")
            return
        }

        guard accountPassword.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
            return
        }

        isCreatingAccount = true
        customerAuthError = nil

        do {
            let session = try await AccountService.register(
                firstName: trimmedFirstName,
                lastName: trimmedLastName,
                email: trimmedEmail,
                password: accountPassword
            )

            applySignedInSession(session)
            accountPassword = ""
            accountConfirmPassword = ""
            accountAuthMode = .signIn
            prepareNewCustomerAddressSetup(firstName: trimmedFirstName, lastName: trimmedLastName)
        } catch {
            customerProfile = nil
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isCreatingAccount = false
    }

    @MainActor
    func requestPasswordResetLink() async {
        let trimmedEmail = normalizedAccountEmail
        guard !trimmedEmail.isEmpty else {
            customerAuthError = AppLocalization.text("enter_email_first", fallback: "Enter your email address first.")
            return
        }

        isRequestingPasswordResetLink = true
        customerAuthError = nil

        do {
            try await AccountService.requestPasswordResetLink(email: trimmedEmail)
            accountPassword = ""
            showToast(message: AppLocalization.text("reset_link_sent", fallback: "If an account exists for that email, a reset link has been sent."))
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(
                for: error,
                fallback: AppLocalization.text("email_reset_link", fallback: "Password reset email is unavailable right now.")
            )
        }

        isRequestingPasswordResetLink = false
    }

    @MainActor
    func loadCustomerProfile() async {
        guard !savedCustomerAccessToken.isEmpty, !isLoadingCustomer else { return }

        isLoadingCustomer = true
        customerAuthError = nil

        do {
            let profile = try await AccountService.fetchProfile()
            applySignedInProfile(profile, loadLoyalty: loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } catch AccountService.SessionError.invalid {
            signOutCustomer(clearError: false)
            customerAuthError = AppLocalization.text("account_session_expired", fallback: "Your account session expired. Sign in again to continue.")
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isLoadingCustomer = false
    }

    @MainActor
    func refreshSignedInProfile() async {
        guard customerProfile != nil, !isLoadingCustomer else { return }
        isLoadingCustomer = true
        defer { isLoadingCustomer = false }

        do {
            let profile = try await AccountService.fetchProfile()
            customerProfile = profile
            savedCustomerEmail = profile.email
            accountEmail = profile.email
            profileFirstName = profile.firstName ?? ""
            profileLastName = profile.lastName ?? ""
        } catch AccountService.SessionError.invalid {
            signOutCustomer(clearError: false)
            customerAuthError = AppLocalization.text("account_session_expired", fallback: "Your account session expired. Sign in again to continue.")
        } catch {
            // Keep the last known account state during transient network failures.
        }
    }

    @MainActor
    @discardableResult
    func restoreSyncedCustomerCredential() -> Bool {
        // Refresh rotation updates the credential store while the view may
        // still hold the previous token. Always read the authoritative copy.
        let syncedToken = TallaAccountCredentialStore.accessToken
        guard savedCustomerAccessToken != syncedToken else { return false }
        savedCustomerAccessToken = syncedToken
        return !syncedToken.isEmpty
    }

    func signOutCustomer(clearError: Bool = true, unregisterBackend: Bool = true) {
        let emailToUnregister = customerProfile?.email ?? (!savedCustomerEmail.isEmpty ? savedCustomerEmail : nil)
        let accessTokenToUnregister = TallaAccountCredentialStore.accessToken
        if unregisterBackend {
            unregisterRemotePushToken(email: emailToUnregister, accessToken: accessTokenToUnregister)
        }
        unregisterRemoteNotifications()
        savedRegisteredPushDeviceEmail = ""
        savedRegisteredPushDeviceToken = ""
        savedCustomerEmail = ""
        savedCustomerAccessToken = ""
        TallaAccountCredentialStore.clear()
        customerProfile = nil
        isAccountOnboardingPresented = false
        accountAuthMode = .signIn
        accountFirstName = ""
        accountLastName = ""
        accountPassword = ""
        accountConfirmPassword = ""
        appleSignInNonce = ""
        profileFirstName = ""
        profileLastName = ""
        currentPasswordInput = ""
        newPasswordInput = ""
        confirmNewPasswordInput = ""
        orderHistory = []
        ordersError = nil
        addresses = []
        addressLabel = ""
        addressFullName = ""
        addressPhone = ""
        addressLine1 = ""
        addressCity = ""
        addressCountry = .bahrain
        addressNotes = ""
        backendStockAlerts = []
        availableVouchers = []
        appliedVoucher = nil
        voucherCodeInput = ""
        voucherError = nil

        if clearError {
            customerAuthError = nil
        }
    }

    @MainActor
    func applySignedInProfile(_ profile: ShopifyCustomerProfile, loadLoyalty: Bool = true) {
        savedCustomerEmail = profile.email
        savedLoyaltyEmail = profile.email
        customerProfile = profile
        accountEmail = profile.email
        profileFirstName = profile.firstName ?? ""
        profileLastName = profile.lastName ?? ""

        if loadLoyalty {
            loyaltyEmail = profile.email
        }

        registerForRemoteNotifications()
        Task {
            await refreshWalletPassPresence()
            await syncRemotePushTokenIfPossible()
            await synchronizeCustomerLibrary()
            if loadLoyalty {
                await loadLoyaltyAccount()
            }
            await loadOrderHistory()
            if let birthday = try? await AccountService.fetchBirthdayProfile() {
                birthdayMonth = String(birthday.month)
                birthdayDay = String(birthday.day)
            }
            await syncBackendStockAlerts()
            await loadBackendStockAlerts()
            await loadAddresses()
            await loadAlertInbox()
        }
    }

    @MainActor
    func applySignedInSession(_ session: AccountService.CustomerSession, loadLoyalty: Bool = true) {
        TallaAccountCredentialStore.save(accessToken: session.accessToken, refreshToken: session.refreshToken)
        savedCustomerAccessToken = session.accessToken
        applySignedInProfile(session.profile, loadLoyalty: loadLoyalty)
    }

    @MainActor
    func saveProfile() async -> Bool {
        guard let profile = customerProfile else { return false }
        let firstName = profileFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = profileLastName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !firstName.isEmpty, !lastName.isEmpty else {
            customerAuthError = AppLocalization.text("enter_full_name_before_saving", fallback: "Enter both first and last name before saving.")
            return false
        }

        isSavingProfile = true
        customerAuthError = nil

        do {
            let updated = try await AccountService.updateProfile(email: profile.email, firstName: firstName, lastName: lastName)
            if let month = Int(birthdayMonth), let day = Int(birthdayDay), (1...12).contains(month), (1...31).contains(day) {
                try await AccountService.saveBirthdayProfile(month: month, day: day)
            }
            customerProfile = updated
            profileFirstName = updated.firstName ?? ""
            profileLastName = updated.lastName ?? ""
            showToast(message: AppLocalization.text("profile_updated_toast", fallback: "Profile updated"))
            isSavingProfile = false
            return true
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isSavingProfile = false
        return false
    }

    @MainActor
    func resetPassword() async {
        guard let profile = customerProfile else { return }

        guard newPasswordInput == confirmNewPasswordInput else {
            customerAuthError = AppLocalization.text("new_password_confirmation_mismatch", fallback: "The new password confirmation does not match.")
            return
        }

        guard newPasswordInput.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
            return
        }

        isResettingPassword = true
        customerAuthError = nil

        do {
            try await AccountService.resetPassword(
                email: profile.email,
                currentPassword: currentPasswordInput,
                newPassword: newPasswordInput
            )
            currentPasswordInput = ""
            newPasswordInput = ""
            confirmNewPasswordInput = ""
            showToast(message: AppLocalization.text("update_password", fallback: "Password updated"))
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isResettingPassword = false
    }

    @MainActor
    func refreshWalletPassPresence() async {
#if canImport(PassKit)
        guard PKPassLibrary.isPassLibraryAvailable() else {
            isLoyaltyPassInWallet = false
            return
        }

        guard let email = customerProfile?.email ?? (!savedLoyaltyEmail.isEmpty ? savedLoyaltyEmail : nil) else {
            isLoyaltyPassInWallet = false
            return
        }

        do {
            let pass = try await AccountService.fetchWalletPass(email: email)
            let library = PKPassLibrary()
            let isPassInWallet = library.containsPass(pass)
            if isPassInWallet {
                _ = library.replacePass(with: pass)
            }
            isLoyaltyPassInWallet = isPassInWallet
        } catch {
            isLoyaltyPassInWallet = false
        }
#else
        isLoyaltyPassInWallet = false
#endif
    }

    @MainActor
    func changePasswordWithoutSignIn() async {
        let trimmedEmail = normalizedAccountEmail

        guard !trimmedEmail.isEmpty, !accountPassword.isEmpty, !accountConfirmPassword.isEmpty else {
            customerAuthError = AppLocalization.text("enter_email_current_new_password", fallback: "Enter your email, current password, and new password.")
            return
        }

        guard accountConfirmPassword.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
            return
        }

        isResettingPassword = true
        customerAuthError = nil

        do {
            try await AccountService.changePasswordWithoutSignIn(
                email: trimmedEmail,
                currentPassword: accountPassword,
                newPassword: accountConfirmPassword
            )
            accountAuthMode = .signIn
            accountPassword = ""
            accountConfirmPassword = ""
            showToast(message: AppLocalization.text("update_password", fallback: "Password updated"))
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isResettingPassword = false
    }

    @MainActor
    func manageCoffeeClub(
        order: AccountOrder,
        action: String,
        note: String?,
        coffeeName: String?,
        variantID: String?,
        address: DeliveryAddress?,
        fulfillmentMethod: TallaFulfillmentMethod = .delivery,
        coffeeItems: [(name: String, variantID: String, quantity: Int)] = []
    ) async -> Bool {
        do {
            orderHistory = try await AccountService.manageCoffeeClub(
                orderID: order.id,
                action: action,
                reason: action == "request_cancel" ? note : nil,
                note: action == "request_refund" ? note : nil,
                coffeeName: coffeeName,
                variantID: variantID,
                address: address,
                fulfillmentMethod: fulfillmentMethod,
                coffeeItems: coffeeItems
            )
            showToast(message: AppLocalization.text("coffee_club_updated", fallback: "Coffee Club updated"))
            return true
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("coffee_club_update_failed", fallback: "Coffee Club could not be updated right now.")
            ))
            return false
        }
    }

    @MainActor
    func submitCustomerOrderAction(order: AccountOrder, action: String) async -> Bool {
        do {
            orderHistory = try await AccountService.submitCustomerOrderAction(orderID: order.id, action: action)
            showToast(message: action == "request_cancellation" ? "Cancellation request sent" : "Support case updated")
            return true
        } catch {
            showToast(message: customerFacingServiceMessage(for: error, fallback: "Your order request could not be completed."))
            return false
        }
    }

    @MainActor
    func loadOrderHistory() async {
        guard let profile = customerProfile, !isLoadingOrders else { return }

        isLoadingOrders = true
        ordersError = nil

        do {
            orderHistory = try await AccountService.fetchOrders(email: profile.email)
            try? coffeeData.importPurchasedCoffee(from: orderHistory, catalog: products, ownerID: profile.email.lowercased())
            if let remoteTasteMemory = try? await AccountService.fetchTasteMemory(email: profile.email) {
                persistTasteMemoryRecords(remoteTasteMemory)
            }
        } catch {
            orderHistory = []
            ordersError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("orders_refresh_failed", fallback: "Orders could not be refreshed right now.")
            )
        }

        isLoadingOrders = false
    }

    @MainActor
    func loadBackendStockAlerts() async {
        guard let profile = customerProfile, !isLoadingBackendAlerts else { return }

        isLoadingBackendAlerts = true
        do {
            backendStockAlerts = try await AccountService.fetchStockAlerts(email: profile.email)
        } catch {
            backendStockAlerts = []
        }
        isLoadingBackendAlerts = false
    }

    @MainActor
    func loadAddresses() async {
        guard let profile = customerProfile else { return }
        if let loaded = try? await AccountService.fetchAddresses(email: profile.email) {
            addresses = loaded
            if loaded.isEmpty {
                prepareAccountOnboarding(for: profile)
            }
        }
    }

    @MainActor
    func prepareAccountOnboarding(for profile: ShopifyCustomerProfile) {
        if addressLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressLabel = AppLocalization.text("home_address_label", fallback: "Home")
        }

        if addressFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressFullName = [profile.firstName, profile.lastName]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        isAccountOnboardingPresented = true
    }

    @MainActor
    func loadAlertInbox() async {
        guard let profile = customerProfile else { return }
        if let loaded = try? await AccountService.fetchAlertInbox(email: profile.email) {
            alertInbox = loaded
        }
    }

    @MainActor
    func syncBackendStockAlerts() async {
        guard let profile = customerProfile, !alertProducts.isEmpty else { return }

        let records = alertProducts.map {
            StockAlertRecord(
                productID: $0.id,
                productName: $0.name,
                tag: $0.tag,
                isAvailableForSale: $0.isAvailableForSale,
                status: $0.isAvailableForSale ? "Available now" : "Waiting for availability",
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        }

        if let synced = try? await AccountService.syncStockAlerts(email: profile.email, alerts: records) {
            backendStockAlerts = synced
        }
    }

    @MainActor
    func saveAddress(closeOnboarding: Bool = false) async {
        guard let profile = customerProfile else { return }
        let label = addressLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = addressFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = normalizedPhoneNumber(addressPhone)
        let line1 = addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = addressCity.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = addressNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !label.isEmpty, !fullName.isEmpty, !phone.isEmpty, !line1.isEmpty, !city.isEmpty else {
            showToast(message: AppLocalization.text("complete_address_details", fallback: "Complete the address details first"))
            return
        }

        isSavingAddress = true
        defer { isSavingAddress = false }

        do {
            addresses = try await AccountService.saveAddress(
                email: profile.email,
                label: label,
                fullName: fullName,
                phone: phone,
                line1: line1,
                city: city,
                countryCode: addressCountry.rawValue,
                notes: notes.isEmpty ? nil : notes
            )
            addressLabel = ""
            addressFullName = ""
            addressPhone = ""
            addressLine1 = ""
            addressCity = ""
            addressCountry = .bahrain
            addressNotes = ""
            if closeOnboarding {
                isAccountOnboardingPresented = false
            }
            showToast(message: AppLocalization.text("address_saved_toast", fallback: "Address saved"))
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("address_save_failed", fallback: "Address could not be saved right now.")
            ))
        }
    }

    func normalizedPhoneNumber(_ rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let compact = trimmed
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        if compact.hasPrefix("+") {
            return compact
        }

        guard !addressCountry.phonePrefix.isEmpty else { return "" }
        let localNumber = compact.drop(while: { $0 == "0" })
        return "\(addressCountry.phonePrefix)\(localNumber)"
    }

    @MainActor
    func deleteAddress(_ address: DeliveryAddress) async {
        guard let profile = customerProfile else { return }

        do {
            addresses = try await AccountService.deleteAddress(email: profile.email, addressID: address.id)
            showToast(message: AppLocalization.text("address_removed_toast", fallback: "Address removed"))
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("address_remove_failed", fallback: "Address could not be removed right now.")
            ))
        }
    }

    @MainActor
    func makePreferredAddress(_ address: DeliveryAddress) async -> Bool {
        guard let profile = customerProfile else { return false }
        guard !address.isPreferred else { return true }

        let previousAddresses = addresses
        selectingAddressID = address.id
        addresses = addresses.map { candidate in
            DeliveryAddress(
                id: candidate.id,
                label: candidate.label,
                fullName: candidate.fullName,
                phone: candidate.phone,
                line1: candidate.line1,
                city: candidate.city,
                countryCode: candidate.countryCode,
                notes: candidate.notes,
                isPreferred: candidate.id == address.id
            )
        }
        defer { selectingAddressID = nil }

        do {
            addresses = try await AccountService.setPreferredAddress(
                email: profile.email,
                addressID: address.id
            )
            checkoutError = nil
            showToast(message: AppLocalization.text("delivery_address_selected", fallback: "Delivery address selected"))
            return true
        } catch {
            addresses = previousAddresses
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("address_selection_failed", fallback: "The delivery address could not be selected right now.")
            ))
            return false
        }
    }

    func friendlyCustomerAuthMessage(for error: Error, fallback: String? = nil) -> String {
        if let urlError = error as? URLError,
           [.cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code) {
            return BackendConfiguration.connectionMessage(for: "account service")
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = message.lowercased()

        if normalized.contains("backendbaseurl") || normalized.contains("127.0.0.1") || normalized.contains("localhost") {
            return fallback ?? AppLocalization.text("connection_issue_try_again", fallback: "Talla is having trouble connecting. Check your internet connection and try again.")
        }

        if normalized.contains("invalid email or password") {
            return fallback ?? "The email or password is incorrect."
        }

        if normalized.contains("account already exists") {
            return fallback ?? "An account with this email already exists."
        }

        if normalized.contains("account not found") {
            return fallback ?? "No account was found for that email."
        }

        if normalized.contains("password reset email is not configured") || normalized.contains("password reset email could not be sent") {
            return fallback ?? "Password reset email is unavailable right now."
        }

        if normalized.contains("unidentified customer") {
            return fallback ?? "This account could not be recognized yet. Check that the email and password are correct and try again."
        }

        return fallback ?? message
    }

    func customerFacingServiceMessage(for error: Error, fallback: String) -> String {
        if let urlError = error as? URLError,
           [.cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code) {
            return AppLocalization.text("connection_issue_try_again", fallback: "Talla is having trouble connecting. Check your internet connection and try again.")
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = message.lowercased()

        if message.isEmpty ||
            normalized.contains("backendbaseurl") ||
            normalized.contains("127.0.0.1") ||
            normalized.contains("localhost") ||
            normalized.contains("url is invalid") ||
            normalized.contains("invalid response") ||
            normalized.contains("service is unavailable") ||
            normalized.contains("could not complete your request") {
            return fallback
        }

        return message
    }

    func isExpiredCustomerSessionError(_ error: Error) -> Bool {
        let message = error.localizedDescription
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return message.contains("sign in again")
            || message.contains("invalid customer token")
            || message.contains("customer authorization required")
            || message.contains("customer access token")
    }

    var normalizedAccountEmail: String {
        accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    @MainActor
    func loadProducts(force: Bool = false) async {
        guard !isLoadingProducts else { return }
        guard force || !hasLoadedProducts else { return }

        isLoadingProducts = true
        loadingError = nil

        let requestedLanguage = AppLocalization.currentLanguage.effectiveLanguageCode
        do {
            let fetchedProducts = try await ShopifyStorefrontClient.fetchAllProducts(languageCode: requestedLanguage)
            guard requestedLanguage == AppLocalization.currentLanguage.effectiveLanguageCode else {
                isLoadingProducts = false
                await loadProducts(force: true)
                return
            }
            products = fetchedProducts
            cartItems = cartItems.map { item in
                guard let product = fetchedProducts.first(where: { $0.id == item.product.id }),
                      let variant = product.variants.first(where: { $0.id == item.variant.id }) else { return item }
                return CartItem(id: item.id, product: product, variant: variant, quantity: item.quantity)
            }
            if let current = selectedProduct,
               let refreshed = fetchedProducts.first(where: { $0.id == current.id }) {
                selectedProduct = refreshed
            }
            hasLoadedProducts = true
            lastProductsRefreshAt = Date()
            async let homeSettingsTask: Void = loadHomeSettings()
            async let passportSettingsTask: Void = loadPassportSettings()
            async let appSettingsTask: Void = loadAppSettings()
            async let eventSettingsTask: Void = loadEventSettings()
            await homeSettingsTask
            await passportSettingsTask
            await appSettingsTask
            await eventSettingsTask

            if !availableCategories.contains(where: { $0.key == activeCategory }) {
                activeCategory = "all"
            }

            if customerProfile != nil {
                await syncBackendStockAlerts()
                await loadBackendStockAlerts()
            }
        } catch {
            loadingError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("shop_retry_later", fallback: "Products could not be loaded right now. Please try again.")
            )
        }

        isLoadingProducts = false
    }

    @MainActor
    func loadHomeSettings() async {
        do {
            let settings = try await HomeSettingsService.fetchHomeSettings()
            remoteHomeSettings = settings
            remoteSignatureRoastProductIDs = settings.signatureRoastProductIDs
        } catch {
            remoteHomeSettings = nil
            remoteSignatureRoastProductIDs = []
        }
    }

    @MainActor
    func loadPassportSettings() async {
        do {
            remotePassportSettings = try await HomeSettingsService.fetchPassportSettings()
        } catch {
            remotePassportSettings = nil
        }
    }

    @MainActor
    func loadAppSettings() async {
        do {
            let settings = try await HomeSettingsService.fetchAppSettings()
            remoteAppSettings = settings
            if let firstLocation = settings.fulfillment?.locations?.first,
               selectedPickupLocationID.isEmpty || settings.fulfillment?.locations?.contains(where: { $0.id == selectedPickupLocationID }) != true {
                selectedPickupLocationID = firstLocation.id
                selectedPickupSlot = firstLocation.pickupSlots?.first(where: { $0.remaining > 0 }).map { isArabicInterface ? $0.labelAR : $0.labelEN } ?? selectedPickupSlot
            }
            if settings.fulfillment?.deliveryEnabled == false,
               settings.fulfillment?.pickupEnabled == true {
                fulfillmentMethod = .pickup
            } else if settings.fulfillment?.pickupEnabled == false,
                      settings.fulfillment?.deliveryEnabled == true {
                fulfillmentMethod = .delivery
            }
        } catch {
            // Keep the bundled defaults when live controls are unavailable.
        }
    }

    @MainActor
    func loadEventSettings() async {
        do {
            remoteEventSettings = try await HomeSettingsService.fetchEventSettings()
        } catch {
            // Seasonal content is optional; keep the normal storefront if unavailable.
        }
    }

    @MainActor
    func refreshProductsIfNeeded() async {
        let now = Date()
        if let lastProductsRefreshAt,
           now.timeIntervalSince(lastProductsRefreshAt) < 45 {
            return
        }

        await loadProducts(force: true)
    }

    @MainActor
    func loadBrewingMethodsIfNeeded() async {
        guard !hasLoadedBrewingMethods else { return }
        await loadBrewingMethods()
    }

    @MainActor
    func loadBrewingMethods(force: Bool = false) async {
        guard !isLoadingBrewingMethods else { return }
        guard force || !hasLoadedBrewingMethods else { return }

        isLoadingBrewingMethods = true
        brewingMethodsError = nil

        do {
            brewingMethods = try await ShopifyStorefrontClient.fetchBrewingMethods()
            hasLoadedBrewingMethods = true
        } catch {
            brewingMethods = []
            brewingMethodsError = AppLocalization.text("brewing_articles_fallback", fallback: "Brewing articles couldn't be loaded from Shopify. Showing curated fallback methods.")
        }

        isLoadingBrewingMethods = false
    }

    @MainActor
    func loadLoyaltyAccount() async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_order_email_loyalty", fallback: "Enter the email you use for your coffee orders.")
            return
        }

        isLoadingLoyalty = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.fetchAccount(email: trimmedEmail)
            savedLoyaltyEmail = trimmedEmail
            syncWidgetSharedState(reload: true)
            async let vouchersTask: Void = loadAvailableVouchers(for: trimmedEmail)
            async let walletTask: Void = refreshWalletPassPresence()
            await vouchersTask
            await walletTask
            showToast(message: AppLocalization.text("rewards_loaded_toast", fallback: "Rewards loaded"))
        } catch {
            loyaltyAccount = nil
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("rewards_refresh_failed", fallback: "Rewards could not be refreshed right now.")
            )
        }

        isLoadingLoyalty = false
    }

    @MainActor
    func redeemReward(points: Int, rewardID: String, rewardTitle: String) async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_rewards_email_first", fallback: "Enter the email tied to your rewards account first.")
            return
        }

        isRedeemingReward = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.redeemReward(email: trimmedEmail, points: points, reward: rewardID)
            syncWidgetSharedState(reload: true)
            let voucherCode = loyaltyAccount?.transactions.first(where: { $0.type == "redeem" })?.voucherCode
            if let voucherCode, !voucherCode.isEmpty {
                showToast(message: String(format: AppLocalization.text("reward_redeemed_with_code", fallback: "%@ redeemed • %@"), rewardTitle, voucherCode))
            } else {
                showToast(message: String(format: AppLocalization.text("reward_redeemed", fallback: "%@ redeemed"), rewardTitle))
            }
            await refreshWalletPassPresence()
        } catch {
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("reward_redeem_failed", fallback: "This reward could not be redeemed right now.")
            )
        }

        isRedeemingReward = false
    }

    @MainActor
    func earnPoints(points: Int, note: String) async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_rewards_email_first", fallback: "Enter the email tied to your rewards account first.")
            return
        }

        isEarningPoints = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.earnPoints(email: trimmedEmail, points: points, note: note)
            syncWidgetSharedState(reload: true)
            showToast(message: String(format: AppLocalization.text("beans_added_toast", fallback: "%d Beans added"), points))
        } catch {
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("beans_update_failed", fallback: "Beans could not be updated right now.")
            )
        }

        isEarningPoints = false
    }

    @MainActor
    func addLoyaltyPassToWallet() async {
#if canImport(PassKit)
        guard PKPassLibrary.isPassLibraryAvailable() else {
            showToast(message: AppLocalization.text("apple_wallet_unavailable", fallback: "Apple Wallet is unavailable on this device"))
            return
        }

        guard let email = customerProfile?.email ?? (!savedLoyaltyEmail.isEmpty ? savedLoyaltyEmail : nil) else {
            showToast(message: AppLocalization.text("sign_in_before_wallet_pass", fallback: "Sign in before adding your Wallet pass"))
            return
        }

        isLoadingWalletPass = true

        do {
            let pass = try await AccountService.fetchWalletPass(email: email)
            let library = PKPassLibrary()
            if library.containsPass(pass) {
                _ = library.replacePass(with: pass)
                isLoyaltyPassInWallet = true
                showToast(message: AppLocalization.text("wallet_pass_updated", fallback: "The Talla Club card was updated in Apple Wallet"))
            } else {
                loyaltyWalletPass = WalletPassItem(pass: pass)
            }
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("wallet_pass_failed", fallback: "Wallet pass could not be loaded right now.")
            ))
        }

        isLoadingWalletPass = false
#else
        showToast(message: AppLocalization.text("apple_wallet_unavailable", fallback: "Apple Wallet is unavailable on this device"))
#endif
    }

}
