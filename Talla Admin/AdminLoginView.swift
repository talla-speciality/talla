import SwiftUI

struct AdminLoginView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var username = ""
    @State private var password = ""
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [TallaAdminStyle.paper, TallaAdminStyle.cream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("TALLA SPECIALITY", systemImage: "cup.and.saucer.fill")
                            .font(.caption.weight(.bold))
                            .tracking(3)
                            .foregroundStyle(TallaAdminStyle.caramel)
                        Text("Your roastery,\nin your pocket.")
                            .font(.system(size: 42, weight: .bold, design: .serif))
                            .foregroundStyle(TallaAdminStyle.espresso)
                        Text("Manage live orders and open every backend control from one secure admin app.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 14) {
                        TextField("Admin username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.username)
                            .submitLabel(.next)
                            .adminField()
                        SecureField("Admin password", text: $password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .adminField()
                            .onSubmit { signIn() }

                        if let error = session.errorMessage {
                            Label(error, systemImage: "exclamationmark.circle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: signIn) {
                            HStack {
                                if isSigningIn { ProgressView().tint(.white) }
                                Text(isSigningIn ? "Signing In…" : "Sign In")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .fontWeight(.semibold)
                            .padding(.horizontal, 18)
                            .frame(height: 54)
                            .foregroundStyle(.white)
                            .background(TallaAdminStyle.caramel, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .disabled(isSigningIn || username.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
                    }
                    .padding(20)
                    .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 26))
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(.brown.opacity(0.12)))
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func signIn() {
        guard !isSigningIn else { return }
        isSigningIn = true
        Task {
            _ = await session.login(username: username.trimmingCharacters(in: .whitespaces), password: password)
            password = ""
            isSigningIn = false
        }
    }
}

private extension View {
    func adminField() -> some View {
        padding(.horizontal, 16)
            .frame(height: 52)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.brown.opacity(0.16)))
    }
}
