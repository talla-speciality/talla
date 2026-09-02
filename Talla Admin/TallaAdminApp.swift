import SwiftUI

@main
struct TallaAdminApp: App {
    @UIApplicationDelegateAdaptor(TallaAdminAppDelegate.self) private var appDelegate
    @StateObject private var session = AdminSession()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isRestoring {
                    LaunchView()
                } else if session.isAuthenticated {
                    AdminRootView()
                } else {
                    AdminLoginView()
                }
            }
            .environmentObject(session)
            .tint(TallaAdminStyle.caramel)
            .fontDesign(.rounded)
            .task { await session.bootstrap() }
        }
    }
}

enum TallaAdminStyle {
    static let espresso = adaptive(light: (0.15, 0.09, 0.05), dark: (0.96, 0.90, 0.82))
    static let caramel = adaptive(light: (0.62, 0.34, 0.14), dark: (0.91, 0.61, 0.34))
    static let cream = adaptive(light: (0.96, 0.92, 0.86), dark: (0.16, 0.13, 0.11))
    static let paper = adaptive(light: (0.985, 0.97, 0.945), dark: (0.11, 0.095, 0.085))
    static let card = adaptive(light: (1, 1, 1), dark: (0.18, 0.155, 0.135))
    static let background = adaptive(light: (0.975, 0.955, 0.925), dark: (0.08, 0.07, 0.065))
    static let border = adaptive(light: (0.82, 0.74, 0.66), dark: (0.35, 0.29, 0.24))
    static let success = adaptive(light: (0.16, 0.43, 0.27), dark: (0.38, 0.76, 0.49))
    static let warning = adaptive(light: (0.72, 0.43, 0.08), dark: (0.96, 0.68, 0.25))

    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: 1)
        })
    }
}

private struct LaunchView: View {
    var body: some View {
        ZStack {
            TallaAdminStyle.cream.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(TallaAdminStyle.caramel)
                Text("TALLA ADMIN")
                    .font(.caption.weight(.bold))
                    .tracking(4)
                    .foregroundStyle(TallaAdminStyle.espresso)
                ProgressView()
            }
        }
    }
}
