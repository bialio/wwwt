//
//  ParkMarkShape.swift
//  Wish We Were There
//
//  Simple line-art marks per park, ported from the original 48x48 SVG line
//  icons (castle / sphere / marquee / tree). Draw with .stroke(), not .fill().
//

import SwiftUI

struct ParkMarkShape: Shape {
    let mark: ParkMark

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch mark {
        case .castle: addCastle(to: &path)
        case .sphere: addSphere(to: &path)
        case .marquee: addTowerOfTerror(to: &path)
        case .tree: addTreeOfLife(to: &path)
        }
        let transform = CGAffineTransform(scaleX: rect.width / 48, y: rect.height / 48)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY))
        return path.applying(transform)
    }

    private func addCastle(to path: inout Path) {
        path.move(to: CGPoint(x: 8, y: 40))
        path.addLine(to: CGPoint(x: 8, y: 22))
        path.addLine(to: CGPoint(x: 16, y: 16))
        path.addLine(to: CGPoint(x: 16, y: 24))
        path.addLine(to: CGPoint(x: 24, y: 10))
        path.addLine(to: CGPoint(x: 32, y: 24))
        path.addLine(to: CGPoint(x: 32, y: 16))
        path.addLine(to: CGPoint(x: 40, y: 22))
        path.addLine(to: CGPoint(x: 40, y: 40))

        path.move(to: CGPoint(x: 20, y: 40))
        path.addLine(to: CGPoint(x: 20, y: 32))
        path.addLine(to: CGPoint(x: 28, y: 32))
        path.addLine(to: CGPoint(x: 28, y: 40))

        path.move(to: CGPoint(x: 24, y: 10))
        path.addLine(to: CGPoint(x: 24, y: 6))
    }

    private func addSphere(to path: inout Path) {
        path.addEllipse(in: CGRect(x: 10, y: 10, width: 28, height: 28))
        path.addEllipse(in: CGRect(x: 18, y: 10, width: 12, height: 28))

        path.move(to: CGPoint(x: 10, y: 24))
        path.addLine(to: CGPoint(x: 38, y: 24))

        path.move(to: CGPoint(x: 12, y: 17))
        path.addLine(to: CGPoint(x: 36, y: 17))

        path.move(to: CGPoint(x: 12, y: 31))
        path.addLine(to: CGPoint(x: 36, y: 31))
    }

    /// A stepped, spired tower silhouette evoking the Hollywood Tower Hotel (Tower of Terror).
    private func addTowerOfTerror(to path: inout Path) {
        path.move(to: CGPoint(x: 16, y: 40))
        path.addLine(to: CGPoint(x: 16, y: 14))
        path.addLine(to: CGPoint(x: 18, y: 8))
        path.addLine(to: CGPoint(x: 20, y: 14))
        path.addLine(to: CGPoint(x: 24, y: 6))
        path.addLine(to: CGPoint(x: 28, y: 14))
        path.addLine(to: CGPoint(x: 30, y: 8))
        path.addLine(to: CGPoint(x: 32, y: 14))
        path.addLine(to: CGPoint(x: 32, y: 40))

        path.move(to: CGPoint(x: 19, y: 22))
        path.addLine(to: CGPoint(x: 29, y: 22))

        path.move(to: CGPoint(x: 19, y: 30))
        path.addLine(to: CGPoint(x: 29, y: 30))

        path.move(to: CGPoint(x: 21, y: 40))
        path.addLine(to: CGPoint(x: 21, y: 34))
        path.addLine(to: CGPoint(x: 27, y: 34))
        path.addLine(to: CGPoint(x: 27, y: 40))
    }

    /// A thick-trunked, broad-canopied silhouette evoking the Tree of Life.
    private func addTreeOfLife(to path: inout Path) {
        path.move(to: CGPoint(x: 16, y: 40))
        path.addQuadCurve(to: CGPoint(x: 21, y: 24), control: CGPoint(x: 13, y: 32))

        path.move(to: CGPoint(x: 32, y: 40))
        path.addQuadCurve(to: CGPoint(x: 27, y: 24), control: CGPoint(x: 35, y: 32))

        path.addEllipse(in: CGRect(x: 9, y: 6, width: 30, height: 22))

        path.move(to: CGPoint(x: 21, y: 26))
        path.addLine(to: CGPoint(x: 15, y: 17))

        path.move(to: CGPoint(x: 24, y: 25))
        path.addLine(to: CGPoint(x: 24, y: 13))

        path.move(to: CGPoint(x: 27, y: 26))
        path.addLine(to: CGPoint(x: 33, y: 17))
    }
}

struct ParkMarkView: View {
    let mark: ParkMark
    var color: Color = Theme.fg

    var body: some View {
        ParkMarkShape(mark: mark)
            .stroke(color, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
    }
}
