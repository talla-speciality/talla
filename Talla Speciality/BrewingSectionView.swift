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

struct BrewRecipeRecord: Identifiable {
    let id: UUID
    let title: String
    let detail: String
    let coffeeGrams: Double?
    let ratio: Double?
    let totalWaterGrams: Double?
    let brewingWaterGrams: Double?
    let iceGrams: Double?
    let methodID: String?
    let brewerID: String?
    let brewMode: String?
    let bloomRatio: String?
    let pourCount: Int?
    let grind: String?
    let temperatureC: Int?
    let controlMode: String?
    let process: String?
    let roast: String?
    let grinder: String?
    let filter: String?
    let altitudeMeters: Int?
    let tastingNotes: String?
    let targetTimeRange: String?
    let temperatureReason: String?
    let expectedCup: String?
    let approach: String?
    let steps: [SmartBrewStep]?

    init(id: UUID, title: String, detail: String, coffeeGrams: Double?, ratio: Double?, totalWaterGrams: Double?, brewingWaterGrams: Double?, iceGrams: Double?, methodID: String?, brewerID: String?, brewMode: String?, bloomRatio: String?, pourCount: Int?, grind: String?, temperatureC: Int?, controlMode: String?, process: String? = nil, roast: String? = nil, grinder: String? = nil, filter: String? = nil, altitudeMeters: Int? = nil, tastingNotes: String? = nil, targetTimeRange: String? = nil, temperatureReason: String? = nil, expectedCup: String? = nil, approach: String? = nil, steps: [SmartBrewStep]? = nil) {
        self.id = id; self.title = title; self.detail = detail; self.coffeeGrams = coffeeGrams; self.ratio = ratio
        self.totalWaterGrams = totalWaterGrams; self.brewingWaterGrams = brewingWaterGrams; self.iceGrams = iceGrams
        self.methodID = methodID; self.brewerID = brewerID; self.brewMode = brewMode; self.bloomRatio = bloomRatio
        self.pourCount = pourCount; self.grind = grind; self.temperatureC = temperatureC; self.controlMode = controlMode
        self.process = process; self.roast = roast; self.grinder = grinder; self.filter = filter; self.altitudeMeters = altitudeMeters
        self.tastingNotes = tastingNotes; self.targetTimeRange = targetTimeRange; self.temperatureReason = temperatureReason
        self.expectedCup = expectedCup; self.approach = approach; self.steps = steps
    }
}

enum BrewRecipeMath {
    static func waterSplit(totalWater: Double, isIced: Bool) -> (brewingWater: Double, ice: Double) {
        guard isIced else { return (totalWater, 0) }
        return (totalWater * 0.6, totalWater * 0.4)
    }

    static func suggestedBloomMultiplier(roast: String, process: String, tasteGoal: String) -> Double {
        let normalizedRoast = roast.lowercased()
        let normalizedProcess = process.lowercased()

        if normalizedRoast.contains("dark") || tasteGoal == "rich" || tasteGoal == "body" {
            return 2
        }
        if normalizedProcess.contains("natural") || normalizedProcess.contains("honey") || normalizedProcess.contains("anaerobic") {
            return 2.25
        }
        return 2.5
    }
}

#if canImport(UIKit)
private struct CoffeeBagCameraPicker: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (UIImage?) -> Void

        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completion(info[.originalImage] as? UIImage)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }
    }
}
#endif

#if canImport(ActivityKit)
    struct TallaBrewActivityAttributes: ActivityAttributes {
        struct ContentState: Codable, Hashable {
            let elapsedSeconds: Int
            let timerStartDate: Date
            let currentStep: String
            let nextStep: String
            let currentWaterGrams: Double
            let isPaused: Bool
            let stepTimes: [Int]
            let stepTitles: [String]
            let stepWaterTargets: [Double]
        }

    let methodName: String
    let coffeeGrams: Double
    let ratio: Double
    let totalWaterGrams: Double
    let totalSeconds: Int
    let languageCode: String
}
#endif

struct BrewingSectionView: View {
    private struct BrewModeStep: Identifiable {
        let id: Int
        let time: Int
        let title: String
        let detail: String
        let waterTarget: Double?
    }

    private struct BrewGuideProfile: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let icon: String
        let methodKeywords: [String]
        let coffeeGrams: Double
        let ratio: Double
        let grind: String
        let temperature: String
        let time: String
        let targetSeconds: Int
        let goal: String
        let steps: [String]
        let learningNotes: [String]
    }

    private enum BrewingDashboardDestination: String, Identifiable {
        case createRecipe
        case scanCoffeeBag
        case ratioCalculator
        case brewTimer
        case coffeeJournal
        case brewCoach

        var id: String { rawValue }
    }

    private enum CreateRecipeStep: Int, CaseIterable {
        case experience = 1
        case brewer
        case tasteGoal
        case coffeeDetails
        case equipment
        case generating
        case recipeDetail

        var progressText: String {
            "\(min(rawValue, 5)) of 5"
        }
    }

    private enum CoffeeDetailsMode {
        case scan
        case manual
    }

    private struct BrewChoice: Identifiable {
        let id: String
        let title: String
        let detail: String
        let systemImage: String
    }

    private struct BrewingMethodChoice: Identifiable, Hashable {
        let id: String
        let title: String
        let category: String
        let estimatedTime: String
        let description: String
        let systemImage: String
    }

    private struct RecipeGenerationStage: Identifiable {
        let id: Int
        let title: String
        let checks: [String]
    }

    private struct GeneratedPourRow: Identifiable {
        let id: Int
        let title: String
        let waterAdded: Int?
        let cumulativeWater: Int?
        let startTime: Int
        let flowRate: String
        let instruction: String
    }

    private struct RecipeRevisionChange: Identifiable {
        let id: String
        let title: String
        let before: String
        let after: String
        let reason: String
    }

    private struct CoffeeCalibrationRecord: Codable, Identifiable {
        let id: String
        var coffeeName: String
        var roaster: String
        var calibration: SmartBrewCalibration
        var updatedAt: Date
    }

    private struct PersistedBrewSession: Codable {
        let savedAt: Date
        let isPresented: Bool
        let isRunning: Bool
        let elapsedSeconds: Int
        let totalSeconds: Int
        let selectedMethodID: String?
        let activeSmartRecipeID: String?
        let selectedGuideProfileID: String
        let brewRecipeName: String
        let ratioCoffeeInput: String
        let ratioValueInput: String
        let createRecipeExperience: String
        let createRecipeBrewer: String
        let createRecipeTasteGoal: String
        let generatedGrindDescription: String
        let generatedTemperatureC: Int
        let recipePourCount: Int
        let scaleStepOverrideIndex: Int?
        let didCompleteBrewFromScale: Bool?
    }

    private enum BrewSessionStorage {
        static let activeSessionKey = "talla.brewing.activeSession.v1"
        static let profileCompletedKey = "talla.brewing.profileCompleted.v1"
        static let profileExperienceKey = "talla.brewing.profileExperience.v1"
        static let profileBrewerKey = "talla.brewing.profileBrewer.v1"
        static let profileTasteKey = "talla.brewing.profileTaste.v1"
        static let equipmentGrinderKey = "talla.brewing.equipmentGrinder.v1"
        static let equipmentFilterKey = "talla.brewing.equipmentFilter.v1"
        static let lastMethodKey = "talla.brewing.lastMethod.v1"
        static let lastBrewTimestampKey = "talla.brewing.lastBrewTimestamp.v1"
        static let favoriteMethodsKey = "talla.brewing.favoriteMethods.v1"
        static let coffeeCalibrationsKey = "talla.brewing.coffeeCalibrations.v1"
    }

    let isCompact: Bool
    let isCustomerSignedIn: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color
    let isOLEDAppearance: Bool
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
    let brewHistoryItems: [BrewRecipeRecord]
    let titleFont: Font
    let sectionTitleFont: Font
    let bodyFont: Font
    let labelFont: Font
    let saveRecipeAction: (BrewRecipeRecord) -> Void
    let openArticleAction: (URL) -> Void
    let guidedBrewCompletedAction: (ContentView.BrewingMethod?, Double, Double, Double, Int) -> Void
    let brewTimerSection: AnyView
    let coffeeJournalSection: AnyView
    let loadingView: AnyView
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var brewingColorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var scaleManager = CoffeeScaleManager()
    @AppStorage(BrewSessionStorage.profileCompletedKey) private var isBrewProfileComplete = false
    @AppStorage(BrewSessionStorage.profileExperienceKey) private var storedBrewProfileExperience = "basics"
    @AppStorage(BrewSessionStorage.profileBrewerKey) private var storedBrewProfileBrewer = "v60"
    @AppStorage(BrewSessionStorage.profileTasteKey) private var storedBrewProfileTaste = "balanced"
    @AppStorage(BrewSessionStorage.equipmentGrinderKey) private var storedEquipmentGrinder = ""
    @AppStorage(BrewSessionStorage.equipmentFilterKey) private var storedEquipmentFilter = ""
    @AppStorage(BrewSessionStorage.lastMethodKey) private var storedLastBrewMethodID = ""
    @AppStorage(BrewSessionStorage.lastBrewTimestampKey) private var storedLastBrewTimestamp = 0.0
    @AppStorage(BrewSessionStorage.favoriteMethodsKey) private var storedFavoriteBrewMethodIDs = "v60,solo,kalita"
    @AppStorage(BrewSessionStorage.coffeeCalibrationsKey) private var storedCoffeeCalibrations = ""
    @State private var isBrewModeRunning = false
    @State private var brewModeElapsedSeconds = 0
    @State private var brewModeRunID = UUID()
    @State private var lastCueStepIndex = -1
    @State private var lastPrePourCueStepID: Int?
    @State private var brewModeBackgroundDate: Date?
    @State private var brewModeHapticTrigger = 0
    @State private var selectedBrewModeMethodID: String?
    @State private var isFocusedBrewPresented = false
    @State private var isEndBrewConfirmationPresented = false
    @State private var isBrewRestartConfirmationPresented = false
    @State private var isScalePickerPresented = false
    @State private var isHomeScalePickerPresented = false
    @State private var selectedGuideProfileID = "balanced-filter"
    @State private var activeSmartRecipeID: String?
    @State private var expandedGuideProfileID: String?
    @State private var brewCoachQuestion = ""
    @State private var brewCoachAnswer: String?
    @State private var isGeneratingBrewCoachAnswer = false
    @State private var activeDashboardDestination: BrewingDashboardDestination?
    @State private var brewProfileStep: CreateRecipeStep = .experience
    @State private var createRecipeStep: CreateRecipeStep = .experience
    @State private var createRecipeValidationMessage: String?
    @State private var createRecipeExperience = "basics"
    @State private var createRecipeBrewer = "v60"
    @State private var createRecipeTasteGoal = "balanced"
    @State private var coffeeDetailsMode: CoffeeDetailsMode?
    @State private var coffeeName = ""
    @State private var coffeeRoaster = ""
    @State private var coffeeOrigin = ""
    @State private var coffeeRegion = ""
    @State private var coffeeAltitude = ""
    @State private var coffeeVariety = ""
    @State private var coffeeProcess = ""
    @State private var coffeeRoastLevel = "Medium"
    @State private var coffeeRoastDate = Date()
    @State private var coffeeTastingNotes = ""
    @State private var coffeeBrewNotes = ""
    @State private var recipeGrinder = ""
    @State private var recipeFilterType = ""
    @State private var recipeBrewTemperatureMode = "Hot"
    @State private var recipeCoffeeDose = "20"
    @State private var recipePreferredRatio = "16"
    @State private var recipeBloomRatio = "Auto"
    @State private var recipePourCount = 3
    @State private var recipeBrewControlMode = "Manual"
    @State private var brewerSearchText = ""
    @State private var isToolsMenuPresented = false
    @State private var isMethodSelectionPresented = false
    @State private var isSavedEquipmentPresented = false
    @State private var isRecentRecipesExpanded = false
    @State private var areAllBrewingGuidesVisible = false
    @State private var methodSearchText = ""
    @State private var methodCategoryFilter = "All"
    @State private var selectedMethodChoiceID = ""
    @State private var coffeeBagReviewMessage: String?
    @State private var isCoffeeBagImageAnalyzing = false
    @State private var coffeeBagAnalysisID = UUID()
    @State private var recipeGenerationStageIndex = 0
    @State private var recipeGenerationProgress = 0.0
    @State private var recipeGenerationTaskID = UUID()
    @State private var generatedRecipeNotes = ""
    @State private var expandedScienceTopics: Set<String> = []
    @State private var generatedGrindDescription = "Medium-fine"
    @State private var generatedTemperatureC = 93
    @State private var publishedRecipeCoffeeGrams: Double?
    @State private var publishedRecipeWaterGrams: Double?
    @State private var publishedRecipeIceGrams: Double?
    @State private var afterBrewRating = 0
    @State private var afterBrewSelections: Set<String> = []
    @State private var afterBrewMoreOfSelections: Set<String> = []
    @State private var afterBrewNotes = ""
    @State private var recipeRevisionChanges: [RecipeRevisionChange] = []
    @State private var revisedRecipeVersionTitle: String?
    @State private var isAfterBrewSavedToJournal = false
    @State private var isAfterBrewFeedbackExpanded = false
    @State private var hasRestoredPersistedBrewSession = false
    @State private var restoredBrewTotalSeconds: Int?
    @State private var generatedRecipeID = UUID()
    @State private var isGeneratedRecipeActive = false
    @State private var restoredRecipeSteps: [SmartBrewStep]?
    @State private var restoredTargetTimeRange: String?
    @State private var restoredTemperatureReason: String?
    @State private var restoredExpectedCup: String?
    @State private var restoredApproach: String?
    @State private var lastScaleAutoAdvancedStepID: Int?
    @State private var scaleStepOverrideIndex: Int?
    @State private var didCompleteBrewFromScale = false
#if canImport(PhotosUI)
    @State private var coffeeBagPhotoSelection: PhotosPickerItem?
#endif
#if canImport(UIKit)
    @State private var isCoffeeBagCameraPresented = false
    @State private var coffeeBagPreviewImage: UIImage?
#endif
#if canImport(ActivityKit)
    @State private var brewLiveActivity: Activity<TallaBrewActivityAttributes>?
#endif

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            brewingEditorialHeader

            if !isBrewProfileComplete {
                brewProfileSetupContent
            } else if isLoadingMethods && methodsAreEmpty {
                loadingView
            } else {
                brewingMinimalHomeContent
            }

            if let methodsError {
                brewingInlineMessage(methodsError)
            }
        }
        .frame(maxWidth: brewColumnMaxWidth, alignment: .leading)
        .fullScreenCover(isPresented: $isFocusedBrewPresented) {
            focusedBrewModeView
        }
        .fullScreenCover(item: $activeDashboardDestination) { destination in
            dashboardDestinationView(destination)
        }
        .sheet(isPresented: $isToolsMenuPresented) {
            brewingToolsMenu
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isMethodSelectionPresented) {
            brewingMethodSelectionView
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isSavedEquipmentPresented) {
            savedEquipmentEditor
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isHomeScalePickerPresented) {
            floatingBluetoothScalePicker {
                isHomeScalePickerPresented = false
            }
            .presentationBackground(.clear)
        }
        .onChange(of: isFocusedBrewPresented) { _, _ in
            updateBrewIdleTimerState()
            persistActiveBrewSession()
        }
        .onChange(of: isBrewModeRunning) { _, _ in
            updateBrewIdleTimerState()
            persistActiveBrewSession()
        }
        .onChange(of: brewModeElapsedSeconds) { _, _ in
            updateBrewIdleTimerState()
            persistActiveBrewSession()
        }
        .onChange(of: scaleManager.weightGrams) { previousWeight, currentWeight in
            handleSmartScaleWeightChange(previousWeight: previousWeight, currentWeight: currentWeight)
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleBrewScenePhaseChange(newPhase)
        }
        .onChange(of: isCustomerSignedIn) { _, signedIn in
            if signedIn {
                hasRestoredPersistedBrewSession = false
                restorePersistedBrewSessionIfNeeded()
            } else {
                resetVisibleBrewSession()
            }
        }
        .onAppear {
            restoreBrewProfileSelections()
            restorePersistedBrewSessionIfNeeded()
            updateBrewIdleTimerState()
        }
        .onDisappear {
            setBrewIdleTimerDisabled(false)
            endBrewLiveActivity()
        }
    }

    private var brewBackgroundColor: Color {
        isOLEDAppearance ? .black : (brewingColorScheme == .dark ? Color(hex: 0x15120E) : Color(hex: 0xF7F5EF))
    }

    private var brewSurfaceColor: Color {
        isOLEDAppearance ? .black : (brewingColorScheme == .dark ? Color(hex: 0x1F1A14) : Color(hex: 0xFFFDF8))
    }

    private var brewPrimaryTextColor: Color {
        brewingColorScheme == .dark ? Color(hex: 0xF7F5EF) : Color(hex: 0x1C1A17)
    }

    private var brewSecondaryTextColor: Color {
        brewingColorScheme == .dark ? Color(hex: 0xB9B1A6) : Color(hex: 0x74716A)
    }

    private var brewBorderColor: Color {
        brewingColorScheme == .dark ? Color(hex: 0x342E26) : Color(hex: 0xDED9CF)
    }

    private var brewAccentColor: Color {
        Color(hex: 0xC99550)
    }

    private var brewColumnMaxWidth: CGFloat {
        isCompact ? .infinity : 720
    }

    private var brewEyebrowFont: Font {
        .system(size: 11, weight: .semibold, design: .monospaced)
    }

    private var brewQuestionFont: Font {
        .system(size: isCompact ? 24 : 28, weight: .semibold)
    }

    private var brewReadingFont: Font {
        .system(size: 15, weight: .regular)
    }

    private var brewSerifTitleFont: Font {
        Font.custom("Georgia-Bold", size: isCompact ? 32 : 38)
    }

    private var brewingEditorialHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("the_craft", fallback: "THE CRAFT"))
                .font(brewEyebrowFont)
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)

            Text(AppLocalization.text("brewing_methods", fallback: "Brewing Methods"))
                .font(brewSerifTitleFont)
                .foregroundColor(brewPrimaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppLocalization.text("brewing_intro_dashboard", fallback: "Build, brew, and refine your perfect cup."))
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var brewProfileSetupContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            brewProfileProgressHeader

            Group {
                switch brewProfileStep {
                case .experience:
                    createRecipeQuestionStep(
                        question: AppLocalization.text("brew_profile_experience_question", fallback: "How much coffee brewing have you done?"),
                        choices: brewProfileExperienceChoices,
                        selection: $createRecipeExperience
                    )
                case .brewer:
                    VStack(alignment: .leading, spacing: 18) {
                        createRecipeQuestionStep(
                            question: AppLocalization.text("brew_profile_brewer_question", fallback: "What do you brew with?"),
                            choices: brewProfileBrewerChoices,
                            selection: $createRecipeBrewer
                        )

                        if createRecipeBrewer == "other" {
                            searchableBrewerList
                        }
                    }
                default:
                    createRecipeQuestionStep(
                        question: AppLocalization.text("brew_profile_taste_question", fallback: "How do you like your cup?"),
                        choices: brewProfileTasteChoices,
                        selection: $createRecipeTasteGoal
                    )
                }
            }

            brewProfileBottomControls
        }
    }

    private var brewProfileProgressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(brewProfileProgressLabel)
                .font(brewEyebrowFont)
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(brewBorderColor)
                    Rectangle()
                        .fill(brewAccentColor)
                        .frame(width: max(18, proxy.size.width * brewProfileProgressFraction))
                }
            }
            .frame(height: 2)
        }
        .accessibilityElement(children: .combine)
    }

    private var brewingMinimalHomeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if isBrewModeRunning || brewModeElapsedSeconds > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    brewSectionLabel(AppLocalization.text("active_brew", fallback: "Active Brew"))
                    brewingLinkedRow(
                        title: AppLocalization.text("continue_active_brew", fallback: "Continue active brew"),
                        detail: currentBrewRecipeTitle,
                        value: formattedBrewElapsedTime
                    ) {
                        isFocusedBrewPresented = true
                    }
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            primaryBrewEntrySection
            brewScaleConnectionSection
            brewingMinimalRecentRecipes
            brewingLibrarySection
            exploreBrewingGuidesSection
        }
    }

    private var primaryBrewEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            brewSectionLabel(AppLocalization.text("start_a_brew", fallback: "Start a Brew"))

            VStack(alignment: .leading, spacing: 14) {
                if hasPreviousBrew {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(lastBrewMethodChoice.title)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)

                        Spacer(minLength: 8)

                        Text(formattedLastBrewDate)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(brewSecondaryTextColor)
                    }

                    Text(primaryBrewEntryDescription)
                        .font(brewReadingFont)
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(primaryBrewEntryDescription)
                        .font(brewReadingFont)
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    if hasPreviousBrew {
                        startLastGuidedBrew()
                    } else {
                        openMethodSelection()
                    }
                } label: {
                    Text(hasPreviousBrew ? AppLocalization.text("brew_again", fallback: "Brew Again") : AppLocalization.text("choose_method", fallback: "Choose Method"))
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.plain)
                .foregroundColor(brewingColorScheme == .dark ? brewPrimaryTextColor : .white)
                .background(brewAccentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if hasPreviousBrew {
                    Button {
                        openMethodSelection()
                    } label: {
                        HStack(spacing: 7) {
                            Text(AppLocalization.text("choose_another_method", fallback: "Choose Another Method"))
                            Image(systemName: "arrow.forward")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(brewAccentColor)
                        .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var brewScaleConnectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            brewSectionLabel(AppLocalization.text("brew_scale", fallback: "Brew scale"))

            Button {
                isHomeScalePickerPresented = true
            } label: {
                HStack(spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [brewAccentColor.opacity(0.20), brewAccentColor.opacity(0.07)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(brewAccentColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Circle()
                            .fill(scaleManager.isConnected ? Color.green : brewSecondaryTextColor.opacity(0.45))
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(brewSurfaceColor, lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }
                    .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(scaleManager.connectedScaleName ?? AppLocalization.text("add_bluetooth_scale", fallback: "Add a Bluetooth scale"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)
                            .lineLimit(1)

                        Text(scaleManager.isConnected
                             ? AppLocalization.text("scale_ready_live", fallback: "Ready for live weight, flow and tare")
                             : AppLocalization.text("scale_optional", fallback: "Optional · guided brewing works without one"))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(brewSecondaryTextColor)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.forward")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(brewAccentColor)
                        .frame(width: 32, height: 32)
                        .background(brewAccentColor.opacity(0.09))
                        .clipShape(Circle())
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(scaleManager.isConnected ? brewAccentColor.opacity(0.46) : brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(scaleManager.isConnected
                ? AppLocalization.text("manage_bluetooth_scale", fallback: "Manage connected Bluetooth scale")
                : AppLocalization.text("add_bluetooth_scale", fallback: "Add a Bluetooth scale"))
            .accessibilityHint(AppLocalization.text("scale_optional_hint", fallback: "Optional. Guided brewing also works without a scale."))
        }
    }

    private var primaryBrewEntryDescription: String {
        if hasPreviousBrew {
            return "\(formattedRatioValue(validCoffeeAmount)) g coffee  ·  1:\(formattedRatioValue(validRatioValue)) ratio"
        }

        return AppLocalization.text(
            "start_brew_description",
            fallback: "Choose your brewing method, add your coffee, and build a recipe around it."
        )
    }

    private var brewingMinimalRecentRecipes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                guard !brewHistoryItems.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    isRecentRecipesExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    brewSectionLabel(AppLocalization.text("recent_recipes", fallback: "Recent Recipes"))
                    Spacer(minLength: 8)
                    if !brewHistoryItems.isEmpty {
                        Text("\(min(brewHistoryItems.count, 4))")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(brewSecondaryTextColor)
                        Image(systemName: isRecentRecipesExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(brewSecondaryTextColor)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if brewHistoryItems.isEmpty {
                VStack(spacing: 0) {
                    Text(AppLocalization.text("no_recent_recipes_yet", fallback: "Your recent recipes will appear after your first saved brew."))
                        .font(brewReadingFont)
                        .foregroundColor(brewSecondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if isRecentRecipesExpanded {
                VStack(spacing: 0) {
                    let recipes = brewHistoryItems.prefix(4)
                    ForEach(Array(recipes.enumerated()), id: \.offset) { index, recipe in
                        if index > 0 {
                            brewDivider
                        }
                        brewingLinkedRow(title: recipe.title, detail: recipe.detail, value: AppLocalization.text("brew_again", fallback: "Brew Again")) {
                            applySavedRecipe(recipe, start: true)
                        }
                    }
                }
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var brewingLibrarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            brewSectionLabel(AppLocalization.text("brew_library", fallback: "Brew Library"))
            brewingMinimalShortcuts
        }
    }

    private var brewingMinimalShortcuts: some View {
        VStack(spacing: 0) {
            brewingLinkedRow(title: AppLocalization.text("coffee_journal", fallback: "Coffee Journal"), detail: AppLocalization.text("journal_shortcut_detail", fallback: "Review tasting notes and saved cups."), value: nil) {
                activeDashboardDestination = .coffeeJournal
            }
            brewDivider
            brewingLinkedRow(title: AppLocalization.text("saved_equipment", fallback: "Saved Equipment"), detail: savedEquipmentDetail, value: nil) {
                isSavedEquipmentPresented = true
            }
            brewDivider
            brewingLinkedRow(title: AppLocalization.text("tools", fallback: "Tools"), detail: AppLocalization.text("tools_menu_detail", fallback: "Ratio calculator, timer, journal, and brew coach."), value: nil) {
                isToolsMenuPresented = true
            }
        }
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brewBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var savedEquipmentDetail: String {
        let grinder = recipeGrinder.trimmingCharacters(in: .whitespacesAndNewlines)
        let grinderText = grinder.isEmpty ? AppLocalization.text("add_grinder", fallback: "Add grinder") : grinder
        return "\(brewProfileBrewerName) · \(grinderText)"
    }

    private var savedEquipmentEditor: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(AppLocalization.text("saved_equipment", fallback: "Saved Equipment"))
                        .font(brewSerifTitleFont)
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppLocalization.text("saved_equipment_detail", fallback: "Save your brewer, grinder, and filter so new recipes start with your setup."))
                        .font(brewReadingFont)
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    brewerSetupSelector
                    catalogPicker(title: AppLocalization.text("grinder", fallback: "Grinder"), selection: $recipeGrinder, options: grinderCatalog, customPlaceholder: "Other grinder")
                    catalogPicker(title: AppLocalization.text("filter", fallback: "Filter"), selection: $recipeFilterType, options: filterCatalog, customPlaceholder: "Other filter")
                }
                .padding(20)
            }
            .background(brewBackgroundColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("cancel", fallback: "Cancel")) {
                        restoreSavedEquipmentSelections()
                        isSavedEquipmentPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLocalization.text("save", fallback: "Save")) {
                        persistSavedEquipmentSelections()
                        isSavedEquipmentPresented = false
                    }
                }
            }
        }
    }

    private var brewingToolsMenu: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    brewingLinkedRow(title: AppLocalization.text("ratio_calculator", fallback: "Ratio Calculator"), detail: AppLocalization.text("ratio_calculator_detail", fallback: "Dose, ratio, and water totals."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .ratioCalculator
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("brew_timer", fallback: "Brew Timer"), detail: AppLocalization.text("brew_timer_detail", fallback: "A focused timer for manual recipes."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .brewTimer
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("coffee_journal", fallback: "Coffee Journal"), detail: AppLocalization.text("coffee_journal_detail", fallback: "Taste notes and brew history."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .coffeeJournal
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("brew_coach", fallback: "Brew Coach"), detail: AppLocalization.text("brew_coach_detail", fallback: "Small adjustments for the next cup."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .brewCoach
                    }
                }
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(22)
            }
            .background(brewBackgroundColor.ignoresSafeArea())
            .navigationTitle(AppLocalization.text("tools", fallback: "Tools"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var brewingMethodSelectionView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalization.text("choose_brewing_method", fallback: "Choose a Brewing Method"))
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundColor(brewPrimaryTextColor)
                            .accessibilityAddTraits(.isHeader)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(brewSecondaryTextColor)
                                .accessibilityHidden(true)
                            TextField(AppLocalization.text("search_methods", fallback: "Search methods"), text: $methodSearchText)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .font(.system(size: 16))
                                .submitLabel(.search)
                        }
                        .frame(minHeight: 46)
                        .padding(.horizontal, 14)
                        .background(brewSurfaceColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(brewBorderColor, lineWidth: 1)
                        )
                    }

                    methodCategorySelector

                    if methodSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        methodChoiceSection(
                            title: AppLocalization.text("recent_methods", fallback: "Recent Methods"),
                            methods: recentMethodChoices
                        )
                        methodChoiceSection(
                            title: AppLocalization.text("favourites", fallback: "Favourites"),
                            methods: deduplicatedFavoriteMethodChoices
                        )
                    }

                    methodChoiceSection(
                        title: AppLocalization.text("popular_methods", fallback: "Popular Methods"),
                        methods: deduplicatedFilteredMethodChoices
                    )
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, selectedMethodChoice == nil ? 28 : 112)
                .frame(maxWidth: brewColumnMaxWidth, alignment: .leading)
            }
            .background(brewBackgroundColor.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if let selectedMethodChoice {
                    VStack(spacing: 10) {
                        brewDivider.padding(.leading, 0)
                        Button {
                            beginBrewSetup(with: selectedMethodChoice)
                        } label: {
                            Text(String(format: AppLocalization.text("start_guided_brew_with_method", fallback: "Start guided brew with %@"), selectedMethodChoice.title))
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(brewingColorScheme == .dark ? brewPrimaryTextColor : .white)
                        .background(brewAccentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Button {
                            beginCustomRecipeSetup(with: selectedMethodChoice)
                        } label: {
                            Text(AppLocalization.text("customize_recipe", fallback: "Customize recipe"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(brewAccentColor)
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.plain)

                        .padding(.bottom, 4)
                    }
                        .padding(.horizontal, 22)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                        .background(brewBackgroundColor)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("close", fallback: "Close")) {
                        isMethodSelectionPresented = false
                    }
                    .foregroundColor(brewPrimaryTextColor)
                }
            }
        }
    }

    @ViewBuilder
    private var methodCategorySelector: some View {
        if horizontalSizeClass == .compact {
            Menu {
                ForEach(methodCategoryFilters, id: \.self) { category in
                    Button {
                        methodCategoryFilter = category
                    } label: {
                        if methodCategoryFilter == category {
                            Label(category, systemImage: "checkmark")
                        } else {
                            Text(category)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(String(format: AppLocalization.text("category_format", fallback: "Category: %@"), methodCategoryFilter))
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(brewPrimaryTextColor)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(methodCategoryFilters, id: \.self) { category in
                    Button {
                        methodCategoryFilter = category
                    } label: {
                        Text(category)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(methodCategoryFilter == category ? brewAccentColor : brewSecondaryTextColor)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 14)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(methodCategoryFilter == category ? brewAccentColor : brewBorderColor.opacity(0.45))
                                    .frame(height: methodCategoryFilter == category ? 2 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(methodCategoryFilter == category ? .isSelected : [])
                }
            }
        }
        }
    }

    private func methodChoiceSection(title: String, methods: [BrewingMethodChoice]) -> some View {
        Group {
            if !methods.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    brewSectionLabel(title)

                    VStack(spacing: 0) {
                        ForEach(Array(methods.enumerated()), id: \.element.id) { index, method in
                            if index > 0 {
                                brewDivider
                            }
                            brewingMethodRow(method)
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
        }
    }

    private func brewingMethodRow(_ method: BrewingMethodChoice) -> some View {
        let isSelected = selectedMethodChoiceID == method.id

        return Button {
            selectedMethodChoiceID = method.id
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: method.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(brewAccentColor)
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(method.category) · \(method.estimatedTime)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(brewSecondaryTextColor)

                    Text(method.description)
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark" : "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? brewAccentColor : brewSecondaryTextColor)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 76)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? brewAccentColor : Color.clear, lineWidth: 1)
                    .padding(4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var exploreBrewingGuidesSection: some View {
        Group {
            if !displayedMethods.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        brewSectionLabel(AppLocalization.text("explore_brewing_guides", fallback: "Explore Brewing Guides"))
                        Spacer(minLength: 8)
                        if displayedMethods.count > 3 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    areAllBrewingGuidesVisible.toggle()
                                }
                            } label: {
                                Text(areAllBrewingGuidesVisible ? AppLocalization.text("show_less", fallback: "Show Less") : AppLocalization.text("view_all", fallback: "View All"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(brewAccentColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(visibleBrewingGuides.enumerated()), id: \.element.id) { index, method in
                            if index > 0 {
                                brewDivider
                            }
                            brewingGuideEntryRow(method)
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
        }
    }

    private var visibleBrewingGuides: [ContentView.BrewingMethod] {
        areAllBrewingGuidesVisible ? displayedMethods : Array(displayedMethods.prefix(3))
    }

    private func brewingGuideEntryRow(_ method: ContentView.BrewingMethod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                selectedBrewModeMethodID = method.id
                activeCategory = method.categories.first ?? activeCategory
            } label: {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(method.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(method.summary)
                            .font(.system(size: 14))
                            .foregroundColor(brewSecondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text(AppLocalization.text("read_guide", fallback: "Read Guide"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(brewAccentColor)

                    Image(systemName: "chevron.forward")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(brewSecondaryTextColor)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                beginBrewSetup(with: methodChoice(from: method))
            } label: {
                Text(AppLocalization.text("use_this_method", fallback: "Use This Method"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func brewingFactRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(brewEyebrowFont)
                .foregroundColor(brewSecondaryTextColor)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(brewPrimaryTextColor)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 36)
    }

    private var brewDivider: some View {
        Rectangle()
            .fill(brewBorderColor)
            .frame(height: 1)
            .padding(.leading, 18)
    }

    private func brewingInlineMessage(_ message: String) -> some View {
        Text(message)
            .font(brewReadingFont)
            .foregroundColor(brewSecondaryTextColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 10)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(brewBorderColor)
                    .frame(height: 1)
            }
    }

    private func brewSectionLabel(_ title: String) -> some View {
        Text(title)
            .font(brewEyebrowFont)
            .tracking(2)
            .textCase(.uppercase)
            .foregroundColor(brewAccentColor)
    }

    private func brewingLinkedRow(title: String, detail: String, value: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
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

                if let value {
                    Text(value)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(brewAccentColor)
                        .multilineTextAlignment(.trailing)
                }

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(brewSecondaryTextColor)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 64)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var formattedBrewElapsedTime: String {
        formattedTimerTime(brewModeElapsedSeconds)
    }

    private var hasPreviousBrew: Bool {
        guard isCustomerSignedIn else { return false }
        return storedLastBrewTimestamp > 0 || !storedLastBrewMethodID.isEmpty || !brewHistoryItems.isEmpty
    }

    private var formattedLastBrewDate: String {
        guard storedLastBrewTimestamp > 0 else {
            return AppLocalization.text("recently", fallback: "Recently")
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date(timeIntervalSince1970: storedLastBrewTimestamp))
    }

    private var methodCategoryFilters: [String] {
        [
            AppLocalization.text("all", fallback: "All"),
            AppLocalization.text("pour_over", fallback: "Pour Over"),
            AppLocalization.text("immersion", fallback: "Immersion"),
            AppLocalization.text("traditional", fallback: "Traditional"),
            AppLocalization.text("espresso", fallback: "Espresso"),
            AppLocalization.text("cold_brew", fallback: "Cold Brew")
        ]
    }

    private var popularMethodChoices: [BrewingMethodChoice] {
        [
            BrewingMethodChoice(id: "v60", title: "V60", category: AppLocalization.text("pour_over", fallback: "Pour Over"), estimatedTime: "3–4 min", description: AppLocalization.text("v60_method_description", fallback: "Clear, precise cups with controlled pouring."), systemImage: "triangle"),
            BrewingMethodChoice(id: "solo", title: "SOLO Dripper", category: AppLocalization.text("pour_over", fallback: "Pour Over"), estimatedTime: "3–4 min", description: AppLocalization.text("solo_method_description", fallback: "Balanced filter brews with a steady, forgiving flow."), systemImage: "trapezoid.and.line.vertical"),
            BrewingMethodChoice(id: "kalita", title: "Kalita Wave", category: AppLocalization.text("pour_over", fallback: "Pour Over"), estimatedTime: "3–4 min", description: AppLocalization.text("kalita_method_description", fallback: "Sweet, even cups from a flat-bottom brewer."), systemImage: "line.3.horizontal.decrease"),
            BrewingMethodChoice(id: "chemex", title: "Chemex", category: AppLocalization.text("pour_over", fallback: "Pour Over"), estimatedTime: "4–6 min", description: AppLocalization.text("chemex_method_description", fallback: "Clean texture and clarity for larger brews."), systemImage: "hourglass"),
            BrewingMethodChoice(id: "aeropress", title: "AeroPress", category: AppLocalization.text("immersion", fallback: "Immersion"), estimatedTime: "2–3 min", description: AppLocalization.text("aeropress_method_description", fallback: "Fast, flexible brewing with gentle pressure."), systemImage: "capsule.portrait"),
            BrewingMethodChoice(id: "french-press", title: "French Press", category: AppLocalization.text("immersion", fallback: "Immersion"), estimatedTime: "4–5 min", description: AppLocalization.text("french_press_method_description", fallback: "Full body and a rounded, comforting cup."), systemImage: "cylinder"),
            BrewingMethodChoice(id: "arabic", title: "Arabic Coffee", category: AppLocalization.text("traditional", fallback: "Traditional"), estimatedTime: "8–12 min", description: AppLocalization.text("arabic_method_description", fallback: "Aromatic traditional brewing with gentle heat."), systemImage: "flame.fill"),
            BrewingMethodChoice(id: "v60-iced", title: "V60 Iced", category: AppLocalization.text("cold_brew", fallback: "Cold Brew"), estimatedTime: "2:15", description: "20 g coffee, 180 g hot water, and 120 g ice with three timed pours.", systemImage: "snowflake"),
            BrewingMethodChoice(id: "cold", title: "Cold Brew", category: AppLocalization.text("cold_brew", fallback: "Cold Brew"), estimatedTime: "12–18 hr", description: AppLocalization.text("cold_brew_method_description", fallback: "Slow extraction for a smooth, low-acidity cup."), systemImage: "snowflake"),
            BrewingMethodChoice(id: "espresso", title: "Espresso", category: AppLocalization.text("espresso", fallback: "Espresso"), estimatedTime: "25–35 sec", description: AppLocalization.text("espresso_method_description", fallback: "Concentrated, pressure-brewed coffee with intensity."), systemImage: "cup.and.saucer.fill")
        ]
    }

    private var favoriteMethodChoices: [BrewingMethodChoice] {
        let ids = storedFavoriteBrewMethodIDs
            .split(separator: ",")
            .map(String.init)
        let favourites = ids.compactMap { methodChoice(for: $0) }
        return Array(favourites.prefix(3))
    }

    private var recentMethodChoices: [BrewingMethodChoice] {
        var ids: [String] = []
        if !storedLastBrewMethodID.isEmpty {
            ids.append(storedLastBrewMethodID)
        }
        ids.append(storedBrewProfileBrewer)
        ids.append(createRecipeBrewer)

        var seen = Set<String>()
        return ids.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return methodChoice(for: id)
        }
        .prefix(3)
        .map { $0 }
    }

    private var filteredMethodChoices: [BrewingMethodChoice] {
        let search = methodSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allCategory = AppLocalization.text("all", fallback: "All")

        return popularMethodChoices.filter { method in
            let matchesCategory = methodCategoryFilter == allCategory || method.category == methodCategoryFilter
            let matchesSearch = search.isEmpty
                || method.title.lowercased().contains(search)
                || method.category.lowercased().contains(search)
                || method.description.lowercased().contains(search)
            return matchesCategory && matchesSearch
        }
    }

    private var deduplicatedFavoriteMethodChoices: [BrewingMethodChoice] {
        let recentIDs = Set(recentMethodChoices.map(\.id))
        return favoriteMethodChoices.filter { !recentIDs.contains($0.id) }
    }

    private var deduplicatedFilteredMethodChoices: [BrewingMethodChoice] {
        guard methodSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return filteredMethodChoices
        }
        let shownIDs = Set((recentMethodChoices + deduplicatedFavoriteMethodChoices).map(\.id))
        return filteredMethodChoices.filter { !shownIDs.contains($0.id) }
    }

    private var selectedMethodChoice: BrewingMethodChoice? {
        methodChoice(for: selectedMethodChoiceID)
    }

    private var lastBrewMethodChoice: BrewingMethodChoice {
        methodChoice(for: storedLastBrewMethodID)
            ?? methodChoice(for: storedBrewProfileBrewer)
            ?? popularMethodChoices[0]
    }

    private func methodChoice(for id: String) -> BrewingMethodChoice? {
        popularMethodChoices.first { $0.id == id }
    }

    private func methodChoice(from method: ContentView.BrewingMethod) -> BrewingMethodChoice {
        if let exact = methodChoice(for: method.id) {
            return exact
        }

        let source = ([method.id, method.name, method.summary, method.detail] + method.categories)
            .joined(separator: " ")
            .lowercased()

        return popularMethodChoices.first { choice in
            source.contains(choice.id) || source.contains(choice.title.lowercased())
        } ?? BrewingMethodChoice(
            id: method.id,
            title: method.name,
            category: method.categories.first ?? AppLocalization.text("all", fallback: "All"),
            estimatedTime: method.brewTime,
            description: method.summary,
            systemImage: "cup.and.saucer"
        )
    }

    private func openMethodSelection() {
        if isCustomerSignedIn {
            selectedMethodChoiceID = storedLastBrewMethodID.isEmpty ? storedBrewProfileBrewer : storedLastBrewMethodID
        } else {
            selectedMethodChoiceID = "v60"
        }
        if methodChoice(for: selectedMethodChoiceID) == nil {
            selectedMethodChoiceID = "v60"
        }
        methodSearchText = ""
        methodCategoryFilter = AppLocalization.text("all", fallback: "All")
        isMethodSelectionPresented = true
    }

    private func beginBrewSetup(with method: BrewingMethodChoice, rememberSelection: Bool = true) {
        createRecipeBrewer = method.id
        let displayedMethodID = matchingDisplayedMethodID(for: method)
        selectedBrewModeMethodID = displayedMethodID
        let publishedRecipe = displayedMethods.first { $0.id == displayedMethodID }?.publishedRecipe
        applyPublishedRecipeDefaults(for: method.id, publishedRecipe: publishedRecipe)
        if isCustomerSignedIn {
            storedBrewProfileBrewer = method.id
        }
        if isCustomerSignedIn {
            storedLastBrewMethodID = method.id
            if rememberSelection || storedLastBrewTimestamp == 0 {
                storedLastBrewTimestamp = Date().timeIntervalSince1970
            }
        }

        isMethodSelectionPresented = false

        DispatchQueue.main.async {
            if let guidedMethod = displayedMethods.first(where: { $0.id == displayedMethodID }) {
                selectBrewModeMethod(guidedMethod, start: true)
            } else {
                beginCustomRecipeSetup(with: method, rememberSelection: false)
            }
        }
    }

    private func beginCustomRecipeSetup(with method: BrewingMethodChoice, rememberSelection: Bool = true) {
        createRecipeBrewer = method.id
        let displayedMethodID = matchingDisplayedMethodID(for: method)
        selectedBrewModeMethodID = displayedMethodID
        let publishedRecipe = displayedMethods.first { $0.id == displayedMethodID }?.publishedRecipe
        applyPublishedRecipeDefaults(for: method.id, publishedRecipe: publishedRecipe)
        if isCustomerSignedIn {
            storedBrewProfileBrewer = method.id
            storedLastBrewMethodID = method.id
            if rememberSelection || storedLastBrewTimestamp == 0 {
                storedLastBrewTimestamp = Date().timeIntervalSince1970
            }
        }

        prepareNewRecipeJourney(startsWithScan: false)
        isMethodSelectionPresented = false

        DispatchQueue.main.async {
            activeDashboardDestination = .createRecipe
        }
    }

    private func startLastGuidedBrew() {
        let methodChoice = lastBrewMethodChoice
        createRecipeBrewer = methodChoice.id
        selectedBrewModeMethodID = matchingDisplayedMethodID(for: methodChoice)

        if isCustomerSignedIn {
            storedBrewProfileBrewer = methodChoice.id
            storedLastBrewMethodID = methodChoice.id
            storedLastBrewTimestamp = Date().timeIntervalSince1970
        }

        if let latestRecipe = brewHistoryItems.first {
            applySavedRecipe(latestRecipe, start: true)
        } else if let methodID = selectedBrewModeMethodID,
                  let method = displayedMethods.first(where: { $0.id == methodID }) {
            selectBrewModeMethod(method, start: true)
        } else {
            brewRecipeName = methodChoice.title
            restartBrewMode()
        }
    }

    private func applyPublishedRecipeDefaults(for methodID: String, publishedRecipe: ContentView.BrewingMethod.PublishedRecipe?) {
        usePublishedRecipe(publishedRecipe)

        switch methodID {
        case "cold":
            recipeCoffeeDose = "60"
            recipePreferredRatio = "8"
            recipeBrewTemperatureMode = "Cold"
            recipeBloomRatio = "Auto"
            recipePourCount = 2
            generatedGrindDescription = "Coarse"
            generatedTemperatureC = 20
        case "v60-iced":
            recipeCoffeeDose = "20"
            recipePreferredRatio = "15"
            recipeBrewTemperatureMode = "Iced"
            recipeBloomRatio = "Auto"
            recipePourCount = 3
            generatedGrindDescription = "Medium"
            generatedTemperatureC = 93
        default:
            recipeCoffeeDose = "20"
            recipePreferredRatio = "16"
            recipeBrewTemperatureMode = "Hot"
            recipeBloomRatio = "Auto"
            recipePourCount = 3
            generatedTemperatureC = 93
        }

        if let coffeeGrams = publishedRecipe?.coffeeGrams {
            recipeCoffeeDose = formattedRatioValue(coffeeGrams)
        }
        if let ratio = publishedRecipe?.ratio {
            recipePreferredRatio = formattedRatioValue(ratio)
        }
    }

    private func usePublishedRecipe(_ publishedRecipe: ContentView.BrewingMethod.PublishedRecipe?) {
        publishedRecipeCoffeeGrams = publishedRecipe?.coffeeGrams
        publishedRecipeWaterGrams = publishedRecipe?.waterGrams
        publishedRecipeIceGrams = publishedRecipe?.iceGrams
    }

    private func matchingDisplayedMethodID(for method: BrewingMethodChoice) -> String? {
        let target = method.title.lowercased()
        let id = method.id.lowercased()

        return displayedMethods.first { displayedMethod in
            let source = ([displayedMethod.id, displayedMethod.name, displayedMethod.summary, displayedMethod.detail] + displayedMethod.categories)
                .joined(separator: " ")
                .lowercased()
            return source.contains(id) || source.contains(target) || target.contains(displayedMethod.name.lowercased())
        }?.id
    }

    private func continueRecipeDetail(_ latest: BrewRecipeRecord?) -> String {
        if let latest {
            return latest.detail
        }

        if let profile = selectedGuideProfile {
            return "\(formattedRatioValue(profile.coffeeGrams)) g · 1:\(formattedRatioValue(profile.ratio)) · \(profile.time)"
        }

        return "20 g · 1:16 · 3:30"
    }

    private var brewProfileExperienceChoices: [BrewChoice] {
        [
            BrewChoice(id: "starting", title: AppLocalization.text("profile_exp_starting", fallback: "Just starting out"), detail: AppLocalization.text("profile_exp_starting_detail", fallback: "Keep the recipe simple and guide every step."), systemImage: "1.circle"),
            BrewChoice(id: "basics", title: AppLocalization.text("profile_exp_basics", fallback: "I know the basics"), detail: AppLocalization.text("profile_exp_basics_detail", fallback: "Give me reliable starting points with room to adjust."), systemImage: "2.circle"),
            BrewChoice(id: "dial", title: AppLocalization.text("profile_exp_dial", fallback: "I dial in my brews"), detail: AppLocalization.text("profile_exp_dial_detail", fallback: "Give me full control over grind, ratio, temperature, and pours."), systemImage: "3.circle"),
            BrewChoice(id: "automatic", title: AppLocalization.text("profile_exp_auto", fallback: "I use an automatic brewer"), detail: AppLocalization.text("profile_exp_auto_detail", fallback: "Build recipes that can be transferred to my equipment."), systemImage: "4.circle")
        ]
    }

    private var brewProfileBrewerChoices: [BrewChoice] {
        [
            BrewChoice(id: "v60", title: "V60", detail: AppLocalization.text("v60_profile_detail", fallback: "Clean cone-style pour-over."), systemImage: "triangle"),
            BrewChoice(id: "solo", title: "SOLO Dripper", detail: AppLocalization.text("solo_profile_detail", fallback: "Precise filter brewing."), systemImage: "trapezoid.and.line.vertical"),
            BrewChoice(id: "kalita", title: "Kalita Wave", detail: AppLocalization.text("kalita_profile_detail", fallback: "Flat-bottom balance and sweetness."), systemImage: "line.3.horizontal.decrease"),
            BrewChoice(id: "chemex", title: "Chemex", detail: AppLocalization.text("chemex_profile_detail", fallback: "Clean texture and larger brews."), systemImage: "hourglass"),
            BrewChoice(id: "origami", title: "Origami", detail: AppLocalization.text("origami_profile_detail", fallback: "Flexible flow and clarity."), systemImage: "diamond"),
            BrewChoice(id: "aeropress", title: "AeroPress", detail: AppLocalization.text("aeropress_profile_detail", fallback: "Pressure-assisted and fast."), systemImage: "capsule.portrait"),
            BrewChoice(id: "french-press", title: "French Press", detail: AppLocalization.text("french_press_profile_detail", fallback: "Immersion body and depth."), systemImage: "cylinder"),
            BrewChoice(id: "espresso", title: "Espresso", detail: AppLocalization.text("espresso_profile_detail", fallback: "Short, concentrated brewing."), systemImage: "cup.and.saucer"),
            BrewChoice(id: "arabic", title: "Arabic coffee", detail: AppLocalization.text("arabic_profile_detail", fallback: "Traditional heat and aroma."), systemImage: "flame"),
            BrewChoice(id: "cold", title: "Cold brew", detail: AppLocalization.text("cold_profile_detail", fallback: "Slow extraction for cold service."), systemImage: "snowflake"),
            BrewChoice(id: "automatic", title: "Automatic brewer", detail: AppLocalization.text("automatic_profile_detail", fallback: "Recipes shaped for equipment transfer."), systemImage: "gearshape.2"),
            BrewChoice(id: "other", title: "Something else", detail: AppLocalization.text("other_profile_detail", fallback: "Search the brewer list."), systemImage: "magnifyingglass")
        ]
    }

    private var brewProfileTasteChoices: [BrewChoice] {
        [
            BrewChoice(id: "bright", title: AppLocalization.text("bright_clean", fallback: "Bright & clean"), detail: AppLocalization.text("profile_taste_bright_detail", fallback: "Lively acidity, clarity, and a lighter body."), systemImage: "sparkle"),
            BrewChoice(id: "balanced", title: AppLocalization.text("balanced", fallback: "Balanced"), detail: AppLocalization.text("profile_taste_balanced_detail", fallback: "A little of everything, with nothing dominating."), systemImage: "circle.lefthalf.filled"),
            BrewChoice(id: "sweet", title: AppLocalization.text("sweet_round", fallback: "Sweet & round"), detail: AppLocalization.text("profile_taste_sweet_detail", fallback: "Soft acidity, noticeable sweetness, and a smooth finish."), systemImage: "drop"),
            BrewChoice(id: "rich", title: AppLocalization.text("rich_full", fallback: "Rich & full"), detail: AppLocalization.text("profile_taste_rich_detail", fallback: "More body, depth, and weight."), systemImage: "circle.fill")
        ]
    }

    private var searchableBrewerList: some View {
        VStack(alignment: .leading, spacing: 12) {
            createRecipeTextField(
                title: AppLocalization.text("search_brewers", fallback: "Search brewers"),
                placeholder: AppLocalization.text("search_brewers_placeholder", fallback: "Orea, December, Stagg..."),
                text: $brewerSearchText
            )

            VStack(spacing: 0) {
                ForEach(Array(filteredSearchBrewers.enumerated()), id: \.element.id) { index, brewer in
                    if index > 0 {
                        brewDivider
                    }
                    createRecipeChoiceCard(brewer, selection: $createRecipeBrewer)
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

    private var filteredSearchBrewers: [BrewChoice] {
        let extended = [
            BrewChoice(id: "orea", title: "Orea", detail: AppLocalization.text("orea_detail", fallback: "Fast flat-bottom filter brewing."), systemImage: "circle.grid.cross"),
            BrewChoice(id: "stagg", title: "Fellow Stagg", detail: AppLocalization.text("stagg_detail", fallback: "Controlled flow and steady bed depth."), systemImage: "square"),
            BrewChoice(id: "december", title: "December Dripper", detail: AppLocalization.text("december_detail", fallback: "Adjustable flow for filter recipes."), systemImage: "slider.horizontal.3"),
            BrewChoice(id: "clever", title: "Clever Dripper", detail: AppLocalization.text("clever_detail", fallback: "Immersion-first filter brewing."), systemImage: "cup.and.saucer")
        ]
        let query = brewerSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return extended }
        return extended.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.detail.localizedCaseInsensitiveContains(query) }
    }

    private var brewProfileProgressLabel: String {
        switch brewProfileStep {
        case .experience:
            return "01 / 03  EXPERIENCE"
        case .brewer:
            return "02 / 03  BREWER"
        default:
            return "03 / 03  TASTE"
        }
    }

    private var brewProfileProgressFraction: Double {
        switch brewProfileStep {
        case .experience:
            return 1.0 / 3.0
        case .brewer:
            return 2.0 / 3.0
        default:
            return 1.0
        }
    }

    private var brewProfileBottomControls: some View {
        HStack(spacing: 10) {
            Button {
                moveBrewProfileBack()
            } label: {
                Text(brewProfileStep == .experience ? AppLocalization.text("skip", fallback: "Skip") : AppLocalization.text("back", fallback: "Back"))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.1)
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
                moveBrewProfileForward()
            } label: {
                Text(brewProfileStep == .tasteGoal ? AppLocalization.text("finish_setup", fallback: "Finish Setup") : AppLocalization.text("continue", fallback: "Continue"))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var brewProfileBrewerName: String {
        (brewProfileBrewerChoices + filteredSearchBrewers).first { $0.id == createRecipeBrewer }?.title
            ?? brewProfileBrewerChoices.first { $0.id == storedBrewProfileBrewer }?.title
            ?? "V60"
    }

    private var brewProfileTasteName: String {
        brewProfileTasteChoices.first { $0.id == createRecipeTasteGoal }?.title
            ?? brewProfileTasteChoices.first { $0.id == storedBrewProfileTaste }?.title
            ?? AppLocalization.text("balanced", fallback: "Balanced")
    }

    private func restoreBrewProfileSelections() {
        createRecipeExperience = storedBrewProfileExperience
        createRecipeBrewer = storedBrewProfileBrewer
        createRecipeTasteGoal = storedBrewProfileTaste
        restoreSavedEquipmentSelections()
    }

    private func persistBrewProfileSelections() {
        storedBrewProfileExperience = createRecipeExperience
        storedBrewProfileBrewer = createRecipeBrewer
        storedBrewProfileTaste = createRecipeTasteGoal
        persistSavedEquipmentSelections()
        isBrewProfileComplete = true
    }

    private func restoreSavedEquipmentSelections() {
        createRecipeBrewer = storedBrewProfileBrewer
        recipeGrinder = storedEquipmentGrinder
        recipeFilterType = storedEquipmentFilter
    }

    private func persistSavedEquipmentSelections() {
        storedBrewProfileBrewer = createRecipeBrewer
        storedEquipmentGrinder = recipeGrinder.trimmingCharacters(in: .whitespacesAndNewlines)
        storedEquipmentFilter = recipeFilterType.trimmingCharacters(in: .whitespacesAndNewlines)
        recipeGrinder = storedEquipmentGrinder
        recipeFilterType = storedEquipmentFilter
    }

    private func moveBrewProfileBack() {
        switch brewProfileStep {
        case .experience:
            persistBrewProfileSelections()
        case .brewer:
            brewProfileStep = .experience
        default:
            brewProfileStep = .brewer
        }
    }

    private func moveBrewProfileForward() {
        switch brewProfileStep {
        case .experience:
            brewProfileStep = .brewer
        case .brewer:
            brewProfileStep = .tasteGoal
        default:
            persistBrewProfileSelections()
        }
    }

    private func applyRecommendedProfileForBrewProfile() {
        if let profile = recommendedProfileForCreateRecipe {
            applyGuideProfile(profile, start: true)
        } else if let profile = brewGuideProfiles.first(where: { $0.id == "balanced-filter" }) {
            applyGuideProfile(profile, start: true)
        }
    }

    private func prepareNewRecipeJourney(startsWithScan: Bool) {
        createRecipeStep = .coffeeDetails
        coffeeDetailsMode = startsWithScan ? .scan : nil
        createRecipeValidationMessage = nil
        recipeGenerationProgress = 0
        recipeGenerationStageIndex = 0
    }

    private var brewMethodCategories: [(title: String, detail: String, query: String)] {
        [
            (
                AppLocalization.text("pour_over", fallback: "Pour Over"),
                AppLocalization.text("pour_over_detail", fallback: "V60, SOLO Dripper, Kalita, Chemex, and Origami."),
                "Pour Over"
            ),
            (
                AppLocalization.text("immersion", fallback: "Immersion"),
                AppLocalization.text("immersion_detail", fallback: "French press, cupping, and steep-and-release recipes."),
                "Immersion"
            ),
            (
                AppLocalization.text("traditional", fallback: "Traditional"),
                AppLocalization.text("traditional_detail", fallback: "Arabic coffee and slow ceremonial methods."),
                "Traditional"
            ),
            (
                AppLocalization.text("cold_brew", fallback: "Cold Brew"),
                AppLocalization.text("cold_brew_detail", fallback: "Long, gentle extraction for cold service."),
                "Cold Brew"
            ),
            (
                AppLocalization.text("espresso", fallback: "Espresso"),
                AppLocalization.text("espresso_detail", fallback: "Short, concentrated recipes for espresso prep."),
                "Espresso"
            )
        ]
    }

    private func openMethodCategory(_ query: String) {
        if brewingCategories.contains(query) {
            activeCategory = query
            return
        }

        if let match = brewingCategories.first(where: { $0.localizedCaseInsensitiveContains(query) || query.localizedCaseInsensitiveContains($0) }) {
            activeCategory = match
        }
    }

    private var brewingDashboardContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            primaryBrewActionCard
            dashboardContinueSection
            dashboardSavedRecipesSection
            dashboardQuickToolsSection
            dashboardBrowseMethodsSection
        }
    }

    private var primaryBrewActionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0x2B170F))
                    .frame(width: 46, height: 46)
                    .background(accentColor)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.text("create_brew_recipe", fallback: "Create a Brew Recipe"))
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 25 : 30))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppLocalization.text("create_brew_recipe_detail", fallback: "Tell Talla about your coffee, equipment, and taste goal. We’ll build a recipe around them."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button {
                    activeDashboardDestination = .createRecipe
                } label: {
                    Label(AppLocalization.text("create_recipe", fallback: "Create Recipe"), systemImage: "plus")
                        .font(Font.custom("AvenirNext-Bold", size: 12))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .foregroundColor(Color(hex: 0x2B170F))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(accentColor)
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    activeDashboardDestination = .scanCoffeeBag
                } label: {
                    Text(AppLocalization.text("scan_coffee_bag", fallback: "Scan Coffee Bag"))
                        .font(Font.custom("AvenirNext-Bold", size: 12))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .foregroundColor(primaryTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(cardFillColor)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(accentColor.opacity(0.22), lineWidth: 1)
                        )
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var dashboardContinueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardSectionTitle(
                isBrewModeRunning || brewModeElapsedSeconds > 0
                    ? AppLocalization.text("continue_active_brew", fallback: "Continue Brew")
                    : AppLocalization.text("brew_again", fallback: "Brew Again")
            )

            let latest = brewHistoryItems.first
            Button {
                if let latest {
                    applySavedRecipe(latest, start: true)
                } else if let profile = selectedGuideProfile {
                    applyGuideProfile(profile, start: true)
                } else {
                    isFocusedBrewPresented = true
                }
            } label: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(latest?.title ?? currentBrewRecipeTitle)
                                .font(Font.custom("Georgia-Bold", size: isCompact ? 21 : 24))
                                .foregroundColor(primaryTextColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)

                            Text(dashboardBrewMetaLine(for: latest))
                                .font(Font.custom("AvenirNext-Regular", size: 13))
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.forward")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentColor)
                            .frame(width: 36, height: 36)
                            .background(accentColor.opacity(0.10))
                            .clipShape(Circle())
                            .accessibilityHidden(true)
                    }

                    HStack(spacing: 8) {
                        dashboardPill("\(formattedRatioValue(latest?.coffeeGrams ?? validCoffeeAmount)) g")
                        dashboardPill("1:\(formattedRatioValue(latest?.ratio ?? validRatioValue))")
                        dashboardPill(AppLocalization.text("last_used_recently", fallback: "Last used recently"))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(accentColor.opacity(0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var dashboardSavedRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardSectionTitle(AppLocalization.text("saved_recipes", fallback: "Saved Recipes"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if brewHistoryItems.isEmpty {
                        ForEach(brewGuideProfiles) { profile in
                            savedDashboardProfileCard(profile)
                        }
                    } else {
                        ForEach(Array(brewHistoryItems.prefix(6).enumerated()), id: \.offset) { _, recipe in
                            savedDashboardRecipeCard(recipe)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var dashboardQuickToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardSectionTitle(AppLocalization.text("quick_tools", fallback: "Quick Tools"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 138 : 168), spacing: 12)], spacing: 12) {
                quickToolButton(
                    title: AppLocalization.text("ratio_calculator", fallback: "Ratio Calculator"),
                    detail: AppLocalization.text("ratio_calculator_detail_short", fallback: "Dose and water"),
                    systemImage: "scalemass.fill",
                    destination: .ratioCalculator
                )
                quickToolButton(
                    title: AppLocalization.text("brew_timer", fallback: "Brew Timer"),
                    detail: AppLocalization.text("brew_timer_detail_short", fallback: "Guided pours"),
                    systemImage: "timer",
                    destination: .brewTimer
                )
                quickToolButton(
                    title: AppLocalization.text("coffee_journal", fallback: "Coffee Journal"),
                    detail: AppLocalization.text("coffee_journal_detail_short", fallback: "Taste notes"),
                    systemImage: "book.closed.fill",
                    destination: .coffeeJournal
                )
                quickToolButton(
                    title: AppLocalization.text("brew_coach", fallback: "Brew Coach"),
                    detail: AppLocalization.text("brew_coach_detail_short", fallback: "Tune the cup"),
                    systemImage: "brain.head.profile",
                    destination: .brewCoach
                )
            }
        }
    }

    private var dashboardBrowseMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardSectionTitle(AppLocalization.text("browse_methods", fallback: "Browse Methods"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 138 : 166), spacing: 12)], spacing: 12) {
                methodFamilyButton(title: AppLocalization.text("pour_over", fallback: "Pour Over"), systemImage: "drop.fill", keywords: ["pour", "v60", "chemex", "filter"])
                methodFamilyButton(title: AppLocalization.text("immersion", fallback: "Immersion"), systemImage: "cylinder.split.1x2.fill", keywords: ["immersion", "press", "aeropress"])
                methodFamilyButton(title: AppLocalization.text("traditional", fallback: "Traditional"), systemImage: "flame.fill", keywords: ["traditional", "arabic", "dallah"])
                methodFamilyButton(title: AppLocalization.text("cold_brew", fallback: "Cold Brew"), systemImage: "snowflake", keywords: ["cold"])
                methodFamilyButton(title: AppLocalization.text("espresso", fallback: "Espresso"), systemImage: "cup.and.saucer.fill", keywords: ["espresso"])
            }
        }
    }

    private func dashboardSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(sectionTitleFont)
            .tracking(2.2)
            .textCase(.uppercase)
            .foregroundColor(accentColor)
            .accessibilityAddTraits(.isHeader)
    }

    private func dashboardPill(_ title: String) -> some View {
        Text(title)
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .tracking(0.8)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.74)
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accentColor.opacity(0.10))
            .clipShape(Capsule(style: .continuous))
    }

    private func dashboardBrewMetaLine(for recipe: BrewRecipeRecord?) -> String {
        let method = selectedBrewModeMethod?.name ?? AppLocalization.text("filter", fallback: "Filter")
        let coffee = formattedRatioValue(recipe?.coffeeGrams ?? validCoffeeAmount)
        let ratio = formattedRatioValue(recipe?.ratio ?? validRatioValue)
        return "\(method) · \(coffee) g · 1:\(ratio)"
    }

    private func savedDashboardRecipeCard(_ recipe: BrewRecipeRecord) -> some View {
        Button {
            applySavedRecipe(recipe, start: true)
        } label: {
            savedDashboardCardContent(
                title: recipe.title,
                brewer: selectedBrewModeMethod?.name ?? AppLocalization.text("filter", fallback: "Filter"),
                dose: "\(formattedRatioValue(recipe.coffeeGrams ?? validCoffeeAmount)) g",
                ratio: "1:\(formattedRatioValue(recipe.ratio ?? validRatioValue))",
                time: formattedTimerTime(brewModeTotalSeconds),
                rating: AppLocalization.text("saved", fallback: "Saved")
            )
        }
        .buttonStyle(.plain)
    }

    private func savedDashboardProfileCard(_ profile: BrewGuideProfile) -> some View {
        Button {
            applyGuideProfile(profile, start: true)
        } label: {
            savedDashboardCardContent(
                title: profile.title,
                brewer: profile.methodKeywords.first?.capitalized ?? AppLocalization.text("filter", fallback: "Filter"),
                dose: "\(formattedRatioValue(profile.coffeeGrams)) g",
                ratio: "1:\(formattedRatioValue(profile.ratio))",
                time: profile.time,
                rating: "4.8"
            )
        }
        .buttonStyle(.plain)
    }

    private func savedDashboardCardContent(title: String, brewer: String, dose: String, ratio: String, time: String, rating: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Font.custom("Georgia-Bold", size: 18))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(brewer)
                .font(Font.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(dose) · \(ratio)")
                Text("\(time) · ★ \(rating)")
            }
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundColor(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.76)

            Spacer(minLength: 0)

            Text(AppLocalization.text("brew", fallback: "Brew"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0x2B170F))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(accentColor)
                .clipShape(Capsule(style: .continuous))
        }
        .padding(14)
        .frame(width: 178, height: 178, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func quickToolButton(title: String, detail: String, systemImage: String, destination: BrewingDashboardDestination) -> some View {
        Button {
            activeDashboardDestination = destination
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 34, height: 34)
                    .background(accentColor.opacity(0.10))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 13))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func methodFamilyButton(title: String, systemImage: String, keywords: [String]) -> some View {
        Button {
            openMethodFamily(keywords: keywords, fallbackCategory: title)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.10))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 13))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tertiaryTextColor)
                    .accessibilityHidden(true)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func openMethodFamily(keywords: [String], fallbackCategory: String) {
        let method = displayedMethods.first { method in
            let source = ([method.name, method.summary, method.detail] + method.categories)
                .joined(separator: " ")
                .lowercased()
            return keywords.contains { source.contains($0) }
        }

        if let articleURL = method?.articleURL {
            openArticleAction(articleURL)
        } else if let category = brewingCategories.first(where: { $0.localizedCaseInsensitiveContains(fallbackCategory) || fallbackCategory.localizedCaseInsensitiveContains($0) }) {
            activeCategory = category
        }
    }

    private func dashboardDestinationView(_ destination: BrewingDashboardDestination) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch destination {
                    case .createRecipe:
                        createBrewRecipeFlow(startsWithScan: false)
                    case .scanCoffeeBag:
                        createBrewRecipeFlow(startsWithScan: true)
                    case .ratioCalculator:
                        goldenRatioSection
                    case .brewTimer:
                        guidedBrewModeSection
                    case .coffeeJournal:
                        coffeeJournalSection
                    case .brewCoach:
                        if let selectedGuideProfile {
                            brewCoachCard(for: selectedGuideProfile)
                        }
                    }
                }
                .frame(maxWidth: brewColumnMaxWidth, alignment: .leading)
                .padding(.horizontal, isCompact ? 22 : 28)
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(brewBackgroundColor.ignoresSafeArea())
            .navigationTitle(destinationTitle(destination))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppLocalization.text("done", fallback: "Done")) {
                        activeDashboardDestination = nil
                    }
                    .font(Font.custom("AvenirNext-Bold", size: 13))
                    .foregroundColor(accentColor)
                }
            }
            .toolbar(.hidden, for: .tabBar)
        }
    }

    private func destinationTitle(_ destination: BrewingDashboardDestination) -> String {
        switch destination {
        case .createRecipe:
            return AppLocalization.text("create_recipe", fallback: "Create Recipe")
        case .scanCoffeeBag:
            return AppLocalization.text("scan_coffee_bag", fallback: "Scan Coffee Bag")
        case .ratioCalculator:
            return AppLocalization.text("ratio_calculator", fallback: "Ratio Calculator")
        case .brewTimer:
            return AppLocalization.text("brew_timer", fallback: "Brew Timer")
        case .coffeeJournal:
            return AppLocalization.text("coffee_journal", fallback: "Coffee Journal")
        case .brewCoach:
            return AppLocalization.text("brew_coach", fallback: "Brew Coach")
        }
    }

    private func createBrewRecipeFlow(startsWithScan: Bool) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            createRecipeProgressHeader

            createRecipeStepContent

            if let createRecipeValidationMessage, createRecipeStep != .generating {
                Text(createRecipeValidationMessage)
                    .font(.system(size: 13))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(brewAccentColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(brewAccentColor.opacity(0.22), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if createRecipeStep != .generating && createRecipeStep != .recipeDetail {
                createRecipeBottomControls
            }
        }
        .onAppear {
            if startsWithScan && coffeeDetailsMode == nil {
                prepareNewRecipeJourney(startsWithScan: true)
                coffeeDetailsMode = .scan
            } else if isBrewProfileComplete && createRecipeStep.rawValue < CreateRecipeStep.coffeeDetails.rawValue {
                prepareNewRecipeJourney(startsWithScan: false)
            }
        }
#if canImport(PhotosUI)
        .onChange(of: coffeeBagPhotoSelection) { _, selection in
            Task { await loadCoffeeBagPhoto(selection) }
        }
#endif
#if canImport(UIKit)
        .fullScreenCover(isPresented: $isCoffeeBagCameraPresented) {
            CoffeeBagCameraPicker { image in
                handleCoffeeBagImage(image)
            }
            .ignoresSafeArea()
        }
#endif
    }

    /// Keeps the recipe flow's large, conditional SwiftUI view types behind a
    /// stable runtime boundary. Without this erasure, resolving the nested
    /// generic type can exhaust the main-thread stack on device.
    private var createRecipeStepContent: AnyView {
        switch createRecipeStep {
        case .experience, .brewer, .tasteGoal, .coffeeDetails:
            AnyView(createRecipeCoffeeDetailsStep)
        case .equipment:
            AnyView(createRecipeEquipmentStep)
        case .generating:
            AnyView(recipeGenerationLoadingScreen)
        case .recipeDetail:
            AnyView(generatedRecipeDetailScreen)
        }
    }

    private var createRecipeProgressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(createRecipeJourneyProgressText)
                    .font(brewEyebrowFont)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(brewAccentColor)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(brewBorderColor)
                        Rectangle()
                            .fill(brewAccentColor)
                            .frame(width: max(12, proxy.size.width * createRecipeProgressFraction))
                    }
                }
                .frame(height: 2)
            }

            Text(AppLocalization.text("create_brew_recipe", fallback: "Create Brew Recipe"))
                .font(Font.custom("Georgia-Bold", size: isCompact ? 28 : 32))
                .foregroundColor(brewPrimaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppLocalization.text("create_recipe_focus_detail", fallback: "A calm recipe builder for your coffee, tools, and taste goal."))
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var createRecipeProgressFraction: Double {
        switch createRecipeStep {
        case .coffeeDetails:
            return 0.25
        case .equipment:
            return 0.50
        case .generating:
            return 0.75
        case .recipeDetail:
            return 1.0
        default:
            return Double(min(createRecipeStep.rawValue, 5)) / 5.0
        }
    }

    private var createRecipeJourneyProgressText: String {
        switch createRecipeStep {
        case .coffeeDetails:
            return "COFFEE INPUT"
        case .equipment:
            return "BREW SETUP"
        case .generating:
            return "GENERATION"
        case .recipeDetail:
            return "RECIPE RESULT"
        default:
            return createRecipeStep.progressText
        }
    }

    private var recipeGenerationStages: [RecipeGenerationStage] {
        [
            RecipeGenerationStage(
                id: 0,
                title: AppLocalization.text("reading_the_coffee", fallback: "Reading the coffee"),
                checks: [
                    AppLocalization.text("generation_reading_coffee_detail", fallback: "Origin · altitude · process · roast")
                ]
            ),
            RecipeGenerationStage(
                id: 1,
                title: AppLocalization.text("understanding_extraction", fallback: "Understanding the extraction"),
                checks: [
                    AppLocalization.text("generation_extraction_detail", fallback: "Density · solubility · flavour goal")
                ]
            ),
            RecipeGenerationStage(
                id: 2,
                title: AppLocalization.text("matching_equipment", fallback: "Matching your equipment"),
                checks: [
                    AppLocalization.text("generation_equipment_detail", fallback: "Brewer · filter · grinder")
                ]
            ),
            RecipeGenerationStage(
                id: 3,
                title: AppLocalization.text("building_pour_structure", fallback: "Building the pour structure"),
                checks: [
                    AppLocalization.text("generation_pour_structure_detail", fallback: "Grind · temperature · bloom · flow")
                ]
            ),
            RecipeGenerationStage(
                id: 4,
                title: AppLocalization.text("validating_recipe", fallback: "Validating the recipe"),
                checks: [
                    AppLocalization.text("generation_validation_detail", fallback: "Checking totals, timing, and practical limits")
                ]
            )
        ]
    }

    private var recipeGenerationLoadingScreen: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.text("building_your_recipe", fallback: "Building your recipe"))
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 32 : 40))
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(displayCoffeeName)
                    .font(Font.custom("AvenirNext-Bold", size: 14))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            VStack(alignment: .leading, spacing: 10) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(accentColor.opacity(0.16))
                        Capsule(style: .continuous)
                            .fill(accentColor)
                            .frame(width: proxy.size.width * recipeGenerationProgress)
                    }
                }
                .frame(height: 8)

                Text("\(Int(recipeGenerationProgress * 100))%")
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AppLocalization.text("recipe_generation_progress", fallback: "Recipe generation progress"))
            .accessibilityValue("\(Int(recipeGenerationProgress * 100)) percent")

            VStack(spacing: 12) {
                ForEach(recipeGenerationStages) { stage in
                    recipeGenerationStageRow(stage)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .task(id: recipeGenerationTaskID) {
            await runRecipeGenerationSequence()
        }
    }

    private func recipeGenerationStageRow(_ stage: RecipeGenerationStage) -> some View {
        let isComplete = stage.id < recipeGenerationStageIndex
        let isActive = stage.id == recipeGenerationStageIndex

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? accentColor : accentColor.opacity(isActive ? 0.18 : 0.08))
                    .frame(width: 34, height: 34)

                Image(systemName: isComplete ? "checkmark" : isActive ? "sparkle" : "circle")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isComplete ? Color(hex: 0x2B170F) : accentColor)
                    .symbolEffect(.pulse, value: recipeGenerationStageIndex)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(stage.title)
                    .font(Font.custom("Georgia-Bold", size: 18))
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 6)], alignment: .leading, spacing: 6) {
                    ForEach(stage.checks, id: \.self) { check in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(isComplete || isActive ? accentColor : tertiaryTextColor.opacity(0.45))
                                .frame(width: 5, height: 5)
                            Text(check)
                                .font(Font.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(isComplete || isActive ? secondaryTextColor : tertiaryTextColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.78)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(isActive ? accentColor.opacity(0.09) : cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isActive ? accentColor.opacity(0.38) : accentColor.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(stage.id <= recipeGenerationStageIndex ? 1 : 0.62)
        .animation(.easeInOut(duration: 0.28), value: recipeGenerationStageIndex)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage.title)
        .accessibilityValue(isComplete ? AppLocalization.text("complete", fallback: "Complete") : isActive ? AppLocalization.text("in_progress", fallback: "In progress") : AppLocalization.text("waiting", fallback: "Waiting"))
    }

    private var generatedRecipeDetailScreen: some View {
        VStack(alignment: .leading, spacing: 26) {
            generatedRecipeHeader
            generatedRecipePrimaryParametersSection
            generatedRecipeFactsSection
            generatedRecipePourSequenceSection
            generatedRecipeActionSection
            generatedRecipeScienceSection
            generatedRecipeNotesSection
            generatedRecipeExpectedCupSection
            generatedCoffeeHistorySection
            generatedRecipeAfterBrewSection
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private var generatedRecipeHeader: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                brewSectionLabel(AppLocalization.text("your_recipe", fallback: "Your Recipe"))
                Spacer(minLength: 0)
                recipeTextButton(AppLocalization.text("edit", fallback: "Edit")) {
                    createRecipeStep = .equipment
                }
                recipeTextButton(AppLocalization.text("save", fallback: "Save")) {
                    saveCurrentRecipe()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(generatedRecipeTitle)
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 31 : 38))
                    .foregroundColor(brewPrimaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(displayCoffeeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(generatedBrewerName) · \(generatedTasteGoalName)")
                    .font(.system(size: 14))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(generatedConfidenceLabel)
                .font(brewEyebrowFont)
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(brewAccentColor.opacity(0.34), lineWidth: 1)
                )

            Text(AppLocalization.text("first_recipe_refine_explanation", fallback: "This is the first recipe for this coffee. Rate the cup afterwards and Talla will refine the next version."))
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
    }

    private var generatedRecipePrimaryParametersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("primary_parameters", fallback: "Primary Parameters"))

            HStack(alignment: .top, spacing: 0) {
                primaryParameterColumn(
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    value: generatedGrindDescription,
                    detail: generatedGrinderSetting,
                    minusAction: { adjustGeneratedGrind(by: -1) },
                    plusAction: { adjustGeneratedGrind(by: 1) }
                )
                recipeVerticalDivider
                primaryParameterColumn(
                    title: AppLocalization.text("temperature", fallback: "Temperature"),
                    value: isClassicColdBrewRecipe ? "Room temp" : "\(generatedTemperatureC) °C",
                    detail: isClassicColdBrewRecipe ? "Filtered water" : AppLocalization.text("safe_range_92_94", fallback: "Safe range 92–94 °C"),
                    minusAction: isClassicColdBrewRecipe ? nil : { generatedTemperatureC = max(88, generatedTemperatureC - 1) },
                    plusAction: isClassicColdBrewRecipe ? nil : { generatedTemperatureC = min(98, generatedTemperatureC + 1) }
                )
                recipeVerticalDivider
                primaryParameterColumn(
                    title: AppLocalization.text("target_time", fallback: "Target time"),
                    value: generatedTargetTimeRange,
                    detail: AppLocalization.text("realistic_window", fallback: "Realistic brew window"),
                    minusAction: nil,
                    plusAction: nil
                )
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var generatedRecipeFactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("recipe_facts", fallback: "Recipe Facts"))

            VStack(spacing: 0) {
                recipeFactRow(title: AppLocalization.text("coffee_dose", fallback: "Coffee dose"), value: "\(formattedRatioValue(validCoffeeAmount)) g")
                recipeDivider
                recipeFactRow(title: AppLocalization.text("ratio", fallback: "Ratio"), value: "1:\(formattedRatioValue(validRatioValue))")
                recipeDivider
                recipeFactRow(title: isV60IcedRecipe ? "Hot brewing water" : AppLocalization.text("total_water", fallback: "Total water"), value: "\(formattedWholeGram(recipeBrewingWaterAmount)) g")
                if isV60IcedRecipe {
                    recipeDivider
                    recipeFactRow(title: "Ice in server", value: "\(formattedWholeGram(recipeIceAmount)) g")
                }
                if isClassicColdBrewRecipe {
                    recipeDivider
                    recipeFactRow(title: "Serving dilution", value: "1 part concentrate : 2 parts water or milk")
                    recipeDivider
                    recipeFactRow(title: "Ice per serving", value: "About 100 g")
                }
                recipeDivider
                recipeFactRow(title: AppLocalization.text("expected_beverage", fallback: "Expected beverage"), value: "\(formattedWholeGram(expectedBeverageAmount)) g")
                recipeDivider
                recipeFactRow(title: AppLocalization.text("agitation", fallback: "Agitation"), value: generatedAgitationLevel)
                if !isClassicColdBrewRecipe {
                    recipeDivider
                    recipeFactRow(title: AppLocalization.text("bloom_amount", fallback: "Bloom amount"), value: "\(formattedWholeGram(bloomWaterAmount)) g")
                    recipeDivider
                    recipeFactRow(title: AppLocalization.text("bloom_duration", fallback: "Bloom duration"), value: "\(bloomDurationSeconds) s")
                    recipeDivider
                    recipeFactRow(title: AppLocalization.text("number_of_pours", fallback: "Number of pours"), value: "\(recipePourCount)")
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

    private var generatedRecipePourSequenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("pour_sequence", fallback: "Pour Sequence"))

            VStack(spacing: 0) {
                if !isCompact {
                    recipePourTableHeader
                    recipeDivider
                }
                ForEach(generatedPourRows) { row in
                    generatedPourTableRow(row)
                    if row.id != generatedPourRows.last?.id {
                        recipeDivider
                    }
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

    private var generatedRecipeActionSection: some View {
        VStack(spacing: 10) {
            Button {
                activeDashboardDestination = nil
                isFocusedBrewPresented = true
            } label: {
                Text(AppLocalization.text("start_guided_brew", fallback: "Start Guided Brew"))
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                secondaryRecipeAction(title: AppLocalization.text("share", fallback: "Share")) {
                    copyGeneratedRecipeToClipboard()
                }
                secondaryRecipeAction(title: AppLocalization.text("copy", fallback: "Copy")) {
                    copyGeneratedRecipeToClipboard()
                }
                secondaryRecipeAction(title: AppLocalization.text("save_recipe", fallback: "Save Recipe")) {
                    saveCurrentRecipe()
                }
            }
        }
    }

    private var generatedRecipeScienceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("brew_science", fallback: "Brew Science"))

            VStack(spacing: 0) {
                scienceTopicCard(id: "temperature", title: AppLocalization.text("why_this_temperature", fallback: "Why this temperature"), summary: restoredTemperatureReason ?? smartRecipe.temperatureReason, more: "Recommended range: \(smartRecipe.temperatureRange). Talla considered the \(coffeeRoastLevel.lowercased()) roast, \(coffeeProcess.isEmpty ? "unknown process" : coffeeProcess.lowercased()), altitude, roast age, brew mode, and your \(generatedTasteGoalName.lowercased()) goal.")
                recipeDivider
                scienceTopicCard(id: "grind", title: AppLocalization.text("why_this_grind", fallback: "Why this grind"), summary: "\(generatedGrindDescription) at about \(smartRecipe.grindMicrons) μm matches this dose, brewer, process, and taste goal.", more: "Your \(recipeGrinder.isEmpty ? "grinder" : recipeGrinder) starting point is \(generatedGrinderSetting). Talla Dial-In will move this in small steps when a brew tastes sour, bitter, dry, fast, or slow.")
                recipeDivider
                scienceTopicCard(id: "ratio", title: AppLocalization.text("why_this_ratio", fallback: "Why this ratio"), summary: "1:\(formattedRatioValue(validRatioValue)) produces \(formattedWholeGram(validWaterAmount)) g total water from \(formattedRatioValue(validCoffeeAmount)) g coffee.", more: isV60IcedRecipe ? "For iced brewing, Talla preserves that ratio by splitting the total into \(formattedWholeGram(recipeBrewingWaterAmount)) g hot water and \(formattedWholeGram(recipeIceAmount)) g ice." : "The expected beverage is about \(formattedWholeGram(expectedBeverageAmount)) g after allowing for coffee-bed retention.")
                recipeDivider
                scienceTopicCard(id: "recipe", title: AppLocalization.text("why_this_recipe", fallback: "Why this recipe"), summary: generatedApproachNotes, more: generatedDecisionExplanation)
                recipeDivider
                scienceTopicCard(id: "process", title: AppLocalization.text("process_considerations", fallback: "Process considerations"), summary: generatedProcessConsiderationSummary, more: "The process changes bloom duration, temperature, grind, agitation, and pour style. This recipe uses a \(bloomDurationSeconds)-second bloom and \(generatedAgitationLevel.lowercased()) agitation rather than applying one generic method to every coffee.")
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var generatedRecipeExpectedCupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("expected_cup", fallback: "Expected Cup"))

            VStack(spacing: 0) {
                recipeFactRow(title: AppLocalization.text("acidity", fallback: "Acidity"), value: expectedCupAcidity)
                recipeDivider
                recipeFactRow(title: AppLocalization.text("sweetness", fallback: "Sweetness"), value: expectedCupSweetness)
                recipeDivider
                recipeFactRow(title: AppLocalization.text("body", fallback: "Body"), value: expectedCupBody)
                recipeDivider
                recipeFactRow(title: AppLocalization.text("clarity", fallback: "Clarity"), value: expectedCupClarity)
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(expectedCupFlavourExpression)
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var generatedCoffeeHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("coffee_history", fallback: "This coffee’s history"))

            VStack(alignment: .leading, spacing: 12) {
                if let calibration = activeCoffeeCalibration {
                    Label(
                        "Talla has learned from \(calibration.calibration.brewCount) previous refinement\(calibration.calibration.brewCount == 1 ? "" : "s") for this coffee.",
                        systemImage: "brain.head.profile"
                    )
                    .font(Font.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundColor(accentColor)

                    if !calibration.calibration.lastFeedback.isEmpty {
                        Text("Latest feedback: \(calibration.calibration.lastFeedback.joined(separator: ", "))")
                            .font(bodyFont)
                            .foregroundColor(secondaryTextColor)
                    }
                }

                if currentCoffeeHistory.isEmpty {
                    Text(AppLocalization.text("first_brew_history", fallback: "This is the first saved brew for this coffee. Rate it afterwards and Talla will build its calibration history here."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                } else {
                    ForEach(Array(currentCoffeeHistory.prefix(5).enumerated()), id: \.element.id) { index, recipe in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(Font.custom("AvenirNext-Bold", size: 11))
                                .foregroundColor(accentColor)
                                .frame(width: 26, height: 26)
                                .background(accentColor.opacity(0.10))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(recipe.title)
                                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                                    .foregroundColor(primaryTextColor)
                                Text(recipe.detail)
                                    .font(Font.custom("AvenirNext-Regular", size: 12))
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(brewSurfaceColor)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(brewBorderColor, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var generatedRecipeNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            recipeSectionHeading(AppLocalization.text("brew_notes", fallback: "Brew Notes"))

            Text(generatedApproachNotes)
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $generatedRecipeNotes)
                .font(.system(size: 14))
                .foregroundColor(brewPrimaryTextColor)
                .frame(minHeight: 96)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel(AppLocalization.text("notes_before_brewing", fallback: "Notes before brewing"))
        }
    }

    private var generatedRecipeAfterBrewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("after_the_brew", fallback: "After the Brew"))

            VStack(alignment: .leading, spacing: 12) {
                Text(AppLocalization.text("brewed_it", fallback: "Brewed it?"))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)

                VStack(spacing: 0) {
                    brewingLinkedRow(title: AppLocalization.text("open_brew_coach", fallback: "Open Brew Coach"), detail: AppLocalization.text("open_brew_coach_detail", fallback: "Get a small adjustment for the next cup."), value: nil) {
                        activeDashboardDestination = .brewCoach
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("rate_this_brew", fallback: "Rate this brew"), detail: AppLocalization.text("rate_this_brew_detail", fallback: "Tell Talla how the cup tasted."), value: nil) {
                        brewModeElapsedSeconds = brewModeTotalSeconds
                        isBrewModeRunning = false
                        isFocusedBrewPresented = true
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("add_tasting_notes", fallback: "Add tasting notes"), detail: AppLocalization.text("add_tasting_notes_detail", fallback: "Capture what stood out before saving."), value: nil) {
                        generatedRecipeNotes = generatedRecipeNotes.isEmpty ? AppLocalization.text("tasting_notes_prompt", fallback: "Tasting notes: ") : generatedRecipeNotes
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("save_to_journal", fallback: "Save to Journal"), detail: AppLocalization.text("save_to_journal_detail", fallback: "Store this recipe and brew notes."), value: nil) {
                        saveCurrentRecipe()
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
    }

    private func recipeTextButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)
        }
        .buttonStyle(.plain)
    }

    private func recipeIconButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(brewPrimaryTextColor)
                .frame(width: 40, height: 40)
                .background(brewSurfaceColor)
                .overlay(
                    Circle()
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func recipeSectionHeading(_ title: String) -> some View {
        Text(title)
            .font(brewEyebrowFont)
            .tracking(1.8)
            .textCase(.uppercase)
            .foregroundColor(brewAccentColor)
    }

    private var recipeDivider: some View {
        Rectangle()
            .fill(brewBorderColor)
            .frame(height: 1)
    }

    private var recipeVerticalDivider: some View {
        Rectangle()
            .fill(brewBorderColor)
            .frame(width: 1)
            .padding(.vertical, 14)
    }

    private func primaryParameterColumn(
        title: String,
        value: String,
        detail: String,
        minusAction: (() -> Void)?,
        plusAction: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(brewEyebrowFont)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(value)
                .font(.system(size: isCompact ? 19 : 22, weight: .semibold, design: .rounded))
                .foregroundColor(brewPrimaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(detail)
                .font(.system(size: 12))
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            if minusAction != nil || plusAction != nil {
                HStack(spacing: 8) {
                    parameterAdjustButton(systemImage: "minus", action: minusAction)
                    parameterAdjustButton(systemImage: "plus", action: plusAction)
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    private func parameterAdjustButton(systemImage: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(action == nil ? brewSecondaryTextColor.opacity(0.45) : brewPrimaryTextColor)
                .frame(width: 34, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityLabel(systemImage == "minus" ? AppLocalization.text("decrease", fallback: "Decrease") : AppLocalization.text("increase", fallback: "Increase"))
    }

    private func recipeFactRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(brewEyebrowFont)
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(brewPrimaryTextColor)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }

    private var recipePourTableHeader: some View {
        HStack(spacing: 10) {
            tableHeaderText(AppLocalization.text("step", fallback: "Step"), width: 160, alignment: .leading)
            tableHeaderText(AppLocalization.text("water_added", fallback: "Water added"), width: 92)
            tableHeaderText(AppLocalization.text("total_target", fallback: "Total target"), width: 92)
            tableHeaderText(AppLocalization.text("flow", fallback: "Flow"), width: 88)
            tableHeaderText(AppLocalization.text("start_time", fallback: "Start time"), width: 78)
            tableHeaderText(AppLocalization.text("duration", fallback: "Duration"), width: 78)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func tableHeaderText(_ text: String, width: CGFloat, alignment: Alignment = .trailing) -> some View {
        Text(text)
            .font(brewEyebrowFont)
            .tracking(0.7)
            .textCase(.uppercase)
            .foregroundColor(brewSecondaryTextColor)
            .frame(width: width, alignment: alignment)
    }

    private func generatedPourTableRow(_ row: GeneratedPourRow) -> some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(String(format: "%02d", row.id))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(brewAccentColor)
                            .frame(width: 28, alignment: .leading)

                        Text(row.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)

                        Spacer(minLength: 8)

                        Text(formattedTimerTime(row.startTime))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(brewAccentColor)
                    }

                    Text(row.instruction)
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        recipeTinyValue(AppLocalization.text("water", fallback: "Water"), row.waterAdded.map { "\($0) g" } ?? "—")
                        recipeTinyValue(AppLocalization.text("total", fallback: "Total"), row.cumulativeWater.map { "\($0) g" } ?? "—")
                        recipeTinyValue(AppLocalization.text("flow", fallback: "Flow"), row.flowRate)
                        recipeTinyValue(AppLocalization.text("duration", fallback: "Duration"), generatedPourDurationText(for: row))
                    }
                }
                .padding(14)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text("\(String(format: "%02d", row.id)) \(row.title)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)
                            .frame(width: 160, alignment: .leading)
                        tableValueText(row.waterAdded.map { "\($0) g" } ?? "—", width: 92)
                        tableValueText(row.cumulativeWater.map { "\($0) g" } ?? "—", width: 92)
                        tableValueText(row.flowRate, width: 88)
                        tableValueText(formattedTimerTime(row.startTime), width: 78)
                        tableValueText(generatedPourDurationText(for: row), width: 78)
                    }

                    Text(row.instruction)
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                }
                .padding(14)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func tableValueText(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundColor(brewPrimaryTextColor)
            .frame(width: width, alignment: .trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }

    private func recipeTinyValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(brewPrimaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func generatedPourDurationText(for row: GeneratedPourRow) -> String {
        guard let index = generatedPourRows.firstIndex(where: { $0.id == row.id }) else {
            return "—"
        }
        let nextStart = index + 1 < generatedPourRows.count ? generatedPourRows[index + 1].startTime : brewModeTotalSeconds
        let duration = max(nextStart - row.startTime, 0)
        return duration == 0 ? "—" : "\(duration) s"
    }

    private func secondaryRecipeAction(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.0)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .foregroundColor(brewPrimaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func adjustableRecipeValueCard(title: String, value: String, detail: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(accentColor)
                        .frame(width: 32, height: 32)
                        .background(accentColor.opacity(0.10))
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    Spacer(minLength: 0)

                    Image(systemName: "plusminus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(tertiaryTextColor)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)

                Text(value)
                    .font(Font.custom("Georgia-Bold", size: 24))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 156, alignment: .leading)
            .background(accentColor.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(AppLocalization.text("tap_to_adjust", fallback: "Tap to adjust"))
    }

    private func recipeInfoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.74)

            Text(value)
                .font(Font.custom("AvenirNext-Bold", size: 15))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func generatedPourRowView(_ row: GeneratedPourRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(row.id)")
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .foregroundColor(accentColor)
                    .monospacedDigit()
                    .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(Font.custom("Georgia-Bold", size: 17))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(row.instruction)
                        .font(Font.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(formattedTimerTime(row.startTime))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .foregroundColor(accentColor)
                    .monospacedDigit()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6)], spacing: 6) {
                recipeMiniStat(title: AppLocalization.text("water_added", fallback: "Water"), value: row.waterAdded.map { "\($0) g" } ?? "—")
                recipeMiniStat(title: AppLocalization.text("total", fallback: "Total"), value: row.cumulativeWater.map { "\($0) g" } ?? "—")
                recipeMiniStat(title: AppLocalization.text("flow", fallback: "Flow"), value: row.flowRate)
            }
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    private func recipeMiniStat(title: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(Font.custom("AvenirNext-Bold", size: 9))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)
            Text(value)
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .foregroundColor(primaryTextColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.07))
        .clipShape(Capsule(style: .continuous))
    }

    private func secondaryRecipeAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.0)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .foregroundColor(primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(accentColor.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func scienceTopicCard(id: String, title: String, summary: String, more: String) -> some View {
        let isExpanded = expandedScienceTopics.contains(id)

        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                if isExpanded {
                    expandedScienceTopics.remove(id)
                } else {
                    expandedScienceTopics.insert(id)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(brewSecondaryTextColor)
                        .accessibilityHidden(true)
                }

                Text(summary)
                    .font(.system(size: 13))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if id == "temperature" {
                    temperatureRangeIndicator
                }

                if isExpanded {
                    Text(more)
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var temperatureRangeIndicator: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(brewBorderColor)
                    .frame(height: 2)

                Rectangle()
                    .fill(brewAccentColor)
                    .frame(width: proxy.size.width * 0.34, height: 2)
                    .offset(x: proxy.size.width * 0.44)

                Circle()
                    .fill(brewAccentColor)
                    .frame(width: 8, height: 8)
                    .offset(x: max(0, min(proxy.size.width - 8, proxy.size.width * CGFloat(Double(generatedTemperatureC - 88) / 10.0))))
            }
        }
        .frame(height: 10)
        .accessibilityLabel(AppLocalization.text("temperature_range_indicator", fallback: "Temperature range indicator"))
        .accessibilityValue("\(generatedTemperatureC) °C")
    }

    private var generatedRecipeTitle: String {
        brewRecipeName.isEmpty ? selectedCreateRecipeTitle : brewRecipeName
    }

    private var generatedBrewerName: String {
        brewerChoices.first { $0.id == createRecipeBrewer }?.title ?? AppLocalization.text("filter", fallback: "Filter")
    }

    private var generatedTasteGoalName: String {
        createRecipeTasteGoalChoice?.title ?? AppLocalization.text("balanced", fallback: "Balanced")
    }

    private var generatedConfidenceLabel: String {
        if createRecipeBrewer == "other" {
            return AppLocalization.text("experimental", fallback: "Experimental")
        }

        switch createRecipeExperience {
        case "dial":
            return AppLocalization.text("personalised", fallback: "Personalised")
        case "automatic", "basics":
            return AppLocalization.text("proven_recipe", fallback: "Proven Recipe")
        default:
            return AppLocalization.text("starting_point", fallback: "Starting Point")
        }
    }

    private var generatedGrinderSetting: String {
        smartRecipe.grinderSetting
    }

    private var generatedTargetTimeRange: String {
        restoredTargetTimeRange ?? smartRecipe.targetTimeRange
    }

    private var isClassicColdBrewRecipe: Bool {
        createRecipeBrewer == "cold" || activeSmartRecipeID == "classic-cold-brew"
    }

    private var isV60IcedRecipe: Bool {
        recipeBrewTemperatureMode.caseInsensitiveCompare("Iced") == .orderedSame
            || createRecipeBrewer == "v60-iced"
            || activeSmartRecipeID == "v60-iced"
    }

    private var recipeBrewingWaterAmount: Double {
        if isGeneratedRecipeActive {
            return BrewRecipeMath.waterSplit(totalWater: validWaterAmount, isIced: isV60IcedRecipe).brewingWater
        }
        guard let publishedRecipeWaterGrams,
              let publishedRecipeCoffeeGrams,
              publishedRecipeCoffeeGrams > 0 else {
            return isV60IcedRecipe ? validCoffeeAmount * 9 : validWaterAmount
        }
        return publishedRecipeWaterGrams * validCoffeeAmount / publishedRecipeCoffeeGrams
    }

    private var recipeIceAmount: Double {
        if isGeneratedRecipeActive {
            return BrewRecipeMath.waterSplit(totalWater: validWaterAmount, isIced: isV60IcedRecipe).ice
        }
        guard let publishedRecipeIceGrams,
              let publishedRecipeCoffeeGrams,
              publishedRecipeCoffeeGrams > 0 else {
            return isV60IcedRecipe ? validCoffeeAmount * 6 : 0
        }
        return publishedRecipeIceGrams * validCoffeeAmount / publishedRecipeCoffeeGrams
    }

    private var expectedBeverageAmount: Double {
        if isV60IcedRecipe {
            return validWaterAmount
        }
        return max(validWaterAmount - (validCoffeeAmount * 2.1), 1)
    }

    private var bloomWaterAmount: Double {
        smartRecipe.bloomWaterGrams
    }

    private var smartBloomMultiplier: Double {
        BrewRecipeMath.suggestedBloomMultiplier(
            roast: coffeeRoastLevel,
            process: coffeeProcess,
            tasteGoal: createRecipeTasteGoal
        )
    }

    private var bloomDurationSeconds: Int {
        smartRecipe.bloomDurationSeconds
    }

    private var generatedAgitationLevel: String {
        smartRecipe.agitation
    }

    private var generatedPourRows: [GeneratedPourRow] {
        (restoredRecipeSteps ?? smartRecipe.steps).map {
            let instruction = restoredRecipeSteps == nil
                ? $0.instruction.replacingOccurrences(of: "\(smartRecipe.temperatureC) °C", with: "\(generatedTemperatureC) °C")
                : $0.instruction
            return GeneratedPourRow(id: $0.id, title: $0.title, waterAdded: $0.waterAdded, cumulativeWater: $0.cumulativeWater, startTime: $0.startTime, flowRate: $0.flowRate, instruction: instruction)
        }
    }

    private var smartRecipe: SmartBrewRecipe {
        let altitude = Int(coffeeAltitude.filter { $0.isNumber })
        let days = max(Calendar.current.dateComponents([.day], from: coffeeRoastDate, to: Date()).day ?? 0, 0)
        return SmartBrewRecipeEngine.generate(
            SmartBrewInput(
                coffeeGrams: validCoffeeAmount,
                ratio: validRatioValue,
                brewerID: createRecipeBrewer,
                brewMode: recipeBrewTemperatureMode,
                roast: coffeeRoastLevel,
                process: coffeeProcess,
                tasteGoal: createRecipeTasteGoal,
                altitudeMeters: altitude,
                daysOffRoast: days,
                grinder: recipeGrinder,
                bloomPreference: recipeBloomRatio,
                requestedPourCount: recipePourCount,
                controlMode: recipeBrewControlMode,
                calibration: activeCoffeeCalibration?.calibration
            )
        )
    }

    private var coffeeCalibrationRecords: [CoffeeCalibrationRecord] {
        guard let data = storedCoffeeCalibrations.data(using: .utf8),
              let records = try? JSONDecoder().decode([CoffeeCalibrationRecord].self, from: data) else {
            return []
        }
        return records
    }

    private var currentCoffeeIdentity: String {
        normalizedCoffeeIdentity(coffeeName)
    }

    private func normalizedCoffeeIdentity(_ value: String) -> String {
        var parts = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().split(separator: " ").map(String.init)
        if let last = parts.last, last.first == "v", last.dropFirst().allSatisfy(\.isNumber) {
            parts.removeLast()
        }
        return parts.joined(separator: " ").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private var currentCoffeeHistory: [BrewRecipeRecord] {
        let identity = currentCoffeeIdentity
        guard !identity.isEmpty else { return [] }
        return brewHistoryItems.filter { normalizedCoffeeIdentity($0.title) == identity }
    }

    private var activeCoffeeCalibration: CoffeeCalibrationRecord? {
        guard !coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return coffeeCalibrationRecords.first { $0.id == currentCoffeeIdentity }
    }

    private func persistCoffeeCalibrations(_ records: [CoffeeCalibrationRecord]) {
        guard let data = try? JSONEncoder().encode(Array(records.prefix(50))),
              let payload = String(data: data, encoding: .utf8) else { return }
        storedCoffeeCalibrations = payload
    }

    private func rememberTallaDialInCalibration(from changes: [RecipeRevisionChange]) {
        guard !coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var records = coffeeCalibrationRecords
        let identity = currentCoffeeIdentity
        let existing = records.first(where: { $0.id == identity })?.calibration
        var calibration = existing ?? SmartBrewCalibration(grindMicronOffset: 0, temperatureOffset: 0, pourCountOffset: 0, preferredAgitation: nil, brewCount: 0, lastFeedback: [])

        if let grind = changes.first(where: { $0.id == "grind" }) {
            let order = ["Fine", "Medium-fine", "Medium", "Medium-coarse", "Coarse"]
            let before = order.firstIndex(of: grind.before) ?? 2
            let after = order.firstIndex(of: grind.after) ?? before
            calibration.grindMicronOffset = min(max(calibration.grindMicronOffset + ((after - before) * 35), -140), 140)
        }
        if let temperature = changes.first(where: { $0.id == "temperature" }) {
            let before = Int(temperature.before.filter(\.isNumber)) ?? generatedTemperatureC
            let after = Int(temperature.after.filter(\.isNumber)) ?? before
            calibration.temperatureOffset = min(max(calibration.temperatureOffset + after - before, -4), 4)
        }
        if changes.contains(where: { $0.id == "time" }) {
            calibration.pourCountOffset = min(calibration.pourCountOffset + 1, 2)
        }
        if let agitation = changes.first(where: { $0.id == "agitation" }) {
            calibration.preferredAgitation = agitation.after
        }
        calibration.brewCount += 1
        calibration.lastFeedback = Array((afterBrewSelections.sorted() + afterBrewMoreOfSelections.sorted()).prefix(8))

        let record = CoffeeCalibrationRecord(
            id: identity,
            coffeeName: coffeeName.trimmingCharacters(in: .whitespacesAndNewlines),
            roaster: coffeeRoaster.trimmingCharacters(in: .whitespacesAndNewlines),
            calibration: calibration,
            updatedAt: Date()
        )
        records.removeAll { $0.id == identity }
        persistCoffeeCalibrations([record] + records.sorted { $0.updatedAt > $1.updatedAt })
    }

    private func generatedPourStartTime(for index: Int) -> Int {
        switch index {
        case 1: return 10 + bloomDurationSeconds
        case 2: return 75
        case 3: return 110
        default: return 145
        }
    }

    private var expectedCupSweetness: String {
        createRecipeTasteGoal == "sweet" ? AppLocalization.text("high", fallback: "High") : AppLocalization.text("medium_high", fallback: "Medium-high")
    }

    private var expectedCupAcidity: String {
        createRecipeTasteGoal == "bright" ? AppLocalization.text("lively", fallback: "Lively") : AppLocalization.text("balanced", fallback: "Balanced")
    }

    private var expectedCupBody: String {
        createRecipeTasteGoal == "rich" ? AppLocalization.text("full", fallback: "Full") : AppLocalization.text("silky", fallback: "Silky")
    }

    private var expectedCupClarity: String {
        createRecipeTasteGoal == "bright" ? AppLocalization.text("very_clear", fallback: "Very clear") : AppLocalization.text("clean", fallback: "Clean")
    }

    private var expectedCupFlavourExpression: String {
        if let restoredExpectedCup { return restoredExpectedCup }
        let notes = coffeeTastingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            return "\(smartRecipe.expectedCup) Look for \(notes)."
        }
        return smartRecipe.expectedCup
    }

    private func cycleGeneratedGrind() {
        let options = ["Medium-fine", "Medium", "Medium-coarse"]
        guard let index = options.firstIndex(of: generatedGrindDescription) else {
            generatedGrindDescription = options[0]
            return
        }
        generatedGrindDescription = options[(index + 1) % options.count]
    }

    private func adjustGeneratedGrind(by offset: Int) {
        let options = ["Fine", "Medium-fine", "Medium", "Medium-coarse", "Coarse"]
        let currentIndex = options.firstIndex(of: generatedGrindDescription) ?? 1
        let nextIndex = max(0, min(options.count - 1, currentIndex + offset))
        generatedGrindDescription = options[nextIndex]
    }

    private var generatedProcessConsiderationSummary: String {
        if let restoredApproach { return restoredApproach }
        return smartRecipe.approach
    }

    private var generatedApproachNotes: String {
        if let restoredApproach { return restoredApproach }
        let notes = coffeeTastingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        return notes.isEmpty ? smartRecipe.approach : "\(smartRecipe.approach) Look for \(notes) as the cup cools."
    }

    private var generatedDecisionExplanation: String {
        var decisions = [
            "\(generatedBrewerName) determines the pour geometry and flow pattern.",
            "\(coffeeProcess.isEmpty ? "Unknown processing" : coffeeProcess) sets a \(bloomDurationSeconds)-second bloom and \(generatedAgitationLevel.lowercased()) agitation.",
            "The \(formattedRatioValue(validCoffeeAmount)) g dose and 1:\(formattedRatioValue(validRatioValue)) ratio set every cumulative water target."
        ]
        if let calibration = activeCoffeeCalibration {
            decisions.append("Talla Dial-In applied \(calibration.calibration.brewCount) saved refinement\(calibration.calibration.brewCount == 1 ? "" : "s") from earlier brews of this coffee.")
        }
        return decisions.joined(separator: " ")
    }

    private func copyGeneratedRecipeToClipboard() {
        let text = generatedRecipeCopyText
#if canImport(UIKit)
        UIPasteboard.general.string = text
#endif
        createRecipeValidationMessage = AppLocalization.text("recipe_copied_friendly", fallback: "Recipe copied. You can paste it wherever you keep brew notes.")
    }

    private var generatedRecipeCopyText: String {
        let rows = generatedPourRows.map { row in
            let water = row.cumulativeWater.map { "\($0) g total" } ?? "no brew water"
            return "\(row.id). \(row.title) — \(water) — \(formattedTimerTime(row.startTime))"
        }.joined(separator: "\n")
        let temperature = isClassicColdBrewRecipe ? "Room temperature" : "\(generatedTemperatureC) °C"
        let waterAndIce = isV60IcedRecipe
            ? "Hot water: \(formattedWholeGram(recipeBrewingWaterAmount)) g\nIce in server: \(formattedWholeGram(recipeIceAmount)) g"
            : "Water: \(formattedWholeGram(validWaterAmount)) g"
        let serving = isClassicColdBrewRecipe
            ? "\nServe: 1 part concentrate + 2 parts water or milk over ice"
            : ""

        return """
        \(generatedRecipeTitle)
        Coffee: \(displayCoffeeName)
        Brewer: \(generatedBrewerName)
        Goal: \(generatedTasteGoalName)
        Dose: \(formattedRatioValue(validCoffeeAmount)) g
        Ratio: 1:\(formattedRatioValue(validRatioValue))
        \(waterAndIce)
        Grind: \(generatedGrindDescription)
        Temperature: \(temperature)
        Time: \(generatedTargetTimeRange)\(serving)

        \(rows)
        """
    }

    private var displayCoffeeName: String {
        let trimmed = coffeeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? selectedCreateRecipeTitle : trimmed
    }

    private var currentRecipeRecord: BrewRecipeRecord {
        BrewRecipeRecord(
            id: generatedRecipeID,
            title: generatedRecipeTitle,
            detail: generatedRecipeSubtitle,
            coffeeGrams: validCoffeeAmount,
            ratio: validRatioValue,
            totalWaterGrams: validWaterAmount,
            brewingWaterGrams: recipeBrewingWaterAmount,
            iceGrams: recipeIceAmount > 0 ? recipeIceAmount : nil,
            methodID: selectedBrewModeMethodID,
            brewerID: createRecipeBrewer,
            brewMode: recipeBrewTemperatureMode,
            bloomRatio: recipeBloomRatio,
            pourCount: recipePourCount,
            grind: generatedGrindDescription,
            temperatureC: generatedTemperatureC,
            controlMode: recipeBrewControlMode,
            process: coffeeProcess,
            roast: coffeeRoastLevel,
            grinder: recipeGrinder,
            filter: recipeFilterType,
            altitudeMeters: Int(coffeeAltitude.filter { $0.isNumber }),
            tastingNotes: coffeeTastingNotes,
            targetTimeRange: generatedTargetTimeRange,
            temperatureReason: restoredTemperatureReason ?? smartRecipe.temperatureReason,
            expectedCup: expectedCupFlavourExpression,
            approach: generatedApproachNotes,
            steps: generatedPourRows.map {
                SmartBrewStep(id: $0.id, title: $0.title, waterAdded: $0.waterAdded, cumulativeWater: $0.cumulativeWater, startTime: $0.startTime, flowRate: $0.flowRate, instruction: $0.instruction)
            }
        )
    }

    private func saveCurrentRecipe() {
        saveRecipeAction(currentRecipeRecord)
    }

    private var generatedRecipeSubtitle: String {
        let brewer = brewerChoices.first { $0.id == createRecipeBrewer }?.title ?? AppLocalization.text("filter", fallback: "Filter")
        return "\(brewer) · \(recipeBrewTemperatureMode) · \(recipeBrewControlMode)"
    }

    private var createRecipeCoffeeDetailsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            createRecipeStepTitle(AppLocalization.text("coffee_input_title", fallback: "Tell us about the coffee"))

            VStack(spacing: 0) {
                coffeeDetailsModeButton(.scan, title: AppLocalization.text("scan_coffee_bag", fallback: "Scan Coffee Bag"), detail: AppLocalization.text("scan_bag_detail", fallback: "Use camera or photo library, then review every detail."))
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

    private var createRecipeEquipmentStep: some View {
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

    private func createRecipeQuestionStep(question: String, choices: [BrewChoice], selection: Binding<String>) -> some View {
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

    private var recipeTasteGoalSelection: Binding<String> {
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

    private var brewerSetupSelector: some View {
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

    private func createRecipeStepTitle(_ title: String) -> some View {
        Text(title)
            .font(brewQuestionFont)
            .foregroundColor(brewPrimaryTextColor)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func createRecipeChoiceCard(_ choice: BrewChoice, selection: Binding<String>) -> some View {
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

    private var brewerChoices: [BrewChoice] {
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

    private func coffeeDetailsModeButton(_ mode: CoffeeDetailsMode, title: String, detail: String) -> some View {
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

    private var scanCoffeeBagPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("scan_bag_review_title", fallback: "Scan, then review"))
                .font(brewEyebrowFont)
                .tracking(1.4)
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

    private func scanActionLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.1)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundColor(Color(hex: 0x1C1A17))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(brewAccentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var manualCoffeeDetailsFields: some View {
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

    private func createRecipeTextField(title: String, placeholder: String, text: Binding<String>) -> some View {
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

    private func catalogPicker(title: String, selection: Binding<String>, options: [String], customPlaceholder: String) -> some View {
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
                Button("Other / Custom") { selection.wrappedValue = "" }
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

    private var grinderCatalog: [String] {
        ["Fellow Ode Gen 2", "Comandante C40", "1Zpresso ZP6", "1Zpresso K-Ultra", "Timemore C3", "Timemore Sculptor", "DF64", "Mahlkönig EK43", "Microns only"]
    }

    private var filterCatalog: [String] {
        ["Hario V60 Paper", "Cafec Abaca", "Cafec T-90", "Kalita Wave 155", "Kalita Wave 185", "Chemex Bonded", "AeroPress Paper", "AeroPress Metal", "Sibarist FAST", "xBloom Omni Dripper", "Cloth filter"]
    }

    private var processCatalog: [String] {
        [
            "Washed", "Natural", "Honey", "Pulped Natural", "Wet-Hulled", "Double Fermented",
            "Anaerobic Natural", "Anaerobic Washed", "Extended Anaerobic", "Carbonic Maceration",
            "Co-Fermented", "Fruit Fermentation", "Thermal Shock", "Koji Fermented",
            "Nitrogen Infusion", "Decaf", "Experimental / Other"
        ]
    }

    private func creamGoldSegmentedControl(title: String, options: [String], selection: Binding<String>) -> some View {
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
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .foregroundColor(selection.wrappedValue == option ? Color(hex: 0x1C1A17) : brewSecondaryTextColor)
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

    private var createRecipeBottomControls: some View {
        HStack(spacing: 10) {
            Button {
                moveCreateRecipeBack()
            } label: {
                Text(AppLocalization.text("back", fallback: "Back"))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.1)
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
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private func moveCreateRecipeBack() {
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

    private func moveCreateRecipeForward() {
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

    private func buildCreatedRecipe() {
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

    private func applySmartRecipeRecommendations() {
        let recommendation = smartRecipe
        generatedGrindDescription = recommendation.grindDescription
        generatedTemperatureC = recommendation.temperatureC
    }

    @MainActor
    private func runRecipeGenerationSequence() async {
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

    private func recipeStageHaptic(isFinal: Bool) {
#if canImport(UIKit)
        if isFinal {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
#endif
    }

    private var selectedCreateRecipeTitle: String {
        let taste = createRecipeTasteGoalChoice?.title ?? AppLocalization.text("balanced", fallback: "Balanced")
        let brewer = brewerChoices.first { $0.id == createRecipeBrewer }?.title ?? AppLocalization.text("filter", fallback: "Filter")
        return "\(brewer) · \(taste)"
    }

    private var createRecipeTasteGoalChoice: BrewChoice? {
        [
            BrewChoice(id: "bright", title: AppLocalization.text("bright_clean", fallback: "Bright & clean"), detail: "", systemImage: ""),
            BrewChoice(id: "balanced", title: AppLocalization.text("balanced", fallback: "Balanced"), detail: "", systemImage: ""),
            BrewChoice(id: "sweet", title: AppLocalization.text("sweet_round", fallback: "Sweet & round"), detail: "", systemImage: ""),
            BrewChoice(id: "rich", title: AppLocalization.text("rich_full_bodied", fallback: "Rich & full-bodied"), detail: "", systemImage: "")
        ].first { $0.id == createRecipeTasteGoal }
    }

    private var recommendedProfileForCreateRecipe: BrewGuideProfile? {
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

    private var matchingMethodForCreateRecipe: ContentView.BrewingMethod? {
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
    private func loadCoffeeBagPhoto(_ item: PhotosPickerItem?) async {
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
    private func handleCoffeeBagImage(_ image: UIImage?) {
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
    private func applyCoffeeBagScanResult(_ result: CoffeeBagScanResult) {
        if let value = result.name { coffeeName = value }
        if let value = result.roaster { coffeeRoaster = value }
        if let value = result.origin { coffeeOrigin = value }
        if let value = result.region { coffeeRegion = value }
        if let value = result.altitude { coffeeAltitude = value }
        if let value = result.variety { coffeeVariety = value }
        if let value = result.process { coffeeProcess = value }
        if let value = result.tastingNotes { coffeeTastingNotes = value }
        createRecipeValidationMessage = nil
    }
#endif

    private var guidedBrewModeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocalization.text("start_guided_brew", fallback: "Start a Guided Brew"))
                        .font(sectionTitleFont)
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("guided_brew_mode_detail", fallback: "Choose a method, adjust your coffee, and follow every pour."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    if let selectedBrewModeMethod {
                        Text("\(AppLocalization.text("using", fallback: "Using")) \(selectedBrewModeMethod.name) · \(methodMetaLine(for: selectedBrewModeMethod))")
                            .font(Font.custom("AvenirNext-Bold", size: 11))
                            .foregroundColor(accentColor)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }
            }

            if !displayedMethods.isEmpty {
                Menu {
                    ForEach(displayedMethods) { method in
                        Button {
                            selectBrewModeMethod(method, start: false)
                        } label: {
                            HStack {
                                Text(method.name)
                                if selectedBrewModeMethod?.id == method.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("\(AppLocalization.text("method", fallback: "Method")): \(currentBrewRecipeTitle)")
                            .font(Font.custom("AvenirNext-Bold", size: 11))
                            .tracking(1.1)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardFillColor)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(accentColor.opacity(0.18), lineWidth: 1)
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                ratioInputField(title: AppLocalization.text("coffee_grams", fallback: "Coffee (g)"), text: $ratioCoffeeInput)
                ratioInputField(title: AppLocalization.text("ratio", fallback: "Ratio"), text: $ratioValueInput)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocalization.text("choose_your_strength", fallback: "Choose your strength"))
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                HStack(spacing: 8) {
                    strengthRatioButton(ratio: "15", title: AppLocalization.text("strong", fallback: "Strong"))
                    strengthRatioButton(ratio: "16", title: AppLocalization.text("balanced", fallback: "Balanced"))
                    strengthRatioButton(ratio: "17", title: AppLocalization.text("light", fallback: "Light"))
                }
            }

            guidedBrewSetupSummary

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    pouringProgressView
                        .frame(width: 92, height: 92)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(formattedTimerTime(brewModeElapsedSeconds))
                            .font(Font.custom("Georgia-Bold", size: isCompact ? 30 : 36))
                            .monospacedDigit()
                            .foregroundColor(primaryTextColor)
                            .contentTransition(.numericText())

                        Text(AppLocalization.text("guided_brew_live_timer", fallback: "Live brew timer"))
                            .font(Font.custom("AvenirNext-Bold", size: 10))
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundColor(accentColor)
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentBrewModeStep.title)
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 24 : 28))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .symbolEffect(.pulse, value: brewModeHapticTrigger)

                    Text(currentBrewModeStep.detail)
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(AppLocalization.text("current_target", fallback: "Current target:"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(tertiaryTextColor)

                    Text("\(formattedWholeGram(currentWaterTarget)) / \(formattedWholeGram(brewModeWaterAmount)) g")
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 24 : 28))
                        .foregroundColor(accentColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                if let nextBrewModeStep {
                    Text("\(AppLocalization.text("next", fallback: "Next")): \(nextBrewModeStep.title) \(AppLocalization.text("at", fallback: "at")) \(formattedTimerTime(nextBrewModeStep.time))")
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Label(AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."), systemImage: "cup.and.saucer.fill")
                        .font(Font.custom("AvenirNext-Bold", size: 13))
                        .foregroundColor(accentColor)
                        .symbolEffect(.bounce, value: brewModeHapticTrigger)
                }
            }

            HStack(spacing: 10) {
                Button {
                    handleBrewModePrimaryAction()
                } label: {
                    Label(
                        brewModePrimaryActionTitle,
                        systemImage: brewModePrimaryActionIcon
                    )
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    skipBrewModeStep()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(cardFillColor)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("skip_step", fallback: "Skip step"))

                Button {
                    restartBrewMode()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(cardFillColor)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("brew_again", fallback: "Brew again"))

                Button(action: saveCurrentRecipe) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(cardFillColor)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("save_recipe", fallback: "Save Recipe"))
            }

        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .sensoryFeedback(.selection, trigger: brewModeHapticTrigger)
    }

    private var smartBrewGuideSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalization.text("smart_brew_guide", fallback: "Smart Brew Guide"))
                        .font(sectionTitleFont)
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("smart_brew_guide_detail", fallback: "Pulls your saved recipes, suggests proven starting points, and explains what to adjust next."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !brewHistoryItems.isEmpty {
                savedRecipeShelf
            }

            bestRecipeShelf

            if let selectedGuideProfile {
                guideProfileDetail(selectedGuideProfile)
                brewCoachCard(for: selectedGuideProfile)
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var savedRecipeShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("your_recipes", fallback: "Your recipes"))
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(brewHistoryItems.prefix(5).enumerated()), id: \.offset) { _, recipe in
                        savedRecipeGuideButton(recipe)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var bestRecipeShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("best_recipes", fallback: "Best recipes"))
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 142 : 168), spacing: 10)], spacing: 10) {
                ForEach(brewGuideProfiles) { profile in
                    brewGuideProfileButton(profile)
                }
            }
        }
    }

    private func savedRecipeGuideButton(_ recipe: BrewRecipeRecord) -> some View {
        Button {
            applySavedRecipe(recipe, start: false)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("saved", fallback: "Saved"))
                        .font(Font.custom("AvenirNext-Bold", size: 9))
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                }

                Text(recipe.title)
                    .font(Font.custom("Georgia-Bold", size: 16))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(recipe.detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(width: 184, alignment: .leading)
            .background(accentColor.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func brewGuideProfileButton(_ profile: BrewGuideProfile) -> some View {
        let isSelected = selectedGuideProfileID == profile.id

        return Button {
            selectedGuideProfileID = profile.id
            expandedGuideProfileID = profile.id
            brewCoachAnswer = nil
            applyGuideProfile(profile, start: false)
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Image(systemName: profile.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSelected ? Color(hex: 0x0A0804) : accentColor)
                        .frame(width: 30, height: 30)
                        .background(isSelected ? Color(hex: 0x0A0804).opacity(0.08) : accentColor.opacity(0.10))
                        .clipShape(Circle())

                    Spacer(minLength: 0)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: 0x0A0804))
                    }
                }

                Text(profile.title)
                    .font(Font.custom("Georgia-Bold", size: 17))
                    .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text("\(formattedRatioValue(profile.coffeeGrams)) g · 1:\(formattedRatioValue(profile.ratio)) · \(profile.time)")
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundColor(isSelected ? Color(hex: 0x0A0804).opacity(0.75) : accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
            .background(isSelected ? accentColor : accentColor.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(isSelected ? 0 : 0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func guideProfileDetail(_ profile: BrewGuideProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.title)
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 24 : 28))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(profile.subtitle)
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button {
                    applyGuideProfile(profile, start: true)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(width: 42, height: 42)
                        .background(accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("start_guided_brew", fallback: "Start a Guided Brew"))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                guideMetric(title: AppLocalization.text("coffee_grams", fallback: "Coffee (g)"), value: "\(formattedRatioValue(profile.coffeeGrams)) g", systemImage: "scalemass.fill")
                guideMetric(title: AppLocalization.text("ratio", fallback: "Ratio"), value: "1:\(formattedRatioValue(profile.ratio))", systemImage: "drop.fill")
                guideMetric(title: AppLocalization.text("grind", fallback: "Grind"), value: profile.grind, systemImage: "circle.grid.3x3.fill")
                guideMetric(title: AppLocalization.text("temperature", fallback: "Temp"), value: profile.temperature, systemImage: "thermometer.medium")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.text("learn_why", fallback: "Learn why"))
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                ForEach(profile.learningNotes, id: \.self) { note in
                    Label(note, systemImage: "lightbulb.fill")
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedGuideProfileID == profile.id },
                    set: { expandedGuideProfileID = $0 ? profile.id : nil }
                )
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(profile.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(Font.custom("AvenirNext-Bold", size: 11))
                                .foregroundColor(Color(hex: 0x0A0804))
                                .frame(width: 24, height: 24)
                                .background(accentColor)
                                .clipShape(Circle())

                            Text(step)
                                .font(Font.custom("AvenirNext-Regular", size: 13))
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                Text(AppLocalization.text("show_brew_steps", fallback: "Show brew steps"))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
            }
        }
        .padding(14)
        .background(accentColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func guideMetric(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accentColor)
                .frame(width: 28, height: 28)
                .background(accentColor.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 9))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(value)
                    .font(Font.custom("AvenirNext-Bold", size: 13))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(cardFillColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func brewCoachCard(for profile: BrewGuideProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("ai_brew_coach", fallback: "AI Brew Coach"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("ai_brew_coach_detail", fallback: "Ask how to tune sweetness, body, acidity, grind, or timing."))
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 132 : 154), spacing: 8)], spacing: 8) {
                ForEach(brewCoachSuggestions, id: \.self) { suggestion in
                    brewCoachSuggestionButton(suggestion, profile: profile)
                }
            }

            HStack(spacing: 8) {
                TextField(AppLocalization.text("brew_coach_placeholder", fallback: "Example: make it sweeter"), text: $brewCoachQuestion)
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(primaryTextColor)
                    .submitLabel(.done)
                    .onSubmit {
                        Task { await generateBrewCoachAnswer(for: profile) }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(cardFillColor)
                    .clipShape(Capsule(style: .continuous))

                Button {
                    Task { await generateBrewCoachAnswer(for: profile) }
                } label: {
                    Image(systemName: isGeneratingBrewCoachAnswer ? "hourglass" : "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(width: 40, height: 40)
                        .background(accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isGeneratingBrewCoachAnswer)
            }

            if let brewCoachAnswer {
                Text(brewCoachAnswer)
                    .font(Font.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(14)
        .background(accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var brewCoachSuggestions: [String] {
        [
            AppLocalization.text("brew_prompt_sweeter", fallback: "Make it sweeter"),
            AppLocalization.text("brew_prompt_reduce_acidity", fallback: "Reduce acidity"),
            AppLocalization.text("brew_prompt_more_body", fallback: "More body"),
            AppLocalization.text("brew_prompt_too_fast", fallback: "Brew finished too fast"),
            AppLocalization.text("brew_prompt_too_slow", fallback: "Brew finished too slowly")
        ]
    }

    private func brewCoachSuggestionButton(_ suggestion: String, profile: BrewGuideProfile) -> some View {
        Button {
            brewCoachQuestion = suggestion
            Task { await generateBrewCoachAnswer(for: profile) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .bold))

                Text(suggestion)
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(0.7)
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(cardFillColor)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(accentColor.opacity(0.16), lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isGeneratingBrewCoachAnswer)
    }

    private var pouringProgressView: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.14), lineWidth: 9)

            Circle()
                .trim(from: 0, to: brewModeProgress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: brewModeProgress)

            Image(systemName: "drop.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accentColor)
                .offset(y: isBrewModeRunning ? -4 : 0)
                .symbolEffect(.pulse, value: brewModeHapticTrigger)
        }
        .frame(width: 64, height: 64)
    }

    private var guidedBrewSetupSummary: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                guidedBrewSetupMetric(
                    title: AppLocalization.text("water", fallback: "Water"),
                    value: "\(formattedWholeGram(validWaterAmount)) g",
                    systemImage: "drop.fill"
                )

                guidedBrewSetupMetric(
                    title: AppLocalization.text("brew_time", fallback: "Brew time"),
                    value: formattedTimerTime(brewModeTotalSeconds),
                    systemImage: "timer"
                )
            }

            if let activeSmartRecipe {
                HStack(spacing: 10) {
                    guidedBrewSetupMetric(
                        title: AppLocalization.text("grind", fallback: "Grind"),
                        value: activeSmartRecipe.grind,
                        systemImage: "circle.grid.3x3.fill"
                    )

                    guidedBrewSetupMetric(
                        title: AppLocalization.text("temperature", fallback: "Temp"),
                        value: activeSmartRecipe.temperature,
                        systemImage: "thermometer.medium"
                    )
                }
            }
        }
    }

    private func guidedBrewSetupMetric(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accentColor)
                .frame(width: 28, height: 28)
                .background(accentColor.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 9))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)

                Text(value)
                    .font(Font.custom("AvenirNext-Bold", size: 14))
                    .foregroundColor(primaryTextColor)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var focusedBrewModeView: some View {
        ZStack {
            brewBackgroundColor
            .ignoresSafeArea()

            if (brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale) && !isBrewModeRunning {
                focusedAfterBrewView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                focusedLiveBrewView
                    .transition(.opacity)
            }
        }
        .interactiveDismissDisabled(isBrewModeRunning || brewModeElapsedSeconds > 0)
        .confirmationDialog(
            AppLocalization.text("end_brew_question", fallback: "End this brew?"),
            isPresented: $isEndBrewConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppLocalization.text("end_brew", fallback: "End Brew"), role: .destructive) {
                endFocusedBrew()
            }

            Button(AppLocalization.text("cancel", fallback: "Cancel"), role: .cancel) { }
        } message: {
            Text(AppLocalization.text("end_brew_detail", fallback: "Your current timer progress will stop."))
        }
        .confirmationDialog(
            AppLocalization.text("restart_brew_question", fallback: "Restart this brew?"),
            isPresented: $isBrewRestartConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppLocalization.text("restart_brew", fallback: "Restart Brew"), role: .destructive) {
                restartBrewMode()
            }

            Button(AppLocalization.text("cancel", fallback: "Cancel"), role: .cancel) { }
        } message: {
            Text(AppLocalization.text("restart_brew_detail", fallback: "Timer and step progress will return to the beginning."))
        }
        .sensoryFeedback(.selection, trigger: brewModeHapticTrigger)
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $isScalePickerPresented) {
            floatingBluetoothScalePicker {
                isScalePickerPresented = false
            }
            .presentationBackground(.clear)
        }
    }

    private var focusedLiveBrewView: some View {
        GeometryReader { proxy in
            let usesLandscapeLayout = proxy.size.width >= 900 && proxy.size.width > proxy.size.height

            Group {
                if usesLandscapeLayout {
                    focusedLandscapeLiveBrewView
                } else {
                    focusedPortraitLiveBrewView
                }
            }
            .frame(maxWidth: usesLandscapeLayout ? 1180 : 820, maxHeight: .infinity, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, usesLandscapeLayout ? 32 : 22)
            .safeAreaPadding(.top, 10)
            .safeAreaPadding(.bottom, 14)
        }
    }

    private var focusedPortraitLiveBrewView: some View {
        VStack(alignment: .leading, spacing: 0) {
            focusedBrewTopArea

            focusedBrewTimeline
                .padding(.top, 20)

            Spacer(minLength: 22)

            if brewModeElapsedSeconds == 0 && !isBrewModeRunning {
                focusedPrepareBrewContent
                    .transition(.opacity)
            } else {
                focusedActiveBrewContent
                    .transition(.opacity)
            }

            Spacer(minLength: 22)

            focusedBrewControls
        }
    }

    private var focusedLandscapeLiveBrewView: some View {
        VStack(alignment: .leading, spacing: 0) {
            focusedBrewTopArea

            focusedBrewTimeline
                .padding(.top, 12)

            Spacer(minLength: 14)

            if brewModeElapsedSeconds == 0 && !isBrewModeRunning {
                focusedPrepareBrewContent
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            } else {
                focusedLandscapeActiveBrewContent
                    .transition(.opacity)
            }

            Spacer(minLength: 14)

            focusedBrewControls
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
        }
    }

    private var focusedLandscapeActiveBrewContent: some View {
        HStack(alignment: .top, spacing: 34) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(currentBrewPhaseName)
                        .font(brewEyebrowFont)
                        .foregroundColor(brewAccentColor)

                    Text(formattedTimerTime(brewModeElapsedSeconds))
                        .font(Font.custom("AvenirNext-DemiBold", size: 72))
                        .monospacedDigit()
                        .foregroundColor(brewPrimaryTextColor)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AppLocalization.text("elapsed_timer", fallback: "Elapsed timer"))
                .accessibilityValue("\(formattedTimerTime(brewModeElapsedSeconds)), \(currentBrewPhaseName)")

                VStack(alignment: .leading, spacing: 8) {
                    Text(primaryWaterTargetText)
                        .font(Font.custom("Georgia-Bold", size: 38))
                        .foregroundColor(brewPrimaryTextColor)
                        .monospacedDigit()
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    Text(focusedBrewGuidanceText)
                        .font(Font.custom("AvenirNext-Regular", size: 16))
                        .foregroundColor(brewSecondaryTextColor)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if scaleManager.isConnected {
                    focusedScaleLiveCard
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 14) {
                focusedBrewMetricRows
                focusedNextStepPreview
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var focusedBrewTopArea: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                requestEndFocusedBrew()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(width: 44, height: 44)
                    .background(brewSurfaceColor)
                    .overlay(
                        Circle()
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))

            VStack(alignment: .leading, spacing: 5) {
                Text(currentBrewRecipeTitle)
                    .font(Font.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundColor(brewPrimaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(displayCoffeeName)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(brewSecondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Button {
                if scaleManager.isConnected {
                    tareConnectedScale()
                } else {
                    isScalePickerPresented = true
                }
            } label: {
                VStack(spacing: 1) {
                    Image(systemName: scaleManager.isConnected ? "scalemass.fill" : "scalemass")
                        .font(.system(size: 13, weight: .semibold))

                    Text(
                        scaleManager.isConnected
                            ? AppLocalization.text("tare", fallback: "Tare")
                            : AppLocalization.text("scale", fallback: "Scale")
                    )
                    .font(Font.custom("AvenirNext-DemiBold", size: 7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                .foregroundColor(scaleManager.isConnected ? brewAccentColor : brewPrimaryTextColor)
                .frame(width: 44, height: 44)
                .background(brewSurfaceColor)
                .overlay(
                    Circle()
                        .stroke(scaleManager.isConnected ? brewAccentColor.opacity(0.65) : brewBorderColor, lineWidth: 1)
                )
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                scaleManager.isConnected
                    ? AppLocalization.text("tare_connected_scale", fallback: "Tare connected scale")
                    : AppLocalization.text("connect_bluetooth_scale", fallback: "Connect Bluetooth scale")
            )

            Text(String(format: AppLocalization.text("step_count_format", fallback: "Step %1$d of %2$d"), currentBrewModeStepIndex + 1, brewModeSteps.count))
                .font(Font.custom("AvenirNext-DemiBold", size: 11))
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Menu {
                Button {
                    isBrewRestartConfirmationPresented = true
                } label: {
                    Label(AppLocalization.text("restart", fallback: "Restart"), systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(width: 44, height: 44)
                    .background(brewSurfaceColor)
                    .overlay(
                        Circle()
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .accessibilityLabel(AppLocalization.text("more", fallback: "More"))
        }
    }

    private var focusedPrepareBrewContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(AppLocalization.text("prepare", fallback: "Prepare"))
                .font(brewEyebrowFont)
                .foregroundColor(brewAccentColor)

            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocalization.text("rinse_and_preheat", fallback: "Rinse and preheat"))
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 36 : 48))
                    .foregroundColor(brewPrimaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(AppLocalization.text("rinse_preheat_explanation", fallback: "Rinse the filter, warm the brewer, and discard the rinse water."))
                    .font(Font.custom("AvenirNext-Regular", size: 17))
                    .foregroundColor(brewSecondaryTextColor)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            focusedScaleSetupCard

            Button {
                if scaleManager.isConnected {
                    tareConnectedScale()
                }
                startBrewModeSession()
            } label: {
                Label(
                    scaleManager.isConnected
                        ? AppLocalization.text("tare_and_start", fallback: "Tare & Start")
                        : AppLocalization.text("ready", fallback: "Ready"),
                    systemImage: scaleManager.isConnected ? "arrow.counterclockwise" : "play.fill"
                )
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint(AppLocalization.text("starts_guided_brew_timer", fallback: "Starts the guided brew timer."))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var focusedActiveBrewContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(currentBrewPhaseName)
                    .font(brewEyebrowFont)
                    .foregroundColor(brewAccentColor)

                Text(formattedTimerTime(brewModeElapsedSeconds))
                    .font(Font.custom("AvenirNext-DemiBold", size: isCompact ? 74 : 104))
                    .monospacedDigit()
                    .foregroundColor(brewPrimaryTextColor)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AppLocalization.text("elapsed_timer", fallback: "Elapsed timer"))
            .accessibilityValue("\(formattedTimerTime(brewModeElapsedSeconds)), \(currentBrewPhaseName)")

            VStack(alignment: .leading, spacing: 12) {
                Text(primaryWaterTargetText)
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 38 : 52))
                    .foregroundColor(brewPrimaryTextColor)
                    .monospacedDigit()
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text(focusedBrewGuidanceText)
                    .font(Font.custom("AvenirNext-Regular", size: 17))
                    .foregroundColor(brewSecondaryTextColor)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if scaleManager.isConnected {
                focusedScaleLiveCard
            }

            focusedBrewMetricRows
            focusedNextStepPreview
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var focusedBrewMetricRows: some View {
        VStack(spacing: 0) {
            focusedMetricRow(title: AppLocalization.text("target", fallback: "Target"), value: "\(formattedWholeGram(currentWaterTarget)) g")
            focusedMetricRow(title: AppLocalization.text("added_this_step", fallback: "Added this step"), value: "\(formattedWholeGram(waterAddedThisStep)) g")
            focusedMetricRow(title: AppLocalization.text("suggested_flow", fallback: "Suggested flow"), value: currentSuggestedFlow)
            focusedMetricRow(title: AppLocalization.text("target_completion_time", fallback: "Target completion time"), value: currentTargetCompletionTime)

            if currentBrewPhaseName == AppLocalization.text("bloom", fallback: "Bloom") {
                focusedMetricRow(title: AppLocalization.text("bloom_duration", fallback: "Bloom duration"), value: focusedBloomDurationText)
            }
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(brewBorderColor)
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(brewBorderColor)
                .frame(height: 1)
        }
    }

    private var focusedScaleSetupCard: some View {
        HStack(spacing: 12) {
            Image(systemName: scaleManager.isConnected ? "checkmark.circle.fill" : "scalemass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(scaleManager.isConnected ? brewAccentColor : brewSecondaryTextColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(scaleManager.connectedScaleName ?? AppLocalization.text("bluetooth_scale", fallback: "Bluetooth Scale"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewPrimaryTextColor)

                Text(scaleManager.isConnected
                    ? AppLocalization.text("scale_connected_live", fallback: "Connected · live weight ready")
                    : AppLocalization.text("scale_connect_live", fallback: "Connect for live weight and flow"))
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(brewSecondaryTextColor)
            }

            Spacer(minLength: 8)

            if scaleManager.isConnected {
                Button(AppLocalization.text("tare", fallback: "Tare")) {
                    tareConnectedScale()
                }
                .font(Font.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(brewAccentColor)
            } else {
                Button(AppLocalization.text("connect", fallback: "Connect")) {
                    isScalePickerPresented = true
                }
                .font(Font.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(brewAccentColor)
            }
        }
        .padding(14)
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brewBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var focusedScaleLiveCard: some View {
        HStack(spacing: 0) {
            scaleLiveMetric(
                title: AppLocalization.text("live_weight", fallback: "Live weight"),
                value: String(format: "%.1f g", scaleManager.weightGrams)
            )

            Rectangle()
                .fill(brewBorderColor)
                .frame(width: 1, height: 42)

            scaleLiveMetric(
                title: AppLocalization.text("to_target", fallback: "To target"),
                value: String(format: "%.1f g", max(currentWaterTarget - scaleManager.weightGrams, 0))
            )

            Rectangle()
                .fill(brewBorderColor)
                .frame(width: 1, height: 42)

            scaleLiveMetric(
                title: AppLocalization.text("flow", fallback: "Flow"),
                value: String(format: "%.1f g/s", scaleManager.flowRateGramsPerSecond)
            )
        }
        .padding(.vertical, 12)
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brewAccentColor.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func tareConnectedScale() {
        guard scaleManager.isConnected else {
            isScalePickerPresented = true
            return
        }

        scaleManager.tare()
        brewStepHaptic(strong: false)
    }

    private func scaleLiveMetric(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 9))
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(Font.custom("AvenirNext-DemiBold", size: 15))
                .monospacedDigit()
                .foregroundColor(brewPrimaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func bluetoothScalePicker(onDone: @escaping () -> Void) -> some View {
        NavigationStack {
            ZStack {
                brewBackgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        bluetoothScalePickerHero
                        bluetoothScalePickerStatus

                        if !scaleManager.discoveredScales.isEmpty && !scaleManager.isConnected {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(AppLocalization.text("nearby_scales", fallback: "Nearby scales"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(brewPrimaryTextColor)

                                    Spacer()

                                    Button {
                                        scaleManager.scan()
                                    } label: {
                                        Label(AppLocalization.text("refresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(brewAccentColor)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(scaleManager.connectionState == .scanning)
                                }

                                ForEach(scaleManager.discoveredScales) { scale in
                                    bluetoothScaleDeviceRow(scale)
                                }
                            }
                        }

                        bluetoothScalePickerFootnote
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(AppLocalization.text("bluetooth_scale", fallback: "Bluetooth scale"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLocalization.text("done", fallback: "Done")) {
                        onDone()
                    }
                }
            }
            .tint(brewAccentColor)
            .task {
                if !scaleManager.isConnected {
                    scaleManager.scan()
                }
            }
            .onDisappear {
                scaleManager.stopScanning()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(brewBackgroundColor)
    }

    private func floatingBluetoothScalePicker(onDone: @escaping () -> Void) -> some View {
        GeometryReader { proxy in
            let panelHeight = min(max(proxy.size.height * 0.66, 560), proxy.size.height - 28)

            ZStack(alignment: .bottom) {
                Color.black.opacity(0.46)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDone()
                    }

                bluetoothScalePicker(onDone: onDone)
                    .frame(height: panelHeight)
                    .background(brewBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .stroke(Color.white.opacity(brewingColorScheme == .dark ? 0.10 : 0.58), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 10)
                    .padding(.horizontal, 14)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 8))
            }
        }
        .ignoresSafeArea()
    }

    private var bluetoothScalePickerHero: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [brewAccentColor.opacity(0.24), brewAccentColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundColor(brewAccentColor)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("brew_companion", fallback: "Brew companion"))
                        .font(brewEyebrowFont)
                        .tracking(1.8)
                        .foregroundColor(brewAccentColor)

                    Text(AppLocalization.text("live_measurements_less_guesswork", fallback: "Live measurements, less guesswork"))
                        .font(Font.custom("Georgia-Bold", size: 21))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(AppLocalization.text("scale_connect_detail", fallback: "Connect once for live weight, flow rate and quick tare throughout every guided brew."))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(brewSecondaryTextColor)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(scaleBrandLogoAssets, id: \.self) { assetName in
                    Image(assetName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(brewAccentColor)
                        .frame(maxWidth: 74, maxHeight: 18)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .padding(.horizontal, 8)
                        .background(brewAccentColor.opacity(0.085))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityLabel(scaleBrandDisplayName(forLogoAsset: assetName))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var bluetoothScalePickerStatus: some View {
        switch scaleManager.connectionState {
        case .connected(let name):
            VStack(spacing: 14) {
                scalePickerStatusCard(
                    icon: "checkmark.circle.fill",
                    title: name,
                    detail: AppLocalization.text("connected_ready_next_brew", fallback: "Connected and ready for your next brew"),
                    tint: brewAccentColor
                )

                HStack(spacing: 0) {
                    scalePickerLiveMetric(
                        label: AppLocalization.text("weight", fallback: "Weight"),
                        value: String(format: "%.1f", scaleManager.weightGrams),
                        unit: "g"
                    )

                    Rectangle()
                        .fill(brewBorderColor)
                        .frame(width: 1, height: 38)

                    scalePickerLiveMetric(
                        label: AppLocalization.text("flow_rate", fallback: "Flow rate"),
                        value: String(format: "%.1f", scaleManager.flowRateGramsPerSecond),
                        unit: "g/s"
                    )
                }
                .padding(.vertical, 12)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack(spacing: 10) {
                    Button {
                        scaleManager.tare()
                    } label: {
                        Label(AppLocalization.text("tare", fallback: "Tare"), systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, minHeight: 42)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button(role: .destructive) {
                        scaleManager.disconnect()
                    } label: {
                        Text(AppLocalization.text("disconnect", fallback: "Disconnect"))
                            .frame(maxWidth: .infinity, minHeight: 42)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red.opacity(0.82))
                    .background(Color.red.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

        case .scanning:
            scalePickerStatusCard(
                icon: "dot.radiowaves.left.and.right",
                title: AppLocalization.text("looking_for_scales", fallback: "Looking for scales"),
                detail: AppLocalization.text("keep_scale_awake", fallback: "Keep your scale awake and close to this iPhone."),
                tint: brewAccentColor,
                showsProgress: true
            )

        case .connecting(let name):
            scalePickerStatusCard(
                icon: "link",
                title: String(format: AppLocalization.text("connecting_to_format", fallback: "Connecting to %@"), name),
                detail: AppLocalization.text("connection_takes_moment", fallback: "This usually takes only a moment."),
                tint: brewAccentColor,
                showsProgress: true
            )

        case .failed(let message):
            VStack(spacing: 12) {
                scalePickerStatusCard(
                    icon: "exclamationmark.triangle.fill",
                    title: message.hasPrefix("No supported scale")
                        ? AppLocalization.text("no_scales_found", fallback: "No scales found")
                        : AppLocalization.text("connection_issue", fallback: "Connection issue"),
                    detail: message,
                    tint: Color.orange
                )
                scalePickerScanButton(title: AppLocalization.text("scan_again", fallback: "Scan again"))
            }

        case .disconnected:
            if scaleManager.discoveredScales.isEmpty {
                VStack(spacing: 12) {
                    scalePickerStatusCard(
                        icon: "power",
                        title: AppLocalization.text("scale_ready_when_you_are", fallback: "Ready when you are"),
                        detail: AppLocalization.text("scale_turn_on_detail", fallback: "Turn on your scale, then scan for nearby devices."),
                        tint: brewSecondaryTextColor
                    )
                    scalePickerScanButton(title: AppLocalization.text("scan_for_scales", fallback: "Scan for scales"))
                }
            }
        }
    }

    private func scalePickerLiveMetric(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.8)
                .foregroundColor(brewSecondaryTextColor)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(brewPrimaryTextColor)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(brewSecondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value) \(unit)")
    }

    private func scalePickerStatusCard(
        icon: String,
        title: String,
        detail: String,
        tint: Color,
        showsProgress: Bool = false
    ) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(tint.opacity(0.11))

                if showsProgress {
                    ProgressView()
                        .tint(tint)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(tint)
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)

                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(brewBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func scalePickerScanButton(title: String) -> some View {
        Button {
            scaleManager.scan()
        } label: {
            Label(title, systemImage: "arrow.clockwise")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: 0x1C1A17))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(brewAccentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func bluetoothScaleDeviceRow(_ scale: DiscoveredCoffeeScale) -> some View {
        Button {
            scaleManager.connect(to: scale.id)
        } label: {
            HStack(spacing: 13) {
                Image(scaleBrandLogoAsset(for: scale))
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(brewAccentColor)
                    .frame(width: 52, height: 22)
                    .frame(width: 68, height: 52)
                    .background(brewAccentColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(scale.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .lineLimit(1)

                    Text(scale.modelName)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(brewSecondaryTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.forward")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(brewAccentColor)
                    .frame(width: 30, height: 30)
                    .background(brewAccentColor.opacity(0.09))
                    .clipShape(Circle())
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(
            format: AppLocalization.text("connect_to_scale_accessibility_format", fallback: "Connect to %@, %@"),
            scale.name,
            scale.modelName
        ))
    }

    private var scaleBrandLogoAssets: [String] {
        [
            "ScaleLogoAcaia",
            "ScaleLogoBookoo",
            "ScaleLogoGoatStory",
            "ScaleLogoHiroia",
            "ScaleLogoMantabrew"
        ]
    }

    private func scaleBrandLogoAsset(for scale: DiscoveredCoffeeScale) -> String {
        if scale.id.hasPrefix("bookoo:") { return "ScaleLogoBookoo" }
        if scale.id.hasPrefix("gina:") { return "ScaleLogoGoatStory" }
        if scale.id.hasPrefix("hiroia:") { return "ScaleLogoHiroia" }
        if scale.id.hasPrefix("mantabrew:") { return "ScaleLogoMantabrew" }
        return "ScaleLogoAcaia"
    }

    private func scaleBrandDisplayName(forLogoAsset assetName: String) -> String {
        switch assetName {
        case "ScaleLogoBookoo": return "BOOKOO"
        case "ScaleLogoGoatStory": return "GOAT STORY"
        case "ScaleLogoHiroia": return "HIROIA"
        case "ScaleLogoMantabrew": return "MANTABREW"
        default: return "Acaia"
        }
    }

    private var bluetoothScalePickerFootnote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(brewAccentColor)
                .padding(.top, 1)

            Text(AppLocalization.text("scale_optional_detail", fallback: "A scale is optional. You can close this sheet and continue with the guided timer at any time."))
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
    }

    private func focusedMetricRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 11))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)

            Spacer(minLength: 12)

            Text(value)
                .font(Font.custom("AvenirNext-DemiBold", size: 15))
                .foregroundColor(brewPrimaryTextColor)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(brewBorderColor.opacity(0.7))
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var focusedNextStepPreview: some View {
        Group {
            if let nextBrewModeStep {
                Text(String(format: AppLocalization.text("next_step_preview_format", fallback: "Next: %@ at %@"), nextStepWaterTargetText(nextBrewModeStep), formattedTimerTime(nextBrewModeStep.time)))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(AppLocalization.text("next_complete_preview", fallback: "Next: Complete"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewSecondaryTextColor)
            }
        }
    }

    private var focusedBrewTimeline: some View {
        HStack(spacing: 8) {
            ForEach(Array(brewModeSteps.enumerated()), id: \.element.id) { index, step in
                let isComplete = index < currentBrewModeStepIndex
                let isCurrent = index == currentBrewModeStepIndex

                HStack(spacing: 8) {
                    Text(isComplete ? "✓" : "\(index + 1)")
                        .font(Font.custom("AvenirNext-DemiBold", size: 10))
                        .foregroundColor(isCurrent ? brewAccentColor : isComplete ? brewPrimaryTextColor : brewSecondaryTextColor.opacity(0.75))
                        .frame(width: 18, height: 18)

                    if index < brewModeSteps.count - 1 {
                        Rectangle()
                            .fill(isComplete ? brewAccentColor.opacity(0.75) : brewBorderColor)
                            .frame(height: isCurrent ? 2 : 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(step.title)
                .accessibilityValue(isComplete ? AppLocalization.text("complete", fallback: "Complete") : isCurrent ? AppLocalization.text("current", fallback: "Current") : AppLocalization.text("upcoming", fallback: "Upcoming"))
            }
        }
    }

    private var focusedAfterBrewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                focusedCompletionTopBar
                focusedBrewCompletionSummary

                if isAfterBrewFeedbackExpanded {
                    Text(AppLocalization.text("how_did_this_cup_taste", fallback: "How did this cup taste?"))
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 30 : 38))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    afterBrewChangeSection
                    afterBrewMoreOfSection
                    afterBrewNotesSection

                    if !recipeRevisionChanges.isEmpty {
                        afterBrewRevisionSection
                    }

                    afterBrewActions
                } else {
                    focusedCompletionActions
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    private var focusedCompletionTopBar: some View {
        HStack {
            Spacer()

            Button {
                isFocusedBrewPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(width: 44, height: 44)
                    .background(brewSurfaceColor)
                    .overlay(
                        Circle()
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
        }
    }

    private var focusedBrewCompletionSummary: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.text("brew_complete", fallback: "Brew complete"))
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 38 : 52))
                    .foregroundColor(brewPrimaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(displayCoffeeName)
                    .font(Font.custom("AvenirNext-Regular", size: 16))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                focusedMetricRow(title: AppLocalization.text("final_brew_time", fallback: "Final brew time"), value: formattedTimerTime(brewModeElapsedSeconds))
                focusedMetricRow(title: AppLocalization.text("target_range", fallback: "Target range"), value: generatedTargetTimeRange)
                focusedMetricRow(title: AppLocalization.text("difference_from_target", fallback: "Difference from target"), value: brewCompletionDifferenceText)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(brewBorderColor)
                    .frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(brewBorderColor)
                    .frame(height: 1)
            }
        }
    }

    private var focusedCompletionActions: some View {
        VStack(spacing: 10) {
            Button {
                isAfterBrewFeedbackExpanded = true
                brewStepHaptic(strong: false)
            } label: {
                Text(AppLocalization.text("refine_next_brew", fallback: "Refine Next Brew"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                isFocusedBrewPresented = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(220))
                    activeDashboardDestination = .brewCoach
                }
            } label: {
                Text(AppLocalization.text("open_brew_coach", fallback: "Open Brew Coach"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                saveAfterBrewToJournal()
            } label: {
                Text(AppLocalization.text("save_to_journal", fallback: "Save to Journal"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var afterBrewChangeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("cup_taste_prompt", fallback: "Select every note that fits. Talla will change only what needs changing."))
                .font(Font.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 142 : 164), spacing: 8)], spacing: 8) {
                ForEach(afterBrewFeedbackOptions, id: \.self) { option in
                    afterBrewChip(option, selection: $afterBrewSelections)
                }
            }
        }
    }

    private var afterBrewMoreOfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("what_would_you_like_more_of", fallback: "What would you like more of?"))
                .font(Font.custom("AvenirNext-DemiBold", size: 16))
                .foregroundColor(brewPrimaryTextColor)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 120 : 148), spacing: 8)], spacing: 8) {
                ForEach(afterBrewMoreOfOptions, id: \.self) { option in
                    afterBrewChip(option, selection: $afterBrewMoreOfSelections)
                }
            }
        }
    }

    private var afterBrewNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("tasting_notes_optional", fallback: "Tasting notes optional"))
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            TextEditor(text: $afterBrewNotes)
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(primaryTextColor)
                .frame(minHeight: 112)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.14), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityLabel(AppLocalization.text("tasting_notes", fallback: "Tasting notes"))
        }
    }

    private var afterBrewRevisionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("tallas_next_adjustment", fallback: "Talla’s next adjustment"))
                .font(Font.custom("Georgia-Bold", size: 24))
                .foregroundColor(brewPrimaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(recipeRevisionChanges) { change in
                VStack(alignment: .leading, spacing: 8) {
                    Text(change.title)
                        .font(brewEyebrowFont)
                        .foregroundColor(brewAccentColor)

                    Text("\(change.before) → \(change.after)")
                        .font(Font.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundColor(brewPrimaryTextColor)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)

                    Text(change.reason)
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(brewBorderColor.opacity(0.75))
                        .frame(height: 1)
                }
            }

            if let revisedRecipeVersionTitle {
                Text(String(format: AppLocalization.text("saved_new_recipe_version", fallback: "Saved as a new version: %@"), revisedRecipeVersionTitle))
                    .font(Font.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundColor(brewAccentColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var afterBrewActions: some View {
        VStack(spacing: 10) {
            if recipeRevisionChanges.isEmpty {
                afterBrewActionButton(
                    title: AppLocalization.text("show_next_adjustment", fallback: "Show Talla’s next adjustment"),
                    isPrimary: true
                ) {
                    prepareNextBrewAdjustment()
                }
            } else {
                afterBrewActionButton(
                    title: AppLocalization.text("save_as_version_2", fallback: "Save as Version 2"),
                    isPrimary: true
                ) {
                    saveRevisedRecipeVersion()
                }

                afterBrewActionButton(
                    title: AppLocalization.text("brew_revised_recipe", fallback: "Brew Revised Recipe"),
                    isPrimary: false
                ) {
                    brewRevisedRecipe()
                }
            }

            afterBrewActionButton(
                title: AppLocalization.text("keep_original", fallback: "Keep Original"),
                isPrimary: false
            ) {
                keepOriginalRecipe()
            }
        }
    }

    private var afterBrewFeedbackOptions: [String] {
        [
            "Bright and pleasant",
            "Too sour",
            "Balanced",
            "Sweet",
            "Too bitter",
            "Too weak",
            "Too heavy",
            "Dry or astringent",
            "Flat",
            "Brewed too quickly",
            "Brewed too slowly"
        ]
    }

    private var afterBrewMoreOfOptions: [String] {
        [
            "Sweetness",
            "Clarity",
            "Body",
            "Acidity",
            "Balance"
        ]
    }

    private func afterBrewChip(_ option: String, selection: Binding<Set<String>>) -> some View {
        let isSelected = selection.wrappedValue.contains(option)

        return Button {
            if isSelected {
                selection.wrappedValue.remove(option)
            } else {
                selection.wrappedValue.insert(option)
            }
            recipeRevisionChanges = []
            revisedRecipeVersionTitle = nil
            brewStepHaptic(strong: false)
        } label: {
            Text(option)
                .font(Font.custom("AvenirNext-DemiBold", size: 12))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundColor(isSelected ? Color(hex: 0x1C1A17) : brewPrimaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(isSelected ? brewAccentColor.opacity(0.32) : brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? brewAccentColor : brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func saveAfterBrewToJournal() {
        saveAfterBrewJournalEntryIfNeeded()
        saveCurrentRecipe()
        clearPersistedBrewSession()
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        isFocusedBrewPresented = false

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            activeDashboardDestination = .coffeeJournal
        }
    }

    private func afterBrewActionButton(title: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 14))
                .foregroundColor(isPrimary ? Color(hex: 0x1C1A17) : brewPrimaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(isPrimary ? brewAccentColor : brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isPrimary ? Color.clear : brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func prepareNextBrewAdjustment() {
        saveAfterBrewJournalEntryIfNeeded()
        recipeRevisionChanges = conservativeRecipeChanges()
        revisedRecipeVersionTitle = nil
        brewStepHaptic(strong: true)
    }

    private func improveNextBrew() {
        saveAfterBrewJournalEntryIfNeeded()

        let changes = conservativeRecipeChanges()
        recipeRevisionChanges = changes

        saveRevisedRecipeVersion()
    }

    private func saveRevisedRecipeVersion() {
        saveAfterBrewJournalEntryIfNeeded()

        if recipeRevisionChanges.isEmpty {
            recipeRevisionChanges = conservativeRecipeChanges()
        }

        let baseTitle = brewRecipeName.isEmpty ? currentBrewRecipeTitle : brewRecipeName
        let versionTitle = "\(baseTitle) v\(brewHistoryItems.count + 2)"
        revisedRecipeVersionTitle = versionTitle

        rememberTallaDialInCalibration(from: recipeRevisionChanges)
        applyRecipeRevisionChanges(recipeRevisionChanges)

        brewRecipeName = versionTitle
        saveCurrentRecipe()
        brewStepHaptic(strong: true)
    }

    private func brewRevisedRecipe() {
        saveRevisedRecipeVersion()
        brewImprovedRecipeAgain()
    }

    private func keepOriginalRecipe() {
        saveAfterBrewJournalEntryIfNeeded()
        saveCurrentRecipe()
        clearPersistedBrewSession()
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        isFocusedBrewPresented = false
    }

    private func applyRecipeRevisionChanges(_ changes: [RecipeRevisionChange]) {
        restoredRecipeSteps = nil
        restoredTargetTimeRange = nil
        restoredTemperatureReason = nil
        restoredExpectedCup = nil
        restoredApproach = nil
        if let grindChange = changes.first(where: { $0.id == "grind" }) {
            generatedGrindDescription = grindChange.after
        }

        if let temperatureChange = changes.first(where: { $0.id == "temperature" }) {
            generatedTemperatureC = Int(temperatureChange.after.filter(\.isNumber)) ?? generatedTemperatureC
        }

        if let ratioChange = changes.first(where: { $0.id == "ratio" }),
           let newRatio = ratioChange.after.split(separator: ":").last {
            ratioValueInput = String(newRatio)
        }

        if changes.contains(where: { $0.id == "time" }) {
            recipePourCount = min(recipePourCount + 1, 5)
        }
    }

    private func saveAfterBrewJournalEntryIfNeeded() {
        guard !isAfterBrewSavedToJournal else { return }
        guidedBrewCompletedAction(selectedBrewModeMethod, validCoffeeAmount, validRatioValue, validWaterAmount, brewModeElapsedSeconds)
        isAfterBrewSavedToJournal = true
    }

    private func brewImprovedRecipeAgain() {
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeBackgroundDate = nil
        restoredBrewTotalSeconds = nil
        recipeRevisionChanges = []
        revisedRecipeVersionTitle = nil
        isAfterBrewSavedToJournal = false
        startBrewModeSession()
    }

    private func resetAfterBrewFeedbackState() {
        afterBrewRating = 0
        afterBrewSelections = []
        afterBrewMoreOfSelections = []
        afterBrewNotes = ""
        recipeRevisionChanges = []
        revisedRecipeVersionTitle = nil
        isAfterBrewSavedToJournal = false
        isAfterBrewFeedbackExpanded = false
    }

    private func conservativeRecipeChanges() -> [RecipeRevisionChange] {
        if afterBrewSelections.contains("Balanced") || afterBrewSelections.contains("Sweet") || afterBrewSelections.contains("Bright and pleasant") {
            guard afterBrewMoreOfSelections.isEmpty else {
                return conservativeMoreOfChanges(currentRatio: max(validRatioValue, 1))
            }

            return [
                RecipeRevisionChange(
                    id: "same",
                    title: AppLocalization.text("recipe", fallback: "Recipe"),
                    before: AppLocalization.text("current_version", fallback: "Current version"),
                    after: AppLocalization.text("saved_unchanged", fallback: "Saved unchanged"),
                    reason: AppLocalization.text("perfect_reason", fallback: "You marked the cup as perfect, so Talla keeps the recipe intact and saves a repeatable version.")
                )
            ]
        }

        var changes: [RecipeRevisionChange] = []
        let selected = afterBrewSelections
        let moreOf = afterBrewMoreOfSelections
        let currentRatio = max(validRatioValue, 1)

        if selected.contains("Too sour") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: finerGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_sour_grind_reason", fallback: "A slightly finer grind raises extraction gently before changing several variables.")
                )
            )
            if selected.contains("Brewed too quickly") {
                changes.append(timeChange(after: "3:05–3:35", reason: AppLocalization.text("too_fast_time_reason", fallback: "The brew finished fast, so the next version aims for a little more contact time.")))
            }
            return uniqueChanges(changes)
        }

        if selected.contains("Too bitter") || selected.contains("Dry or astringent") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: coarserGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_bitter_grind_reason", fallback: "A slightly coarser grind lowers extraction without flattening the cup.")
                )
            )
            if generatedTemperatureC > 92 {
                changes.append(
                    RecipeRevisionChange(
                        id: "temperature",
                        title: AppLocalization.text("temperature", fallback: "Temperature"),
                        before: "\(generatedTemperatureC) °C",
                        after: "\(generatedTemperatureC - 1) °C",
                        reason: AppLocalization.text("too_bitter_temp_reason", fallback: "A small temperature drop softens bitterness while staying in a safe brewing range.")
                    )
                )
            }
            return uniqueChanges(changes)
        }

        if selected.contains("Too weak") {
            changes.append(
                RecipeRevisionChange(
                    id: "ratio",
                    title: AppLocalization.text("ratio", fallback: "Ratio"),
                    before: "1:\(formattedRatioValue(currentRatio))",
                    after: "1:\(formattedRatioValue(max(currentRatio - 1, 12)))",
                    reason: AppLocalization.text("too_weak_ratio_reason", fallback: "A slightly stronger ratio adds concentration without overcomplicating the brew.")
                )
            )
            return uniqueChanges(changes)
        }

        if selected.contains("Too heavy") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: coarserGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_heavy_grind_reason", fallback: "A coarser grind and gentler flow reduce weight while keeping sweetness.")
                )
            )
            changes.append(
                RecipeRevisionChange(
                    id: "agitation",
                    title: AppLocalization.text("agitation", fallback: "Agitation"),
                    before: generatedAgitationLevel,
                    after: AppLocalization.text("gentle", fallback: "Gentle"),
                    reason: AppLocalization.text("too_heavy_agitation_reason", fallback: "Lower agitation keeps fines from clogging the brew bed.")
                )
            )
            return uniqueChanges(changes)
        }

        if selected.contains("Flat") || moreOf.contains("Clarity") || moreOf.contains("Acidity") {
            changes.append(
                RecipeRevisionChange(
                    id: "temperature",
                    title: AppLocalization.text("temperature", fallback: "Temperature"),
                    before: "\(generatedTemperatureC) °C",
                    after: "\(min(generatedTemperatureC + 1, 94)) °C",
                    reason: AppLocalization.text("flat_temp_reason", fallback: "A small heat increase can lift clarity without making the recipe aggressive.")
                )
            )
            return uniqueChanges(changes)
        }

        if selected.contains("Brewed too quickly") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: finerGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_fast_grind_reason", fallback: "A slightly finer grind slows flow before changing dose or ratio.")
                )
            )
            return uniqueChanges(changes)
        }

        if selected.contains("Brewed too slowly") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: coarserGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_slow_grind_reason", fallback: "A slightly coarser grind helps the brew finish cleanly without changing the cup style.")
                )
            )
            return uniqueChanges(changes)
        }

        if moreOf.contains("Sweetness") {
            changes.append(timeChange(after: "3:05–3:35", reason: AppLocalization.text("sweeter_time_reason", fallback: "A little more contact time often brings sweetness forward. Keep the rest stable for comparison.")))
            return uniqueChanges(changes)
        }

        if moreOf.contains("Body") {
            changes.append(
                RecipeRevisionChange(
                    id: "ratio",
                    title: AppLocalization.text("ratio", fallback: "Ratio"),
                    before: "1:\(formattedRatioValue(currentRatio))",
                    after: "1:\(formattedRatioValue(max(currentRatio - 1, 12)))",
                    reason: AppLocalization.text("more_body_ratio_reason", fallback: "A modestly stronger ratio adds body while preserving the same workflow.")
                )
            )
            return uniqueChanges(changes)
        }

        if moreOf.contains("Balance") {
            changes.append(
                RecipeRevisionChange(
                    id: "time",
                    title: AppLocalization.text("target_time", fallback: "Target time"),
                    before: generatedTargetTimeRange,
                    after: "3:00–3:30",
                    reason: AppLocalization.text("more_balance_time_reason", fallback: "A tighter target keeps the next brew centred without changing grind, temperature, and ratio together.")
                )
            )
            return uniqueChanges(changes)
        }

        return [
            RecipeRevisionChange(
                id: "notes",
                title: AppLocalization.text("recipe_notes", fallback: "Recipe notes"),
                before: AppLocalization.text("first_version", fallback: "First version"),
                after: AppLocalization.text("new_version_saved", fallback: "New version saved"),
                reason: AppLocalization.text("notes_only_reason", fallback: "No flaw was selected, so Talla saves the tasting notes as the next recipe version.")
            )
        ]
    }

    private func conservativeMoreOfChanges(currentRatio: Double) -> [RecipeRevisionChange] {
        if afterBrewMoreOfSelections.contains("Sweetness") {
            return [timeChange(after: "3:05–3:35", reason: AppLocalization.text("sweeter_time_reason", fallback: "A little more contact time often brings sweetness forward. Keep the rest stable for comparison."))]
        }

        if afterBrewMoreOfSelections.contains("Clarity") || afterBrewMoreOfSelections.contains("Acidity") {
            return [
                RecipeRevisionChange(
                    id: "temperature",
                    title: AppLocalization.text("temperature", fallback: "Temperature"),
                    before: "\(generatedTemperatureC) °C",
                    after: "\(min(generatedTemperatureC + 1, 94)) °C",
                    reason: AppLocalization.text("clarity_temp_reason", fallback: "A one-degree lift can brighten the cup while keeping the rest of the recipe comparable.")
                )
            ]
        }

        if afterBrewMoreOfSelections.contains("Body") {
            return [
                RecipeRevisionChange(
                    id: "ratio",
                    title: AppLocalization.text("ratio", fallback: "Ratio"),
                    before: "1:\(formattedRatioValue(currentRatio))",
                    after: "1:\(formattedRatioValue(max(currentRatio - 1, 12)))",
                    reason: AppLocalization.text("more_body_ratio_reason", fallback: "A modestly stronger ratio adds body while preserving the same workflow.")
                )
            ]
        }

        return [
            RecipeRevisionChange(
                id: "time",
                title: AppLocalization.text("target_time", fallback: "Target time"),
                before: generatedTargetTimeRange,
                after: "3:00–3:30",
                reason: AppLocalization.text("more_balance_time_reason", fallback: "A tighter target keeps the next brew centred without changing grind, temperature, and ratio together.")
            )
        ]
    }

    private func timeChange(after: String, reason: String) -> RecipeRevisionChange {
        RecipeRevisionChange(
            id: "time",
            title: AppLocalization.text("final_target_time", fallback: "Final target time"),
            before: generatedTargetTimeRange,
            after: after,
            reason: reason
        )
    }

    private func uniqueChanges(_ changes: [RecipeRevisionChange]) -> [RecipeRevisionChange] {
        var seen = Set<String>()
        return changes.filter { change in
            guard !seen.contains(change.id) else { return false }
            seen.insert(change.id)
            return true
        }
    }

    private func finerGrind(from grind: String) -> String {
        switch grind {
        case "Medium-coarse": return "Medium"
        case "Medium": return "Medium-fine"
        case "Medium-fine": return "Fine-medium"
        default: return "Medium-fine"
        }
    }

    private func coarserGrind(from grind: String) -> String {
        switch grind {
        case "Fine-medium": return "Medium-fine"
        case "Medium-fine": return "Medium"
        case "Medium": return "Medium-coarse"
        default: return "Medium"
        }
    }

    private var focusedBrewControls: some View {
        VStack(spacing: 10) {
            focusedControlButton(
                title: brewModePauseResumeTitle,
                systemImage: isBrewModeRunning ? "pause.fill" : "play.fill",
                isPrimary: true
            ) {
                toggleBrewMode()
            }

            HStack(spacing: 8) {
                focusedControlButton(
                    title: AppLocalization.text("previous", fallback: "Previous"),
                    systemImage: "chevron.backward",
                    isPrimary: false
                ) {
                    previousBrewModeStep()
                }

                focusedControlButton(
                    title: AppLocalization.text("next", fallback: "Next"),
                    systemImage: "chevron.forward",
                    isPrimary: false
                ) {
                    skipBrewModeStep()
                }

                focusedControlButton(
                    title: AppLocalization.text("end_brew", fallback: "End Brew"),
                    systemImage: "xmark",
                    isPrimary: false
                ) {
                    requestEndFocusedBrew()
                }
            }
        }
    }

    private func focusedControlButton(title: String, systemImage: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Font.custom("AvenirNext-DemiBold", size: isPrimary ? 14 : 12))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .foregroundColor(isPrimary ? Color(hex: 0x1C1A17) : brewPrimaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: isPrimary ? 54 : 50)
                .background(isPrimary ? brewAccentColor : brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isPrimary ? Color.clear : brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var continueBrewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("continue_or_saved_recipes", fallback: "Continue Last Brew"))
                .font(sectionTitleFont)
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            if let latestBrew = brewHistoryItems.first {
                brewHistoryButton(latestBrew, isPrimary: true)
            } else {
                brewHistoryButton(currentRecipeRecord, isPrimary: true)
            }

            if brewHistoryItems.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.text("recent_brews", fallback: "Recent Brews"))
                        .font(Font.custom("AvenirNext-Bold", size: 10))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(tertiaryTextColor)

                    ForEach(Array(brewHistoryItems.dropFirst().prefix(2).enumerated()), id: \.offset) { _, item in
                        brewHistoryButton(item, isPrimary: false)
                    }
                }
            }
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var goldenRatioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("choose_your_strength", fallback: "Choose your strength"))
                .font(sectionTitleFont)
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            HStack(spacing: 8) {
                strengthRatioButton(ratio: "15", title: AppLocalization.text("strong", fallback: "Strong"))
                strengthRatioButton(ratio: "16", title: AppLocalization.text("balanced", fallback: "Balanced"))
                strengthRatioButton(ratio: "17", title: AppLocalization.text("light", fallback: "Light"))
            }

            ratioCalculatorCard
        }
        .padding(16)
        .background(cardFillColor.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        VStack(alignment: .leading, spacing: 12) {
            brewerIllustration(for: method)

            Text(method.name)
                .font(.system(size: isCompact ? 20 : 22, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(method.summary)
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(secondaryTextColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(methodMetaLine(for: method))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .foregroundColor(accentColor)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            HStack(spacing: 10) {
                Button {
                    if let articleURL = method.articleURL {
                        openArticleAction(articleURL)
                    } else {
                        restartBrewMode()
                    }
                } label: {
                    Text(AppLocalization.text("read_guide", fallback: "Read Guide"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    selectBrewModeMethod(method, start: true)
                } label: {
                    HStack(spacing: 6) {
                        Text(AppLocalization.text("brew_now", fallback: "Brew Now"))
                            .font(Font.custom("AvenirNext-Bold", size: 10))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func brewerIllustration(for method: ContentView.BrewingMethod) -> some View {
        let methodText = ([method.name] + method.categories).joined(separator: " ").lowercased()

        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.10))
                .frame(height: 86)

            brewerIcon(for: methodText)
        }
    }

    @ViewBuilder
    private func brewerIcon(for methodText: String) -> some View {
        if methodText.contains("chemex") {
            chemexIcon
        } else if methodText.contains("aeropress") || methodText.contains("aero press") {
            aeroPressIcon
        } else if methodText.contains("french") || methodText.contains("press") || methodText.contains("immersion") {
            frenchPressIcon
        } else if methodText.contains("arabic") || methodText.contains("dallah") || methodText.contains("traditional") {
            dallahIcon
        } else if methodText.contains("siphon") || methodText.contains("syphon") {
            siphonIcon
        } else if methodText.contains("cold") {
            coldBrewIcon
        } else {
            v60Icon
        }
    }

    private var v60Icon: some View {
        VStack(spacing: 0) {
            Path { path in
                path.move(to: CGPoint(x: 8, y: 0))
                path.addLine(to: CGPoint(x: 62, y: 0))
                path.addLine(to: CGPoint(x: 49, y: 38))
                path.addLine(to: CGPoint(x: 21, y: 38))
                path.closeSubpath()
            }
            .fill(accentColor)
            .frame(width: 70, height: 38)

            Capsule()
                .fill(accentColor.opacity(0.34))
                .frame(width: 56, height: 8)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_v60_cone", fallback: "V60 cone"))
    }

    private var chemexIcon: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 24, y: 0))
                path.addLine(to: CGPoint(x: 48, y: 0))
                path.addLine(to: CGPoint(x: 42, y: 22))
                path.addLine(to: CGPoint(x: 58, y: 58))
                path.addLine(to: CGPoint(x: 14, y: 58))
                path.addLine(to: CGPoint(x: 30, y: 22))
                path.closeSubpath()
            }
            .stroke(accentColor, lineWidth: 4)
            .frame(width: 72, height: 60)

            Capsule()
                .fill(accentColor)
                .frame(width: 34, height: 8)
                .offset(y: 7)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_chemex", fallback: "Chemex"))
    }

    private var aeroPressIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accentColor, lineWidth: 4)
                .frame(width: 36, height: 58)

            Capsule()
                .fill(accentColor)
                .frame(width: 54, height: 8)
                .offset(y: -34)

            Capsule()
                .fill(accentColor.opacity(0.35))
                .frame(width: 44, height: 8)
                .offset(y: 34)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_aeropress", fallback: "AeroPress"))
    }

    private var frenchPressIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(accentColor, lineWidth: 3)
                .frame(width: 42, height: 50)

            Rectangle()
                .fill(accentColor)
                .frame(width: 32, height: 3)
                .offset(y: -31)

            Capsule()
                .fill(accentColor)
                .frame(width: 5, height: 28)
                .offset(y: -19)

            Path { path in
                path.move(to: CGPoint(x: 58, y: 28))
                path.addQuadCurve(to: CGPoint(x: 58, y: 46), control: CGPoint(x: 74, y: 36))
            }
            .stroke(accentColor, lineWidth: 4)
            .frame(width: 82, height: 62)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_french_press", fallback: "French press"))
    }

    private var dallahIcon: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 34, y: 8))
                path.addQuadCurve(to: CGPoint(x: 26, y: 52), control: CGPoint(x: 15, y: 24))
                path.addQuadCurve(to: CGPoint(x: 54, y: 52), control: CGPoint(x: 40, y: 64))
                path.addQuadCurve(to: CGPoint(x: 44, y: 8), control: CGPoint(x: 64, y: 24))
                path.closeSubpath()
            }
            .fill(accentColor)
            .frame(width: 76, height: 64)

            Path { path in
                path.move(to: CGPoint(x: 49, y: 18))
                path.addQuadCurve(to: CGPoint(x: 72, y: 8), control: CGPoint(x: 66, y: 4))
                path.addQuadCurve(to: CGPoint(x: 60, y: 26), control: CGPoint(x: 72, y: 23))
            }
            .stroke(accentColor, lineWidth: 5)
            .frame(width: 84, height: 64)

            Capsule()
                .fill(accentColor)
                .frame(width: 8, height: 20)
                .offset(y: -34)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_arabic_dallah", fallback: "Arabic dallah"))
    }

    private var siphonIcon: some View {
        ZStack {
            Circle()
                .stroke(accentColor, lineWidth: 4)
                .frame(width: 34, height: 34)
                .offset(y: -18)

            Circle()
                .stroke(accentColor, lineWidth: 4)
                .frame(width: 42, height: 42)
                .offset(y: 20)

            Rectangle()
                .fill(accentColor)
                .frame(width: 5, height: 30)

            Capsule()
                .fill(accentColor.opacity(0.35))
                .frame(width: 54, height: 7)
                .offset(y: 46)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_siphon", fallback: "Siphon"))
    }

    private var coldBrewIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accentColor, lineWidth: 4)
                .frame(width: 34, height: 58)

            Capsule()
                .fill(accentColor)
                .frame(width: 22, height: 8)
                .offset(y: -34)

            Circle()
                .fill(accentColor)
                .frame(width: 7, height: 7)
                .offset(x: 28, y: -12)

            Circle()
                .fill(accentColor.opacity(0.6))
                .frame(width: 6, height: 6)
                .offset(x: 34, y: 12)

            Image(systemName: "snowflake")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accentColor)
                .offset(x: -30, y: 0)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_cold_brew_bottle", fallback: "Cold-brew bottle"))
    }

    private func methodMetaLine(for method: ContentView.BrewingMethod) -> String {
        let category = method.categories.first ?? AppLocalization.text("brewing_guide", fallback: "Brewing Guide")
        return [method.brewTime, method.difficulty, category]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
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

    private var brewGuideProfiles: [BrewGuideProfile] {
        [
            BrewGuideProfile(
                id: "balanced-filter",
                title: AppLocalization.text("balanced_filter", fallback: "Balanced Filter"),
                subtitle: AppLocalization.text("balanced_filter_detail", fallback: "A clean daily cup with sweetness first and acidity kept tidy."),
                icon: "drop.fill",
                methodKeywords: ["pour", "filter", "v60", "chemex"],
                coffeeGrams: 20,
                ratio: 16,
                grind: AppLocalization.text("medium_fine", fallback: "Medium-fine"),
                temperature: "92–94 °C",
                time: "3:30",
                targetSeconds: 210,
                goal: AppLocalization.text("sweet_clean_goal", fallback: "Sweet, clean, balanced"),
                steps: [
                    AppLocalization.text("balanced_filter_step_1", fallback: "Rinse the filter, warm the brewer, and level 20 g of coffee."),
                    AppLocalization.text("balanced_filter_step_2", fallback: "Bloom with 60 g water for 35-45 seconds."),
                    AppLocalization.text("balanced_filter_step_3", fallback: "Pour steadily to 220 g, then finish at 320 g."),
                    AppLocalization.text("balanced_filter_step_4", fallback: "Target a drawdown around 3:15-3:45 and adjust grind from there.")
                ],
                learningNotes: [
                    AppLocalization.text("filter_note_bloom", fallback: "Blooming releases gas so the main pour extracts more evenly."),
                    AppLocalization.text("filter_note_grind", fallback: "If it tastes sharp, grind a touch finer or pour slower; if heavy, grind coarser.")
                ]
            ),
            BrewGuideProfile(
                id: "v60-iced",
                title: "V60 Iced",
                subtitle: "Talla's flash-chilled V60 recipe with the ice included in the final 1:15 ratio.",
                icon: "snowflake",
                methodKeywords: ["v60 iced"],
                coffeeGrams: 20,
                ratio: 15,
                grind: "Medium",
                temperature: "93 °C",
                time: "2:15",
                targetSeconds: 135,
                goal: "Crisp, sweet, aromatic",
                steps: [
                    "Put 120 g ice in the server and add 20 g medium-ground coffee to the rinsed V60.",
                    "Bloom with 50 g hot water, then pour 70 g at 0:45.",
                    "Pour the final 60 g at 1:30 to reach 180 g hot water.",
                    "Finish near 2:15, swirl to melt the brewing ice evenly, and serve over fresh ice."
                ],
                learningNotes: [
                    "The 1:15 ratio includes both 180 g brewing water and 120 g ice.",
                    "Flash chilling preserves aroma while the stronger hot-water portion prevents a watery cup."
                ]
            ),
            BrewGuideProfile(
                id: "classic-cold-brew",
                title: "Classic Cold Brew",
                subtitle: "Talla's smooth concentrate recipe, brewed at 1:8 and served diluted over ice.",
                icon: "snowflake.circle.fill",
                methodKeywords: ["classic cold brew"],
                coffeeGrams: 60,
                ratio: 8,
                grind: "Coarse",
                temperature: "Room temperature",
                time: "12–16 hr",
                targetSeconds: 50_400,
                goal: "Velvety, sweet, low acidity",
                steps: [
                    "Combine 60 g coarse-ground coffee with 480 g filtered water.",
                    "Stir gently until every ground is wet, then cover.",
                    "Steep at room temperature for 12–16 hours and filter into a clean vessel.",
                    "Serve 1 part concentrate with 2 parts water or milk over plenty of ice."
                ],
                learningNotes: [
                    "This is a concentrate recipe at 1:8, not a ready-to-drink 1:16 brew.",
                    "For one serving, use 100 g concentrate, 200 g water or milk, and about 100 g fresh ice."
                ]
            ),
            BrewGuideProfile(
                id: "espresso-base",
                title: AppLocalization.text("espresso_base", fallback: "Espresso Base"),
                subtitle: AppLocalization.text("espresso_base_detail", fallback: "A practical starting point for milk drinks or a short, syrupy shot."),
                icon: "cup.and.saucer.fill",
                methodKeywords: ["espresso"],
                coffeeGrams: 18,
                ratio: 2,
                grind: AppLocalization.text("fine", fallback: "Fine"),
                temperature: "92–94 °C",
                time: "0:30",
                targetSeconds: 30,
                goal: AppLocalization.text("syrupy_sweet_goal", fallback: "Syrupy, sweet, focused"),
                steps: [
                    AppLocalization.text("espresso_step_1", fallback: "Dose 18 g, distribute evenly, and tamp level."),
                    AppLocalization.text("espresso_step_2", fallback: "Aim for 36 g out in 25-32 seconds."),
                    AppLocalization.text("espresso_step_3", fallback: "If sour, grind finer; if bitter and dry, grind coarser or shorten the yield."),
                    AppLocalization.text("espresso_step_4", fallback: "Taste before milk so you know what the shot is doing.")
                ],
                learningNotes: [
                    AppLocalization.text("espresso_note_ratio", fallback: "A 1:2 ratio gives you a reliable baseline before changing dose or yield."),
                    AppLocalization.text("espresso_note_time", fallback: "Time is a guide; taste decides the final adjustment.")
                ]
            ),
            BrewGuideProfile(
                id: "french-press-sweet",
                title: AppLocalization.text("sweet_press", fallback: "Sweet Press"),
                subtitle: AppLocalization.text("sweet_press_detail", fallback: "A round, easy French press recipe with less grit and more sweetness."),
                icon: "cylinder.split.1x2.fill",
                methodKeywords: ["french", "press", "immersion"],
                coffeeGrams: 24,
                ratio: 15,
                grind: AppLocalization.text("coarse", fallback: "Coarse"),
                temperature: "94 °C",
                time: "4:00",
                targetSeconds: 240,
                goal: AppLocalization.text("round_full_goal", fallback: "Round, full, sweet"),
                steps: [
                    AppLocalization.text("press_step_1", fallback: "Add 24 g coarse coffee and pour 360 g water."),
                    AppLocalization.text("press_step_2", fallback: "Stir gently after the pour and steep for 4 minutes."),
                    AppLocalization.text("press_step_3", fallback: "Break the crust, skim the foam, and press slowly."),
                    AppLocalization.text("press_step_4", fallback: "Pour everything out so the coffee stops extracting.")
                ],
                learningNotes: [
                    AppLocalization.text("press_note_body", fallback: "Immersion brewing builds body because the coffee sits with the water."),
                    AppLocalization.text("press_note_clean", fallback: "Skimming before pressing keeps the cup cleaner.")
                ]
            ),
            BrewGuideProfile(
                id: "arabic-majlis",
                title: AppLocalization.text("arabic_majlis", fallback: "Arabic Majlis"),
                subtitle: AppLocalization.text("arabic_majlis_detail", fallback: "A calm Arabic coffee guide for service, aroma, and a clean pour."),
                icon: "flame.fill",
                methodKeywords: ["arabic", "dallah", "traditional"],
                coffeeGrams: 18,
                ratio: 18,
                grind: AppLocalization.text("medium_coarse", fallback: "Medium-coarse"),
                temperature: AppLocalization.text("gentle_simmer", fallback: "Gentle simmer"),
                time: "8:00",
                targetSeconds: 480,
                goal: AppLocalization.text("aromatic_light_goal", fallback: "Aromatic, light, clean"),
                steps: [
                    AppLocalization.text("arabic_step_1", fallback: "Heat the water gently, then add coffee without boiling hard."),
                    AppLocalization.text("arabic_step_2", fallback: "Simmer low so the aroma opens without harshness."),
                    AppLocalization.text("arabic_step_3", fallback: "Add spices near the end if you use them."),
                    AppLocalization.text("arabic_step_4", fallback: "Rest briefly, then pour slowly into the dallah or cups.")
                ],
                learningNotes: [
                    AppLocalization.text("arabic_note_heat", fallback: "Gentle heat protects the lighter aromatic side of Arabic coffee."),
                    AppLocalization.text("arabic_note_rest", fallback: "Resting helps sediment settle for a cleaner service.")
                ]
            )
        ]
    }

    private var selectedGuideProfile: BrewGuideProfile? {
        brewGuideProfiles.first { $0.id == selectedGuideProfileID } ?? brewGuideProfiles.first
    }

    private var activeSmartRecipe: BrewGuideProfile? {
        guard let activeSmartRecipeID else { return nil }
        return brewGuideProfiles.first { $0.id == activeSmartRecipeID }
    }

    private var currentBrewRecipeTitle: String {
        if isGeneratedRecipeActive, !brewRecipeName.isEmpty {
            return brewRecipeName
        }
        return activeSmartRecipe?.title ?? selectedBrewModeMethod?.name ?? AppLocalization.text("custom_brew", fallback: "Custom Brew")
    }

    private func matchingMethod(for profile: BrewGuideProfile) -> ContentView.BrewingMethod? {
        displayedMethods.first { method in
            let source = ([method.name, method.summary, method.detail, method.difficulty, method.brewTime] + method.categories)
                .joined(separator: " ")
                .lowercased()
            return profile.methodKeywords.contains { source.contains($0) }
        } ?? displayedMethods.first
    }

    private func applyGuideProfile(_ profile: BrewGuideProfile, start: Bool) {
        restoredBrewTotalSeconds = nil
        ratioCoffeeInput = formattedRatioValue(profile.coffeeGrams)
        ratioValueInput = formattedRatioValue(profile.ratio)
        selectedGuideProfileID = profile.id
        activeSmartRecipeID = profile.id

        if let method = matchingMethod(for: profile) {
            usePublishedRecipe(method.publishedRecipe)
            if let coffeeGrams = method.publishedRecipe?.coffeeGrams {
                ratioCoffeeInput = formattedRatioValue(coffeeGrams)
            }
            if let ratio = method.publishedRecipe?.ratio {
                ratioValueInput = formattedRatioValue(ratio)
            }
            selectBrewModeMethod(method, start: start, usesSmartRecipe: true)
        } else if start {
            usePublishedRecipe(nil)
            restartBrewMode()
        }

        brewRecipeName = profile.title
    }

    private func applySavedRecipe(_ recipe: BrewRecipeRecord, start: Bool) {
        restoredBrewTotalSeconds = nil
        activeSmartRecipeID = nil
        generatedRecipeID = recipe.id
        isGeneratedRecipeActive = recipe.brewMode != nil || recipe.brewerID != nil
        brewRecipeName = recipe.title
        coffeeName = recipe.title
        if let coffeeGrams = recipe.coffeeGrams {
            ratioCoffeeInput = formattedRatioValue(coffeeGrams)
        }
        if let ratio = recipe.ratio {
            ratioValueInput = formattedRatioValue(ratio)
        }

        if let brewerID = recipe.brewerID { createRecipeBrewer = brewerID }
        if let brewMode = recipe.brewMode { recipeBrewTemperatureMode = brewMode }
        if let bloomRatio = recipe.bloomRatio { recipeBloomRatio = bloomRatio }
        if let pourCount = recipe.pourCount { recipePourCount = pourCount }
        if let grind = recipe.grind { generatedGrindDescription = grind }
        if let temperatureC = recipe.temperatureC { generatedTemperatureC = temperatureC }
        if let controlMode = recipe.controlMode { recipeBrewControlMode = controlMode }
        if let process = recipe.process { coffeeProcess = process }
        if let roast = recipe.roast { coffeeRoastLevel = roast }
        if let grinder = recipe.grinder { recipeGrinder = grinder }
        if let filter = recipe.filter { recipeFilterType = filter }
        if let altitude = recipe.altitudeMeters { coffeeAltitude = String(altitude) }
        if let tastingNotes = recipe.tastingNotes { coffeeTastingNotes = tastingNotes }
        restoredRecipeSteps = recipe.steps
        restoredTargetTimeRange = recipe.targetTimeRange
        restoredTemperatureReason = recipe.temperatureReason
        restoredExpectedCup = recipe.expectedCup
        restoredApproach = recipe.approach
        usePublishedRecipe(nil)

        if let method = displayedMethods.first(where: { $0.id == recipe.methodID })
            ?? displayedMethods.first(where: { recipe.title.localizedCaseInsensitiveContains($0.name) || $0.name.localizedCaseInsensitiveContains(recipe.title) }) {
            selectBrewModeMethod(method, start: start, preserveRecipeIdentity: true)
        } else if start {
            restartBrewMode()
        }
    }

    @MainActor
    private func generateBrewCoachAnswer(for profile: BrewGuideProfile) async {
        guard !isGeneratingBrewCoachAnswer else { return }
        isGeneratingBrewCoachAnswer = true
        defer { isGeneratingBrewCoachAnswer = false }

        let question = brewCoachQuestion.trimmingCharacters(in: .whitespacesAndNewlines)

#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if let aiAnswer = try? await foundationBrewCoachAnswer(profile: profile, question: question) {
                brewCoachAnswer = aiAnswer
                brewModeHapticTrigger += 1
                return
            }
        }
#endif

        brewCoachAnswer = fallbackBrewCoachAnswer(profile: profile, question: question)
        brewModeHapticTrigger += 1
    }

    private func fallbackBrewCoachAnswer(profile: BrewGuideProfile, question: String) -> String {
        let normalized = question.lowercased()
        let savedRecipeHint = brewHistoryItems.first.map { " Your latest saved recipe is \($0.title), so compare this cup against that note." } ?? ""

        if normalized.contains("sweet") || normalized.contains("حلو") {
            return "For \(profile.title), keep \(formattedRatioValue(profile.coffeeGrams)) g coffee at 1:\(formattedRatioValue(profile.ratio)), grind slightly finer, and slow the middle pour. Sweetness usually improves when extraction is even.\(savedRecipeHint)"
        }

        if normalized.contains("acid") || normalized.contains("sour") || normalized.contains("sharp") {
            return "If the cup is sharp, raise extraction: use a slightly finer grind, hotter water, or a longer contact time. Change one thing only, then save the result as a recipe."
        }

        if normalized.contains("bitter") || normalized.contains("dry") {
            return "If it tastes bitter or dry, lower extraction: grind a little coarser, pour faster, or stop the brew earlier. Keep the same dose so the change is easy to read."
        }

        if normalized.contains("body") || normalized.contains("heavy") || normalized.contains("strong") {
            return "For more body, use a stronger ratio like 1:15 and keep agitation gentle. For a cleaner cup, move back to 1:16 or 1:17 and pour softer."
        }

        if normalized.contains("fast") || normalized.contains("quick") {
            return "If \(profile.title) finished too fast, grind finer first. For filter brews, also pour a little slower and keep the water stream lower. Keep the same dose and ratio so the next cup is easy to compare."
        }

        if normalized.contains("slow") || normalized.contains("slowly") {
            return "If \(profile.title) finished too slowly, grind coarser first. For filter brews, reduce heavy agitation and avoid choking the filter. Keep the water target the same, then taste before changing ratio."
        }

        return "\(profile.title) is a good baseline for \(profile.goal.lowercased()). Start at \(formattedRatioValue(profile.coffeeGrams)) g coffee, 1:\(formattedRatioValue(profile.ratio)), \(profile.grind) grind, and \(profile.time). Taste, adjust one variable, then save the recipe.\(savedRecipeHint)"
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func foundationBrewCoachAnswer(profile: BrewGuideProfile, question: String) async throws -> String {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { throw BrewCoachError.unavailable }

        let savedRecipes = brewHistoryItems
            .prefix(5)
            .map { "- \($0.title): \($0.detail)" }
            .joined(separator: "\n")
        let savedContext = savedRecipes.isEmpty ? "No saved recipes yet." : savedRecipes

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are Talla Speciality's brew coach. Give practical coffee brewing advice only. Use the selected recipe and saved recipes as context. Keep the answer under 60 words. Do not invent medical, health, or store policy claims.
            """
        )

        let prompt = """
        Selected recipe:
        \(profile.title)
        Dose: \(formattedRatioValue(profile.coffeeGrams)) g
        Ratio: 1:\(formattedRatioValue(profile.ratio))
        Grind: \(profile.grind)
        Temperature: \(profile.temperature)
        Time: \(profile.time)
        Goal: \(profile.goal)

        Saved recipes:
        \(savedContext)

        Customer question: \(question.isEmpty ? "What should I do next to improve this brew?" : question)
        """

        let response = try await session.respond(to: prompt)
        let answer = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { throw BrewCoachError.unavailable }
        return answer
    }
#endif

    private enum BrewCoachError: Error {
        case unavailable
    }

    private var validCoffeeAmount: Double {
        ratioCoffeeAmount > 0 ? ratioCoffeeAmount : 20
    }

    private var createRecipeCoffeeAmount: Double {
        let value = Double(recipeCoffeeDose.replacingOccurrences(of: ",", with: ".")) ?? 0
        return value > 0 ? value : 20
    }

    private var createRecipeRatioValue: Double {
        let value = Double(recipePreferredRatio.replacingOccurrences(of: ",", with: ".")) ?? 0
        return value > 0 ? value : 16
    }

    private var validRatioValue: Double {
        ratioValue > 0 ? ratioValue : 16
    }

    private var validWaterAmount: Double {
        max(validCoffeeAmount * validRatioValue, 1)
    }

    private var brewModeWaterAmount: Double {
        isV60IcedRecipe ? recipeBrewingWaterAmount : validWaterAmount
    }

    private var selectedBrewModeMethod: ContentView.BrewingMethod? {
        if let selectedBrewModeMethodID,
           let method = displayedMethods.first(where: { $0.id == selectedBrewModeMethodID }) {
            return method
        }

        return displayedMethods.first
    }

    private var brewModeTotalSeconds: Int {
        if isGeneratedRecipeActive {
            return max((generatedPourRows.last?.startTime ?? 165) + 45, 1)
        }
        if let activeSmartRecipe {
            return activeSmartRecipe.targetSeconds
        }

        if let methodSeconds = selectedBrewModeMethod.flatMap({ seconds(from: $0.brewTime) }) {
            return methodSeconds
        }

        return restoredBrewTotalSeconds ?? 210
    }

    private var brewModeProgress: Double {
        min(Double(brewModeElapsedSeconds) / Double(brewModeTotalSeconds), 1)
    }

    private var currentBrewModeStepIndex: Int {
        let timedIndex = brewModeSteps.lastIndex { brewModeElapsedSeconds >= $0.time } ?? 0
        return min(max(timedIndex, scaleStepOverrideIndex ?? 0), brewModeSteps.count - 1)
    }

    private var currentBrewModeStep: BrewModeStep {
        brewModeSteps[min(currentBrewModeStepIndex, brewModeSteps.count - 1)]
    }

    private var nextBrewModeStep: BrewModeStep? {
        guard !didCompleteBrewFromScale else { return nil }
        let nextIndex = currentBrewModeStepIndex + 1
        guard brewModeElapsedSeconds < brewModeTotalSeconds, brewModeSteps.indices.contains(nextIndex) else {
            return nil
        }

        return brewModeSteps[nextIndex]
    }

    private var currentWaterTarget: Double {
        if let waterTarget = currentBrewModeStep.waterTarget {
            return waterTarget
        }

        return brewModeSteps
            .prefix(currentBrewModeStepIndex + 1)
            .compactMap(\.waterTarget)
            .last ?? 0
    }

    private var previousWaterTarget: Double {
        guard currentBrewModeStepIndex > 0 else { return 0 }
        return brewModeSteps
            .prefix(currentBrewModeStepIndex)
            .compactMap(\.waterTarget)
            .last ?? 0
    }

    private var waterAddedThisStep: Double {
        max(currentWaterTarget - previousWaterTarget, 0)
    }

    private var primaryWaterTargetText: String {
        guard currentWaterTarget > 0 else {
            return AppLocalization.text("prepare_the_brewer", fallback: "Prepare the brewer")
        }
        return "\(AppLocalization.text("pour_to", fallback: "Pour to")) \(formattedWholeGram(currentWaterTarget)) g"
    }

    private var currentSuggestedFlow: String {
        if isGeneratedRecipeActive,
           let row = generatedPourRows.first(where: { $0.id == currentBrewModeStep.id }) {
            return row.flowRate
        }
        let title = currentBrewModeStep.title.lowercased()
        if currentWaterTarget <= 0 { return "—" }
        if title.contains("bloom") { return "2–3 g/s" }
        if title.contains("final") { return "3–4 g/s" }
        return "3–4 g/s"
    }

    private func handleSmartScaleWeightChange(previousWeight: Double, currentWeight: Double) {
        guard isGeneratedRecipeActive,
              lastScaleAutoAdvancedStepID != currentBrewModeStep.id,
              let row = generatedPourRows.first(where: { $0.id == currentBrewModeStep.id }),
              let target = currentBrewModeStep.waterTarget,
              SmartScaleGuidanceRules.shouldAdvance(
                isConnected: scaleManager.isConnected,
                isRunning: isBrewModeRunning,
                waterAdded: row.waterAdded,
                stepTitle: row.title,
                previousWeight: previousWeight,
                currentWeight: currentWeight,
                targetWeight: target
              ) else { return }

        let completedIndex = currentBrewModeStepIndex
        lastScaleAutoAdvancedStepID = currentBrewModeStep.id
        let hasLaterPour = generatedPourRows.dropFirst(completedIndex + 1).contains { $0.waterAdded != nil }
        if brewModeSteps.indices.contains(completedIndex + 1) {
            scaleStepOverrideIndex = completedIndex + 1
        }
        lastCueStepIndex = currentBrewModeStepIndex
        lastPrePourCueStepID = nil

        if !hasLaterPour {
            completeBrewModeSession(preserveElapsedTime: true, completedFromScale: true)
            return
        }

        updateBrewLiveActivity(isPaused: !isBrewModeRunning)
        sendBrewWatchUpdate(action: "update", isPaused: !isBrewModeRunning)
        persistActiveBrewSession()
        brewStepHaptic(strong: true)
    }

    private var brewModePauseResumeTitle: String {
        if isBrewModeRunning {
            return AppLocalization.text("pause", fallback: "Pause")
        }

        if brewModeElapsedSeconds > 0 {
            return AppLocalization.text("resume", fallback: "Resume")
        }

        return AppLocalization.text("start", fallback: "Start")
    }

    private var focusedBrewGuidanceText: String {
        let title = currentBrewModeStep.title.lowercased()

        if title.contains("bloom") {
            return AppLocalization.text("focused_bloom_guidance", fallback: "Pour evenly until every ground is saturated, then let the coffee open before the next pour.")
        }

        if currentWaterTarget > 0 {
            return currentBrewModeStep.detail.isEmpty
                ? AppLocalization.text("focused_pour_guidance", fallback: "Pour steadily through the centre, then widen into small circles.")
                : currentBrewModeStep.detail
        }

        return currentBrewModeStep.detail
    }

    private var currentTargetCompletionTime: String {
        if let nextBrewModeStep {
            return formattedTimerTime(nextBrewModeStep.time)
        }

        return formattedTimerTime(brewModeTotalSeconds)
    }

    private var focusedBloomDurationText: String {
        let bloomStart = currentBrewModeStep.time
        let bloomEnd = nextBrewModeStep?.time ?? min(bloomStart + 45, brewModeTotalSeconds)
        let duration = max(bloomEnd - bloomStart, 0)

        if duration >= 35 {
            return "35–45 seconds"
        }

        return "\(duration) seconds"
    }

    private var brewCompletionDifferenceText: String {
        let difference = brewModeElapsedSeconds - brewModeTotalSeconds

        if difference == 0 {
            return AppLocalization.text("on_target", fallback: "On target")
        }

        let formattedDifference = formattedTimerTime(abs(difference))
        if difference > 0 {
            return String(format: AppLocalization.text("over_target_format", fallback: "%@ over"), formattedDifference)
        }

        return String(format: AppLocalization.text("under_target_format", fallback: "%@ under"), formattedDifference)
    }

    private var currentBrewPhaseName: String {
        if brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale {
            return AppLocalization.text("complete", fallback: "Complete")
        }

        let title = currentBrewModeStep.title.lowercased()
        let detail = currentBrewModeStep.detail.lowercased()

        if title.contains("rinse") || title.contains("preheat") || title.contains("prepare") {
            return AppLocalization.text("prepare", fallback: "Prepare")
        }
        if title.contains("bloom") {
            return AppLocalization.text("bloom", fallback: "Bloom")
        }
        if title.contains("wait") || detail.contains("wait") || detail.contains("steep") {
            return AppLocalization.text("wait", fallback: "Wait")
        }
        if nextBrewModeStep == nil {
            return AppLocalization.text("drawdown", fallback: "Drawdown")
        }
        if currentWaterTarget > 0 {
            return AppLocalization.text("pour", fallback: "Pour")
        }
        return AppLocalization.text("prepare", fallback: "Prepare")
    }

    private func nextStepWaterTargetText(_ step: BrewModeStep) -> String {
        if let target = step.waterTarget {
            return "\(AppLocalization.text("pour_to", fallback: "Pour to")) \(formattedWholeGram(target)) g"
        }
        return step.title
    }

    private var brewModePrimaryActionTitle: String {
        if isBrewModeRunning {
            return AppLocalization.text("pause", fallback: "Pause")
        }

        if brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale {
            return AppLocalization.text("rate_this_brew_save", fallback: "Rate This Brew & Save")
        }

        if brewModeElapsedSeconds > 0 {
            return AppLocalization.text("resume", fallback: "Resume")
        }

        if activeSmartRecipe != nil {
            return String(
                format: AppLocalization.text("start_named_brew", fallback: "Start %@ Brew"),
                currentBrewRecipeTitle
            )
        }

        return AppLocalization.text("start", fallback: "Start")
    }

    private var brewModePrimaryActionIcon: String {
        if isBrewModeRunning {
            return "pause.fill"
        }

        if brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale {
            return "star.fill"
        }

        return "play.fill"
    }

    private var brewModeSteps: [BrewModeStep] {
        if isGeneratedRecipeActive {
            return generatedPourRows.map { row in
                BrewModeStep(
                    id: row.id,
                    time: row.startTime,
                    title: row.title,
                    detail: row.instruction,
                    waterTarget: row.cumulativeWater.map(Double.init)
                )
            }
        }
        if let activeSmartRecipe {
            return smartRecipeBrewModeSteps(for: activeSmartRecipe)
        }

        let method = selectedBrewModeMethod
        let categoryText = (method?.categories.joined(separator: " ") ?? method?.name ?? "").lowercased()

        if categoryText.contains("cold") {
            return coldBrewModeSteps
        }

        if categoryText.contains("traditional") || categoryText.contains("arabic") {
            return traditionalBrewModeSteps
        }

        if categoryText.contains("immersion") || categoryText.contains("press") {
            return immersionBrewModeSteps
        }

        return pourOverBrewModeSteps
    }

    private func smartRecipeBrewModeSteps(for profile: BrewGuideProfile) -> [BrewModeStep] {
        switch profile.id {
        case "v60-iced":
            let hotWater = recipeBrewingWaterAmount
            let ice = recipeIceAmount
            let bloom = hotWater * 50 / 180
            let secondTarget = hotWater * 120 / 180
            return [
                BrewModeStep(id: 0, time: 0, title: "Add \(formattedWholeGram(ice)) g ice", detail: "Put the brewing ice in the server, rinse the filter, and add \(formattedRatioValue(validCoffeeAmount)) g medium-ground coffee.", waterTarget: nil),
                BrewModeStep(id: 1, time: 5, title: "Bloom to \(formattedWholeGram(bloom)) g", detail: "Pour at 93 °C, wet every ground, and wait 10–15 seconds.", waterTarget: bloom),
                BrewModeStep(id: 2, time: 45, title: "Pour to \(formattedWholeGram(secondTarget)) g", detail: "Add water in slow circles.", waterTarget: secondTarget),
                BrewModeStep(id: 3, time: 90, title: "Finish at \(formattedWholeGram(hotWater)) g", detail: "Add the final hot water.", waterTarget: hotWater),
                BrewModeStep(id: 4, time: 135, title: "Swirl and serve over ice", detail: "Swirl the server so the brewing ice melts evenly, then pour over fresh ice.", waterTarget: hotWater)
            ]
        case "classic-cold-brew":
            let brewingWater = recipeBrewingWaterAmount
            return [
                BrewModeStep(id: 0, time: 0, title: "Add \(formattedRatioValue(validCoffeeAmount)) g coarse coffee", detail: "Use a clean jar or cold-brew bottle.", waterTarget: nil),
                BrewModeStep(id: 1, time: 30, title: "Pour to \(formattedWholeGram(brewingWater)) g", detail: "Use room-temperature filtered water and stir until every ground is wet.", waterTarget: brewingWater),
                BrewModeStep(id: 2, time: 60, title: "Steep covered", detail: "Leave at room temperature for 12–16 hours.", waterTarget: brewingWater),
                BrewModeStep(id: 3, time: 43_200, title: "Ready to filter", detail: "At 12 hours, taste the concentrate. Continue up to 16 hours for more strength.", waterTarget: brewingWater),
                BrewModeStep(id: 4, time: 50_400, title: "Filter and serve over ice", detail: "Use 1 part concentrate to 2 parts water or milk. A good serving is 100 g concentrate, 200 g mixer, and about 100 g ice.", waterTarget: brewingWater)
            ]
        case "balanced-filter":
            return [
                BrewModeStep(
                    id: 0,
                    time: 0,
                    title: "Add 20 g coffee",
                    detail: "Use a medium-fine grind, rinse the filter, warm the brewer, and level the bed.",
                    waterTarget: nil
                ),
                BrewModeStep(
                    id: 1,
                    time: 10,
                    title: "Bloom to 60 g",
                    detail: "Pour just enough 92–94 °C water to wet every ground, then let gas release.",
                    waterTarget: 60
                ),
                BrewModeStep(
                    id: 2,
                    time: 45,
                    title: "Pour to 220 g",
                    detail: "Use slow circles, keep the slurry even, and avoid pouring hard on the filter wall.",
                    waterTarget: 220
                ),
                BrewModeStep(
                    id: 3,
                    time: 90,
                    title: "Finish at 320 g",
                    detail: "Top up gently to the final 1:16 target and let the bed settle flat.",
                    waterTarget: 320
                ),
                BrewModeStep(
                    id: 4,
                    time: 210,
                    title: "Taste and save",
                    detail: "Target 3:30. If the cup is sweet and clean, save this recipe for next time.",
                    waterTarget: 320
                )
            ]
        case "espresso-base":
            return [
                BrewModeStep(id: 0, time: 0, title: "Dose 18 g coffee", detail: "Grind fine, distribute evenly, and tamp level.", waterTarget: nil),
                BrewModeStep(id: 1, time: 5, title: "Start the shot", detail: "Watch for an even flow across the basket.", waterTarget: nil),
                BrewModeStep(id: 2, time: 20, title: "Track the yield", detail: "Aim for the stream to stay steady and sweet, not pale too early.", waterTarget: nil),
                BrewModeStep(id: 3, time: 30, title: "Stop at 36 g", detail: "Taste before changing the next shot. Adjust grind first.", waterTarget: nil)
            ]
        case "french-press-sweet":
            return [
                BrewModeStep(id: 0, time: 0, title: "Add 24 g coffee", detail: "Use a coarse grind and preheat the press.", waterTarget: nil),
                BrewModeStep(id: 1, time: 10, title: "Pour to 360 g", detail: "Saturate all grounds, then stir gently.", waterTarget: 360),
                BrewModeStep(id: 2, time: 60, title: "Let sweetness build", detail: "Leave the slurry still while the coffee extracts.", waterTarget: 360),
                BrewModeStep(id: 3, time: 210, title: "Break and skim", detail: "Break the crust, skim the foam, then press slowly.", waterTarget: 360),
                BrewModeStep(id: 4, time: 240, title: "Serve fully", detail: "Pour everything out so it stops extracting in the brewer.", waterTarget: 360)
            ]
        case "arabic-majlis":
            return [
                BrewModeStep(id: 0, time: 0, title: "Measure 18 g coffee", detail: "Use a medium-coarse grind and prepare your spices if using them.", waterTarget: nil),
                BrewModeStep(id: 1, time: 45, title: "Add 324 g water", detail: "Heat gently and avoid a hard boil.", waterTarget: 324),
                BrewModeStep(id: 2, time: 150, title: "Simmer low", detail: "Keep heat calm so aroma develops without harshness.", waterTarget: 324),
                BrewModeStep(id: 3, time: 360, title: "Add spices and rest", detail: "Finish aromatics near the end, then let sediment settle.", waterTarget: 324),
                BrewModeStep(id: 4, time: 480, title: "Serve slowly", detail: "Pour cleanly into the dallah or cups.", waterTarget: 324)
            ]
        default:
            return pourOverBrewModeSteps
        }
    }

    private var pourOverBrewModeSteps: [BrewModeStep] {
        let bloomWater = min(validWaterAmount, validCoffeeAmount * 3)
        let firstPourWater = min(validWaterAmount, max(bloomWater, roundedBrewTarget(validWaterAmount * 0.56)))

        return [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Add \(formattedWholeGram(validCoffeeAmount)) g coffee",
                detail: AppLocalization.text("brew_mode_step_grind", fallback: "Level the bed, start the timer, and get ready to bloom."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: 10,
                title: "Pour to \(formattedWholeGram(bloomWater)) g",
                detail: AppLocalization.text("brew_mode_step_bloom", fallback: "Cover all grounds and let the coffee bloom."),
                waterTarget: bloomWater
            ),
            BrewModeStep(
                id: 2,
                time: stepTime(0.22, minimum: 45),
                title: "Continue pouring to \(formattedWholeGram(firstPourWater)) g",
                detail: AppLocalization.text("brew_mode_step_main_pour", fallback: "Pour slowly in circles and keep the bed even."),
                waterTarget: firstPourWater
            ),
            BrewModeStep(
                id: 3,
                time: stepTime(0.43, minimum: 90),
                title: "Finish at \(formattedWholeGram(validWaterAmount)) g",
                detail: AppLocalization.text("brew_mode_step_finish_pour", fallback: "Use the remaining water and let the drawdown settle."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: stepTime(0.79, minimum: 165),
                title: AppLocalization.text("brew_mode_step_serve_title", fallback: "Serve and taste"),
                detail: AppLocalization.text("brew_mode_step_serve_detail", fallback: "Swirl, pour, and save the recipe if this cup worked."),
                waterTarget: nil
            )
        ]
    }

    private var immersionBrewModeSteps: [BrewModeStep] {
        [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Add \(formattedWholeGram(validCoffeeAmount)) g coffee",
                detail: selectedBrewModeMethod?.summary ?? AppLocalization.text("immersion_step_add", fallback: "Use a medium-coarse grind and level the bed."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: 10,
                title: "Pour to \(formattedWholeGram(validWaterAmount)) g",
                detail: AppLocalization.text("immersion_step_pour", fallback: "Add all the water, saturate the grounds, and stir gently."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 2,
                time: stepTime(0.25, minimum: 60),
                title: AppLocalization.text("immersion_step_steep", fallback: "Let it steep"),
                detail: AppLocalization.text("immersion_step_steep_detail", fallback: "Keep the slurry still and let sweetness build."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 3,
                time: stepTime(0.82, minimum: 180),
                title: AppLocalization.text("immersion_step_finish", fallback: "Press or filter"),
                detail: AppLocalization.text("immersion_step_finish_detail", fallback: "Move slowly, then pour into a warm cup."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: stepTime(0.95, minimum: 210),
                title: AppLocalization.text("brew_mode_step_serve_title", fallback: "Serve and taste"),
                detail: AppLocalization.text("brew_mode_step_serve_detail", fallback: "Swirl, pour, and save the recipe if this cup worked."),
                waterTarget: nil
            )
        ]
    }

    private var traditionalBrewModeSteps: [BrewModeStep] {
        [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Measure \(formattedWholeGram(validCoffeeAmount)) g coffee",
                detail: selectedBrewModeMethod?.summary ?? AppLocalization.text("traditional_step_measure", fallback: "Prepare your pot, coffee, and spices before heating."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: stepTime(0.10, minimum: 45),
                title: "Add \(formattedWholeGram(validWaterAmount)) g water",
                detail: AppLocalization.text("traditional_step_water", fallback: "Bring the water up gently before adding coffee."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 2,
                time: stepTime(0.36, minimum: 150),
                title: AppLocalization.text("traditional_step_simmer", fallback: "Simmer gently"),
                detail: AppLocalization.text("traditional_step_simmer_detail", fallback: "Keep the heat low and let the aroma develop."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 3,
                time: stepTime(0.72, minimum: 300),
                title: AppLocalization.text("traditional_step_settle", fallback: "Let it settle"),
                detail: AppLocalization.text("traditional_step_settle_detail", fallback: "Rest briefly so the cup pours cleanly."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: stepTime(0.92, minimum: 420),
                title: AppLocalization.text("traditional_step_serve", fallback: "Serve slowly"),
                detail: AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
                waterTarget: nil
            )
        ]
    }

    private var coldBrewModeSteps: [BrewModeStep] {
        [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Add \(formattedWholeGram(validCoffeeAmount)) g coffee",
                detail: selectedBrewModeMethod?.summary ?? AppLocalization.text("cold_step_add", fallback: "Use a coarse grind and a clean jar or brewer."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: 30,
                title: "Pour to \(formattedWholeGram(validWaterAmount)) g",
                detail: AppLocalization.text("cold_step_pour", fallback: "Add water slowly and make sure all grounds are wet."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 2,
                time: stepTime(0.05, minimum: 120),
                title: AppLocalization.text("cold_step_steep", fallback: "Start steeping"),
                detail: AppLocalization.text("cold_step_steep_detail", fallback: "Cover and leave it chilled or at room temperature."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 3,
                time: stepTime(0.92, minimum: 600),
                title: AppLocalization.text("cold_step_filter", fallback: "Filter the brew"),
                detail: AppLocalization.text("cold_step_filter_detail", fallback: "Filter gently, then dilute or serve over ice."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: stepTime(0.98, minimum: 660),
                title: AppLocalization.text("cold_step_serve", fallback: "Serve chilled"),
                detail: AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
                waterTarget: nil
            )
        ]
    }

    private func brewModeStepRow(_ step: BrewModeStep, index: Int) -> some View {
        let isActive = index == currentBrewModeStepIndex
        let isComplete = brewModeElapsedSeconds > step.time && index < currentBrewModeStepIndex

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? accentColor : accentColor.opacity(isComplete ? 0.26 : 0.1))
                    .frame(width: 30, height: 30)

                Image(systemName: isComplete ? "checkmark" : "drop.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isActive ? Color(hex: 0x0A0804) : accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(formattedTimerTime(step.time)) - \(step.title)")
                    .font(Font.custom("AvenirNext-Bold", size: isActive ? 14 : 13))
                    .foregroundColor(isActive ? primaryTextColor : secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(tertiaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? accentColor.opacity(0.12) : accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func brewHistoryButton(_ item: BrewRecipeRecord, isPrimary: Bool) -> some View {
        Button {
            brewRecipeName = item.title
            if let coffeeGrams = item.coffeeGrams {
                ratioCoffeeInput = formattedRatioValue(coffeeGrams)
            }
            if let ratio = item.ratio {
                ratioValueInput = formattedRatioValue(ratio)
            }
            restartBrewMode()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isPrimary ? Color(hex: 0x0A0804) : accentColor)
                    .frame(width: 28, height: 28)
                    .background(isPrimary ? Color(hex: 0x0A0804).opacity(0.10) : accentColor.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(Font.custom("AvenirNext-Bold", size: isPrimary ? 14 : 13))
                        .foregroundColor(isPrimary ? Color(hex: 0x0A0804) : primaryTextColor)
                        .lineLimit(1)

                    Text(item.detail)
                        .font(Font.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(isPrimary ? Color(hex: 0x0A0804).opacity(0.72) : secondaryTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(AppLocalization.text("brew_again", fallback: "Brew Again"))
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(isPrimary ? Color(hex: 0x0A0804) : accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isPrimary ? Color(hex: 0x0A0804).opacity(0.08) : accentColor.opacity(0.10))
                    .clipShape(Capsule(style: .continuous))
            }
            .padding(isPrimary ? 14 : 12)
            .background(isPrimary ? accentColor : accentColor.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func selectBrewModeMethod(
        _ method: ContentView.BrewingMethod,
        start: Bool,
        usesSmartRecipe: Bool = false,
        preserveRecipeIdentity: Bool = false
    ) {
        restoredBrewTotalSeconds = nil
        if !usesSmartRecipe {
            activeSmartRecipeID = nil
        }

        selectedBrewModeMethodID = method.id
        if !preserveRecipeIdentity {
            brewRecipeName = method.name
            isGeneratedRecipeActive = false
        }
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeBackgroundDate = nil
        brewModeRunID = UUID()
        isBrewModeRunning = false
        endBrewLiveActivity()
        brewModeHapticTrigger += 1

        if start {
            startBrewModeSession()
        }
    }

    private func toggleBrewMode() {
        if isBrewModeRunning {
            brewModeRunID = UUID()
            isBrewModeRunning = false
            scaleManager.pauseTimer()
            updateBrewLiveActivity(isPaused: true)
            sendBrewWatchUpdate(action: "update", isPaused: true, allowBackgroundTransfer: true)
            brewModeHapticTrigger += 1
            return
        }

        if brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale {
            brewModeElapsedSeconds = 0
            lastCueStepIndex = -1
            lastPrePourCueStepID = nil
            lastScaleAutoAdvancedStepID = nil
            scaleStepOverrideIndex = nil
            didCompleteBrewFromScale = false
        }

        startBrewModeSession()
    }

    private func handleBrewModePrimaryAction() {
        if !isBrewModeRunning, (brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale) {
            guidedBrewCompletedAction(selectedBrewModeMethod, validCoffeeAmount, validRatioValue, validWaterAmount, brewModeElapsedSeconds)
            clearPersistedBrewSession()
            isFocusedBrewPresented = false
            brewModeHapticTrigger += 1
            return
        }

        toggleBrewMode()
    }

    private func restartBrewMode() {
        scaleManager.stopTimer()
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeBackgroundDate = nil
        endBrewLiveActivity()
        startBrewModeSession()
    }

    private func previousBrewModeStep() {
        let previousIndex = max(currentBrewModeStepIndex - 1, 0)
        brewModeElapsedSeconds = brewModeSteps[previousIndex].time
        lastCueStepIndex = previousIndex
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = previousIndex
        didCompleteBrewFromScale = false
        updateBrewLiveActivity(isPaused: !isBrewModeRunning)
        sendBrewWatchUpdate(action: "update", isPaused: !isBrewModeRunning)
        brewStepHaptic(strong: false)
    }

    private func skipBrewModeStep() {
        guard let nextBrewModeStep else {
            completeBrewModeSession()
            return
        }

        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeElapsedSeconds = nextBrewModeStep.time
        lastCueStepIndex = currentBrewModeStepIndex
        lastPrePourCueStepID = nil
        updateBrewLiveActivity(isPaused: !isBrewModeRunning)
        sendBrewWatchUpdate(action: "update", isPaused: !isBrewModeRunning)
        brewStepHaptic(strong: false)
    }

    private func startBrewModeSession() {
        if activeDashboardDestination != nil {
            activeDashboardDestination = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                startBrewModeSession()
            }
            return
        }

        if brewModeElapsedSeconds == 0 {
            resetAfterBrewFeedbackState()
            lastScaleAutoAdvancedStepID = nil
            scaleStepOverrideIndex = nil
            didCompleteBrewFromScale = false
        }

        let runID = UUID()
        brewModeRunID = runID
        isBrewModeRunning = true
        isFocusedBrewPresented = true
        brewModeBackgroundDate = nil
        scaleManager.startTimer()
        brewStepHaptic(strong: false)
        startOrUpdateBrewLiveActivity()
        sendBrewWatchUpdate(action: "start", isPaused: false, allowBackgroundTransfer: true)
        persistActiveBrewSession()

        Task { @MainActor in
            while isBrewModeRunning && brewModeRunID == runID && brewModeElapsedSeconds < brewModeTotalSeconds {
                try? await Task.sleep(for: .seconds(1))
                guard isBrewModeRunning, brewModeRunID == runID else { return }
                tickBrewMode()
            }
        }
    }

    private func tickBrewMode() {
        guard isBrewModeRunning else { return }

        if brewModeElapsedSeconds >= brewModeTotalSeconds {
            completeBrewModeSession()
            return
        }

        brewModeElapsedSeconds += 1
        let stepIndex = currentBrewModeStepIndex

        if stepIndex != lastCueStepIndex {
            lastCueStepIndex = stepIndex
            lastPrePourCueStepID = nil
            brewStepHaptic(strong: false)
        }

        if let nextBrewModeStep,
           nextBrewModeStep.waterTarget != nil,
           nextBrewModeStep.time - brewModeElapsedSeconds == 5,
           lastPrePourCueStepID != nextBrewModeStep.id {
            lastPrePourCueStepID = nextBrewModeStep.id
            brewStepHaptic(strong: true)
        }

        updateBrewLiveActivity(isPaused: false)
        sendBrewWatchUpdate(action: "update", isPaused: false)

        if brewModeElapsedSeconds >= brewModeTotalSeconds {
            completeBrewModeSession()
        }
    }

    private func completeBrewModeSession(
        dismissLiveActivityAfter seconds: Double = 8,
        preserveElapsedTime: Bool = false,
        completedFromScale: Bool = false
    ) {
        if !preserveElapsedTime {
            brewModeElapsedSeconds = brewModeTotalSeconds
        }
        didCompleteBrewFromScale = completedFromScale
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeBackgroundDate = nil
        scaleManager.pauseTimer()
        lastCueStepIndex = currentBrewModeStepIndex
        lastPrePourCueStepID = nil
        brewStepHaptic(strong: true, completion: true)
        persistActiveBrewSession()
        updateBrewLiveActivity(isPaused: true)
        sendBrewWatchUpdate(action: "end", isPaused: true, allowBackgroundTransfer: true)
        endBrewLiveActivity(after: seconds)
        setBrewIdleTimerDisabled(false)
    }

    private func requestEndFocusedBrew() {
        if isBrewModeRunning || brewModeElapsedSeconds > 0 {
            isEndBrewConfirmationPresented = true
        } else {
            isFocusedBrewPresented = false
        }
    }

    private func endFocusedBrew() {
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeBackgroundDate = nil
        restoredBrewTotalSeconds = nil
        isFocusedBrewPresented = false
        scaleManager.stopTimer()
        endBrewLiveActivity()
        sendBrewWatchUpdate(action: "end", isPaused: false, allowBackgroundTransfer: true)
        clearPersistedBrewSession()
        setBrewIdleTimerDisabled(false)
    }

    private func updateBrewIdleTimerState() {
        setBrewIdleTimerDisabled(isFocusedBrewPresented && (isBrewModeRunning || brewModeElapsedSeconds > 0))
    }

    private func handleBrewScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            if isBrewModeRunning {
                if brewModeBackgroundDate == nil {
                    brewModeBackgroundDate = Date()
                }
                persistActiveBrewSession()
                updateBrewLiveActivity(isPaused: false)
                sendBrewWatchUpdate(action: "update", isPaused: false, allowBackgroundTransfer: true)
            }
        case .active:
            guard isBrewModeRunning, let brewModeBackgroundDate else { return }
            let elapsedDelta = max(Int(Date().timeIntervalSince(brewModeBackgroundDate)), 0)
            self.brewModeBackgroundDate = nil
            guard elapsedDelta > 0 else { return }
            brewModeElapsedSeconds = min(brewModeElapsedSeconds + elapsedDelta, brewModeTotalSeconds)
            lastCueStepIndex = currentBrewModeStepIndex
            persistActiveBrewSession()
            updateBrewLiveActivity(isPaused: false)
            sendBrewWatchUpdate(action: "update", isPaused: false)
            if brewModeElapsedSeconds >= brewModeTotalSeconds {
                completeBrewModeSession()
            }
        @unknown default:
            break
        }
    }

    private func brewStepHaptic(strong: Bool, completion: Bool = false) {
        brewModeHapticTrigger += 1
#if canImport(UIKit)
        if completion {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if strong {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
#endif
    }

    private func setBrewIdleTimerDisabled(_ isDisabled: Bool) {
#if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = isDisabled
#endif
    }

    private func persistActiveBrewSession() {
        guard isCustomerSignedIn else {
            clearPersistedBrewSession()
            return
        }

        guard isFocusedBrewPresented || isBrewModeRunning || brewModeElapsedSeconds > 0 else {
            clearPersistedBrewSession()
            return
        }

        let snapshot = PersistedBrewSession(
            savedAt: Date(),
            isPresented: isFocusedBrewPresented,
            isRunning: isBrewModeRunning,
            elapsedSeconds: brewModeElapsedSeconds,
            totalSeconds: brewModeTotalSeconds,
            selectedMethodID: selectedBrewModeMethodID,
            activeSmartRecipeID: activeSmartRecipeID,
            selectedGuideProfileID: selectedGuideProfileID,
            brewRecipeName: brewRecipeName,
            ratioCoffeeInput: ratioCoffeeInput,
            ratioValueInput: ratioValueInput,
            createRecipeExperience: createRecipeExperience,
            createRecipeBrewer: createRecipeBrewer,
            createRecipeTasteGoal: createRecipeTasteGoal,
            generatedGrindDescription: generatedGrindDescription,
            generatedTemperatureC: generatedTemperatureC,
            recipePourCount: recipePourCount,
            scaleStepOverrideIndex: scaleStepOverrideIndex,
            didCompleteBrewFromScale: didCompleteBrewFromScale
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: BrewSessionStorage.activeSessionKey)
    }

    private func restorePersistedBrewSessionIfNeeded() {
        guard isCustomerSignedIn else {
            resetVisibleBrewSession()
            hasRestoredPersistedBrewSession = true
            return
        }

        guard !hasRestoredPersistedBrewSession else { return }
        hasRestoredPersistedBrewSession = true

        guard
            let data = UserDefaults.standard.data(forKey: BrewSessionStorage.activeSessionKey),
            let snapshot = try? JSONDecoder().decode(PersistedBrewSession.self, from: data)
        else {
            return
        }

        selectedBrewModeMethodID = snapshot.selectedMethodID
        activeSmartRecipeID = snapshot.activeSmartRecipeID
        selectedGuideProfileID = snapshot.selectedGuideProfileID
        brewRecipeName = snapshot.brewRecipeName
        ratioCoffeeInput = snapshot.ratioCoffeeInput
        ratioValueInput = snapshot.ratioValueInput
        createRecipeExperience = snapshot.createRecipeExperience
        createRecipeBrewer = snapshot.createRecipeBrewer
        createRecipeTasteGoal = snapshot.createRecipeTasteGoal
        generatedGrindDescription = snapshot.generatedGrindDescription
        generatedTemperatureC = snapshot.generatedTemperatureC
        recipePourCount = snapshot.recipePourCount
        scaleStepOverrideIndex = snapshot.scaleStepOverrideIndex
        didCompleteBrewFromScale = snapshot.didCompleteBrewFromScale ?? false
        restoredBrewTotalSeconds = snapshot.totalSeconds

        let backgroundDelta = snapshot.isRunning ? max(Int(Date().timeIntervalSince(snapshot.savedAt)), 0) : 0
        brewModeElapsedSeconds = min(snapshot.elapsedSeconds + backgroundDelta, brewModeTotalSeconds)
        lastCueStepIndex = currentBrewModeStepIndex
        lastPrePourCueStepID = nil
        brewModeBackgroundDate = nil

        if snapshot.isPresented || brewModeElapsedSeconds > 0 || didCompleteBrewFromScale {
            isFocusedBrewPresented = true
        }

        if snapshot.isRunning && !didCompleteBrewFromScale && brewModeElapsedSeconds < brewModeTotalSeconds {
            startBrewModeSession()
        } else {
            isBrewModeRunning = false
            updateBrewLiveActivity(isPaused: false)
        }
    }

    private func resetVisibleBrewSession() {
        isFocusedBrewPresented = false
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        selectedBrewModeMethodID = nil
        activeSmartRecipeID = nil
        restoredBrewTotalSeconds = nil
        brewModeBackgroundDate = nil
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        endBrewLiveActivity()
        sendBrewWatchUpdate(action: "end", isPaused: false, allowBackgroundTransfer: true)
        setBrewIdleTimerDisabled(false)
        clearPersistedBrewSession()
    }

    private func clearPersistedBrewSession() {
        UserDefaults.standard.removeObject(forKey: BrewSessionStorage.activeSessionKey)
    }

#if canImport(WatchConnectivity) && os(iOS)
    private func sendBrewWatchUpdate(action: String, isPaused: Bool, allowBackgroundTransfer: Bool = false) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }

        let payload: [String: Any] = [
            "brewActivity": action,
            "methodName": currentBrewRecipeTitle,
            "coffeeGrams": validCoffeeAmount,
            "ratio": validRatioValue,
            "totalWaterGrams": brewModeWaterAmount,
            "totalSeconds": brewModeTotalSeconds,
            "elapsedSeconds": brewModeElapsedSeconds,
            "currentStep": currentBrewModeStep.title,
            "nextStep": nextBrewModeStep?.title ?? AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
            "currentWaterGrams": currentWaterTarget,
            "isPaused": isPaused,
            "stepTimes": brewModeSteps.map(\.time),
            "stepTitles": brewModeSteps.map(\.title),
            "stepWaterTargets": brewModeSteps.map { $0.waterTarget ?? -1 }
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else if allowBackgroundTransfer {
            WCSession.default.transferUserInfo(payload)
        }
    }
#else
    private func sendBrewWatchUpdate(action: String, isPaused: Bool, allowBackgroundTransfer: Bool = false) { }
#endif

    private func startOrUpdateBrewLiveActivity() {
#if canImport(ActivityKit)
        guard shouldUseBrewLiveActivity, #available(iOS 16.1, *), ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if brewLiveActivity == nil {
            let attributes = TallaBrewActivityAttributes(
                methodName: currentBrewRecipeTitle,
                coffeeGrams: validCoffeeAmount,
                ratio: validRatioValue,
                totalWaterGrams: brewModeWaterAmount,
                totalSeconds: brewModeTotalSeconds,
                languageCode: AppLocalization.currentLanguage.effectiveLanguageCode
            )
            let content = ActivityContent(
                state: brewLiveActivityState(isPaused: false),
                staleDate: Date().addingTimeInterval(TimeInterval(max(brewModeTotalSeconds - brewModeElapsedSeconds, 1))),
                relevanceScore: 100
            )

            do {
                brewLiveActivity = try Activity<TallaBrewActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                brewLiveActivity = nil
            }
        } else {
            updateBrewLiveActivity(isPaused: false)
        }
#endif
    }

    private func updateBrewLiveActivity(isPaused: Bool) {
#if canImport(ActivityKit)
        guard shouldUseBrewLiveActivity, #available(iOS 16.1, *), let brewLiveActivity else { return }

        let content = ActivityContent(
            state: brewLiveActivityState(isPaused: isPaused),
            staleDate: Date().addingTimeInterval(TimeInterval(max(brewModeTotalSeconds - brewModeElapsedSeconds, 1))),
            relevanceScore: 100
        )

        Task {
            await brewLiveActivity.update(content)
        }
#endif
    }

    private func endBrewLiveActivity(after seconds: Double = 0) {
#if canImport(ActivityKit)
        guard shouldUseBrewLiveActivity, #available(iOS 16.1, *), let brewLiveActivity else { return }

        let finalContent = ActivityContent(
            state: brewLiveActivityState(isPaused: true),
            staleDate: nil,
            relevanceScore: 100
        )
        self.brewLiveActivity = nil

        Task {
            if seconds > 0 {
                await brewLiveActivity.end(finalContent, dismissalPolicy: .after(Date().addingTimeInterval(seconds)))
            } else {
                await brewLiveActivity.end(finalContent, dismissalPolicy: .immediate)
            }
        }
#endif
    }

#if canImport(ActivityKit)
    private var shouldUseBrewLiveActivity: Bool {
#if canImport(UIKit)
        UIDevice.current.userInterfaceIdiom == .phone
#else
        false
#endif
    }

    @available(iOS 16.1, *)
    private func brewLiveActivityState(isPaused: Bool) -> TallaBrewActivityAttributes.ContentState {
        TallaBrewActivityAttributes.ContentState(
            elapsedSeconds: brewModeElapsedSeconds,
            timerStartDate: Date().addingTimeInterval(-Double(brewModeElapsedSeconds)),
            currentStep: currentBrewModeStep.title,
            nextStep: nextBrewModeStep?.title ?? AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
            currentWaterGrams: currentWaterTarget,
            isPaused: isPaused,
            stepTimes: brewModeSteps.map(\.time),
            stepTitles: brewModeSteps.map(\.title),
            stepWaterTargets: brewModeSteps.map { $0.waterTarget ?? -1 }
        )
    }
#endif

    private func formattedTimerTime(_ seconds: Int) -> String {
        if seconds >= 3_600 {
            let hours = seconds / 3_600
            let minutes = (seconds % 3_600) / 60
            return String(format: "%d:%02d hr", hours, minutes)
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func stepTime(_ fraction: Double, minimum: Int) -> Int {
        min(max(Int(Double(brewModeTotalSeconds) * fraction), minimum), max(brewModeTotalSeconds - 1, 0))
    }

    private func seconds(from brewTime: String) -> Int? {
        let lowercasedTime = brewTime.lowercased()
        let matches = lowercasedTime.matches(of: /\d+(?:\.\d+)?/)
            .compactMap { Double($0.output) }

        guard !matches.isEmpty else { return nil }

        let value = matches.reduce(0, +) / Double(matches.count)

        if lowercasedTime.contains("hr") || lowercasedTime.contains("hour") {
            return max(Int(value * 3600), 60)
        }

        if lowercasedTime.contains("sec") {
            return max(Int(value), 30)
        }

        return max(Int(value * 60), 60)
    }

    private var ratioCalculatorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("ratio_calculator", fallback: "RATIO CALCULATOR"))
                .font(sectionTitleFont)
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            HStack(spacing: 12) {
                ratioInputField(title: AppLocalization.text("coffee_grams", fallback: "Coffee (g)"), text: $ratioCoffeeInput)
                ratioInputField(title: AppLocalization.text("ratio", fallback: "Ratio"), text: $ratioValueInput)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(formattedRatioValue(calculatedWaterAmount)) g")
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 26 : 30))
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text("water", fallback: "water"))
                    .font(Font.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(secondaryTextColor)
            }

            Text(String(
                format: AppLocalization.text("ratio_based_on", fallback: "Based on %@ g coffee at 1:%@."),
                formattedRatioValue(ratioCoffeeAmount),
                formattedRatioValue(ratioValue)
            ))
                .font(Font.custom("AvenirNext-Regular", size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                ratioInputField(
                    title: AppLocalization.text("recipe_name", fallback: "Recipe Name"),
                    text: $brewRecipeName,
                    placeholder: AppLocalization.text("name_this_recipe", fallback: "Name this recipe"),
                    keyboardType: .default
                )

                Button(action: saveCurrentRecipe) {
                    Text(AppLocalization.text("save_recipe", fallback: "Save Recipe"))
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

    private func strengthRatioButton(ratio: String, title: String) -> some View {
        let isSelected = ratioValueInput.trimmingCharacters(in: .whitespacesAndNewlines) == ratio

        return Button {
            ratioValueInput = ratio
        } label: {
            VStack(spacing: 3) {
                Text("1:\(ratio)")
                    .font(Font.custom("AvenirNext-Bold", size: 12))
                    .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)

                Text(title)
                    .font(Font.custom("AvenirNext-DemiBold", size: 10))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .foregroundColor(isSelected ? Color(hex: 0x0A0804).opacity(0.72) : tertiaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? accentColor : cardFillColor)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(accentColor.opacity(isSelected ? 0.0 : 0.20), lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func ratioInputField(title: String, text: Binding<String>, placeholder: String = "0", keyboardType: UIKeyboardType = .decimalPad) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 10))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            TextField(placeholder, text: text)
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

    private func formattedWholeGram(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    private func roundedBrewTarget(_ value: Double) -> Double {
        (value / 10).rounded() * 10
    }
}
