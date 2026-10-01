import SwiftUI

struct WorkshopView: View {
    @EnvironmentObject private var game: GameStore
    @State private var gemToSell: Gem?
    @State private var filter = 0
    @State private var sort = 0
    @State private var selection: Set<UUID> = []
    @State private var bulkConfirmation = false
    private var gems: [Gem] {
        let filtered = game.state.inventory.filter { filter == 0 || (filter == 1 ? $0.cutQuality == nil : $0.cutQuality != nil) }
        return filtered.sorted { sort == 0 ? $0.value > $1.value : $0.kind.rawValue < $1.kind.rawValue }
    }
    private var selectedGems: [Gem] { game.state.inventory.filter { selection.contains($0.id) && $0.id != game.state.cutting?.gemID } }
    private var selectedTotal: Int { selectedGems.reduce(0) { $0 + $1.value } }
    private var groupedKinds: [GemKind] {
        let present = GemKind.allCases.filter { kind in gems.contains(where: { $0.kind == kind }) }
        if sort != 0 { return present.sorted { $0.rawValue < $1.rawValue } }
        let values = Dictionary(grouping: gems, by: \.kind).mapValues { items in items.map(\.value).max() ?? 0 }
        return present.sorted { (values[$0] ?? 0) > (values[$1] ?? 0) }
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "Sua oficina", subtitle: "Lapide, organize e transforme seu saque em moedas.")
                Label("\(game.state.coins) moedas", systemImage: "circle.fill").foregroundStyle(Color.deepGold).font(.headline)
                Picker("Pedras", selection: $filter) { Text("Todas").tag(0); Text("Brutas").tag(1); Text("Lapidadas").tag(2) }.pickerStyle(.segmented)
                HStack {
                    Picker("Ordenar", selection: $sort) { Text("Maior valor").tag(0); Text("Tipo de pedra").tag(1) }.pickerStyle(.menu)
                    Spacer()
                    Button("Selecionar brutas") { selection = Set(gems.filter { $0.cutQuality == nil && $0.id != game.state.cutting?.gemID }.map(\.id)) }.font(.caption.bold())
                }
                if gems.isEmpty { ContentUnavailableView("Nenhuma pedra aqui", systemImage: "diamond", description: Text("Explore e volte à base para guardar suas descobertas.")) }
                ForEach(groupedKinds) { kind in groupCard(kind) }
            }.padding(20)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                if !selectedGems.isEmpty {
                    VStack(spacing: 8) {
                        HStack { Text("\(selectedGems.count) pedras • \(selectedTotal) moedas").font(.caption.bold()); Spacer(); Button("Limpar") { selection.removeAll() }.font(.caption) }
                        Button("Vender selecionadas") { bulkConfirmation = true }.buttonStyle(GoldButtonStyle())
                    }.padding(14).background(Color.deepBackground)
                }
            }
            .alert("Vender esta pedra?", isPresented: Binding(get: { gemToSell != nil }, set: { if !$0 { gemToSell = nil } })) {
                Button("Cancelar", role: .cancel) { gemToSell = nil }
                Button("Vender por \(gemToSell?.value ?? 0)") { if let gem = gemToSell { game.sell(gem); selection.remove(gem.id) }; gemToSell = nil }
            } message: { Text("A coleção mantém o registro da descoberta.") }
            .confirmationDialog("Vender \(selectedGems.count) pedras por \(selectedTotal) moedas?", isPresented: $bulkConfirmation, titleVisibility: .visible) {
                Button("Confirmar venda • \(selectedTotal) moedas") { game.sellBatch(Set(selectedGems.map(\.id))); selection.removeAll() }
            }
    }
    private func groupCard(_ kind: GemKind) -> some View {
        let group = gems.filter { $0.kind == kind }
        let total = group.reduce(0) { $0 + $1.value }
        return DisclosureGroup {
            ForEach(group) { gem in gemRow(gem) }
        } label: {
            HStack(spacing: 14) {
                GemArt(kind: kind).frame(width: 45, height: 55)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(kind.name) • \(group.count)").font(.headline)
                    Text("Total \(total) moedas").font(.caption).foregroundStyle(Color.deepGold)
                }
            }
        }.padding(14).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 18))
    }
    private func gemRow(_ gem: Gem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button { if selection.contains(gem.id) { selection.remove(gem.id) } else { selection.insert(gem.id) } } label: {
                    Image(systemName: selection.contains(gem.id) ? "checkmark.circle.fill" : "circle").font(.title2)
                }.disabled(gem.id == game.state.cutting?.gemID).accessibilityLabel("Selecionar \(gem.kind.name), \(gem.value) moedas")
                GemArt(kind: gem.kind, polished: gem.cutQuality != nil).frame(width: 35, height: 45)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(gem.carats) ct • pureza \(gem.purity)%").font(.caption)
                    Text("\(gem.qualityName) • \(gem.value) moedas").font(.caption.bold()).foregroundStyle(Color.deepGold)
                }
            }
            HStack {
                if gem.cutQuality == nil { Button("Lapidar") { game.beginCutting(gem) }.buttonStyle(.borderedProminent).disabled(game.state.expedition != nil) }
                Spacer()
                Button("Vender") { gemToSell = gem }.buttonStyle(.bordered).disabled(gem.id == game.state.cutting?.gemID)
            }
        }.padding(.vertical, 12)
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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var game: GameStore
    @State private var resetConfirmation = false
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Button { dismiss() } label: { Label("Voltar à base", systemImage: "chevron.left").font(.caption.bold()) }.frame(maxWidth: .infinity, alignment: .leading)
                ScreenTitle(title: "Seu explorador", subtitle: "Nível \(game.state.level) • \(game.state.experience) XP")
                BaseShowcase(outfit: game.state.outfit, pickaxe: game.state.equippedPickaxe, backpackLevel: game.state.backpackLevel, staminaLevel: game.state.staminaLevel).frame(height: 350)
                Text("Guarda-roupa").font(.system(.title2, design: .serif, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Outfit.allCases) { outfit in
                        Button { game.equip(outfit) } label: {
                            VStack(spacing: 8) {
                                Image(uiImage: GameArtwork.explorer(outfit)).resizable().scaledToFit().frame(height: 105)
                                Text(outfit.name).font(.caption.bold()).lineLimit(2)
                                if game.state.level < outfit.requiredLevel { Label("Nv. \(outfit.requiredLevel)", systemImage: "lock.fill").font(.caption2) }
                                else { Text(game.state.outfit == outfit ? "Equipado" : "Equipar").font(.caption2.bold()).foregroundStyle(Color.deepGold) }
                            }.padding(10).frame(maxWidth: .infinity).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(game.state.outfit == outfit ? Color.deepGold : Color.white.opacity(0.15), lineWidth: 2))
                        }.buttonStyle(.plain).disabled(game.state.level < outfit.requiredLevel || game.state.outfit == outfit)
                    }
                }
                HStack {
                    UpgradeArt(kind: .backpack, level: game.state.backpackLevel).frame(height: 65)
                    Text("Mochila Nv. \(game.state.backpackLevel)").font(.caption.bold())
                    UpgradeArt(kind: .stamina, level: game.state.staminaLevel).frame(height: 65)
                    Text("Botas Nv. \(game.state.staminaLevel)").font(.caption.bold())
                }
                Panel {
                    Text("Sua jornada").font(.headline)
                    Text("Recorde: \(game.state.deepestRow) m • \(game.state.ownedPickaxes.count) picaretas conquistadas").font(.caption).foregroundStyle(.secondary)
                }
                Button("Começar novo jogo", role: .destructive) { resetConfirmation = true }.padding(.vertical)
            }.padding(20)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("Reiniciar o progresso? Uma cópia dos arquivos atuais será arquivada neste aparelho.", isPresented: $resetConfirmation, titleVisibility: .visible) {
                Button("Reiniciar", role: .destructive) { game.reset() }
            }
    }
}
