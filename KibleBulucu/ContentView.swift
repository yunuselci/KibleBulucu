//
//  ContentView.swift
//  KibleBulucu
//
//  Created by Yunus Elçi on 27.05.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PrayerTimesViewModel()
    @State private var wasAligned = false

    private var isAligned: Bool {
        let rotation = viewModel.qiblaDirection - viewModel.currentHeading
        let angleDifference = abs(normalizeAngle(rotation))
        return angleDifference <= 3
    }

    private func normalizeAngle(_ angle: Double) -> Double {
        var normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        if normalizedAngle > 180 {
            normalizedAngle -= 360
        } else if normalizedAngle < -180 {
            normalizedAngle += 360
        }
        return normalizedAngle
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    compassSection
                    prayerSummarySection
                    errorSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showCitySelection) {
            CitySelectionSheet(
                currentSelection: viewModel.selectedLocation?.isAutomatic == false ? viewModel.selectedLocation : nil,
                countries: viewModel.countries,
                cities: viewModel.cities,
                districts: viewModel.districts,
                selectedCountryID: viewModel.selectedCountryID,
                selectedCityID: viewModel.selectedCityID,
                selectedDistrictID: viewModel.selectedDistrictID,
                isLoading: viewModel.isLoadingLocations,
                errorMessage: viewModel.errorMessage,
                onSelectCountry: viewModel.selectCountry(_:),
                onSelectCity: viewModel.selectCity(_:),
                onSelectDistrict: viewModel.selectDistrict(_:),
                onSave: viewModel.saveManualSelection
            )
        }
        .sheet(isPresented: $viewModel.showNotificationSettings) {
            NotificationSettingsView(
                settings: viewModel.settings,
                onNotificationsChanged: viewModel.updateNotificationPreference(enabled:),
                onSoundChanged: viewModel.updateSoundPreference(enabled:),
                onPrayerToggleChanged: viewModel.updatePrayerToggle(_:enabled:)
            )
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text(viewModel.todayDateText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    private var compassSection: some View {
        VStack(spacing: 18) {
            if viewModel.hasCompassData {
                CompassView(
                    currentHeading: viewModel.currentHeading,
                    qiblaDirection: viewModel.qiblaDirection
                )
                .onChange(of: isAligned) { newValue in
                    if newValue != wasAligned {
                        if newValue {
                            let feedback = UINotificationFeedbackGenerator()
                            feedback.notificationOccurred(.success)
                        } else {
                            let feedback = UIImpactFeedbackGenerator(style: .light)
                            feedback.impactOccurred()
                        }
                        wasAligned = newValue
                    }
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)

                    Text("finding_location", bundle: .main)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
            }

        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
        )
    }

    private var prayerSummarySection: some View {
        PrayerTimesCard(
            cityName: viewModel.citySummaryText,
            dateText: viewModel.todayDateText,
            currentPrayer: viewModel.currentPrayer,
            nextPrayer: viewModel.nextPrayer,
            countdownText: viewModel.countdownText,
            prayerTimes: viewModel.prayerTimes,
            isLoading: viewModel.isLoadingPrayerTimes,
            onRefresh: viewModel.refreshManually,
            onSelectCity: viewModel.presentLocationSelection,
            onNotifications: { viewModel.showNotificationSettings = true }
        )
    }

    @ViewBuilder
    private var errorSection: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

#Preview {
    ContentView()
}
