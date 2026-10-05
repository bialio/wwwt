//
//  AttractionCardView.swift
//  Wish We Were There
//

import SwiftUI

struct AttractionCardView: View {
    let attraction: Attraction
    var showPark: Bool = false
    var onSelect: () -> Void

    var body: some View {
        let park = Park.byID[attraction.parkID]
        let lane: String? = {
            guard let lightningLane = attraction.lightningLane, lightningLane.state == "AVAILABLE" else { return nil }
            return lightningLane.kind == .individual ? "ILL" : "LL"
        }()

        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(showPark ? (park?.shortName ?? "") : attraction.land)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                    Text(attraction.name)
                        .font(Theme.displayFont(18))
                        .foregroundStyle(Theme.fg)
                        .lineLimit(2)
                    HStack(spacing: 10) {
                        if let lane {
                            Text(lane)
                                .font(.caption2.weight(.semibold))
                                .tracking(1)
                                .foregroundStyle(Theme.fg.opacity(0.8))
                        }
                        if let single = attraction.singleRiderMinutes {
                            Text("SINGLE \(single)M")
                                .font(.caption2.weight(.semibold))
                                .tracking(1)
                                .foregroundStyle(Theme.muted)
                        }
                    }
                }
                Spacer(minLength: 12)
                WaitFigureView(attraction: attraction, size: .md)
                    .fixedSize()
                    .layoutPriority(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 124, maxHeight: 124, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.cornerMedium).fill(Theme.elevated))
        }
        .buttonStyle(.card)
        // Match the card platter to our background so the corners don't double up.
        .buttonBorderShape(.roundedRectangle(radius: Theme.cornerMedium))
    }
}
