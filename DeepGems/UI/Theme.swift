import SwiftUI

extension Color {
    static let deepBackground = Color(red: 0.035, green: 0.065, blue: 0.12)
    static let deepPanel = Color(red: 0.08, green: 0.13, blue: 0.21)
    static let deepGold = Color(red: 1, green: 0.72, blue: 0.19)
    static let deepTeal = Color(red: 0.12, green: 0.78, blue: 0.78)
}

extension GemKind {
    var color: Color {
        switch self {
        case .quartz: return Color(red: 0.8, green: 0.86, blue: 0.92)
        case .amethyst: return .purple
        case .emerald: return .green
        case .ruby: return .pink
        case .diamond: return .cyan
        }
    }
}

extension Outfit {
    var color: Color {
        switch self { case .teal: return .deepTeal; case .purple: return .purple; case .orange: return .orange }
    }
}

struct GemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points: [CGPoint] = [CGPoint(x: 0.5, y: 0), CGPoint(x: 0.88, y: 0.24), CGPoint(x: 0.95, y: 0.64), CGPoint(x: 0.5, y: 1), CGPoint(x: 0.05, y: 0.64), CGPoint(x: 0.12, y: 0.24)]
        path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
        path.closeSubpath()
        return path
    }
}

struct GemArt: View {
    let kind: GemKind
    var polished = false
    var body: some View {
        Image(uiImage: GameArtwork.gem(kind)).resizable().scaledToFit()
            .clipShape(CutGemShape(cuts: polished ? kind.cutCount : 0))
            .brightness(polished ? 0.07 : -0.07)
            .shadow(color: kind.color.opacity(polished ? 0.5 : 0.18), radius: polished ? 18 : 6)
            .overlay(alignment: .topTrailing) {
                if polished { Image(systemName: "sparkle").font(.title3).foregroundStyle(.white) }
            }
            .accessibilityLabel("\(kind.name), \(polished ? "lapidada" : "bruta")")
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View { VStack(alignment: .leading, spacing: 10) { content }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(LinearGradient(colors: [Color(red: 0.13, green: 0.21, blue: 0.32), .deepPanel], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 0.3, green: 0.43, blue: 0.58), lineWidth: 1.5)) }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.headline, design: .rounded, weight: .bold)).padding(.vertical, 14).frame(maxWidth: .infinity)
            .foregroundStyle(Color.white).shadow(color: .brown.opacity(0.6), radius: 1, y: 2)
            .background(LinearGradient(colors: [Color(red: 1, green: 0.76, blue: 0.12), Color(red: 0.95, green: 0.43, blue: 0.02)], startPoint: .top, endPoint: .bottom), in: Capsule())
            .overlay(Capsule().stroke(Color(red: 1, green: 0.87, blue: 0.4), lineWidth: 2))
            .shadow(color: Color.orange.opacity(0.25), radius: 8, y: 3)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct ScreenTitle: View {
    let title: String
    let subtitle: String
    var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title).font(.system(.largeTitle, design: .serif, weight: .bold)).foregroundStyle(Color(red: 1, green: 0.94, blue: 0.82)); Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
}
