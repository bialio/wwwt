//
//  ShowsRailView.swift
//  Wish We Were There
//

import SwiftUI

struct ShowsRailView: View {
    let shows: [Showtime]

    var body: some View {
        if !shows.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Tonight on stage")
                        .font(Theme.displayFont(26))
                        .foregroundStyle(Theme.fg)
                    Spacer()
                    Text("Next showtimes")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(shows) { show in
                            let park = Park.byID[show.parkID]
                            VStack(alignment: .leading, spacing: 10) {
                                Text(formatTime(show.startTime))
                                    .font(Theme.displayFont(26))
                                    .foregroundStyle(Theme.fg)
                                    .monospacedDigit()
                                Text(show.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.fg)
                                    .lineLimit(2)
                                if let park {
                                    Text(park.shortName)
                                        .font(.caption)
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                            .padding(16)
                            .frame(width: 240, height: 140, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Theme.cornerMedium).fill(Theme.elevated))
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }
}
