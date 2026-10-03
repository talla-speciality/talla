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
    func tareConnectedScale() {
        guard scaleManager.isConnected else {
            isScalePickerPresented = true
            return
        }

        scaleManager.tare()
        brewStepHaptic(strong: false)
    }

    func scaleLiveMetric(title: String, value: String) -> some View {
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

    func bluetoothScalePicker(onDone: @escaping () -> Void) -> some View {
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

    func floatingBluetoothScalePicker(onDone: @escaping () -> Void) -> some View {
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

    var bluetoothScalePickerHero: some View {
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
                        .tracking(AppLocalization.letterSpacing(1.8))
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
                    scaleBrandBadge(assetName: assetName)
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
    var bluetoothScalePickerStatus: some View {
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
                    .accessibilityIdentifier("bluetooth.interrupt")
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

    func scalePickerLiveMetric(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(AppLocalization.letterSpacing(0.8))
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

    func scalePickerStatusCard(
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
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("bluetooth.status")
        .accessibilityLabel("\(title). \(detail)")
    }

    func scalePickerScanButton(title: String) -> some View {
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
        .accessibilityIdentifier("bluetooth.reconnect")
    }

    func bluetoothScaleDeviceRow(_ scale: DiscoveredCoffeeScale) -> some View {
        Button {
            scaleManager.connect(to: scale.id)
        } label: {
            HStack(spacing: 13) {
                scaleBrandBadge(assetName: scaleBrandLogoAsset(for: scale))
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

    var scaleBrandLogoAssets: [String] {
        [
            "ScaleLogoAcaia",
            "ScaleLogoBookoo",
            "ScaleLogoGoatStory",
            "ScaleLogoHiroia",
            "ScaleLogoMantabrew",
            "ScaleLogoTimemore"
        ]
    }

    @ViewBuilder
    func scaleBrandBadge(assetName: String) -> some View {
        if assetName == "ScaleLogoTimemore" {
            Text("TIMEMORE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(AppLocalization.letterSpacing(0.5))
                .foregroundColor(brewAccentColor)
        } else {
            Image(assetName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(brewAccentColor)
        }
    }

    func scaleBrandLogoAsset(for scale: DiscoveredCoffeeScale) -> String {
        if scale.id.hasPrefix("bookoo:") { return "ScaleLogoBookoo" }
        if scale.id.hasPrefix("gina:") { return "ScaleLogoGoatStory" }
        if scale.id.hasPrefix("hiroia:") { return "ScaleLogoHiroia" }
        if scale.id.hasPrefix("mantabrew:") { return "ScaleLogoMantabrew" }
        if scale.id.hasPrefix("timemore:") { return "ScaleLogoTimemore" }
        return "ScaleLogoAcaia"
    }

    func scaleBrandDisplayName(forLogoAsset assetName: String) -> String {
        switch assetName {
        case "ScaleLogoBookoo": return "BOOKOO"
        case "ScaleLogoGoatStory": return "GOAT STORY"
        case "ScaleLogoHiroia": return "HIROIA"
        case "ScaleLogoMantabrew": return "MANTABREW"
        case "ScaleLogoTimemore": return "TIMEMORE"
        default: return "Acaia"
        }
    }

}
