import SwiftUI

/// Read-only recipe presentation shared by the full app and App Clip.
struct XBloomPassportCard: View {
    let coffeeName: String
    let method: String
    let dose: String
    let water: String
    let temperature: String

    private var supportsPourOver: Bool {
        ["v60", "pour-over", "pour over"].contains { method.localizedCaseInsensitiveContains($0) }
    }
    private func number(_ value: String) -> Double? {
        value.split(whereSeparator: { !$0.isNumber && $0 != "." }).first.flatMap { Double($0) }
    }
    private var volumes: [Int]? {
        guard let grams = number(dose), let total = number(water),
              (1...18).contains(grams), (3...500).contains(total) else { return nil }
        let bloom = min(Int((grams * 2.5).rounded()), Int(total) - 2)
        let remaining = Int(total) - bloom
        return [bloom, remaining / 2, remaining - remaining / 2]
    }
    var body: some View {
        if supportsPourOver, let volumes {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 14) {
                    Text(coffeeName).font(.subheadline).foregroundStyle(.secondary)
                    Text("Suggested Omni Dripper recipe").font(.caption).foregroundStyle(.secondary)
                    Text("Grind 62 · Spiral · Flow 3.0 ml/s · Speed 100 RPM").font(.subheadline)
                    ForEach(Array(volumes.enumerated()), id: \.offset) { index, volume in
                        HStack(alignment: .top) {
                            Text(index == 0 ? "Bloom" : "Pour \(index + 1)").fontWeight(.semibold)
                            Spacer()
                            Text("\(volume) ml · \(index == 0 ? 40 : index == 1 ? 10 : 0) s pause")
                        }.font(.subheadline)
                    }
                    Text("Vibration on for bloom only. Place a rinsed filter in the Omni Dripper, add beans and place your cup. Enter this recipe in the xBloom app, then start on the machine. xBloom handles grinding and pouring.").font(.callout)
                    Text("Suggested starting settings; not yet tested on this coffee with xBloom. Customize in Talla’s Brew tab.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Label("xBloom Studio recipe", systemImage: "cup.and.saucer.fill")
                        .font(.headline)
                    Text("\(dose) · \(water) · \(temperature)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("passport.xbloom.recipe")
        }
    }
}
