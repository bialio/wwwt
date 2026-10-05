//
//  ContentProvider.swift
//  TopShelf
//

import Foundation
import TVServices

class ContentProvider: TVTopShelfContentProvider {

    private static let appGroupID = "group.com.thelindstrom.wwwt.shared"
    private static let tripDateKey = "wwwt.tripDate"
    private static let countdownIdentifier = "trip-countdown"
    private static let waitsIdentifier = "trip-top-waits"

    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        let tripCopy = Self.tripCopy(defaults?.string(forKey: Self.tripDateKey))
        let countdown = Self.sharedImage("trip-countdown") ?? Self.bundledImage()
        let waitsImage = Self.sharedImage("trip-top-waits") ?? Self.bundledImage()
        guard let countdown, let waitsImage else { return nil }

        let countdownItem = TVTopShelfSectionedItem(identifier: Self.countdownIdentifier)
        countdownItem.imageShape = .hdtv
        countdownItem.setImageURL(countdown, for: .screenScale1x)
        countdownItem.setImageURL(countdown, for: .screenScale2x)
        countdownItem.title = tripCopy.title

        let waitsItem = TVTopShelfSectionedItem(identifier: Self.waitsIdentifier)
        waitsItem.imageShape = .hdtv
        waitsItem.setImageURL(waitsImage, for: .screenScale1x)
        waitsItem.setImageURL(waitsImage, for: .screenScale2x)
        waitsItem.title = "Longest waits right now"

        if let openURL = URL(string: "wishwewerethere://") {
            countdownItem.displayAction = TVTopShelfAction(url: openURL)
            waitsItem.displayAction = TVTopShelfAction(url: openURL)
        }

        let collection = TVTopShelfItemCollection(items: [countdownItem, waitsItem])
        return TVTopShelfSectionedContent(sections: [collection])
    }

    /// A file in the extension's private cache is what showed up as an empty grey card.
    private static func sharedImage(_ name: String) -> URL? {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        // Must match ShelfCardWriter: tvOS only allows writes under Library/Caches in the group folder.
        let directory = root.appendingPathComponent("Library/Caches/TopShelf", isDirectory: true)
        // The app stamps each write with a timestamp so the home screen does not reuse a cached card.
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.lastPathComponent.hasPrefix("\(name)-") && $0.pathExtension == "jpg" }
            .max { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func bundledImage() -> URL? {
        Bundle.main.url(forResource: "background", withExtension: "png")
    }

    private static func tripCopy(_ key: String?) -> (kicker: String, title: String) {
        guard let key, let days = daysUntil(key) else {
            return ("Next trip", "Set a date")
        }
        if days > 1 { return ("Going home in", "\(days) days") }
        if days == 1 { return ("Going home in", "1 day") }
        if days == 0 { return ("Going home", "Today") }
        return ("Welcome home", "Set the next trip")
    }

    private static func daysUntil(_ key: String) -> Int? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let calendar = Calendar.current
        guard let target = calendar.date(from: components) else { return nil }
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: target)
        return calendar.dateComponents([.day], from: today, to: targetDay).day
    }
}
