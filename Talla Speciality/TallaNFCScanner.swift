import Foundation
#if canImport(CoreNFC) && os(iOS)
import CoreNFC

@MainActor
final class TallaNFCScanner: NSObject, NFCNDEFReaderSessionDelegate {
    private var session: NFCNDEFReaderSession?
    private var onScan: ((URL) -> Void)?
    private var onError: ((String) -> Void)?

    let isAvailable = NFCNDEFReaderSession.readingAvailable

    func beginScanning(onScan: @escaping (URL) -> Void, onError: @escaping (String) -> Void) {
        self.onScan = onScan
        self.onError = onError
        guard isAvailable else {
            onError(AppLocalization.text("nfc_unavailable", fallback: "NFC scanning is not available on this device."))
            return
        }
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session.alertMessage = AppLocalization.text("nfc_scan_prompt", fallback: "Hold your iPhone near the Talla tag.")
        self.session = session
        session.begin()
    }

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        guard (error as? NFCReaderError)?.code != .readerSessionInvalidationErrorUserCanceled else { return }
        Task { @MainActor in self.onError?(error.localizedDescription) }
    }

    nonisolated func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        let url = messages
            .flatMap(\.records)
            .compactMap { $0.wellKnownTypeURIPayload() }
            .first(where: Self.isTrustedTallaURL)
        Task { @MainActor in
            if let url {
                session.alertMessage = AppLocalization.text("nfc_scan_success", fallback: "Talla tag opened.")
                self.onScan?(url)
            } else {
                self.onError?(AppLocalization.text("nfc_invalid_tag", fallback: "This is not a supported Talla tag."))
            }
        }
    }

    nonisolated private static func isTrustedTallaURL(_ url: URL) -> Bool {
        if url.scheme?.lowercased() == "talla" { return true }
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return false }
        return ["talla.me", "www.talla.me"].contains(url.host?.lowercased() ?? "")
    }
}
#else
@MainActor
final class TallaNFCScanner {
    let isAvailable = false
    func beginScanning(onScan: @escaping (URL) -> Void, onError: @escaping (String) -> Void) {
        onError(AppLocalization.text("nfc_unavailable", fallback: "NFC scanning is not available on this device."))
    }
}
#endif
