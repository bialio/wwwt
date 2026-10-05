//
//  ContentView.swift
//  Wish We Were There
//
//  Created by Brian Lindstrom on 10/3/26.
//

import SwiftUI

struct ContentView: View {
    @State private var store = ParksStore()
    @State private var path = NavigationPath()
    @State private var selectedAttraction: Attraction?
    @State private var tripPickerOpen = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    header
                    content
                    footer
                }
                .padding(60)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationDestination(for: String.self) { parkID in
                if let park = store.parks.first(where: { $0.id == parkID }) {
                    ParkView(
                        park: park,
                        onSelectAttraction: { selectedAttraction = $0 }
                    )
                }
            }
        }
        .sheet(item: $selectedAttraction) { attraction in
            if let found = findAttraction(in: store.parks, id: attraction.id) {
                AttractionDetailView(
                    park: found.park,
                    ride: found.ride,
                    onClose: { selectedAttraction = nil }
                )
            }
        }
        .sheet(isPresented: $tripPickerOpen) {
            TripPickerView(tripDate: $store.tripDate, onClose: { tripPickerOpen = false })
        }
        .task {
            store.startAutoRefresh()
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("WALT DISNEY WORLD")
                    .font(.caption.weight(.medium))
                    .tracking(2)
                    .foregroundStyle(Theme.muted)
                Text("Wish We Were There")
                    .font(Theme.displayFont(44))
                    .foregroundStyle(Theme.fg)
                    .lineLimit(1)
                    .fixedSize()
                Text("Bring a little of the parks home.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            TimelineView(.periodic(from: .now, by: 15)) { context in
                VStack(alignment: .trailing, spacing: 20) {
                    Text("\(formatClock(context.date)) on Main Street, USA")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        .monospacedDigit()
                    TripCountdownView(tripDate: store.tripDate, now: context.date, onTap: { tripPickerOpen = true })
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        if let resort = store.resort, !resort.isOK, resort.parks.isEmpty {
            errorState
        } else {
            HomeView(
                parks: store.parks,
                onSelectAttraction: { selectedAttraction = $0 },
                onSelectPark: { park in path.append(park.id) }
            )
        }
    }

    private var errorState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The feed went quiet.")
                .font(Theme.displayFont(28))
                .foregroundStyle(Theme.fg)
            if case .failure(_, let message, _) = store.resort {
                Text("\(message) Refresh in a moment and the waits will come back.")
                    .foregroundStyle(Theme.muted)
            }
            Button("Try again") {
                Task { await store.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.elevated))
    }

    private var footer: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            HStack(alignment: .center, spacing: 16) {
                Text("Live waits via ThemeParks.wiki. Not affiliated with The Walt Disney Company.")
                    .font(.caption)
                    .foregroundStyle(Theme.subtle)
                Spacer()
                Text(statusLine(at: context.date))
                    .font(.caption)
                    .foregroundStyle(Theme.subtle)
                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statusLine(at now: Date) -> String {
        guard let resort = store.resort else { return "Loading\u{2026}" }
        if !resort.isOK { return "Feed paused" }
        return "Updated \(formatRelative(resort.fetchedAt, at: now))"
    }
}

#Preview {
    ContentView()
}
