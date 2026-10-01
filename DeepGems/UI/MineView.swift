import SwiftUI
import SpriteKit

struct MineView: View {
    @EnvironmentObject private var game: GameStore
    @State private var showReturn = false
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let expedition = game.state.expedition {
                    ScreenTitle(title: "\(expedition.player.row) metros", subtitle: "Recorde da expedição: \(expedition.deepestRow) m")
                    HStack(spacing: 12) {
                        Panel {
                            Label("\(expedition.energy) / \(game.state.maximumEnergy)", systemImage: "bolt.fill").font(.headline).foregroundStyle(Color.deepTeal)
                            ProgressView(value: Double(expedition.energy), total: Double(game.state.maximumEnergy)).tint(.deepTeal)
                        }
                        Panel {
                            Label("\(expedition.carried.count) / \(game.state.capacity)", systemImage: "backpack.fill").font(.headline).foregroundStyle(Color.deepGold)
                            ProgressView(value: Double(expedition.carried.count), total: Double(game.state.capacity))
                        }
                    }
                    SpriteView(scene: game.mineScene, isPaused: scenePhase != .active, preferredFramesPerSecond: 30)
                        .frame(height: 390).clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityLabel("Mina. Use os controles abaixo para mover ou escavar.")
                    Text("Toque em um bloco com borda dourada. Cada golpe usa 1 de energia.").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        direction("arrow.left", name: "Escavar ou andar para a esquerda", column: -1, row: 0)
                        direction("arrow.up", name: "Escavar ou andar para cima", column: 0, row: -1)
                        direction("arrow.down", name: "Escavar ou andar para baixo", column: 0, row: 1)
                        direction("arrow.right", name: "Escavar ou andar para a direita", column: 1, row: 0)
                    }
                    if expedition.energy == 0 { Text("Energia esgotada. Seu saque está seguro: volte à base.").font(.subheadline.bold()).foregroundStyle(Color.deepGold) }
                    if !expedition.carried.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(expedition.carried) { gem in
                                    VStack { GemArt(kind: gem.kind).frame(width: 35, height: 42); Text(gem.kind.name).font(.caption2) }.padding(8).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    Button { showReturn = true } label: { Label("Voltar à base e guardar saque", systemImage: "house.fill") }.buttonStyle(GoldButtonStyle())
                } else {
                    ScreenTitle(title: "A mina espera", subtitle: "Comece uma expedição com energia cheia.")
                    GemArt(kind: .amethyst).frame(width: 150, height: 180).padding(35)
                    Text("Você mantém seu nível, equipamentos e coleção. Cada expedição gera uma nova mina.").foregroundStyle(.secondary)
                    Button("Começar expedição") { game.start() }.buttonStyle(GoldButtonStyle())
                }
            }.padding(20)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Guardar \(game.state.expedition?.carried.count ?? 0) pedras e encerrar esta expedição?", isPresented: $showReturn, titleVisibility: .visible) {
                Button("Guardar e voltar") { game.returnToBase() }
            }
    }
    private func direction(_ symbol: String, name: String, column: Int, row: Int) -> some View {
        Button { game.move(column: column, row: row) } label: {
            Image(systemName: symbol).font(.title2.bold()).frame(maxWidth: .infinity).frame(height: 48).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 12))
        }.accessibilityLabel(name)
    }
}
