//
//  WaitFigureView.swift
//  Wish We Were There
//

import SwiftUI

enum WaitFigureSize {
    case sm, md, lg, hero

    var numberSize: CGFloat {
        switch self {
        case .hero: return 96
        case .lg: return 64
        case .md: return 48
        case .sm: return 36
        }
    }

    var unitSize: CGFloat {
        switch self {
        case .hero: return 28
        case .lg: return 22
        case .md: return 18
        case .sm: return 16
        }
    }
}

struct WaitFigureView: View {
    let attraction: Attraction
    var size: WaitFigureSize = .md

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(attraction.waitLabel)
                .font(Theme.displayFont(size.numberSize))
                .foregroundStyle(Theme.band(attraction.waitBand))
                .lineLimit(1)
            if attraction.showsWaitUnit {
                Text("min")
                    .font(.system(size: size.unitSize, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
        }
        .monospacedDigit()
    }
}
