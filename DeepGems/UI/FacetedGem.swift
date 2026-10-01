import SwiftUI

/// Progressive bevels physically clip the sprite instead of changing only its brightness.
struct CutGemShape: Shape {
    var cuts: Int
    func path(in rect: CGRect) -> Path {
        let a: CGFloat = cuts >= 1 ? 0.25 : 0
        let b: CGFloat = cuts >= 2 ? 0.25 : 0
        let c: CGFloat = cuts >= 3 ? 0.27 : 0
        let points: [CGPoint] = [
            .init(x: a, y: 0), .init(x: 1-b, y: 0), .init(x: 1, y: b),
            .init(x: 1, y: 1-c), .init(x: 1-c, y: 1), .init(x: c, y: 1),
            .init(x: 0, y: 1-c), .init(x: 0, y: a)
        ]
        var p = Path(); p.addLines(points.map { .init(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }); p.closeSubpath(); return p
    }
}

struct FacetedGemArt: View {
    let kind: GemKind
    let cuts: Int
    var body: some View {
        ZStack {
            Image(uiImage: GameArtwork.gem(kind)).resizable().scaledToFit()
            GeometryReader { g in
                Path { p in
                    p.move(to: .init(x: g.size.width * 0.25, y: 0))
                    p.addLine(to: .init(x: g.size.width * 0.5, y: g.size.height * 0.45))
                    p.addLine(to: .init(x: 0, y: g.size.height * 0.25)); p.closeSubpath()
                }.fill(.white.opacity(cuts > 0 ? 0.24 : 0))
                Path { p in
                    p.move(to: .init(x: g.size.width * 0.75, y: 0))
                    p.addLine(to: .init(x: g.size.width * 0.5, y: g.size.height * 0.45))
                    p.addLine(to: .init(x: g.size.width, y: g.size.height * 0.25)); p.closeSubpath()
                }.fill(.white.opacity(cuts > 1 ? 0.18 : 0))
            }
        }.clipShape(CutGemShape(cuts: cuts))
            .overlay(CutGemShape(cuts: cuts).stroke(.white.opacity(cuts > 0 ? 0.35 : 0), lineWidth: 1))
            .shadow(color: kind.color.opacity(0.45), radius: 18)
            .accessibilityLabel("\(kind.name), \(cuts) facetas lapidadas")
    }
}
