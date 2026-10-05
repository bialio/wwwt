//
//  AttractionDetailView.swift
//  Wish We Were There
//

import SwiftUI

struct AttractionDetailView: View {
    let park: ParkSnapshot
    let ride: Attraction
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(park.park.shortName.uppercased())
                        .font(.caption.weight(.medium))
                        .tracking(1.5)
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                }

                Text(ride.name)
                    .font(Theme.displayFont(34))
                    .foregroundStyle(Theme.fg)
                    .padding(.top, 24)
                Text(ride.land)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 4)

                HStack(alignment: .bottom) {
                    WaitFigureView(attraction: ride, size: .hero)
                    Spacer()
                    Text(statusCopy(ride.status))
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    if let rideHours = ride.rideHours {
                        detailRow(
                            "Ride hours",
                            "\(formatTime(rideHours.open, timeZone: park.timezone)) \u{2013} \(formatTime(rideHours.close, timeZone: park.timezone))"
                        )
                    }
                    let parkHoursText = formatHours(park.hours, timeZone: park.timezone)
                    if parkHoursText != "Hours unavailable" {
                        detailRow("Park hours", parkHoursText)
                    }
                    if let lane = ride.lightningLane, lane.state == "AVAILABLE" {
                        let label = lane.kind == .individual ? "Lightning Lane" : "Multi Pass"
                        let value: String = {
                            if let start = lane.returnStart {
                                return "\(formatTime(start, timeZone: park.timezone)) \u{2013} \(formatTime(lane.returnEnd, timeZone: park.timezone))"
                            }
                            return lane.price ?? "Available"
                        }()
                        detailRow(label, value)
                    }
                    if let single = ride.singleRiderMinutes {
                        detailRow("Single rider", "\(single) min")
                    }
                }
                .padding(.top, 40)

                if !ride.forecast.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WAIT FORECAST")
                            .font(.caption.weight(.medium))
                            .tracking(1.5)
                            .foregroundStyle(Theme.muted)
                        ForecastBarsView(forecast: ride.forecast, timeZone: park.timezone)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(48)
        }
        .background(Theme.surface)
        .onExitCommand(perform: onClose)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.muted)
            Spacer()
            Text(value).foregroundStyle(Theme.fg).monospacedDigit()
        }
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.fg.opacity(0.08)).frame(height: 1)
        }
    }
}

private struct ForecastBarsView: View {
    let forecast: [ForecastPoint]
    let timeZone: TimeZone

    var body: some View {
        let step = max(1, Int((Double(forecast.count) / 8.0).rounded(.up)))
        let points = forecast.enumerated().filter { $0.offset % step == 0 }.map { $0.element }
        let maxWait = max(15, points.compactMap { $0.waitMinutes }.max() ?? 0)

        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                let ratio = point.waitMinutes == nil ? 0.08 : max(0.08, Double(point.waitMinutes!) / Double(maxWait))
                VStack(spacing: 6) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.fg.opacity(0.4))
                        .frame(height: max(4, 140 * ratio))
                    Text(formatHourOnly(point.time, timeZone: timeZone))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.subtle)
                        .monospacedDigit()
                }
            }
        }
        .frame(height: 170)
    }
}
