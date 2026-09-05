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
struct CoffeeBagCameraPicker: UIViewControllerRepresentable {
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
    @EnvironmentObject var coffeeData: CoffeeDataStore
    struct BrewModeStep: Identifiable {
        let id: Int
        let time: Int
        let title: String
        let detail: String
        let waterTarget: Double?
    }

    struct BrewGuideProfile: Identifiable {
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

    enum BrewingDashboardDestination: String, Identifiable {
        case createRecipe
        case scanCoffeeBag
        case ratioCalculator
        case brewTimer
        case coffeeJournal
        case coffeeLibrary
        case brewCoach

        var id: String { rawValue }
    }

    enum CreateRecipeStep: Int, CaseIterable {
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

    enum CoffeeDetailsMode {
        case scan
        case manual
    }

    struct BrewChoice: Identifiable {
        let id: String
        let title: String
        let detail: String
        let systemImage: String
    }

    struct BrewingMethodChoice: Identifiable, Hashable {
        let id: String
        let title: String
        let category: String
        let estimatedTime: String
        let description: String
        let systemImage: String
    }

    struct RecipeGenerationStage: Identifiable {
        let id: Int
        let title: String
        let checks: [String]
    }

    struct GeneratedPourRow: Identifiable {
        let id: Int
        let title: String
        let waterAdded: Int?
        let cumulativeWater: Int?
        let startTime: Int
        let flowRate: String
        let instruction: String
    }

    struct RecipeRevisionChange: Identifiable {
        let id: String
        let title: String
        let before: String
        let after: String
        let reason: String
    }

    struct CoffeeCalibrationRecord: Codable, Identifiable {
        let id: String
        var coffeeName: String
        var roaster: String
        var calibration: SmartBrewCalibration
        var updatedAt: Date
    }

    struct PersistedBrewSession: Codable {
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

    enum BrewSessionStorage {
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
    @Binding var pendingCoffeeName: String
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
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var brewingColorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject var scaleManager = CoffeeScaleManager()
    @AppStorage(BrewSessionStorage.profileCompletedKey) var isBrewProfileComplete = false
    @AppStorage(BrewSessionStorage.profileExperienceKey) var storedBrewProfileExperience = "basics"
    @AppStorage(BrewSessionStorage.profileBrewerKey) var storedBrewProfileBrewer = "v60"
    @AppStorage(BrewSessionStorage.profileTasteKey) var storedBrewProfileTaste = "balanced"
    @State var storedEquipmentGrinder = ""
    @AppStorage(BrewSessionStorage.equipmentFilterKey) var storedEquipmentFilter = ""
    @AppStorage(BrewSessionStorage.lastMethodKey) var storedLastBrewMethodID = ""
    @AppStorage(BrewSessionStorage.lastBrewTimestampKey) var storedLastBrewTimestamp = 0.0
    @AppStorage(BrewSessionStorage.favoriteMethodsKey) var storedFavoriteBrewMethodIDs = "v60,solo,kalita"
    @State var storedCoffeeCalibrations = ""
    @State var isBrewModeRunning = false
    @State var brewModeElapsedSeconds = 0
    @State var brewModeRunID = UUID()
    @State var lastCueStepIndex = -1
    @State var lastPrePourCueStepID: Int?
    @State var brewModeBackgroundDate: Date?
    @State var brewModeHapticTrigger = 0
    @State var selectedBrewModeMethodID: String?
    @State var isFocusedBrewPresented = false
    @State var isEndBrewConfirmationPresented = false
    @State var isBrewRestartConfirmationPresented = false
    @State var isScalePickerPresented = false
    @State var isHomeScalePickerPresented = false
    @State var selectedGuideProfileID = "balanced-filter"
    @State var activeSmartRecipeID: String?
    @State var expandedGuideProfileID: String?
    @State var brewCoachQuestion = ""
    @State var brewCoachAnswer: String?
    @State var isGeneratingBrewCoachAnswer = false
    @State var activeDashboardDestination: BrewingDashboardDestination?
    @State var brewProfileStep: CreateRecipeStep = .experience
    @State var createRecipeStep: CreateRecipeStep = .experience
    @State var createRecipeValidationMessage: String?
    @State var createRecipeExperience = "basics"
    @State var createRecipeBrewer = "v60"
    @State var createRecipeTasteGoal = "balanced"
    @State var coffeeDetailsMode: CoffeeDetailsMode?
    @State var coffeeName = ""
    @State var coffeeRoaster = ""
    @State var coffeeOrigin = ""
    @State var coffeeRegion = ""
    @State var coffeeAltitude = ""
    @State var coffeeVariety = ""
    @State var coffeeProcess = ""
    @State var coffeeRoastLevel = "Medium"
    @State var coffeeRoastDate = Date()
    @State var coffeeTastingNotes = ""
    @State var coffeeBrewNotes = ""
    @State var recipeGrinder = ""
    @State var recipeFilterType = ""
    @State var recipeBrewTemperatureMode = "Hot"
    @State var recipeCoffeeDose = "20"
    @State var recipePreferredRatio = "16"
    @State var recipeBloomRatio = "Auto"
    @State var recipePourCount = 3
    @State var recipeBrewControlMode = "Manual"
    @State var brewerSearchText = ""
    @State var isToolsMenuPresented = false
    @State var isMethodSelectionPresented = false
    @State var isSavedEquipmentPresented = false
    @State var isRecentRecipesExpanded = false
    @State var isBrewingGuidesExpanded = false
    @State var areAllBrewingGuidesVisible = false
    @State var methodSearchText = ""
    @State var methodCategoryFilter = "All"
    @State var selectedMethodChoiceID = ""
    @State var coffeeBagReviewMessage: String?
    @State var isCoffeeBagImageAnalyzing = false
    @State var coffeeBagAnalysisID = UUID()
    @State var recipeGenerationStageIndex = 0
    @State var recipeGenerationProgress = 0.0
    @State var recipeGenerationTaskID = UUID()
    @State var generatedRecipeNotes = ""
    @State var expandedScienceTopics: Set<String> = []
    @State var generatedGrindDescription = "Medium-fine"
    @State var generatedTemperatureC = 93
    @State var publishedRecipeCoffeeGrams: Double?
    @State var publishedRecipeWaterGrams: Double?
    @State var publishedRecipeIceGrams: Double?
    @State var afterBrewRating = 0
    @State var afterBrewSelections: Set<String> = []
    @State var afterBrewMoreOfSelections: Set<String> = []
    @State var afterBrewNotes = ""
    @State var recipeRevisionChanges: [RecipeRevisionChange] = []
    @State var revisedRecipeVersionTitle: String?
    @State var isAfterBrewSavedToJournal = false
    @State var isAfterBrewFeedbackExpanded = false
    @State var hasRestoredPersistedBrewSession = false
    @State var restoredBrewTotalSeconds: Int?
    @State var generatedRecipeID = UUID()
    @State var isGeneratedRecipeActive = false
    @State var restoredRecipeSteps: [SmartBrewStep]?
    @State var restoredTargetTimeRange: String?
    @State var restoredTemperatureReason: String?
    @State var restoredExpectedCup: String?
    @State var restoredApproach: String?
    @State var lastScaleAutoAdvancedStepID: Int?
    @State var scaleStepOverrideIndex: Int?
    @State var didCompleteBrewFromScale = false
#if canImport(PhotosUI)
    @State var coffeeBagPhotoSelection: PhotosPickerItem?
#endif
#if canImport(UIKit)
    @State var isCoffeeBagCameraPresented = false
    @State var coffeeBagPreviewImage: UIImage?
#endif
#if canImport(ActivityKit)
    @State var brewLiveActivity: Activity<TallaBrewActivityAttributes>?
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
        .onChange(of: pendingCoffeeName) { _, _ in
            consumePendingCoffeeIfNeeded()
        }
        .onAppear {
            storedEquipmentGrinder = coffeeData.equipmentName(kind: .grinder)
            storedCoffeeCalibrations = coffeeData.calibrationJSON()
            restoreBrewProfileSelections()
            restorePersistedBrewSessionIfNeeded()
            updateBrewIdleTimerState()
            consumePendingCoffeeIfNeeded()
        }
        .onDisappear {
            setBrewIdleTimerDisabled(false)
            endBrewLiveActivity()
        }
    }

    var brewBackgroundColor: Color {
        isOLEDAppearance ? .black : (brewingColorScheme == .dark ? Color(hex: 0x15120E) : Color(hex: 0xF7F5EF))
    }

    var brewSurfaceColor: Color {
        isOLEDAppearance ? .black : (brewingColorScheme == .dark ? Color(hex: 0x1F1A14) : Color(hex: 0xFFFDF8))
    }

    var brewPrimaryTextColor: Color {
        brewingColorScheme == .dark ? Color(hex: 0xF7F5EF) : Color(hex: 0x1C1A17)
    }

    var brewSecondaryTextColor: Color {
        brewingColorScheme == .dark ? Color(hex: 0xB9B1A6) : Color(hex: 0x74716A)
    }

    var brewBorderColor: Color {
        brewingColorScheme == .dark ? Color(hex: 0x342E26) : Color(hex: 0xDED9CF)
    }

    var brewAccentColor: Color {
        Color(hex: 0xC99550)
    }

    var brewColumnMaxWidth: CGFloat {
        isCompact ? .infinity : 720
    }

    var brewEyebrowFont: Font {
        .system(size: 11, weight: .semibold, design: .monospaced)
    }

    var brewQuestionFont: Font {
        .system(size: isCompact ? 24 : 28, weight: .semibold)
    }

    var brewReadingFont: Font {
        .system(size: 15, weight: .regular)
    }

    var brewSerifTitleFont: Font {
        Font.custom("Georgia-Bold", size: isCompact ? 32 : 38)
    }

}
