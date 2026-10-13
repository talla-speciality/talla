import SwiftUI
import MapKit

private struct GulfCoffeeRatingSummary: Hashable {
    let offeringID: String
    let count: Int
    let average: Double?
    let reviewCount: Int
}

private struct GulfCoffeePublicReview: Hashable, Decodable {
    let id: String
    let offeringID: String
    let rating: Int
    let note: String
    let updatedAt: String
}

private struct GulfCoffeeEvent: Identifiable, Hashable {
    let id: String
    let titleEN: String
    let titleAR: String
    let kind: String
    let startsAt: String
    let url: URL?

    var localizedTitle: String {
        AppLocalization.currentLanguage.effectiveLanguageCode == "ar" && !titleAR.isEmpty ? titleAR : titleEN
    }
}

extension ContentView {
    var gulfCoffeeMapView: some View {
        GulfCoffeeMapView(onShopCoffee: { query in
            openShop(category: "coffee-beans", searchQuery: query)
        }, onStartBrew: { offering in
            pendingBrewingCoffeeName = offering.name
            pendingBrewingCoffeeNotes = offering.detail
            pendingRecommendedRecipe = true
            openBrewing()
        })
    }
}

private struct GulfCoffeeMapView: View {
    let onShopCoffee: (String) -> Void
    let onStartBrew: (GulfCoffeeOffering) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedCountry = "All GCC"
    @State private var selectedCategory = "All"
    @State private var selectedSpot: GulfCoffeeSpot?
    @State private var ratingTarget: GulfCoffeeOffering?
    @State private var ratings: [String: Int] = [:]
    @State private var ratingSummaries: [String: GulfCoffeeRatingSummary] = [:]
    @State private var ratingNotes: [String: String] = [:]
    @State private var publicReviews: [String: [GulfCoffeePublicReview]] = [:]
    @State private var spots = GulfCoffeeSpot.seed
    @State private var passportSpotIDs: Set<String> = []
    @State private var rsvpEventIDs: Set<String> = []
    @State private var brewGuideOffering: GulfCoffeeOffering?
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.3, longitude: 51.2),
            span: MKCoordinateSpan(latitudeDelta: 10.8, longitudeDelta: 13.8)
        )
    )
    @AppStorage("gulfCoffeeMap.ratings") private var ratingStore = ""
    @AppStorage("app.appearanceMode") private var appearanceMode = "system"
    @AppStorage("gulfCoffeeMap.ratingNotes") private var ratingNotesStore = ""
    @AppStorage("gulfCoffeeMap.regionalPassport") private var regionalPassportStore = ""
    @AppStorage("gulfCoffeeMap.eventRSVPs") private var eventRSVPStore = ""
    @AppStorage("tasteMemory.saved") private var tasteMemoryStore = ""

    private let countries = ["All GCC", "Bahrain", "Saudi Arabia", "UAE", "Kuwait", "Qatar", "Oman"]
    private let categories = ["All", "Cafés", "Roasters", "Trucks", "Green beans", "Equipment", "Cuppings & workshops", "Work-friendly", "Drive-through", "Family-friendly"]

    private var pageBackground: Color { appearanceMode == "oled" ? .black : (colorScheme == .dark ? TallaTheme.Colors.darkBackground : TallaTheme.Colors.lightBackground) }
    private var surface: Color { appearanceMode == "oled" ? .black : (colorScheme == .dark ? TallaTheme.Colors.darkElevatedSurface : TallaTheme.Colors.lightElevatedSurface) }
    private var cardSurface: Color { appearanceMode == "oled" ? .black : (colorScheme == .dark ? TallaTheme.Colors.darkSurface : TallaTheme.Colors.lightSurface) }
    private var primaryText: Color { colorScheme == .dark ? Color(hex: 0xFFF7EA) : Color(hex: 0x24140D) }
    private var secondaryText: Color { colorScheme == .dark ? Color(hex: 0xBFB3A6) : Color(hex: 0x6F5B4E) }

    private var filteredSpots: [GulfCoffeeSpot] {
        spots.filter { spot in
            let matchesCountry = selectedCountry == "All GCC" || spot.country == selectedCountry
            let matchesCategory = selectedCategory == "All" || spot.categories.contains(selectedCategory)
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty || [spot.name, spot.city, spot.country, spot.neighborhood, spot.tags.joined(separator: " ")]
                .joined(separator: " ")
                .localizedCaseInsensitiveContains(query)
            return matchesCountry && matchesCategory && matchesSearch
        }
    }

    private var mappedSpots: [GulfCoffeeSpot] {
        filteredSpots.filter { !$0.isOnline && $0.isVerifiedForMap }
    }

    private var verificationSummary: String {
        let verified = filteredSpots.filter(\.isVerifiedForMap).count
        let awaiting = filteredSpots.count - verified
        return awaiting == 0 ? "\(verified) verified listings" : "\(verified) verified · \(awaiting) awaiting review"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                mapHeader
                searchField
                countryFilters
                regionOverview
                verificationNotice
                regionalPassportCard
                categoryFilters
                cityRecommendations
                recommendationSection
                directorySection
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(pageBackground)
        .navigationTitle("Gulf Coffee Map")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSpot) { spot in
            GulfCoffeeSpotDetail(spot: spot, ratings: $ratings, ratingSummaries: ratingSummaries, ratingNotes: $ratingNotes, publicReviews: publicReviews, ratingTarget: $ratingTarget, passportSpotIDs: $passportSpotIDs, rsvpEventIDs: $rsvpEventIDs, brewGuideOffering: $brewGuideOffering, onShopCoffee: onShopCoffee, onStartBrew: onStartBrew)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $ratingTarget) { offering in
            GulfCoffeeRatingSheet(offering: offering, savedRating: ratings[offering.id] ?? 0, savedNote: ratingNotes[offering.id] ?? "") { rating, note in
                ratings[offering.id] = rating
                ratingNotes[offering.id] = note
                ratingTarget = nil
                guard let spotID = spots.first(where: { offering.id.hasPrefix($0.id) })?.id,
                      !TallaAccountCredentialStore.accessToken.isEmpty else { return }
                Task {
                    try? await GulfCoffeeMapRatingService.saveRating(spotID: spotID, offeringID: offering.id, rating: rating, note: note)
                }
            }
            .presentationDetents([.height(420)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $brewGuideOffering) { offering in
            GulfCoffeeBrewGuideSheet(offering: offering, onStartBrew: onStartBrew)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            ratings = decodeRatings(ratingStore)
            ratingNotes = decodeNotes(ratingNotesStore)
            passportSpotIDs = Set(regionalPassportStore.split(separator: ",").map(String.init))
            rsvpEventIDs = Set(eventRSVPStore.split(separator: ",").map(String.init))
            TallaTelemetry.shared.track("gulf_map_viewed", properties: [
                "language": AppLocalization.currentLanguage.effectiveLanguageCode
            ])
            Task { await syncRemoteData() }
        }
        .onChange(of: ratings) { _, value in
            ratingStore = encodeRatings(value)
        }
        .onChange(of: ratingNotes) { _, value in
            ratingNotesStore = encodeNotes(value)
        }
        .onChange(of: passportSpotIDs) { _, value in
            regionalPassportStore = value.sorted().joined(separator: ",")
        }
        .onChange(of: rsvpEventIDs) { _, value in
            eventRSVPStore = value.sorted().joined(separator: ",")
        }
    }

    private var mapHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("TALLA SPECIALITY", systemImage: "cup.and.saucer.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(TallaTheme.Colors.brandSoft)
                Spacer()
                Text("GCC GUIDE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2A160E))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(TallaTheme.Colors.brandSoft, in: Capsule())
            }

            Text("Find your next\nTalla coffee stop.")
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: 0xFFF4DE))
                .fixedSize(horizontal: false, vertical: true)

            Text("A considered guide to cafés, beans and the people making coffee better across the Gulf.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(colorScheme == .dark ? Color(hex: 0xD9BFA4) : Color(hex: 0x6F5B4E))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x4A2818), Color(hex: 0x25150F)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color(hex: 0xD9B181).opacity(0.22), lineWidth: 1)
        )
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TallaTheme.Colors.ink)
            TextField("Search a city, café, bean or brew…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(primaryText)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(hex: 0x8E8176))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.08)))
    }

    private var countryFilters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explore the GCC")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(secondaryText)
                .textCase(.uppercase)
                .tracking(1.1)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(countries, id: \.self) { country in
                        filterPill(country, isSelected: selectedCountry == country) {
                            selectedCountry = country
                        }
                    }
                }
            }
            .defaultScrollAnchor(.leading)
            .scrollIndicators(.hidden)
        }
    }

    private var regionOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The Gulf, one cup at a time")
                        .font(.system(size: 23, weight: .semibold, design: .serif))
                        .foregroundStyle(primaryText)
                    Text("Start with the places Talla is watching closely.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(secondaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(filteredSpots.count) places")
                    Text("\(mappedSpots.count) map pins")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryText)
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(TallaTheme.Colors.ink)
            }

            ZStack(alignment: .bottomLeading) {
                Map(position: $mapPosition, interactionModes: [.pan, .zoom]) {
                    ForEach(mappedSpots) { spot in
                        Annotation(spot.name, coordinate: spot.coordinate) {
                            Button { selectedSpot = spot } label: {
                                Image(systemName: spot.icon)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x17110B))
                                    .frame(width: 30, height: 30)
                                    .background(TallaTheme.Colors.accent, in: Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2))
                                    .shadow(color: .black.opacity(0.32), radius: 5, y: 3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open \(spot.name)")
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                Label("Tap a pin to open a place", systemImage: "hand.tap.fill")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0xEBCB9F))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.62), in: Capsule())
                    .padding(14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 238)
            .clipped()
        }
    }

    private var verificationNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(TallaTheme.Colors.ink)
            VStack(alignment: .leading, spacing: 3) {
                Text(verificationSummary)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                Text("Only verified or link-verified places appear as map pins. Other entries are pilots awaiting admin review.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(TallaTheme.Colors.ink.opacity(0.22)))
    }

    private var categoryFilters: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Browse by what you need")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(secondaryText)
                .textCase(.uppercase)
                .tracking(1.1)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        filterPill(category, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .defaultScrollAnchor(.leading)
            .scrollIndicators(.hidden)
        }
    }

    private var regionalPassportCard: some View {
        let physicalSpots = spots.filter { !$0.isOnline && $0.isVerifiedForMap }
        let visited = passportSpotIDs.intersection(Set(physicalSpots.map(\.id))).count
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lanyardcard.fill")
                .font(.system(size: 22))
                .foregroundStyle(TallaTheme.Colors.ink)
            VStack(alignment: .leading, spacing: 5) {
                Text(AppLocalization.text("gulf_passport_title", fallback: "Your Gulf coffee passport"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                Text(AppLocalization.text("gulf_passport_detail", fallback: "Collect verified places, remember the cup, and build a taste trail across the region."))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(secondaryText)
                Text(AppLocalization.text("gulf_passport_progress", fallback: "%(visited) of %(total) places visited")
                    .replacingOccurrences(of: "%(visited)", with: "\(visited)")
                    .replacingOccurrences(of: "%(total)", with: "\(physicalSpots.count)"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(TallaTheme.Colors.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(TallaTheme.Colors.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cityRecommendations: some View {
        let cities = Dictionary(grouping: filteredSpots.filter { $0.isVerifiedForMap }, by: { $0.city })
            .sorted { $0.key < $1.key }
        return VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("gulf_city_picks", fallback: "City picks"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(secondaryText)
                .textCase(.uppercase)
                .tracking(1.1)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(cities, id: \.key) { city in
                        let citySpots = city.value
                        Button {
                            selectedCountry = citySpots.first?.country ?? selectedCountry
                            searchText = city.key
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(city.key).font(.system(size: 15, weight: .bold, design: .rounded))
                                Text("\(citySpots.count) \(AppLocalization.text("gulf_city_places", fallback: "places"))")
                                    .font(.system(size: 12, design: .rounded))
                            }
                            .foregroundStyle(primaryText)
                            .padding(12)
                            .background(surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var recommendationSection: some View {
        let picks = recommendedSpots
        return Group {
            if !picks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.text("gulf_recommendations", fallback: "Picked for your next cup"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryText)
                        .textCase(.uppercase)
                        .tracking(1.1)
                    ForEach(picks) { spot in
                        Button {
                            TallaTelemetry.shared.track("gulf_recommendation_opened", properties: ["spot_id": spot.id, "city": spot.city])
                            selectedSpot = spot
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: spot.icon)
                                    .foregroundStyle(Color(hex: 0x1A120C))
                                    .frame(width: 40, height: 40)
                                    .background(spot.tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(spot.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                    Text(spotRecommendationReason(spot))
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(secondaryText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(secondaryText)
                            }
                            .foregroundStyle(primaryText)
                            .padding(12)
                            .background(surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onAppear {
                    TallaTelemetry.shared.track("gulf_recommendations_viewed", properties: ["count": String(picks.count)])
                }
            }
        }
    }

    private var recommendedSpots: [GulfCoffeeSpot] {
        filteredSpots
            .filter(\.isVerifiedForMap)
            .sorted { lhs, rhs in
                let lhsScore = recommendationScore(lhs)
                let rhsScore = recommendationScore(rhs)
                return lhsScore == rhsScore ? lhs.name < rhs.name : lhsScore > rhsScore
            }
            .prefix(3)
            .map { $0 }
    }

    private func recommendationScore(_ spot: GulfCoffeeSpot) -> Int {
        let tasteText: String = {
            guard let data = tasteMemoryStore.data(using: .utf8),
                  let records = try? JSONDecoder().decode([ContentView.TasteMemoryRecord].self, from: data) else { return "" }
            return records.flatMap { [$0.reaction] + $0.tags }.joined(separator: " ").lowercased()
        }()
        let tasteMatch = spot.tags.contains { tasteText.localizedCaseInsensitiveContains($0.lowercased()) } ? 5 : 0
        let ratedMatch = spot.offerings.contains { (ratings[$0.id] ?? 0) >= 4 } ? 3 : 0
        return (spot.isFeatured ? 4 : 0) + tasteMatch + ratedMatch + (passportSpotIDs.contains(spot.id) ? 0 : 3) +
            (spot.offerings.isEmpty ? 0 : 1) + (spot.events.isEmpty ? 0 : 1)
    }

    private func spotRecommendationReason(_ spot: GulfCoffeeSpot) -> String {
        if !passportSpotIDs.contains(spot.id) {
            return AppLocalization.text("gulf_recommendation_new", fallback: "Verified in %@ · new passport stop").replacingOccurrences(of: "%@", with: spot.city)
        }
        if !spot.events.isEmpty {
            return AppLocalization.text("gulf_recommendation_event", fallback: "Verified in %@ · upcoming event").replacingOccurrences(of: "%@", with: spot.city)
        }
        return AppLocalization.text("gulf_recommendation_pick", fallback: "Verified in %@ · Talla pick").replacingOccurrences(of: "%@", with: spot.city)
    }

    private var directorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedCategory == "All" ? "Talla picks" : selectedCategory)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                Spacer()
                Text("Rate the item")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(TallaTheme.Colors.ink)
            }

            if filteredSpots.isEmpty {
                ContentUnavailableView("No places yet", systemImage: "mappin.slash", description: Text("Try a different country, category or search.") )
                    .foregroundStyle(secondaryText)
                    .padding(.vertical, 24)
            } else {
                ForEach(filteredSpots) { spot in
                    GulfCoffeeSpotCard(spot: spot, rating: spot.offerings.compactMap { ratings[$0.id] }.first, ratingSummaries: ratingSummaries) {
                        selectedSpot = spot
                    } onRate: { offering in
                        ratingTarget = offering
                    }
                }
            }
        }
    }

    private func filterPill(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : secondaryText)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(isSelected ? TallaTheme.Colors.accent : surface, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? .clear : Color.primary.opacity(0.10)))
        }
        .buttonStyle(.plain)
    }

    private func decodeRatings(_ storedValue: String) -> [String: Int] {
        storedValue.split(separator: "|").reduce(into: [:]) { result, entry in
            let pieces = entry.split(separator: "=", maxSplits: 1).map(String.init)
            guard pieces.count == 2, let value = Int(pieces[1]), (1...5).contains(value) else { return }
            result[pieces[0]] = value
        }
    }

    private func encodeRatings(_ values: [String: Int]) -> String {
        values.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "|")
    }

    private func decodeNotes(_ value: String) -> [String: String] {
        value.split(separator: "|", omittingEmptySubsequences: true).reduce(into: [:]) { result, item in
            let parts = item.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return }
            result[parts[0]] = parts[1].replacingOccurrences(of: "\\n", with: "\n")
        }
    }

    private func encodeNotes(_ values: [String: String]) -> String {
        values.sorted { $0.key < $1.key }.map {
            "\($0.key)=\($0.value.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "|", with: " "))"
        }.joined(separator: "|")
    }

    private func syncRemoteData() async {
        if let remoteDirectory = try? await GulfCoffeeMapRatingService.fetchDirectory() {
            // The admin directory is authoritative. Never resurrect a deleted local seed.
            let mergedSpots = remoteDirectory.compactMap { remote in
                GulfCoffeeSpot.seed.first(where: { $0.id == remote.id })?.applying(remote: remote)
            }
            await MainActor.run { spots = mergedSpots }
        }
        let summaries = (try? await GulfCoffeeMapRatingService.fetchRatingSummary()) ?? []
        let reviews = (try? await GulfCoffeeMapRatingService.fetchPublicReviews()) ?? []
        await MainActor.run {
            ratingSummaries = Dictionary(uniqueKeysWithValues: summaries.map {
                ($0.offeringID, GulfCoffeeRatingSummary(offeringID: $0.offeringID, count: $0.count, average: $0.average, reviewCount: $0.reviewCount))
            })
            publicReviews = Dictionary(grouping: reviews, by: \.offeringID)
        }
        if !TallaAccountCredentialStore.accessToken.isEmpty,
           let remoteVisits = try? await LoyaltyService.fetchGulfCoffeeVisits() {
            await MainActor.run { passportSpotIDs.formUnion(remoteVisits) }
        }
        if !TallaAccountCredentialStore.accessToken.isEmpty,
           let remoteRSVPs = try? await LoyaltyService.fetchGulfCoffeeEventRSVPs() {
            await MainActor.run { rsvpEventIDs.formUnion(remoteRSVPs) }
        }
        guard !TallaAccountCredentialStore.accessToken.isEmpty,
              let remoteRatings = try? await GulfCoffeeMapRatingService.fetchRatings() else { return }
        var merged = ratings
        var mergedNotes = ratingNotes
        for rating in remoteRatings {
            merged[rating.offeringID] = rating.rating
            mergedNotes[rating.offeringID] = rating.note ?? ""
        }
        await MainActor.run {
            ratings = merged
            ratingNotes = mergedNotes
        }
    }
}

private struct GulfCoffeeSpotCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("app.appearanceMode") private var appearanceMode = "system"
    let spot: GulfCoffeeSpot
    let rating: Int?
    let ratingSummaries: [String: GulfCoffeeRatingSummary]
    let onOpen: () -> Void
    let onRate: (GulfCoffeeOffering) -> Void

    private var cardSurface: Color { appearanceMode == "oled" ? .black : (colorScheme == .dark ? TallaTheme.Colors.darkSurface : TallaTheme.Colors.lightSurface) }
    private var primaryText: Color { colorScheme == .dark ? Color(hex: 0xFFF7EA) : Color(hex: 0x24140D) }
    private var secondaryText: Color { colorScheme == .dark ? Color(hex: 0xBFB3A6) : Color(hex: 0x6F5B4E) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                        GulfCoffeeStoreLogo(spot: spot)
                    }
                    .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Text(spot.name)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                            if spot.isFeatured {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(TallaTheme.Colors.ink)
                            }
                        }
                        Text("\(spot.city) · \(spot.country)")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(secondaryText)
                        Text(spot.relationshipLabel)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(TallaTheme.Colors.ink)
                        if !spot.isVerifiedForMap {
                            Label("Awaiting verification", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(TallaTheme.Colors.brandSoft)
                        }
                        Text(spot.shortDescription)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(TallaTheme.Colors.ink)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0x87786B))
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Label(spot.primaryCategory, systemImage: "tag").lineLimit(1)
                    Spacer(minLength: 4)
                    if let rating {
                        Label("You \(rating)/5", systemImage: "star.fill")
                            .foregroundStyle(TallaTheme.Colors.ink)
                    }
                }
                HStack(spacing: 8) {
                    Label(spot.neighborhood, systemImage: "mappin.and.ellipse").lineLimit(1)
                    Spacer(minLength: 4)
                    if let summary = spot.offerings.compactMap({ ratingSummaries[$0.id] }).first,
                       let average = summary.average {
                        Label(String(format: "%.1f · %d", average, summary.count), systemImage: "person.2.fill")
                            .foregroundStyle(TallaTheme.Colors.ink)
                    }
                }
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(spot.offerings) { offering in
                        Button { onRate(offering) } label: {
                            HStack(spacing: 6) {
                                Image(systemName: offering.kind.icon)
                                Text(offering.name)
                                Image(systemName: "star")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(colorScheme == .dark ? Color(hex: 0xEED9B9) : Color(hex: 0x6F4328))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 9)
                            .background(colorScheme == .dark ? Color(hex: 0x292019) : Color(hex: 0xF1E0C9), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollClipDisabled()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.primary.opacity(0.09)))
    }
}

private struct GulfCoffeeStoreLogo: View {
    let spot: GulfCoffeeSpot

    var body: some View {
        if spot.id == "bhr-seef" {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .padding(11)
                .accessibilityLabel("Talla Speciality logo")
        } else if spot.id == "not-just-beans" {
            Image("NotJustBeansLogo")
                .resizable()
                .scaledToFit()
                .padding(8)
                .accessibilityLabel("Not Just Beans logo")
        } else if spot.id == "hambella-riffa" {
            Image("HambellaLogo")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(7)
                .accessibilityLabel("Hambella logo")
        } else if spot.id == "tumma-roast-zinj" {
            Image("TummaRoastLogo")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(7)
                .accessibilityLabel("Tumma Roast logo")
        } else if let logoURL = spot.logoURL, let url = URL(string: logoURL) {
            AsyncImage(url: url, transaction: Transaction(animation: nil)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFit().padding(10)
                default: monogram
                }
            }
            .accessibilityLabel("\(spot.name) logo")
        } else {
            monogram
        }
    }

    private var monogram: some View {
        VStack(spacing: 2) {
            Text(spot.brandMonogram)
                .font(.system(size: spot.brandMonogram.count > 1 ? 19 : 29, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: 0x1A120C))
            if spot.brandMonogram.count > 1 {
                Text(spot.name.uppercased())
                    .font(.system(size: 6, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Color(hex: 0x1A120C).opacity(0.72))
            }
        }
        .padding(8)
    }
}

private struct GulfCoffeeSpotDetail: View {
    let spot: GulfCoffeeSpot
    @Binding var ratings: [String: Int]
    let ratingSummaries: [String: GulfCoffeeRatingSummary]
    @Binding var ratingNotes: [String: String]
    let publicReviews: [String: [GulfCoffeePublicReview]]
    @Binding var ratingTarget: GulfCoffeeOffering?
    @Binding var passportSpotIDs: Set<String>
    @Binding var rsvpEventIDs: Set<String>
    @Binding var brewGuideOffering: GulfCoffeeOffering?
    let onShopCoffee: (String) -> Void
    let onStartBrew: (GulfCoffeeOffering) -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        Image(systemName: spot.icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color(hex: 0x1A120C))
                            .frame(width: 64, height: 64)
                            .background(spot.tint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(spot.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("\(spot.city), \(spot.country)")
                                .foregroundStyle(.secondary)
                            Label(spot.trustLabel, systemImage: spot.isVerifiedForMap ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(spot.isVerifiedForMap ? .green : .orange)
                            if let freshness = spot.profileFreshnessLabel {
                                Label(freshness, systemImage: "clock.arrow.circlepath")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        Button {
                            let adding = !passportSpotIDs.contains(spot.id)
                            if adding {
                                passportSpotIDs.insert(spot.id)
                                TallaTelemetry.shared.track("gulf_passport_visit_started", properties: ["spot_id": spot.id, "city": spot.city])
                                guard !TallaAccountCredentialStore.accessToken.isEmpty else { return }
                                Task {
                                    if (try? await LoyaltyService.recordGulfCoffeeVisit(spotID: spot.id)) != nil {
                                        TallaTelemetry.shared.track("gulf_passport_visit_synced", properties: ["spot_id": spot.id])
                                    }
                                }
                            } else {
                                passportSpotIDs.remove(spot.id)
                            }
                        } label: {
                            Label(passportSpotIDs.contains(spot.id)
                                  ? AppLocalization.text("gulf_passport_visited", fallback: "Visited")
                                  : AppLocalization.text("gulf_passport_mark", fallback: "Add to passport"),
                                  systemImage: passportSpotIDs.contains(spot.id) ? "checkmark.circle.fill" : "plus.circle")
                        }
                        .buttonStyle(.tallaSecondary)
                        .tint(TallaTheme.Colors.readableAccentLight)
                        if spot.categories.contains("Cuppings & workshops") {
                            Label(AppLocalization.text("gulf_events_available", fallback: "Events listed"), systemImage: "calendar.badge.clock")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(spot.longDescription)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.secondary)
                    if !spot.localizedDescription.isEmpty {
                        Text(spot.localizedDescription)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    if !spot.localizedTastingNotes.isEmpty {
                        Label(spot.localizedTastingNotes, systemImage: "nose")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(TallaTheme.Colors.readableAccentLight)
                    }
                    if !spot.events.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(AppLocalization.text("gulf_upcoming_events", fallback: "Upcoming at this place"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            ForEach(spot.events) { event in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: event.kind.localizedCaseInsensitiveContains("cup") ? "wineglass" : "calendar")
                                        .foregroundStyle(TallaTheme.Colors.readableAccentLight)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(event.localizedTitle).font(.system(size: 14, weight: .semibold, design: .rounded))
                                        Text(event.startsAt).font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                    Button {
                                        guard !rsvpEventIDs.contains(event.id) else { return }
                                        rsvpEventIDs.insert(event.id)
                                        TallaTelemetry.shared.track("gulf_event_rsvp_started", properties: ["event_id": event.id, "spot_id": spot.id])
                                        guard !TallaAccountCredentialStore.accessToken.isEmpty else { return }
                                        Task {
                                            if (try? await LoyaltyService.rsvpGulfCoffeeEvent(eventID: event.id, spotID: spot.id)) != nil {
                                                TallaTelemetry.shared.track("gulf_event_rsvp_synced", properties: ["event_id": event.id])
                                            }
                                        }
                                    } label: {
                                        Label(rsvpEventIDs.contains(event.id)
                                              ? AppLocalization.text("gulf_event_saved", fallback: "Saved")
                                              : AppLocalization.text("gulf_event_save", fallback: "Save"),
                                              systemImage: rsvpEventIDs.contains(event.id) ? "checkmark" : "calendar.badge.plus")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(TallaTheme.Colors.readableAccentLight)
                                    if let url = event.url {
                                        Button { openURL(url) } label: { Image(systemName: "arrow.up.right.square") }
                                            .buttonStyle(.plain)
                                            .foregroundStyle(TallaTheme.Colors.readableAccentLight)
                                    }
                                }
                                .padding(12)
                                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    if !spot.address.isEmpty || !spot.phone.isEmpty || !spot.hours.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            if !spot.address.isEmpty { Label(spot.address, systemImage: "mappin.and.ellipse") }
                            if !spot.phone.isEmpty { Label(spot.phone, systemImage: "phone") }
                            if !spot.hours.isEmpty { Label(spot.hours, systemImage: "clock") }
                        }
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                    }
                    if let websiteURL = spot.websiteURL {
                        Button {
                            openURL(websiteURL)
                        } label: {
                            Label(spot.isOnline ? "Open online store" : "Open location", systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.tallaPrimary)
                        .tint(TallaTheme.Colors.readableAccentLight)
                    }
                    if let sourceURL = URL(string: spot.sourceURL), !spot.sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            openURL(sourceURL)
                        } label: {
                            Label("Open verification source", systemImage: "checkmark.seal")
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(TallaTheme.Colors.readableAccentLight)
                    }
                    if let reportURL = correctionURL {
                        Button {
                            TallaTelemetry.shared.track("gulf_profile_correction_started", properties: ["spot_id": spot.id])
                            openURL(reportURL)
                        } label: {
                            Label(AppLocalization.text("gulf_report_correction", fallback: "Report a correction"), systemImage: "exclamationmark.bubble")
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rate a specific cup or bean")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        ForEach(spot.offerings) { offering in
                            VStack(alignment: .leading, spacing: 8) {
                                Button { ratingTarget = offering } label: {
                                HStack {
                                    Image(systemName: offering.kind.icon)
                                        .foregroundStyle(TallaTheme.Colors.readableAccentLight)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(offering.name)
                                            .foregroundStyle(.primary)
                                        if let summary = ratingSummaries[offering.id], let average = summary.average {
                                            Text(String(format: "%.1f/5 · %d ratings · %d reviews", average, summary.count, summary.reviewCount))
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundStyle(TallaTheme.Colors.readableAccentLight)
                                        }
                                        Text(offering.detail)
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let rating = ratings[offering.id] {
                                        Text("\(rating)/5")
                                            .foregroundStyle(TallaTheme.Colors.readableAccentLight)
                                    } else {
                                        Image(systemName: "star")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(13)
                                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                if offering.kind != .workshop {
                                    Button {
                                        brewGuideOffering = offering
                                    } label: {
                                        Label(AppLocalization.text("gulf_brew_at_home", fallback: "Brew this coffee at home"), systemImage: "drop.circle.fill")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    .buttonStyle(.tallaSecondary)
                                    .tint(TallaTheme.Colors.readableAccentLight)
                                }
                                if offering.kind == .bean {
                                    Button {
                                        onShopCoffee(offering.name)
                                    } label: {
                                        Label(AppLocalization.text("gulf_buy_this_coffee", fallback: "Find this coffee to buy"), systemImage: "bag.fill")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    .buttonStyle(.tallaSecondary)
                                    .tint(TallaTheme.Colors.readableAccentLight)
                                }
                            }
                            if let note = ratingNotes[offering.id], !note.isEmpty {
                                Text("Your note: \(note)")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 13)
                            }
                            if let reviews = publicReviews[offering.id], !reviews.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Community reviews")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                    ForEach(reviews.prefix(3), id: \.id) { review in
                                        Text("★\(review.rating)  \(review.note)")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.leading, 13)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Place details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var correctionURL: URL? {
        var components = URLComponents(string: "https://wa.me/97339392414")
        components?.queryItems = [URLQueryItem(name: "text", value: "Hi Talla, I’d like to report a correction for \(spot.name) in \(spot.city).")]
        return components?.url
    }
}

private struct GulfCoffeeRatingSheet: View {
    let offering: GulfCoffeeOffering
    let savedRating: Int
    let savedNote: String
    let onSave: (Int, String) -> Void
    @State private var rating = 0
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Rate the item")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(offering.name)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text(offering.detail)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { value in
                    Button { rating = value } label: {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundStyle(value <= rating ? TallaTheme.Colors.readableAccentLight : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rate \(value) out of 5")
                }
            }
            TextEditor(text: $note)
                .frame(minHeight: 70, maxHeight: 100)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.25)))
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Optional tasting note")
                            .foregroundStyle(.secondary)
                            .padding(13)
                            .allowsHitTesting(false)
                    }
                }
            Button("Save rating") { onSave(rating, note.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .buttonStyle(.tallaPrimary)
                .disabled(rating == 0)
        }
        .padding(24)
        .onAppear { rating = savedRating; note = savedNote }
    }
}

private struct CoffeeRegionContour: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.height * 0.46))
        path.addCurve(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.27), control1: CGPoint(x: rect.width * 0.18, y: rect.height * 0.38), control2: CGPoint(x: rect.width * 0.23, y: rect.height * 0.19))
        path.addCurve(to: CGPoint(x: rect.width * 0.57, y: rect.height * 0.34), control1: CGPoint(x: rect.width * 0.42, y: rect.height * 0.32), control2: CGPoint(x: rect.width * 0.51, y: rect.height * 0.29))
        path.addCurve(to: CGPoint(x: rect.width * 0.76, y: rect.height * 0.60), control1: CGPoint(x: rect.width * 0.67, y: rect.height * 0.39), control2: CGPoint(x: rect.width * 0.73, y: rect.height * 0.57))
        path.addCurve(to: CGPoint(x: rect.width * 0.90, y: rect.height * 0.70), control1: CGPoint(x: rect.width * 0.80, y: rect.height * 0.63), control2: CGPoint(x: rect.width * 0.86, y: rect.height * 0.66))
        path.addCurve(to: CGPoint(x: rect.width * 0.64, y: rect.height * 0.87), control1: CGPoint(x: rect.width * 0.83, y: rect.height * 0.81), control2: CGPoint(x: rect.width * 0.73, y: rect.height * 0.91))
        path.addCurve(to: CGPoint(x: rect.width * 0.30, y: rect.height * 0.76), control1: CGPoint(x: rect.width * 0.52, y: rect.height * 0.87), control2: CGPoint(x: rect.width * 0.43, y: rect.height * 0.70))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.height * 0.46), control1: CGPoint(x: rect.width * 0.17, y: rect.height * 0.80), control2: CGPoint(x: rect.width * 0.10, y: rect.height * 0.58))
        return path
    }
}

private struct GulfCoffeeOffering: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case drink, bean, workshop
        var icon: String { self == .drink ? "cup.and.saucer.fill" : self == .bean ? "circle.hexagongrid.fill" : "person.2.fill" }
    }

    let id: String
    let name: String
    let detail: String
    let kind: Kind

    var brewMethod: String {
        if !brewMethodOverride.isEmpty { return brewMethodOverride }
        switch kind {
        case .drink: return name.localizedCaseInsensitiveContains("espresso") ? "Espresso" : "Pour-over / V60"
        case .bean: return "V60 or AeroPress"
        case .workshop: return "Guided tasting"
        }
    }

    var brewRatio: String { !brewRatioOverride.isEmpty ? brewRatioOverride : (kind == .bean ? "15 g coffee · 250 g water" : "Use the barista recipe as your baseline") }
    var brewTemperature: String { !brewTemperatureOverride.isEmpty ? brewTemperatureOverride : (detail.localizedCaseInsensitiveContains("berry") ? "92–94°C" : "90–93°C") }
    var brewTip: String { !brewTipOverride.isEmpty ? brewTipOverride : detail.replacingOccurrences(of: " · ", with: ", ") + ". Adjust one variable at a time." }

    func applying(remote: GulfCoffeeMapRatingService.RemoteOffering) -> GulfCoffeeOffering {
        GulfCoffeeOffering(
            id: id,
            name: remote.name.isEmpty ? name : remote.name,
            detail: (remote.detail ?? "").isEmpty ? detail : (remote.detail ?? ""),
            kind: Kind(rawValue: remote.kind) ?? kind,
            detailAR: remote.detailAR ?? "",
            brewMethodOverride: remote.brewMethod ?? "",
            brewRatioOverride: remote.brewRatio ?? "",
            brewTemperatureOverride: remote.brewTemperature ?? "",
            brewTipOverride: remote.brewTip ?? ""
        )
    }

    init(
        id: String,
        name: String,
        detail: String,
        kind: Kind,
        detailAR: String = "",
        brewMethodOverride: String = "",
        brewRatioOverride: String = "",
        brewTemperatureOverride: String = "",
        brewTipOverride: String = ""
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.kind = kind
        self.detailAR = detailAR
        self.brewMethodOverride = brewMethodOverride
        self.brewRatioOverride = brewRatioOverride
        self.brewTemperatureOverride = brewTemperatureOverride
        self.brewTipOverride = brewTipOverride
    }

    var detailAR: String = ""
    var brewMethodOverride: String = ""
    var brewRatioOverride: String = ""
    var brewTemperatureOverride: String = ""
    var brewTipOverride: String = ""
}

private struct GulfCoffeeSpot: Identifiable, Hashable {
    let id: String
    let name: String
    let city: String
    let country: String
    let neighborhood: String
    let categories: [String]
    let tags: [String]
    let shortDescription: String
    let longDescription: String
    let primaryCategory: String
    let icon: String
    let tint: Color
    let mapOffset: CGSize
    let isFeatured: Bool
    let offerings: [GulfCoffeeOffering]
    var address: String = ""
    var phone: String = ""
    var hours: String = ""
    var verificationStatus: String = "unverified"
    var externalURL: String? = nil
    var logoURL: String? = nil
    var profileDescriptionEN: String = ""
    var profileDescriptionAR: String = ""
    var tastingNotesEN: String = ""
    var tastingNotesAR: String = ""
    var verifiedAt: String = ""
    var verifiedBy: String = ""
    var lastCheckedAt: String = ""
    var sourceURL: String = ""
    var events: [GulfCoffeeEvent] = []
    var latitude: Double {
        switch id { case "bhr-seef": 26.1295; case "hambella-riffa": 26.1300; case "tumma-roast-zinj": 26.2050; case "ksa-riyadh": 24.7136; case "uae-dubai": 25.2048; case "kwt-kuwait": 29.3759; case "qat-doha": 25.2854; default: 23.5880 }
    }
    var longitude: Double {
        switch id { case "bhr-seef": 50.5530; case "hambella-riffa": 50.5550; case "tumma-roast-zinj": 50.5600; case "ksa-riyadh": 46.6753; case "uae-dubai": 55.2708; case "kwt-kuwait": 47.9774; case "qat-doha": 51.5310; default: 58.3829 }
    }
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
    var isOnline: Bool { id == "not-just-beans" }
    var isVerifiedForMap: Bool {
        ["verified", "link-verified", "manually-verified"].contains(verificationStatus.lowercased())
    }
    var websiteURL: URL? {
        if let externalURL, !externalURL.isEmpty, let url = URL(string: externalURL) { return url }
        switch id {
        case "bhr-seef": return URL(string: "https://maps.app.goo.gl/PaaVd6sz66JGk4KS9?g_st=ic")
        case "not-just-beans": return URL(string: "https://notjustbeans.shop/collections/talla-speciality-roasters")
        case "hambella-riffa": return URL(string: "https://maps.app.goo.gl/DU2Gy8kmZ1rGYVLy6?g_st=ic")
        case "tumma-roast-zinj": return URL(string: "https://maps.app.goo.gl/Kd7Fwxq9afe4nirt8?g_st=ic")
        default: return nil
        }
    }
    var relationshipLabel: String {
        if id == "bhr-seef" { return "Talla location" }
        let partnerSellerIDs = ["not-just-beans", "hambella-riffa", "tumma-roast-zinj"]
        if partnerSellerIDs.contains(id) { return "Bean seller / partner listing" }
        return isVerifiedForMap ? "Directory listing" : "Pilot listing · admin review"
    }

    var trustLabel: String {
        switch verificationStatus.lowercased() {
        case "verified": return AppLocalization.text("gulf_verified_profile", fallback: "Talla verified profile")
        case "link-verified": return AppLocalization.text("gulf_link_verified", fallback: "Link verified")
        case "manually-verified": return AppLocalization.text("gulf_manually_verified", fallback: "Manually verified")
        default: return AppLocalization.text("gulf_awaiting_review", fallback: "Awaiting verification")
        }
    }

    var profileFreshnessLabel: String? {
        let checked = lastCheckedAt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !checked.isEmpty else { return nil }
        return "Checked \(checked.prefix(10))"
    }

    var localizedDescription: String {
        AppLocalization.currentLanguage.effectiveLanguageCode == "ar" ? profileDescriptionAR : profileDescriptionEN
    }

    var localizedTastingNotes: String {
        AppLocalization.currentLanguage.effectiveLanguageCode == "ar" ? tastingNotesAR : tastingNotesEN
    }

    var brandMonogram: String {
        switch id {
        case "not-just-beans": return "NJB"
        case "hambella-riffa": return "H"
        case "tumma-roast-zinj": return "TR"
        default: return String(name.prefix(1)).uppercased()
        }
    }

    func applying(remote: GulfCoffeeMapRatingService.RemotePlace?) -> GulfCoffeeSpot {
        guard let remote else { return self }
        return GulfCoffeeSpot(
            id: id,
            name: remote.name.isEmpty ? name : remote.name,
            city: remote.city.isEmpty ? city : remote.city,
            country: remote.country.isEmpty ? country : remote.country,
            neighborhood: remote.neighborhood.isEmpty ? neighborhood : remote.neighborhood,
            categories: remote.categories.isEmpty ? categories : remote.categories,
            tags: remote.tags.isEmpty ? tags : remote.tags,
            shortDescription: shortDescription,
            longDescription: longDescription,
            primaryCategory: primaryCategory,
            icon: icon,
            tint: tint,
            mapOffset: mapOffset,
            isFeatured: isFeatured,
            offerings: remote.offerings?.map { remoteOffering in
                let existing = offerings.first(where: { $0.id == remoteOffering.id })
                    ?? GulfCoffeeOffering(id: remoteOffering.id, name: remoteOffering.name, detail: remoteOffering.detail ?? "", kind: GulfCoffeeOffering.Kind(rawValue: remoteOffering.kind) ?? .drink)
                return existing.applying(remote: remoteOffering)
            } ?? offerings,
            address: remote.address ?? address,
            phone: remote.phone ?? phone,
            hours: remote.hours ?? hours,
            verificationStatus: remote.verificationStatus ?? verificationStatus,
            externalURL: remote.websiteURL ?? externalURL,
            logoURL: remote.logoURL ?? logoURL,
            profileDescriptionEN: remote.description?.en ?? profileDescriptionEN,
            profileDescriptionAR: remote.description?.ar ?? profileDescriptionAR,
            tastingNotesEN: remote.tastingNotes?.en ?? tastingNotesEN,
            tastingNotesAR: remote.tastingNotes?.ar ?? tastingNotesAR,
            verifiedAt: remote.verifiedAt ?? verifiedAt,
            verifiedBy: remote.verifiedBy ?? verifiedBy,
            lastCheckedAt: remote.lastCheckedAt ?? lastCheckedAt,
            sourceURL: remote.sourceURL ?? sourceURL,
            events: remote.events?.compactMap { remoteEvent in
                GulfCoffeeEvent(
                    id: remoteEvent.id,
                    titleEN: remoteEvent.title.en,
                    titleAR: remoteEvent.title.ar,
                    kind: remoteEvent.kind,
                    startsAt: remoteEvent.startsAt,
                    url: URL(string: remoteEvent.url)
                )
            } ?? events
        )
    }

    static let seed: [GulfCoffeeSpot] = [
        .init(id: "bhr-seef", name: "Talla Speciality", city: "Riffa", country: "Bahrain", neighborhood: "Riffa 913", categories: ["Cafés", "Roasters", "Work-friendly"], tags: ["pour over", "quiet", "single origin"], shortDescription: "Talla’s home location for coffee, conversation and beans.", longDescription: "Talla’s single owned location in Bahrain. Use this listing for the home experience, while the bean-seller listings show other places where Talla coffee can be purchased.", primaryCategory: "Talla home location", icon: "flame.fill", tint: Color(hex: 0xD7A866), mapOffset: CGSize(width: -108, height: -24), isFeatured: true, offerings: [.init(id: "bhr-seef-v60", name: "Ethiopia V60", detail: "Floral · peach · tea-like", kind: .drink), .init(id: "bhr-seef-bean", name: "House seasonal lot", detail: "250 g · light roast", kind: .bean)], address: "Villa 336, Street 1307, Riffa 913", verificationStatus: "verified", externalURL: "https://maps.app.goo.gl/PaaVd6sz66JGk4KS9?g_st=ic"),
        .init(id: "ksa-riyadh", name: "Origin Room", city: "Riyadh", country: "Saudi Arabia", neighborhood: "Al Olaya", categories: ["Cafés", "Cuppings & workshops", "Work-friendly"], tags: ["cupping", "espresso", "work tables"], shortDescription: "A social room for espresso, filter and coffee talk.", longDescription: "A Talla pilot listing for a Riyadh coffee room with flexible seating and a calendar built around tastings, throwdowns and guest roaster pop-ups.", primaryCategory: "Café + events", icon: "sparkles", tint: Color(hex: 0xE6B57D), mapOffset: CGSize(width: -42, height: -42), isFeatured: true, offerings: [.init(id: "ksa-riyadh-espresso", name: "House espresso", detail: "Chocolate · date · silky", kind: .drink), .init(id: "ksa-riyadh-cupping", name: "Friday cupping", detail: "Public · guided tasting", kind: .workshop)]),
        .init(id: "uae-dubai", name: "Night Shift Roasters", city: "Dubai", country: "UAE", neighborhood: "Al Quoz", categories: ["Roasters", "Green beans", "Equipment"], tags: ["green coffee", "gear", "training"], shortDescription: "Roasting, green coffee and gear under one roof.", longDescription: "A Talla pilot listing for a roastery-led destination where home brewers can browse green lots, dial in a grinder and leave with a clear next experiment.", primaryCategory: "Roaster + gear", icon: "gearshape.fill", tint: Color(hex: 0xD5B58D), mapOffset: CGSize(width: 34, height: -36), isFeatured: false, offerings: [.init(id: "uae-dubai-natural", name: "Colombia natural", detail: "1 kg green · berry-led", kind: .bean), .init(id: "uae-dubai-grinder", name: "Hand grinder clinic", detail: "Workshop · bookable", kind: .workshop)]),
        .init(id: "kwt-kuwait", name: "Grounds & Co.", city: "Kuwait City", country: "Kuwait", neighborhood: "Sharq", categories: ["Cafés", "Drive-through", "Family-friendly"], tags: ["drive through", "family", "iced latte"], shortDescription: "Easy coffee runs with a menu for every pace.", longDescription: "A Talla pilot listing for a family-friendly stop with a quick lane, generous seating and a menu that keeps both the espresso regular and the iced-coffee explorer happy.", primaryCategory: "Café + drive-through", icon: "car.fill", tint: Color(hex: 0xC6A27B), mapOffset: CGSize(width: -2, height: 2), isFeatured: false, offerings: [.init(id: "kwt-kuwait-spanish", name: "Spanish latte", detail: "Cold · creamy · cardamom", kind: .drink), .init(id: "kwt-kuwait-beans", name: "Weekend blend", detail: "250 g · medium roast", kind: .bean)]),
        .init(id: "qat-doha", name: "Saddleback Coffee Truck", city: "Doha", country: "Qatar", neighborhood: "Msheireb", categories: ["Trucks", "Cafés", "Cuppings & workshops"], tags: ["truck", "pop-up", "throwdown"], shortDescription: "Find the truck, then stay for the coffee conversation.", longDescription: "A Talla pilot listing for a mobile coffee bar that moves with the city and publishes its next stop, guest brewer and throwdown schedule.", primaryCategory: "Coffee truck", icon: "truck.box.fill", tint: Color(hex: 0xD4A36A), mapOffset: CGSize(width: 47, height: 40), isFeatured: true, offerings: [.init(id: "qat-doha-aeropress", name: "AeroPress special", detail: "Citrus · cacao · clean", kind: .drink), .init(id: "qat-doha-throwdown", name: "Open throwdown", detail: "Monthly · all levels", kind: .workshop)]),
        .init(id: "omn-muscat", name: "Wadi Coffee Supply", city: "Muscat", country: "Oman", neighborhood: "Al Khuwair", categories: ["Equipment", "Green beans", "Work-friendly"], tags: ["equipment", "beans", "brew bar"], shortDescription: "A practical stop for beans, brewers and better habits.", longDescription: "A Talla pilot listing for an equipment-forward coffee shop with approachable advice, green bean leads and enough table space to plan the next brew.", primaryCategory: "Supply + brew bar", icon: "drop.fill", tint: Color(hex: 0xCFAE83), mapOffset: CGSize(width: 88, height: 60), isFeatured: false, offerings: [.init(id: "omn-muscat-kenya", name: "Kenya AA", detail: "250 g · currant · lime", kind: .bean), .init(id: "omn-muscat-brew", name: "Brew setup consult", detail: "30 min · practical", kind: .workshop)])
        , .init(id: "not-just-beans", name: "Not Just Beans", city: "Online", country: "GCC", neighborhood: "Online store", categories: ["Green beans"], tags: ["online store", "Talla beans", "delivery"], shortDescription: "Order Talla beans online from a partner seller.", longDescription: "A Talla partner listing for Not Just Beans, an online store carrying Talla beans. This listing is intentionally not shown as a physical map pin.", primaryCategory: "Online bean seller", icon: "cart.fill", tint: Color(hex: 0xB98B62), mapOffset: .zero, isFeatured: true, offerings: [.init(id: "not-just-beans-talla", name: "Talla beans", detail: "Available online · partner seller", kind: .bean)], verificationStatus: "link-verified")
        , .init(id: "hambella-riffa", name: "Hambella", city: "Riffa", country: "Bahrain", neighborhood: "Riffa", categories: ["Green beans"], tags: ["Talla beans", "partner seller"], shortDescription: "Find Talla beans at Hambella in Riffa.", longDescription: "A Talla partner listing for Hambella in Riffa, where customers can find Talla beans. This is a seller location, not a Talla-owned location.", primaryCategory: "Bean seller", icon: "bag.fill", tint: Color(hex: 0xB98B62), mapOffset: .zero, isFeatured: true, offerings: [.init(id: "hambella-riffa-talla", name: "Talla beans", detail: "Available in Riffa · partner seller", kind: .bean)], verificationStatus: "link-verified")
        , .init(id: "tumma-roast-zinj", name: "Tumma Roast", city: "Manama", country: "Bahrain", neighborhood: "Zinj", categories: ["Green beans"], tags: ["Talla beans", "partner seller"], shortDescription: "Find Talla beans at Tumma Roast in Zinj.", longDescription: "A Talla partner listing for Tumma Roast in Zinj, where customers can find Talla beans. This is a seller location, not a Talla-owned location.", primaryCategory: "Bean seller", icon: "bag.fill", tint: Color(hex: 0xB98B62), mapOffset: .zero, isFeatured: true, offerings: [.init(id: "tumma-roast-zinj-talla", name: "Talla beans", detail: "Available in Zinj · partner seller", kind: .bean)], verificationStatus: "link-verified")
    ]
}

private struct GulfCoffeeBrewGuideSheet: View {
    let offering: GulfCoffeeOffering
    let onStartBrew: (GulfCoffeeOffering) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(AppLocalization.text("gulf_brew_guide", fallback: "Brew this coffee at home"), systemImage: "drop.circle.fill")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(offering.name)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(offering.detail)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                brewRow("Method", offering.brewMethod)
                brewRow("Dose / water", offering.brewRatio)
                brewRow("Temperature", offering.brewTemperature)
                brewRow("Start here", offering.brewTip)
            }
            .padding(15)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Button {
                dismiss()
                onStartBrew(offering)
            } label: {
                Label(AppLocalization.text("start_guided_brew", fallback: "Start guided brew"), systemImage: "play.fill")
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.tallaPrimary)
        }
        .padding(24)
    }

    private func brewRow(_ title: String, _ detail: String) -> some View {
        HStack(alignment: .top) {
            Text(title).font(.system(size: 13, weight: .semibold, design: .rounded)).frame(width: 92, alignment: .leading)
            Text(detail).font(.system(size: 14, design: .rounded)).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

private enum GulfCoffeeMapRatingService {
    struct LocalizedText: Decodable {
        let en: String
        let ar: String
    }

    struct RemoteOffering: Decodable {
        let id: String
        let name: String
        let detail: String?
        let detailAR: String?
        let kind: String
        let brewMethod: String?
        let brewRatio: String?
        let brewTemperature: String?
        let brewTip: String?
    }

    struct RemoteEvent: Decodable {
        let id: String
        let title: LocalizedText
        let kind: String
        let startsAt: String
        let url: String
    }

    struct RemotePlace: Decodable {
        let id: String
        let name: String
        let city: String
        let country: String
        let neighborhood: String
        let websiteURL: String?
        let logoURL: String?
        let categories: [String]
        let tags: [String]
        let latitude: Double?
        let longitude: Double?
        let address: String?
        let phone: String?
        let hours: String?
        let verificationStatus: String?
        let verifiedAt: String?
        let verifiedBy: String?
        let lastCheckedAt: String?
        let sourceURL: String?
        let description: LocalizedText?
        let tastingNotes: LocalizedText?
        let offerings: [RemoteOffering]?
        let events: [RemoteEvent]?
    }

    struct Rating: Decodable {
        let offeringID: String
        let rating: Int
        let note: String?
    }

    struct RatingSummary: Decodable {
        let offeringID: String
        let count: Int
        let average: Double?
        let reviewCount: Int
    }

    static func fetchDirectory() async throws -> [RemotePlace] {
        guard let baseURL = AccountService.baseURL else { throw URLError(.badURL) }
        let request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map"))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        struct Envelope: Decodable { let directory: [RemotePlace] }
        return try JSONDecoder().decode(Envelope.self, from: data).directory
    }

    static func fetchRatings() async throws -> [Rating] {
        guard let baseURL = AccountService.baseURL else { throw URLError(.badURL) }
        var request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map/ratings"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try AccountService.authorize(&request)
        let (data, response) = try await AccountService.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        struct Envelope: Decodable { let ratings: [Rating] }
        return try JSONDecoder().decode(Envelope.self, from: data).ratings
    }

    static func fetchRatingSummary() async throws -> [RatingSummary] {
        guard let baseURL = AccountService.baseURL else { throw URLError(.badURL) }
        let request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map/ratings/summary"))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        struct Envelope: Decodable { let ratings: [RatingSummary] }
        return try JSONDecoder().decode(Envelope.self, from: data).ratings
    }

    static func fetchPublicReviews() async throws -> [GulfCoffeePublicReview] {
        guard let baseURL = AccountService.baseURL else { throw URLError(.badURL) }
        let request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map/reviews"))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        struct Envelope: Decodable { let reviews: [GulfCoffeePublicReview] }
        return try JSONDecoder().decode(Envelope.self, from: data).reviews
    }

    static func saveRating(spotID: String, offeringID: String, rating: Int, note: String) async throws {
        guard let baseURL = AccountService.baseURL else { throw URLError(.badURL) }
        var request = URLRequest(url: baseURL.appending(path: "/gulf-coffee-map/ratings"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["spotID": spotID, "offeringID": offeringID, "rating": rating, "note": note])
        let (_, response) = try await AccountService.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
    }
}
