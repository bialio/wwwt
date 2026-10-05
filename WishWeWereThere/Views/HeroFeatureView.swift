//
//  HeroFeatureView.swift
//  Wish We Were There
//

import SwiftUI

struct HeroFeatureView: View {
    let attraction: Attraction?
    var onSelect: (Attraction) -> Void

    var body: some View {
        if let attraction {
            let park = Park.byID[attraction.parkID]
            Button {
                onSelect(attraction)
            } label: {
                VStack(alignment: .leading, spacing: 16) {
                    Text("LONGEST WAIT RIGHT NOW")
                        .font(.caption.weight(.medium))
                        .tracking(2)
                        .foregroundStyle(Theme.muted)

                    HStack(alignment: .bottom, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(attraction.name)
                                .font(Theme.displayFont(40))
                                .foregroundStyle(Theme.fg)
                                .lineLimit(2)
                            if let park {
                                Text("\(park.shortName)   \u{00b7}   \(attraction.land)")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        Spacer(minLength: 24)
                        WaitFigureView(attraction: attraction, size: .hero)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(heroBackground(for: park))
            }
            .buttonStyle(.card)
            // Match the card platter to our background so the corners don't double up.
            .buttonBorderShape(.roundedRectangle(radius: Theme.cornerLarge))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("THIS EVENING")
                    .font(.caption.weight(.medium))
                    .tracking(2)
                    .foregroundStyle(Theme.muted)
                Text("The parks have gone quiet.")
                    .font(Theme.displayFont(32))
                    .foregroundStyle(Theme.fg)
                Text("Live waits will return when the gates open. Sit tight \u{2014} the lanterns come back on in the morning.")
                    .foregroundStyle(Theme.muted)
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.elevated))
        }
    }

    private func heroBackground(for park: Park?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.elevated)
            if let park {
                RoundedRectangle(cornerRadius: Theme.cornerLarge)
                    .fill(
                        RadialGradient(
                            colors: [Theme.atmosphere(park.atmosphere).opacity(0.3), .clear],
                            center: .topTrailing,
                            startRadius: 10,
                            endRadius: 420
                        )
                    )
            }
        }
    }
}
