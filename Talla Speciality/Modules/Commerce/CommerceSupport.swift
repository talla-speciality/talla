import Foundation
import SwiftUI
import StoreKit
#if canImport(Security)
import Security
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

struct ProductThumbnail: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.displayScale) var displayScale
    @AppStorage("app.appearanceMode") var savedAppearanceMode = "system"

    let imageURL: URL?
    let size: CGFloat?
    let cornerRadius: CGFloat

    var isLightAppearance: Bool {
        colorScheme == .light
    }

    var isOLEDAppearance: Bool {
        savedAppearanceMode == "oled"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: isLightAppearance
                            ? [Color(hex: 0xFFF9F2), Color(hex: 0xF2E2CD)]
                            : (isOLEDAppearance
                                ? [.black, .black]
                                : [Color(hex: 0x1A1612), Color(hex: 0x100D08)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                            lineWidth: 1
                        )
                )

            if let imageURL = retinaImageURL {
                AsyncImage(url: imageURL, transaction: Transaction(animation: nil)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(Color(hex: 0xC8965A))

                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(size == nil ? 12 : 4)

                    case .failure:
                        placeholder

                    @unknown default:
                        placeholder
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipped()
    }

    /// Shopify image URLs can retain a small `width` transform from an upstream
    /// response or cache. Always request enough physical pixels for Retina and
    /// ProMotion iPhones so SwiftUI never has to enlarge a thumbnail.
    var retinaImageURL: URL? {
        guard let imageURL else { return nil }
        guard imageURL.host?.localizedCaseInsensitiveContains("shopify") == true else {
            return imageURL
        }

        var components = URLComponents(url: imageURL, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.removeAll {
            ["width", "height"].contains($0.name.lowercased())
        }

        let renderedPoints = size ?? 420
        let targetPixels = max(768, min(2_048, Int(ceil(renderedPoints * displayScale * 1.5))))
        queryItems.append(URLQueryItem(name: "width", value: String(targetPixels)))
        components?.queryItems = queryItems
        return components?.url ?? imageURL
    }

    var placeholder: some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: 28))
            .foregroundColor(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.66 : 0.8))
    }
}

#if canImport(UserNotifications)

enum HomeSettingsService {
    static let baseURL = BackendConfiguration.serviceBaseURL

    static func fetchHomeSettings() async throws -> ContentView.HomeSettings {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Home settings service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/app/home-settings"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await TallaSecureSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The home settings service returned an invalid response.")
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The home settings service could not complete your request.")
        }

        return try JSONDecoder().decode(ContentView.HomeSettings.self, from: data)
    }

    static func fetchPassportSettings() async throws -> ContentView.PassportSettings {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Passport settings service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/app/passport-settings"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await TallaSecureSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The passport settings service returned an invalid response.")
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The passport settings service could not complete your request.")
        }

        return try JSONDecoder().decode(ContentView.PassportSettings.self, from: data)
    }

    static func fetchAppSettings() async throws -> ContentView.AppSettings {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "App settings service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/app/settings"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await TallaSecureSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The app settings service returned an invalid response.")
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The app settings service could not complete your request.")
        }

        return try JSONDecoder().decode(ContentView.AppSettings.self, from: data)
    }

    static func fetchEventSettings() async throws -> ContentView.EventSettings {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Events service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/app/events"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await TallaSecureSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200 ..< 300 ~= httpResponse.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The events service could not complete your request.")
        }

        return try JSONDecoder().decode(ContentView.EventSettings.self, from: data)
    }
}

struct CheckoutWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}
#else
struct CheckoutWebView: View {
    let url: URL

    var body: some View {
        VStack(spacing: 16) {
            Text(AppLocalization.text("checkout_only_iphone", fallback: "Checkout is only available on iPhone."))
                .font(.headline)
            Text(url.absoluteString)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
}
#endif

enum ShopifyStorefrontClient {
    static let endpoint = URL(string: "https://\(ShopifyConfiguration.shopDomain)/api/2025-10/graphql.json")!
    static let brewingArticlePageSize = 50

    static func fetchAllProducts() async throws -> [ContentView.Product] {
        var products: [ContentView.Product] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            let response = try await fetchPage(after: cursor)

            products.append(contentsOf: response.products.edges.compactMap { edge in
                guard ContentView.Product.shouldInclude(shopifyNode: edge.node) else {
                    return nil
                }
                return ContentView.Product(shopifyNode: edge.node)
            })

            hasNextPage = response.products.pageInfo.hasNextPage
            cursor = response.products.pageInfo.endCursor
        }

        return products
    }

    static func fetchBrewingMethods() async throws -> [ContentView.BrewingMethod] {
        let nodesFromBlog = try await fetchBrewingBlogArticleNodes()
        let fallbackNodes = nodesFromBlog.isEmpty ? try await fetchBrewingSearchArticleNodes() : []
        let selectedNodes = uniqueArticleNodes(nodesFromBlog.isEmpty ? fallbackNodes : nodesFromBlog)

        guard !selectedNodes.isEmpty else {
            throw ShopifyError.api("No brewing articles are available in Shopify yet.")
        }

        return selectedNodes.map(ContentView.BrewingMethod.init(article:))
    }

    static func fetchBrewingBlogArticleNodes() async throws -> [ShopifyBrewingArticlesResponse.ArticleNode] {
        var nodes: [ShopifyBrewingArticlesResponse.ArticleNode] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            var variables: [String: Any] = [
                "handle": ShopifyConfiguration.brewingBlogHandle,
                "first": brewingArticlePageSize
            ]
            if let cursor {
                variables["cursor"] = cursor
            }

            let body = ShopifyGraphQLRequest(
                query: """
                query BrewingBlogArticles($handle: String!, $first: Int!, $cursor: String) {
                  blog(handle: $handle) {
                    articles(first: $first, after: $cursor) {
                      pageInfo {
                        hasNextPage
                        endCursor
                      }
                      edges {
                        node {
                          id
                          handle
                          title
                          excerpt
                          content
                          tags
                          onlineStoreUrl
                          blog {
                            handle
                            title
                          }
                        }
                      }
                    }
                  }
                }
                """,
                variables: variables
            )

            let decoded: ShopifyBrewingArticlesResponse = try await performRequest(body)

            if let errors = decoded.errors, let first = errors.first {
                throw ShopifyError.api(first.message)
            }

            guard let connection = decoded.data?.blog?.articles else {
                return nodes
            }

            nodes.append(contentsOf: connection.edges.map(\.node))
            hasNextPage = connection.pageInfo.hasNextPage
            cursor = connection.pageInfo.endCursor
        }

        return nodes
    }

    static func fetchBrewingSearchArticleNodes() async throws -> [ShopifyBrewingArticlesResponse.ArticleNode] {
        var nodes: [ShopifyBrewingArticlesResponse.ArticleNode] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            var variables: [String: Any] = [
                "query": ShopifyConfiguration.brewingArticlesQuery,
                "first": brewingArticlePageSize
            ]
            if let cursor {
                variables["cursor"] = cursor
            }

            let body = ShopifyGraphQLRequest(
                query: """
                query BrewingSearchArticles($query: String!, $first: Int!, $cursor: String) {
                  articles(first: $first, after: $cursor, sortKey: PUBLISHED_AT, reverse: true, query: $query) {
                    pageInfo {
                      hasNextPage
                      endCursor
                    }
                    edges {
                      node {
                        id
                        handle
                        title
                        excerpt
                          content
                        tags
                        onlineStoreUrl
                        blog {
                          handle
                          title
                        }
                      }
                    }
                  }
                }
                """,
                variables: variables
            )

            let decoded: ShopifyBrewingArticlesResponse = try await performRequest(body)

            if let errors = decoded.errors, let first = errors.first {
                throw ShopifyError.api(first.message)
            }

            guard let connection = decoded.data?.articles else {
                return nodes
            }

            nodes.append(contentsOf: connection.edges.map(\.node))
            hasNextPage = connection.pageInfo.hasNextPage
            cursor = connection.pageInfo.endCursor
        }

        return nodes
    }

    static func uniqueArticleNodes(_ nodes: [ShopifyBrewingArticlesResponse.ArticleNode]) -> [ShopifyBrewingArticlesResponse.ArticleNode] {
        var seenIDs: Set<String> = []
        return nodes.filter { node in
            seenIDs.insert(node.id).inserted
        }
    }

    static func createCustomerAccessToken(email: String, password: String) async throws -> ShopifyCustomerSession {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CustomerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
              customerAccessTokenCreate(input: $input) {
                customerAccessToken {
                  accessToken
                  expiresAt
                }
                customerUserErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": [
                    "email": email,
                    "password": password
                ]
            ]
        )

        let decoded: ShopifyCustomerAccessTokenCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.customerAccessTokenCreate.customerUserErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let session = decoded.data?.customerAccessTokenCreate.customerAccessToken else {
            throw ShopifyError.invalidResponse
        }

        return session
    }

    static func createCustomer(firstName: String, lastName: String, email: String, password: String) async throws -> ShopifyCustomerCreateResponse.CreatedCustomer {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CustomerCreate($input: CustomerCreateInput!) {
              customerCreate(input: $input) {
                customer {
                  id
                }
                customerUserErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": [
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    "password": password
                ]
            ]
        )

        let decoded: ShopifyCustomerCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.customerCreate.customerUserErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let customer = decoded.data?.customerCreate.customer else {
            throw ShopifyError.invalidResponse
        }

        return customer
    }

    static func fetchCustomer(accessToken: String) async throws -> ContentView.ShopifyCustomerProfile {
        let body = ShopifyGraphQLRequest(
            query: """
            query Customer($customerAccessToken: String!) {
              customer(customerAccessToken: $customerAccessToken) {
                id
                firstName
                lastName
                email
              }
            }
            """,
            variables: [
                "customerAccessToken": accessToken
            ]
        )

        let decoded: ShopifyCustomerQueryResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let customer = decoded.data?.customer else {
            throw ShopifyError.api("Your account session has expired. Please sign in again.")
        }

        return ContentView.ShopifyCustomerProfile(
            id: customer.id,
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email
        )
    }

    static func fetchPage(after cursor: String?) async throws -> ShopifyProductsResponse.DataPayload {
        let body = ShopifyGraphQLRequest(
            query: """
            query Products($cursor: String) {
              products(first: 50, after: $cursor, sortKey: TITLE) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
                edges {
                  node {
                    id
                    handle
                    title
                    description
                    tags
                    productType
                    countryOfOrigin: metafield(namespace: "custom", key: "country_of_origin") {
                      value
                    }
                    featuredImage {
                      url
                    }
                    variants(first: 12) {
                      edges {
                        node {
                          id
                          title
                          availableForSale
                          requiresShipping
                          weight
                          weightUnit
                          price {
                            amount
                            currencyCode
                          }
                        }
                      }
                    }
                    priceRange {
                      minVariantPrice {
                        amount
                        currencyCode
                      }
                    }
                  }
                }
              }
            }
            """,
            variables: ["cursor": cursor as Any]
        )

        let decoded: ShopifyProductsResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let payload = decoded.data else {
            throw ShopifyError.invalidResponse
        }

        return payload
    }

    static func createCheckoutURL(
        lines: [ShopifyCheckoutLine],
        customerEmail: String? = nil,
        checkoutAddress: ShopifyCheckoutAddress? = nil,
        tallaPaymentID: String? = nil,
        fulfillmentMethod: TallaFulfillmentMethod = .delivery
    ) async throws -> URL {
        let lineInputs = lines.map { line in
            [
                "merchandiseId": line.merchandiseId,
                "quantity": line.quantity
            ] as [String: Any]
        }

        var input: [String: Any] = [
            "lines": lineInputs
        ]
        var attributes = [["key": "talla_fulfillment_method", "value": fulfillmentMethod.rawValue]]
        if let tallaPaymentID = tallaPaymentID?.trimmingCharacters(in: .whitespacesAndNewlines), !tallaPaymentID.isEmpty {
            attributes.append(["key": "talla_payment_id", "value": tallaPaymentID])
        }
        input["attributes"] = attributes
        var buyerIdentity: [String: Any] = [:]

        if let customerEmail = customerEmail?.trimmingCharacters(in: .whitespacesAndNewlines), !customerEmail.isEmpty {
            buyerIdentity["email"] = customerEmail
        }

        if let checkoutAddress {
            let nameParts = checkoutAddress.fullName
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            let firstName = nameParts.first ?? checkoutAddress.fullName
            let lastName = nameParts.dropFirst().joined(separator: " ")
            let deliveryAddress: [String: Any] = [
                "address1": checkoutAddress.address1,
                "city": checkoutAddress.city,
                "country": checkoutAddress.country,
                "firstName": firstName,
                "lastName": lastName,
                "phone": checkoutAddress.phone
            ]
            let deliveryAddressPreference: [String: Any] = [
                "deliveryAddress": deliveryAddress
            ]
            buyerIdentity["email"] = checkoutAddress.email
            buyerIdentity["phone"] = checkoutAddress.phone
            buyerIdentity["deliveryAddressPreferences"] = [deliveryAddressPreference]
        }

        if !buyerIdentity.isEmpty {
            input["buyerIdentity"] = buyerIdentity
        }

        let firstResponse = try await createCart(input: input)
        if let checkoutURL = firstResponse.data?.cartCreate.cart?.checkoutUrl {
            return checkoutURL
        }

        if input.removeValue(forKey: "buyerIdentity") != nil {
            let fallbackResponse = try await createCart(input: input)
            if let checkoutURL = fallbackResponse.data?.cartCreate.cart?.checkoutUrl {
                return checkoutURL
            }
            if let userError = fallbackResponse.data?.cartCreate.userErrors.first {
                throw ShopifyError.api(userError.message)
            }
            if let error = fallbackResponse.errors?.first {
                throw ShopifyError.api(error.message)
            }
        }

        if let userError = firstResponse.data?.cartCreate.userErrors.first {
            throw ShopifyError.api(userError.message)
        }
        if let error = firstResponse.errors?.first {
            throw ShopifyError.api(error.message)
        }
        throw ShopifyError.invalidResponse
    }

    static func createCart(input: [String: Any]) async throws -> ShopifyCartCreateResponse {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CreateCart($input: CartInput) {
              cartCreate(input: $input) {
                cart {
                  checkoutUrl
                }
                userErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": input
            ]
        )
        return try await performRequest(body)
    }

    static func performRequest<Response: Decodable>(_ body: ShopifyGraphQLRequest) async throws -> Response {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ShopifyConfiguration.storefrontToken, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")
        request.httpBody = try JSONSerialization.data(withJSONObject: body.dictionary, options: [])

        let (data, response) = try await TallaSecureSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ShopifyError.invalidResponse
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

struct ShopifyConfiguration {
    static let shopDomain = "duneroastery.myshopify.com"
    static let storefrontToken = "0b8e38878678cd9b9db8325f88f95141"
    static let accountLoginURL = URL(string: "https://\(shopDomain)/account/login")!
    static let accountRegisterURL = URL(string: "https://\(shopDomain)/account/register")!
    static let brewingBlogHandle = "brewing-methods"
    static let brewingArticlesQuery = "blog_title:\"Brewing Methods\" OR tag:brewing OR tag:brew"
}

struct ShopifyGraphQLRequest {
    let query: String
    let variables: [String: Any]

    var dictionary: [String: Any] {
        [
            "query": query,
            "variables": variables
        ]
    }
}

struct ShopifyProductsResponse: Decodable {
    let data: DataPayload?
    let errors: [GraphQLError]?

    struct DataPayload: Decodable {
        let products: ProductConnection
    }

    struct ProductConnection: Decodable {
        let pageInfo: PageInfo
        let edges: [ProductEdge]
    }

    struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
    }

    struct ProductEdge: Decodable {
        let node: ShopifyProductNode
    }

    struct GraphQLError: Decodable {
        let message: String
    }
}

struct ShopifyProductNode: Decodable {
    let id: String
    let handle: String
    let title: String
    let description: String
    let tags: [String]
    let productType: String
    let countryOfOrigin: Metafield?
    let featuredImage: FeaturedImage?
    let variants: VariantConnection
    let priceRange: PriceRange

    struct FeaturedImage: Decodable {
        let url: URL
    }

    struct Metafield: Decodable {
        let value: String
    }

    struct PriceRange: Decodable {
        let minVariantPrice: Money
    }

    struct VariantConnection: Decodable {
        let edges: [VariantEdge]
    }

    struct VariantEdge: Decodable {
        let node: ProductVariant
    }

    struct ProductVariant: Decodable {
        let id: String
        let title: String
        let availableForSale: Bool
        let requiresShipping: Bool
        let weight: Double?
        let weightUnit: WeightUnit
        let price: Money

        enum WeightUnit: String, Decodable {
            case grams = "GRAMS"
            case kilograms = "KILOGRAMS"
            case ounces = "OUNCES"
            case pounds = "POUNDS"
        }

        var weightGrams: Double? {
            guard let weight else { return nil }
            switch weightUnit {
            case .grams: return weight
            case .kilograms: return weight * 1_000
            case .ounces: return weight * 28.349_523_125
            case .pounds: return weight * 453.592_37
            }
        }
    }

    struct Money: Decodable {
        let amount: String
        let currencyCode: String
    }
}

enum ShopifyError: LocalizedError {
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The Shopify response was invalid."
        case .api(let message):
            return message
        }
    }
}

struct ShopifyCheckoutLine {
    let merchandiseId: String
    let quantity: Int
}

struct ShopifyCheckoutAddress {
    let email: String
    let fullName: String
    let phone: String
    let address1: String
    let city: String
    let country: String
}

struct ShopifyCartCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let cartCreate: CartCreatePayload
    }

    struct CartCreatePayload: Decodable {
        let cart: Cart?
        let userErrors: [UserError]
    }

    struct Cart: Decodable {
        let checkoutUrl: URL
    }

    struct UserError: Decodable {
        let message: String
    }
}

struct ShopifyCustomerSession: Decodable {
    let accessToken: String
    let expiresAt: String
}

struct ShopifyCustomerAccessTokenCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customerAccessTokenCreate: CustomerAccessTokenCreatePayload
    }

    struct CustomerAccessTokenCreatePayload: Decodable {
        let customerAccessToken: ShopifyCustomerSession?
        let customerUserErrors: [ShopifyCustomerUserError]
    }

    struct ShopifyCustomerUserError: Decodable {
        let message: String
    }
}

struct ShopifyCustomerQueryResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customer: Customer?
    }

    struct Customer: Decodable {
        let id: String
        let firstName: String?
        let lastName: String?
        let email: String
    }
}

struct ShopifyCustomerCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customerCreate: CustomerCreatePayload
    }

    struct CustomerCreatePayload: Decodable {
        let customer: CreatedCustomer?
        let customerUserErrors: [ShopifyCustomerAccessTokenCreateResponse.ShopifyCustomerUserError]
    }

    struct CreatedCustomer: Decodable {
        let id: String
    }
}

struct ShopifyBrewingArticlesResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let blog: Blog?
        let articles: ArticleConnection?
    }

    struct Blog: Decodable {
        let articles: ArticleConnection
    }

    struct ArticleConnection: Decodable {
        let pageInfo: PageInfo
        let edges: [ArticleEdge]
    }

    struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
    }

    struct ArticleEdge: Decodable {
        let node: ArticleNode
    }

    struct ArticleNode: Decodable {
        let id: String
        let handle: String
        let title: String
        let excerpt: String?
        let content: String
        let tags: [String]
        let onlineStoreUrl: URL?
        let blog: BlogSummary
    }

    struct BlogSummary: Decodable {
        let handle: String
        let title: String
    }
}

struct AccountProfileResponse: Decodable {
    let id: String
    let firstName: String?
    let lastName: String?
    let email: String
}

struct AccountSessionResponse: Decodable {
    let profile: AccountProfileResponse
    let accessToken: String
    let expiresAt: String
    let refreshToken: String
    let refreshExpiresAt: String
}

struct AccountTokenRefreshResponse: Decodable, Sendable {
    let accessToken: String
    let expiresAt: String
    let refreshToken: String
    let refreshExpiresAt: String
}

struct TasteMemoryResponse: Decodable {
    let tasteMemory: [ContentView.TasteMemoryRecord]
}

struct CheckoutStartResponse: Decodable {
    let orderID: String
    let orders: [ContentView.AccountOrder]
}

struct BenefitPaymentResponse: Decodable {
    let paymentUrl: URL
    let trackId: String
}

struct BenefitHostedPaymentStatus: Decodable {
    let orderId: String
    let status: String
    let paid: Bool
}

struct EazyShopifyPaymentResponse: Decodable {
    let tallaPaymentId: String
    let shopifyOrderName: String?
    let status: String
    let paymentUrl: URL?
    let paid: Bool
    let pending: Bool
    let message: String?
}

struct ServiceErrorResponse: Decodable {
    let error: String
}

enum ProductCatalogRules {
    static func shouldInclude(title: String, productType: String, tags: [String]) -> Bool {
        let source = ([title, productType] + tags)
            .joined(separator: " ")
            .lowercased()

        return !source.contains("gift card") && !source.contains("giftcard")
    }

    static func categoryKey(productType: String, tags: [String], title: String) -> String {
        if let appCategory = appCategoryOverride(from: tags) {
            return appCategory
        }

        let parts = [title, productType] + tags
        let source = parts.joined(separator: " ").lowercased()
        let sourceSlug = slug(from: parts.joined(separator: " "))
        let typeSlug = slug(from: productType)

        if typeSlug == "summer-drinks" {
            return "summer-drinks"
        }

        if containsAny(sourceSlug, [
            "hot-chocolate", "hot-cocoa", "cocoa-mix", "cacao", "chocolate-powder"
        ]) || typeSlug == "hot-chocolate" {
            return "hot-chocolate"
        }

        if containsAny(sourceSlug, [
            "jam", "jams", "spread", "spreads", "butter", "butters", "sauce", "sauces", "honey", "jar", "jars"
        ]) || ["spreads", "spread", "jams", "butters"].contains(typeSlug) {
            return "spreads"
        }

        if containsAny(sourceSlug, [
            "crmb", "bakery", "dessert", "desserts", "pastry", "pastries", "croissant",
            "cookie", "cookies", "cake", "cakes", "brownie", "brownies", "fudge",
            "creme-caramel", "crème-caramel", "cream-caramel", "caramel", "bread", "breads", "banana-bread"
        ]) || ["crmb", "desserts", "dessert", "bread", "bakery", "pastries"].contains(typeSlug) {
            return "desserts"
        }

        if containsAny(sourceSlug, [
            "bottle", "bottled", "ready-made", "ready-made-drink", "ready-made-drinks",
            "tea", "karak", "matcha", "juice", "beverage", "beverages"
        ]) || ["tea", "ready-made-drinks", "drinks", "ready-made"].contains(typeSlug) {
            return "ready-made-drinks"
        }

        if containsAny(sourceSlug, [
            "cup", "cups", "latte-cup", "drink-cup", "talla-cup", "mug", "mugs", "tumbler", "tumblers", "drinkware"
        ]) || ["drink-cups", "cups", "mugs", "drinkware"].contains(typeSlug) {
            return "cups"
        }

        if containsAny(sourceSlug, [
            "drip-bag", "drip-bags", "drip-coffee-bag", "single-serve", "coffee-bag"
        ]) || typeSlug == "drip-bags" {
            return "drip-bags"
        }

        if containsAny(sourceSlug, [
            "equipment", "brewer", "brewers", "tool", "tools", "accessory", "accessories",
            "v60", "filter", "filters", "scale", "grinder", "kettle", "server", "dripper",
            "aeropress", "chemex", "french-press"
        ]) || ["coffee-equipment", "equipment", "accessories"].contains(typeSlug) {
            return "coffee-equipment"
        }

        if containsAny(sourceSlug, [
            "talla-box", "mini-talla-box", "mini-coffee-box", "mini-arabic-coffee-box",
            "gift-box", "gift-set", "gift-bundle", "seasonal-gift", "bundle", "majlis", "eid"
        ]) || source.contains("عيد") || ["gifts", "gift", "eid-gifts"].contains(typeSlug) {
            return "gifts"
        }

        if containsAny(sourceSlug, [
            "arabic-coffee", "shamali", "northern-coffee", "turkish", "qahwa", "gahwa",
            "dallah", "cardamom"
        ]) || ["arabic-coffee", "arabic-coffee-beans", "northern-coffee"].contains(typeSlug) {
            return "arabic-coffee-beans"
        }

        if containsAny(sourceSlug, [
            "coffee-bean", "coffee-beans", "beans", "espresso", "roast", "roasted", "single-origin",
            "brazil", "colombia", "ethiopia", "yemen", "decaf"
        ]) || ["coffee", "coffee-beans", "beans"].contains(typeSlug) {
            return "coffee-beans"
        }

        return "coffee-beans"
    }

    static func categoryLabel(productType: String, fallbackKey: String) -> String {
        switch fallbackKey {
        case "summer-drinks":
            return "Summer Boxes"
        case "coffee-beans":
            return "Coffee Beans"
        case "arabic-coffee-beans", "arabic-coffee", "northern-coffee", "other":
            return "Arabic & Shamali Coffee"
        case "drip-bags":
            return "Drip Bags"
        case "coffee-equipment":
            return "Equipment"
        case "ready-made-drinks", "tea", "drinks":
            return "Drinks"
        case "drink-cups", "cups", "mugs", "drinkware":
            return "Cups"
        case "crmb-tallas-speciality-bakery", "desserts", "bread", "bakery":
            return "CRMB"
        case "spreads":
            return "Spreads"
        case "hot-chocolate":
            return "Hot Chocolate"
        case "gifts", "eid-gifts":
            return "Talla Boxes"
        default:
            return fallbackKey
                .split(separator: "-")
                .map { $0.capitalized }
                .joined(separator: " ")
        }
    }

    static func productTag(from tags: [String]) -> String? {
        let preferred = ["STAFF PICK", "BESTSELLER", "LIMITED", "NEW", "LOCAL", "PREMIUM", "GIFT"]
        let uppercased = tags.map { $0.uppercased() }
        guard let tag = preferred.first(where: uppercased.contains) else { return nil }
        return tag == "BESTSELLER" ? "BEST SELLER" : tag
    }

    static func countryOfOriginLabel(from tags: [String]) -> String? {
        let countryNamesByTag = [
            "bolivia": "Bolivia",
            "brazil": "Brazil",
            "burundi": "Burundi",
            "colombia": "Colombia",
            "costa rica": "Costa Rica",
            "ecuador": "Ecuador",
            "el salvador": "El Salvador",
            "ethiopia": "Ethiopia",
            "greece": "Greece",
            "guatemala": "Guatemala",
            "honduras": "Honduras",
            "india": "India",
            "indonesia": "Indonesia",
            "kenya": "Kenya",
            "kuwait": "Kuwait",
            "mexico": "Mexico",
            "nicaragua": "Nicaragua",
            "panama": "Panama",
            "papua new guinea": "Papua New Guinea",
            "peru": "Peru",
            "qatar": "Qatar",
            "rwanda": "Rwanda",
            "tanzania": "Tanzania",
            "thailand": "Thailand",
            "uganda": "Uganda",
            "united arab emirates": "United Arab Emirates",
            "uae": "United Arab Emirates",
            "vietnam": "Vietnam",
            "yemen": "Yemen"
        ]
        var seenCountries = Set<String>()
        let countries = tags.compactMap { tag -> String? in
            let normalizedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let country = countryNamesByTag[normalizedTag], seenCountries.insert(country).inserted else {
                return nil
            }
            return country
        }

        guard let firstCountry = countries.first else { return nil }
        return countries.count == 1 ? firstCountry : "\(firstCountry) +\(countries.count - 1)"
    }

    static func containsAny(_ source: String, _ needles: [String]) -> Bool {
        needles.contains { source.contains($0) }
    }

    static func appCategoryOverride(from tags: [String]) -> String? {
        for tag in tags {
            let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercasedTag = trimmedTag.lowercased()
            let prefixes = ["app-category:", "app-category=", "app_category:", "app_category="]

            guard let prefix = prefixes.first(where: { lowercasedTag.hasPrefix($0) }) else {
                continue
            }

            let rawValue = String(trimmedTag.dropFirst(prefix.count))
            if let categoryKey = canonicalAppCategoryKey(from: rawValue) {
                return categoryKey
            }
        }

        for tag in tags {
            switch slug(from: tag) {
            case "cups", "cup", "drink-cups", "mugs", "mug", "drinkware", "tumblers", "tumbler":
                return "cups"
            case "ready-made-drinks", "ready-made", "drinks", "drink":
                return "ready-made-drinks"
            default:
                continue
            }
        }

        return nil
    }

    static func canonicalAppCategoryKey(from value: String) -> String? {
        switch slug(from: value) {
        case "coffee", "coffee-beans", "beans":
            return "coffee-beans"
        case "arabic-coffee", "arabic-coffee-beans", "northern-coffee", "shamali":
            return "arabic-coffee-beans"
        case "drip-bags", "drip-bag":
            return "drip-bags"
        case "cups", "cup", "drink-cups", "mugs", "mug", "drinkware", "tumblers", "tumbler":
            return "cups"
        case "ready-made-drinks", "ready-made", "drinks", "drink", "tea", "karak", "matcha", "cups-and-drinks":
            return "ready-made-drinks"
        case "desserts", "dessert", "crmb", "bakery", "bread":
            return "desserts"
        case "spreads", "spread", "jams", "butters":
            return "spreads"
        case "hot-chocolate", "hot-cocoa", "cocoa":
            return "hot-chocolate"
        case "equipment", "coffee-equipment", "accessories", "tools":
            return "coffee-equipment"
        case "gifts", "gift", "talla-boxes", "boxes", "eid-gifts":
            return "gifts"
        default:
            return nil
        }
    }

    static func slug(from value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

extension ContentView.Product {
    static func shouldInclude(shopifyNode: ShopifyProductNode) -> Bool {
        ProductCatalogRules.shouldInclude(
            title: shopifyNode.title,
            productType: shopifyNode.productType,
            tags: shopifyNode.tags
        )
    }

    init(shopifyNode: ShopifyProductNode) {
        let categoryKey = ProductCatalogRules.categoryKey(
            productType: shopifyNode.productType,
            tags: shopifyNode.tags,
            title: shopifyNode.title
        )
        let variants = shopifyNode.variants.edges.map { edge in
            Variant(
                id: edge.node.id,
                title: edge.node.title.isEmpty ? "Default" : edge.node.title,
                price: Self.formattedPrice(from: edge.node.price),
                isAvailableForSale: edge.node.availableForSale,
                requiresShipping: edge.node.requiresShipping,
                weightGrams: edge.node.weightGrams
            )
        }
        let defaultVariant = variants.first(where: \.isAvailableForSale) ?? variants.first
        let metafieldCountryOfOrigin = shopifyNode.countryOfOrigin?.value
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let countryOfOrigin = metafieldCountryOfOrigin?.isEmpty == false
            ? metafieldCountryOfOrigin
            : ProductCatalogRules.countryOfOriginLabel(from: shopifyNode.tags)

        self.init(
            id: shopifyNode.id,
            handle: shopifyNode.handle,
            variantID: defaultVariant?.id,
            variants: variants,
            name: shopifyNode.title,
            price: defaultVariant?.price ?? Self.formattedPrice(from: shopifyNode.priceRange.minVariantPrice),
            categoryKey: categoryKey,
            categoryLabel: ProductCatalogRules.categoryLabel(productType: shopifyNode.productType, fallbackKey: categoryKey),
            imageURL: shopifyNode.featuredImage?.url,
            desc: shopifyNode.description,
            tag: ProductCatalogRules.productTag(from: shopifyNode.tags),
            countryOfOrigin: countryOfOrigin,
            isAvailableForSale: defaultVariant?.isAvailableForSale ?? false
        )
    }

    static func formattedPrice(from money: ShopifyProductNode.Money) -> String {
        guard let decimal = Decimal(string: money.amount) else {
            return "\(money.amount) \(money.currencyCode)"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = money.currencyCode == "BHD" ? 3 : 2

        return formatter.string(from: decimal as NSDecimalNumber) ?? "\(money.amount) \(money.currencyCode)"
    }
}

extension ContentView.BrewingMethod {
    init(article: ShopifyBrewingArticlesResponse.ArticleNode) {
        let summarySource = [article.excerpt, article.content]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Brew guide from Shopify."

        self.init(
            id: article.id,
            name: article.title,
            summary: summarySource,
            detail: article.blog.title,
            symbol: Self.symbol(title: article.title, tags: article.tags),
            articleURL: article.onlineStoreUrl ?? Self.articleURL(blogHandle: article.blog.handle, articleHandle: article.handle),
            categories: Self.categories(title: article.title, tags: article.tags),
            difficulty: Self.difficulty(title: article.title, tags: article.tags),
            brewTime: Self.brewTime(title: article.title, tags: article.tags),
            publishedRecipe: Self.publishedRecipe(from: article.content)
        )
    }

    static func publishedRecipe(from content: String) -> PublishedRecipe? {
        let coffee = firstNumber(in: content, pattern: #"([0-9]+(?:\.[0-9]+)?)\s*g\s+(?:[A-Za-z-]+\s+){0,3}coffee"#)
        let ratio = firstNumber(in: content, pattern: #"Brew\s*Ratio\s*:\s*1\s*:\s*([0-9]+(?:\.[0-9]+)?)"#)
        let water = firstNumber(in: content, pattern: #"([0-9]+(?:\.[0-9]+)?)\s*(?:ml|g)\s+(?:[A-Za-z-]+\s+){0,3}water"#)
        let ice = firstNumber(in: content, pattern: #"([0-9]+(?:\.[0-9]+)?)\s*g\s+ice"#)

        guard coffee != nil || ratio != nil || water != nil || ice != nil else {
            return nil
        }

        return PublishedRecipe(coffeeGrams: coffee, ratio: ratio, waterGrams: water, iceGrams: ice)
    }

    static func firstNumber(in text: String, pattern: String) -> Double? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = expression.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let numberRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return Double(text[numberRange])
    }

    static func symbol(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("press") {
            return "cup.and.saucer.fill"
        }

        if source.contains("chemex") || source.contains("filter") {
            return "flask.fill"
        }

        if source.contains("espresso") {
            return "bolt.fill"
        }

        if source.contains("cold") {
            return "snowflake"
        }

        return "drop.fill"
    }

    static func categories(title: String, tags: [String]) -> [String] {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("cold") {
            return ["Cold Brew"]
        }

        if source.contains("arabic") || source.contains("dallah") || source.contains("traditional") {
            return ["Traditional"]
        }

        if source.contains("press") || source.contains("immersion") {
            return ["Immersion"]
        }

        if source.contains("chemex") || source.contains("v60") || source.contains("pour") || source.contains("filter") {
            return ["Pour Over"]
        }

        return ["Pour Over"]
    }

    static func difficulty(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("espresso") || source.contains("v60") {
            return "Advanced"
        }

        if source.contains("chemex") || source.contains("pour") || source.contains("aeropress") {
            return "Intermediate"
        }

        return "Easy"
    }

    static func brewTime(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("cold") {
            return "8-12 hr"
        }

        if source.contains("espresso") {
            return "30 sec"
        }

        if source.contains("press") {
            return "4 min"
        }

        if source.contains("chemex") {
            return "4-5 min"
        }

        if source.contains("pour") || source.contains("v60") || source.contains("filter") {
            return "3-4 min"
        }

        return "3–5 min"
    }

    static func articleURL(blogHandle: String, articleHandle: String) -> URL? {
        URL(string: "https://\(ShopifyConfiguration.shopDomain)/blogs/\(blogHandle)/\(articleHandle)")
    }
}

extension ContentView {
    static func randomAppleNonce(length: Int = 32) -> String {
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var nonce = ""
        nonce.reserveCapacity(length)

        while nonce.count < length {
            let randomValue = Int.random(in: 0 ..< characters.count)
            nonce.append(characters[randomValue])
        }

        return nonce
    }

    static func sha256(_ input: String) -> String {
#if canImport(CryptoKit)
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
#else
        return input
#endif
    }
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

extension Array where Element: Identifiable {
    func uniquedByID() -> [Element] where Element.ID: Hashable {
        var seenIDs = Set<Element.ID>()
        return filter { element in
            seenIDs.insert(element.id).inserted
        }
    }
}
