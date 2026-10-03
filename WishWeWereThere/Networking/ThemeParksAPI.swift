//
//  ThemeParksAPI.swift
//  Wish We Were There
//

import Foundation

// MARK: - Wire DTOs (ThemeParks.wiki v1)

private struct ApiWaitTime: Decodable { let waitTime: Int? }

private struct ApiReturnTime: Decodable {
    let state: String?
    let returnStart: String?
    let returnEnd: String?
}

private struct ApiPrice: Decodable { let formatted: String? }

private struct ApiPaidReturnTime: Decodable {
    let state: String?
    let returnStart: String?
    let returnEnd: String?
    let price: ApiPrice?
}

private struct ApiQueue: Decodable {
    let standby: ApiWaitTime?
    let singleRider: ApiWaitTime?
    let returnTime: ApiReturnTime?
    let paidReturnTime: ApiPaidReturnTime?

    enum CodingKeys: String, CodingKey {
        case standby = "STANDBY"
        case singleRider = "SINGLE_RIDER"
        case returnTime = "RETURN_TIME"
        case paidReturnTime = "PAID_RETURN_TIME"
    }
}

private struct ApiShowtime: Decodable {
    let startTime: String?
    let endTime: String?
}

private struct ApiForecastPoint: Decodable {
    let time: String?
    let waitTime: Int?
}

private struct ApiOperatingHoursSlot: Decodable {
    let type: String?
    let startTime: String?
    let endTime: String?
}

private struct ApiLiveItem: Decodable {
    let id: String?
    let name: String?
    let entityType: String?
    let status: String?
    let queue: ApiQueue?
    let showtimes: [ApiShowtime]?
    let forecast: [ApiForecastPoint]?
    let operatingHours: [ApiOperatingHoursSlot]?
    let lastUpdated: String?
}

private struct ApiLive: Decodable {
    let timezone: String?
    let liveData: [ApiLiveItem]?
}

private struct ApiScheduleEntry: Decodable {
    let date: String?
    let type: String?
    let openingTime: String?
    let closingTime: String?
    let description: String?
}

private struct ApiSchedule: Decodable {
    let timezone: String?
    let schedule: [ApiScheduleEntry]?
}

// MARK: - Date parsing

private let isoFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let isoPlain: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private func parseISODate(_ string: String?) -> Date? {
    guard let string else { return nil }
    return isoFractional.date(from: string) ?? isoPlain.date(from: string)
}

private func dateKey(for date: Date, in timeZone: TimeZone) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
}

// MARK: - DTO -> model parsing

private func asStatus(_ value: String?) -> LiveStatus {
    LiveStatus(rawValue: value ?? "") ?? .operating
}

private func parseLane(_ queue: ApiQueue?) -> LightningLane? {
    guard let queue else { return nil }
    if let paid = queue.paidReturnTime, paid.state == "AVAILABLE" || paid.state == "FINISHED" {
        return LightningLane(
            kind: .individual,
            state: paid.state ?? "UNKNOWN",
            returnStart: parseISODate(paid.returnStart),
            returnEnd: parseISODate(paid.returnEnd),
            price: paid.price?.formatted
        )
    }
    if let multi = queue.returnTime, multi.state == "AVAILABLE" || multi.state == "FINISHED" {
        return LightningLane(
            kind: .multi,
            state: multi.state ?? "UNKNOWN",
            returnStart: parseISODate(multi.returnStart),
            returnEnd: parseISODate(multi.returnEnd),
            price: nil
        )
    }
    return nil
}

private func parseRideHours(_ item: ApiLiveItem) -> (open: Date, close: Date)? {
    guard let slot = (item.operatingHours ?? []).first(where: { ($0.type ?? "").uppercased() == "OPERATING" }),
          let open = parseISODate(slot.startTime),
          let close = parseISODate(slot.endTime)
    else { return nil }
    return (open, close)
}

private func parseAttraction(_ item: ApiLiveItem, parkID: String) -> Attraction? {
    guard let id = item.id, let name = item.name else { return nil }
    return Attraction(
        id: id,
        name: name,
        parkID: parkID,
        land: landFor(parkID: parkID, name: name),
        status: asStatus(item.status),
        waitMinutes: item.queue?.standby?.waitTime,
        singleRiderMinutes: item.queue?.singleRider?.waitTime,
        lightningLane: parseLane(item.queue),
        lastUpdated: parseISODate(item.lastUpdated),
        rideHours: parseRideHours(item),
        forecast: (item.forecast ?? []).compactMap { point in
            guard let time = parseISODate(point.time) else { return nil }
            return ForecastPoint(time: time, waitMinutes: point.waitTime)
        }
    )
}

private func parseShows(_ item: ApiLiveItem, parkID: String, at now: Date) -> [Showtime] {
    guard let id = item.id, let name = item.name, let showtimes = item.showtimes, !showtimes.isEmpty else { return [] }
    let horizon = now.addingTimeInterval(-20 * 60)
    return showtimes.compactMap { show in
        guard let start = parseISODate(show.startTime), start >= horizon else { return nil }
        return Showtime(id: "\(id):\(show.startTime ?? "")", name: name, parkID: parkID, startTime: start, endTime: parseISODate(show.endTime))
    }
}

private func parseHours(_ schedule: ApiSchedule?, timeZone: TimeZone, at now: Date) -> ParkHours {
    let today = dateKey(for: now, in: timeZone)
    let entries = (schedule?.schedule ?? []).filter { $0.date == today }
    let operating = entries.first { $0.type == "OPERATING" }
    let early = entries.first {
        $0.type == "TICKETED_EVENT" && ($0.description ?? "").lowercased().contains("early")
    }
    let opensAt = parseISODate(operating?.openingTime)
    let closesAt = parseISODate(operating?.closingTime)
    let isOpen: Bool = {
        guard let opensAt, let closesAt else { return false }
        return opensAt <= now && now < closesAt
    }()
    return ParkHours(opensAt: opensAt, closesAt: closesAt, earlyEntryAt: parseISODate(early?.openingTime), isOpen: isOpen)
}

// MARK: - API client

enum ThemeParksAPIError: Error {
    case badResponse
}

actor ThemeParksAPI {
    static let shared = ThemeParksAPI()

    private var cachedPayload: ResortPayload?
    private var cacheExpires: Date = .distantPast

    func loadResort() async -> ResortPayload {
        let now = Date()
        if let cachedPayload, cacheExpires > now {
            return cachedPayload
        }
        let payload = await fetchResort(at: now)
        if payload.isOK {
            cachedPayload = payload
            cacheExpires = now.addingTimeInterval(ParksConstants.cacheInterval)
        }
        return payload
    }

    private func fetchResort(at now: Date) async -> ResortPayload {
        do {
            let parks = try await withThrowingTaskGroup(of: ParkSnapshot.self) { group in
                for park in Park.all {
                    group.addTask { try await Self.loadPark(park, at: now) }
                }
                var results: [ParkSnapshot] = []
                for try await snapshot in group {
                    results.append(snapshot)
                }
                return results
            }
            let ordered = Park.all.compactMap { park in parks.first { $0.id == park.id } }
            return .live(fetchedAt: now, parks: ordered)
        } catch {
            return .failure(fetchedAt: now, message: "The parks feed is unavailable right now.", parks: [])
        }
    }

    private static func getJSON<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        guard let url = URL(string: ParksConstants.themeParksAPI + path) else {
            throw ThemeParksAPIError.badResponse
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(ParksConstants.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ThemeParksAPIError.badResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func scheduleOrNil(_ park: Park) async -> ApiSchedule? {
        try? await getJSON(ApiSchedule.self, path: "/entity/\(park.id)/schedule")
    }

    private static func loadPark(_ park: Park, at now: Date) async throws -> ParkSnapshot {
        async let liveResult = getJSON(ApiLive.self, path: "/entity/\(park.id)/live")
        async let scheduleResult = scheduleOrNil(park)
        let live = try await liveResult
        let schedule = await scheduleResult

        let timeZoneID = live.timezone ?? schedule?.timezone ?? "America/New_York"
        let timeZone = TimeZone(identifier: timeZoneID) ?? TimeZone(identifier: "America/New_York")!

        let items = live.liveData ?? []
        let attractions = items
            .filter { $0.entityType == "ATTRACTION" }
            .compactMap { parseAttraction($0, parkID: park.id) }
        let shows = items
            .filter { $0.entityType == "SHOW" }
            .flatMap { parseShows($0, parkID: park.id, at: now) }
            .sorted { $0.startTime < $1.startTime }

        return ParkSnapshot(
            id: park.id,
            park: park,
            timezone: timeZone,
            hours: parseHours(schedule, timeZone: timeZone, at: now),
            attractions: attractions,
            shows: shows
        )
    }
}
