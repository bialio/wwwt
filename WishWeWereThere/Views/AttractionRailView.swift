//
//  AttractionRailView.swift
//  Wish We Were There
//

import SwiftUI

struct AttractionRailView: View {
    let title: String
    var subtitle: String?
    let attractions: [Attraction]
    var showPark: Bool = true
    let favorites: Set<String>
    let onSelect: (Attraction) -> Void

    var body: some View {
        if !attractions.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(Theme.displayFont(26))
                        .foregroundStyle(Theme.fg)
                    Spacer()
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16) {
                    ForEach(Array(attractions.enumerated()), id: \.element.id) { index, ride in
                        AttractionCardView(
                            attraction: ride,
                            showPark: showPark,
                            featured: index == 0,
                            isFavorite: favorites.contains(ride.id),
                            onSelect: { onSelect(ride) }
                        )
                    }
                }
            }
        }
    }
}
