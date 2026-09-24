import SwiftUI

struct CoffeeEducationView: View {
    private let accent = Color(red: 0.79, green: 0.59, blue: 0.35)
    @State private var selectedFamily = "Fruity"
    @State private var selectedMethod: BrewMethodLesson?
    @State private var quizChoice = ""
    @State private var extraction = 50.0
    @State private var completedLessons: Set<String> = []
    @State private var currentQuestion: EducationQuestion?
    @State private var remoteQuestions: [EducationQuestion] = []
    @State private var quizScore = 0
    @State private var questionsAnswered = 0
    @AppStorage("talla.education.completedLessons.v1") private var persistedCompletedLessons = ""
    @AppStorage("talla.education.quizScore.v1") private var persistedQuizScore = 0
    @AppStorage("talla.education.questionsAnswered.v1") private var persistedQuestionsAnswered = 0

    private let families: [(name: String, color: Color, notes: [String], description: String)] = [
        ("Fruity", Color(red: 0.89, green: 0.32, blue: 0.28), ["Berry", "Citrus", "Stone fruit"], "Bright, juicy notes often found in lightly roasted coffees."),
        ("Floral", Color(red: 0.70, green: 0.42, blue: 0.77), ["Jasmine", "Rose", "Tea-like"], "Delicate aromas with a fragrant, lifted finish."),
        ("Sweet", Color(red: 0.91, green: 0.62, blue: 0.20), ["Caramel", "Honey", "Chocolate"], "Comforting sweetness, from brown sugar to cocoa."),
        ("Nutty", Color(red: 0.62, green: 0.38, blue: 0.19), ["Almond", "Hazelnut", "Peanut"], "Toasty, rounded flavours often found in medium roasts."),
        ("Spiced", Color(red: 0.76, green: 0.24, blue: 0.13), ["Cinnamon", "Clove", "Black tea"], "Warm aromatic notes with a gently lingering finish."),
        ("Roasted", Color(red: 0.25, green: 0.16, blue: 0.12), ["Cocoa", "Tobacco", "Smoke"], "Deep, developed flavours created by darker roasting.")
    ]
    private let methods = [
        BrewMethodLesson(name: "Pour over", icon: "drop", time: "3–4 min", grind: "Medium-fine", description: "A clean, expressive cup.", tip: "Start with a 30–45 second bloom, then pour in steady pulses."),
        BrewMethodLesson(name: "French press", icon: "mug", time: "4 min", grind: "Coarse", description: "Full-bodied and textured, with more oils in the cup.", tip: "Let the coffee settle after plunging instead of stirring up the silt."),
        BrewMethodLesson(name: "AeroPress", icon: "paperplane", time: "1–2 min", grind: "Medium-fine", description: "Fast, versatile, and forgiving.", tip: "Change one variable at a time: grind, water, dose, or time."),
        BrewMethodLesson(name: "Espresso", icon: "circle.fill", time: "25–30 sec", grind: "Fine", description: "Concentrated, syrupy coffee made under pressure.", tip: "Adjust grind finer for sourness, coarser for bitterness."),
        BrewMethodLesson(name: "Cold brew", icon: "snowflake", time: "12–16 hr", grind: "Coarse", description: "Smooth, low-acidity coffee steeped slowly.", tip: "Dilute the concentrate to taste and keep it refrigerated."),
        BrewMethodLesson(name: "Moka pot", icon: "flame", time: "5–7 min", grind: "Medium-fine", description: "Rich stovetop coffee with a bold character.", tip: "Use gentle heat and remove it as soon as the upper chamber fills.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 38) {
            intro
            learningPath
            flavourWheel
            brewLab
            knowledgeCheck
            methodsSection
            basics
        }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .sheet(item: $selectedMethod) { MethodLessonSheet(lesson: $0) }
            .onAppear {
                completedLessons = Set(persistedCompletedLessons.split(separator: ",").map(String.init))
                quizScore = persistedQuizScore
                questionsAnswered = persistedQuestionsAnswered
                loadNewQuestion()
                Task { await loadRemoteQuestions() }
            }
    }
    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LEARN WITH TALLA")
                .font(.caption.weight(.bold))
                .tracking(3)
                .foregroundStyle(accent)
            Text("Coffee school")
                .font(.system(size: 44, weight: .bold, design: .serif))
            Text("Learn the bean, the brew, and everything in between.")
                .font(.title3)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button { surpriseMe() } label: {
                    Label("Surprise me", systemImage: "sparkles")
                }
                .buttonStyle(.tallaPrimary)
                .tint(accent)
                Button { withAnimation { selectedFamily = families.randomElement()?.name ?? "Fruity"; completedLessons.insert("1") }; persistProgress() } label: {
                    Label("Taste a coffee", systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(.tallaSecondary)
                .tint(accent)
            }
        }
    }
    private func surpriseMe() {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedFamily = families.randomElement()?.name ?? "Fruity"
            selectedMethod = methods.randomElement()
        }
    }
    private var learningPath: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOUR COFFEE SCHOOL LEVEL")
                            .font(.caption.weight(.bold))
                            .tracking(1.8)
                            .foregroundStyle(accent)
                        Text(learningLevel.title)
                            .font(.system(.title2, design: .serif, weight: .bold))
                        Text(learningLevel.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: learningLevel.icon)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(accent)
                        Text("\(completedLessons.count)/3")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(accent)
                    }
                }
                ProgressView(value: Double(completedLessons.count), total: 3)
                    .tint(accent)
                HStack(spacing: 8) {
                    schoolBadge(title: "First pour", earned: completedLessons.contains("1"), icon: "drop.fill")
                    schoolBadge(title: "Dialled in", earned: completedLessons.contains("2"), icon: "slider.horizontal.3")
                    schoolBadge(title: "Bean brain", earned: quizScore > 0, icon: "brain.head.profile")
                }
            }
            .padding(16)
            .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))

            HStack { sectionTitle("Your learning path"); Spacer(); Text("\(completedLessons.count)/3").font(.subheadline.weight(.bold)).foregroundStyle(accent) }
            Text("Build a better palate in three small steps.").foregroundStyle(.secondary)
            ForEach([("1", "Taste vocabulary", "Use the flavour wheel to name what you taste."), ("2", "Brew variables", "See how grind and time change extraction."), ("3", "Check your knowledge", "Answer a quick question and keep learning.")], id: \.0) { item in
                Button { withAnimation(.easeInOut(duration: 0.2)) { toggleLesson(item.0) } } label: {
                    HStack(spacing: 12) {
                        Image(systemName: completedLessons.contains(item.0) ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(completedLessons.contains(item.0) ? .green : accent)
                        VStack(alignment: .leading, spacing: 3) { Text(item.1).font(.headline).foregroundStyle(.primary); Text(item.2).font(.subheadline).foregroundStyle(.secondary) }
                        Spacer()
                        Text(completedLessons.contains(item.0) ? "Done" : "Mark done")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(completedLessons.contains(item.0) ? .green : accent)
                    }
                    .padding(.vertical, 10)
                }.buttonStyle(.plain)
            }
        }
    }
    private var learningLevel: (title: String, detail: String, icon: String) {
        switch completedLessons.count {
        case 0: return ("Beginner", "Start with flavour vocabulary and the basics.", "leaf")
        case 1...2: return ("Brewer", "You are building confident brewing instincts.", "drop.triangle")
        default: return ("Coffee Expert", "Path complete — keep exploring and teaching your palate.", "rosette")
        }
    }
    private func schoolBadge(title: String, earned: Bool, icon: String) -> some View {
        Label(title, systemImage: earned ? "checkmark.seal.fill" : icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(earned ? .green : .secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(earned ? 0.10 : 0.05), in: Capsule())
    }
    private var selectedColor: Color { families.first(where: { $0.name == selectedFamily })?.color ?? .brown }
    private var flavourWheel: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Explore the flavour wheel")
            Text("Tap a family to see the notes you may find in your cup.").foregroundStyle(.secondary)
            ZStack {
                Circle().fill(Color.primary.opacity(0.055)).frame(width: 220, height: 220)
                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1).frame(width: 148, height: 148)
                Circle().fill(selectedColor.opacity(0.16)).frame(width: 94, height: 94)
                Text(selectedFamily).font(.headline).multilineTextAlignment(.center).frame(width: 78)
                ForEach(Array(families.enumerated()), id: \.element.name) { index, family in
                    let angle = Angle.degrees(Double(index) * 60 - 90)
                    Button { withAnimation { selectedFamily = family.name } } label: { Text(family.name).font(.caption.bold()).foregroundStyle(.primary).padding(.horizontal, 9).padding(.vertical, 7).background(family.color.opacity(selectedFamily == family.name ? 0.85 : 0.22), in: Capsule()) }.offset(x: CGFloat(cos(angle.radians)) * 135, y: CGFloat(sin(angle.radians)) * 135)
                }
            }.frame(maxWidth: .infinity).padding(.vertical, 18)
            if let family = families.first(where: { $0.name == selectedFamily }) { VStack(alignment: .leading, spacing: 10) { Text(family.description); HStack { ForEach(family.notes, id: \.self) { Text($0).font(.subheadline.weight(.semibold)).padding(.horizontal, 10).padding(.vertical, 7).background(family.color.opacity(0.16), in: Capsule()) } } }.padding(16).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 18)) }
            }
    }
    private var methodsSection: some View { VStack(alignment: .leading, spacing: 14) { sectionTitle("Every method, explained"); Text("Choose a method to learn its character and starting point.").foregroundStyle(.secondary); LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(methods) { method in Button { selectedMethod = method } label: { VStack(alignment: .leading, spacing: 10) { Image(systemName: method.icon).font(.title2).foregroundStyle(accent); Text(method.name).font(.headline).foregroundStyle(.primary); Text("\(method.time) · \(method.grind)").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).educationCard(cornerRadius: 18, accent: accent) }.buttonStyle(.plain) } } } }
    private var brewLab: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Brew lab")
            Text("Move the dial to see how extraction changes. Aim for balance.").foregroundStyle(.secondary)
            Slider(value: $extraction, in: 0...100, step: 1).tint(accent).onChange(of: extraction) { _, _ in completedLessons.insert("2") }
            HStack { Text("Under-extracted").font(.caption); Spacer(); Text("Balanced").font(.caption.bold()); Spacer(); Text("Over-extracted").font(.caption) }.foregroundStyle(.secondary)
            Text(extraction < 38 ? "Sour, sharp, or thin? Try a finer grind, hotter water, or more brew time." : extraction > 66 ? "Bitter, dry, or harsh? Try a coarser grind, cooler water, or less brew time." : "Sweet, clear, and balanced. This is the zone to look for when dialing in a recipe.")
                .font(.body).padding(14).frame(maxWidth: .infinity, alignment: .leading).background(accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
        }
    }
    private var knowledgeCheck: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { sectionTitle("Quick check"); Spacer(); Text("\(quizScore)/\(questionsAnswered)").font(.subheadline.weight(.bold)).foregroundStyle(accent) }
            if let question = currentQuestion {
                Text(question.prompt).font(.headline)
                ForEach(question.options, id: \.self) { answer in
                    Button { answerQuestion(answer, question: question) } label: {
                        HStack { Text(answer); Spacer(); if quizChoice == answer { Image(systemName: answer == question.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundStyle(answer == question.correctAnswer ? .green : .red) } }.padding(13).background(Color.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 13))
                    }.buttonStyle(.plain).disabled(!quizChoice.isEmpty)
                }
                if !quizChoice.isEmpty {
                    Text(quizChoice == question.correctAnswer ? "Correct — \(question.explanation)" : "Not quite — \(question.explanation)")
                        .font(.subheadline).foregroundStyle(quizChoice == question.correctAnswer ? .green : .secondary)
                    Button("New question") { loadNewQuestion() }.buttonStyle(.tallaPrimary).tint(accent)
                }
            }
        }
    }

    private func answerQuestion(_ answer: String, question: EducationQuestion) {
        quizChoice = answer
        questionsAnswered += 1
        if answer == question.correctAnswer { quizScore += 1 }
        completedLessons.insert("3")
        persistProgress()
    }

    private func loadNewQuestion() {
        let previous = currentQuestion?.id
        let questions = remoteQuestions.isEmpty ? educationQuestions : remoteQuestions
        currentQuestion = questions.filter { $0.id != previous }.randomElement() ?? questions[0]
        quizChoice = ""
    }

    private func loadRemoteQuestions() async {
        guard let baseURL = BackendConfiguration.serviceBaseURL else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: baseURL.appending(path: "/education-content"))
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            let payload = try JSONDecoder().decode(EducationContentPayload.self, from: data)
            guard !payload.questions.isEmpty else { return }
            await MainActor.run { remoteQuestions = payload.questions; loadNewQuestion() }
        } catch { }
    }
    private func toggleLesson(_ id: String) {
        if completedLessons.contains(id) {
            completedLessons.remove(id)
        } else {
            completedLessons.insert(id)
        }
        persistProgress()
    }

    private func persistProgress() {
        persistedCompletedLessons = completedLessons.sorted().joined(separator: ",")
        persistedQuizScore = quizScore
        persistedQuestionsAnswered = questionsAnswered
        if completedLessons.count >= 3 && !UserDefaults.standard.bool(forKey: "talla.metrics.educationCompleted.v1") {
            UserDefaults.standard.set(true, forKey: "talla.metrics.educationCompleted.v1")
            TallaTelemetry.shared.track("education_path_completed", properties: ["lessons": String(completedLessons.count), "quiz_score": String(quizScore)])
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.system(.title2, design: .serif, weight: .bold))
    }

    private var basics: some View { VStack(alignment: .leading, spacing: 12) { sectionTitle("Start with the basics"); Text("Great coffee comes from a balance of four things: coffee, water, grind, and time.").foregroundStyle(.secondary); LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) { ForEach([("Bean", "Where it grows"), ("Roast", "How it develops"), ("Grind", "How it extracts"), ("Water", "What carries flavour")], id: \.0) { item in VStack(alignment: .leading, spacing: 4) { Text(item.0).font(.headline); Text(item.1).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14)) } } } }
}

private extension View {
    func educationCard(cornerRadius: CGFloat, accent: Color) -> some View {
        self
    }
}

private struct BrewMethodLesson: Identifiable { let id = UUID(); let name: String; let icon: String; let time: String; let grind: String; let description: String; let tip: String }
private struct MethodLessonSheet: View { let lesson: BrewMethodLesson; var body: some View { VStack(alignment: .leading, spacing: 18) { Image(systemName: lesson.icon).font(.system(size: 42)).foregroundStyle(Color(red: 0.79, green: 0.59, blue: 0.35)); Text(lesson.name).font(.system(.largeTitle, design: .serif, weight: .bold)); Text(lesson.description).font(.title3); Divider(); Text("Starting point").font(.headline); Text("Time: \(lesson.time)\nGrind: \(lesson.grind)"); Text("Barista tip").font(.headline); Text(lesson.tip); Spacer() }.padding(24).presentationDetents([.medium, .large]) } }
private struct EducationContentPayload: Codable { let questions: [EducationQuestion] }
private struct EducationQuestion: Identifiable, Codable { let id: String; let prompt: String; let options: [String]; let correctAnswer: String; let explanation: String }

private let educationQuestions = [
    EducationQuestion(id: "grind-french-press", prompt: "Which grind is usually best for a French press?", options: ["Fine", "Medium-fine", "Coarse"], correctAnswer: "Coarse", explanation: "A coarse grind suits the longer immersion and helps keep the cup clear."),
    EducationQuestion(id: "water-temperature", prompt: "What does hotter water generally do?", options: ["Extracts more quickly", "Stops extraction", "Makes coffee caffeine-free"], correctAnswer: "Extracts more quickly", explanation: "Heat speeds up extraction, so very hot water can pull bitterness if the recipe is not adjusted."),
    EducationQuestion(id: "sour-cup", prompt: "Your coffee tastes sharp and sour. What is a good first adjustment?", options: ["Grind finer", "Grind much coarser", "Use less coffee and less time"], correctAnswer: "Grind finer", explanation: "A finer grind increases surface area and usually extracts more flavour."),
    EducationQuestion(id: "roast-flavour", prompt: "Which flavour is commonly associated with a darker roast?", options: ["Cocoa and roast", "Fresh cucumber", "Lemon sherbet only"], correctAnswer: "Cocoa and roast", explanation: "Longer roasting develops deeper caramelised, cocoa, and roasted notes."),
    EducationQuestion(id: "bloom", prompt: "Why do pour-over brewers bloom coffee?", options: ["To release trapped gas", "To cool the water", "To remove all caffeine"], correctAnswer: "To release trapped gas", explanation: "Blooming lets carbon dioxide escape so water can contact the grounds more evenly.")
]
