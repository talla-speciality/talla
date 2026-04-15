import SwiftUI

struct BrewingSectionView: View {
    let isCompact: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color
    let displayedMethods: [ContentView.BrewingMethod]
    let brewingCategories: [String]
    let gridColumns: [GridItem]
    let isLoadingMethods: Bool
    let methodsAreEmpty: Bool
    let methodsError: String?
    @Binding var activeCategory: String
    @Binding var ratioCoffeeInput: String
    @Binding var ratioValueInput: String
    @Binding var brewRecipeName: String
    let calculatedWaterAmount: Double
    let ratioCoffeeAmount: Double
    let ratioValue: Double
    let titleFont: Font
    let sectionTitleFont: Font
    let bodyFont: Font
    let labelFont: Font
    let saveRecipeAction: () -> Void
    let openArticleAction: (URL) -> Void
    let loadingView: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text("The craft")
                    .font(labelFont)
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text("BREWING METHODS")
                    .font(titleFont)
                    .tracking(1)
                    .foregroundColor(primaryTextColor)

                Text("Guides for making better coffee at home.")
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(tertiaryTextColor)
                    .padding(.top, 6)
            }

            if isLoadingMethods && methodsAreEmpty {
                loadingView
            } else {
                goldenRatioSection
                brewingCategoriesSection

                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(displayedMethods) { method in
                        methodCard(method)
                    }
                }
            }

            if let methodsError {
                Text(methodsError)
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var goldenRatioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THE GOLDEN RATIO")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                ratioCard(ratio: "1:15", label: "Strong & Bold")
                ratioCard(ratio: "1:16", label: "Balanced")
                ratioCard(ratio: "1:17", label: "Light & Bright", showsDivider: false)
            }

            Text("Coffee to water ratio. Adjust to your taste based on roast level and brew method.")
                .font(.system(size: 15, weight: .light, design: .serif))
                .italic()
                .foregroundColor(tertiaryTextColor)
                .padding(.top, 6)

            ratioCalculatorCard
        }
        .padding(24)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var brewingCategoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(brewingCategories, id: \.self) { category in
                    Button {
                        activeCategory = category
                    } label: {
                        Text(category)
                            .font(Font.custom("AvenirNext-Bold", size: 11))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundColor(activeCategory == category ? Color(hex: 0x0A0804) : secondaryTextColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(activeCategory == category ? accentColor : cardFillColor)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(accentColor.opacity(activeCategory == category ? 0 : 0.18), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func methodCard(_ method: ContentView.BrewingMethod) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: method.symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                Spacer()

                methodTag(method.articleURL == nil ? "In-App Guide" : "Coffee Journal")
            }

            Text(method.name)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(primaryTextColor)

            Text(method.summary)
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            if !method.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        methodTag(method.brewTime)
                        methodTag(method.difficulty)

                        ForEach(method.categories, id: \.self) { category in
                            methodTag(category)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                brewingDetail(title: "Source", value: method.detail)
                brewingDetail(
                    title: "Guide",
                    value: method.articleURL == nil ? "In-app guide" : "Coffee journal article"
                )
            }

            HStack {
                Text(method.articleURL == nil ? "Use the built-in guide below." : "Open the full brew guide.")
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)

                Spacer()

                if let articleURL = method.articleURL {
                    Button {
                        openArticleAction(articleURL)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Open Guide")
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("In App")
                        .font(Font.custom("AvenirNext-Bold", size: 10))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func methodTag(_ title: String) -> some View {
        Text(title)
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundColor(accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accentColor.opacity(0.1))
            .clipShape(Capsule())
    }

    private var ratioCalculatorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RATIO CALCULATOR")
                .font(sectionTitleFont)
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            HStack(spacing: 12) {
                ratioInputField(title: "Coffee (g)", text: $ratioCoffeeInput)
                ratioInputField(title: "Ratio", text: $ratioValueInput)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(formattedRatioValue(calculatedWaterAmount)) g")
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 26 : 30))
                    .foregroundColor(primaryTextColor)

                Text("water")
                    .font(Font.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(secondaryTextColor)
            }

            Text("Based on \(formattedRatioValue(ratioCoffeeAmount)) g coffee at 1:\(formattedRatioValue(ratioValue)).")
                .font(Font.custom("AvenirNext-Regular", size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                ratioInputField(title: "Recipe Name", text: $brewRecipeName, keyboardType: .default)

                Button(action: saveRecipeAction) {
                    Text("Save Recipe")
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func brewingDetail(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .light))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            Text(value)
                .font(Font.custom("AvenirNext-Bold", size: 13))
                .foregroundColor(accentColor)
        }
    }

    private func ratioCard(ratio: String, label: String, showsDivider: Bool = true) -> some View {
        VStack(spacing: 6) {
            Text(ratio)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(accentColor)

            Text(label)
                .font(.system(size: 10, weight: .light))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if showsDivider {
                Rectangle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 1)
            }
        }
    }

    private func ratioInputField(title: String, text: Binding<String>, keyboardType: UIKeyboardType = .decimalPad) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 10))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            TextField("0", text: text)
                .keyboardType(keyboardType)
                .font(Font.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(accentColor.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedRatioValue(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}
