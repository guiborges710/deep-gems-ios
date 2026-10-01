import SwiftUI

struct CuttingView: View {
    @EnvironmentObject private var game: GameStore
    @State private var angle = 0.0
    private var gem: Gem? {
        guard let id = game.state.cutting?.gemID else { return nil }
        return game.state.inventory.first { $0.id == id }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if let gem, let session = game.state.cutting {
                    ScreenTitle(title: "Lapidar \(gem.kind.name)", subtitle: "Corte \(session.scores.count + 1) de \(gem.kind.cutCount)")
                    Text(gem.kind.cuttingHint).font(.subheadline).foregroundStyle(.secondary)
                    ZStack {
                        RoundedRectangle(cornerRadius: 24).fill(Color.deepPanel)
                        GemArt(kind: gem.kind).frame(width: 175, height: 210)
                        cutLine(angle: GameEngine.targetAngle(for: gem, cut: session.scores.count), color: .white.opacity(0.7), dashed: true)
                        if gem.kind == .emerald { cutLine(angle: 25, color: .red.opacity(0.65), dashed: false) }
                        cutLine(angle: angle, color: .deepGold, dashed: false)
                    }.frame(height: 280)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 30).onEnded { drag in
                            let distance = abs(drag.translation.height)
                            guard distance >= 50 else { return }
                            let deviation = abs(drag.translation.width) / max(1, distance)
                            game.cut(angle: angle, accuracy: max(0.4, 1 - Double(deviation) * 0.5))
                        })
                        .accessibilityLabel("Pedra para lapidar. Ajuste o ângulo e use o botão Executar corte.")
                    HStack { Text("Ângulo do corte"); Spacer(); Text("\(Int(angle))°").monospacedDigit().foregroundStyle(Color.deepGold) }
                    Slider(value: $angle, in: -60...60, step: 1).accessibilityLabel("Ângulo do corte em graus")
                    Text("Alinhe a linha dourada com a pontilhada. Deslize de cima para baixo sobre a pedra ou use o botão.").font(.caption).foregroundStyle(.secondary)
                    Button("Executar corte") { game.cut(angle: angle, accuracy: 1) }.buttonStyle(GoldButtonStyle())
                    if !session.scores.isEmpty {
                        HStack { ForEach(Array(session.scores.enumerated()), id: \.offset) { index, score in Text("C\(index + 1): \(score)%").font(.caption.bold()).padding(10).background(Color.deepPanel, in: Capsule()) } }
                    }
                    Text("A lapidação é salva a cada corte. Você pode fechar o app e continuar depois.").font(.caption2).foregroundStyle(.secondary)
                } else if let result = game.cuttingResult {
                    ScreenTitle(title: "Peça finalizada!", subtitle: result.kind.name)
                    GemArt(kind: result.kind, polished: true).frame(width: 180, height: 220).padding(25)
                    Text(result.qualityName).font(.largeTitle.bold()).foregroundStyle(result.kind.color)
                    Text("Qualidade: \(result.cutQuality ?? 0)%").font(.headline)
                    Label("\(result.value) moedas", systemImage: "circle.fill").font(.title2.bold()).foregroundStyle(Color.deepGold)
                    Text("A peça está na sua oficina. Guarde ou venda para investir na próxima expedição.").foregroundStyle(.secondary)
                    Button("Guardar na oficina") { game.cuttingResult = nil }.buttonStyle(GoldButtonStyle())
                }
            }.padding(24)
        }.background(Color.deepBackground.ignoresSafeArea())
            .onChange(of: game.state.cutting?.scores.count) { _, _ in angle = 0 }
    }
    private func cutLine(angle: Double, color: Color, dashed: Bool) -> some View {
        Rectangle().stroke(color, style: StrokeStyle(lineWidth: 2, dash: dashed ? [6, 5] : []))
            .frame(width: 230, height: 1).rotationEffect(.degrees(angle))
    }
}
