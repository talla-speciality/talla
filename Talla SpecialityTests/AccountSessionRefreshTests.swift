import Foundation
import Testing
@testable import Talla_Speciality

@MainActor
@Suite(.serialized)
struct AccountSessionRefreshTests {
    private final class NotificationCounter: @unchecked Sendable {
        var count = 0
    }

    private func withCredentials(_ body: () async throws -> Void) async throws {
        let access = TallaAccountCredentialStore.accessToken
        let refresh = TallaAccountCredentialStore.refreshToken
        defer { TallaAccountCredentialStore.save(accessToken: access, refreshToken: refresh) }
        TallaAccountCredentialStore.save(accessToken: "old-access", refreshToken: "old-refresh")
        try #require(TallaAccountCredentialStore.refreshToken == "old-refresh")
        try await body()
    }

    private func response(_ request: URLRequest, status: Int, body: String = "{}") -> (Data, URLResponse) {
        (Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }

    private let validBody = #"{"accessToken":"new-access","refreshToken":"new-refresh","expiresAt":"2030-01-01","refreshExpiresAt":"2030-02-01"}"#

    @Test func readingStoredCredentialsDoesNotInvalidateSwiftUI() async throws {
        try await withCredentials {
            let counter = NotificationCounter()
            let observer = NotificationCenter.default.addObserver(
                forName: UserDefaults.didChangeNotification,
                object: UserDefaults.standard,
                queue: .main
            ) { _ in counter.count += 1 }
            defer { NotificationCenter.default.removeObserver(observer) }
            #expect(TallaAccountCredentialStore.accessToken == "old-access")
            #expect(TallaAccountCredentialStore.accessToken == "old-access")
            #expect(counter.count == 0)
        }
    }

    @Test func serverFailurePreservesCredentials() async throws {
        try await withCredentials {
            do {
                _ = try await AccountService.performRefreshSession { response($0, status: 503) }
                Issue.record("A server error must not be accepted as a refresh")
            } catch {
                #expect(error is URLError)
            }
            #expect(TallaAccountCredentialStore.accessToken == "old-access")
            #expect(TallaAccountCredentialStore.refreshToken == "old-refresh")
        }
    }

    @Test func malformedSuccessPreservesCredentials() async throws {
        try await withCredentials {
            do {
                _ = try await AccountService.performRefreshSession { response($0, status: 200) }
                Issue.record("Missing tokens must not be accepted")
            } catch {
                #expect(error is DecodingError)
            }
            #expect(TallaAccountCredentialStore.refreshToken == "old-refresh")
        }
    }

    @Test func rejectedCredentialClearsSession() async throws {
        try await withCredentials {
            do {
                _ = try await AccountService.performRefreshSession { response($0, status: 401) }
                Issue.record("Expired credentials must be rejected")
            } catch AccountService.SessionError.invalid {
                #expect(TallaAccountCredentialStore.accessToken.isEmpty)
                #expect(TallaAccountCredentialStore.refreshToken.isEmpty)
            }
        }
    }

    @Test func emptyTokensPreserveCredentials() async throws {
        try await withCredentials {
            do {
                _ = try await AccountService.performRefreshSession {
                    response($0, status: 200, body: #"{"accessToken":" ","refreshToken":"","expiresAt":"2030","refreshExpiresAt":"2030"}"#)
                }
                Issue.record("Empty tokens must not replace working credentials")
            } catch {
                #expect(error is URLError)
            }
            #expect(TallaAccountCredentialStore.accessToken == "old-access")
            #expect(TallaAccountCredentialStore.refreshToken == "old-refresh")
        }
    }

    @Test func successfulRefreshReplacesBothCredentials() async throws {
        try await withCredentials {
            let tokens = try await AccountService.performRefreshSession { response($0, status: 200, body: validBody) }
            #expect(tokens.accessToken == "new-access")
            #expect(TallaAccountCredentialStore.accessToken == "new-access")
            #expect(TallaAccountCredentialStore.refreshToken == "new-refresh")
        }
    }

    @Test(arguments: [200, 401]) func lateResponseDoesNotReplaceAnotherLogin(status: Int) async throws {
        try await withCredentials {
            do {
                _ = try await AccountService.performRefreshSession {
                    TallaAccountCredentialStore.save(accessToken: "other-access", refreshToken: "other-refresh")
                    return response($0, status: status, body: validBody)
                }
                Issue.record("A replaced login must cancel the old refresh")
            } catch is CancellationError {
                #expect(TallaAccountCredentialStore.accessToken == "other-access")
                #expect(TallaAccountCredentialStore.refreshToken == "other-refresh")
            }
        }
    }

    @Test func lateSuccessDoesNotUndoSignOut() async throws {
        try await withCredentials {
            do {
                _ = try await AccountService.performRefreshSession {
                    TallaAccountCredentialStore.clear()
                    return response($0, status: 200, body: validBody)
                }
                Issue.record("Signing out must cancel an in-flight refresh")
            } catch is CancellationError {
                #expect(TallaAccountCredentialStore.accessToken.isEmpty)
                #expect(TallaAccountCredentialStore.refreshToken.isEmpty)
            }
        }
    }
}
