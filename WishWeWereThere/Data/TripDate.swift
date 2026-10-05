//
//  TripDate.swift
//  Wish We Were There
//
//  Shared with the TopShelf extension — keep this file free of app-only
//  model dependencies.
//

import Foundation

func toDateKey(_ date: Date) -> String {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
}

func parseDateKey(_ key: String?) -> Date? {
    guard let key else { return nil }
    let parts = key.split(separator: "-")
    guard parts.count == 3, let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
        return nil
    }
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return Calendar.current.date(from: components)
}

func daysUntil(_ key: String, now: Date = Date()) -> Int? {
    guard let target = parseDateKey(key) else { return nil }
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: now)
    let targetDay = calendar.startOfDay(for: target)
    let delta = calendar.dateComponents([.day], from: today, to: targetDay).day
    return delta
}

func tripCopy(_ key: String?, now: Date = Date()) -> (kicker: String, title: String) {
    guard let key, let days = daysUntil(key, now: now) else {
        return (kicker: "Next trip", title: "Set a date")
    }
    if days > 1 { return (kicker: "Going home in", title: "\(days) days") }
    if days == 1 { return (kicker: "Going home in", title: "1 day") }
    if days == 0 { return (kicker: "Going home", title: "Today") }
    return (kicker: "Welcome home", title: "Set the next trip")
}
