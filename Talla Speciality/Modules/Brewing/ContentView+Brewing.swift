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

extension ContentView {
    var brewingView: some View {
        BrewingSectionView(
            isCompact: isCompact,
            isCustomerSignedIn: customerProfile != nil,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: Color(hex: 0xC8965A),
            isOLEDAppearance: isOLEDAppearance,
            displayedMethods: displayedBrewingMethods,
            brewingCategories: brewingCategories,
            gridColumns: brewingGridColumns,
            isLoadingMethods: isLoadingBrewingMethods,
            methodsAreEmpty: brewingMethods.isEmpty,
            methodsError: brewingMethodsError,
            activeCategory: $activeBrewingCategory,
            ratioCoffeeInput: $ratioCoffeeInput,
            ratioValueInput: $ratioValueInput,
            brewRecipeName: $brewRecipeName,
            pendingCoffeeName: $pendingBrewingCoffeeName,
            calculatedWaterAmount: calculatedWaterAmount,
            ratioCoffeeAmount: ratioCoffeeAmount,
            ratioValue: ratioValue,
            brewHistoryItems: brewAgainHistoryItems,
            titleFont: displayFont(size: 32),
            sectionTitleFont: labelFont(size: 11, weight: .bold),
            bodyFont: bodyFont(size: 13),
            labelFont: labelFont(size: 10, weight: .semibold),
            saveRecipeAction: { recipe in
                saveCurrentBrewRecipe(recipe)
            },
            openArticleAction: { url in
                articleSession = CheckoutSession(url: url)
            },
            guidedBrewCompletedAction: { method, coffeeAmount, ratio, waterAmount, brewTime in
                prepareJournalEntryFromGuidedBrew(
                    method: method,
                    coffeeAmount: coffeeAmount,
                    ratio: ratio,
                    waterAmount: waterAmount,
                    brewTime: brewTime
                )
            },
            brewTimerSection: AnyView(brewTimerSection),
            coffeeJournalSection: AnyView(coffeeJournalSection),
            loadingView: AnyView(loadingSection)
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    var brewTimerPresets: [(name: String, seconds: Int, symbol: String)] {
        [
            ("Pour Over", 210, "drop.fill"),
            ("French Press", 240, "cup.and.saucer.fill"),
            ("Arabic Coffee", 480, "flame.fill"),
            ("Cold Brew", 43_200, "snowflake")
        ]
    }

    var brewTimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalization.text("brew_timer", fallback: "Brew Timer"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                    Text(AppLocalization.text("brew_timer_detail", fallback: "Start a focused timer for the brew you are making now."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .center, spacing: 12) {
                Text(formattedTimerTime(brewTimerRemainingSeconds))
                    .font(displayFont(size: isCompact ? 42 : 52))
                    .monospacedDigit()
                    .foregroundColor(primaryTextColor)
                    .contentTransition(.numericText())

                Spacer(minLength: 0)

                Button {
                    resetBrewTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(cardFillColor)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("reset_timer", fallback: "Reset timer"))
            }

            Text(brewTimerCueText)
                .font(labelFont(size: 11, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .contentTransition(.opacity)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.10))

                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xC8965A))
                        .frame(width: max(proxy.size.width * brewTimerFraction, isBrewTimerRunning ? 10 : 0))
                        .animation(.linear(duration: 0.2), value: brewTimerRemainingSeconds)
                }
            }
            .frame(height: 9)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                ForEach(brewTimerPresets, id: \.name) { preset in
                    brewTimerPresetButton(preset)
                }
            }

            HStack(spacing: 10) {
                Button {
                    if isBrewTimerRunning {
                        pauseBrewTimer()
                    } else {
                        startBrewTimer()
                    }
                } label: {
                    Label(brewTimerPrimaryActionTitle, systemImage: isBrewTimerRunning ? "pause.fill" : "play.fill")
                        .font(labelFont(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var coffeeJournalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalization.text("coffee_journal", fallback: "Coffee Journal"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                    Text(AppLocalization.text("coffee_journal_detail", fallback: "Save what worked: method, rating, and a note for your next cup."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            TextField(AppLocalization.text("journal_title", fallback: "Coffee or recipe name"), text: $journalTitleInput)
                .textInputAutocapitalization(.words)
                .font(bodyFont(size: 14))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(elevatedSurfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            TextField(AppLocalization.text("method", fallback: "Method"), text: $journalMethodInput)
                .textInputAutocapitalization(.words)
                .font(bodyFont(size: 14))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(elevatedSurfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let journalBrewDetailLine {
                Text(journalBrewDetailLine)
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        journalRating = rating
                        delightFeedbackTrigger += 1
                    } label: {
                        Image(systemName: rating <= journalRating ? "star.fill" : "star")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(readableBrandGoldColor)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(rating) \(AppLocalization.text("stars", fallback: "stars"))")
                }

                Spacer(minLength: 0)
            }

            TextField(AppLocalization.text("tasting_notes", fallback: "Tasting notes"), text: $journalNotesInput, axis: .vertical)
                .lineLimit(2...4)
                .textInputAutocapitalization(.sentences)
                .font(bodyFont(size: 14))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(elevatedSurfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                saveCoffeeJournalEntry()
            } label: {
                Text(AppLocalization.text("save_journal_entry", fallback: "Save Journal Entry"))
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if !brewJournalEntries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.text("recent_notes", fallback: "Recent Notes"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                    ForEach(brewJournalEntries.prefix(3)) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.title)
                                    .font(titleFont(size: 17))
                                    .foregroundColor(primaryTextColor)

                                Text("\(entry.method) • \(entry.rating)/5")
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.2)
                                    .textCase(.uppercase)
                                    .foregroundColor(readableBrandGoldColor)

                                if let detail = brewJournalDetailLine(for: entry) {
                                    Text(detail)
                                        .font(labelFont(size: 9, weight: .bold))
                                        .tracking(0.9)
                                        .textCase(.uppercase)
                                        .foregroundColor(tertiaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if !entry.notes.isEmpty {
                                    Text(entry.notes)
                                        .font(bodyFont(size: 13))
                                        .foregroundColor(secondaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Spacer(minLength: 0)

                            Button {
                                deleteCoffeeJournalEntry(entry)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(primaryTextColor)
                                    .frame(width: 32, height: 32)
                                    .background(cardFillColor)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(elevatedSurfaceColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func brewTimerPresetButton(_ preset: (name: String, seconds: Int, symbol: String)) -> some View {
        let isSelected = selectedBrewTimerName == preset.name

        return Button {
            cancelBrewTimerCompletionNotification()
            brewTimerRunID = UUID()
            selectedBrewTimerName = preset.name
            selectedBrewTimerSeconds = preset.seconds
            brewTimerRemainingSeconds = preset.seconds
            isBrewTimerRunning = false
            brewTimerEndDate = nil
            journalMethodInput = preset.name
        } label: {
            Label(preset.name, systemImage: preset.symbol)
                .font(labelFont(size: 10, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected ? Color(hex: 0xC8965A) : elevatedSurfaceColor)
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func persistBrewRecipes(_ recipes: [BrewRecipe]) {
        guard let data = try? JSONEncoder().encode(recipes),
              let objects = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return
        }
        try? coffeeData.replaceLegacyRecords(entityType: "recipe", objects: objects)
    }

    var brewTimerFraction: Double {
        guard selectedBrewTimerSeconds > 0 else { return 0 }
        return min(max(Double(brewTimerRemainingSeconds) / Double(selectedBrewTimerSeconds), 0), 1)
    }

    var brewTimerElapsedSeconds: Int {
        max(selectedBrewTimerSeconds - brewTimerRemainingSeconds, 0)
    }

    var brewTimerPrimaryActionTitle: String {
        if isBrewTimerRunning {
            return AppLocalization.text("pause", fallback: "Pause")
        }

        if brewTimerRemainingSeconds == selectedBrewTimerSeconds {
            return AppLocalization.text("start", fallback: "Start")
        }

        if brewTimerRemainingSeconds == 0 {
            return AppLocalization.text("brew_again", fallback: "Brew Again")
        }

        return AppLocalization.text("resume", fallback: "Resume")
    }

    var brewTimerCueText: String {
        let elapsed = brewTimerElapsedSeconds
        let method = selectedBrewTimerName.lowercased()

        if brewTimerRemainingSeconds == 0 {
            return AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly.")
        }

        if method.contains("cold") {
            if elapsed < 60 {
                return AppLocalization.text("cold_timer_cue_saturate", fallback: "Saturate the grounds")
            }
            if elapsed < 43_000 {
                return AppLocalization.text("cold_timer_cue_steep", fallback: "Steep slowly")
            }
            return AppLocalization.text("cold_timer_cue_filter", fallback: "Filter and serve chilled")
        }

        if method.contains("arabic") {
            if elapsed < 90 {
                return AppLocalization.text("arabic_timer_cue_heat", fallback: "Heat the water")
            }
            if elapsed < 180 {
                return AppLocalization.text("arabic_timer_cue_add", fallback: "Add coffee and spices")
            }
            if elapsed < 360 {
                return AppLocalization.text("arabic_timer_cue_simmer", fallback: "Simmer gently")
            }
            return AppLocalization.text("arabic_timer_cue_settle", fallback: "Let it settle")
        }

        if method.contains("press") {
            if elapsed < 30 {
                return AppLocalization.text("press_timer_cue_pour", fallback: "Pour and saturate")
            }
            if elapsed < 210 {
                return AppLocalization.text("press_timer_cue_steep", fallback: "Let it steep")
            }
            return AppLocalization.text("press_timer_cue_plunge", fallback: "Press slowly")
        }

        if elapsed < 30 {
            return AppLocalization.text("pour_timer_cue_bloom", fallback: "Blooming")
        }
        if elapsed < 45 {
            return AppLocalization.text("pour_timer_cue_bloom_done", fallback: "Bloom complete")
        }
        if elapsed < 90 {
            return AppLocalization.text("pour_timer_cue_second_pour", fallback: "Begin second pour")
        }
        if elapsed < 165 {
            return AppLocalization.text("pour_timer_cue_drawdown", fallback: "Drawdown should start now")
        }
        return AppLocalization.text("pour_timer_cue_finish", fallback: "Let it finish")
    }

    func tickBrewTimer() {
        guard isBrewTimerRunning else { return }
        guard let brewTimerEndDate else { return }
        brewTimerRemainingSeconds = max(Int(ceil(brewTimerEndDate.timeIntervalSinceNow)), 0)

        if brewTimerRemainingSeconds == 0 {
            isBrewTimerRunning = false
            self.brewTimerEndDate = nil
            delightFeedbackTrigger += 1
            showToast(message: AppLocalization.text("brew_timer_done", fallback: "Brew timer done"))
        }
    }

    func startBrewTimer() {
        if brewTimerRemainingSeconds == 0 {
            cancelBrewTimerCompletionNotification()
            brewTimerRemainingSeconds = selectedBrewTimerSeconds
        }

        let runID = UUID()
        brewTimerRunID = runID
        isBrewTimerRunning = true
        brewTimerEndDate = Date().addingTimeInterval(TimeInterval(brewTimerRemainingSeconds))
        delightFeedbackTrigger += 1

#if canImport(UserNotifications)
        let notificationTitle = AppLocalization.text("brew_timer_notification_title", fallback: "Brew complete")
        let notificationBody = AppLocalization.text("brew_timer_notification_body", fallback: "Your coffee is ready for the next step.")
        Task {
            await BrewTimerNotificationService.scheduleCompletion(
                runID: runID,
                after: brewTimerRemainingSeconds,
                title: notificationTitle,
                body: notificationBody
            )
            guard isBrewTimerRunning, brewTimerRunID == runID else {
                BrewTimerNotificationService.cancelCompletion(runID: runID)
                return
            }
        }
#endif

        Task { @MainActor in
            while isBrewTimerRunning && brewTimerRunID == runID && brewTimerRemainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard isBrewTimerRunning, brewTimerRunID == runID else { return }
                tickBrewTimer()
            }
        }
    }

    func pauseBrewTimer() {
        synchronizeBrewTimerWithClock()
        cancelBrewTimerCompletionNotification()
        brewTimerRunID = UUID()
        isBrewTimerRunning = false
        brewTimerEndDate = nil
    }

    func synchronizeBrewTimerWithClock() {
        guard isBrewTimerRunning, brewTimerEndDate != nil else { return }
        tickBrewTimer()
    }

    func resetBrewTimer() {
        cancelBrewTimerCompletionNotification()
        brewTimerRunID = UUID()
        brewTimerRemainingSeconds = selectedBrewTimerSeconds
        isBrewTimerRunning = false
        brewTimerEndDate = nil
    }

    func cancelBrewTimerCompletionNotification() {
#if canImport(UserNotifications)
        BrewTimerNotificationService.cancelCompletion(runID: brewTimerRunID)
#endif
    }

    func formattedTimerTime(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    func persistCoffeeJournalEntries(_ entries: [BrewJournalEntry]) {
        guard let data = try? JSONEncoder().encode(entries),
              let objects = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return
        }
        try? coffeeData.replaceLegacyRecords(entityType: "brewSession", objects: objects)
    }

    @MainActor
    func synchronizeCustomerLibrary() async {
        guard let email = customerProfile?.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !email.isEmpty else { return }

        let migratedEmails = Set(customerLibraryMigratedEmails.split(separator: ",").map(String.init))
        do {
            let library: CustomerLibraryPayload
            if migratedEmails.contains(email) || (!customerLibraryCacheOwnerEmail.isEmpty && customerLibraryCacheOwnerEmail != email) {
                library = try await AccountService.fetchCustomerLibrary()
            } else {
                library = try await AccountService.mergeCustomerLibrary(
                    favorites: Array(favoriteProductIDs),
                    recentlyViewed: recentlyViewedProductIDs,
                    brewJournal: brewJournalEntries
                )
                customerLibraryMigratedEmails = (migratedEmails.union([email])).sorted().joined(separator: ",")
            }
            applyCustomerLibrary(library)
            let token = savedCustomerAccessToken.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseURL = (Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String).flatMap(URL.init(string:))
            if !token.isEmpty, let baseURL {
                try await coffeeData.synchronize(ownerID: email, bearerToken: token, baseURL: baseURL)
            }
        } catch {
            // Keep the local cache available while offline and retry on the next activation.
        }
    }

    @MainActor
    func applyCustomerLibrary(_ library: CustomerLibraryPayload) {
        savedFavoriteProductIDs = Array(Set(library.favorites)).sorted().joined(separator: ",")
        savedRecentlyViewedProductIDs = Array(library.recentlyViewed.prefix(20)).joined(separator: ",")
        persistCoffeeJournalEntries(Array(library.brewJournal.prefix(20)))
        customerLibraryCacheOwnerEmail = customerProfile?.email.lowercased() ?? customerLibraryCacheOwnerEmail
    }

    func saveCoffeeJournalEntry() {
        let title = journalTitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let method = journalMethodInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = journalNotesInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty || !notes.isEmpty else {
            showToast(message: AppLocalization.text("journal_needs_note", fallback: "Add a coffee name or note first"))
            return
        }

        let entry = BrewJournalEntry(
            id: UUID(),
            title: title.isEmpty ? defaultBrewRecipeName() : title,
            method: method.isEmpty ? selectedBrewTimerName : method,
            coffeeGrams: journalCoffeeGrams,
            ratio: journalRatio,
            waterGrams: journalWaterGrams,
            brewTimeSeconds: journalBrewTimeSeconds,
            rating: journalRating,
            notes: notes,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        persistCoffeeJournalEntries(Array(([entry] + brewJournalEntries).prefix(20)))
        var brewTelemetry: [String: String] = [
            "method": entry.method,
            "rating": String(entry.rating)
        ]
        if let duration = entry.brewTimeSeconds {
            brewTelemetry["duration_seconds"] = String(duration)
        }
        TallaTelemetry.shared.track("brew_completed", properties: brewTelemetry)
        TallaTelemetry.shared.track("brew_rated", properties: ["rating": String(entry.rating)])
        if customerProfile != nil {
            Task { _ = try? await AccountService.saveBrewJournal(entry) }
        }
        journalTitleInput = ""
        journalNotesInput = ""
        clearJournalBrewDetails()
        showToast(message: AppLocalization.text("journal_saved_toast", fallback: "Coffee note saved"))
    }

    func prepareJournalEntryFromGuidedBrew(method: BrewingMethod?, coffeeAmount: Double, ratio: Double, waterAmount: Double, brewTime: Int) {
        let methodName = method?.name ?? (activeBrewingCategory == "All" ? selectedBrewTimerName : activeBrewingCategory)
        let recipeName = methodName.isEmpty ? defaultBrewRecipeName() : methodName

        journalTitleInput = recipeName
        journalMethodInput = methodName
        journalCoffeeGrams = coffeeAmount
        journalRatio = ratio
        journalWaterGrams = waterAmount
        journalBrewTimeSeconds = brewTime
        journalNotesInput = ""
        brewRecipeName = recipeName
        showToast(message: AppLocalization.text("guided_brew_journal_ready", fallback: "Journal entry prepared"))
    }

    var journalBrewDetailLine: String? {
        guard let coffeeGrams = journalCoffeeGrams,
              let ratio = journalRatio,
              let waterGrams = journalWaterGrams,
              let brewTimeSeconds = journalBrewTimeSeconds else {
            return nil
        }

        return brewJournalDetailLine(
            coffeeGrams: coffeeGrams,
            ratio: ratio,
            waterGrams: waterGrams,
            brewTimeSeconds: brewTimeSeconds
        )
    }

    func brewJournalDetailLine(for entry: BrewJournalEntry) -> String? {
        guard let coffeeGrams = entry.coffeeGrams,
              let ratio = entry.ratio,
              let waterGrams = entry.waterGrams,
              let brewTimeSeconds = entry.brewTimeSeconds else {
            return nil
        }

        return brewJournalDetailLine(
            coffeeGrams: coffeeGrams,
            ratio: ratio,
            waterGrams: waterGrams,
            brewTimeSeconds: brewTimeSeconds
        )
    }

    func brewJournalDetailLine(coffeeGrams: Double, ratio: Double, waterGrams: Double, brewTimeSeconds: Int) -> String {
        [
            "\(formattedRatioValue(coffeeGrams)) g coffee",
            "1:\(formattedRatioValue(ratio))",
            "\(formattedRatioValue(waterGrams)) g water",
            formattedTimerTime(brewTimeSeconds)
        ].joined(separator: " - ")
    }

    func clearJournalBrewDetails() {
        journalCoffeeGrams = nil
        journalRatio = nil
        journalWaterGrams = nil
        journalBrewTimeSeconds = nil
    }

    func deleteCoffeeJournalEntry(_ entry: BrewJournalEntry) {
        persistCoffeeJournalEntries(brewJournalEntries.filter { $0.id != entry.id })
        if customerProfile != nil {
            Task { _ = try? await AccountService.deleteBrewJournal(id: entry.id) }
        }
        showToast(message: AppLocalization.text("journal_deleted_toast", fallback: "Coffee note deleted"))
    }

    func saveCurrentBrewRecipe(_ record: BrewRecipeRecord) {
        guard let coffeeGrams = record.coffeeGrams,
              let ratio = record.ratio,
              coffeeGrams > 0,
              ratio > 0 else {
            showToast(message: AppLocalization.text("enter_valid_brew_recipe", fallback: "Enter a valid brew recipe first"))
            return
        }

        let trimmedName = record.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let recipe = BrewRecipe(
            id: record.id,
            name: trimmedName.isEmpty ? defaultBrewRecipeName() : trimmedName,
            coffeeGrams: coffeeGrams,
            ratio: ratio,
            waterGrams: record.totalWaterGrams ?? coffeeGrams * ratio,
            category: activeBrewingCategory == "All" ? "Custom Brew" : activeBrewingCategory,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            brewingWaterGrams: record.brewingWaterGrams,
            iceGrams: record.iceGrams,
            methodID: record.methodID,
            brewerID: record.brewerID,
            brewMode: record.brewMode,
            bloomRatio: record.bloomRatio,
            pourCount: record.pourCount,
            grind: record.grind,
            temperatureC: record.temperatureC,
            controlMode: record.controlMode,
            process: record.process,
            roast: record.roast,
            grinder: record.grinder,
            filter: record.filter,
            altitudeMeters: record.altitudeMeters,
            tastingNotes: record.tastingNotes,
            targetTimeRange: record.targetTimeRange,
            temperatureReason: record.temperatureReason,
            expectedCup: record.expectedCup,
            approach: record.approach,
            steps: record.steps
        )

        persistBrewRecipes([recipe] + brewRecipes.filter { $0.id != recipe.id })
        showToast(message: AppLocalization.text("brew_recipe_saved_toast", fallback: "Brew recipe saved"))
    }

    func applyBrewRecipe(_ recipe: BrewRecipe) {
        ratioCoffeeInput = formattedRatioValue(recipe.coffeeGrams)
        ratioValueInput = formattedRatioValue(recipe.ratio)
        openBrewing()
        showToast(message: String(format: AppLocalization.text("recipe_loaded_toast", fallback: "%@ loaded"), recipe.name))
    }

    func deleteBrewRecipe(_ recipe: BrewRecipe) {
        persistBrewRecipes(brewRecipes.filter { $0.id != recipe.id })
        showToast(message: AppLocalization.text("brew_recipe_deleted_toast", fallback: "Brew recipe deleted"))
    }

    func defaultBrewRecipeName() -> String {
        let category = activeBrewingCategory == "All" ? "House Ratio" : activeBrewingCategory
        return "\(category) \(formattedRatioValue(ratioCoffeeAmount))g"
    }

}
