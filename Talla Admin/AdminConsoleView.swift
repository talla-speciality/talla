import SwiftUI
import WebKit

struct AdminConsoleView: View {
    let url: URL
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var reloadID = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AdminWebView(url: url, isLoading: $isLoading, errorMessage: $errorMessage)
                    .id(reloadID)

                if isLoading {
                    ProgressView("Loading admin…")
                        .padding(18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Admin page unavailable", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") { reload() }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TallaAdminStyle.background)
                }
            }
            .navigationTitle("Full Admin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { reload() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Reload full admin")
                }
            }
        }
    }

    private func reload() {
        errorMessage = nil
        isLoading = true
        reloadID += 1
    }
}

private struct AdminWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, errorMessage: $errorMessage)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController.addUserScript(WKUserScript(
            source: "document.getElementById('order-notification-control')?.remove();",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.isOpaque = false
        webView.backgroundColor = .clear

        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.refresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
        context.coordinator.webView = webView

        Task { @MainActor in
            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
            for cookie in cookies where cookie.name == "talla_admin_session" {
                await withCheckedContinuation { continuation in
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) { continuation.resume() }
                }
            }
            webView.load(URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        weak var webView: WKWebView?
        private var isLoading: Binding<Bool>
        private var errorMessage: Binding<String?>

        init(isLoading: Binding<Bool>, errorMessage: Binding<String?>) {
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }

        @objc func refresh(_ sender: UIRefreshControl) {
            webView?.reload()
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
            isLoading.wrappedValue = true
            errorMessage.wrappedValue = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            webView.scrollView.refreshControl?.endRefreshing()
            isLoading.wrappedValue = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
            finishWithError(error, webView: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
            finishWithError(error, webView: webView)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = UIAlertController(title: "Talla Admin", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            present(alert, from: webView, fallback: completionHandler)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(title: "Talla Admin", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in completionHandler(true) })
            present(alert, from: webView) { completionHandler(false) }
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            let alert = UIAlertController(title: "Talla Admin", message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            present(alert, from: webView) { completionHandler(nil) }
        }

        private func present(_ alert: UIAlertController, from webView: WKWebView, fallback: @escaping () -> Void) {
            guard let presenter = webView.window?.rootViewController?.topPresenter else {
                fallback()
                return
            }
            presenter.present(alert, animated: true)
        }

        private func finishWithError(_ error: Error, webView: WKWebView) {
            webView.scrollView.refreshControl?.endRefreshing()
            isLoading.wrappedValue = false
            errorMessage.wrappedValue = error.localizedDescription
        }
    }
}

private extension UIViewController {
    var topPresenter: UIViewController {
        if let presentedViewController { return presentedViewController.topPresenter }
        if let navigation = self as? UINavigationController { return navigation.visibleViewController?.topPresenter ?? navigation }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.topPresenter ?? tab }
        return self
    }
}
