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
            .task { await session.bootstrap() }
        }
    }
}

enum TallaAdminStyle {
    static let espresso = Color(red: 0.15, green: 0.09, blue: 0.05)
    static let caramel = Color(red: 0.62, green: 0.37, blue: 0.18)
    static let cream = Color(red: 0.96, green: 0.92, blue: 0.86)
    static let paper = Color(red: 0.985, green: 0.97, blue: 0.945)
    static let success = Color(red: 0.18, green: 0.42, blue: 0.28)
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
