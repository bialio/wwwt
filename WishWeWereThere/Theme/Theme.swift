//
//  Theme.swift
//  Wish We Were There
//

import SwiftUI

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Theme {
    static let bg = Color(hex: 0x0b0c0f)
    static let surface = Color(hex: 0x12141a)
    static let elevated = Color(hex: 0x1c1f28)
    static let fg = Color(hex: 0xece8df)
    static let muted = Color(hex: 0x9a958c)
    static let subtle = Color(hex: 0x6f6b64)
    static let accent = Color(hex: 0xc9c4b8)
    static let accentFg = Color(hex: 0x0b0c0f)

    static let waitWalk = Color(hex: 0x8aa186)
    static let waitMid = Color(hex: 0xc4a574)
    static let waitLong = Color(hex: 0xc17b6a)
    static let waitDown = Color(hex: 0xb96a6a)

    static let cornerSmall: CGFloat = 8
    static let cornerMedium: CGFloat = 12
    static let cornerLarge: CGFloat = 20
    static let cornerXL: CGFloat = 28

    static let display = Font.system(.title, design: .serif, weight: .semibold)

    static func displayFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func atmosphere(_ atmosphere: ParkAtmosphere) -> Color {
        switch atmosphere {
        case .mk: return Color(hex: 0x5f82b0)
        case .epcot: return Color(hex: 0xdad7cc)
        case .hs: return Color(hex: 0xa8453f)
        case .ak: return Color(hex: 0x5f7a52)
        }
    }

    static func band(_ band: WaitBand) -> Color {
        switch band {
        case .walk: return waitWalk
        case .moderate: return waitMid
        case .long: return waitLong
        case .down: return waitDown
        case .closed: return subtle
        case .open: return fg
        }
    }
}
