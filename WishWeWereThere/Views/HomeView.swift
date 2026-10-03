//
//  HomeView.swift
//  Wish We Were There
//

import SwiftUI

struct HomeView: View {
    let parks: [ParkSnapshot]
    let favorites: Set<String>
    let onSelectAttraction: (Attraction) -> Void
    let onSelectPark: (ParkSnapshot) -> Void

    var body: some View {
        let top = hottest(parks, limit: 8)
        let walks = walkOns(parks, limit: 8)
        let shows = upcomingShows(parks, limit: 8)

        VStack(alignment: .leading, spacing: 40) {
            HeroFeatureView(attraction: top.first, onSelect: onSelectAttraction)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("The parks")
                        .font(Theme.displayFont(26))
                        .foregroundStyle(Theme.fg)
                    Spacer()
                    Text("Choose a gate")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                    ForEach(parks) { park in
                        ParkPosterView(park: park, onSelect: { onSelectPark(park) })
                    }
                }
            }

            AttractionRailView(
                title: "Hottest waits",
                subtitle: "Longest lines across the resort",
                attractions: Array(top.prefix(4)),
                favorites: favorites,
                onSelect: onSelectAttraction
            )

            AttractionRailView(
                title: "Walk on",
                subtitle: "Fifteen minutes or less",
                attractions: Array(walks.prefix(4)),
                favorites: favorites,
                onSelect: onSelectAttraction
            )

            ShowsRailView(shows: shows)
        }
    }
}
