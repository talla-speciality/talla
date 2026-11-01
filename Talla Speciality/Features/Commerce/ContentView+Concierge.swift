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

struct TallaCompanionView: View {
    let isThinking: Bool
    let size: CGFloat

    @State private var isFloating = false
    @State private var sparkleRotation = false

    var body: some View {
        ZStack {
            Circle()
                .fill(TallaTheme.Colors.accent.opacity(0.12))
                .frame(width: size * 1.22, height: size * 1.22)
                .scaleEffect(isFloating ? 1.05 : 0.96)

            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: TallaTheme.Colors.accent.opacity(0.24), radius: 7, y: 4)
                .rotationEffect(.degrees(isThinking ? (isFloating ? 4 : -4) : 0))
                .scaleEffect(isThinking && isFloating ? 1.04 : 1)

            Image(systemName: "sparkle")
                .font(.system(size: max(8, size * 0.20), weight: .bold))
                .foregroundColor(TallaTheme.Colors.accent)
                .offset(x: size * 0.48, y: -size * 0.42)
                .rotationEffect(.degrees(sparkleRotation ? 18 : -18))
        }
        .frame(width: size * 1.26, height: size * 1.26)
        .onAppear {
            withAnimation(.easeInOut(duration: isThinking ? 0.65 : 1.8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                sparkleRotation = true
            }
        }
        .accessibilityLabel(isThinking ? "Talla is thinking" : "Talla companion")
    }
}

extension ContentView {
    var coffeeConciergeSheet: some View {
        VStack(spacing: 0) {
            coffeeConciergeWorkspaceHeader

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if conciergeMessages.isEmpty {
                            coffeeConciergeEmptyState
                        } else {
                            ForEach(conciergeMessages) { message in
                                conciergeMessageBubble(message)
                                    .id(message.id)
                            }

                            if let conciergeResult {
                                coffeeConciergeResultAccessory(conciergeResult)
                            }

                            if !isRunningConcierge {
                                coffeeConciergeFollowUps
                            }
                        }

                        if isRunningConcierge {
                            coffeeConciergeThinkingView
                        }

                        Color.clear
                            .frame(height: 4)
                            .id("concierge-bottom")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 14)
                }
                .onChange(of: conciergeMessages.count) { _, _ in
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                        proxy.scrollTo("concierge-bottom", anchor: .bottom)
                    }
                }
                .onChange(of: isRunningConcierge) { _, running in
                    guard !running else { return }
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                        proxy.scrollTo("concierge-bottom", anchor: .bottom)
                    }
                }
            }

            coffeeConciergeComposer
        }
        .background(
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(.ultraThinMaterial)
        .onChange(of: conciergeMessages) { _, messages in
            ConciergeChatMessage.persist(messages)
        }
    }

    var coffeeConciergeWorkspaceHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                TallaCompanionView(isThinking: isRunningConcierge, size: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("TALLA AI")
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.8)
                        .foregroundColor(readableBrandGoldColor)
                    Text("Your personal coffee coach")
                        .font(displayFont(size: 22))
                        .foregroundColor(primaryTextColor)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isRunningConcierge ? readableBrandGoldColor : Color.green)
                            .frame(width: 6, height: 6)
                        Text(isRunningConcierge ? "Thinking through your brew…" : "Ready when you are")
                            .font(labelFont(size: 10, weight: .semibold))
                            .foregroundColor(secondaryTextColor)
                    }
                }

                Spacer(minLength: 0)

                if !conciergeMessages.isEmpty {
                    Button {
                        conciergeMessages = []
                        ConciergeChatMessage.persist([])
                        conciergeResult = nil
                        conciergeLastRequest = ""
                        conciergeRequest = ""
                        conciergeImageData = nil
#if canImport(PhotosUI)
                        conciergeImageSelection = nil
#endif
                    } label: {
                        Image(systemName: "plus.bubble")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 38, height: 38)
                            .background(cardFillColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("New conversation")
                }
            }

            Text("Ask about beans, recipes, grinders, espresso, water, or your next cup.")
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 15)
        .background(elevatedSurfaceColor.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.10 : 0.08))
                .frame(height: 1)
        }
    }

    var coffeeConciergeEmptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What are we brewing today?")
                        .font(displayFont(size: 25))
                        .foregroundColor(primaryTextColor)
                    Text("Start with a question. You can keep talking naturally from there.")
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                TallaCompanionView(isThinking: false, size: 62)
            }

            VStack(spacing: 8) {
                conciergeLargePrompt("Improve my brew", icon: "drop.fill")
                conciergeLargePrompt("Fix my espresso", icon: "dial.medium.fill")
                conciergeLargePrompt("Choose coffee equipment", icon: "gearshape.fill")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [readableBrandGoldColor.opacity(isLightAppearance ? 0.14 : 0.18), cardFillColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    func conciergeLargePrompt(_ title: String, icon: String) -> some View {
        Button {
            conciergeRequest = title
            Task { await runCoffeeConcierge(requestOverride: title) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                    .frame(width: 28, height: 28)
                    .background(elevatedSurfaceColor, in: Circle())
                Text(title)
                    .font(bodyFont(size: 13).weight(.semibold))
                    .foregroundColor(primaryTextColor)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(secondaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(cardFillColor.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRunningConcierge || products.isEmpty)
    }

    var coffeeConciergeThinkingView: some View {
        VStack(spacing: 12) {
            TallaCompanionView(isThinking: true, size: 74)

            VStack(spacing: 4) {
                Text("Talla is preparing your answer")
                    .font(displayFont(size: 17))
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                Text("Looking at your coffee context and brew details…")
                    .font(bodyFont(size: 12))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            ProgressView()
                .tint(readableBrandGoldColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.12 : 0.08), lineWidth: 1)
        )
    }

    var coffeeConciergeFollowUps: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                conciergePromptChip("What should I change first?")
                conciergePromptChip("Why is that?")
                conciergePromptChip("Give me a recipe")
            }
        }
    }

    var coffeeConciergeComposer: some View {
        VStack(spacing: 9) {
#if canImport(PhotosUI)
            HStack {
                PhotosPicker(selection: $conciergeImageSelection, matching: .images, photoLibrary: .shared()) {
                    Label(
                        conciergeImageData == nil ? "Add photo" : "Photo attached",
                        systemImage: conciergeImageData == nil ? "photo.badge.plus" : "photo.fill"
                    )
                    .font(labelFont(size: 10, weight: .bold))
                    .foregroundColor(secondaryTextColor)
                }
                .buttonStyle(.plain)
                Spacer()
                if conciergeImageData != nil {
                    Button {
                        conciergeImageData = nil
                        conciergeImageSelection = nil
                    } label: {
                        Text("Remove")
                            .font(labelFont(size: 10, weight: .semibold))
                            .foregroundColor(readableBrandGoldColor)
                    }
                    .buttonStyle(.plain)
                }
            }
#endif

            HStack(spacing: 9) {
                TextField("Continue the conversation…", text: $conciergeRequest, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(bodyFont(size: 14))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1...4)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.send)
                    .onSubmit { Task { await runCoffeeConcierge() } }

                Button {
                    Task { await runCoffeeConcierge() }
                } label: {
                    Image(systemName: isRunningConcierge ? "hourglass" : "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(TallaTheme.Colors.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isRunningConcierge || products.isEmpty || conciergeRequest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.16 : 0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.top, 11)
        .padding(.bottom, 13)
        .background(elevatedSurfaceColor.opacity(0.98))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.10 : 0.08))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    func coffeeConciergeResultAccessory(_ result: CoffeeConciergeResult) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Label("Talla AI", systemImage: "sparkles")
                    .font(labelFont(size: 10, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                Spacer()
                conciergeFeedbackButton(systemImage: "hand.thumbsup", value: 1)
                conciergeFeedbackButton(systemImage: "hand.thumbsdown", value: -1)
            }

            if !result.sourceURLs.isEmpty {
                HStack(spacing: 7) {
                    Image(systemName: "link")
                    Text("Sources")
                    ForEach(Array(result.sourceURLs.prefix(3)), id: \.self) { source in
                        if let url = URL(string: source) { Link("↗", destination: url) }
                    }
                }
                .font(labelFont(size: 10, weight: .semibold))
                .foregroundColor(readableBrandGoldColor)
            }

            if result.canBuildCart && !conciergeProducts.isEmpty {
                Button { buildConciergeCart() } label: {
                    Label("Build this bag", systemImage: "bag.badge.plus")
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(TallaTheme.Colors.accent)
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if !conciergeProducts.isEmpty {
                LazyVGrid(columns: productGridColumns, spacing: 12) {
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
                .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var coffeeConciergePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(TallaTheme.Colors.accent)
                        .clipShape(Circle())

                    Image(systemName: "sparkle")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(readableBrandGoldColor)
                        .padding(3)
                        .background(elevatedSurfaceColor, in: Circle())
                        .offset(x: 2, y: -2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppLocalization.text("talla_ai_title", fallback: "Talla AI"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.5)
                        .textCase(.uppercase)
                        .foregroundColor(primaryTextColor)

                    Text(AppLocalization.text("talla_ai_detail", fallback: "Ask about beans, grinders, scales, drippers, espresso, recipes, water, or any coffee problem."))
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(isRunningConcierge ? readableBrandGoldColor : Color.green)
                            .frame(width: 6, height: 6)
                        Text(isRunningConcierge ? "Working on your coffee question…" : "Your coffee coach is ready")
                            .font(labelFont(size: 9, weight: .semibold))
                            .foregroundColor(secondaryTextColor)
                    }
                }

                if !conciergeMessages.isEmpty {
                    Button {
                        conciergeMessages = []
                        ConciergeChatMessage.persist([])
                        conciergeResult = nil
                        conciergeLastRequest = ""
                        conciergeRequest = ""
                        conciergeImageData = nil
#if canImport(PhotosUI)
                        conciergeImageSelection = nil
#endif
                    } label: {
                        Image(systemName: "plus.bubble")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(readableBrandGoldColor)
                            .frame(width: 34, height: 34)
                            .background(cardFillColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("New conversation")
                }
            }

            HStack(spacing: 8) {
                TextField(AppLocalization.text("coffee_concierge_placeholder", fallback: "Example: why does my espresso taste sour?"), text: $conciergeRequest)
                    .textFieldStyle(.plain)
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
                            .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task { await runCoffeeConcierge() }
                } label: {
                    Image(systemName: isRunningConcierge ? "hourglass" : "arrow.forward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
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
                            .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)

                if isLoadingConciergeImage {
                    ProgressView()
                        .tint(TallaTheme.Colors.ink)
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
                    conciergePromptChip(AppLocalization.text("concierge_prompt_brew", fallback: "Improve my brew"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_espresso", fallback: "Fix my espresso"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_beans", fallback: "Choose beans"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_equipment", fallback: "Coffee equipment"))
                }
            }

            if isRunningConcierge {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(readableBrandGoldColor.opacity(0.24), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(readableBrandGoldColor)
                    }
                    .rotationEffect(.degrees(isRunningConcierge ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: isRunningConcierge)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Talla is thinking")
                            .font(labelFont(size: 10, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        Text("Checking your brew method and coffee context…")
                            .font(bodyFont(size: 11))
                            .foregroundColor(secondaryTextColor)
                    }

                    Spacer(minLength: 0)
                    ProgressView()
                        .tint(readableBrandGoldColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(readableBrandGoldColor.opacity(isLightAppearance ? 0.10 : 0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if conciergeMessages.isEmpty && !isRunningConcierge {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your coffee coach is here")
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(readableBrandGoldColor)
                    Text("Ask a question, then keep going with follow-ups like ‘why?’, ‘what should I change first?’, or ‘show me the Talla option.’")
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(readableBrandGoldColor.opacity(isLightAppearance ? 0.08 : 0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            ForEach(conciergeMessages) { message in
                conciergeMessageBubble(message)
            }

            if let conciergeResult {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(readableBrandGoldColor)
                        Text("TALLA AI")
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.4)
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        Spacer(minLength: 0)
                    }

                    if conciergeMessages.isEmpty {
                        Text("Here’s the next step I’d try")
                            .font(labelFont(size: 10, weight: .semibold))
                            .foregroundColor(secondaryTextColor)

                        Text(conciergeResult.message)
                            .font(bodyFont(size: 14))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Keep going — your next question will use this context")
                            .font(labelFont(size: 10, weight: .semibold))
                            .foregroundColor(secondaryTextColor)
                    }

                    HStack(spacing: 12) {
                        Text(AppLocalization.text("concierge_helpful", fallback: "Was this helpful?"))
                            .font(labelFont(size: 9, weight: .semibold))
                            .foregroundColor(secondaryTextColor)
                        Spacer(minLength: 0)
                        conciergeFeedbackButton(systemImage: "hand.thumbsup", value: 1)
                        conciergeFeedbackButton(systemImage: "hand.thumbsdown", value: -1)
                    }

                    if !conciergeResult.sourceURLs.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 10, weight: .semibold))
                            Text(AppLocalization.text("concierge_sources", fallback: "Sources"))
                                .font(labelFont(size: 9, weight: .semibold))
                            ForEach(Array(conciergeResult.sourceURLs.prefix(3)), id: \.self) { source in
                                if let url = URL(string: source) {
                                    Link("↗", destination: url)
                                        .font(labelFont(size: 10, weight: .bold))
                                }
                            }
                        }
                        .foregroundColor(readableBrandGoldColor)
                    }

                    if !conciergeResult.giftMessageSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(AppLocalization.text("concierge_gift_message_title", fallback: "Gift message ideas"))
                                .font(labelFont(size: 9, weight: .bold))
                                .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                                .textCase(.uppercase)
                                .foregroundColor(readableBrandGoldColor)

                            ForEach(conciergeResult.giftMessageSuggestions, id: \.self) { suggestion in
                                Button {
                                    giftMessage = suggestion
                                    isGiftOrder = true
                                    showToast(message: AppLocalization.text("concierge_gift_message_added", fallback: "Gift message added to your order"))
                                } label: {
                                    Text(suggestion)
                                        .font(bodyFont(size: 12))
                                        .foregroundColor(primaryTextColor)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(9)
                                        .background(elevatedSurfaceColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if conciergeResult.canBuildCart && !conciergeProducts.isEmpty {
                        Button {
                            buildConciergeCart()
                        } label: {
                            Label(
                                AppLocalization.text("concierge_build_cart", fallback: "Build this bag"),
                                systemImage: "bag.badge.plus"
                            )
                            .font(labelFont(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(TallaTheme.Colors.accent)
                            .clipShape(Capsule(style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

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
                        .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if !conciergeMessages.isEmpty && !isRunningConcierge {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        conciergePromptChip("What should I change first?")
                        conciergePromptChip("Why is that?")
                        conciergePromptChip("Give me a recipe")
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(elevatedSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    func conciergeMessageBubble(_ message: ConciergeChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                TallaCompanionView(isThinking: false, size: 24)
            }

            Text(message.text)
                .font(bodyFont(size: 13))
                .foregroundColor(message.role == .user ? .white : primaryTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(message.role == .user ? TallaTheme.Colors.accent : cardFillColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(TallaTheme.Colors.ink.opacity(message.role == .user ? 0 : (isLightAppearance ? 0.12 : 0.08)), lineWidth: 1)
                )

            if message.role == .user {
                Spacer(minLength: 32)
            } else {
                Spacer(minLength: 22)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
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
                        .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.22 : 0.12), lineWidth: 1)
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
                        .stroke(TallaTheme.Colors.ink.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRunningConcierge || products.isEmpty)
    }

    @ViewBuilder
    func conciergeFeedbackButton(systemImage: String, value: Int) -> some View {
        Button {
            guard let conciergeResult else { return }
            CoffeeConciergeService.recordFeedback(request: conciergeLastRequest, result: conciergeResult, feedback: value)
            showToast(message: AppLocalization.text("concierge_feedback_saved", fallback: "Thanks — I’ll use that feedback."))
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(secondaryTextColor)
                .frame(width: 30, height: 28)
                .background(elevatedSurfaceColor)
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
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

        let request = (requestOverride ?? conciergeRequest).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !request.isEmpty else { return }

        let priorConversation = conciergeMessages.map { message in
            CoffeeConversationTurn(
                role: message.role == .user ? "Customer" : "Talla AI",
                text: message.text
            )
        }
        conciergeMessages.append(ConciergeChatMessage(role: .user, text: request))
        conciergeLastRequest = request
        conciergeRequest = ""
        isRunningConcierge = true

        let result = await CoffeeConciergeService.recommend(
            request: request,
            products: products,
            localeIdentifier: appLanguage.localeIdentifier,
            imageData: conciergeImageData,
            conversation: priorConversation
        )
        conciergeResult = result
        conciergeMessages.append(ConciergeChatMessage(role: .assistant, text: result.message, result: result))
        CoffeeConciergeService.recordInteraction(request: request, result: result)
        delightFeedbackTrigger += 1
        isRunningConcierge = false
    }

    @MainActor
    func buildConciergeCart() {
        let picks = conciergeProducts.filter { $0.isAvailableForSale }
        guard !picks.isEmpty else {
            showToast(message: AppLocalization.text("concierge_no_available_picks", fallback: "Those picks are not available right now"))
            return
        }

        // The Concierge only proposes catalog IDs. Existing cart and checkout code
        // still re-check variant availability, pricing, payment, redemption, and expiry.
        for product in picks {
            addToCart(product: product)
        }
        if conciergeResult?.giftMessageSuggestions.isEmpty == false {
            isGiftOrder = true
        }
        cartOpen = true
    }

}
