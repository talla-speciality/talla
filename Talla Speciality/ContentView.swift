import Foundation
import SwiftUI

struct ContentView: View {
    private enum Tab: String, CaseIterable {
        case home
        case shop
        case brewing
        case about
    }

    private struct Product: Identifiable, Hashable {
        let id: String
        let name: String
        let price: String
        let categoryKey: String
        let categoryLabel: String
        let imageURL: URL?
        let desc: String
        let tag: String?
    }

    private struct BrewingMethod: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let time: String
        let difficulty: String
        let symbol: String
    }

    private struct CartItem: Identifiable, Hashable {
        let id: String
        let product: Product
        var quantity: Int
    }

    @State private var activeTab: Tab = .home
    @State private var activeCategory = "all"
    @State private var products: [Product] = []
    @State private var cartItems: [CartItem] = []
    @State private var cartOpen = false
    @State private var toastMessage: String?
    @State private var isLoadingProducts = false
    @State private var hasLoadedProducts = false
    @State private var loadingError: String?

    private let brewingMethods: [BrewingMethod] = [
        BrewingMethod(name: "Pour Over", time: "3-4 min", difficulty: "Medium", symbol: "drop.fill"),
        BrewingMethod(name: "French Press", time: "4 min", difficulty: "Easy", symbol: "cup.and.saucer.fill"),
        BrewingMethod(name: "Chemex", time: "4-5 min", difficulty: "Medium", symbol: "flask.fill"),
        BrewingMethod(name: "AeroPress", time: "2-3 min", difficulty: "Easy", symbol: "gauge.with.dots.needle.67percent")
    ]

    private var cartCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    private var availableCategories: [String] {
        let dynamic = Set(products.map(\.categoryKey))
        let preferredOrder = ["beans", "drip", "equipment", "gifts", "food"]
        let ordered = preferredOrder.filter { dynamic.contains($0) }
        let extra = dynamic.subtracting(preferredOrder).sorted()
        return ["all"] + ordered + extra
    }

    private var filteredProducts: [Product] {
        guard activeCategory != "all" else { return products }
        return products.filter { $0.categoryKey == activeCategory }
    }

    var body: some View {
        ZStack {
            Color(hex: 0x0A0804)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        switch activeTab {
                        case .home:
                            homeView
                        case .shop:
                            shopView
                        case .brewing:
                            brewingView
                        case .about:
                            aboutView
                        }

                        footer
                    }
                }
            }

            if cartOpen {
                cartDrawer
            }

            if let toastMessage {
                toastView(message: toastMessage)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: cartOpen)
        .task {
            await loadProductsIfNeeded()
        }
    }

    private var header: some View {
        HStack {
            Button {
                activeTab = .home
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xC8965A), Color(hex: 0x8A5E30)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: 0x0A0804))
                        )

                    Text("TALLA")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .tracking(3)
                        .foregroundColor(Color(hex: 0xF5EDE0))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 6) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .light))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor(activeTab == tab ? Color(hex: 0xC8965A) : Color(hex: 0xF5EDE0).opacity(0.55))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button {
                cartOpen = true
            } label: {
                HStack(spacing: 6) {
                    Text("BAG")
                    if cartCount > 0 {
                        Text("\(cartCount)")
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 16, height: 16)
                            .background(Color(hex: 0xC8965A))
                            .clipShape(Circle())
                            .foregroundColor(Color(hex: 0x0A0804))
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(hex: 0xC8965A).opacity(0.35), lineWidth: 1)
                )
                .foregroundColor(Color(hex: 0xC8965A))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 60)
        .background(Color(hex: 0x0A0804).opacity(0.95))
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xC8965A).opacity(0.12))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            heroSection
            featureStrip
            featuredProducts
            collections
        }
    }

    private var heroSection: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: 0xC8965A).opacity(0.06), lineWidth: 1)
                .frame(width: 520, height: 520)
                .offset(y: -20)

            Circle()
                .stroke(Color(hex: 0xC8965A).opacity(0.1), lineWidth: 1)
                .frame(width: 360, height: 360)
                .offset(y: -20)

            VStack(spacing: 20) {
                Text("Imported from Shopify")
                    .font(.system(size: 10, weight: .light))
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                Text("SPECIALTY\nROASTED\nIN BAHRAIN")
                    .font(.system(size: 56, weight: .bold, design: .serif))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(hex: 0xF5EDE0))

                Text("Your live Shopify catalog is now the product source for the app.")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.6))
                    .frame(maxWidth: 440)

                HStack(spacing: 14) {
                    Button {
                        activeTab = .shop
                    } label: {
                        Text("SHOP NOW")
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(3)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 28)
                            .background(Color(hex: 0xC8965A))
                            .cornerRadius(2)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await loadProducts(force: true)
                        }
                    } label: {
                        Text(isLoadingProducts ? "LOADING..." : "REFRESH")
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(3)
                            .foregroundColor(Color(hex: 0xF5EDE0))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color(hex: 0xF5EDE0).opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingProducts)
                }
            }
            .padding(.vertical, 80)
            .padding(.horizontal, 24)
        }
        .frame(minHeight: 520)
    }

    private var featureStrip: some View {
        HStack(spacing: 24) {
            featureItem(symbol: "globe", label: "Live Shopify Sync")
            featureItem(symbol: "shippingbox.fill", label: "Published Products")
            featureItem(symbol: "photo", label: "Remote Images")
            featureItem(symbol: "arrow.clockwise", label: "Manual Refresh")
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .overlay(
            VStack(spacing: 0) {
                Rectangle().fill(Color(hex: 0xC8965A).opacity(0.1)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color(hex: 0xC8965A).opacity(0.1)).frame(height: 1)
            }
        )
    }

    private var featuredProducts: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Curated for you")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))
                    Text("FEATURED PICKS")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundColor(Color(hex: 0xF5EDE0))
                }

                Spacer()

                Button {
                    activeTab = .shop
                } label: {
                    Text("View All")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))
                        .underline()
                }
                .buttonStyle(.plain)
            }

            if isLoadingProducts && products.isEmpty {
                loadingSection
            } else if let loadingError, products.isEmpty {
                errorSection(message: loadingError)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                    ForEach(Array(products.prefix(4))) { product in
                        productCard(product: product, showDescription: false)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 60)
    }

    private var collections: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("COLLECTIONS")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundColor(Color(hex: 0xF5EDE0))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                collectionTile(name: "Coffee Beans", desc: "Single-origin and whole bean products.", systemImage: "leaf.fill", color: Color(hex: 0x3D1F00), categoryKey: "beans")
                collectionTile(name: "Premium Equipment", desc: "Brewing tools and accessories.", systemImage: "flask.fill", color: Color(hex: 0x001F2E), categoryKey: "equipment")
                collectionTile(name: "Gift Boxes", desc: "Bundles, boxes, and gifting sets.", systemImage: "gift.fill", color: Color(hex: 0x1A1A00), categoryKey: "gifts")
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 80)
    }

    private var shopView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Explore")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))
                Text("ALL PRODUCTS")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundColor(Color(hex: 0xF5EDE0))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableCategories, id: \.self) { category in
                        Button {
                            activeCategory = category
                        } label: {
                            Text(categoryLabel(for: category))
                                .font(.system(size: 10, weight: .medium))
                                .tracking(3)
                                .textCase(.uppercase)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .foregroundColor(activeCategory == category ? Color(hex: 0x0A0804) : Color(hex: 0xC8965A))
                                .background(activeCategory == category ? Color(hex: 0xC8965A) : .clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: 0xC8965A).opacity(0.25), lineWidth: 1)
                                )
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }

            if isLoadingProducts && products.isEmpty {
                loadingSection
            } else if let loadingError, products.isEmpty {
                errorSection(message: loadingError)
            } else if filteredProducts.isEmpty {
                emptySection
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                    ForEach(filteredProducts) { product in
                        productCard(product: product, showDescription: true)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
    }

    private var brewingView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("The craft")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))
                Text("BREWING METHODS")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundColor(Color(hex: 0xF5EDE0))
                Text("Master the art of the perfect cup.")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.5))
                    .padding(.top, 6)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                ForEach(brewingMethods) { method in
                    VStack(alignment: .leading, spacing: 16) {
                        Image(systemName: method.symbol)
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: 0xC8965A))

                        Text(method.name)
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .tracking(1)
                            .foregroundColor(Color(hex: 0xF5EDE0))

                        HStack(spacing: 20) {
                            brewingDetail(title: "Brew Time", value: method.time)
                            brewingDetail(title: "Difficulty", value: method.difficulty)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                    )
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("THE GOLDEN RATIO")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundColor(Color(hex: 0xF5EDE0))

                HStack(spacing: 16) {
                    ratioCard(ratio: "1:15", label: "Strong & Bold")
                    ratioCard(ratio: "1:16", label: "Balanced")
                    ratioCard(ratio: "1:17", label: "Light & Bright", showsDivider: false)
                }

                Text("Coffee to water ratio. Adjust to your taste based on roast level and brew method.")
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.45))
                    .padding(.top, 6)
            }
            .padding(24)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(hex: 0xC8965A).opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
    }

    private var aboutView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Our story")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))
                Text("ABOUT TALLA")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundColor(Color(hex: 0xF5EDE0))
            }

            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Talla Speciality Roasters is a Bahrain-based coffee company dedicated to bringing the finest single-origin beans and brewing tools to the Gulf.")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.75))

                    Text("This build now reads product data directly from Shopify, so the catalog in the app follows the store instead of a hardcoded sample list.")
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.55))
                }

                VStack(alignment: .leading, spacing: 12) {
                    infoChip(symbol: "shippingbox.fill", text: "Storefront API")
                    infoChip(symbol: "photo.fill", text: "Live Product Media")
                    infoChip(symbol: "arrow.clockwise", text: "Refresh on Demand")
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("WE SHIP TO")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundColor(Color(hex: 0xF5EDE0))

                let countries = ["Bahrain", "Kuwait", "Oman", "Qatar", "Saudi Arabia", "UAE"]
                let columns = [GridItem(.adaptive(minimum: 120), spacing: 10, alignment: .leading)]

                LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                    ForEach(countries, id: \.self) { country in
                        Text(country)
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(hex: 0xC8965A).opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color(hex: 0xC8965A).opacity(0.2), lineWidth: 1)
                            )
                            .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.8))
                    }
                }
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 14) {
                Text("FOLLOW US")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundColor(Color(hex: 0xF5EDE0))

                HStack(spacing: 10) {
                    socialChip(label: "Instagram", systemImage: "camera.fill")
                    socialChip(label: "TikTok", systemImage: "music.note")
                    socialChip(label: "X / Twitter", systemImage: "message.fill")
                    socialChip(label: "Snapchat", systemImage: "bolt.horizontal.fill")
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 48)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("TALLA")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .tracking(4)
                .foregroundColor(Color(hex: 0xC8965A))

            Text("Powered by Shopify Storefront API")
                .font(.system(size: 9, weight: .light))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xC8965A).opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }

    private var cartDrawer: some View {
        ZStack(alignment: .trailing) {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    cartOpen = false
                }

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("YOUR CART")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Spacer()

                    Button {
                        cartOpen = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                if cartItems.isEmpty {
                    Text("Your cart is empty.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.4))
                } else {
                    ForEach(cartItems) { item in
                        HStack(spacing: 10) {
                            ProductThumbnail(imageURL: item.product.imageURL, size: 44, cornerRadius: 8)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.product.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: 0xF5EDE0))

                                Text("\(item.product.price) x \(item.quantity)")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(Color(hex: 0xC8965A))
                            }

                            Spacer()

                            Button {
                                removeFromCart(id: item.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: 0xC8965A).opacity(0.2), lineWidth: 1)
                                    )
                                    .foregroundColor(Color(hex: 0xC8965A).opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                        .overlay(
                            Rectangle()
                                .fill(Color(hex: 0xC8965A).opacity(0.08))
                                .frame(height: 1),
                            alignment: .bottom
                        )
                    }

                    Button {
                    } label: {
                        Text("CHECKOUT")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .tracking(2)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: 0xC8965A))
                            .cornerRadius(2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }

                Spacer()
            }
            .padding(24)
            .frame(width: 320)
            .background(Color(hex: 0x100D08))
            .overlay(
                Rectangle()
                    .fill(Color(hex: 0xC8965A).opacity(0.2))
                    .frame(width: 1),
                alignment: .leading
            )
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: 0xC8965A))

            Text("Loading products from Shopify")
                .font(.system(size: 12, weight: .medium))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptySection: some View {
        VStack(spacing: 12) {
            Text("No products found in this category.")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.7))

            Button {
                activeCategory = "all"
            } label: {
                Text("Show All Products")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(hex: 0xC8965A))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func errorSection(message: String) -> some View {
        VStack(spacing: 14) {
            Text("Could not load Shopify products.")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(Color(hex: 0xF5EDE0))

            Text(message)
                .font(.system(size: 12, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.6))

            Button {
                Task {
                    await loadProducts(force: true)
                }
            } label: {
                Text("Retry")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(hex: 0xC8965A))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func productCard(product: Product, showDescription: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 10)
                    .frame(height: 170)

                if let tag = product.tag {
                    Text(tag)
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(2)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color(hex: 0xC8965A))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .cornerRadius(2)
                        .padding(10)
                }
            }

            Text(product.categoryLabel)
                .font(.system(size: 9, weight: .light))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.45))

            Text(product.name)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(Color(hex: 0xF5EDE0))

            if showDescription {
                Text(product.desc)
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.5))
                    .lineLimit(3)
            }

            Text(product.price)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: 0xC8965A))

            Button {
                addToCart(product: product)
            } label: {
                Text("Add to Bag")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(3)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xC8965A))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
        )
    }

    private func collectionTile(name: String, desc: String, systemImage: String, color: Color, categoryKey: String) -> some View {
        Button {
            activeTab = .shop
            activeCategory = categoryKey
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                    .foregroundColor(Color(hex: 0xC8965A))

                Text(name)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: 0xF5EDE0))

                Text(desc)
                    .font(.system(size: 13, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.6))

                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: 0xC8965A).opacity(0.6))
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
            .background(color)
        }
        .buttonStyle(.plain)
    }

    private func featureItem(symbol: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0xC8965A))

            Text(label)
                .font(.system(size: 10, weight: .light))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.55))
        }
    }

    private func brewingDetail(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .light))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.4))

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: 0xC8965A))
        }
    }

    private func ratioCard(ratio: String, label: String, showsDivider: Bool = true) -> some View {
        VStack(spacing: 6) {
            Text(ratio)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: 0xC8965A))

            Text(label)
                .font(.system(size: 10, weight: .light))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if showsDivider {
                Rectangle()
                    .fill(Color(hex: 0xC8965A).opacity(0.1))
                    .frame(width: 1)
            }
        }
    }

    private func infoChip(symbol: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0xC8965A))

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xF5EDE0).opacity(0.7))

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: 0xC8965A).opacity(0.15), lineWidth: 1)
        )
    }

    private func socialChip(label: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(label)
        }
        .font(.system(size: 10, weight: .medium))
        .tracking(2)
        .textCase(.uppercase)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: 0xC8965A).opacity(0.2), lineWidth: 1)
        )
        .foregroundColor(Color(hex: 0xF5EDE0))
    }

    @MainActor
    private func loadProductsIfNeeded() async {
        guard !hasLoadedProducts else { return }
        await loadProducts()
    }

    @MainActor
    private func loadProducts(force: Bool = false) async {
        guard !isLoadingProducts else { return }
        guard force || !hasLoadedProducts else { return }

        isLoadingProducts = true
        loadingError = nil

        do {
            let fetchedProducts = try await ShopifyStorefrontClient.fetchAllProducts()
            products = fetchedProducts
            hasLoadedProducts = true

            if !availableCategories.contains(activeCategory) {
                activeCategory = "all"
            }
        } catch {
            loadingError = error.localizedDescription
        }

        isLoadingProducts = false
    }

    private func addToCart(product: Product) {
        if let index = cartItems.firstIndex(where: { $0.id == product.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(id: product.id, product: product, quantity: 1))
        }

        showToast(message: "\(product.name) added to cart")
    }

    private func removeFromCart(id: String) {
        cartItems.removeAll { $0.id == id }
    }

    private func showToast(message: String) {
        toastMessage = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    private func categoryLabel(for key: String) -> String {
        guard key != "all" else { return "all" }
        return key
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func toastView(message: String) -> some View {
        Text(message)
            .font(.system(size: 11, weight: .medium))
            .tracking(1)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color(hex: 0xC8965A))
            .foregroundColor(Color(hex: 0x0A0804))
            .cornerRadius(2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, 24)
    }
}

private struct ProductThumbnail: View {
    let imageURL: URL?
    let size: CGFloat?
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1A1612), Color(hex: 0x100D08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(Color(hex: 0xC8965A))

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

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

    private var placeholder: some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: 28))
            .foregroundColor(Color(hex: 0xC8965A).opacity(0.8))
    }
}

private enum ShopifyStorefrontClient {
    private static let endpoint = URL(string: "https://\(ShopifyConfiguration.shopDomain)/api/2025-10/graphql.json")!

    static func fetchAllProducts() async throws -> [ContentView.Product] {
        var products: [ContentView.Product] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            let response = try await fetchPage(after: cursor)

            products.append(contentsOf: response.products.edges.map { edge in
                ContentView.Product(shopifyNode: edge.node)
            })

            hasNextPage = response.products.pageInfo.hasNextPage
            cursor = response.products.pageInfo.endCursor
        }

        return products
    }

    private static func fetchPage(after cursor: String?) async throws -> ShopifyProductsResponse.DataPayload {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ShopifyConfiguration.storefrontToken, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")

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
                    title
                    description
                    tags
                    productType
                    featuredImage {
                      url
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

        request.httpBody = try JSONSerialization.data(withJSONObject: body.dictionary, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ShopifyError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ShopifyProductsResponse.self, from: data)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let payload = decoded.data else {
            throw ShopifyError.invalidResponse
        }

        return payload
    }
}

private struct ShopifyConfiguration {
    static let shopDomain = "duneroastery.myshopify.com"
    static let storefrontToken = "0b8e38878678cd9b9db8325f88f95141"
}

private struct ShopifyGraphQLRequest {
    let query: String
    let variables: [String: Any]

    var dictionary: [String: Any] {
        [
            "query": query,
            "variables": variables
        ]
    }
}

private struct ShopifyProductsResponse: Decodable {
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

private struct ShopifyProductNode: Decodable {
    let id: String
    let title: String
    let description: String
    let tags: [String]
    let productType: String
    let featuredImage: FeaturedImage?
    let priceRange: PriceRange

    struct FeaturedImage: Decodable {
        let url: URL
    }

    struct PriceRange: Decodable {
        let minVariantPrice: Money
    }

    struct Money: Decodable {
        let amount: String
        let currencyCode: String
    }
}

private enum ShopifyError: LocalizedError {
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

private extension ContentView.Product {
    init(shopifyNode: ShopifyProductNode) {
        let categoryKey = Self.categoryKey(
            productType: shopifyNode.productType,
            tags: shopifyNode.tags,
            title: shopifyNode.title
        )

        self.init(
            id: shopifyNode.id,
            name: shopifyNode.title,
            price: Self.formattedPrice(from: shopifyNode.priceRange.minVariantPrice),
            categoryKey: categoryKey,
            categoryLabel: Self.categoryLabel(from: categoryKey),
            imageURL: shopifyNode.featuredImage?.url,
            desc: shopifyNode.description.isEmpty ? "Freshly synced from Shopify." : shopifyNode.description,
            tag: Self.productTag(from: shopifyNode.tags)
        )
    }

    private static func categoryKey(productType: String, tags: [String], title: String) -> String {
        let source = ([productType, title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("drip") {
            return "drip"
        }

        if source.contains("equip") || source.contains("chemex") || source.contains("scale") || source.contains("server") || source.contains("grinder") || source.contains("brew") {
            return "equipment"
        }

        if source.contains("gift") || source.contains("box") {
            return "gifts"
        }

        if source.contains("cookie") || source.contains("chocolate") || source.contains("snack") || source.contains("food") {
            return "food"
        }

        return "beans"
    }

    private static func categoryLabel(from key: String) -> String {
        key
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private static func productTag(from tags: [String]) -> String? {
        let preferred = ["BESTSELLER", "NEW", "LOCAL", "PREMIUM", "GIFT"]
        let uppercased = tags.map { $0.uppercased() }
        return preferred.first(where: uppercased.contains)
    }

    private static func formattedPrice(from money: ShopifyProductNode.Money) -> String {
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

private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    ContentView()
}
