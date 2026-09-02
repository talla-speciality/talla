import SwiftUI

struct AdminLoginView: View {
    @EnvironmentObject private var session: AdminSession
    @State private var username = ""
    @State private var password = ""
    @State private var isSigningIn = false
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
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("TALLA SPECIALITY", systemImage: "cup.and.saucer.fill")
                            .font(.caption.weight(.bold))
                            .tracking(3)
                            .foregroundStyle(TallaAdminStyle.caramel)
                        Text("Your roastery,\nin your pocket.")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
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
                            .focused($focusedField, equals: .username)
                            .adminField()
                            .onSubmit { focusedField = .password }
                        SecureField("Admin password", text: $password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
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
                        .opacity(isSigningIn || username.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty ? 0.55 : 1)
                    }
                    .padding(20)
                    .background(TallaAdminStyle.card.opacity(0.9), in: RoundedRectangle(cornerRadius: 26))
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(TallaAdminStyle.border.opacity(0.35)))
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
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
            .background(TallaAdminStyle.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(TallaAdminStyle.border.opacity(0.45)))
    }
}
