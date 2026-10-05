//
//  ParkPosterView.swift
//  Wish We Were There
//

import SwiftUI

struct ParkPosterView: View {
    let park: ParkSnapshot
    var onSelect: () -> Void

    var body: some View {
        let headline = parkHeadline(park)

        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(park.hours.isOpen ? "OPEN NOW" : "CURRENTLY CLOSED")
                            .font(.caption2.weight(.medium))
                            .tracking(1.5)
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(park.park.shortName)
                            .font(Theme.displayFont(26))
                            .foregroundStyle(Theme.fg)
                            .lineLimit(2)
                    }
                    Spacer()
                    ParkMarkView(mark: park.park.mark, color: Theme.fg.opacity(0.7))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(formatHoursCompact(park.hours, timeZone: park.timezone))
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(Theme.muted)

                    if let headline {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(headline.name)
                                .font(.caption)
                                .foregroundStyle(Theme.muted)
                                .lineLimit(2)
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(headline.waitMinutes ?? 0)")
                                    .font(Theme.displayFont(30))
                                    .foregroundStyle(Theme.fg)
                                    .monospacedDigit()
                                Text("min")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                    } else {
                        Text("No waits reporting right now")
                            .font(.caption)
                            .foregroundStyle(Theme.subtle)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(posterBackground)
        }
        .buttonStyle(.card)
        // Match the card platter to our background so the corners don't double up.
        .buttonBorderShape(.roundedRectangle(radius: Theme.cornerLarge))
        .frame(height: 248)
    }

    private var posterBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.elevated)
            RoundedRectangle(cornerRadius: Theme.cornerLarge)
                .fill(
                    RadialGradient(
                        colors: [Theme.atmosphere(park.park.atmosphere).opacity(0.3), .clear],
                        center: .topTrailing,
                        startRadius: 10,
                        endRadius: 260
                    )
                )
        }
    }
}
