//
//  ParkView.swift
//  Wish We Were There
//

import SwiftUI

struct ParkView: View {
    let park: ParkSnapshot
    let favorites: Set<String>
    let onSelectAttraction: (Attraction) -> Void

    @State private var filter: ViewFilter = .all
    @State private var sort: ViewSort = .waitDesc

    var body: some View {
        let rides = sortAttractions(filterAttractions(park.attractions, filter: filter, favorites: favorites), sort: sort)
        let groups = groupByLand(rides)
        let shows = upcomingShows([park], limit: 6)

        VStack(alignment: .leading, spacing: 32) {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        ParkMarkView(mark: park.park.mark, color: Theme.fg.opacity(0.7))
                            .frame(width: 30, height: 30)
                        Text(park.park.shortName)
                            .font(Theme.displayFont(34))
                            .foregroundStyle(Theme.fg)
                    }
                    Text(formatHours(park.hours, timeZone: park.timezone) + (park.hours.isOpen ? " \u{00b7} Open now" : " \u{00b7} Closed"))
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }

                Spacer()

                HStack(spacing: 8) {
                    ForEach(ViewSort.allCases) { option in
                        Button(option.label) { sort = option }
                            .buttonStyle(.bordered)
                            .tint(sort == option ? Theme.fg : Theme.elevated)
                    }
                }
            }

            HStack(spacing: 8) {
                ForEach(ViewFilter.allCases) { option in
                    Button(option.label) { filter = option }
                        .buttonStyle(.bordered)
                        .tint(filter == option ? Theme.fg : Theme.elevated)
                }
            }

            if rides.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nothing in this view.")
                        .font(Theme.displayFont(26))
                        .foregroundStyle(Theme.fg)
                    Text("Try another filter, or save a few favorites from the operating list to build a porch-side watchlist.")
                        .foregroundStyle(Theme.muted)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.elevated))
            } else {
                ForEach(groups, id: \.land) { group in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(group.land.uppercased())
                            .font(.caption.weight(.medium))
                            .tracking(1.5)
                            .foregroundStyle(Theme.muted)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                            ForEach(group.rides) { ride in
                                AttractionCardView(
                                    attraction: ride,
                                    isFavorite: favorites.contains(ride.id),
                                    onSelect: { onSelectAttraction(ride) }
                                )
                            }
                        }
                    }
                }
            }

            ShowsRailView(shows: shows)
        }
        .navigationTitle(park.park.shortName)
    }
}
