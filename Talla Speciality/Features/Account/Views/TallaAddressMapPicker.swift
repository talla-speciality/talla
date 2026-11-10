import SwiftUI
import Combine
import MapKit
import CoreLocation

/// A confirmed pin is kept separately from the editable postal address.
struct TallaPickedAddress {
    let coordinate: CLLocationCoordinate2D
    let placemark: CLPlacemark?

    var mapsURL: String {
        "https://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)"
    }
}

@MainActor
final class TallaAddressLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var message: String?
    @Published var isLocating = false
    private let manager = CLLocationManager()
    private var requested = false
    var arabic = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func locate() {
        requested = true
        isLocating = true
        message = nil
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default:
            isLocating = false
            message = arabic ? "يمكنك البحث أو تحريك الخريطة دون السماح بالموقع." : "You can search or move the map without location access."
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard requested else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied, .restricted:
            isLocating = false
            message = arabic ? "يمكنك البحث أو تحريك الخريطة دون السماح بالموقع." : "You can search or move the map without location access."
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLocating = false
        coordinate = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        message = arabic ? "تعذر تحديد موقعك. ابحث أو حرّك الخريطة." : "Couldn’t find your location. Search or move the map instead."
    }
}

struct TallaAddressMapPicker: View {
    let arabic: Bool
    let initial: TallaPickedAddress?
    let onPick: (TallaPickedAddress) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var location = TallaAddressLocation()
    @State private var position: MapCameraPosition = .automatic
    @State private var center = CLLocationCoordinate2D(latitude: 26.13, longitude: 50.56)
    @State private var region = MKCoordinateRegion()
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @State private var results: [MKMapItem] = []
    @State private var searchID = UUID()
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var placemark: CLPlacemark?
    @State private var isResolving = false
    @State private var resolvedPinID = ""
    @State private var addressMessage = ""

    private var pinID: String { "\(center.latitude),\(center.longitude)" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    TextField(arabic ? "ابحث عن منطقة أو شارع أو مكان" : "Search area, street or place", text: $query)
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .onSubmit { Task { await search() } }
                    Button { Task { await search() } } label: {
                        Label(arabic ? "بحث" : "Search", systemImage: "magnifyingglass")
                    }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()

                if isSearching { ProgressView().padding(8) }
                if let searchError { Text(searchError).font(.footnote).padding(8) }
                if !results.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(results.indices, id: \.self) { index in
                                let item = results[index]
                                Button {
                                    recenter(item.placemark.coordinate)
                                    results = []
                                    query = item.name ?? query
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name ?? "").font(.body.weight(.semibold))
                                        Text(item.placemark.title ?? "").font(.caption).foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 170)
                }

                Map(position: $position) { }
                    .mapStyle(.standard(elevation: .flat))
                    .onMapCameraChange(frequency: .continuous) { context in
                        region = context.region
                        center = context.region.center
                    }
                    .overlay {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(TallaTheme.Colors.accent)
                            .background(.background, in: Circle())
                            .offset(y: -22)
                            .allowsHitTesting(false)
                    }
                    .accessibilityLabel(arabic ? "حرّك الخريطة لاختيار موقع التوصيل" : "Move the map to choose your delivery location")

                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        location.arabic = arabic
                        location.locate()
                    } label: {
                        Label(arabic ? "استخدم موقعي الحالي" : "Use my current location", systemImage: "location.fill")
                    }
                    .disabled(location.isLocating)
                    if location.isLocating { ProgressView() }
                    if let message = location.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
                    Text(arabic ? "حرّك الخريطة لوضع الدبوس عند المدخل." : "Move the map to put the pin at your entrance.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if isResolving {
                        ProgressView(arabic ? "جارٍ البحث عن العنوان…" : "Finding address…")
                    } else {
                        Text(addressMessage).font(.footnote)
                    }
                    Button {
                        onPick(TallaPickedAddress(coordinate: center, placemark: placemark))
                        dismiss()
                    } label: {
                        Text(arabic ? "استخدم هذا الموقع" : "Use this location")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(TallaTheme.Colors.accent)
                    .disabled(isResolving || resolvedPinID != pinID)
                }
                .padding()
            }
            .navigationTitle(arabic ? "اختر موقع التوصيل" : "Choose delivery location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(arabic ? "إلغاء" : "Cancel") { dismiss() }
                }
            }
            .onAppear { recenter(initial?.coordinate ?? center) }
            .onChange(of: location.coordinate.map { "\($0.latitude),\($0.longitude)" }) { _, _ in
                if let coordinate = location.coordinate { recenter(coordinate) }
            }
            .task(id: pinID) {
                let requestedPinID = pinID
                placemark = nil
                isResolving = true
                do {
                    try await Task.sleep(for: .milliseconds(450))
                    let coordinate = center
                    let geocoder = CLGeocoder()
                    let marks = try await geocoder.reverseGeocodeLocation(
                        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                        preferredLocale: Locale(identifier: arabic ? "ar" : "en")
                    )
                    try Task.checkCancellation()
                    guard requestedPinID == pinID else { return }
                    resolvedPinID = requestedPinID
                    placemark = marks.first
                    addressMessage = [marks.first?.name, marks.first?.locality, marks.first?.country]
                        .compactMap { $0 }.joined(separator: ", ")
                    isResolving = false
                } catch {
                    guard !Task.isCancelled, requestedPinID == pinID else { return }
                    resolvedPinID = requestedPinID
                    addressMessage = arabic ? "تم تحديد الدبوس. أكمل تفاصيل العنوان بعد التأكيد." : "Pin selected. Fill in address details after confirming."
                    isResolving = false
                }
            }
        }
    }

    private func recenter(_ coordinate: CLLocationCoordinate2D) {
        center = coordinate
        position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)))
    }

    @MainActor private func search() async {
        searchFocused = false
        let id = UUID()
        searchID = id
        isSearching = true
        searchError = nil
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard id == searchID else { return }
            results = Array(response.mapItems.prefix(6))
            if results.isEmpty { searchError = arabic ? "لا توجد نتائج. جرّب اسم منطقة أو شارع." : "No results. Try an area or street name." }
        } catch {
            guard id == searchID else { return }
            results = []
            searchError = arabic ? "البحث غير متاح الآن. يمكنك تحريك الخريطة." : "Search is unavailable. You can still move the map."
        }
        isSearching = false
    }
}
