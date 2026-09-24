import SwiftUI

struct CuppingEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var name = ""
    var aroma = 3
    var acidity = 3
    var sweetness = 3
    var body = 3
    var clarity = 3
    var notes = ""
    var createdAt = Date()
}

struct CommunityRecipeEntry: Codable, Identifiable, Hashable {
    enum ModerationStatus: String, Codable { case pending, approved, rejected }
    var id = UUID().uuidString
    var title: String
    var method: String
    var detail: String
    var author: String
    var status: ModerationStatus = .pending
    var createdAt = Date()
    var canEdit = true
}

struct CuppingWorkspaceView: View {
    let isSignedIn: Bool
    let accent: Color
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    @State private var entries: [CuppingEntry] = []
    @State private var name = ""
    @State private var notes = ""
    @State private var eventTitle = ""
    @State private var eventDate = Date().addingTimeInterval(86_400)
    @State private var showEventForm = false
    private let key = "talla.cupping.entries.v1"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(AppLocalization.text("cupping_mode", fallback: "CUPPING MODE"), systemImage: "wineglass")
                        .font(.caption.weight(.bold)).tracking(1.6).foregroundStyle(accent)
                    Text(AppLocalization.text("cupping_title", fallback: "Calibrate your palate")).font(.system(size: 27, weight: .semibold, design: .serif)).foregroundStyle(primary)
                    Text(AppLocalization.text("cupping_detail", fallback: "Taste coffees side by side, score the same dimensions, and keep the language consistent.")).font(.subheadline).foregroundStyle(secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(AppLocalization.text("cupping_new_sample", fallback: "New sample")).font(.headline).foregroundStyle(primary)
                    TextField(AppLocalization.text("cupping_sample_name", fallback: "Coffee or sample name"), text: $name).textFieldStyle(.talla)
                    cuppingSlider("Aroma", value: $draftAroma)
                    cuppingSlider("Acidity", value: $draftAcidity)
                    cuppingSlider("Sweetness", value: $draftSweetness)
                    cuppingSlider("Body", value: $draftBody)
                    cuppingSlider("Clarity", value: $draftClarity)
                    TextField(AppLocalization.text("cupping_notes", fallback: "Sensory notes"), text: $notes, axis: .vertical).lineLimit(3...6).textFieldStyle(.talla)
                    Button {
                        let entry = CuppingEntry(name: name.isEmpty ? "Sample (entries.count + 1)" : name, aroma: draftAroma, acidity: draftAcidity, sweetness: draftSweetness, body: draftBody, clarity: draftClarity, notes: notes)
                        entries.insert(entry, at: 0); save(); name = ""; notes = ""
                        if isSignedIn { Task { _ = try? await AccountService.saveCuppingEntry(entry) } }
                    } label: { Label(AppLocalization.text("save_cupping_sample", fallback: "Save sample"), systemImage: "plus.circle.fill").frame(maxWidth: .infinity).padding(12) }
                        .buttonStyle(.tallaPrimary).tint(accent)
                }.padding(16).background(surface).clipShape(RoundedRectangle(cornerRadius: 18))

                if entries.count >= 2 {
                    comparisonCard
                }
                if !entries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalization.text("cupping_history", fallback: "Cupping history")).font(.headline).foregroundStyle(primary)
                        ForEach(entries) { entry in
                            HStack { VStack(alignment: .leading) { Text(entry.name).font(.subheadline.weight(.semibold)).foregroundStyle(primary); Text(entry.notes.isEmpty ? "No notes" : entry.notes).font(.caption).foregroundStyle(secondary) }; Spacer(); Text("\(average(entry)) / 5").font(.headline.monospacedDigit()).foregroundStyle(accent) }
                                .padding(12).background(surface).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                Button { showEventForm = true } label: { Label(AppLocalization.text("cupping_event", fallback: "Plan a cupping event"), systemImage: "calendar.badge.plus") }
                    .buttonStyle(.tallaSecondary).tint(accent)
            }.padding(20)
        }
        .background(background.ignoresSafeArea())
        .navigationTitle(AppLocalization.text("cupping_mode", fallback: "Cupping"))
        .onAppear { load() }
        .sheet(isPresented: $showEventForm) {
            NavigationStack { Form { TextField("Event name", text: $eventTitle); DatePicker("Date", selection: $eventDate, in: Date()...) }.navigationTitle("Cupping event").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { showEventForm = false } } } }
        }
    }

    @State private var draftAroma = 3
    @State private var draftAcidity = 3
    @State private var draftSweetness = 3
    @State private var draftBody = 3
    @State private var draftClarity = 3

    private func cuppingSlider(_ title: String, value: Binding<Int>) -> some View { HStack { Text(title).frame(width: 78, alignment: .leading).foregroundStyle(primary); Slider(value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Int($0.rounded()) }), in: 1...5, step: 1).tint(accent); Text("\(value.wrappedValue)").monospacedDigit().foregroundStyle(secondary) } }
    private var comparisonCard: some View { VStack(alignment: .leading, spacing: 10) { Text(AppLocalization.text("cupping_comparison", fallback: "Side-by-side comparison")).font(.headline).foregroundStyle(primary); ForEach(entries.prefix(2)) { entry in Text("\(entry.name): \(average(entry))/5 · A\(entry.aroma) · Ac\(entry.acidity) · S\(entry.sweetness) · B\(entry.body) · C\(entry.clarity)").font(.caption).foregroundStyle(secondary) } }.padding(16).background(accent.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 16)) }
    private func average(_ entry: CuppingEntry) -> String { String(format: "%.1f", Double(entry.aroma + entry.acidity + entry.sweetness + entry.body + entry.clarity) / 5) }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([CuppingEntry].self, from: data) { entries = decoded }
        guard isSignedIn else { return }
        Task {
            if let remote = try? await AccountService.fetchCuppingEntries() {
                await MainActor.run { entries = remote; save() }
            }
        }
    }
    private func save() { UserDefaults.standard.set(try? JSONEncoder().encode(entries), forKey: key) }
}

struct CommunityRecipesView: View {
    let isSignedIn: Bool
    let accent: Color
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    @State private var recipes: [CommunityRecipeEntry] = []
    @State private var title = ""
    @State private var method = ""
    @State private var detail = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var editingRecipe: CommunityRecipeEntry?
    @AppStorage("privacy.community.sharing.optOut") private var communitySharingOptOut = false
    private let key = "talla.community.recipes.v1"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(AppLocalization.text("community_moderation_detail", fallback: "New recipes are reviewed before they appear publicly. Your saved drafts stay on this device until approved."))
                    .font(.subheadline).foregroundStyle(secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Submit a recipe").font(.headline).foregroundStyle(primary)
                    TextField("Title", text: $title).textFieldStyle(.roundedBorder)
                    TextField("Method", text: $method).textFieldStyle(.roundedBorder)
                    TextField("Recipe and notes", text: $detail, axis: .vertical).lineLimit(3...7).textFieldStyle(.roundedBorder)
                    Button(communitySharingOptOut ? "Community sharing is off" : "Submit for review") { submit() }
                        .buttonStyle(.borderedProminent).tint(accent)
                        .disabled(communitySharingOptOut || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.red) }
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(surface).clipShape(RoundedRectangle(cornerRadius: 16))

                recipeSection("Approved recipes", recipes.filter { $0.status == .approved }, showStatus: false)
                recipeSection("Your submissions", recipes.filter { $0.status != .approved }, showStatus: true)
            }.padding(.horizontal, 20).padding(.vertical, 16)
        }.background(background.ignoresSafeArea()).navigationTitle("Community recipes").onAppear { load() }
        .sheet(item: $editingRecipe) { recipe in
            NavigationStack { CommunityRecipeEditorView(recipe: recipe, accent: accent, background: background, primary: primary, secondary: secondary) { updated in
                if let index = recipes.firstIndex(where: { $0.id == updated.id }) { recipes[index] = updated; persistLocal() }
            } }
        }
    }
    private func recipeRow(_ recipe: CommunityRecipeEntry, showStatus: Bool) -> some View {
        HStack { VStack(alignment: .leading) { Text(recipe.title).font(.headline); Text("\(recipe.method) · \(recipe.detail)").font(.caption).foregroundStyle(secondary); if showStatus { Text(recipe.status.rawValue.capitalized).font(.caption.weight(.semibold)).foregroundStyle(accent) } }; Spacer(); if recipe.canEdit { Button("Edit") { editingRecipe = recipe }.buttonStyle(.tallaSecondary).tint(accent) } }
    }
    @ViewBuilder private func recipeSection(_ title: String, _ recipes: [CommunityRecipeEntry], showStatus: Bool) -> some View {
        if !recipes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.headline).foregroundStyle(primary)
                ForEach(recipes) { recipe in recipeRow(recipe, showStatus: showStatus).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(surface).clipShape(RoundedRectangle(cornerRadius: 12)) }
            }
        }
    }
    private func submit() {
        let local = CommunityRecipeEntry(title: title, method: method, detail: detail, author: "You")
        recipes.insert(local, at: 0); persistLocal(); title = ""; method = ""; detail = ""
        guard isSignedIn else { return }
        isLoading = true
        Task {
            do {
                _ = try await AccountService.submitCommunityRecipe(title: local.title, method: local.method, detail: local.detail)
                await loadFromServer()
            } catch { await MainActor.run { errorMessage = "Saved offline; it will sync when the community service is available." } }
            await MainActor.run { isLoading = false }
        }
    }
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([CommunityRecipeEntry].self, from: data) { recipes = decoded }
        guard isSignedIn else { return }
        Task { await loadFromServer() }
    }
    private func loadFromServer() async {
        do {
            let remote = try await AccountService.fetchCommunityRecipes()
            let mapped = remote.map { CommunityRecipeEntry(id: $0.id, title: $0.title, method: $0.method, detail: $0.detail, author: $0.author, status: CommunityRecipeEntry.ModerationStatus(rawValue: $0.status) ?? .pending, canEdit: $0.canEdit ?? false) }
            await MainActor.run { recipes = mapped; persistLocal() }
        } catch { }
    }
    private func persistLocal() { UserDefaults.standard.set(try? JSONEncoder().encode(recipes), forKey: key) }
}

private struct CommunityRecipeEditorView: View {
    let recipe: CommunityRecipeEntry
    let accent: Color
    let background: Color
    let primary: Color
    let secondary: Color
    let onSaved: (CommunityRecipeEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var method: String
    @State private var detail: String
    @State private var saving = false
    @State private var errorMessage: String?

    init(recipe: CommunityRecipeEntry, accent: Color, background: Color, primary: Color, secondary: Color, onSaved: @escaping (CommunityRecipeEntry) -> Void) {
        self.recipe = recipe; self.accent = accent; self.background = background; self.primary = primary; self.secondary = secondary; self.onSaved = onSaved
        _title = State(initialValue: recipe.title); _method = State(initialValue: recipe.method); _detail = State(initialValue: recipe.detail)
    }

    var body: some View {
        Form {
            Section("Recipe") { TextField("Title", text: $title); TextField("Method", text: $method); TextField("Recipe and notes", text: $detail, axis: .vertical).lineLimit(4...10) }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            Section { Button(saving ? "Saving…" : "Save changes") { save() }.disabled(saving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            Section { Text("Editing sends the recipe back for review before it appears publicly again.").font(.footnote).foregroundStyle(secondary) }
        }.scrollContentBackground(.hidden).background(background).navigationTitle("Edit recipe").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
    }

    private func save() {
        saving = true; errorMessage = nil
        Task {
            do {
                let updated = try await AccountService.updateCommunityRecipe(id: recipe.id, title: title.trimmingCharacters(in: .whitespacesAndNewlines), method: method.trimmingCharacters(in: .whitespacesAndNewlines), detail: detail.trimmingCharacters(in: .whitespacesAndNewlines))
                let entry = CommunityRecipeEntry(id: updated.id, title: updated.title, method: updated.method, detail: updated.detail, author: updated.author, status: CommunityRecipeEntry.ModerationStatus(rawValue: updated.status) ?? .pending, canEdit: updated.canEdit ?? true)
                await MainActor.run { onSaved(entry); dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not save changes. Please try again."
                    saving = false
                }
            }
        }
    }
}

struct PrivacyControlsView: View {
    let accent: Color
    let background: Color
    let primary: Color
    let secondary: Color
    @AppStorage("privacy.analytics.optOut") private var analyticsOptOut = false
    @AppStorage("privacy.personalization.optOut") private var personalizationOptOut = false
    @AppStorage("privacy.community.sharing.optOut") private var communitySharingOptOut = false

    var body: some View {
        Form {
            Section("Controls") {
                Toggle("Anonymous product analytics", isOn: Binding(get: { !analyticsOptOut }, set: { analyticsOptOut = !$0 })).tint(accent)
                Toggle("Use taste profile for recommendations", isOn: Binding(get: { !personalizationOptOut }, set: { personalizationOptOut = !$0 })).tint(accent)
                Toggle("Allow community recipe sharing", isOn: Binding(get: { !communitySharingOptOut }, set: { communitySharingOptOut = !$0 })).tint(accent)
            }
            Section("How recommendations work") { Text("Talla ranks available products using your saved taste preferences, favorites, recent orders, coffee library matches, and availability. Turning off personalization removes taste-profile weighting from new recommendations.").foregroundStyle(secondary) }
            Section("Your data") { Text("Brew sessions, cupping notes, and taste preferences remain local unless you are signed in and choose to sync them.").foregroundStyle(secondary); Button("Delete local expert data", role: .destructive) { UserDefaults.standard.removeObject(forKey: "talla.cupping.entries.v1"); UserDefaults.standard.removeObject(forKey: "talla.community.recipes.v1") } }
        }.scrollContentBackground(.hidden).background(background).navigationTitle("Privacy & explanations")
    }
}
