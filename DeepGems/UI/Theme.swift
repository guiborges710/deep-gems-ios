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
            .brightness(polished ? 0.07 : -0.07)
            .shadow(color: kind.color.opacity(polished ? 0.5 : 0.18), radius: polished ? 18 : 6)
            .overlay(alignment: .topTrailing) {
                if polished { Image(systemName: "sparkle").font(.title3).foregroundStyle(.white) }
            }
            .accessibilityLabel("\(kind.name), \(polished ? "lapidada" : "bruta")")
    }
}

struct ExplorerArt: View {
    let outfit: Outfit
    var body: some View {
        ZStack {
            Ellipse().fill(outfit.color.opacity(0.14)).frame(width: 170, height: 35).offset(y: 105)
            RoundedRectangle(cornerRadius: 18).fill(.brown).frame(width: 90, height: 100).offset(x: 24, y: 15)
            HStack(spacing: 10) {
                Capsule().fill(Color(red: 0.18, green: 0.23, blue: 0.3)).frame(width: 28, height: 60)
                Capsule().fill(Color(red: 0.18, green: 0.23, blue: 0.3)).frame(width: 28, height: 60)
            }.offset(y: 70)
            RoundedRectangle(cornerRadius: 24).fill(outfit.color.gradient).frame(width: 83, height: 94).offset(y: 15)
            HStack(spacing: 50) {
                Capsule().fill(outfit.color).frame(width: 22, height: 65)
                Capsule().fill(outfit.color).frame(width: 22, height: 65)
            }.offset(y: 19)
            RoundedRectangle(cornerRadius: 7).fill(.brown).frame(width: 85, height: 15).offset(y: 43)
            RoundedRectangle(cornerRadius: 3).stroke(Color.deepGold, lineWidth: 3).frame(width: 18, height: 13).offset(y: 43)
            Circle().fill(Color(red: 0.94, green: 0.71, blue: 0.48)).frame(width: 67, height: 70).offset(y: -57)
            HStack(spacing: 18) {
                Circle().fill(.black).frame(width: 5, height: 7)
                Circle().fill(.black).frame(width: 5, height: 7)
            }.offset(y: -55)
            Capsule().fill(Color.deepGold.gradient).frame(width: 78, height: 36).offset(y: -86)
            Capsule().fill(Color.deepGold).frame(width: 92, height: 10).offset(y: -74)
            Circle().fill(.white).frame(width: 17).shadow(color: .deepGold, radius: 12).offset(y: -87)
            Image(systemName: "hammer.fill").font(.system(size: 49)).foregroundStyle(.gray).rotationEffect(.degrees(-25)).offset(x: 70, y: 30)
        }.frame(height: 240).accessibilityLabel("Explorador usando \(outfit.name)")
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View { content.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.08))) }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).padding(.vertical, 15).frame(maxWidth: .infinity)
            .foregroundStyle(Color.deepBackground)
            .background(Color.deepGold.gradient, in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct ScreenTitle: View {
    let title: String
    let subtitle: String
    var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title).font(.largeTitle.bold()); Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
}
