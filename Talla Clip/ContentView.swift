import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @State private var productHandle = "hawar-islands"

    private var passport: CoffeePassport { CoffeePassport.forHandle(productHandle) }
    private let gold = Color(red: 0.78, green: 0.56, blue: 0.20)
    private let espresso = Color(red: 0.08, green: 0.07, blue: 0.06)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                brandHeader
                hero
                quickFacts
                cupSection
                brewSection
                actions
                footer
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onOpenURL { updateProduct(from: $0) }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            if let url = activity.webpageURL { updateProduct(from: url) }
        }
    }

    private var brandHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("TALLA SPECIALITY").font(.caption.weight(.black)).tracking(2.2)
                Text("Coffee passport").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Label("SCANNED BAG", systemImage: "wave.3.right")
                .font(.caption2.weight(.bold)).foregroundStyle(gold)
        }
        .padding(.horizontal, 2)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if let imageURL = passport.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        if case .success(let image) = phase { image.resizable().scaledToFill() }
                        else { heroFallback }
                    }
                } else { heroFallback }
                LinearGradient(colors: [.clear, .black.opacity(0.76)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 5) {
                    Text(passport.name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.72)
                    Text("Single origin • \(passport.origin)")
                        .font(.subheadline.weight(.medium)).opacity(0.88)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 78)
            }
            .frame(height: 260)
            .clipped()

        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.13), radius: 16, y: 8)
    }

    private var quickFacts: some View {
        HStack(spacing: 0) {
            quickFact("ORIGIN", passport.origin)
            Divider().frame(height: 38)
            quickFact("METHOD", passport.method.replacingOccurrences(of: " / pour-over", with: ""))
            Divider().frame(height: 38)
            quickFact("TIME", passport.time)
        }
        .padding(.vertical, 16)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func quickFact(_ label: String, _ value: String) -> some View {
        VStack(spacing: 5) {
            Text(label).font(.caption2.weight(.bold)).tracking(1.1).foregroundStyle(.secondary)
            Text(value).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }

    private var cupSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("In the cup", detail: "What to expect")
            Text(passport.profile).font(.title3.weight(.semibold))
            VStack(alignment: .leading, spacing: 11) {
                ForEach(Array(passport.noteTags.enumerated()), id: \.offset) { index, note in
                    HStack(spacing: 10) {
                        Image(systemName: index == 0 ? "sparkles" : "circle.fill").font(.caption).foregroundStyle(gold)
                        Text(note).font(.body)
                    }
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var brewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Brew recipe", detail: passport.method)
            recipeRow("01", "Dose", passport.dose.replacingOccurrences(of: " coffee", with: ""), "circle.grid.3x3.fill")
            recipeRow("02", "Water", passport.water, "drop.fill")
            recipeRow("03", "Temperature", passport.temperature, "thermometer.medium")
            recipeRow("04", "Grind", passport.grind, "circle.lefthalf.filled")
            HStack {
                Image(systemName: "timer").foregroundStyle(gold)
                Text("Target brew time").foregroundStyle(.secondary)
                Spacer()
                Text(passport.time).fontWeight(.bold)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(gold.opacity(colorScheme == .dark ? 0.16 : 0.10), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func recipeRow(_ number: String, _ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Text(number).font(.caption.weight(.bold)).foregroundStyle(gold).frame(width: 22)
            Image(systemName: icon).frame(width: 20).foregroundStyle(.secondary)
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button { openURL(URL(string: "talla://products/\(passport.handle)")!) } label: {
                Label("Open in Talla app", systemImage: "arrow.up.forward.app.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent).tint(espresso)

            Button { openURL(URL(string: "https://talla.me/products/\(passport.handle)")!) } label: {
                Label("View product online", systemImage: "safari")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.bordered).tint(espresso)
        }
    }

    private var footer: some View {
        Text("Roasted with care in Bahrain • Talla Speciality")
            .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).multilineTextAlignment(.center)
    }

    private var heroFallback: some View {
        LinearGradient(colors: [espresso, Color(red: 0.30, green: 0.21, blue: 0.11)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func sectionHeader(_ title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.bold))
            Spacer()
            Text(detail).font(.caption.weight(.medium)).foregroundStyle(.secondary)
        }
    }

    private func updateProduct(from url: URL) {
        guard ["talla.me", "www.talla.me"].contains(url.host?.lowercased() ?? "") else { return }
        let parts = url.pathComponents
        guard let index = parts.firstIndex(where: { $0.lowercased() == "products" }), index + 1 < parts.count else { return }
        productHandle = parts[index + 1].removingPercentEncoding?.lowercased() ?? productHandle
    }
}

private struct CoffeePassport {
    let handle: String; let name: String; let origin: String; let profile: String; let notes: String
    let method: String; let dose: String; let water: String; let temperature: String; let grind: String; let time: String; let imageURL: URL?

    var noteTags: [String] {
        notes.split(separator: ",").map { note in
            let cleaned = note.trimmingCharacters(in: .whitespaces)
            return cleaned.hasPrefix("and ") ? String(cleaned.dropFirst(4)).capitalized : cleaned
        }
    }

    static func forHandle(_ handle: String) -> CoffeePassport {
        switch handle.lowercased() {
        case "muharraq": return .init(handle: "muharraq", name: "Muharraq", origin: "Ethiopia", profile: "Floral, bright, and aromatic", notes: "Floral aromatics, citrus brightness, and stone fruit", method: "V60 / pour-over", dose: "15 g coffee", water: "250 g water", temperature: "94°C", grind: "Medium-fine", time: "2:45–3:15", imageURL: URL(string: "https://talla.me/cdn/shop/files/IMG-0963.png?v=1785173744&width=800"))
        case "riffa": return .init(handle: "riffa", name: "Riffa", origin: "Yemen", profile: "Rich, deep, and wine-like", notes: "Cocoa, dried fruit, warm spice, and a lingering finish", method: "V60 / pour-over", dose: "15 g coffee", water: "240 g water", temperature: "93°C", grind: "Medium", time: "3:00–3:30", imageURL: URL(string: "https://talla.me/cdn/shop/files/IMG-0961.png?v=1785173934&width=800"))
        case "durrat-al-bahrain": return .init(handle: "durrat-al-bahrain", name: "Durrat Al-Bahrain", origin: "Brazil", profile: "Smooth, sweet, and comforting", notes: "Milk chocolate, toasted nuts, and gentle sweetness", method: "V60 / pour-over", dose: "15 g coffee", water: "240 g water", temperature: "92°C", grind: "Medium", time: "2:45–3:15", imageURL: URL(string: "https://talla.me/cdn/shop/files/IMG-5379.png?v=1785241840&width=800"))
        case "al-majd": return .init(handle: "al-majd", name: "Al-Majd", origin: "Qatar", profile: "Golden, aromatic, and delicately floral", notes: "Cardamom, saffron, rose water, and gentle floral sweetness", method: "Arabic coffee / dallah", dose: "10 g coffee", water: "150 g water", temperature: "90–92°C", grind: "Fine", time: "8–10 min", imageURL: URL(string: "https://talla.me/cdn/shop/files/IMG-5449.png?v=1785441159&width=800"))
        case "zayed": return .init(handle: "zayed", name: "Zayed", origin: "United Arab Emirates", profile: "Light, fragrant, and warmly spiced", notes: "Cardamom, saffron, golden sweetness, and delicate spice", method: "Arabic coffee / dallah", dose: "10 g coffee", water: "150 g water", temperature: "90–92°C", grind: "Fine", time: "8–10 min", imageURL: URL(string: "https://talla.me/cdn/shop/files/IMG-5448.png?v=1785441189&width=800"))
        default: return .init(handle: "hawar-islands", name: "Hawar Islands", origin: "Colombia", profile: "Balanced, bright, and smooth", notes: "Caramel, ripe fruit, and a clean finish", method: "V60 / pour-over", dose: "15 g coffee", water: "250 g water", temperature: "93°C", grind: "Medium-fine", time: "2:45–3:15", imageURL: URL(string: "https://talla.me/cdn/shop/files/IMG-0962.png?v=1785173845&width=800"))
        }
    }
}

#Preview { ContentView() }
