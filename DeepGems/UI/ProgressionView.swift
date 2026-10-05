import SwiftUI

struct ObjectiveCard: View {
    let state: GameState
    var compact = false
    var body: some View {
        if let goal = state.currentGoal {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(goal.title).font(.caption.bold())
                    Spacer()
                    Text("+\(goal.reward) ●").font(.caption).foregroundStyle(Color.deepGold)
                }
                ProgressView(value: Double(min(goal.progress, goal.target)), total: Double(goal.target)).tint(.deepGold)
                if !compact { Text("\(min(goal.progress, goal.target)) / \(goal.target)").font(.caption2).foregroundStyle(.secondary) }
            }.padding(10).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 12))
        } else {
            Label("Sua base prosperou. Continue descobrindo!", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(Color.deepGold)
        }
    }
}

/// Illustrated progression textures share the original cave, wood and amber-light art direction.
struct CampLandscape: View {
    let level: Int
    var relics: [String] = []
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: GameArtwork.camp(level))
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                if !relics.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(relics, id: \.self) { relic in
                            RelicArt(relic: relic).frame(width: 26, height: 38)
                        }
                    }.padding(10)
                        .background(Color.deepBackground.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.deepGold.opacity(0.55)))
                        .padding(12)
                }
            }
        }.frame(height: 340).clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.deepGold.opacity(0.3)))
            .accessibilityLabel("Acampamento estágio \(level): \(level == 1 ? "barraca e oficina simples" : (level == 2 ? "cabana, oficina e depósito" : "base ampliada de dois andares"))")
    }
}

struct CampView: View {
    @EnvironmentObject private var game: GameStore
    let explore: () -> Void
    let shop: () -> Void
    @State private var showMap = false
    @State private var showHelp = false
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    ScreenTitle(title: "Sua base", subtitle: ["Primeiros passos", "Acampamento equipado", "Base de mineração"][game.state.campLevel - 1])
                    Spacer()
                    Text("\(game.state.coins) ●").font(.headline).foregroundStyle(Color.deepGold)
                }
                ObjectiveCard(state: game.state)
                CampLandscape(level: game.state.campLevel, relics: game.state.relics)
                    .overlay(alignment: .bottomLeading) {
                        ExplorerShowcase(outfit: game.state.outfit, pickaxe: game.state.equippedPickaxe, backpackLevel: game.state.backpackLevel, staminaLevel: game.state.staminaLevel)
                            .frame(width: 135, height: 210).padding(.leading, 24).padding(.bottom, 38)
                    }
                HStack {
                    Text("Cobre \(game.state.copper) • Ferro \(game.state.iron)")
                    Spacer()
                    Text("Recorde \(game.state.deepestRow) m")
                }.font(.caption).foregroundStyle(Color.deepGold)
                Button(action: explore) { Label(game.state.expedition == nil ? "Entrar na sua mina" : "Continuar escavação", systemImage: "mountain.2.fill") }.buttonStyle(GoldButtonStyle())
                HStack {
                    Button(action: shop) { Label("Oficina", systemImage: "hammer.fill") }
                    Spacer()
                    NavigationLink { WorkshopView() } label: { Label("Vender", systemImage: "dollarsign.circle.fill") }
                    Spacer()
                    Button { showMap = true } label: { Label("Mapa", systemImage: "map.fill") }
                }.font(.subheadline.bold()).foregroundStyle(Color.deepTeal).padding(.vertical, 8)
                NavigationLink { CharacterView() } label: {
                    Label("Explorador estágio \(game.state.characterTier) • ver equipamentos", systemImage: "person.crop.circle.fill")
                }.font(.caption).foregroundStyle(Color.deepGold)
                if game.state.campLevel < 3 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.state.campLevel == 1 ? "Construa sua cabana" : "Amplie sua base").font(.headline)
                        Text(Progression.campCost(game.state.campLevel).description).font(.caption).foregroundStyle(.secondary)
                        Button("Construir estágio \(game.state.campLevel + 1)") { game.improveCamp() }
                            .buttonStyle(GoldButtonStyle())
                            .disabled(game.state.expedition != nil || !Progression.campCost(game.state.campLevel).isAffordable(game.state))
                    }.padding().background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 16))
                }
                NavigationLink { EquipmentView(initialSection: 1) } label: { Label("Depósito • ampliar mochila de \(game.state.capacity) pedras", systemImage: "shippingbox.fill") }
                    .font(.subheadline).foregroundStyle(Color.deepTeal)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Exposição de descobertas").font(.headline)
                    if game.state.relics.isEmpty { Text("Investigue os blocos marcados com ? na mina.").font(.caption).foregroundStyle(.secondary) }
                    ForEach(game.state.relics, id: \.self) { relic in
                        HStack { RelicArt(relic: relic).frame(width: 28, height: 40); Text(relic).font(.subheadline); Spacer(); Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.deepTeal) }
                    }
                }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 16))
                Button("Como jogar") { showHelp = true }.font(.caption)
            }.padding(18)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showMap) { MineOverview().environmentObject(game) }
            .sheet(isPresented: $showHelp) {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenTitle(title: "Construa sua história", subtitle: "Cada túnel permanece na sua mina.")
                    Label("Use as setas ou toque em blocos vizinhos para explorar.", systemImage: "hand.tap.fill")
                    Label("Pedras liberam cobre e ferro. Construa luzes, escadas e elevadores dentro dos túneis.", systemImage: "hammer.fill")
                    Label("Para subir, instale uma escada no bloco atual. O retorno à base guarda todo o saque e funciona mesmo sem energia.", systemImage: "arrow.up")
                    Label("Lapide e venda na Oficina. Amplie seu depósito e transforme seu acampamento.", systemImage: "house.fill")
                    Button("Bora explorar!") { game.finishTutorial(); showHelp = false }.buttonStyle(GoldButtonStyle())
                }.padding(24)
            }.onAppear { if !game.state.hasSeenTutorial && !ProcessInfo.processInfo.arguments.contains("-deepgems-screenshot") { showHelp = true } }
    }
}

struct MineOverview: View {
    @EnvironmentObject private var game: GameStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    CampLandscape(level: game.state.campLevel, relics: game.state.relics)
                    Text("Claro: escavado • colorido: investigado • escuro: desconhecido").font(.caption2)
                    let tilesByChunk = Dictionary(grouping: game.state.mineChanges) { $0.position.row / 40 }
                    let structuresByChunk = Dictionary(grouping: game.state.structures) { $0.position.row / 40 }
                    LazyVStack(spacing: 0) {
                        ForEach(0..<((game.state.deepestRow + 43) / 40), id: \.self) { chunk in
                            MineMapSlice(firstRow: chunk * 40, rowCount: min(40, game.state.deepestRow + 4 - chunk * 40),
                                         tiles: tilesByChunk[chunk] ?? [], structures: structuresByChunk[chunk] ?? [], player: game.state.expedition?.player)
                        }
                    }.background(Color.black.opacity(0.35))
                    Text("\(game.state.deepestRow) m explorados. O restante aguarda suas descobertas.").font(.caption)
                }.padding(16)
            }.background(Color.deepBackground).navigationTitle("Sua escavação")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fechar") { dismiss() } } }
        }
    }
}

struct MineConstructionPanel: View {
    @EnvironmentObject private var game: GameStore
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Construir no túnel atual").font(.title2.bold())
            Text("Cobre \(game.state.copper) • Ferro \(game.state.iron) • \(game.state.coins) moedas").font(.caption).foregroundStyle(Color.deepGold)
            ForEach(StructureKind.allCases) { kind in
                VStack(alignment: .leading, spacing: 6) {
                    Label(kind.name, systemImage: kind.symbol).font(.headline)
                    Text(kind == .ladder ? "Permite subir deste bloco para o bloco acima." : (kind == .light ? "Ilumina os túneis em um raio de três blocos." : "Liga esta estação à superfície e a outros elevadores."))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(kind.cost.description).font(.caption2)
                    Button("Instalar \(kind.name.lowercased())") { game.build(kind) }.buttonStyle(GoldButtonStyle())
                        .disabled(!kind.cost.isAffordable(game.state) || game.state.expedition?.player.row == 0 || game.state.structures.contains { $0.kind == kind && $0.position == game.state.expedition?.player })
                }
            }
        }.padding(24).background(Color.deepBackground)
    }
}

struct RelicArt: View {
    let relic: String
    private var symbol: String { relic.contains("Fóssil") ? "leaf.fill" : (relic.contains("Ídolo") ? "sun.max.fill" : "diamond.fill") }
    private var color: Color { relic.contains("Fóssil") ? .orange : (relic.contains("Ídolo") ? .deepGold : .purple) }
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: symbol).resizable().scaledToFit().foregroundStyle(color.gradient).shadow(color: color.opacity(0.5), radius: 5)
            RoundedRectangle(cornerRadius: 2).fill(Color.brown.gradient).frame(height: 6)
        }.accessibilityLabel(relic)
    }
}

/// The overview also renders in chunks so a deep mine never creates one enormous drawing surface.
private struct MineMapSlice: View {
    let firstRow: Int
    let rowCount: Int
    let tiles: [MineTile]
    let structures: [MineStructure]
    let player: GridPosition?
    var body: some View {
        Canvas { context, size in
            let cell = size.width / CGFloat(GameEngine.columns)
            for tile in tiles {
                let rect = CGRect(x: CGFloat(tile.position.column) * cell + 1, y: CGFloat(tile.position.row - firstRow) * 14 + 1, width: cell - 2, height: 12)
                let region = MineRegion.at(tile.position.row)
                let color: Color = tile.isEmpty ? .deepGold : (region == .earth ? .brown : (region == .copperCaves ? .orange : .purple))
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color.opacity(tile.isEmpty ? 0.8 : 0.35)))
            }
            for structure in structures {
                let point = CGPoint(x: (CGFloat(structure.position.column) + 0.5) * cell, y: CGFloat(structure.position.row - firstRow) * 14 + 7)
                context.draw(Text(structure.kind == .light ? "✦" : (structure.kind == .ladder ? "≡" : "↕")).font(.caption2).foregroundColor(.white), at: point)
            }
            if let player, (firstRow..<(firstRow + rowCount)).contains(player.row) {
                let point = CGPoint(x: (CGFloat(player.column) + 0.5) * cell, y: CGFloat(player.row - firstRow) * 14 + 7)
                context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(.deepTeal))
            }
        }.frame(height: CGFloat(rowCount) * 14)
            .overlay(alignment: .topTrailing) { Text("\(firstRow) m").font(.caption2).foregroundStyle(.white.opacity(0.6)) }
    }
}
