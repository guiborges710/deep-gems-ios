import SwiftUI

/// Progressive bevels physically clip the sprite instead of changing only its brightness.
struct CutGemShape: Shape {
    var cuts: Int
    func path(in rect: CGRect) -> Path {
        let top: CGFloat = cuts >= 4 ? 0.18 : (cuts >= 1 ? 0.11 : 0)
        let left: CGFloat = cuts >= 4 ? 0.18 : (cuts >= 2 ? 0.12 : 0)
        let bottom: CGFloat = cuts >= 4 ? 0.82 : (cuts >= 3 ? 0.86 : 1)
        let right: CGFloat = cuts >= 4 ? 0.84 : (cuts >= 3 ? 0.9 : 1)
        let bevel: CGFloat = cuts > 0 ? 0.22 : 0
        let points: [CGPoint] = [
            .init(x: left+bevel, y: top), .init(x: right-bevel, y: top), .init(x: right, y: top+bevel),
            .init(x: right, y: bottom-bevel), .init(x: right-bevel, y: bottom), .init(x: left+bevel, y: bottom),
            .init(x: left, y: bottom-bevel), .init(x: left, y: top+bevel)
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
