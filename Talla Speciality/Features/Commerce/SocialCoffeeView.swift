import SwiftUI

struct TallaCoffeeGiftVaultView: View {
    let openGift: (TallaStoredGift) -> Void
    @Environment(\.dismiss) private var dismiss
    private var gifts: [TallaStoredGift] { TallaGiftVault.all() }

    var body: some View {
        NavigationStack {
            Group {
                if gifts.isEmpty {
                    ContentUnavailableView("No coffee gifts yet", systemImage: "gift", description: Text("Coffee gifts you open from Talla links will appear here."))
                } else {
                    List(gifts) { gift in
                        Button { openGift(gift) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "gift.fill").foregroundStyle(TallaTheme.Colors.accent)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(gift.drinkName).font(.headline)
                                    Text("Tap to check whether it is redeemable").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Coffee gifts")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct SocialCoffeeView: View {
    let accent: Color
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let products: [ContentView.Product]
    let isSignedIn: Bool
    let cartCount: Int
    let hasItemsInBag: () -> Bool
    let canContinueGiftShopping: () -> Bool
    let clearBagAction: () -> Void
    let openCartAction: () -> Void
    let accountAction: () -> Void
    let addGiftCardAction: (ContentView.Product, String, String, String, String) -> Void
    let addCoffeeGiftAction: (ContentView.Product, String, String, String) -> Void
    let addSuspendedCoffeeAction: (ContentView.Product, String, Int) -> Void
    let shopAction: (String) -> Void
    let openGroupAction: (String) -> Void

    @Environment(\.openURL) private var openURL
    @ScaledMetric(relativeTo: .subheadline) private var giftingTileHeight: CGFloat = 82
    @State private var presentedFlow: SocialCoffeeFlow?
    @State private var pendingShopCategory: String?
    @State private var isConfirmingShopReplacement = false
    @AppStorage("socialCoffee.wishListEnabled") private var isWishListEnabled = true
    @AppStorage("socialCoffee.latestTastingNote") private var tastingNote = ""
    @AppStorage("socialCoffee.latestTastingNote.visibility") private var noteVisibility = "Private"
    @AppStorage("socialCoffee.wishList") private var wishListPayload = ""
    @AppStorage("socialCoffee.followedPeople") private var followedPeoplePayload = ""
    @AppStorage("socialCoffee.publicDisplayName") private var publicDisplayName = "Coffee lover"
    @AppStorage("socialCoffee.publicRole") private var publicRole = "Friend"
    @State private var wishListDraft = ""
    @State private var selectedWishProductID = ""
    @State private var peopleSearch = ""
    @State private var showFollowingOnly = false
    @State private var hasLoadedCloudProfile = false
    @State private var syncStatus = ""
    @State private var syncTask: Task<Void, Never>?
    @State private var publicNotes: [SocialCoffeePublicNote] = []
    @State private var notesStatus = ""
    @State private var groups: [SocialCoffeeGroup] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                hero
                bagButton
                quickActions
                giftingSection
                gatheringSection
                tastingSection
                peopleSection
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 24)
        }
        .background(background.ignoresSafeArea())
        .navigationTitle(AppLocalization.text("social_coffee_title", fallback: "Social Coffee"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $presentedFlow, onDismiss: { Task { await loadGroups() } }) { flow in
            SocialCoffeeFlowSheet(flow: flow, accent: accent, background: background, surface: surface, primary: primary, secondary: secondary, openURL: openURL, products: products, isSignedIn: isSignedIn, hasItemsInBag: hasItemsInBag, clearBagAction: clearBagAction, accountAction: accountAction, addGiftCardAction: addGiftCardAction, addCoffeeGiftAction: addCoffeeGiftAction, addSuspendedCoffeeAction: addSuspendedCoffeeAction, shopAction: shopAction)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Replace current bag?", isPresented: $isConfirmingShopReplacement, titleVisibility: .visible) {
            Button("Replace bag and continue", role: .destructive) {
                let category = pendingShopCategory
                pendingShopCategory = nil
                clearBagAction()
                if let category { shopAction(category) }
            }
            Button("Keep current bag", role: .cancel) { pendingShopCategory = nil }
        } message: {
            Text("This Social Coffee gift needs its own bag. Replace the items in your current bag to continue?")
        }
        .task(id: isSignedIn) { await loadCloudProfile() }
        .task { await loadPublicNotes() }
        .task(id: isSignedIn) { await loadGroups() }
        .onChange(of: wishListPayload) { _, _ in scheduleCloudSave() }
        .onChange(of: isWishListEnabled) { _, _ in scheduleCloudSave() }
        .onChange(of: followedPeoplePayload) { _, _ in scheduleCloudSave() }
        .onChange(of: publicDisplayName) { _, _ in scheduleCloudSave() }
        .onChange(of: publicRole) { _, _ in scheduleCloudSave() }
        .onChange(of: tastingNote) { _, _ in scheduleCloudSave() }
        .onChange(of: noteVisibility) { _, _ in scheduleCloudSave() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(AppLocalization.text("social_coffee_eyebrow", fallback: "COFFEE IS BETTER SHARED"), systemImage: "person.2.fill")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(accent)
            Text(AppLocalization.text("social_coffee_hero_title", fallback: "Send a little warmth."))
                .font(.system(size: 31, weight: .semibold, design: .serif))
                .foregroundStyle(primary)
            Text(AppLocalization.text("social_coffee_hero_detail", fallback: "Gift a cup, gather your people, and keep the coffees worth remembering close."))
                .font(.subheadline)
                .foregroundStyle(secondary)
        }
    }

    private var bagButton: some View {
        Button(action: openCartAction) {
            HStack(spacing: 12) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your bag")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primary)
                    Text(cartCount == 0 ? "Ready for something to share" : "\(cartCount) item\(cartCount == 1 ? "" : "s") in your bag")
                        .font(.caption)
                        .foregroundStyle(secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(secondary)
            }
            .padding(14)
            .background(surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open bag, \(cartCount) item\(cartCount == 1 ? "" : "s")")
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            socialAction(AppLocalization.text("social_coffee_send", fallback: "Send coffee"), systemImage: "paperplane.fill", flow: .sendCoffee)
            socialAction(AppLocalization.text("social_coffee_gift_card", fallback: "Gift card"), systemImage: "gift.fill", flow: .giftCard)
            socialAction(AppLocalization.text("social_coffee_group_order", fallback: "Group order"), systemImage: "person.3.fill", flow: .groupOrder)
        }
    }

    private func socialAction(_ title: String, systemImage: String, flow: SocialCoffeeFlow) -> some View {
        Button { presentedFlow = flow } label: {
            VStack(spacing: 9) {
                Image(systemName: systemImage).font(.system(size: 18, weight: .semibold)).foregroundStyle(accent)
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(primary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 78)
            .padding(.horizontal, 4)
            .background(surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var giftingSection: some View {
        socialCard(title: AppLocalization.text("social_coffee_gifting_title", fallback: "Gifting that feels personal"), eyebrow: AppLocalization.text("social_coffee_gifting_eyebrow", fallback: "SEND WITH INTENTION"), icon: "gift") {
            Text(AppLocalization.text("social_coffee_gifting_detail", fallback: "Send a coffee by link or WhatsApp, gift beans or a brew kit, or leave a suspended coffee for whoever needs a good moment."))
                .font(.subheadline).foregroundStyle(secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                giftingAction("Send by link", systemImage: "link", highlighted: true) { presentedFlow = .sendCoffee }
                giftingAction(AppLocalization.text("social_coffee_whatsapp", fallback: "WhatsApp"), systemImage: "message.fill") { presentedFlow = .sendCoffee }
                giftingAction(AppLocalization.text("social_coffee_gift_beans", fallback: "Gift beans"), systemImage: "shippingbox.fill") { openGiftShop("coffee-beans") }
                giftingAction(AppLocalization.text("social_coffee_gift_kit", fallback: "Gift a brew kit"), systemImage: "cup.and.saucer.fill") { openGiftShop("coffee-equipment") }
            }
            Button { presentedFlow = .suspendedCoffee } label: {
                HStack { Image(systemName: "cup.and.saucer.fill"); Text(AppLocalization.text("social_coffee_suspended", fallback: "Leave a suspended coffee")); Spacer(); Image(systemName: "chevron.right").font(.caption.weight(.bold)) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primary)
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }.buttonStyle(.plain)
        }
    }

    private func giftingAction(_ title: String, systemImage: String, highlighted: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(highlighted ? Color.white : accent)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(highlighted ? Color.white : primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: giftingTileHeight)
            .background(highlighted ? accent : background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func openGiftShop(_ category: String) {
        guard hasItemsInBag() && !canContinueGiftShopping() else { shopAction(category); return }
        pendingShopCategory = category
        isConfirmingShopReplacement = true
    }

    private var gatheringSection: some View {
        socialCard(title: AppLocalization.text("social_coffee_gather_title", fallback: "Make it a gathering"), eyebrow: AppLocalization.text("social_coffee_gather_eyebrow", fallback: "MAJLIS · OFFICE · FRIENDS"), icon: "person.3") {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "building.2.fill").font(.title3).foregroundStyle(accent).frame(width: 38, height: 38).background(accent.opacity(0.13), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("social_coffee_office_title", fallback: "Office coffee, sorted")).font(.subheadline.weight(.semibold)).foregroundStyle(primary)
                    Text(AppLocalization.text("social_coffee_office_detail", fallback: "One shared order, one checkout with the host, one delivery window.")).font(.caption).foregroundStyle(secondary)
                }
                Spacer()
            }
            flowButton(AppLocalization.text("social_coffee_start_group", fallback: "Start a group order"), systemImage: "plus", flow: .groupOrder)
            if isSignedIn, !groups.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your group orders").font(.subheadline.weight(.semibold))
                    ForEach(groups) { group in
                        Button(group.name) { openGroupAction(group.id) }
                    }
                }
            }
        }
    }

    @MainActor
    private func loadGroups() async {
        guard isSignedIn else { groups = []; return }
        do {
            groups = try await AccountService.fetchSocialCoffeeGroups()
            AppWidgetSharedState.syncGroupOrderWidgetState(groups)
            TallaSpotlightIndexer.reindex(orders: [], groups: groups)
        }
        catch {
            groups = []
            AppWidgetSharedState.syncGroupOrderWidgetState([], reload: false)
        }
    }


    private var tastingSection: some View {
        socialCard(title: AppLocalization.text("social_coffee_memory_title", fallback: "Keep the good cups close"), eyebrow: AppLocalization.text("social_coffee_memory_eyebrow", fallback: "YOUR COFFEE MEMORY"), icon: "text.quote") {
            Text("Save a tasting note, keep a wish list, and choose who gets to see what you taste.")
                .font(.subheadline).foregroundStyle(secondary)
            TextField("e.g. date sweetness, cardamom, silky finish", text: $tastingNote, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            if isSignedIn {
                TextField("Name shown with a public note", text: $publicDisplayName)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
            }
            HStack {
                Image(systemName: noteVisibility == "Private" ? "lock.fill" : "globe")
            Picker("Visibility", selection: $noteVisibility) { Text("Private").tag("Private"); Text("Public").tag("Public") }
                    .pickerStyle(.segmented)
            }.font(.caption).foregroundStyle(secondary)
            if noteVisibility == "Public", !isSignedIn {
                Button(action: accountAction) { Label("Sign in to publish this note to the community", systemImage: "person.crop.circle") }
                    .font(.caption.weight(.semibold))
            }
            Label("Saved on this device", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.medium)).foregroundStyle(accent)
            if noteVisibility == "Public", !tastingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ShareLink(item: "My Talla tasting note: \(tastingNote)") {
                    Label("Share tasting note", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(accent)
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack { Text("Community tasting notes").font(.subheadline.weight(.semibold)).foregroundStyle(primary); Spacer(); Button { Task { await loadPublicNotes() } } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Refresh tasting notes") }
                if isSignedIn {
                    Picker("Notes", selection: $showFollowingOnly) {
                        Text("Everyone").tag(false)
                        Text("Following").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                if displayedNotes.isEmpty {
                    Text(notesStatus.isEmpty
                        ? showFollowingOnly ? "No notes from people you follow yet." : "No public tasting notes yet. Share yours to start the conversation."
                        : notesStatus)
                        .font(.caption).foregroundStyle(secondary)
                }
                ForEach(displayedNotes) { note in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack { Text(note.displayName).font(.caption.weight(.semibold)).foregroundStyle(accent)
                            Text(note.role ?? "Friend").font(.caption2).foregroundStyle(secondary)
                            Spacer()
                            Button(isFollowing(note.profileID) ? "Following" : "Follow") { toggleFollow(note) }
                                .font(.caption.weight(.semibold)).buttonStyle(.bordered).tint(accent).disabled(!isSignedIn)
                        }
                        Text(note.note).font(.subheadline).foregroundStyle(primary)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading).background(background, in: RoundedRectangle(cornerRadius: 12))
                }
                if !isSignedIn { Button("Sign in to follow coffee people", action: accountAction).font(.caption.weight(.semibold)) }
            }
            VStack(alignment: .leading, spacing: 9) {
                Text("Coffee wish list").font(.subheadline.weight(.semibold)).foregroundStyle(primary)
                ForEach(wishListItems, id: \.self) { coffee in
                    HStack {
                        Image(systemName: "heart.fill").foregroundStyle(accent)
                        if let product = wishListProduct(for: coffee), let url = URL(string: "https://talla.me/products/\(product.handle)") {
                            Link(product.name, destination: url).font(.subheadline).foregroundStyle(primary)
                            Image(systemName: "arrow.up.right").font(.caption2).foregroundStyle(secondary)
                        } else {
                            Text(coffee).font(.subheadline).foregroundStyle(primary)
                        }
                        Spacer()
                        Button { removeWishListItem(coffee) } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(secondary) }
                            .buttonStyle(.plain).accessibilityLabel("Remove \(wishListTitle(for: coffee)) from wish list")
                    }
                }
                if !wishListProducts.isEmpty {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(wishListProducts) { product in
                                Button(product.name) { selectedWishProductID = product.id }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(wishListProducts.first(where: { $0.id == selectedWishProductID })?.name ?? "Choose a product")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption.weight(.semibold))
                            }
                            .font(.subheadline)
                            .foregroundStyle(accent)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Add from Talla catalog")
                        Button { addWishListProduct() } label: {
                            Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(accent)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(selectedWishProductID.isEmpty)
                        .accessibilityLabel("Add selected product to wish list")
                    }
                }
                HStack {
                    TextField("Or add a custom wish", text: $wishListDraft)
                        .textFieldStyle(.roundedBorder)
                    Button { addWishListItem() } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(accent) }
                        .disabled(wishListDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityLabel("Add coffee to wish list")
                }
                if isWishListEnabled, !wishListItems.isEmpty {
                    ShareLink(item: wishListShareText) {
                        Label("Share wish list", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(accent)
                }
            }
        }
    }

    private var peopleSection: some View {
        socialCard(title: AppLocalization.text("social_coffee_people_title", fallback: "Your coffee people"), eyebrow: AppLocalization.text("social_coffee_people_eyebrow", fallback: "FOLLOW THE CRAFT"), icon: "heart") {
            Text("Find public coffee profiles and follow their tasting notes. Friend, barista, and roaster labels are self-described, not verified by Talla.")
                .font(.caption).foregroundStyle(secondary)
            if isSignedIn {
                Label(syncStatus, systemImage: hasLoadedCloudProfile ? "checkmark.icloud.fill" : "icloud")
                    .font(.caption.weight(.medium)).foregroundStyle(accent)
                Picker("My public profile", selection: $publicRole) {
                    Text("Friend").tag("Friend")
                    Text("Barista").tag("Barista")
                    Text("Roaster").tag("Roaster")
                }
                .font(.subheadline)
            } else {
                Button(action: accountAction) {
                    Label(AppLocalization.text("social_coffee_sign_in_sync", fallback: "Sign in to sync across devices"), systemImage: "person.crop.circle.badge.checkmark")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered).tint(accent)
            }
            ForEach(Array(followedPeople.enumerated()), id: \.offset) { entry in
                let person = entry.element
                HStack(spacing: 12) {
                    Text(String(person.name.prefix(1))).font(.headline).foregroundStyle(accent).frame(width: 38, height: 38).background(accent.opacity(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: 2) { Text(person.name).font(.subheadline.weight(.semibold)).foregroundStyle(primary); Text(person.profileID == nil ? "Saved name · not linked to an account" : person.role).font(.caption).foregroundStyle(secondary) }
                    Spacer()
                    Button(person.profileID == nil ? "Remove" : "Following") { removeFollow(person) }
                        .font(.caption.weight(.semibold)).buttonStyle(.bordered).tint(secondary)
                }
            }
            if isSignedIn {
                TextField("Find a public coffee person", text: $peopleSearch)
                    .textFieldStyle(.roundedBorder)
                ForEach(discoverablePeople) { person in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.displayName).font(.subheadline.weight(.semibold)).foregroundStyle(primary)
                            Text(person.role ?? "Friend").font(.caption).foregroundStyle(secondary)
                        }
                        Spacer()
                        Button(isFollowing(person.profileID) ? "Following" : "Follow") { toggleFollow(person) }
                            .buttonStyle(.bordered).tint(accent)
                    }
                }
                if discoverablePeople.isEmpty {
                    Text("Public profiles appear here when their owners publish tasting notes.")
                        .font(.caption).foregroundStyle(secondary)
                }
            }
            Toggle("Keep my wish list ready for gifting", isOn: $isWishListEnabled)
                .font(.subheadline).tint(accent)
        }
    }

    private func socialCard<Content: View>(title: String, eyebrow: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) { Text(eyebrow).font(.caption2.weight(.bold)).tracking(1.3).foregroundStyle(accent); Text(title).font(.title3.weight(.semibold)).foregroundStyle(primary) }
                Spacer(); Image(systemName: icon).foregroundStyle(accent)
            }
            content()
        }
        .padding(16)
        .background(surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func flowButton(_ title: String, systemImage: String, flow: SocialCoffeeFlow) -> some View {
        Button { presentedFlow = flow } label: { flowLabel(title, systemImage: systemImage) }
            .buttonStyle(.borderedProminent).tint(accent)
    }

    private func flowLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity)
    }

    private var wishListItems: [String] {
        wishListPayload.split(separator: "|").map(String.init)
    }

    private var wishListProducts: [ContentView.Product] {
        products.filter { $0.isAvailableForSale && !$0.isGiftCardProduct }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func wishListProduct(for item: String) -> ContentView.Product? {
        guard item.hasPrefix("product:") else { return nil }
        let handle = String(item.dropFirst("product:".count))
        return products.first { $0.handle.caseInsensitiveCompare(handle) == .orderedSame }
    }

    private func wishListTitle(for item: String) -> String {
        wishListProduct(for: item)?.name ?? item
    }

    private var wishListShareText: String {
        let lines = wishListItems.map { item in
            guard let product = wishListProduct(for: item) else { return "• \(item)" }
            return "• \(product.name): https://talla.me/products/\(product.handle)"
        }
        return "My Talla coffee wish list:\n" + lines.joined(separator: "\n")
    }

    private func addWishListProduct() {
        guard let product = wishListProducts.first(where: { $0.id == selectedWishProductID }) else { return }
        let item = "product:\(product.handle)"
        guard !wishListItems.contains(item) else { return }
        wishListPayload = (wishListItems + [item]).joined(separator: "|")
        selectedWishProductID = ""
    }

    private func addWishListItem() {
        let item = wishListDraft.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "|", with: " ")
        guard !item.isEmpty, !wishListItems.contains(where: { $0.localizedCaseInsensitiveCompare(item) == .orderedSame }) else { return }
        wishListPayload = (wishListItems + [item]).joined(separator: "|")
        wishListDraft = ""
    }

    private func removeWishListItem(_ item: String) {
        wishListPayload = wishListItems.filter { $0 != item }.joined(separator: "|")
    }

    private var followedPeople: [(name: String, role: String, profileID: String?)] {
        followedPeoplePayload.split(separator: "|").compactMap { record in
            let parts = record.split(separator: "~", maxSplits: 2).map(String.init)
            guard parts.count >= 2 else { return nil }
            return (parts[0], parts[1], parts.count > 2 && !parts[2].isEmpty ? parts[2] : nil)
        }
    }

    private var displayedNotes: [SocialCoffeePublicNote] {
        let notes = showFollowingOnly ? publicNotes.filter { isFollowing($0.profileID) } : publicNotes
        return notes.sorted {
            if isFollowing($0.profileID) != isFollowing($1.profileID) {
                return isFollowing($0.profileID)
            }
            return $0.updatedAt > $1.updatedAt
        }
    }

    private var discoverablePeople: [SocialCoffeePublicNote] {
        let search = peopleSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = search.isEmpty ? publicNotes : publicNotes.filter {
            $0.displayName.localizedCaseInsensitiveContains(search) || ($0.role ?? "").localizedCaseInsensitiveContains(search)
        }
        return Array(matching.prefix(20))
    }

    private func removeFollow(_ person: (name: String, role: String, profileID: String?)) {
        followedPeoplePayload = followedPeople.filter {
            if let profileID = person.profileID { return $0.profileID != profileID }
            return $0.profileID != nil || $0.name != person.name
        }.map { "\($0.name)~\($0.role)~\($0.profileID ?? "")" }.joined(separator: "|")
    }

    private func isFollowing(_ profileID: String) -> Bool { followedPeople.contains(where: { $0.profileID == profileID }) }

    private func toggleFollow(_ note: SocialCoffeePublicNote) {
        if isFollowing(note.profileID) { followedPeoplePayload = followedPeople.filter { $0.profileID != note.profileID }.map { "\($0.name)~\($0.role)~\($0.profileID ?? "")" }.joined(separator: "|") }
        else { followedPeoplePayload = (followedPeople.map { "\($0.name)~\($0.role)~\($0.profileID ?? "")" } + ["\(note.displayName)~\(note.role ?? "Friend")~\(note.profileID)"]).joined(separator: "|") }
    }

    @MainActor
    private func loadPublicNotes() async {
        do { publicNotes = try await AccountService.fetchPublicSocialCoffeeNotes(); notesStatus = "" }
        catch { notesStatus = "Tasting notes are temporarily unavailable." }
    }

    @MainActor
    private func loadCloudProfile() async {
        syncTask?.cancel()
        hasLoadedCloudProfile = false
        guard isSignedIn else {
            syncStatus = AppLocalization.text("social_coffee_local_only", fallback: "Saved on this device")
            return
        }
        syncStatus = AppLocalization.text("social_coffee_syncing", fallback: "Syncing your coffee circle…")
        do {
            if let profile = try await AccountService.fetchSocialCoffeeProfile() {
                wishListPayload = profile.wishList.joined(separator: "|")
                isWishListEnabled = profile.wishListEnabled
                followedPeoplePayload = profile.followedPeople.map { "\($0.name)~\($0.role)~\($0.profileID ?? "")" }.joined(separator: "|")
                publicDisplayName = profile.displayName ?? "Coffee lover"
                publicRole = profile.role ?? "Friend"
                tastingNote = profile.tastingNote
                noteVisibility = profile.tastingNoteVisibility
                await Task.yield()
            } else {
                try await AccountService.saveSocialCoffeeProfile(currentCloudProfile)
            }
            hasLoadedCloudProfile = true
            syncStatus = AppLocalization.text("social_coffee_synced", fallback: "Synced to your Talla account")
        } catch {
            hasLoadedCloudProfile = true
            syncStatus = AppLocalization.text("social_coffee_local_only", fallback: "Saved on this device")
        }
    }

    private var currentCloudProfile: SocialCoffeeProfile {
        SocialCoffeeProfile(
            displayName: publicDisplayName.trimmingCharacters(in: .whitespacesAndNewlines),
            role: publicRole,
            wishList: wishListItems,
            wishListEnabled: isWishListEnabled,
            followedPeople: followedPeople.map { SocialCoffeeFollowRecord(name: $0.name, role: $0.role, profileID: $0.profileID) },
            tastingNote: tastingNote,
            tastingNoteVisibility: noteVisibility
        )
    }

    private func scheduleCloudSave() {
        guard isSignedIn, hasLoadedCloudProfile else { return }
        let profile = currentCloudProfile
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            do {
                _ = try await AccountService.saveSocialCoffeeProfile(profile)
                await MainActor.run { syncStatus = AppLocalization.text("social_coffee_synced", fallback: "Synced to your Talla account") }
                await loadPublicNotes()
            } catch {
                await MainActor.run { syncStatus = AppLocalization.text("social_coffee_sync_failed", fallback: "Sync unavailable · saved on this device") }
            }
        }
    }
}

nonisolated enum SocialCoffeeSharedLink: Equatable {
    case group(id: String, inviteCode: String)
    case gift(orderID: String, token: String?)

    static func parse(_ url: URL) -> Self? {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              ["talla.me", "www.talla.me"].contains(url.host?.lowercased() ?? "") else { return nil }
        let path = url.pathComponents.dropFirst().map { $0.lowercased() }
        let route = path.joined(separator: "/")
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if route == "pages/group-coffee-order" || route == "app/group-order" {
            guard let id = query.first(where: { $0.name == "id" })?.value,
                  let inviteCode = query.first(where: { $0.name == "invite" })?.value,
                  id.range(of: "^[a-fA-F0-9]{16}$", options: .regularExpression) != nil,
                  inviteCode.range(of: "^[a-fA-F0-9]{32}$", options: .regularExpression) != nil else { return nil }
            return .group(id: id, inviteCode: inviteCode)
        }
        if route == "pages/coffee-gift" || route == "app/suspended-coffee" {
            guard let orderID = query.first(where: { $0.name == "order" })?.value,
                  orderID.range(of: "^[A-Za-z0-9_-]{4,128}$", options: .regularExpression) != nil else { return nil }
            let token = url.fragment
            if let token, token.range(of: "^[a-fA-F0-9]{64}$", options: .regularExpression) == nil { return nil }
            return .gift(orderID: orderID, token: token)
        }
        return nil
    }
}

struct SocialCoffeeInvite: Identifiable {
    var id: String
    let inviteCode: String
}

struct SocialCoffeePassGift: Identifiable {
    let orderID: String
    let token: String?
    var id: String { orderID }
}

struct SocialCoffeePassGiftView: View {
    let gift: SocialCoffeePassGift
    @Environment(\.dismiss) private var dismiss
    @State private var verifiedGift: SocialCoffeeGiftStatus?
    @State private var isChecking = false
    @State private var lookupError = false

    private var giftURL: URL {
        var components = URLComponents(string: "https://talla.me/pages/coffee-gift")!
        components.queryItems = [URLQueryItem(name: "order", value: gift.orderID)]
        components.fragment = gift.token
        return components.url!
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 42)).foregroundStyle(TallaTheme.Colors.ink)
                Text(verifiedGift?.status == "ready" ? "Your coffee is ready to redeem" : "Talla coffee gift")
                    .font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                Text(giftStatusMessage)
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                if isChecking { ProgressView("Checking gift status…") }
                Text(gift.orderID)
                    .font(.system(.headline, design: .monospaced)).textSelection(.enabled)
                    .padding(14).frame(maxWidth: .infinity)
                    .background(TallaTheme.Colors.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                if verifiedGift?.status == "ready" {
                    ShareLink(item: giftURL, subject: Text("A coffee from Talla"), message: Text("A verified coffee gift is waiting for you at Talla ☕️")) {
                        Label("Share this coffee gift", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(TallaTheme.Colors.accent)
                }
                if gift.token != nil {
                    Button("Refresh gift status") { Task { await refreshGiftStatus() } }
                        .disabled(isChecking)
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task(id: gift.id) { await refreshGiftStatus() }
        }
    }

    private var giftStatusMessage: String {
        if let verifiedGift {
            switch verifiedGift.status {
            case "ready": return "\(verifiedGift.drinkName) is paid and has one counter redemption remaining. Show this code to Talla staff."
            case "redeemed": return "This coffee gift has already been redeemed."
            case "expired": return "This coffee gift has expired."
            default: return "This coffee gift is not ready yet. Ask the sender to confirm payment before visiting."
            }
        }
        if gift.token == nil { return "This older link cannot confirm payment in the app. Show the code to Talla staff for verification, or ask the sender for an updated link." }
        return lookupError ? "Gift status is temporarily unavailable. Staff can verify this code before serving." : "Checking whether this coffee gift is paid and redeemable…"
    }

    @MainActor
    private func refreshGiftStatus() async {
        guard let token = gift.token else { return }
        isChecking = true
        lookupError = false
        verifiedGift = nil
        do { verifiedGift = try await AccountService.fetchSocialCoffeeGiftStatus(orderID: gift.orderID, token: token) }
        catch { verifiedGift = nil; lookupError = true }
        isChecking = false
    }
}

struct SocialCoffeeGroupInviteView: View {
    let invite: SocialCoffeeInvite
    let products: [ContentView.Product]
    let isSignedIn: Bool
    let hasItemsInBag: () -> Bool
    let clearBagAction: () -> Void
    let accountAction: () -> Void
    let checkoutAction: (SocialCoffeeGroup) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var guestName = ""
    @State private var group: SocialCoffeeGroup?
    @State private var productID = ""
    @State private var variantID = ""
    @State private var quantity = 1
    @State private var error = ""
    @State private var busy = false
    @State private var isConfirmingBagReplacement = false
    @State private var replaceBagOnCheckout = false
    private var availableProducts: [ContentView.Product] { products.filter { $0.isAvailableForSale && !$0.variants.filter(\.isAvailableForSale).isEmpty } }
    private var selectedProduct: ContentView.Product? { availableProducts.first(where: { $0.id == productID }) ?? availableProducts.first }
    private var availableVariants: [ContentView.Product.Variant] { selectedProduct?.variants.filter(\.isAvailableForSale) ?? [] }
    private var selectedVariant: ContentView.Product.Variant? { availableVariants.first(where: { $0.id == variantID }) ?? availableVariants.first }

    var body: some View {
        NavigationStack {
            Form {
                if !isSignedIn {
                    Section { Text("Sign in to join this private group order. Group details are only visible to members."); Button(action: accountAction) { Label("Sign in", systemImage: "person.crop.circle") } }
                } else if group == nil && invite.inviteCode.isEmpty {
                    Section { if error.isEmpty { ProgressView("Loading group order…") } }
                } else if group == nil {
                    Section("Join this coffee order") { TextField("Your name", text: $guestName); Text("The invite is private and expires after 48 hours.").font(.caption).foregroundStyle(.secondary) }
                    Section { Button(action: join) { if busy { ProgressView() } else { Text("Join group order") } }.disabled(busy || guestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                } else if let group {
                    Section(group.name) {
                        Text("\(group.participants.count) people · order \(group.status)").font(.subheadline)
                        ForEach(group.items) { item in
                            let name = products.first(where: { $0.id == item.productID })?.name ?? "Coffee"
                            LabeledContent("\(item.participantName) · \(name)", value: "×\(item.quantity)")
                        }
                    }
                    if group.status == "open" {
                        Section("Add yours") {
                            if !availableProducts.isEmpty {
                                Picker("Coffee", selection: $productID) { ForEach(availableProducts) { Text($0.name).tag($0.id) } }
                                Picker("Size", selection: $variantID) { ForEach(availableVariants) { Text($0.title).tag($0.id) } }
                                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...20)
                                Button(action: addItem) { if busy { ProgressView() } else { Label("Add to group", systemImage: "plus") } }.disabled(busy || selectedProduct == nil || selectedVariant == nil)
                            } else { Text("Products are loading. Please try again shortly.") }
                        }
                        if group.isHost == true, !group.items.isEmpty {
                            Section { Button(action: closeAndCheckout) { Label("Close order and review bag", systemImage: "bag.fill") }.disabled(busy) }
                        }
                    } else if group.status == "closed", group.isHost == true, !group.items.isEmpty {
                        Section { Button(action: closeAndCheckout) { Label("Resume checkout", systemImage: "bag.fill") }.disabled(busy) }
                    }
                }
                if !error.isEmpty { Section { Text(error).foregroundStyle(.red) } }
            }
            .navigationTitle("Group coffee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onChange(of: productID) { _, _ in variantID = selectedProduct?.defaultVariant?.id ?? availableVariants.first?.id ?? "" }
            .onAppear { loadExistingGroup() }
            .confirmationDialog("Replace current bag?", isPresented: $isConfirmingBagReplacement, titleVisibility: .visible) {
                Button("Replace bag and review group order", role: .destructive) {
                    replaceBagOnCheckout = true
                    closeAndCheckout()
                }
                Button("Keep current bag", role: .cancel) {}
            } message: {
                Text("This group order needs its own bag. Replace the items in your current bag to continue?")
            }
        }
    }

    private func loadExistingGroup() {
        guard invite.inviteCode.isEmpty, isSignedIn else { return }
        join()
    }

    private func join() {
        busy = true; error = ""
        Task { do { group = try await AccountService.joinSocialCoffeeGroup(id: invite.id, inviteCode: invite.inviteCode, name: guestName.trimmingCharacters(in: .whitespacesAndNewlines)); productID = availableProducts.first?.id ?? ""; variantID = selectedProduct?.defaultVariant?.id ?? availableVariants.first?.id ?? "" } catch { self.error = "This invite may be closed or expired. Please ask the host for a new link." }; busy = false }
    }

    private func addItem() {
        guard let selectedProduct, let selectedVariant else { return }
        busy = true; error = ""
        Task { do { group = try await AccountService.addSocialCoffeeGroupItem(id: invite.id, productID: selectedProduct.id, variantID: selectedVariant.id, quantity: quantity) } catch { self.error = "Couldn’t add that item. Please try again." }; busy = false }
    }

    private func closeAndCheckout() {
        guard let group else { return }
        let unavailableItems = group.items.filter { item in
            guard let product = products.first(where: { $0.id == item.productID }),
                  let variant = product.variants.first(where: { $0.id == item.variantID }) else { return true }
            return !product.isAvailableForSale || !variant.isAvailableForSale
        }
        guard unavailableItems.isEmpty else {
            replaceBagOnCheckout = false
            error = "One or more coffees in this group are no longer available. Ask the member to choose an available item before closing the order."
            return
        }
        if hasItemsInBag() && !replaceBagOnCheckout {
            isConfirmingBagReplacement = true
            return
        }
        if group.status == "closed" {
            if replaceBagOnCheckout { clearBagAction() }
            replaceBagOnCheckout = false
            checkoutAction(group)
            dismiss()
            return
        }
        busy = true; error = ""
        Task {
            do {
                let closed = try await AccountService.closeSocialCoffeeGroup(id: group.id)
                if replaceBagOnCheckout { clearBagAction() }
                replaceBagOnCheckout = false
                checkoutAction(closed)
                dismiss()
            } catch {
                replaceBagOnCheckout = false
                self.error = "Only the host can close this order. Please check your sign-in and try again."
            }
            busy = false
        }
    }
}

private enum SocialCoffeeFlow: String, Identifiable {
    case sendCoffee, giftCard, groupOrder, suspendedCoffee
    var id: String { rawValue }
    var title: String {
        switch self { case .sendCoffee: return "Send a coffee"; case .giftCard: return "Digital gift card"; case .groupOrder: return "Group order"; case .suspendedCoffee: return "Suspended coffee" }
    }
}

private struct SocialCoffeeFlowSheet: View {
    let flow: SocialCoffeeFlow
    let accent: Color
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let openURL: OpenURLAction
    let products: [ContentView.Product]
    let isSignedIn: Bool
    let hasItemsInBag: () -> Bool
    let clearBagAction: () -> Void
    let accountAction: () -> Void
    let addGiftCardAction: (ContentView.Product, String, String, String, String) -> Void
    let addCoffeeGiftAction: (ContentView.Product, String, String, String) -> Void
    let addSuspendedCoffeeAction: (ContentView.Product, String, Int) -> Void
    let shopAction: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var recipient = ""
    @State private var recipientEmail = ""
    @State private var quantity = 5
    @State private var amount = 10
    @State private var message = "A little coffee break, on me ☕️"
    @State private var selectedGiftCardID = ""
    @State private var selectedGiftVariantID = ""
    @State private var selectedSuspendedProductID = ""
    @State private var selectedSuspendedVariantID = ""
    @State private var groupName = ""
    @State private var hostName = ""
    @State private var createdGroup: SocialCoffeeGroup?
    @State private var groupError = ""
    @State private var isCreatingGroup = false
    @State private var pendingBagAction: (() -> Void)?
    @State private var isConfirmingBagReplacement = false

    private var giftCardProducts: [ContentView.Product] {
        products.filter { $0.isGiftCardProduct && $0.isAvailableForSale && $0.variants.contains(where: \.isAvailableForSale) }
            .sorted { left, right in
                if left.handle.lowercased() == "gift-card" { return true }
                if right.handle.lowercased() == "gift-card" { return false }
                return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
            }
    }

    private var selectedGiftCard: ContentView.Product? {
        giftCardProducts.first(where: { $0.id == selectedGiftCardID }) ?? giftCardProducts.first
    }

    private var availableGiftVariants: [ContentView.Product.Variant] {
        selectedGiftCard?.variants.filter(\.isAvailableForSale) ?? []
    }

    private var selectedGiftVariant: ContentView.Product.Variant? {
        availableGiftVariants.first(where: { $0.id == selectedGiftVariantID }) ?? availableGiftVariants.first
    }

    private var suspendedProducts: [ContentView.Product] {
        products.filter { ["ready-made-drinks", "summer-drinks"].contains($0.categoryKey) && $0.isAvailableForSale && $0.variants.contains(where: \.isAvailableForSale) }
    }

    private var selectedSuspendedProduct: ContentView.Product? {
        suspendedProducts.first(where: { $0.id == selectedSuspendedProductID }) ?? suspendedProducts.first
    }

    private var suspendedVariants: [ContentView.Product.Variant] { selectedSuspendedProduct?.variants.filter(\.isAvailableForSale) ?? [] }

    private var selectedSuspendedVariant: ContentView.Product.Variant? {
        suspendedVariants.first(where: { $0.id == selectedSuspendedVariantID }) ?? suspendedVariants.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section { Text(flowDetail).font(.subheadline).foregroundStyle(secondary) }
                switch flow {
                case .sendCoffee:
                    if isSignedIn {
                        Section("Who is it for?") {
                            TextField("Recipient name", text: $recipient)
                            TextField("Add a message (optional)", text: $message, axis: .vertical)
                        }
                        if !suspendedProducts.isEmpty {
                            Section("Choose their coffee") {
                                Picker("Drink", selection: $selectedSuspendedProductID) {
                                    ForEach(suspendedProducts) { product in Text(product.name).tag(product.id) }
                                }
                                Picker("Size", selection: $selectedSuspendedVariantID) {
                                    ForEach(suspendedVariants) { variant in Text(variant.title).tag(variant.id) }
                                }
                                if let variant = selectedSuspendedVariant {
                                    Text("One prepaid coffee · BHD \(variant.price) · valid for 30 days after payment")
                                        .font(.caption).foregroundStyle(secondary)
                                }
                            }
                            Section {
                                Button {
                                    guard let product = selectedSuspendedProduct, let variant = selectedSuspendedVariant else { return }
                                    beginBagAction {
                                        addCoffeeGiftAction(product, variant.id, recipient.trimmingCharacters(in: .whitespacesAndNewlines), message.trimmingCharacters(in: .whitespacesAndNewlines))
                                        dismiss()
                                    }
                                } label: { Label("Add prepaid coffee gift to bag", systemImage: "gift.fill") }
                                .disabled(recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSuspendedVariant == nil)
                                Text("After online payment, share the redeemable gift link or send it on WhatsApp from your order. Staff redeem it once at the counter.")
                                    .font(.caption).foregroundStyle(secondary)
                            }
                        } else {
                            Section("No eligible drinks available") {
                                Text("A coffee gift needs an available ready-made drink in the Talla catalog.")
                                    .font(.caption).foregroundStyle(secondary)
                            }
                        }
                    } else {
                        Section("Send a coffee") {
                            Text("Sign in to buy a redeemable coffee gift. You can share its link after payment is confirmed.")
                                .font(.subheadline).foregroundStyle(secondary)
                            Button(action: accountAction) { Label("Sign in", systemImage: "person.crop.circle") }
                        }
                    }
                case .giftCard:
                    if !giftCardProducts.isEmpty {
                        Section("Choose a gift card") {
                            Picker("Gift card", selection: $selectedGiftCardID) {
                                ForEach(giftCardProducts) { product in Text(product.name).tag(product.id) }
                            }
                            if availableGiftVariants.count > 1 {
                                Picker("Amount", selection: $selectedGiftVariantID) {
                                    ForEach(availableGiftVariants) { variant in Text("\(variant.title) · BHD \(variant.price)").tag(variant.id) }
                                }
                            } else if let variant = selectedGiftVariant {
                                LabeledContent("Amount", value: "BHD \(variant.price)")
                            }
                            TextField("Recipient name", text: $recipient)
                            TextField("Recipient email", text: $recipientEmail)
                                .textInputAutocapitalization(.never).keyboardType(.emailAddress).textContentType(.emailAddress)
                            TextField("Gift message (optional)", text: $message, axis: .vertical).lineLimit(2...4)
                            Text("Shopify sends the digital card and redemption code to the recipient when the order is fulfilled.").font(.caption).foregroundStyle(secondary)
                        }
                        Section {
                            Button {
                                guard let product = selectedGiftCard, let variant = selectedGiftVariant else { return }
                                beginBagAction {
                                    addGiftCardAction(product, variant.id, recipient, recipientEmail, message)
                                    dismiss()
                                }
                            } label: { Label("Continue to secure checkout", systemImage: "bag.badge.plus") }
                            .disabled(selectedGiftCard == nil || selectedGiftVariant == nil || !isValidEmail(recipientEmail))
                        }
                    } else {
                        Section("Choose an amount") {
                            Stepper("BHD \(amount)", value: $amount, in: 5...100, step: 5)
                            TextField("Recipient name", text: $recipient)
                            TextField("Recipient email", text: $recipientEmail).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                        }
                        Section { Button { requestGiftCard(); dismiss() } label: { Label("Request by WhatsApp", systemImage: "message.fill") }
                            Text("Talla will follow up for the recipient’s delivery details before issuing the card.").font(.caption).foregroundStyle(secondary)
                        }
                    }
                case .groupOrder:
                    if isSignedIn {
                        if let createdGroup, let inviteCode = createdGroup.inviteCode, let inviteURL = groupInviteURL(createdGroup.id, inviteCode) {
                            Section("Invite your people") {
                                Text("\(createdGroup.name) is open for 48 hours. Friends sign in before they can see or add to this order.").font(.subheadline).foregroundStyle(secondary)
                                ShareLink(item: inviteURL, subject: Text("Join our Talla coffee order"), message: Text("Add your coffee to \(createdGroup.name) ☕️")) { Label("Share group invite", systemImage: "square.and.arrow.up") }
                                Text(inviteURL.absoluteString).font(.caption2).foregroundStyle(secondary).textSelection(.enabled)
                            }
                        } else {
                            Section("Start an order") {
                                TextField("Office or gathering name", text: $groupName)
                                TextField("Your name", text: $hostName)
                                Text("Invitees must sign in to join; only group members can see the combined order.").font(.caption).foregroundStyle(secondary)
                            }
                            Section {
                                Button(action: createGroupOrder) { if isCreatingGroup { ProgressView() } else { Label("Create and share invite", systemImage: "person.3.fill") } }
                                    .disabled(isCreatingGroup || groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hostName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                if !groupError.isEmpty { Text(groupError).font(.caption).foregroundStyle(.red) }
                            }
                        }
                    } else {
                        Section("Group orders") { Text("Sign in to create or join a private group order.").font(.subheadline).foregroundStyle(secondary); Button(action: accountAction) { Label("Sign in", systemImage: "person.crop.circle") } }
                    }
                case .suspendedCoffee:
                    if isSignedIn {
                        if !suspendedProducts.isEmpty {
                            Section("Choose the coffee") {
                                Picker("Drink", selection: $selectedSuspendedProductID) { ForEach(suspendedProducts) { Text($0.name).tag($0.id) } }
                                Picker("Size", selection: $selectedSuspendedVariantID) { ForEach(suspendedVariants) { Text($0.title).tag($0.id) } }
                                Stepper("Coffees to sponsor: \(quantity)", value: $quantity, in: 1...20)
                                if let variant = selectedSuspendedVariant {
                                    Text("Total: BHD \(String(format: "%.3f", (Double(variant.price) ?? 0) * Double(quantity))) · charged at the current menu price, with no pass discount.")
                                        .font(.caption).foregroundStyle(secondary)
                                }
                            }
                            Section {
                                Text("Each sponsored coffee becomes a 30-day counter credit. Show the shareable QR from your order; Talla staff redeem each drink once and can see the remaining balance.")
                                    .font(.caption).foregroundStyle(secondary)
                                Button {
                                    guard let product = selectedSuspendedProduct, let variant = selectedSuspendedVariant else { return }
                                    beginBagAction {
                                        addSuspendedCoffeeAction(product, variant.id, quantity)
                                        dismiss()
                                    }
                                } label: { Label("Add sponsored coffees to bag", systemImage: "heart.fill") }
                                    .disabled(selectedSuspendedProduct == nil || selectedSuspendedVariant == nil)
                            }
                        } else {
                            Section("No eligible drinks available") {
                                Text("A suspended coffee needs a ready-made drink in the Talla catalog. Ask Talla to add an eligible drink before sponsoring one.").font(.caption).foregroundStyle(secondary)
                                Button { beginBagAction { shopAction("ready-made-drinks"); dismiss() } } label: { Label("Browse drinks", systemImage: "cup.and.saucer.fill") }
                            }
                        }
                    } else {
                        Section("Sign in to sponsor coffees") { Text("Sponsored credits are attached to your paid order so staff can verify and redeem each one at the counter.").font(.subheadline).foregroundStyle(secondary); Button(action: accountAction) { Label("Sign in", systemImage: "person.crop.circle") } }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(background)
            .navigationTitle(flow.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onAppear {
                if selectedGiftCardID.isEmpty { selectedGiftCardID = giftCardProducts.first?.id ?? "" }
                if selectedGiftVariantID.isEmpty { selectedGiftVariantID = selectedGiftCard?.defaultVariant?.id ?? "" }
                if selectedSuspendedProductID.isEmpty { selectedSuspendedProductID = suspendedProducts.first?.id ?? "" }
                if selectedSuspendedVariantID.isEmpty { selectedSuspendedVariantID = selectedSuspendedProduct?.defaultVariant?.id ?? suspendedVariants.first?.id ?? "" }
            }
            .onChange(of: selectedGiftCardID) { _, _ in selectedGiftVariantID = selectedGiftCard?.defaultVariant?.id ?? "" }
            .onChange(of: selectedSuspendedProductID) { _, _ in selectedSuspendedVariantID = selectedSuspendedProduct?.defaultVariant?.id ?? suspendedVariants.first?.id ?? "" }
            .confirmationDialog("Replace current bag?", isPresented: $isConfirmingBagReplacement, titleVisibility: .visible) {
                Button("Replace bag and continue", role: .destructive) {
                    let action = pendingBagAction
                    pendingBagAction = nil
                    clearBagAction()
                    action?()
                }
                Button("Keep current bag", role: .cancel) { pendingBagAction = nil }
            } message: {
                Text("This Social Coffee purchase needs its own bag. Replace the items in your current bag to continue?")
            }
        }
    }

    private func beginBagAction(_ action: @escaping () -> Void) {
        guard hasItemsInBag() else { action(); return }
        pendingBagAction = action
        isConfirmingBagReplacement = true
    }

    private var flowDetail: String {
        switch flow {
        case .sendCoffee:
            return "Buy one coffee for someone you care about, then share its redeemable gift link or send it on WhatsApp after payment."
        case .giftCard where !giftCardProducts.isEmpty:
            return "Choose an amount, enter the recipient’s email, and pay securely. Shopify sends the digital card after fulfillment."
        case .giftCard:
            return "Ask Talla to arrange a digital gift card; the team will follow up for the recipient’s delivery email."
        case .groupOrder:
            return "Create a private order and invite friends, family, or colleagues to add their coffees."
        case .suspendedCoffee:
            return "Sponsor ready-made drinks for someone to redeem at the Talla counter."
        }
    }

    private func groupInviteURL(_ id: String, _ code: String) -> URL? {
        var components = URLComponents(string: "https://talla.me/pages/group-coffee-order")
        components?.queryItems = [URLQueryItem(name: "id", value: id), URLQueryItem(name: "invite", value: code)]
        return components?.url
    }

    private func createGroupOrder() {
        isCreatingGroup = true; groupError = ""
        Task {
            do { createdGroup = try await AccountService.createSocialCoffeeGroup(name: groupName.trimmingCharacters(in: .whitespacesAndNewlines), hostName: hostName.trimmingCharacters(in: .whitespacesAndNewlines)) }
            catch { groupError = "Couldn’t create the group order. Please try again." }
            isCreatingGroup = false
        }
    }

    private func openGroupOrder() {
        let text = "Hi Talla, can you help arrange a group order for \(quantity) coffees or bags for \(recipient.isEmpty ? "our gathering" : recipient)?"
        openWhatsApp(text)
    }

    private func requestGiftCard() {
        let recipientText = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = recipientText.isEmpty ? "" : " for \(recipientText)"
        openWhatsApp("Hi Talla, can you arrange a BHD \(amount) digital coffee gift card\(detail)? Please follow up with me for the recipient’s delivery email.")
    }

    private func isValidEmail(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count <= 254, let at = normalized.firstIndex(of: "@"), at != normalized.startIndex else { return false }
        return normalized[normalized.index(after: at)...].contains(".")
    }

    private func openWhatsApp(_ text: String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "wa.me"
        components.queryItems = [URLQueryItem(name: "text", value: text)]
        if let url = components.url { openURL(url) }
    }
}
