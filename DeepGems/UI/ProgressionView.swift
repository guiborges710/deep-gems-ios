import SwiftUI

struct ObjectiveCard: View {
    let state: GameState
    var body: some View {
        if let goal = state.currentGoal {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(goal.title).font(.caption.bold())
                    Spacer()
                    Text("+\(goal.reward) ●").font(.caption).foregroundStyle(Color.deepGold)
                }
                ProgressView(value: Double(min(goal.progress, goal.target)), total: Double(goal.target)).tint(.deepGold)
                Text("\(min(goal.progress, goal.target)) / \(goal.target)").font(.caption2).foregroundStyle(.secondary)
            }.padding(10).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 12))
        } else {
            Label("Sua base prosperou. Continue descobrindo!", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(Color.deepGold)
        }
    }
}

/// Native vector buildings let each upgrade change the actual scene, without replacing the existing art assets.
struct CampLandscape: View {
    let level: Int
    var body: some View {
        GeometryReader { g in
            ZStack {
                LinearGradient(colors: [Color(red: 0.06, green: 0.20, blue: 0.25), .deepBackground], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color.deepGold.opacity(0.20)).frame(width: 95, height: 95).blur(radius: 12).offset(x: g.size.width * 0.3, y: -65)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: g.size.height * 0.65))
                    path.addLine(to: CGPoint(x: g.size.width * 0.2, y: 35))
                    path.addLine(to: CGPoint(x: g.size.width * 0.43, y: g.size.height * 0.7))
                    path.addLine(to: CGPoint(x: g.size.width * 0.7, y: 10))
                    path.addLine(to: CGPoint(x: g.size.width, y: g.size.height * 0.6))
                    path.addLine(to: CGPoint(x: g.size.width, y: g.size.height))
                    path.addLine(to: CGPoint(x: 0, y: g.size.height)); path.closeSubpath()
                }.fill(Color(red: 0.08, green: 0.28, blue: 0.24))
                Ellipse().fill(Color(red: 0.23, green: 0.17, blue: 0.10)).frame(width: g.size.width * 1.4, height: 130).offset(y: g.size.height * 0.40)
                HStack(alignment: .bottom, spacing: 12) {
                    if level == 1 {
                        ZStack(alignment: .bottom) {
                            triangle.fill(LinearGradient(colors: [.deepGold, .brown], startPoint: .topLeading, endPoint: .bottomTrailing))
                            triangle.fill(Color.deepBackground).frame(width: 32, height: 45)
                        }.frame(width: 100, height: 85)
                    } else { building(name: level == 2 ? "CABANA" : "BASE", color: .brown, floors: level == 3 ? 2 : 1) }
                    building(name: "OFICINA", color: level == 1 ? .brown.opacity(0.55) : .deepTeal, floors: 1)
                    if level >= 2 { building(name: "DEPÓSITO", color: .brown, floors: level == 3 ? 2 : 1) }
                }.padding(.horizontal, 12).offset(y: 20)
                HStack {
                    Image(systemName: "shippingbox.fill").font(.system(size: level == 1 ? 22 : 34)).foregroundStyle(Color.deepGold)
                    Spacer()
                    if level == 3 {
                        Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 40)).foregroundStyle(Color.deepTeal)
                    }
                    Image(systemName: "flame.fill").font(.system(size: 24)).foregroundStyle(.orange)
                }.padding(30).offset(y: 95)
                if level >= 2 {
                    HStack(spacing: 35) {
                        ForEach(0..<3) { _ in Circle().fill(Color.deepGold).frame(width: 7, height: 7).shadow(color: .yellow, radius: 9) }
                    }.offset(y: -35)
                }
            }
        }.frame(height: 235).clipped().clipShape(RoundedRectangle(cornerRadius: 20))
            .accessibilityLabel("Acampamento estágio \(level): \(level == 1 ? "barraca e oficina simples" : (level == 2 ? "cabana, oficina e depósito" : "base ampliada de dois andares"))")
    }
    private var triangle: Path {
        Path { p in p.move(to: CGPoint(x: 0, y: 85)); p.addLine(to: CGPoint(x: 50, y: 0)); p.addLine(to: CGPoint(x: 100, y: 85)); p.closeSubpath() }
    }
    private func building(name: String, color: Color, floors: Int) -> some View {
        VStack(spacing: 0) {
            Image(systemName: "triangle.fill").resizable().foregroundStyle(Color.deepGold).frame(height: 27)
            VStack(spacing: 7) {
                ForEach(0..<floors, id: \.self) { _ in
                    HStack(spacing: 13) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.deepGold).frame(width: 13, height: 17)
                        RoundedRectangle(cornerRadius: 2).fill(Color.deepGold).frame(width: 13, height: 17)
                    }
                }
                Text(name).font(.system(size: 8, weight: .black)).foregroundStyle(.white)
            }.padding(9).frame(maxWidth: .infinity).background(color.gradient)
                .overlay(Rectangle().stroke(Color.deepGold.opacity(0.4)))
        }.frame(maxWidth: .infinity)
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
                CampLandscape(level: game.state.campLevel)
                    .overlay(alignment: .bottomLeading) {
                        ExplorerShowcase(outfit: game.state.outfit, pickaxe: game.state.equippedPickaxe, backpackLevel: game.state.backpackLevel, staminaLevel: game.state.staminaLevel)
                            .frame(width: 100, height: 155).padding(.leading, 16).padding(.bottom, 3)
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
                        HStack { Image(systemName: "sparkles").foregroundStyle(Color.deepGold); Text(relic).font(.subheadline); Spacer(); Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.deepTeal) }
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
                    CampLandscape(level: game.state.campLevel)
                    Text("Claro: escavado • colorido: investigado • escuro: desconhecido").font(.caption2)
                    // Draw only explored blocks. Generated but unvisited ore is never disclosed by the map.
                    Canvas { context, size in
                        let cell = size.width / CGFloat(GameEngine.columns)
                        for tile in game.state.mineChanges {
                            let rect = CGRect(x: CGFloat(tile.position.column) * cell + 1, y: CGFloat(tile.position.row) * 14 + 1, width: cell - 2, height: 12)
                            let region = MineRegion.at(tile.position.row)
                            let color: Color = tile.isEmpty ? .deepGold : (region == .earth ? .brown : (region == .copperCaves ? .orange : .purple))
                            context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color.opacity(tile.isEmpty ? 0.8 : 0.35)))
                        }
                        for structure in game.state.structures {
                            let point = CGPoint(x: (CGFloat(structure.position.column) + 0.5) * cell, y: CGFloat(structure.position.row) * 14 + 7)
                            context.draw(Text(structure.kind == .light ? "✦" : (structure.kind == .ladder ? "≡" : "↕")).font(.caption2).foregroundColor(.white), at: point)
                        }
                        if let player = game.state.expedition?.player {
                            let point = CGPoint(x: (CGFloat(player.column) + 0.5) * cell, y: CGFloat(player.row) * 14 + 7)
                            context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(.deepTeal))
                        }
                    }.frame(height: CGFloat(game.state.deepestRow + 4) * 14).background(Color.black.opacity(0.35))
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
