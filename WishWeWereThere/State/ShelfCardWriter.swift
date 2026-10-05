//
//  ShelfCardWriter.swift
//  Wish We Were There
//
//  The home screen cannot read the extension's private cache, so the app writes the cards
//  into the shared folder's Library/Caches, the only writable spot in it on tvOS.
//

import UIKit
import ImageIO
import TVServices

enum ShelfCardWriter {
    private static let appGroupID = "group.com.thelindstrom.wwwt.shared"
    private static let folderName = "TopShelf"

    static func writeCountdown(tripDate: String?) {
        let copy = tripCopy(tripDate)
        write(name: "trip-countdown") { context, size in
            drawChrome(context, size: size, focus: .center)
            let pad = size.width * 0.06
            let kicker = attributed(copy.kicker.uppercased(), size: size.height * 0.07, weight: .medium, color: UIColor(hex: 0x9a958c), tracking: 2.2)
            let title = attributed(copy.title, size: size.height * 0.2, weight: .semibold, color: UIColor(hex: 0xece8df), design: .serif)
            kicker.draw(with: CGRect(x: pad, y: size.height * 0.52, width: size.width - pad * 2, height: size.height * 0.12), options: [.usesLineFragmentOrigin], context: nil)
            title.draw(with: CGRect(x: pad, y: size.height * 0.64, width: size.width - pad * 2, height: size.height * 0.24), options: [.usesLineFragmentOrigin], context: nil)
        }
    }

    static func writeWaits(_ waits: [(name: String, minutes: Int)]) {
        write(name: "trip-top-waits") { context, size in
            drawChrome(context, size: size, focus: .trailing)
            let pad = size.width * 0.06
            let header = attributed("LONGEST WAITS RIGHT NOW", size: size.height * 0.065, weight: .medium, color: UIColor(hex: 0x9a958c), tracking: 1.6)
            header.draw(with: CGRect(x: pad, y: size.height * 0.40, width: size.width - pad * 2, height: size.height * 0.1), options: [.usesLineFragmentOrigin], context: nil)
            if waits.isEmpty {
                let quiet = attributed("The parks have gone quiet.", size: size.height * 0.1, weight: .semibold, color: UIColor(hex: 0xece8df), design: .serif)
                quiet.draw(with: CGRect(x: pad, y: size.height * 0.54, width: size.width - pad * 2, height: size.height * 0.2), options: [.usesLineFragmentOrigin], context: nil)
                return
            }
            var y = size.height * 0.52
            let row = size.height * 0.09
            for wait in waits.prefix(4) {
                let minutes = attributed("\(wait.minutes)", size: row * 0.72, weight: .semibold, color: color(for: wait.minutes), design: .serif)
                let unit = attributed("min", size: row * 0.4, weight: .medium, color: UIColor(hex: 0x6f6b64))
                let name = attributed(wait.name, size: row * 0.52, weight: .medium, color: UIColor(hex: 0xece8df))
                minutes.draw(with: CGRect(x: pad, y: y, width: size.width * 0.12, height: row), options: [.usesLineFragmentOrigin], context: nil)
                unit.draw(with: CGRect(x: pad + size.width * 0.12, y: y + row * 0.14, width: size.width * 0.1, height: row), options: [.usesLineFragmentOrigin], context: nil)
                name.draw(with: CGRect(x: pad + size.width * 0.22, y: y + row * 0.08, width: size.width * 0.68, height: row), options: [.usesLineFragmentOrigin], context: nil)
                y += row
            }
        }
    }

    private static func write(name: String, draw: (CGContext, CGSize) -> Void) {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            NSLog("ShelfCardWriter: no shared folder")
            return
        }
        // tvOS refuses writes at the group folder's root; only Library/Caches is writable there.
        let directory = root
            .appendingPathComponent("Library/Caches", isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
        let size = TVTopShelfSectionedContent.imageSize(for: .hdtv)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            UIGraphicsPushContext(renderer.cgContext)
            draw(renderer.cgContext, size)
            UIGraphicsPopContext()
        }
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            // The home screen caches cards by URL, so each write needs a new file name to be picked up.
            let stamp = Int(Date().timeIntervalSince1970 * 1000)
            let url = directory.appendingPathComponent("\(name)-\(stamp).jpg")
            try data.write(to: url, options: .noFileProtection)
            let stale = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasPrefix("\(name)") && $0 != url }
            for old in stale {
                try? FileManager.default.removeItem(at: old)
            }
            NSLog("ShelfCardWriter wrote %@", url.path)
        } catch {
            NSLog("ShelfCardWriter write failed: %@", error.localizedDescription)
        }
    }

    private enum Focus { case center, trailing }

    /// background.png ships in the Top Shelf extension, which is embedded in the app, so read it from there.
    private static let background: UIImage? = {
        guard let url = Bundle.main.builtInPlugInsURL?.appendingPathComponent("TopShelf.appex/background.png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            NSLog("ShelfCardWriter: no background image")
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: 960,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        // Keep the top two thirds; the bottom of the banner is mostly empty ground.
        let crop = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height * 2 / 3)
        return UIImage(cgImage: cgImage.cropping(to: crop) ?? cgImage)
    }()

    private static func drawChrome(_ context: CGContext, size: CGSize, focus: Focus) {
        let rect = CGRect(origin: .zero, size: size)
        context.setFillColor(UIColor(hex: 0x0b0c0f).cgColor)
        context.fill(rect)
        if let background {
            background.draw(in: aspectFill(background.size, in: rect, focus: focus), blendMode: .normal, alpha: 0.55)
        }
        let colors = [
            UIColor(hex: 0x0b0c0f).withAlphaComponent(0.25).cgColor,
            UIColor(hex: 0x0b0c0f).withAlphaComponent(0.92).cgColor,
        ] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
    }

    private static func aspectFill(_ imageSize: CGSize, in rect: CGRect, focus: Focus) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let fitted = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let x = focus == .trailing ? rect.maxX - fitted.width : rect.midX - fitted.width / 2
        return CGRect(origin: CGPoint(x: x, y: rect.midY - fitted.height / 2), size: fitted)
    }

    private static func tripCopy(_ key: String?) -> (kicker: String, title: String) {
        guard let key, let days = daysUntil(key) else { return ("Next trip", "Set a date") }
        if days > 1 { return ("Going home in", "\(days) days") }
        if days == 1 { return ("Going home in", "1 day") }
        if days == 0 { return ("Going home", "Today") }
        return ("Welcome home", "Set the next trip")
    }

    private static func daysUntil(_ key: String) -> Int? {
        let parts = key.split(separator: "-")
        guard parts.count == 3, let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let calendar = Calendar.current
        guard let target = calendar.date(from: components) else { return nil }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: target)).day
    }

    private static func color(for minutes: Int) -> UIColor {
        if minutes <= 15 { return UIColor(hex: 0x8aa186) }
        if minutes <= 45 { return UIColor(hex: 0xc4a574) }
        return UIColor(hex: 0xc17b6a)
    }

    private static func attributed(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor, design: UIFontDescriptor.SystemDesign? = nil, tracking: CGFloat = 0) -> NSAttributedString {
        var font = UIFont.systemFont(ofSize: size, weight: weight)
        if let design, let descriptor = font.fontDescriptor.withDesign(design) {
            font = UIFont(descriptor: descriptor, size: size)
        }
        return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .kern: tracking])
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
