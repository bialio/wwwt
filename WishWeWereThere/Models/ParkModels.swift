//
//  ParkModels.swift
//  Wish We Were There
//

import Foundation

enum ParkMark: String {
    case castle, sphere, marquee, tree
}

enum ParkAtmosphere: String {
    case mk, epcot, hs, ak
}

struct Park: Identifiable, Hashable {
    let id: String
    let slug: String
    let shortName: String
    let name: String
    let mark: ParkMark
    let atmosphere: ParkAtmosphere

    static let all: [Park] = [
        Park(id: "75ea578a-adc8-4116-a54d-dccb60765ef9", slug: "mk", shortName: "Magic Kingdom", name: "Magic Kingdom Park", mark: .castle, atmosphere: .mk),
        Park(id: "47f90d2c-e191-4239-a466-5892ef59a88b", slug: "epcot", shortName: "EPCOT", name: "EPCOT", mark: .sphere, atmosphere: .epcot),
        Park(id: "288747d1-8b4f-4a64-867e-ea7c9b27bad8", slug: "hs", shortName: "Hollywood Studios", name: "Disney's Hollywood Studios", mark: .marquee, atmosphere: .hs),
        Park(id: "1c84a229-8862-4648-9c71-378ddd2c7693", slug: "ak", shortName: "Animal Kingdom", name: "Disney's Animal Kingdom Theme Park", mark: .tree, atmosphere: .ak),
    ]

    static let byID: [String: Park] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
}

enum LiveStatus: String, Codable {
    case operating = "OPERATING"
    case down = "DOWN"
    case closed = "CLOSED"
    case refurbishment = "REFURBISHMENT"
}

enum WaitBand {
    case walk, moderate, long, down, closed, open
}

struct LightningLane: Equatable {
    enum Kind { case multi, individual }

    let kind: Kind
    let state: String
    let returnStart: Date?
    let returnEnd: Date?
    let price: String?
}

struct ForecastPoint: Equatable {
    let time: Date
    let waitMinutes: Int?
}

struct Attraction: Identifiable, Equatable {
    let id: String
    let name: String
    let parkID: String
    let land: String
    let status: LiveStatus
    let waitMinutes: Int?
    let singleRiderMinutes: Int?
    let lightningLane: LightningLane?
    let lastUpdated: Date?
    /// (open, close) of the ride's own operating hours, if published separately from park hours.
    let rideHours: (open: Date, close: Date)?
    let forecast: [ForecastPoint]

    static func == (lhs: Attraction, rhs: Attraction) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.waitMinutes == rhs.waitMinutes
            && lhs.singleRiderMinutes == rhs.singleRiderMinutes && lhs.lightningLane == rhs.lightningLane
            && lhs.lastUpdated == rhs.lastUpdated && lhs.forecast == rhs.forecast
    }
}

struct Showtime: Identifiable, Equatable {
    let id: String
    let name: String
    let parkID: String
    let startTime: Date
    let endTime: Date?
}

struct ParkHours {
    let opensAt: Date?
    let closesAt: Date?
    let earlyEntryAt: Date?
    let isOpen: Bool
}

struct ParkSnapshot: Identifiable {
    let id: String
    let park: Park
    let timezone: TimeZone
    let hours: ParkHours
    let attractions: [Attraction]
    let shows: [Showtime]
}

enum ResortPayload {
    case live(fetchedAt: Date, parks: [ParkSnapshot])
    case failure(fetchedAt: Date, message: String, parks: [ParkSnapshot])

    var parks: [ParkSnapshot] {
        switch self {
        case .live(_, let parks): return parks
        case .failure(_, _, let parks): return parks
        }
    }

    var fetchedAt: Date {
        switch self {
        case .live(let fetchedAt, _): return fetchedAt
        case .failure(let fetchedAt, _, _): return fetchedAt
        }
    }

    var isOK: Bool {
        switch self {
        case .live: return true
        case .failure: return false
        }
    }
}

enum ParksConstants {
    static let themeParksAPI = "https://api.themeparks.wiki/v1"
    static let userAgent = "WishWeWereThere/1.0 (Wish We Were There living-room wait times)"
    static let walkOnMax = 15
    static let moderateMax = 45
    // ThemeParks.wiki refreshes every few minutes and asks clients to poll no more than once every 5 minutes.
    static let refreshInterval: TimeInterval = 300
    static let cacheInterval: TimeInterval = 295
}
