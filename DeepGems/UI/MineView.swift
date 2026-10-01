import SwiftUI
import SpriteKit

struct MineView: View {
    @EnvironmentObject private var game: GameStore
    @State private var showReturn = false
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        GeometryReader { geometry in
            if let e = game.state.expedition {
                VStack(spacing: 8) {
                    HStack {
                        Text("Profundidade \(e.player.row) m").font(.system(.title2, design: .serif, weight: .bold))
                        Spacer()
                        Text("Recorde \(game.state.deepestRow) m").font(.caption2).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 10) {
                        meter(value: e.energy, maximum: game.state.maximumEnergy, symbol: "bolt.fill", tint: .deepTeal)
                        meter(value: e.carried.count, maximum: game.state.capacity, symbol: "backpack.fill", tint: .deepGold)
                    }
                    SpriteView(scene: game.mineScene, isPaused: false, preferredFramesPerSecond: 60)
                        .frame(maxWidth: .infinity).frame(height: max(80, geometry.size.height - (geometry.size.height < 650 ? 308 : 320)))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.deepGold.opacity(0.3)))
                        .accessibilityLabel("Mina. Toque nos blocos dourados ao lado do explorador ou use as setas.")
                    HStack(spacing: 8) {
                        ForEach(GemKind.allCases) { kind in
                            VStack(spacing: 2) {
                                GemArt(kind: kind).frame(height: geometry.size.height < 650 ? 24 : 36)
                                Text("\(e.carried.filter { $0.kind == kind }.count)").font(.caption.bold()).monospacedDigit()
                            }.frame(maxWidth: .infinity).padding(5).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 9))
                        }
                    }.accessibilityLabel("Saque: \(e.carried.count) pedras")
                    Text(status(e)).font(.caption).foregroundStyle(e.energy == 0 || e.carried.count >= game.state.capacity ? Color.deepGold : Color.white.opacity(0.75))
                        .lineLimit(2).frame(height: 30)
                    HStack(spacing: 8) {
                        direction("arrow.left", name: "Esquerda", column: -1, row: 0)
                        direction("arrow.up", name: "Cima", column: 0, row: -1)
                        direction("arrow.down", name: "Baixo", column: 0, row: 1)
                        direction("arrow.right", name: "Direita", column: 1, row: 0)
                    }
                    Button { showReturn = true } label: { Label("Voltar à base • \(e.carried.count) pedras", systemImage: "house.fill") }
                        .buttonStyle(GoldButtonStyle())
                }.padding(.horizontal, 16).padding(.vertical, 8)
            } else {
                VStack(spacing: 22) {
                    ScreenTitle(title: "A mina espera", subtitle: "Uma nova expedição. Novas descobertas.")
                    Spacer()
                    GemArt(kind: .amethyst).frame(width: 160, height: 180)
                    Text("Energia cheia, mochila vazia. Até onde você vai chegar?").multilineTextAlignment(.center).foregroundStyle(.secondary)
                    Spacer()
                    Button("Começar expedição") { game.start() }.buttonStyle(GoldButtonStyle())
                }.padding(24)
            }
        }.onAppear { game.mineScene.isPaused = false }
            .onChange(of: scenePhase) { _, phase in game.mineScene.isPaused = phase != .active }
            .background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Guardar \(game.state.expedition?.carried.count ?? 0) pedras e encerrar a expedição?", isPresented: $showReturn, titleVisibility: .visible) {
                Button("Guardar e voltar") { game.returnToBase() }
            }
    }
    private func status(_ e: Expedition) -> String {
        if e.energy == 0 { return "Energia esgotada. Volte para guardar seu saque." }
        if e.carried.count >= game.state.capacity { return "Mochila cheia. Guarde suas descobertas na base." }
        return game.miningNotice ?? "Toque nos blocos dourados. Cada golpe custa 1 de energia."
    }
    private func meter(value: Int, maximum: Int, symbol: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).font(.title3).foregroundStyle(tint)
            VStack(spacing: 4) {
                Text("\(value) / \(maximum)").font(.caption.bold()).monospacedDigit()
                ProgressView(value: Double(value), total: Double(maximum)).tint(tint)
            }
        }.padding(9).frame(maxWidth: .infinity).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.35)))
    }
    private func direction(_ symbol: String, name: String, column: Int, row: Int) -> some View {
        Button { game.move(column: column, row: row) } label: {
            Image(systemName: symbol).font(.title3.bold()).frame(maxWidth: .infinity).frame(height: 40)
                .background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 10))
        }.disabled(!game.canAct(column: column, row: row)).accessibilityLabel("Escavar ou andar: \(name)")
    }
}
