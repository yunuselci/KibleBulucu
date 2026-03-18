import SwiftUI

struct CitySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentSelection: PrayerLocationSelection?
    let countries: [Country]
    let cities: [City]
    let districts: [District]
    let selectedCountryID: String?
    let selectedCityID: String?
    let selectedDistrictID: String?
    let isLoading: Bool
    let errorMessage: String?
    let onSelectCountry: (String?) -> Void
    let onSelectCity: (String?) -> Void
    let onSelectDistrict: (String?) -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Seçili Konum") {
                    if let currentSelection {
                        Text(currentSelection.displayName)
                    } else {
                        Text("Henüz bir konum seçilmedi.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Picker("", selection: Binding(
                        get: { selectedCountryID },
                        set: onSelectCountry
                    )) {
                        Text("Ülke Seçin").tag(String?.none)
                        ForEach(countries) { country in
                            Text(country.name).tag(Optional(country.id))
                        }
                    }
                    .labelsHidden()
                }

                Section {
                    Picker("", selection: Binding(
                        get: { selectedCityID },
                        set: onSelectCity
                    )) {
                        Text("Şehir Seçin").tag(String?.none)
                        ForEach(cities) { city in
                            Text(city.name).tag(Optional(city.id))
                        }
                    }
                    .labelsHidden()
                    .disabled(selectedCountryID == nil)
                }

                Section {
                    Picker("", selection: Binding(
                        get: { selectedDistrictID },
                        set: onSelectDistrict
                    )) {
                        Text("İlçe Seçin").tag(String?.none)
                        ForEach(districts) { district in
                            Text(district.name).tag(Optional(district.id))
                        }
                    }
                    .labelsHidden()
                    .disabled(selectedCityID == nil)
                }

                if isLoading {
                    Section {
                        ProgressView("Konumlar yükleniyor...")
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Seçimi Kaydet") {
                        onSave()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(selectedDistrictID == nil)
                }
            }
            .navigationTitle("Konum Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bitti") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CitySelectionSheet(
        currentSelection: PrayerLocationSelection(
            country: Country(name: "TURKIYE", englishName: "TURKEY", id: "2"),
            city: City(name: "ISTANBUL", englishName: "ISTANBUL", id: "539"),
            district: District(name: "ISTANBUL", englishName: "ISTANBUL", id: "9541"),
            isAutomatic: false
        ),
        countries: [],
        cities: [],
        districts: [],
        selectedCountryID: nil,
        selectedCityID: nil,
        selectedDistrictID: nil,
        isLoading: false,
        errorMessage: nil,
        onSelectCountry: { _ in },
        onSelectCity: { _ in },
        onSelectDistrict: { _ in },
        onSave: {}
    )
}
