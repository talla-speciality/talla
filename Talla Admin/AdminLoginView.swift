import SwiftUI

struct AdminLoginView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var username = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var enableBiometrics = false
    @State private var didAttemptAutomaticBiometricSignIn = false
    @FocusState private var focusedField: Field?

    private enum Field { case username, password }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [TallaAdminStyle.paper, TallaAdminStyle.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: TallaAdminStyle.Spacing.page) {
                    VStack(alignment: .leading, spacing: TallaAdminStyle.Spacing.standard) {
                        Label("TALLA SPECIALITY", systemImage: "cup.and.saucer.fill")
                            .font(.caption.weight(.bold))
                            .tracking(3)
                            .foregroundStyle(TallaAdminStyle.caramel)
                        Text("Your roastery,\nin your pocket.")
                            .font(TallaAdminStyle.Font.display)
                            .foregroundStyle(TallaAdminStyle.espresso)
                        Text("Manage live orders and open every backend control from one secure admin app.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: TallaAdminStyle.Spacing.standard) {
                        if session.biometricEnabled {
                            Button {
                                Task { await signInWithBiometrics() }
                            } label: {
                                Label("Sign in with Face ID / Touch ID", systemImage: "faceid")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.tallaAdminPrimary)
                            .disabled(isSigningIn)

                            Text("Use Face ID or Touch ID to unlock your saved admin sign-in.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Divider()
                                .overlay(TallaAdminStyle.border)

                            Text("Use password instead")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TallaAdminStyle.espresso)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        TextField("Admin username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .username)
                            .tallaAdminField()
                            .onSubmit { focusedField = .password }
                        SecureField("Admin password", text: $password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .tallaAdminField()
                            .onSubmit { signIn() }

                        if session.biometricAvailable && !session.biometricEnabled {
                            Toggle(isOn: $enableBiometrics) {
                                Label("Save Face ID / Touch ID sign-in", systemImage: "faceid")
                                    .font(.subheadline)
                            }
                            .tint(TallaAdminStyle.caramel)
                        }

                        if let error = session.errorMessage {
                            Label(error, systemImage: "exclamationmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(TallaAdminStyle.destructive)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: signIn) {
                            HStack {
                                if isSigningIn { ProgressView().tint(.white) }
                                Text(isSigningIn ? "Signing In…" : "Sign In")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.tallaAdminPrimary)
                        .disabled(isSigningIn || username.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)

                    }
                    .tallaAdminCard()
                }
                .padding(TallaAdminStyle.Spacing.page)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .task(id: session.biometricEnabled) {
            guard session.biometricEnabled, !didAttemptAutomaticBiometricSignIn else { return }
            didAttemptAutomaticBiometricSignIn = true
            await signInWithBiometrics()
        }
        .onChange(of: session.isAuthenticated) { _, authenticated in
            if !authenticated { didAttemptAutomaticBiometricSignIn = false }
        }
        .onAppear {
            if session.biometricAvailable && !session.biometricEnabled {
                enableBiometrics = true
            }
        }
    }

    private func signInWithBiometrics() async {
        guard !isSigningIn else { return }
        isSigningIn = true
        await session.loginWithBiometrics()
        isSigningIn = false
    }

    private func signIn() {
        guard !isSigningIn else { return }
        isSigningIn = true
        Task {
            _ = await session.login(username: username.trimmingCharacters(in: .whitespaces), password: password, saveBiometrics: enableBiometrics)
            password = ""
            isSigningIn = false
        }
    }
}
