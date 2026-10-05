//
//  TripCountdownView.swift
//  Wish We Were There
//

import SwiftUI

struct TripCountdownView: View {
    let tripDate: String?
    let now: Date
    let onTap: () -> Void

    var body: some View {
        let copy = tripCopy(tripDate, now: now)
        let when = tripDate.map(formatTripDate)

        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(copy.kicker.uppercased())
                    .font(.caption2.weight(.medium))
                    .tracking(1.5)
                    .foregroundStyle(Theme.muted)
                Text(copy.title)
                    .font(Theme.displayFont(22))
                    .foregroundStyle(Theme.fg)
                    .monospacedDigit()
                if let when {
                    Text(when)
                        .font(.caption)
                        .foregroundStyle(Theme.subtle)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 180, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.cornerMedium).fill(Theme.elevated))
        }
        .buttonStyle(.card)
        // Match the card platter to our background so the corners don't double up.
        .buttonBorderShape(.roundedRectangle(radius: Theme.cornerMedium))
    }
}

struct TripPickerView: View {
    @Binding var tripDate: String?
    let onClose: () -> Void

    @State private var cursor: Date

    init(tripDate: Binding<String?>, onClose: @escaping () -> Void) {
        self._tripDate = tripDate
        self.onClose = onClose
        let start = parseDateKey(tripDate.wrappedValue) ?? Date()
        let components = Calendar.current.dateComponents([.year, .month], from: start)
        self._cursor = State(initialValue: Calendar.current.date(from: components) ?? start)
    }

    private static let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("NEXT TRIP")
                        .font(.caption.weight(.medium))
                        .tracking(1.5)
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                }

                Text("When are you going home?")
                    .font(Theme.displayFont(34))
                    .foregroundStyle(Theme.fg)
                    .padding(.top, 24)
                Text("Pick the first park day. It stays on this set.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 4)

                HStack {
                    Button(action: { shiftMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Text(monthLabel)
                        .font(Theme.displayFont(22))
                        .foregroundStyle(Theme.fg)
                    Spacer()
                    Button(action: { shiftMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 32)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                    ForEach(Array(Self.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol)
                            .font(.caption2.weight(.medium))
                            .tracking(1)
                            .foregroundStyle(Theme.subtle)
                            .frame(height: 24)
                            .id("weekday-\(index)")
                    }
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayButton(day)
                        } else {
                            Color.clear.frame(width: 56, height: 56)
                        }
                    }
                }
                .padding(.top, 16)

                if tripDate != nil {
                    Button("Clear trip date") {
                        tripDate = nil
                        onClose()
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 32)
                }
            }
            .padding(48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.surface)
        .onExitCommand(perform: onClose)
    }

    private var monthLabel: String {
        cursor.formatted(.dateTime.month(.wide).year())
    }

    private var cells: [Int?] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: cursor)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
        else { return [] }
        let leadingPad = calendar.component(.weekday, from: firstOfMonth) - 1
        var result: [Int?] = Array(repeating: nil, count: leadingPad)
        result.append(contentsOf: range.map { Optional($0) })
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private func dayButton(_ day: Int) -> some View {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: cursor)
        let date = calendar.date(from: DateComponents(year: components.year, month: components.month, day: day)) ?? cursor
        let key = toDateKey(date)
        let isTrip = key == tripDate
        let isToday = key == toDateKey(Date())

        return Button {
            tripDate = key
            onClose()
        } label: {
            Text("\(day)")
                .font(.body)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(isTrip ? Theme.accentFg : Theme.fg)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(isTrip ? Theme.fg : (isToday ? Theme.elevated : Color.clear))
                )
        }
        .buttonStyle(.card)
    }

    private func shiftMonth(by delta: Int) {
        cursor = Calendar.current.date(byAdding: .month, value: delta, to: cursor) ?? cursor
    }
}
