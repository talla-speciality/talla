import SwiftUI

struct ShopSectionView: View {
    let activeCategoryTitle: String
    let availableCategories: [ContentView.ShopCategory]
    let filteredProducts: [ContentView.Product]
    let allProductsAreEmpty: Bool
    let isLoadingProducts: Bool
    let loadingError: String?
    @Binding var activeCategory: String
    @Binding var searchQuery: String
    @Binding var sortMode: ContentView.ShopSortMode
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color
    let isLightAppearance: Bool
    let titleFont: Font
    let sectionTitleFont: Font
    let bodyFont: Font
    let labelFont: Font
    let categoryLabelFont: Font
    let categoryBodyFont: Font
    let gridColumns: [GridItem]
    let recentSearches: [String]
    let quickSearches: [(title: String, query: String, categoryKey: String)]
    let guidancePanel: AnyView
    let renderProductCard: (ContentView.Product, Bool) -> AnyView
    let submitSearch: (String) -> Void
    let selectQuickSearch: (String, String) -> Void
    let clearRecentSearches: () -> Void
    let retryLoad: () -> Void
    let categorySelected: () -> Void
    @State private var isSortDialogPresented = false
    @FocusState private var isSearchFocused: Bool

    private var usesArabicTypography: Bool {
        AppLocalization.currentLanguage.effectiveLanguageCode == "ar"
    }

    private func localizedTracking(_ value: CGFloat) -> CGFloat {
        usesArabicTypography ? 0 : value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppLocalization.text("shop_eyebrow", fallback: "What are you craving?"))
                    .font(labelFont)
                    .tracking(localizedTracking(3))
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text(AppLocalization.text("shop_heading", fallback: "Pick your Talla run"))
                    .font(titleFont)
                    .tracking(localizedTracking(0.6))
                    .foregroundColor(primaryTextColor)
            }

            shopSearchField

            if isSearchFocused || !searchQuery.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    shopSearchSuggestions
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            shopCategoriesSection
            shopSortSection

            if isLoadingProducts && allProductsAreEmpty {
                loadingSection
            } else if let loadingError, allProductsAreEmpty {
                errorSection(message: loadingError)
            } else if filteredProducts.isEmpty {
                emptySection
            } else {
                let discoveryBreakIndex = min(4, filteredProducts.count)

                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(Array(filteredProducts.prefix(discoveryBreakIndex))) { product in
                        renderProductCard(product, true)
                    }
                }

                guidancePanel

                if filteredProducts.count > discoveryBreakIndex {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(Array(filteredProducts.dropFirst(discoveryBreakIndex))) { product in
                            renderProductCard(product, true)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
        .confirmationDialog(
            AppLocalization.text("sort_by", fallback: "Sort by"),
            isPresented: $isSortDialogPresented,
            titleVisibility: .visible
        ) {
            ForEach(ContentView.ShopSortMode.allCases) { mode in
                Button(mode.title) {
                    sortMode = mode
                }
            }

            Button(AppLocalization.text("cancel", fallback: "Cancel"), role: .cancel) { }
        }
    }

    private var shopSearchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(accentColor)

            TextField(AppLocalization.text("search_shop_placeholder", fallback: "Search summer drinks, cups, CRMB..."), text: $searchQuery)
                .font(bodyFont)
                .foregroundColor(primaryTextColor)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .onSubmit {
                    submitSearch(searchQuery)
                    isSearchFocused = false
                }

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(secondaryTextColor.opacity(0.75))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("clear_search", fallback: "Clear search"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var shopSearchSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchChipRow(
                title: AppLocalization.text("quick_searches", fallback: "Quick searches"),
                items: quickSearches.map { ($0.title, $0.query, $0.categoryKey) },
                showClear: false
            )

            if !recentSearches.isEmpty {
                searchChipRow(
                    title: AppLocalization.text("recent_searches", fallback: "Recent searches"),
                    items: recentSearches.map { ($0, $0, "all") },
                    showClear: true
                )
            }
        }
    }

    private func searchChipRow(title: String, items: [(title: String, query: String, categoryKey: String)], showClear: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(categoryLabelFont)
                    .tracking(localizedTracking(1.6))
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Spacer()

                if showClear {
                    Button(action: clearRecentSearches) {
                        Text(AppLocalization.text("clear", fallback: "Clear"))
                            .font(categoryLabelFont)
                            .foregroundColor(secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        Button {
                            selectQuickSearch(item.query, item.categoryKey)
                        } label: {
                            Text(item.title)
                                .font(categoryLabelFont)
                                .tracking(localizedTracking(1.2))
                                .textCase(.uppercase)
                                .foregroundColor(primaryTextColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(cardFillColor)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(accentColor.opacity(0.18), lineWidth: 1)
                                )
                                .clipShape(Capsule(style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var shopSortSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(activeCategoryTitle)
                    .font(categoryLabelFont)
                    .tracking(localizedTracking(1.2))
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(resultsCountText)
                    .font(categoryBodyFont)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if activeCategory != "all" || !searchQuery.isEmpty {
                Button {
                    activeCategory = "all"
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentColor)
                        .frame(width: 30, height: 30)
                        .background(accentColor.opacity(isLightAppearance ? 0.10 : 0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("clear", fallback: "Clear"))
            }

            Button {
                isSortDialogPresented = true
            } label: {
                HStack(spacing: 7) {
                    Text("\(AppLocalization.text("sort", fallback: "Sort")): \(sortMode.title)")
                        .font(categoryLabelFont)
                        .tracking(localizedTracking(1.0))
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(accentColor.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .id("shop-catalogue")
    }

    private var shopResultsSummary: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(activeCategoryTitle)
                    .font(categoryLabelFont)
                    .tracking(localizedTracking(1.6))
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text(resultsCountText)
                    .font(categoryBodyFont)
                    .foregroundColor(secondaryTextColor)
            }

            Spacer()

            if activeCategory != "all" || !searchQuery.isEmpty {
                Button {
                    activeCategory = "all"
                    searchQuery = ""
                } label: {
                    Text(AppLocalization.text("clear", fallback: "Clear"))
                        .font(categoryLabelFont)
                        .tracking(localizedTracking(1.6))
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(cardFillColor)
                        .overlay(
                            Capsule()
                                .stroke(accentColor.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.top, 12)
        .id("shop-catalogue")
    }

    private var resultsCountText: String {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let key = filteredProducts.count == 1 ? "shop_catalog_product_count_one" : "shop_catalog_product_count_many"
            let fallback = filteredProducts.count == 1 ? "%d product" : "%d products"
            return String(format: AppLocalization.text(key, fallback: fallback), filteredProducts.count)
        }

        let key = filteredProducts.count == 1 ? "shop_search_count_one" : "shop_search_count_many"
        let fallback = filteredProducts.count == 1 ? "%d result for \"%@\"" : "%d results for \"%@\""
        return String(format: AppLocalization.text(key, fallback: fallback), filteredProducts.count, searchQuery)
    }

    private var shopCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalization.text("categories", fallback: "CATEGORIES"))
                .font(labelFont)
                .tracking(localizedTracking(4))
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(availableCategories) { category in
                        shopCategoryButton(category)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func shopCategoryButton(_ category: ContentView.ShopCategory) -> some View {
        let isSelected = activeCategory == category.key

        return Button {
            activeCategory = category.key
            categorySelected()
        } label: {
            HStack(spacing: 7) {
                categoryButtonIcon(for: category, isSelected: isSelected)

                Text(category.title)
                    .font(categoryLabelFont)
                    .tracking(localizedTracking(0.8))
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .foregroundColor(primaryTextColor)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(accentColor)
                }
            }
            .frame(height: 38, alignment: .leading)
            .padding(.horizontal, 11)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardFillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(isSelected ? 0.82 : 0.18), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryButtonIcon(for category: ContentView.ShopCategory, isSelected: Bool) -> some View {
        Group {
            if category.key == "coffee-beans" {
                Image(systemName: "capsule.portrait.fill")
                    .rotationEffect(.degrees(28))
            } else {
                Image(systemName: category.symbol)
            }
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(accentColor)
        .frame(width: 18, height: 18)
    }

    private var loadingSection: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                productSkeletonCard
            }
        }
        .accessibilityLabel(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
    }

    private var productSkeletonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(skeletonFill)
                .frame(height: 184)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(skeletonFill)
                .frame(width: 92, height: 10)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(skeletonFill)
                .frame(height: 22)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(skeletonFill)
                .frame(width: 150, height: 22)

            VStack(alignment: .leading, spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(skeletonFill)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(skeletonFill)
                    .frame(width: 132, height: 10)
            }

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(skeletonFill)
                .frame(width: 78, height: 14)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(skeletonFill)
                .frame(height: 38)
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private var skeletonFill: Color {
        isLightAppearance ? accentColor.opacity(0.13) : Color.white.opacity(0.08)
    }

    private var emptySection: some View {
        VStack(spacing: 14) {
            Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? AppLocalization.text("no_products", fallback: "No products match this category right now.")
                : AppLocalization.text("no_search_results", fallback: "No products match that search right now."))
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(secondaryTextColor)

            if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(AppLocalization.text("try_quick_searches", fallback: "Try one of the quick searches above or clear the search to browse everything."))
                    .font(categoryBodyFont)
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Button {
                activeCategory = "all"
                searchQuery = ""
            } label: {
                Text(AppLocalization.text("show_all_products", fallback: "Show All Products"))
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(localizedTracking(3))
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(accentColor)
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
            Text(AppLocalization.text("shop_load_failed", fallback: "We couldn’t load the shop."))
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(primaryTextColor)

            Text(message)
                .font(.system(size: 12, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(secondaryTextColor)

            Button(action: retryLoad) {
                Text(AppLocalization.text("retry", fallback: "Retry"))
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(localizedTracking(3))
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(accentColor)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
