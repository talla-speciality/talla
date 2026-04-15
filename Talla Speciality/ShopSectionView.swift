import SwiftUI

struct ShopSectionView: View {
    let activeCategoryTitle: String
    let availableCategories: [ContentView.ShopCategory]
    let filteredProducts: [ContentView.Product]
    let allProductsAreEmpty: Bool
    let isLoadingProducts: Bool
    let loadingError: String?
    @Binding var activeCategory: String
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
                Text("Explore")
                    .font(labelFont)
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text("ALL PRODUCTS")
                    .font(titleFont)
                    .tracking(1)
                    .foregroundColor(primaryTextColor)

                Text("Browse by category, jump into customer favorites, and add to bag without hunting through the catalog.")
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            shopQuickActions
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

    private var shopQuickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            shortcutCard(
                title: "Best for Daily Brewing",
                detail: "Jump into roasted beans and signature staples.",
                systemImage: "leaf.fill",
                categoryKey: "coffee-beans"
            )
            shortcutCard(
                title: "Quick Gift Ideas",
                detail: "Open curated boxes and ready-to-share bundles.",
                systemImage: "gift.fill",
                categoryKey: "gifts"
            )
            shortcutCard(
                title: "Tools & Equipment",
                detail: "Find brewers, scales, and setup essentials.",
                systemImage: "flask.fill",
                categoryKey: "coffee-equipment"
            )
            shortcutCard(
                title: "Show Everything",
                detail: "Reset filters and browse the full catalog.",
                systemImage: "square.grid.2x2.fill",
                categoryKey: "all"
            )
        }
    }

    private var shopResultsSummary: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(activeCategoryTitle)
                    .font(categoryLabelFont)
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text("\(filteredProducts.count) product\(filteredProducts.count == 1 ? "" : "s") available")
                    .font(categoryBodyFont)
                    .foregroundColor(secondaryTextColor)
            }

            Spacer()

            if activeCategory != "all" {
                Button {
                    activeCategory = "all"
                } label: {
                    Text("Clear")
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

    private var shopCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CATEGORIES")
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
            if category.key == "coffee-beans" {
                Image(systemName: "capsule.portrait.fill")
                    .rotationEffect(.degrees(28))
            } else {
                Image(systemName: category.symbol)
            }
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(isSelected ? Color(hex: 0x0A0804) : accentColor)
    }

    private func shortcutCard(title: String, detail: String, systemImage: String, categoryKey: String) -> some View {
        ActionTileView(
            title: title,
            detail: detail,
            systemImage: systemImage,
            titleFont: categoryLabelFont,
            detailFont: categoryBodyFont,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
            backgroundColor: cardFillColor,
            strokeColor: accentColor.opacity(isLightAppearance ? 0.14 : 0.08),
            minHeight: 118
        ) {
            activeCategory = categoryKey
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(accentColor)

            Text("Loading the shop")
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
            Text("No products match this category right now.")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(secondaryTextColor)

            Button {
                activeCategory = "all"
            } label: {
                Text("Show All Products")
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
            Text("We couldn’t load the shop.")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(primaryTextColor)

            Text(message)
                .font(.system(size: 12, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(secondaryTextColor)

            Button(action: retryLoad) {
                Text("Retry")
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
