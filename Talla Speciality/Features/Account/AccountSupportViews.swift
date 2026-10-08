struct TallaAppIconOption: Identifiable {
    let iconName: String?
    let previewAsset: String
    let title: String

    var id: String { iconName ?? "primary" }

    static let all: [TallaAppIconOption] = [
        TallaAppIconOption(iconName: nil, previewAsset: "AppIconPreview1", title: "Bahrain Pink"),
        TallaAppIconOption(iconName: "TallaOriginal", previewAsset: "AppIconPreviewOriginal", title: "Original"),
        TallaAppIconOption(iconName: "TallaIcon2", previewAsset: "AppIconPreview2", title: "Pink Cup"),
        TallaAppIconOption(iconName: "TallaIcon4", previewAsset: "AppIconPreview4", title: "Gold Cup"),
        TallaAppIconOption(iconName: "TallaIcon5", previewAsset: "AppIconPreview5", title: "Witch Cup"),
        TallaAppIconOption(iconName: "TallaIcon6", previewAsset: "AppIconPreview6", title: "Talla Wordmark")
    ]
}

struct TallaAppIconPicker: View {
    let accentColor: Color
    let cardColor: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let onError: (String) -> Void

    @State private var selectedIconName: String?
    @State private var pendingIconID: String?

    init(
        accentColor: Color,
        cardColor: Color,
        primaryTextColor: Color,
        secondaryTextColor: Color,
        onError: @escaping (String) -> Void
    ) {
        self.accentColor = accentColor
        self.cardColor = cardColor
        self.primaryTextColor = primaryTextColor
        self.secondaryTextColor = secondaryTextColor
        self.onError = onError
        _selectedIconName = State(initialValue: UIApplication.shared.alternateIconName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppLocalization.text("choose_app_icon", fallback: "Choose your Talla icon"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text(
                    "choose_app_icon_detail",
                    fallback: "Your selection appears on the Home Screen, in Spotlight, and in Settings."
                ))
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 14)], spacing: 18) {
                ForEach(TallaAppIconOption.all) { option in
                    iconButton(option)
                }
            }

            if !UIApplication.shared.supportsAlternateIcons {
                Text(AppLocalization.text(
                    "alternate_icons_unavailable",
                    fallback: "Alternate icons are unavailable on this device."
                ))
                .font(.footnote)
                .foregroundColor(secondaryTextColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TallaTheme.Colors.ink.opacity(0.16), lineWidth: 1)
        )
        .onAppear {
            selectedIconName = UIApplication.shared.alternateIconName
        }
    }

    private func iconButton(_ option: TallaAppIconOption) -> some View {
        let normalizedSelectedName = selectedIconName == "TallaIcon1" ? nil : selectedIconName
        let isSelected = normalizedSelectedName == option.iconName
        let isPending = pendingIconID == option.id

        return Button {
            select(option)
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(option.previewAsset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(isSelected ? accentColor : primaryTextColor.opacity(0.10), lineWidth: isSelected ? 3 : 1)
                        )
                        .shadow(color: Color.black.opacity(0.14), radius: 5, y: 3)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 21, weight: .bold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, accentColor)
                            .background(Circle().fill(Color.white))
                            .offset(x: 6, y: -6)
                    } else if isPending {
                        ProgressView()
                            .tint(TallaTheme.Colors.ink)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(cardColor))
                            .offset(x: 6, y: -6)
                    }
                }

                Text(option.title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? TallaTheme.Colors.ink : primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!UIApplication.shared.supportsAlternateIcons || pendingIconID != nil || isSelected)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func select(_ option: TallaAppIconOption) {
        guard UIApplication.shared.supportsAlternateIcons else {
            onError(AppLocalization.text("alternate_icons_unavailable", fallback: "Alternate icons are unavailable on this device."))
            return
        }

        pendingIconID = option.id
        UIApplication.shared.setAlternateIconName(option.iconName) { error in
            DispatchQueue.main.async {
                pendingIconID = nil
                if let error {
                    onError(error.localizedDescription)
                } else {
                    selectedIconName = option.iconName
                }
            }
        }
    }
}

struct SavedBrewRecipeEditor: View {
    let recipe: ContentView.BrewRecipe
    let accent: Color
    let background: Color
    let primary: Color
    let secondary: Color
    let onSave: (ContentView.BrewRecipe) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var coffeeGrams: String
    @State private var ratio: String
    @State private var error: String?

    init(recipe: ContentView.BrewRecipe, accent: Color, background: Color, primary: Color, secondary: Color, onSave: @escaping (ContentView.BrewRecipe) -> Void) {
        self.recipe = recipe; self.accent = accent; self.background = background; self.primary = primary; self.secondary = secondary; self.onSave = onSave
        _name = State(initialValue: recipe.name)
        _coffeeGrams = State(initialValue: String(recipe.coffeeGrams))
        _ratio = State(initialValue: String(recipe.ratio))
    }

    var body: some View {
        Form {
            Section("Recipe") {
                TextField("Recipe name", text: $name)
                TextField("Coffee (g)", text: $coffeeGrams).keyboardType(.decimalPad)
                TextField("Ratio (1:x)", text: $ratio).keyboardType(.decimalPad)
                if let error { Text(error).font(.footnote).foregroundStyle(.red) }
            }
            Section {
                Text("Water: \(waterText) g").foregroundStyle(secondary)
                Button("Save changes") { save() }.frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(background)
        .navigationTitle("Edit saved recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }

    private var parsedCoffee: Double? { Double(coffeeGrams.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)) }
    private var parsedRatio: Double? { Double(ratio.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)) }
    private var waterText: String { guard let parsedCoffee, let parsedRatio else { return "—" }; return String(format: "%.1f", parsedCoffee * parsedRatio) }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let parsedCoffee, parsedCoffee > 0, let parsedRatio, parsedRatio > 0 else {
            error = "Enter a name, coffee amount, and positive ratio."
            return
        }
        let updated = ContentView.BrewRecipe(
            id: recipe.id, name: trimmedName, coffeeGrams: parsedCoffee, ratio: parsedRatio,
            waterGrams: parsedCoffee * parsedRatio, category: recipe.category, createdAt: recipe.createdAt,
            brewingWaterGrams: recipe.brewingWaterGrams, iceGrams: recipe.iceGrams, methodID: recipe.methodID,
            brewerID: recipe.brewerID, brewMode: recipe.brewMode, bloomRatio: recipe.bloomRatio,
            pourCount: recipe.pourCount, grind: recipe.grind, temperatureC: recipe.temperatureC,
            controlMode: recipe.controlMode, process: recipe.process, roast: recipe.roast,
            grinder: recipe.grinder, grinderID: recipe.grinderID, waterProfileID: recipe.waterProfileID,
            temperaturePresetID: recipe.temperaturePresetID, filter: recipe.filter, altitudeMeters: recipe.altitudeMeters,
            tastingNotes: recipe.tastingNotes, targetTimeRange: recipe.targetTimeRange,
            temperatureReason: recipe.temperatureReason, expectedCup: recipe.expectedCup,
            approach: recipe.approach, steps: recipe.steps
        )
        onSave(updated)
        dismiss()
    }
}
import Foundation
import SwiftUI
