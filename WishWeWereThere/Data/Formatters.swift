//
//  Formatters.swift
//  Wish We Were There
//

import Foundation

let easternTimeZone = TimeZone(identifier: "America/New_York")!

func formatTime(_ date: Date?, timeZone: TimeZone = easternTimeZone) -> String {
    guard let date else { return "" }
    return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone))
}

func formatHourOnly(_ date: Date, timeZone: TimeZone = easternTimeZone) -> String {
    date.formatted(Date.FormatStyle(timeZone: timeZone).hour())
}

func formatClock(_ date: Date, timeZone: TimeZone = easternTimeZone) -> String {
    let weekday = date.formatted(Date.FormatStyle(timeZone: timeZone).weekday(.abbreviated))
    let time = date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone))
    return "\(weekday) \(time)"
}

func formatHours(_ hours: ParkHours, timeZone: TimeZone = easternTimeZone) -> String {
    if hours.opensAt == nil && hours.closesAt == nil { return "Hours unavailable" }
    let open = formatTime(hours.opensAt, timeZone: timeZone)
    let close = formatTime(hours.closesAt, timeZone: timeZone)
    if !open.isEmpty && !close.isEmpty { return "\(open) \u{2013} \(close)" }
    return open.isEmpty ? close : open
}

func formatHoursCompact(_ hours: ParkHours, timeZone: TimeZone = easternTimeZone) -> String {
    func compact(_ date: Date?) -> String {
        formatTime(date, timeZone: timeZone)
            .replacingOccurrences(of: " AM", with: "a")
            .replacingOccurrences(of: " PM", with: "p")
    }
    let open = compact(hours.opensAt)
    let close = compact(hours.closesAt)
    if !open.isEmpty && !close.isEmpty { return "\(open) \u{2013} \(close)" }
    if !open.isEmpty { return open }
    if !close.isEmpty { return close }
    return "Hours unavailable"
}

func formatRelative(_ date: Date?, at now: Date = Date()) -> String {
    guard let date else { return "Just now" }
    let delta = max(0, now.timeIntervalSince(date))
    if delta < 20 { return "Just now" }
    if delta < 60 { return "\(Int(delta.rounded()))s ago" }
    let minutes = (delta / 60).rounded()
    if minutes < 60 { return "\(Int(minutes)) min ago" }
    let hours = (minutes / 60).rounded()
    return "\(Int(hours))h ago"
}

func formatTripDate(_ key: String) -> String {
    guard let date = parseDateKey(key) else { return "" }
    return date.formatted(.dateTime.month(.abbreviated).day().year())
}

func waitBand(status: LiveStatus, waitMinutes: Int?) -> WaitBand {
    if status == .down { return .down }
    if status == .closed || status == .refurbishment { return .closed }
    guard let waitMinutes else { return .open }
    if waitMinutes <= ParksConstants.walkOnMax { return .walk }
    if waitMinutes <= ParksConstants.moderateMax { return .moderate }
    return .long
}

func waitLabel(status: LiveStatus, waitMinutes: Int?) -> String {
    switch status {
    case .down: return "Down"
    case .refurbishment: return "Refurb"
    case .closed: return "Closed"
    case .operating:
        guard let waitMinutes else { return "Open" }
        return "\(waitMinutes)"
    }
}

func statusCopy(_ status: LiveStatus) -> String {
    switch status {
    case .down: return "Temporarily down"
    case .refurbishment: return "Under refurbishment"
    case .closed: return "Closed"
    case .operating: return "Operating"
    }
}

extension Attraction {
    var waitBand: WaitBand { WishWeWereThere.waitBand(status: status, waitMinutes: waitMinutes) }
    var waitLabel: String { WishWeWereThere.waitLabel(status: status, waitMinutes: waitMinutes) }
    var showsWaitUnit: Bool { status == .operating && waitMinutes != nil }
}
