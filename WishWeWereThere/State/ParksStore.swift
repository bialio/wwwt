//
//  ParksStore.swift
//  Wish We Were There
//

import Foundation
import Observation

@Observable
final class ParksStore {
    private enum DefaultsKey {
        static let favorites = "wwwt.favorites"
        static let tripDate = "wwwt.tripDate"
    }

    var resort: ResortPayload?
    var isFetching = false

    var favorites: Set<String> {
        didSet { UserDefaults.standard.set(Array(favorites), forKey: DefaultsKey.favorites) }
    }

    var tripDate: String? {
        didSet { UserDefaults.standard.set(tripDate, forKey: DefaultsKey.tripDate) }
    }

    @ObservationIgnored private var autoRefreshTask: Task<Void, Never>?

    init() {
        let defaults = UserDefaults.standard
        favorites = Set(defaults.stringArray(forKey: DefaultsKey.favorites) ?? [])
        tripDate = defaults.string(forKey: DefaultsKey.tripDate)
    }

    var parks: [ParkSnapshot] { resort?.parks ?? [] }

    func toggleFavorite(_ id: String) {
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }
    }

    func refresh() async {
        isFetching = true
        resort = await ThemeParksAPI.shared.loadResort()
        isFetching = false
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
