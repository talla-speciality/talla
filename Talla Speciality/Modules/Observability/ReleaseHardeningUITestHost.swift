#if DEBUG
import SwiftUI

struct ReleaseHardeningUITestHost: View {
    let scenario: String
    @State private var checkoutStep = 0
    @State private var accountExists = true
    @State private var deleteConfirmation = false
    @State private var online = false
    @State private var bluetoothConnected = true

    var body: some View {
        NavigationStack {
            Group {
                switch scenario {
                case "checkout": checkoutScenario
                case "arabic": arabicScenario
                case "account-deletion": accountDeletionScenario
                case "offline-recovery": offlineRecoveryScenario
                case "bluetooth-interruption": bluetoothInterruptionScenario
                default: Text("Unknown UI test scenario")
                }
            }
            .padding(24)
            .navigationTitle("Release validation")
        }
        .accessibilityIdentifier("release-hardening.test-host")
    }

    private var checkoutScenario: some View {
        VStack(spacing: 20) {
            Text(checkoutStep == 0 ? "Order total BHD 8.500" : checkoutStep == 1 ? "Apple Pay selected" : "Order confirmed")
                .accessibilityIdentifier("checkout.status")
            if checkoutStep == 0 {
                Button("Continue to payment") { checkoutStep = 1 }
                    .accessibilityIdentifier("checkout.continue")
            } else if checkoutStep == 1 {
                Button("Confirm purchase") { checkoutStep = 2 }
                    .accessibilityIdentifier("checkout.confirm")
            }
        }
    }

    private var arabicScenario: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("الدفع")
                .accessibilityIdentifier("arabic.checkout-title")
            Text("عنوان التوصيل")
            HStack {
                Text("المجموع")
                Spacer()
                Text("٨٫٥٠٠ د.ب")
            }
            .accessibilityIdentifier("arabic.summary-row")
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
    }

    private var accountDeletionScenario: some View {
        VStack(spacing: 20) {
            Text(accountExists ? "Signed in as release-test@talla.test" : "Your account has been deleted")
                .accessibilityIdentifier("account.status")
            if accountExists {
                Button("Delete Account Permanently", role: .destructive) { deleteConfirmation = true }
                    .accessibilityIdentifier("account.delete")
            }
        }
        .alert("Delete Account Permanently?", isPresented: $deleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) { accountExists = false }
                .accessibilityIdentifier("account.delete.confirm")
        } message: {
            Text("Your profile, loyalty data, saved addresses, alerts, vouchers, and order records will be permanently deleted.")
        }
    }

    private var offlineRecoveryScenario: some View {
        VStack(spacing: 20) {
            Text(online ? "Back online. Your saved coffee data is synced." : "Offline. Showing saved coffee data.")
                .accessibilityIdentifier("offline.status")
            Text("Cached brew: V60 · 20 g · 1:16")
                .accessibilityIdentifier("offline.cached-brew")
            if !online {
                Button("Retry connection") { online = true }
                    .accessibilityIdentifier("offline.retry")
            }
        }
    }

    private var bluetoothInterruptionScenario: some View {
        VStack(spacing: 20) {
            Text(bluetoothConnected ? "Acaia scale connected" : "Scale connection interrupted")
                .accessibilityIdentifier("bluetooth.status")
            if bluetoothConnected {
                Button("Simulate interruption") { bluetoothConnected = false }
                    .accessibilityIdentifier("bluetooth.interrupt")
            } else {
                Button("Reconnect scale") { bluetoothConnected = true }
                    .accessibilityIdentifier("bluetooth.reconnect")
            }
        }
    }
}
#endif
