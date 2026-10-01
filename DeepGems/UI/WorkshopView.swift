import SwiftUI

struct WorkshopView: View {
    @EnvironmentObject private var game: GameStore
    @State private var gemToSell: Gem?
    @State private var filter = 0
    private var gems: [Gem] { game.state.inventory.filter { filter == 0 || (filter == 1 ? $0.cutQuality == nil : $0.cutQuality != nil) } }
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenTitle(title: "Sua oficina", subtitle: "Transforme descobertas em peças únicas.")
                Panel { Label("\(game.state.coins) moedas", systemImage: "circle.fill").foregroundStyle(Color.deepGold).font(.headline) }
                Picker("Pedras", selection: $filter) { Text("Todas").tag(0); Text("Brutas").tag(1); Text("Lapidadas").tag(2) }.pickerStyle(.segmented)
                if gems.isEmpty {
                    ContentUnavailableView("Nenhuma pedra aqui", systemImage: "diamond", description: Text("Explore a mina e volte à base para trazer suas descobertas."))
                }
                ForEach(gems) { gem in
                    Panel {
                        HStack(spacing: 18) {
                            GemArt(kind: gem.kind, polished: gem.cutQuality != nil).frame(width: 55, height: 65)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(gem.kind.name).font(.headline)
                                Text("\(gem.carats) ct • Pureza \(gem.purity)%").font(.caption).foregroundStyle(.secondary)
                                Text(gem.qualityName + (gem.cutQuality.map { " • \($0)%" } ?? "")).font(.caption).foregroundStyle(gem.kind.color)
                                Text("Valor: \(gem.value) moedas").font(.subheadline.bold()).foregroundStyle(Color.deepGold)
                            }
                            Spacer(minLength: 0)
                        }
                        HStack {
                            if gem.cutQuality == nil {
                                Button("Lapidar") { game.beginCutting(gem) }.buttonStyle(.borderedProminent).disabled(game.state.expedition != nil)
                            }
                            Spacer()
                            Button("Vender") { gemToSell = gem }.buttonStyle(.bordered)
                        }.padding(.top, 10)
                    }
                }
                Text("Vendas são feitas para o próprio jogo. A coleção mantém o registro das suas descobertas.").font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .alert("Vender esta pedra?", isPresented: Binding(get: { gemToSell != nil }, set: { if !$0 { gemToSell = nil } })) {
                Button("Cancelar", role: .cancel) { gemToSell = nil }
                Button("Vender por \(gemToSell?.value ?? 0)") { if let gem = gemToSell { game.sell(gem) }; gemToSell = nil }
            } message: { Text("Você receberá moedas para melhorar seus equipamentos.") }
    }
}

struct CollectionView: View {
    @EnvironmentObject private var game: GameStore
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenTitle(title: "Suas descobertas", subtitle: "\(game.state.collection.values.filter { $0.found > 0 }.count) de \(GemKind.allCases.count) tipos encontrados")
                ForEach(GemKind.allCases) { kind in
                    let entry = game.state.collection[kind.rawValue] ?? CollectionEntry()
                    Panel {
                        HStack(spacing: 20) {
                            GemArt(kind: kind, polished: entry.bestQuality > 0).frame(width: 65, height: 80).opacity(entry.found == 0 ? 0.2 : 1)
                            VStack(alignment: .leading, spacing: 7) {
                                Text(kind.name).font(.title3.bold())
                                if entry.found > 0 {
                                    Text("\(entry.found) descobertas").font(.subheadline)
                                    Text("Melhor lapidação: \(entry.bestQuality)%").font(.caption).foregroundStyle(.secondary)
                                    Text("Maior valor: \(entry.bestValue) moedas").font(.caption).foregroundStyle(Color.deepGold)
                                } else {
                                    Label("A partir de \(kind.minimumDepth) m", systemImage: "lock.fill").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }.padding(20)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
    }
}

struct CharacterView: View {
    @EnvironmentObject private var game: GameStore
    @State private var resetConfirmation = false
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenTitle(title: "Seu explorador", subtitle: "Nível \(game.state.level) • \(game.state.experience) XP")
                ExplorerShowcase(outfit: game.state.outfit, pickaxe: game.state.equippedPickaxe).frame(height: 310).padding(.vertical, 20)
                Text("Guarda-roupa").font(.title2.bold()).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Outfit.allCases) { outfit in
                    Panel {
                        HStack {
                            Image(systemName: "tshirt.fill").font(.largeTitle).foregroundStyle(outfit.color)
                            VStack(alignment: .leading) { Text(outfit.name).font(.headline); Text("Desbloqueia no nível \(outfit.requiredLevel)").font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            Button(game.state.outfit == outfit ? "Equipado" : "Equipar") { game.equip(outfit) }
                                .disabled(game.state.level < outfit.requiredLevel || game.state.outfit == outfit)
                        }
                    }
                }
                Panel {
                    Text("Protótipo 0.2").font(.headline)
                    Text("Progresso salvo neste aparelho. Esta versão ainda não tem compras, anúncios, conta online ou multiplayer.").font(.caption).foregroundStyle(.secondary)
                }
                Button("Começar novo jogo", role: .destructive) { resetConfirmation = true }.padding(.vertical)
            }.padding(20)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Reiniciar o progresso? Uma cópia dos arquivos atuais será arquivada neste aparelho.", isPresented: $resetConfirmation, titleVisibility: .visible) {
                Button("Reiniciar", role: .destructive) { game.reset() }
            }
    }
}
