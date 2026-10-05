//
//  ParksSelection.swift
//  Wish We Were There
//

import Foundation

enum ViewFilter: String, CaseIterable, Identifiable {
    case all, open, walk, down
    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .open: return "Operating"
        case .walk: return "Walk on"
        case .down: return "Down"
        }
    }
}

enum ViewSort: String, CaseIterable, Identifiable {
    case waitDesc, waitAsc, name
    var id: String { rawValue }

    var label: String {
        switch self {
        case .waitDesc: return "Longest"
        case .waitAsc: return "Shortest"
        case .name: return "A\u{2013}Z"
        }
    }
}

func hottest(_ parks: [ParkSnapshot], limit: Int = 8) -> [Attraction] {
    parks.flatMap { $0.attractions }
        .filter { $0.status == .operating && $0.waitMinutes != nil }
        .sorted { ($0.waitMinutes ?? 0) > ($1.waitMinutes ?? 0) }
        .prefix(limit)
        .map { $0 }
}

func walkOns(_ parks: [ParkSnapshot], limit: Int = 8) -> [Attraction] {
    parks.flatMap { $0.attractions }
        .filter { $0.status == .operating && ($0.waitMinutes ?? Int.max) <= ParksConstants.walkOnMax }
        .sorted { ($0.waitMinutes ?? 0) < ($1.waitMinutes ?? 0) }
        .prefix(limit)
        .map { $0 }
}

func upcomingShows(_ parks: [ParkSnapshot], limit: Int = 8) -> [Showtime] {
    parks.flatMap { $0.shows }
        .sorted { $0.startTime < $1.startTime }
        .prefix(limit)
        .map { $0 }
}

func parkHeadline(_ park: ParkSnapshot) -> Attraction? {
    park.attractions
        .filter { $0.status == .operating && $0.waitMinutes != nil }
        .max { ($0.waitMinutes ?? 0) < ($1.waitMinutes ?? 0) }
}

func filterAttractions(_ attractions: [Attraction], filter: ViewFilter) -> [Attraction] {
    switch filter {
    case .all:
        return attractions
    case .open:
        return attractions.filter { $0.status == .operating }
    case .walk:
        return attractions.filter { $0.status == .operating && ($0.waitMinutes ?? Int.max) <= ParksConstants.walkOnMax }
    case .down:
        return attractions.filter { $0.status == .down || $0.status == .refurbishment }
    }
}

func sortAttractions(_ attractions: [Attraction], sort: ViewSort) -> [Attraction] {
    func rank(_ attraction: Attraction) -> Int {
        attraction.status == .operating ? (attraction.waitMinutes ?? -1) : -2
    }
    return attractions.sorted { lhs, rhs in
        if sort == .name {
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        let lv = rank(lhs)
        let rv = rank(rhs)
        if lv == -2 && rv != -2 { return false }
        if rv == -2 && lv != -2 { return true }
        return sort == .waitAsc ? lv < rv : lv > rv
    }
}

func groupByLand(_ attractions: [Attraction]) -> [(land: String, rides: [Attraction])] {
    var order: [String] = []
    var map: [String: [Attraction]] = [:]
    for ride in attractions {
        if map[ride.land] == nil {
            order.append(ride.land)
            map[ride.land] = []
        }
        map[ride.land]?.append(ride)
    }
    return order.map { (land: $0, rides: map[$0] ?? []) }
}

func findAttraction(in parks: [ParkSnapshot], id: String?) -> (park: ParkSnapshot, ride: Attraction)? {
    guard let id else { return nil }
    for park in parks {
        if let ride = park.attractions.first(where: { $0.id == id }) {
            return (park, ride)
        }
    }
    return nil
}
