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
    let renderProductCard: (ContentView.Product, Bool) -> AnyView
    let retryLoad: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppLocalization.text("explore", fallback: "Explore"))
                    .font(labelFont)
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text(AppLocalization.text("all_products", fallback: "ALL PRODUCTS"))
                    .font(titleFont)
                    .tracking(1)
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text("browse_catalog", fallback: "Browse by category, jump into customer favorites, and add to bag without hunting through the catalog."))
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            shopSearchField
            shopSortSection
            shopCategoriesSection
            shopResultsSummary

            if isLoadingProducts && allProductsAreEmpty {
                loadingSection
            } else if let loadingError, allProductsAreEmpty {
                errorSection(message: loadingError)
            } else if filteredProducts.isEmpty {
                emptySection
            } else {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(filteredProducts) { product in
                        renderProductCard(product, true)
                    }
                }
            }
        }
    }

    private var shopSearchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(accentColor)

            TextField(AppLocalization.text("search_shop_placeholder", fallback: "Search coffee, tools, gifts..."), text: $searchQuery)
                .font(bodyFont)
                .foregroundColor(primaryTextColor)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)

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
        .padding(.vertical, 13)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var shopSortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("sort_by", fallback: "Sort by"))
                .font(labelFont)
                .tracking(4)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ContentView.ShopSortMode.allCases) { mode in
                        sortButton(mode)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func sortButton(_ mode: ContentView.ShopSortMode) -> some View {
        let isSelected = sortMode == mode

        return Button {
            sortMode = mode
        } label: {
            Text(mode.title)
                .font(categoryLabelFont)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? accentColor : cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(accentColor.opacity(isSelected ? 0 : 0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var shopResultsSummary: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(activeCategoryTitle)
                    .font(categoryLabelFont)
                    .tracking(1.6)
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
                        .tracking(1.6)
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
    }

    private var resultsCountText: String {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(filteredProducts.count) product\(filteredProducts.count == 1 ? "" : "s") available"
        }

        return "\(filteredProducts.count) result\(filteredProducts.count == 1 ? "" : "s") for \"\(searchQuery)\""
    }

    private var shopCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("categories", fallback: "CATEGORIES"))
                .font(labelFont)
                .tracking(4)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableCategories) { category in
                        shopCategoryButton(category)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func shopCategoryButton(_ category: ContentView.ShopCategory) -> some View {
        let isSelected = activeCategory == category.key

        return Button {
            activeCategory = category.key
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                categoryButtonIcon(for: category, isSelected: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.title)
                        .font(categoryLabelFont)
                        .tracking(1.4)
                        .textCase(.uppercase)

                    Text(category.subtitle)
                        .font(categoryBodyFont)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
            }
            .frame(width: 138, height: 96, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? accentColor : cardFillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(isSelected ? 0 : 0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func categoryButtonIcon(for category: ContentView.ShopCategory, isSelected: Bool) -> some View {
        Group {
            if category.key == "eid-gifts" {
                LambIconView(
                    color: isSelected ? Color(hex: 0x0A0804) : accentColor,
                    size: 19
                )
            } else if category.key == "coffee-beans" {
                Image(systemName: "capsule.portrait.fill")
                    .rotationEffect(.degrees(28))
            } else {
                Image(systemName: category.symbol)
            }
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(isSelected ? Color(hex: 0x0A0804) : accentColor)
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(accentColor)

                Text(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
                .font(.system(size: 12, weight: .medium))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptySection: some View {
        VStack(spacing: 12) {
            Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? AppLocalization.text("no_products", fallback: "No products match this category right now.")
                : AppLocalization.text("no_search_results", fallback: "No products match that search right now."))
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(secondaryTextColor)

            Button {
                activeCategory = "all"
                searchQuery = ""
            } label: {
                Text(AppLocalization.text("show_all_products", fallback: "Show All Products"))
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(3)
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
                    .tracking(3)
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
