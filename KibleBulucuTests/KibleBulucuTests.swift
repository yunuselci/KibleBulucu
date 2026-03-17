//
//  KibleBulucuTests.swift
//  KibleBulucuTests
//
//  Created by Yunus Elçi on 27.05.2025.
//

import Foundation
import Testing
@testable import KibleBulucu

struct KibleBulucuTests {
    @Test func prayerAPIServiceParsesAndCachesDailyPrayerTimes() async throws {
        let session = Self.makeMockSession()
        let suiteName = "PrayerStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        MockURLProtocol.requestCount = 0
        MockURLProtocol.handler = { request in
            #expect(request.url?.absoluteString.contains("/vakitler/9541") == true)
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Self.samplePrayerDaysResponse.data(using: .utf8)!)
        }

        let service = PrayerAPIService(session: session, store: PrayerStore(defaults: defaults))
        let selection = PrayerLocationSelection(
            country: Country(name: "TURKIYE", englishName: "TURKEY", id: "2"),
            city: City(name: "ISTANBUL", englishName: "ISTANBUL", id: "539"),
            district: District(name: "ISTANBUL", englishName: "ISTANBUL", id: "9541"),
            isAutomatic: false
        )

        let first = try await service.fetchPrayerTimes(for: selection, forceRefresh: true)
        let second = try await service.fetchPrayerTimes(for: selection, forceRefresh: false)

        #expect(first.city == "ISTANBUL")
        #expect(first.country == "TURKIYE")
        #expect(first.districtID == "9541")
        #expect(first.sortedPrayers.count == 6)
        #expect(first.entry(for: Prayer.fajr) != nil)
        #expect(first.entry(for: Prayer.isha) != nil)
        #expect(MockURLProtocol.requestCount == 1)
        #expect(first == second)
    }

    @Test func prayerAPIServiceMatchesResolvedPlacemarkToDistrictHierarchy() async throws {
        let session = Self.makeMockSession()
        let suiteName = "PrayerStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        MockURLProtocol.handler = { request in
            let url = try #require(request.url?.absoluteString)
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)!

            if url.hasSuffix("/ulkeler") {
                return (response, Self.sampleCountriesResponse.data(using: .utf8)!)
            }
            if url.hasSuffix("/sehirler/2") {
                return (response, Self.sampleCitiesResponse.data(using: .utf8)!)
            }
            if url.hasSuffix("/ilceler/539") {
                return (response, Self.sampleDistrictsResponse.data(using: .utf8)!)
            }

            throw URLError(.badURL)
        }

        let service = PrayerAPIService(session: session, store: PrayerStore(defaults: defaults))
        let selection = try await service.resolveSelection(
            from: ResolvedPlacemark(countryName: "Turkey", cityName: "Istanbul", districtName: "Pendik")
        )

        #expect(selection.country.id == "2")
        #expect(selection.city.id == "539")
        #expect(selection.district.id == "9545")
    }

    @Test func countdownSnapshotTracksNextPrayerAndCompletion() {
        let prayerTimes = Self.fixturePrayerTimes()

        let beforeMaghrib = CountdownManager.snapshot(
            for: prayerTimes,
            at: Self.makeDate(hour: 18, minute: 30)
        )
        let afterIsha = CountdownManager.snapshot(
            for: prayerTimes,
            at: Self.makeDate(hour: 21, minute: 15)
        )

        #expect(beforeMaghrib.currentPrayer == .asr)
        #expect(beforeMaghrib.nextPrayer?.prayer == .maghrib)
        #expect(beforeMaghrib.remainingTimeText == "00:30:00")
        #expect(afterIsha.currentPrayer == .isha)
        #expect(afterIsha.nextPrayer == nil)
        #expect(afterIsha.remainingTimeText == "Completed")
    }

    @Test func notificationManagerBuildsRequestsForEnabledFuturePrayers() {
        let prayerTimes = PrayerTimes(
            city: "Istanbul",
            country: "Turkey",
            district: "Pendik",
            districtID: "9545",
            date: Calendar.current.startOfDay(for: Date()),
            timeZoneIdentifier: TimeZone.current.identifier,
            fetchedAt: Date(),
            prayers: [
                PrayerTimeEntry(prayer: .fajr, time: Date().addingTimeInterval(-600)),
                PrayerTimeEntry(prayer: .dhuhr, time: Date().addingTimeInterval(3600)),
                PrayerTimeEntry(prayer: .asr, time: Date().addingTimeInterval(7200))
            ]
        )
        var settings = PrayerSettings.default
        settings.notificationsEnabled = true
        settings.enabledPrayers[.dhuhr] = true
        settings.enabledPrayers[.asr] = false

        let requests = NotificationManager().notificationRequests(for: prayerTimes, settings: settings)

        #expect(requests.count == 1)
        #expect(requests.first?.identifier == Prayer.dhuhr.rawValue)
        #expect(requests.first?.content.sound != nil)
    }
}

private extension KibleBulucuTests {
    static let sampleCountriesResponse = """
    [
      { "UlkeAdi": "TURKIYE", "UlkeAdiEn": "TURKEY", "UlkeID": "2" }
    ]
    """

    static let sampleCitiesResponse = """
    [
      { "SehirAdi": "ISTANBUL", "SehirAdiEn": "ISTANBUL", "SehirID": "539" }
    ]
    """

    static let sampleDistrictsResponse = """
    [
      { "IlceAdi": "ISTANBUL", "IlceAdiEn": "ISTANBUL", "IlceID": "9541" },
      { "IlceAdi": "PENDIK", "IlceAdiEn": "PENDIK", "IlceID": "9545" }
    ]
    """

    static let samplePrayerDaysResponse = """
    [
      {
        "MiladiTarihKisaIso8601": "16.03.2026",
        "MiladiTarihUzunIso8601": "2026-03-16T00:00:00.0000000+03:00",
        "Aksam": "19:19",
        "Gunes": "07:08",
        "Ikindi": "16:37",
        "Imsak": "05:43",
        "Ogle": "13:18",
        "Yatsi": "20:38"
      }
    ]
    """

    static func fixturePrayerTimes() -> PrayerTimes {
        PrayerTimes(
            city: "Istanbul",
            country: "Turkey",
            district: "Pendik",
            districtID: "9545",
            date: Calendar.current.startOfDay(for: makeDate(hour: 0, minute: 0)),
            timeZoneIdentifier: TimeZone.current.identifier,
            fetchedAt: Date(),
            prayers: [
                PrayerTimeEntry(prayer: .fajr, time: makeDate(hour: 5, minute: 30)),
                PrayerTimeEntry(prayer: .sunrise, time: makeDate(hour: 7, minute: 0)),
                PrayerTimeEntry(prayer: .dhuhr, time: makeDate(hour: 13, minute: 0)),
                PrayerTimeEntry(prayer: .asr, time: makeDate(hour: 16, minute: 0)),
                PrayerTimeEntry(prayer: .maghrib, time: makeDate(hour: 19, minute: 0)),
                PrayerTimeEntry(prayer: .isha, time: makeDate(hour: 20, minute: 30))
            ]
        )
    }

    static func makeDate(hour: Int, minute: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
    }

    static func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            MockURLProtocol.requestCount += 1
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
