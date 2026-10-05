//
//  ParkView.swift
//  Wish We Were There
//

import SwiftUI

private struct ContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 1800
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private func chunk<T>(_ items: [T], into size: Int) -> [[T]] {
    guard size > 0 else { return [items] }
    return stride(from: 0, to: items.count, by: size).map {
        Array(items[$0..<min($0 + size, items.count)])
    }
}

struct ParkView: View {
    let park: ParkSnapshot
    let onSelectAttraction: (Attraction) -> Void

    @State private var filter: ViewFilter = .all
    @State private var sort: ViewSort = .waitDesc
    @State private var contentWidth: CGFloat = ContentWidthKey.defaultValue

    private let minCardWidth: CGFloat = 320
    private let cardSpacing: CGFloat = 16

    var body: some View {
        let rides = sortAttractions(filterAttractions(park.attractions, filter: filter), sort: sort)
        let groups = groupByLand(rides)
        let shows = upcomingShows([park], limit: 6)
        let columns = max(1, Int((contentWidth + cardSpacing) / (minCardWidth + cardSpacing)))
        let cardWidth = (contentWidth - CGFloat(columns - 1) * cardSpacing) / CGFloat(columns)

        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 20) {
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

                    HStack(spacing: 8) {
                        ForEach(ViewSort.allCases) { option in
                            Button(option.label) { sort = option }
                                .buttonStyle(.bordered)
                                .tint(sort == option ? Theme.fg : Theme.elevated)
                        }
                    }

                    HStack(spacing: 8) {
                        ForEach(ViewFilter.allCases) { option in
                            Button(option.label) { filter = option }
                                .buttonStyle(.bordered)
                                .tint(filter == option ? Theme.fg : Theme.elevated)
                        }
                    }
                }
                .focusSection()

                if rides.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nothing in this view.")
                            .font(Theme.displayFont(26))
                            .foregroundStyle(Theme.fg)
                        Text("Try another filter to see what's open.")
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
                            VStack(alignment: .leading, spacing: cardSpacing) {
                                ForEach(Array(chunk(group.rides, into: columns).enumerated()), id: \.offset) { _, row in
                                    HStack(spacing: cardSpacing) {
                                        ForEach(row) { ride in
                                            AttractionCardView(
                                                attraction: ride,
                                                onSelect: { onSelectAttraction(ride) }
                                            )
                                            .frame(width: cardWidth)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ShowsRailView(shows: shows)
            }
            .padding(60)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ContentWidthKey.self, value: geo.size.width)
                }
            )
        }
        .onPreferenceChange(ContentWidthKey.self) { contentWidth = $0 }
        .background(Theme.bg.ignoresSafeArea())
    }
}
