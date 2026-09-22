import SwiftUI

struct CoffeeEducationView: View {
    @State private var selectedFamily = "Fruity"
    @State private var selectedMethod: BrewMethodLesson?
    @State private var quizChoice = ""
    @State private var extraction = 50.0
    @State private var completedLessons: Set<String> = []
    @State private var currentQuestion: EducationQuestion?
    @State private var remoteQuestions: [EducationQuestion] = []
    @State private var quizScore = 0
    @State private var questionsAnswered = 0

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
        ScrollView { VStack(alignment: .leading, spacing: 28) { intro; learningPath; flavourWheel; brewLab; knowledgeCheck; methodsSection; basics }.padding(20) }
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedMethod) { MethodLessonSheet(lesson: $0) }
            .onAppear { loadNewQuestion(); Task { await loadRemoteQuestions() } }
    }
    private var intro: some View { VStack(alignment: .leading, spacing: 8) { Text("Coffee school").font(.system(size: 34, weight: .bold, design: .rounded)); Text("Learn the bean, the brew, and everything in between.").font(.title3).foregroundStyle(.secondary) } }
    private var learningPath: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("Your learning path").font(.title2.bold()); Spacer(); Text("\(completedLessons.count)/3").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary) }
            Text("Build a better palate in three small steps.").foregroundStyle(.secondary)
            ForEach([("1", "Taste vocabulary", "Use the flavour wheel to name what you taste."), ("2", "Brew variables", "See how grind and time change extraction."), ("3", "Check your knowledge", "Answer a quick question and keep learning.")], id: \.0) { item in
                Button { withAnimation { completedLessons.insert(item.0) } } label: {
                    HStack(spacing: 12) {
                        Image(systemName: completedLessons.contains(item.0) ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(completedLessons.contains(item.0) ? .green : .orange)
                        VStack(alignment: .leading, spacing: 3) { Text(item.1).font(.headline).foregroundStyle(.primary); Text(item.2).font(.subheadline).foregroundStyle(.secondary) }
                        Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }.padding(14).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain)
            }
        }
    }
    private var selectedColor: Color { families.first(where: { $0.name == selectedFamily })?.color ?? .brown }
    private var flavourWheel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Explore the flavour wheel").font(.title2.bold())
            Text("Tap a family to see the notes you may find in your cup.").foregroundStyle(.secondary)
            ZStack {
                Circle().fill(Color(.secondarySystemBackground)).frame(width: 220, height: 220)
                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1).frame(width: 148, height: 148)
                Circle().fill(selectedColor.opacity(0.16)).frame(width: 94, height: 94)
                Text(selectedFamily).font(.headline).multilineTextAlignment(.center).frame(width: 78)
                ForEach(Array(families.enumerated()), id: \.element.name) { index, family in
                    let angle = Angle.degrees(Double(index) * 60 - 90)
                    Button { withAnimation { selectedFamily = family.name } } label: { Text(family.name).font(.caption.bold()).foregroundStyle(.primary).padding(.horizontal, 9).padding(.vertical, 7).background(family.color.opacity(selectedFamily == family.name ? 0.85 : 0.22), in: Capsule()) }.offset(x: CGFloat(cos(angle.radians)) * 135, y: CGFloat(sin(angle.radians)) * 135)
                }
            }.frame(maxWidth: .infinity).padding(.vertical, 18)
            if let family = families.first(where: { $0.name == selectedFamily }) { VStack(alignment: .leading, spacing: 10) { Text(family.description); HStack { ForEach(family.notes, id: \.self) { Text($0).font(.subheadline.weight(.semibold)).padding(.horizontal, 10).padding(.vertical, 7).background(family.color.opacity(0.16), in: Capsule()) } } }.padding(16).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18)) }
        }.padding(18).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24))
    }
    private var methodsSection: some View { VStack(alignment: .leading, spacing: 14) { Text("Every method, explained").font(.title2.bold()); Text("Choose a method to learn its character and starting point.").foregroundStyle(.secondary); LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(methods) { method in Button { selectedMethod = method } label: { VStack(alignment: .leading, spacing: 10) { Image(systemName: method.icon).font(.title2).foregroundStyle(.orange); Text(method.name).font(.headline).foregroundStyle(.primary); Text("\(method.time) · \(method.grind)").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18)) }.buttonStyle(.plain) } } } }
    private var brewLab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Brew lab").font(.title2.bold())
            Text("Move the dial to see how extraction changes. Aim for balance.").foregroundStyle(.secondary)
            Slider(value: $extraction, in: 0...100, step: 1).tint(.orange).onChange(of: extraction) { _, _ in completedLessons.insert("2") }
            HStack { Text("Under-extracted").font(.caption); Spacer(); Text("Balanced").font(.caption.bold()); Spacer(); Text("Over-extracted").font(.caption) }.foregroundStyle(.secondary)
            Text(extraction < 38 ? "Sour, sharp, or thin? Try a finer grind, hotter water, or more brew time." : extraction > 66 ? "Bitter, dry, or harsh? Try a coarser grind, cooler water, or less brew time." : "Sweet, clear, and balanced. This is the zone to look for when dialing in a recipe.")
                .font(.body).padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }.padding(18).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22))
    }
    private var knowledgeCheck: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("Quick check").font(.title2.bold()); Spacer(); Text("\(quizScore)/\(questionsAnswered)").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary) }
            if let question = currentQuestion {
                Text(question.prompt).font(.headline)
                ForEach(question.options, id: \.self) { answer in
                    Button { answerQuestion(answer, question: question) } label: {
                        HStack { Text(answer); Spacer(); if quizChoice == answer { Image(systemName: answer == question.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundStyle(answer == question.correctAnswer ? .green : .red) } }.padding(13).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 13))
                    }.buttonStyle(.plain).disabled(!quizChoice.isEmpty)
                }
                if !quizChoice.isEmpty {
                    Text(quizChoice == question.correctAnswer ? "Correct — \(question.explanation)" : "Not quite — \(question.explanation)")
                        .font(.subheadline).foregroundStyle(quizChoice == question.correctAnswer ? .green : .secondary)
                    Button("New question") { loadNewQuestion() }.buttonStyle(.borderedProminent).tint(.orange)
                }
            }
        }.padding(18).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22))
    }

    private func answerQuestion(_ answer: String, question: EducationQuestion) {
        quizChoice = answer
        questionsAnswered += 1
        if answer == question.correctAnswer { quizScore += 1 }
        completedLessons.insert("3")
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
    private var basics: some View { VStack(alignment: .leading, spacing: 12) { Text("Start with the basics").font(.title2.bold()); Text("Great coffee comes from a balance of four things: coffee, water, grind, and time.").foregroundStyle(.secondary); HStack(spacing: 10) { ForEach([("Bean", "Where it grows"), ("Roast", "How it develops"), ("Grind", "How it extracts"), ("Water", "What carries flavour")], id: \.0) { item in VStack(alignment: .leading, spacing: 4) { Text(item.0).font(.headline); Text(item.1).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) } }.padding(16).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18)) } }
}

private struct BrewMethodLesson: Identifiable { let id = UUID(); let name: String; let icon: String; let time: String; let grind: String; let description: String; let tip: String }
private struct MethodLessonSheet: View { let lesson: BrewMethodLesson; var body: some View { VStack(alignment: .leading, spacing: 18) { Image(systemName: lesson.icon).font(.system(size: 42)).foregroundStyle(.orange); Text(lesson.name).font(.largeTitle.bold()); Text(lesson.description).font(.title3); Divider(); Text("Starting point").font(.headline); Text("Time: \(lesson.time)\nGrind: \(lesson.grind)"); Text("Barista tip").font(.headline); Text(lesson.tip); Spacer() }.padding(24).presentationDetents([.medium, .large]) } }
private struct EducationContentPayload: Codable { let questions: [EducationQuestion] }
private struct EducationQuestion: Identifiable, Codable { let id: String; let prompt: String; let options: [String]; let correctAnswer: String; let explanation: String }

private let educationQuestions = [
    EducationQuestion(id: "grind-french-press", prompt: "Which grind is usually best for a French press?", options: ["Fine", "Medium-fine", "Coarse"], correctAnswer: "Coarse", explanation: "A coarse grind suits the longer immersion and helps keep the cup clear."),
    EducationQuestion(id: "water-temperature", prompt: "What does hotter water generally do?", options: ["Extracts more quickly", "Stops extraction", "Makes coffee caffeine-free"], correctAnswer: "Extracts more quickly", explanation: "Heat speeds up extraction, so very hot water can pull bitterness if the recipe is not adjusted."),
    EducationQuestion(id: "sour-cup", prompt: "Your coffee tastes sharp and sour. What is a good first adjustment?", options: ["Grind finer", "Grind much coarser", "Use less coffee and less time"], correctAnswer: "Grind finer", explanation: "A finer grind increases surface area and usually extracts more flavour."),
    EducationQuestion(id: "roast-flavour", prompt: "Which flavour is commonly associated with a darker roast?", options: ["Cocoa and roast", "Fresh cucumber", "Lemon sherbet only"], correctAnswer: "Cocoa and roast", explanation: "Longer roasting develops deeper caramelised, cocoa, and roasted notes."),
    EducationQuestion(id: "bloom", prompt: "Why do pour-over brewers bloom coffee?", options: ["To release trapped gas", "To cool the water", "To remove all caffeine"], correctAnswer: "To release trapped gas", explanation: "Blooming lets carbon dioxide escape so water can contact the grounds more evenly.")
]
