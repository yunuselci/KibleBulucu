import Foundation
import CoreLocation
import Combine

@MainActor
final class PrayerTimesViewModel: ObservableObject {
    @Published private(set) var location: CLLocation?
    @Published private(set) var heading: CLHeading?
    @Published private(set) var selectedLocation: PrayerLocationSelection?
    @Published private(set) var prayerTimes: PrayerTimes?
    @Published private(set) var nextPrayer: PrayerTimeEntry?
    @Published private(set) var currentPrayer: Prayer?
    @Published private(set) var countdownText = "--:--:--"
    @Published private(set) var settings: PrayerSettings
    @Published private(set) var isLoadingPrayerTimes = false
    @Published private(set) var isLoadingLocations = false
    @Published private(set) var errorMessage: String?
    @Published var showNotificationSettings = false
    @Published var showCitySelection = false
    @Published private(set) var countries: [Country] = []
    @Published private(set) var cities: [City] = []
    @Published private(set) var districts: [District] = []
    @Published var selectedCountryID: String?
    @Published var selectedCityID: String?
    @Published var selectedDistrictID: String?

    let locationManager: LocationManager

    private let prayerAPIService: PrayerAPIService
    private let prayerStore: PrayerStore
    private let notificationManager: NotificationManager
    private let countdownManager: CountdownManager

    private var cancellables: Set<AnyCancellable> = []

    init(
        locationManager: LocationManager = LocationManager(),
        prayerStore: PrayerStore = PrayerStore(),
        notificationManager: NotificationManager = NotificationManager(),
        countdownManager: CountdownManager = CountdownManager()
    ) {
        self.locationManager = locationManager
        self.prayerStore = prayerStore
        self.notificationManager = notificationManager
        self.countdownManager = countdownManager
        self.prayerAPIService = PrayerAPIService(store: prayerStore)
        self.settings = prayerStore.loadSettings()
        self.selectedLocation = prayerStore.loadLocationSelection() ?? PrayerLocationSelection.defaultSelection
        self.prayerTimes = prayerStore.loadPrayerTimes()
        if prayerStore.loadLocationSelection() == nil {
            prayerStore.saveLocationSelection(PrayerLocationSelection.defaultSelection)
        }
        applySelectionToPickers()

        bindLocation()
        bindCountdown()
    }

    var currentHeading: Double {
        heading?.magneticHeading ?? 0
    }

    var qiblaDirection: Double {
        guard let location else { return 0 }
        return QiblaCalculator.calculateQiblaDirection(from: location)
    }

    var hasCompassData: Bool {
        location != nil && heading != nil
    }

    var todayDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.setLocalizedDateFormatFromTemplate("d MMMM y")
        return formatter.string(from: prayerTimes?.date ?? Date())
    }

    var citySummaryText: String {
        if let selectedLocation {
            return "\(selectedLocation.city.name), \(selectedLocation.country.name)"
        }
        if let prayerTimes {
            return "\(prayerTimes.city), \(prayerTimes.country)"
        }
        return "Şehir bulunuyor..."
    }

    var districtSummaryText: String {
        selectedLocation?.district.name ?? prayerTimes?.district ?? "İlçe Seçilmedi"
    }

    var isUsingAutomaticLocation: Bool {
        selectedLocation?.isAutomatic ?? true
    }

    func onAppear() {
        locationManager.startUpdatingLocation()
        countdownManager.start(with: prayerTimes)
        Task {
            await loadCountriesIfNeeded()
            await restoreLocationSelection(selectedLocation ?? PrayerLocationSelection.defaultSelection, refresh: false)
        }
    }

    func refreshManually() {
        Task {
            await refreshPrayerTimes(for: selectedLocation ?? PrayerLocationSelection.defaultSelection, forceRefresh: true)
        }
    }

    func presentLocationSelection() {
        Task {
            await loadCountriesIfNeeded()
            showCitySelection = true
        }
    }

    func selectCountry(_ countryID: String?) {
        Task {
            selectedCountryID = countryID
            selectedCityID = nil
            selectedDistrictID = nil
            cities = []
            districts = []

            guard let countryID else { return }
            await loadCities(countryID: countryID)
        }
    }

    func selectCity(_ cityID: String?) {
        Task {
            selectedCityID = cityID
            selectedDistrictID = nil
            districts = []

            guard let cityID else { return }
            await loadDistricts(cityID: cityID)
        }
    }

    func selectDistrict(_ districtID: String?) {
        selectedDistrictID = districtID
    }

    func saveManualSelection() {
        guard
            let countryID = selectedCountryID,
            let cityID = selectedCityID,
            let districtID = selectedDistrictID,
            let country = countries.first(where: { $0.id == countryID }),
            let city = cities.first(where: { $0.id == cityID }),
            let district = districts.first(where: { $0.id == districtID })
        else {
            errorMessage = "Lütfen ülke, şehir ve ilçe seçin."
            return
        }

        let selection = PrayerLocationSelection(country: country, city: city, district: district, isAutomatic: false)
        selectedLocation = selection
        prayerStore.saveLocationSelection(selection)
        showCitySelection = false

        Task {
            await refreshPrayerTimes(for: selection, forceRefresh: true)
        }
    }

    func updateNotificationPreference(enabled: Bool) {
        settings.notificationsEnabled = enabled
        persistSettingsAndReschedule()
    }

    func updateSoundPreference(enabled: Bool) {
        settings.soundEnabled = enabled
        persistSettingsAndReschedule()
    }

    func updatePrayerToggle(_ prayer: Prayer, enabled: Bool) {
        settings.enabledPrayers[prayer] = enabled
        persistSettingsAndReschedule()
    }

    private func bindLocation() {
        locationManager.$location
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self else { return }
                self.location = location
            }
            .store(in: &cancellables)

        locationManager.$heading
            .receive(on: RunLoop.main)
            .assign(to: &$heading)

        locationManager.$errorMessage
            .receive(on: RunLoop.main)
            .assign(to: &$errorMessage)
    }

    private func bindCountdown() {
        countdownManager.$nextPrayer
            .receive(on: RunLoop.main)
            .assign(to: &$nextPrayer)

        countdownManager.$currentPrayer
            .receive(on: RunLoop.main)
            .assign(to: &$currentPrayer)

        countdownManager.$remainingTimeText
            .receive(on: RunLoop.main)
            .assign(to: &$countdownText)
    }

    private func applySelectionToPickers() {
        selectedCountryID = selectedLocation?.country.id
        selectedCityID = selectedLocation?.city.id
        selectedDistrictID = selectedLocation?.district.id
    }

    private func loadCountriesIfNeeded() async {
        guard countries.isEmpty else { return }
        isLoadingLocations = true
        defer { isLoadingLocations = false }

        do {
            countries = try await prayerAPIService.fetchCountries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadCities(countryID: String) async {
        isLoadingLocations = true
        defer { isLoadingLocations = false }

        do {
            cities = try await prayerAPIService.fetchCities(countryID: countryID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadDistricts(cityID: String) async {
        isLoadingLocations = true
        defer { isLoadingLocations = false }

        do {
            districts = try await prayerAPIService.fetchDistricts(cityID: cityID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restoreLocationSelection(_ selection: PrayerLocationSelection, refresh: Bool) async {
        await loadCountriesIfNeeded()
        await loadCities(countryID: selection.country.id)
        await loadDistricts(cityID: selection.city.id)
        selectedLocation = selection
        applySelectionToPickers()
        await refreshPrayerTimes(for: selection, forceRefresh: refresh)
    }

    private func refreshPrayerTimes(for selection: PrayerLocationSelection, forceRefresh: Bool) async {
        isLoadingPrayerTimes = true
        errorMessage = nil
        defer { isLoadingPrayerTimes = false }

        do {
            let prayerTimes = try await prayerAPIService.fetchPrayerTimes(for: selection, forceRefresh: forceRefresh)
            self.prayerTimes = prayerTimes
            countdownManager.start(with: prayerTimes)

            if settings.notificationsEnabled {
                let isAuthorized = try await notificationManager.requestAuthorizationIfNeeded()
                if isAuthorized {
                    await notificationManager.rescheduleNotifications(for: prayerTimes, settings: settings)
                } else {
                    settings.notificationsEnabled = false
                    prayerStore.saveSettings(settings)
                }
            } else {
                await notificationManager.rescheduleNotifications(for: prayerTimes, settings: settings)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistSettingsAndReschedule() {
        Task {
            if settings.notificationsEnabled {
                let granted = try await notificationManager.requestAuthorizationIfNeeded()
                if !granted {
                    settings.notificationsEnabled = false
                    errorMessage = "Bildirimler Ayarlar'da kapalı."
                }
            }

            prayerStore.saveSettings(settings)
            await notificationManager.rescheduleNotifications(for: prayerTimes, settings: settings)
        }
    }
}
