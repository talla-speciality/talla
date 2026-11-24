import SwiftUI

extension BrewingSectionView {
    var xBloomGuidedBrewView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Prepare your xBloom Studio").font(.title2.bold())
                    Text("1. Fill the tank, rinse the filter in the Omni Dripper and place your cup.")
                    Text("2. Add \(formattedWholeGram(validCoffeeAmount)) g beans. Set grind \(xBloomGrindSetting) in the xBloom app.")
                    Text("3. Enter the pour schedule below at \(xBloomTemperatureC) °C, using \(xBloomPourPattern.lowercased()) pouring and 3.0 ml/s flow.")
                    ForEach(generatedPourRows.filter { ($0.waterAdded ?? 0) > 0 }) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title).font(.headline)
                            Text("\(row.waterAdded ?? 0) ml · Pause \(xBloomPauseSeconds) s")
                        }
                    }
                    Text("Vibration: \(xBloomVibrationEnabled && xBloomPourPattern == "Spiral" ? "on" : "off"). Rotation: \(xBloomPourPattern == "Centered" ? 0 : 100) RPM.")
                    if let recipe = xBloomExportText {
                        ShareLink("Export recipe JSON", item: recipe)
                        Text("Export is for the community client; enter the recipe manually in the official xBloom app.").font(.caption)
                    } else {
                        Text("Return to Brew setup to correct the recipe before brewing. Use 1–18 g whole-number doses, 40–95 °C, and Spiral if vibration is enabled.")
                    }
                    Text("4. Start the brew on xBloom. The machine grinds and pours automatically; no hand pouring is needed.")
                    Text("5. Wait for the machine’s completion signal, remove the dripper and enjoy.")
                    Text("Talla is showing setup guidance. It is not connected to xBloom and cannot report its progress or completion.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(20)
            }
            .navigationTitle("xBloom guided brew")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isFocusedBrewPresented = false }
                }
            }
        }
    }
}
