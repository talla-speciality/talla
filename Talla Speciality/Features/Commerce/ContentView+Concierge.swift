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
    var coffeeConciergeSheet: some View {
        ScrollView {
            coffeeConciergePanel
                .padding(18)
        }
        .background(
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .presentationDetents([.medium, .large])
    }

    var coffeeConciergePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x151515))
                    .frame(width: 30, height: 30)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppLocalization.text("coffee_concierge_title", fallback: "Coffee Concierge"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.5)
                        .textCase(.uppercase)
                        .foregroundColor(primaryTextColor)

                    Text(AppLocalization.text("coffee_concierge_detail", fallback: "Ask for a roast, gift, mood, budget, or brew style and get focused Talla picks."))
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                TextField(AppLocalization.text("coffee_concierge_placeholder", fallback: "Example: gift under 20 BHD"), text: $conciergeRequest)
                    .font(bodyFont(size: 13))
                    .foregroundColor(primaryTextColor)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .onSubmit {
                        Task { await runCoffeeConcierge() }
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task { await runCoffeeConcierge() }
                } label: {
                    Image(systemName: isRunningConcierge ? "hourglass" : "arrow.forward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x151515))
                        .frame(width: 38, height: 38)
                        .background(TallaTheme.Colors.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isRunningConcierge || products.isEmpty)
            }

#if canImport(PhotosUI)
            HStack(alignment: .center, spacing: 10) {
                PhotosPicker(selection: $conciergeImageSelection, matching: .images, photoLibrary: .shared()) {
                    Label(
                        conciergeImageData == nil
                            ? AppLocalization.text("add_image", fallback: "Add Image")
                            : AppLocalization.text("change_image", fallback: "Change Image"),
                        systemImage: "photo.badge.plus"
                    )
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(cardFillColor)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)

                if isLoadingConciergeImage {
                    ProgressView()
                        .tint(TallaTheme.Colors.accent)
                } else if conciergeImageData != nil {
                    conciergeImagePreview

                    Button {
                        conciergeImageSelection = nil
                        conciergeImageData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("remove_image", fallback: "Remove image"))
                }

                Spacer(minLength: 0)
            }
#endif

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    conciergePromptChip(AppLocalization.text("concierge_prompt_gift", fallback: "Gift box"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_arabic", fallback: "Arabic coffee"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_chocolate", fallback: "Chocolate pairing"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_tools", fallback: "Brew tools"))
                }
            }

            if let conciergeResult {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(conciergeResult.usedAppleIntelligence
                            ? AppLocalization.text("apple_intelligence_used", fallback: "Apple Intelligence")
                            : AppLocalization.text("smart_fallback_used", fallback: "Smart picks"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.4)
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        Spacer(minLength: 0)
                    }

                    Text(conciergeResult.message)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    if !conciergeProducts.isEmpty {
                        LazyVGrid(columns: productGridColumns, spacing: 14) {
                            ForEach(conciergeProducts) { product in
                                productCard(product: product, showDescription: false)
                            }
                        }
                    }
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(elevatedSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

#if canImport(PhotosUI)
    @ViewBuilder
    var conciergeImagePreview: some View {
#if canImport(UIKit)
        if let conciergeImageData, let image = UIImage(data: conciergeImageData) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.22 : 0.12), lineWidth: 1)
                )
                .accessibilityLabel(AppLocalization.text("selected_image", fallback: "Selected image"))
        }
#else
        Image(systemName: "photo.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(readableBrandGoldColor)
            .frame(width: 42, height: 42)
            .background(cardFillColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
#endif
    }
#endif

    func conciergePromptChip(_ title: String) -> some View {
        Button {
            conciergeRequest = title
            Task { await runCoffeeConcierge(requestOverride: title) }
        } label: {
            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .lineLimit(1)
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRunningConcierge || products.isEmpty)
    }

#if canImport(PhotosUI)
    @MainActor
    func loadConciergeImage(from selection: PhotosPickerItem?) async {
        guard let selection else {
            conciergeImageData = nil
            isLoadingConciergeImage = false
            return
        }

        isLoadingConciergeImage = true
        defer { isLoadingConciergeImage = false }

        do {
            conciergeImageData = try await selection.loadTransferable(type: Data.self)
        } catch {
            conciergeImageData = nil
            showToast(message: AppLocalization.text("image_load_failed", fallback: "Could not load that image"))
        }
    }
#endif

    @MainActor
    func runCoffeeConcierge(requestOverride: String? = nil) async {
        guard !isRunningConcierge else { return }
        guard !products.isEmpty else {
            showToast(message: AppLocalization.text("loading_shop", fallback: "Loading the shop"))
            return
        }

        isRunningConcierge = true
        let request = requestOverride ?? conciergeRequest
        let result = await CoffeeConciergeService.recommend(
            request: request,
            products: products,
            localeIdentifier: appLanguage.localeIdentifier,
            imageData: conciergeImageData
        )
        conciergeRequest = request
        conciergeResult = result
        delightFeedbackTrigger += 1
        isRunningConcierge = false
    }

}
