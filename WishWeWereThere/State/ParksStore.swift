//
//  ParksStore.swift
//  Wish We Were There
//

import Foundation
import Observation
import TVServices

@Observable
final class ParksStore {
    private enum DefaultsKey {
        static let tripDate = "wwwt.tripDate"
        static let topWaits = "wwwt.topWaits"
    }

    static let appGroupID = "group.com.thelindstrom.WishWeWereThere"

    var resort: ResortPayload?
    var isFetching = false

    var tripDate: String? {
        didSet {
            UserDefaults.standard.set(tripDate, forKey: DefaultsKey.tripDate)
            UserDefaults(suiteName: Self.appGroupID)?.set(tripDate, forKey: DefaultsKey.tripDate)
            TVTopShelfContentProvider.topShelfContentDidChange()
        }
    }

    @ObservationIgnored private var autoRefreshTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard
        tripDate = defaults.string(forKey: DefaultsKey.tripDate)
    }

    var parks: [ParkSnapshot] { resort?.parks ?? [] }

    func refresh() async {
        isFetching = true
        resort = await ThemeParksAPI.shared.loadResort()
        isFetching = false
        publishTopWaits()
    }

    private func publishTopWaits() {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        let top = hottest(parks, limit: 4)
        if top.isEmpty {
            defaults?.removeObject(forKey: DefaultsKey.topWaits)
        } else {
            let entries = top.compactMap { attraction -> [String: Any]? in
                guard let waitMinutes = attraction.waitMinutes, let park = Park.byID[attraction.parkID] else { return nil }
                return [
                    "attraction": attraction.name,
                    "park": park.shortName,
                    "land": attraction.land,
                    "minutes": waitMinutes,
                    "mark": park.mark.rawValue,
                    "atmosphere": park.atmosphere.rawValue,
                ]
            }
            defaults?.set(entries, forKey: DefaultsKey.topWaits)
        }
        TVTopShelfContentProvider.topShelfContentDidChange()
    }

    func startAutoRefresh() {
        guard autoRefreshTask == nil else { return }
        autoRefreshTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.refresh()
                try? await Task.sleep(for: .seconds(ParksConstants.refreshInterval))
            }
        }
    }

    deinit {
        autoRefreshTask?.cancel()
    }
}
