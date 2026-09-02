import SwiftUI
import WebKit

struct AdminConsoleView: View {
    let url: URL

    var body: some View {
        NavigationStack {
            AdminWebView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Full Admin")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AdminWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

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
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive

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
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?

        @objc func refresh(_ sender: UIRefreshControl) {
            webView?.reload()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            webView.scrollView.refreshControl?.endRefreshing()
        }
    }
}
