import Foundation
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(FoundationModels)
import FoundationModels
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity
#endif
#if canImport(UIKit)
import UIKit
#endif


extension BrewingSectionView {
    var createRecipeCoffeeDetailsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            createRecipeStepTitle(AppLocalization.text("coffee_input_title", fallback: "Tell us about the coffee"))

            purchasedCoffeePicker

            VStack(spacing: 0) {
                if coffeeMemoryEnabled && roastDateOCREnabled {
                    coffeeDetailsModeButton(.scan, title: AppLocalization.text("scan_coffee_bag", fallback: "Scan Coffee Bag"), detail: AppLocalization.text("scan_bag_detail", fallback: "Use camera or photo library, then review every detail."))
                }
                brewDivider
                coffeeDetailsModeButton(.manual, title: AppLocalization.text("enter_manually", fallback: "Enter Manually"), detail: AppLocalization.text("manual_details_detail", fallback: "Type the bag details you know. Only the name is required."))
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if coffeeDetailsMode == .scan {
                scanCoffeeBagPanel
            }

            manualCoffeeDetailsFields
        }
    }

    var createRecipeEquipmentStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            createRecipeStepTitle(AppLocalization.text("dial_in_the_brew", fallback: "Dial in the brew"))

            VStack(spacing: 0) {
                brewingFactRow(title: AppLocalization.text("selected_method", fallback: "Selected method"), value: brewProfileBrewerName)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                brewDivider.padding(.leading, 0)
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.text("coffee", fallback: "Coffee"))
                        .font(brewEyebrowFont)
                        .foregroundColor(brewSecondaryTextColor)
                    TextField(AppLocalization.text("coffee_name_placeholder", fallback: "Coffee name"), text: $coffeeName)
                        .textInputAutocapitalization(.words)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .submitLabel(.next)
                        .frame(minHeight: 44)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(spacing: 12) {
                creamGoldSegmentedControl(
                    title: AppLocalization.text("taste_goal", fallback: "Taste goal"),
                    options: ["Clarity", "Balanced", "Sweetness", "Body"],
                    selection: recipeTasteGoalSelection
                )

                brewerSetupSelector
                catalogPicker(title: AppLocalization.text("filter", fallback: "Filter"), selection: $recipeFilterType, options: filterCatalog, customPlaceholder: "Other filter")
                catalogPicker(title: AppLocalization.text("grinder", fallback: "Grinder"), selection: $recipeGrinder, options: grinderCatalog, customPlaceholder: "Other grinder")

                Picker("Water profile", selection: $selectedWaterProfileID) {
                    Text("No water profile").tag(nil as UUID?)
                    ForEach(coffeeData.records(WaterProfileRecord.self, entity: "waterProfile")) { profile in
                        Text(profile.name).tag(Optional(profile.id))
                    }
                }
                .pickerStyle(.menu)

                Picker("Temperature preset", selection: $selectedTemperaturePresetID) {
                    Text("Automatic temperature").tag(nil as UUID?)
                    ForEach(coffeeData.records(TemperaturePresetRecord.self, entity: "temperaturePreset")) { preset in
                        Text("\(preset.name) · \(preset.celsius, specifier: "%.0f") °C").tag(Optional(preset.id))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedTemperaturePresetID) { _, id in
                    guard let id,
                          let preset = coffeeData.records(TemperaturePresetRecord.self, entity: "temperaturePreset").first(where: { $0.id == id }) else { return }
                    generatedTemperatureC = Int(preset.celsius.rounded())
                }

                creamGoldSegmentedControl(
                    title: AppLocalization.text("brew_mode", fallback: "Brew mode"),
                    options: ["Hot", "Iced"],
                    selection: $recipeBrewTemperatureMode
                )

                HStack(spacing: 10) {
                    createRecipeTextField(title: AppLocalization.text("coffee_dose", fallback: "Coffee dose"), placeholder: "20", text: $recipeCoffeeDose)
                        .keyboardType(.decimalPad)
                    createRecipeTextField(title: AppLocalization.text("preferred_ratio", fallback: "Preferred ratio"), placeholder: "16", text: $recipePreferredRatio)
                        .keyboardType(.decimalPad)
                }

                Text("\(formattedWholeGram(createRecipeCoffeeAmount * createRecipeRatioValue)) g \(AppLocalization.text("calculated_water", fallback: "calculated water"))")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(brewAccentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, -2)

                creamGoldSegmentedControl(
                    title: AppLocalization.text("bloom_ratio", fallback: "Bloom ratio"),
                    options: ["Auto", "1:2", "1:2.5", "1:3"],
                    selection: $recipeBloomRatio
                )

                Text(recipeBloomRatio == "Auto"
                    ? "Talla recommends a \(formattedWholeGram(bloomWaterAmount)) g bloom for this coffee."
                    : "Bloom target: \(formattedWholeGram(bloomWaterAmount)) g")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(brewSecondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.text("number_of_pours", fallback: "Number of pours"))
                        .font(brewEyebrowFont)
                        .foregroundColor(brewSecondaryTextColor)

                    Stepper(value: $recipePourCount, in: 2...5) {
                        Text("\(recipePourCount) \(AppLocalization.text("pours", fallback: "pours"))")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)
                    }
                    .tint(brewAccentColor)
                }
                .padding(14)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                creamGoldSegmentedControl(
                    title: AppLocalization.text("brew_control", fallback: "Brew control"),
                    options: ["Manual", "xBloom Studio"],
                    selection: $recipeBrewControlMode
                )
            }
        }
    }

    func createRecipeQuestionStep(question: String, choices: [BrewChoice], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            createRecipeStepTitle(question)

            VStack(spacing: 0) {
                ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
                    if index > 0 {
                        brewDivider
                    }
                    createRecipeChoiceCard(choice, selection: selection)
                }
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var recipeTasteGoalSelection: Binding<String> {
        Binding(
            get: {
                switch createRecipeTasteGoal {
                case "bright":
                    return "Clarity"
                case "sweet":
                    return "Sweetness"
                case "rich":
                    return "Body"
                default:
                    return "Balanced"
                }
            },
            set: { newValue in
                switch newValue {
                case "Clarity":
                    createRecipeTasteGoal = "bright"
                case "Sweetness":
                    createRecipeTasteGoal = "sweet"
                case "Body":
                    createRecipeTasteGoal = "rich"
                default:
                    createRecipeTasteGoal = "balanced"
                }
            }
        )
    }

    var brewerSetupSelector: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(AppLocalization.text("brewer", fallback: "Brewer"))
                .font(brewEyebrowFont)
                .foregroundColor(brewSecondaryTextColor)

            Menu {
                ForEach(brewProfileBrewerChoices) { brewer in
                    Button {
                        createRecipeBrewer = brewer.id
                    } label: {
                        Text(brewer.title)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Text(brewProfileBrewerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(brewSecondaryTextColor)
                }
                .frame(minHeight: 48)
                .padding(.horizontal, 14)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    func createRecipeStepTitle(_ title: String) -> some View {
        Text(title)
            .font(brewQuestionFont)
            .foregroundColor(brewPrimaryTextColor)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    func createRecipeChoiceCard(_ choice: BrewChoice, selection: Binding<String>) -> some View {
        let isSelected = selection.wrappedValue == choice.id

        return Button {
            selection.wrappedValue = choice.id
            createRecipeValidationMessage = nil
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: choice.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? brewAccentColor : brewSecondaryTextColor)
                    .frame(width: 26)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(choice.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(choice.detail)
                        .font(.system(size: 14))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark" : "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? brewAccentColor : brewSecondaryTextColor)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 68)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isSelected ? brewAccentColor.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .buttonStyle(.plain)
    }

    var brewerChoices: [BrewChoice] {
        [
            BrewChoice(id: "v60", title: "V60", detail: AppLocalization.text("v60_detail_short", fallback: "A bright cone-style pour-over."), systemImage: "triangle"),
            BrewChoice(id: "solo", title: "Solo Dripper", detail: AppLocalization.text("solo_detail_short", fallback: "A precise flat-bottom dripper."), systemImage: "trapezoid.and.line.vertical"),
            BrewChoice(id: "kalita", title: "Kalita Wave", detail: AppLocalization.text("kalita_detail_short", fallback: "Flat-bottom balance and sweetness."), systemImage: "line.3.horizontal.decrease"),
            BrewChoice(id: "chemex", title: "Chemex", detail: AppLocalization.text("chemex_detail_short", fallback: "Clean texture and larger brews."), systemImage: "hourglass"),
            BrewChoice(id: "origami", title: "Origami", detail: AppLocalization.text("origami_detail_short", fallback: "Flexible flow with elegant clarity."), systemImage: "diamond"),
            BrewChoice(id: "aeropress", title: "AeroPress", detail: AppLocalization.text("aeropress_detail_short", fallback: "Pressure-assisted, fast, and forgiving."), systemImage: "capsule.portrait"),
            BrewChoice(id: "french-press", title: "French Press", detail: AppLocalization.text("french_press_detail_short", fallback: "Immersion body and comfort."), systemImage: "cylinder"),
            BrewChoice(id: "arabic", title: "Arabic coffee", detail: AppLocalization.text("arabic_coffee_detail_short", fallback: "Gentle heat, aroma, and service."), systemImage: "flame.fill"),
            BrewChoice(id: "cold", title: "Cold brew", detail: AppLocalization.text("cold_brew_detail_short", fallback: "Low acidity and slow extraction."), systemImage: "snowflake"),
            BrewChoice(id: "espresso", title: "Espresso", detail: AppLocalization.text("espresso_detail_short", fallback: "Pressure, intensity, and short ratios."), systemImage: "cup.and.saucer.fill"),
            BrewChoice(id: "other", title: "Other", detail: AppLocalization.text("other_brewer_detail_short", fallback: "Talla will adapt the recipe manually."), systemImage: "ellipsis.circle")
        ]
    }

    func coffeeDetailsModeButton(_ mode: CoffeeDetailsMode, title: String, detail: String) -> some View {
        let isSelected = coffeeDetailsMode == mode

        return Button {
            coffeeDetailsMode = mode
            createRecipeValidationMessage = nil
        } label: {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detail)
                        .font(.system(size: 14))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark" : "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? brewAccentColor : brewSecondaryTextColor)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 68)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isSelected ? brewAccentColor.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var scanCoffeeBagPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("scan_bag_review_title", fallback: "Scan, then review"))
                .font(brewEyebrowFont)
                .tracking(AppLocalization.letterSpacing(1.4))
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)

            Text(coffeeBagReviewMessage ?? AppLocalization.text("scan_bag_review_detail", fallback: "Use the camera or photo library. If Talla can read useful label details, they’ll appear below for you to edit."))
                .font(.system(size: 13))
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            if isCoffeeBagImageAnalyzing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(brewAccentColor)
                    Text(AppLocalization.text("bag_photo_reading", fallback: "Reading coffee bag details…"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(brewAccentColor)
                }
                .accessibilityElement(children: .combine)
            }

            HStack(spacing: 10) {
#if canImport(UIKit)
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        isCoffeeBagCameraPresented = true
                    } else {
                        coffeeBagReviewMessage = AppLocalization.text("camera_unavailable_friendly", fallback: "Camera is not available here. Choose a bag photo from your library and review the details below.")
                    }
                } label: {
                    scanActionLabel(title: AppLocalization.text("open_camera", fallback: "Open Camera"), systemImage: "camera.fill")
                }
                .buttonStyle(.plain)
                .disabled(isCoffeeBagImageAnalyzing)
#endif

#if canImport(PhotosUI)
                PhotosPicker(selection: $coffeeBagPhotoSelection, matching: .images) {
                    scanActionLabel(title: AppLocalization.text("photo_library", fallback: "Photo Library"), systemImage: "photo.fill")
                }
                .buttonStyle(.plain)
                .disabled(isCoffeeBagImageAnalyzing)
#endif
            }

#if canImport(UIKit)
            if let coffeeBagPreviewImage {
                Image(uiImage: coffeeBagPreviewImage)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFill()
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel(AppLocalization.text("coffee_bag_preview", fallback: "Coffee bag preview"))
            }
#endif
        }
        .padding(14)
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brewBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func scanActionLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 12, weight: .semibold))
            .tracking(AppLocalization.letterSpacing(1.1))
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundColor(brewAccentForegroundColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(brewAccentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var manualCoffeeDetailsFields: some View {
        VStack(spacing: 12) {
            createRecipeTextField(title: AppLocalization.text("coffee_name", fallback: "Coffee name"), placeholder: "Guji Natural", text: $coffeeName)
            createRecipeTextField(title: AppLocalization.text("roaster", fallback: "Roaster"), placeholder: "Talla Speciality", text: $coffeeRoaster)
            createRecipeTextField(title: AppLocalization.text("origin", fallback: "Origin"), placeholder: "Ethiopia", text: $coffeeOrigin)
            createRecipeTextField(title: AppLocalization.text("region", fallback: "Region"), placeholder: "Guji", text: $coffeeRegion)
            createRecipeTextField(title: AppLocalization.text("altitude", fallback: "Altitude"), placeholder: "1,900 masl", text: $coffeeAltitude)
            createRecipeTextField(title: AppLocalization.text("variety", fallback: "Variety"), placeholder: "Heirloom, SL28, Gesha", text: $coffeeVariety)
            catalogPicker(title: AppLocalization.text("process", fallback: "Process"), selection: $coffeeProcess, options: processCatalog, customPlaceholder: "Other or experimental process")
            createRecipeTextField(title: AppLocalization.text("flavour_profile", fallback: "Flavour profile"), placeholder: "Jasmine, peach, honey", text: $coffeeTastingNotes)

            creamGoldSegmentedControl(
                title: AppLocalization.text("roast_level", fallback: "Roast level"),
                options: ["Light", "Light-medium", "Medium", "Medium-dark", "Dark"],
                selection: $coffeeRoastLevel
            )

            DatePicker(
                AppLocalization.text("roast_date", fallback: "Roast date"),
                selection: $coffeeRoastDate,
                displayedComponents: .date
            )
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(brewPrimaryTextColor)
            .tint(brewAccentColor)
            .padding(14)
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(AppLocalization.text("brew_notes", fallback: "Brew notes"))
                    .font(brewEyebrowFont)
                    .foregroundColor(brewSecondaryTextColor)

                TextEditor(text: $coffeeBrewNotes)
                    .font(.system(size: 14))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(minHeight: 88)
                    .scrollContentBackground(.hidden)
            }
            .padding(14)
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    var purchasedCoffeePicker: some View {
        let bags = coffeeData.inventory()
            .filter { $0.remainingQuantityGrams > 0 }
            .sorted { ($0.openedAt ?? .distantPast) > ($1.openedAt ?? .distantPast) }

        if !bags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.text("purchased_bag", fallback: "Purchased bag"))
                    .font(brewEyebrowFont)
                    .foregroundColor(brewSecondaryTextColor)

                Picker(AppLocalization.text("purchased_bag", fallback: "Purchased bag"), selection: $selectedPurchasedCoffeeID) {
                    Text(AppLocalization.text("enter_new_coffee", fallback: "Enter a different coffee"))
                        .tag(nil as UUID?)
                    ForEach(bags) { bag in
                        Text("\(bag.productName) · \(bag.remainingQuantityGrams.formatted(.number.precision(.fractionLength(0...1)))) g left")
                            .tag(Optional(bag.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(brewAccentColor)
                .onChange(of: selectedPurchasedCoffeeID) { _, id in
                    guard let id, let bag = bags.first(where: { $0.id == id }) else { return }
                    applyPurchasedCoffee(bag)
                }

                if let id = selectedPurchasedCoffeeID,
                   let bag = bags.first(where: { $0.id == id }) {
                    Text("\(bag.remainingQuantityGrams.formatted(.number.precision(.fractionLength(0...1)))) g available · about \(bag.estimatedBrews(doseGrams: Double(recipeCoffeeDose) ?? 18)) brews")
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                }
            }
            .padding(14)
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    func applyPurchasedCoffee(_ bag: CoffeeInventoryRecord) {
        coffeeName = bag.productName
        coffeeRoaster = bag.roaster
        coffeeOrigin = bag.origin
        coffeeRegion = bag.region
        coffeeVariety = bag.variety
        coffeeProcess = bag.process
        if !bag.roastLevel.isEmpty { coffeeRoastLevel = bag.roastLevel }
        coffeeTastingNotes = bag.tastingNotes
        if let roastDate = bag.roastDate { coffeeRoastDate = roastDate }
        coffeeDetailsMode = .manual
        createRecipeValidationMessage = nil
    }

    func createRecipeTextField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(brewEyebrowFont)
                .foregroundColor(brewSecondaryTextColor)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundColor(brewPrimaryTextColor)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
        }
        .padding(14)
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(brewBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func catalogPicker(title: String, selection: Binding<String>, options: [String], customPlaceholder: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(brewEyebrowFont)
                .foregroundColor(brewSecondaryTextColor)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        if selection.wrappedValue == option {
                            Label(option, systemImage: "checkmark")
                        } else {
                            Text(option)
                        }
                    }
                }
                Divider()
                Button(AppLocalization.text("other_custom", fallback: "Other / Custom")) { selection.wrappedValue = "" }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? "Choose \(title.lowercased())" : selection.wrappedValue)
                        .font(.system(size: 15))
                        .foregroundColor(selection.wrappedValue.isEmpty ? brewSecondaryTextColor : brewPrimaryTextColor)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(brewAccentColor)
                }
                .frame(minHeight: 28)
            }
            .buttonStyle(.plain)

            if selection.wrappedValue.isEmpty {
                TextField(customPlaceholder, text: selection)
                    .font(.system(size: 14))
                    .foregroundColor(brewPrimaryTextColor)
                    .textInputAutocapitalization(.words)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .background(brewSurfaceColor)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(brewBorderColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var grinderCatalog: [String] {
        let savedProfiles = coffeeData.equipmentRecords()
            .filter { $0.kind == .grinder }
            .map(\.name)
        let defaults = ["Fellow Ode Gen 2", "Comandante C40", "1Zpresso ZP6", "1Zpresso K-Ultra", "Timemore C3", "Timemore Sculptor", "DF64", "Mahlkönig EK43", "Microns only"]
        return savedProfiles + defaults.filter { !savedProfiles.contains($0) }
    }

    var filterCatalog: [String] {
        ["Hario V60 Paper", "Cafec Abaca", "Cafec T-90", "Kalita Wave 155", "Kalita Wave 185", "Chemex Bonded", "AeroPress Paper", "AeroPress Metal", "Sibarist FAST", "xBloom Omni Dripper", "Cloth filter"]
    }

    var processCatalog: [String] {
        [
            "Washed", "Natural", "Honey", "Pulped Natural", "Wet-Hulled", "Double Fermented",
            "Anaerobic Natural", "Anaerobic Washed", "Extended Anaerobic", "Carbonic Maceration",
            "Co-Fermented", "Fruit Fermentation", "Thermal Shock", "Koji Fermented",
            "Nitrogen Infusion", "Decaf", "Experimental / Other"
        ]
    }

    func creamGoldSegmentedControl(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(brewEyebrowFont)
                .foregroundColor(brewSecondaryTextColor)

            HStack(spacing: 6) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(option)
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(AppLocalization.letterSpacing(0.8))
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .foregroundColor(selection.wrappedValue == option ? brewPrimaryTextColor : brewSecondaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selection.wrappedValue == option ? brewAccentColor.opacity(0.18) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection.wrappedValue == option ? .isSelected : [])
                }
            }
            .padding(4)
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    var createRecipeBottomControls: some View {
        HStack(spacing: 10) {
            Button {
                moveCreateRecipeBack()
            } label: {
                Text(AppLocalization.text("back", fallback: "Back"))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(AppLocalization.letterSpacing(1.1))
                    .textCase(.uppercase)
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                moveCreateRecipeForward()
            } label: {
                Text(createRecipeStep == .equipment ? AppLocalization.text("build_my_recipe", fallback: "Build My Recipe") : AppLocalization.text("continue", fallback: "Continue"))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(AppLocalization.letterSpacing(1.1))
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundColor(brewAccentForegroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    func moveCreateRecipeBack() {
        createRecipeValidationMessage = nil

        guard createRecipeStep != .coffeeDetails else {
            activeDashboardDestination = nil
            return
        }

        guard let previousStep = CreateRecipeStep(rawValue: createRecipeStep.rawValue - 1) else {
            activeDashboardDestination = nil
            return
        }

        guard previousStep.rawValue >= CreateRecipeStep.coffeeDetails.rawValue else {
            activeDashboardDestination = nil
            return
        }

        createRecipeStep = previousStep
    }

    func moveCreateRecipeForward() {
        createRecipeValidationMessage = nil

        if (createRecipeStep == .coffeeDetails || createRecipeStep == .equipment) && coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            createRecipeValidationMessage = AppLocalization.text("coffee_name_needed_friendly", fallback: "Give this coffee a name so Talla can save the recipe clearly.")
            return
        }

        if createRecipeStep == .equipment {
            buildCreatedRecipe()
            return
        }

        guard let nextStep = CreateRecipeStep(rawValue: createRecipeStep.rawValue + 1),
              nextStep.rawValue >= CreateRecipeStep.coffeeDetails.rawValue else {
            createRecipeStep = .coffeeDetails
            return
        }

        createRecipeStep = nextStep
    }

    func buildCreatedRecipe() {
        restoredBrewTotalSeconds = nil
        generatedRecipeID = UUID()
        isGeneratedRecipeActive = true
        restoredRecipeSteps = nil
        restoredTargetTimeRange = nil
        restoredTemperatureReason = nil
        restoredExpectedCup = nil
        restoredApproach = nil
        applySmartRecipeRecommendations()
        let name = coffeeName.trimmingCharacters(in: .whitespacesAndNewlines)
        brewRecipeName = name.isEmpty ? selectedCreateRecipeTitle : name
        ratioCoffeeInput = recipeCoffeeDose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "20" : recipeCoffeeDose
        ratioValueInput = recipePreferredRatio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "16" : recipePreferredRatio
        usePublishedRecipe(nil)
        activeSmartRecipeID = nil
        selectedGuideProfileID = recommendedProfileForCreateRecipe?.id ?? selectedGuideProfileID

        if let method = matchingMethodForCreateRecipe {
            selectBrewModeMethod(method, start: false, preserveRecipeIdentity: true)
        }

        createRecipeValidationMessage = nil
        recipeGenerationStageIndex = 0
        recipeGenerationProgress = 0
        recipeGenerationTaskID = UUID()
        withAnimation(.easeInOut(duration: 0.28)) {
            createRecipeStep = .generating
        }
    }

    func applySmartRecipeRecommendations() {
        let recommendation = smartRecipe
        generatedGrindDescription = recommendation.grindDescription
        generatedTemperatureC = recommendation.temperatureC
    }

    @MainActor
    func runRecipeGenerationSequence() async {
        recipeGenerationProgress = 0
        recipeGenerationStageIndex = 0

        for index in recipeGenerationStages.indices {
            withAnimation(.easeInOut(duration: 0.25)) {
                recipeGenerationStageIndex = index
                recipeGenerationProgress = Double(index) / Double(recipeGenerationStages.count)
            }

            recipeStageHaptic(isFinal: false)
            try? await Task.sleep(nanoseconds: 650_000_000)

            withAnimation(.easeInOut(duration: 0.30)) {
                recipeGenerationProgress = Double(index + 1) / Double(recipeGenerationStages.count)
            }

            recipeStageHaptic(isFinal: index == recipeGenerationStages.count - 1)
            try? await Task.sleep(nanoseconds: 360_000_000)
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            recipeGenerationStageIndex = recipeGenerationStages.count
            recipeGenerationProgress = 1
        }

        try? await Task.sleep(nanoseconds: 450_000_000)

        withAnimation(.easeInOut(duration: 0.38)) {
            createRecipeStep = .recipeDetail
        }
        saveCurrentRecipe()
    }

    func recipeStageHaptic(isFinal: Bool) {
#if canImport(UIKit)
        if isFinal {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
#endif
    }

    var selectedCreateRecipeTitle: String {
        let taste = createRecipeTasteGoalChoice?.title ?? AppLocalization.text("balanced", fallback: "Balanced")
        let brewer = brewerChoices.first { $0.id == createRecipeBrewer }?.title ?? AppLocalization.text("filter", fallback: "Filter")
        return "\(brewer) · \(taste)"
    }

    var createRecipeTasteGoalChoice: BrewChoice? {
        [
            BrewChoice(id: "bright", title: AppLocalization.text("bright_clean", fallback: "Bright & clean"), detail: "", systemImage: ""),
            BrewChoice(id: "balanced", title: AppLocalization.text("balanced", fallback: "Balanced"), detail: "", systemImage: ""),
            BrewChoice(id: "sweet", title: AppLocalization.text("sweet_round", fallback: "Sweet & round"), detail: "", systemImage: ""),
            BrewChoice(id: "rich", title: AppLocalization.text("rich_full_bodied", fallback: "Rich & full-bodied"), detail: "", systemImage: "")
        ].first { $0.id == createRecipeTasteGoal }
    }

    var recommendedProfileForCreateRecipe: BrewGuideProfile? {
        switch createRecipeBrewer {
        case "v60-iced":
            return brewGuideProfiles.first { $0.id == "v60-iced" }
        case "cold":
            return brewGuideProfiles.first { $0.id == "classic-cold-brew" }
        case "espresso":
            return brewGuideProfiles.first { $0.id == "espresso-base" }
        case "french-press", "aeropress":
            return brewGuideProfiles.first { $0.id == "french-press-sweet" }
        case "arabic":
            return brewGuideProfiles.first { $0.id == "arabic-majlis" }
        default:
            return brewGuideProfiles.first { $0.id == "balanced-filter" }
        }
    }

    var matchingMethodForCreateRecipe: ContentView.BrewingMethod? {
        if let exactMatch = displayedMethods.first(where: {
            $0.id.caseInsensitiveCompare(createRecipeBrewer) == .orderedSame
                || $0.name.caseInsensitiveCompare(generatedBrewerName) == .orderedSame
        }) {
            return exactMatch
        }

        let keywords: [String]
        switch createRecipeBrewer {
        case "v60-iced": keywords = ["v60 iced"]
        case "espresso": keywords = ["espresso"]
        case "french-press": keywords = ["french", "press", "immersion"]
        case "aeropress": keywords = ["aeropress", "aero"]
        case "arabic": keywords = ["arabic", "traditional", "dallah"]
        case "cold": keywords = ["classic cold brew"]
        case "chemex": keywords = ["chemex"]
        case "v60": keywords = ["v60"]
        case "solo": keywords = ["solo"]
        case "kalita": keywords = ["kalita", "wave"]
        case "origami": keywords = ["origami"]
        default: keywords = ["pour", "filter"]
        }

        return displayedMethods.first { method in
            let source = ([method.name, method.summary, method.detail] + method.categories)
                .joined(separator: " ")
                .lowercased()
            return keywords.contains { source.contains($0) }
        } ?? displayedMethods.first
    }

#if canImport(PhotosUI)
    @MainActor
    func loadCoffeeBagPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            coffeeBagReviewMessage = AppLocalization.text("bag_photo_read_friendly", fallback: "Talla could not read that photo clearly. You can still enter or adjust the coffee details below.")
            return
        }

#if canImport(UIKit)
        handleCoffeeBagImage(UIImage(data: data))
#else
        coffeeBagReviewMessage = AppLocalization.text("bag_photo_ready_friendly", fallback: "Photo added. Review the coffee details below before continuing.")
#endif
    }
#endif

#if canImport(UIKit)
    @MainActor
    func handleCoffeeBagImage(_ image: UIImage?) {
        guard let image else { return }
        let analysisID = UUID()
        coffeeBagAnalysisID = analysisID
        coffeeBagPreviewImage = image
        coffeeDetailsMode = .scan
        isCoffeeBagImageAnalyzing = true
        coffeeBagReviewMessage = AppLocalization.text("bag_photo_reading", fallback: "Reading coffee bag details…")

        Task { @MainActor in
            do {
                let result = try await CoffeeBagImageAnalyzer.analyze(image)
                guard coffeeBagAnalysisID == analysisID else { return }
                applyCoffeeBagScanResult(result)
                isCoffeeBagImageAnalyzing = false
                coffeeBagReviewMessage = result.populatedFieldCount > 0
                    ? AppLocalization.text("bag_photo_details_found", fallback: "Details were added from the bag. Review and edit them below before continuing.")
                    : AppLocalization.text("bag_photo_read_friendly", fallback: "Talla could not read that photo clearly. You can still enter or adjust the coffee details below.")
            } catch {
                guard coffeeBagAnalysisID == analysisID else { return }
                isCoffeeBagImageAnalyzing = false
                coffeeBagReviewMessage = AppLocalization.text("bag_photo_read_friendly", fallback: "Talla could not read that photo clearly. You can still enter or adjust the coffee details below.")
            }
        }
    }

    @MainActor
    func applyCoffeeBagScanResult(_ result: CoffeeBagScanResult) {
        if let value = result.roastDate { coffeeRoastDate = value }
        if let value = result.name { coffeeName = value }
        if let value = result.roaster { coffeeRoaster = value }
        if let value = result.origin { coffeeOrigin = value }
        if let value = result.region { coffeeRegion = value }
        if let value = result.altitude { coffeeAltitude = value }
        if let value = result.variety { coffeeVariety = value }
        if let value = result.process { coffeeProcess = value }
        if let value = result.tastingNotes { coffeeTastingNotes = value }
        let scannedName = coffeeName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !scannedName.isEmpty,
           !coffeeData.beanLots().contains(where: { normalizedCoffeeIdentity($0.name) == normalizedCoffeeIdentity(scannedName) }) {
            try? coffeeData.saveLot(BeanLotRecord(
                id: UUID(), name: scannedName,
                roaster: coffeeRoaster.trimmingCharacters(in: .whitespacesAndNewlines),
                origin: coffeeOrigin.trimmingCharacters(in: .whitespacesAndNewlines),
                region: coffeeRegion.trimmingCharacters(in: .whitespacesAndNewlines),
                variety: coffeeVariety.trimmingCharacters(in: .whitespacesAndNewlines),
                process: coffeeProcess.trimmingCharacters(in: .whitespacesAndNewlines),
                roastLevel: coffeeRoastLevel.trimmingCharacters(in: .whitespacesAndNewlines),
                tastingNotes: coffeeTastingNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                productID: nil, variantID: nil, replacementProductID: nil
            ))
        }
        createRecipeValidationMessage = nil
    }
#endif

}
