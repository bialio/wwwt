//
//  ContentProvider.swift
//  TopShelf
//
//  Created by Brian Lindstrom on 10/4/26.
//

import TVServices
import SwiftUI
import UIKit

class ContentProvider: TVTopShelfContentProvider {

    private static let appGroupID = "group.com.thelindstrom.wwwt.shared"
    private static let tripDateKey = "wwwt.tripDate"
    private static let topWaitsKey = "wwwt.topWaits"
    private static let countdownIdentifier = "trip-countdown"
    private static let waitsIdentifier = "trip-top-waits"
    private static let countdownFileName = "trip-countdown.png"
    private static let waitsFileName = "trip-top-waits.png"

    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        let tripDate = defaults?.string(forKey: Self.tripDateKey)
        let tripCopy = Self.tripCopy(tripDate)
        let waits = Self.waitEntries(from: defaults?.array(forKey: Self.topWaitsKey) as? [[String: Any]])

        guard let background = await Self.loadBackground() else { return nil }

        async let countdownURL = Self.renderImage(
            fileName: Self.countdownFileName,
            background: background,
            alignment: .center
        ) { size in CountdownCardView(kicker: tripCopy.kicker, title: tripCopy.title, size: size) }

        async let waitsURL = Self.renderImage(
            fileName: Self.waitsFileName,
            background: background,
            alignment: .trailing
        ) { size in TopWaitsCardView(waits: waits, size: size) }

        guard let countdownImageURL = await countdownURL, let waitsImageURL = await waitsURL else {
            return nil
        }

        let countdownItem = TVTopShelfSectionedItem(identifier: Self.countdownIdentifier)
        countdownItem.imageShape = .hdtv
        countdownItem.setImageURL(countdownImageURL, for: .screenScale1x)
        countdownItem.setImageURL(countdownImageURL, for: .screenScale2x)
        countdownItem.title = tripCopy.title

        let waitsItem = TVTopShelfSectionedItem(identifier: Self.waitsIdentifier)
        waitsItem.imageShape = .hdtv
        waitsItem.setImageURL(waitsImageURL, for: .screenScale1x)
        waitsItem.setImageURL(waitsImageURL, for: .screenScale2x)
        waitsItem.title = "Longest waits right now"

        if let openURL = URL(string: "wishwewerethere://") {
            countdownItem.displayAction = TVTopShelfAction(url: openURL)
            waitsItem.displayAction = TVTopShelfAction(url: openURL)
        }

        let collection = TVTopShelfItemCollection(items: [countdownItem, waitsItem])
        return TVTopShelfSectionedContent(sections: [collection])
    }

    @MainActor
    private static func loadBackground() -> UIImage? {
        guard let url = Bundle.main.url(forResource: "background", withExtension: "png"),
              let data = try? Data(contentsOf: url),
              let fullImage = UIImage(data: data),
              let cgImage = fullImage.cgImage else {
            return nil
        }
        // The source artwork has a title baked into its lower third; crop that away
        // so our own card text is the only text layered on top.
        let cropHeight = cgImage.height * 2 / 3
        guard let cropped = cgImage.cropping(to: CGRect(x: 0, y: 0, width: cgImage.width, height: cropHeight)) else {
            return fullImage
        }
        return UIImage(cgImage: cropped)
    }

    @MainActor
    private static func renderImage<Content: View>(
        fileName: String,
        background: UIImage,
        alignment: Alignment,
        @ViewBuilder content: @escaping (CGSize) -> Content
    ) async -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }

        let size = TVTopShelfSectionedContent.imageSize(for: .hdtv)
        let renderer = ImageRenderer(
            content: CardBackground(background: background, alignment: alignment, size: size) { content(size) }
        )
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(size)

        guard let cgImage = renderer.cgImage,
              let data = UIImage(cgImage: cgImage).pngData() else {
            return nil
        }

        let fileURL = containerURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
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

    private static func waitEntries(from array: [[String: Any]]?) -> [WaitEntry] {
        guard let array else { return [] }
        return array.compactMap { dict in
            guard let attraction = dict["attraction"] as? String,
                  let minutes = dict["minutes"] as? Int else {
                return nil
            }
            return WaitEntry(attraction: attraction, minutes: minutes)
        }
    }
}

private struct WaitEntry {
    let attraction: String
    let minutes: Int
}

private enum WaitBandThresholds {
    static let walkOnMax = 15
    static let moderateMax = 45

    static func color(for minutes: Int) -> Color {
        if minutes <= walkOnMax { return Color(hex: 0x8aa186) }
        if minutes <= moderateMax { return Color(hex: 0xc4a574) }
        return Color(hex: 0xc17b6a)
    }
}

/// Shared chrome for both cards: the cropped brand artwork, a legibility gradient, then the card's own content on top.
private struct CardBackground<Content: View>: View {
    let background: UIImage
    let alignment: Alignment
    let size: CGSize
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color(hex: 0x0b0c0f)
            Image(uiImage: background)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height, alignment: alignment)
                .clipped()
                .opacity(0.55)
            LinearGradient(
                colors: [Color(hex: 0x0b0c0f).opacity(0.35), Color(hex: 0x0b0c0f).opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            content()
                .padding(44)
                .frame(width: size.width, height: size.height, alignment: .bottomLeading)
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct CountdownCardView: View {
    let kicker: String
    let title: String
    let size: CGSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(kicker.uppercased())
                .font(.system(size: 24, weight: .medium))
                .tracking(2.5)
                .foregroundStyle(Color(hex: 0x9a958c))
            Text(title)
                .font(.system(size: 72, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: 0xece8df))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

private struct TopWaitsCardView: View {
    let waits: [WaitEntry]
    let size: CGSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LONGEST WAITS RIGHT NOW")
                .font(.system(size: 24, weight: .medium))
                .tracking(2.5)
                .foregroundStyle(Color(hex: 0x9a958c))

            if waits.isEmpty {
                Text("The parks have gone quiet.")
                    .font(.system(size: 36, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: 0xece8df))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(waits.prefix(4).enumerated()), id: \.offset) { _, wait in
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text("\(wait.minutes)")
                                .font(.system(size: 30, weight: .semibold, design: .serif))
                                .foregroundStyle(WaitBandThresholds.color(for: wait.minutes))
                                .frame(minWidth: 52, alignment: .trailing)
                            Text("min")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(hex: 0x6f6b64))
                            Text(wait.attraction)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color(hex: 0xece8df))
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
