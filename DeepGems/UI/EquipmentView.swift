import SwiftUI

struct EquipmentView: View {
    @EnvironmentObject private var game: GameStore
    @State private var selected: PickaxeKind = .amethyst
    @State private var purchaseConfirmation = false
    @State private var section = ProcessInfo.processInfo.arguments.contains("-deepgems-upgrades-preview") ? 1 : 0
    init(initialSection: Int? = nil) {
        _section = State(initialValue: initialSection ?? (ProcessInfo.processInfo.arguments.contains("-deepgems-upgrades-preview") ? 1 : 0))
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenTitle(title: "Equipamentos", subtitle: "Sua próxima grande descoberta começa aqui.")
                HStack {
                    Label("\(game.state.coins) moedas", systemImage: "circle.fill").font(.headline).foregroundStyle(Color.deepGold)
                    Spacer()
                    Label("Força \(game.state.miningPower)", systemImage: "hammer.fill").font(.caption.bold()).foregroundStyle(Color.deepTeal)
                }
                Picker("Categoria", selection: $section) { Text("Picaretas").tag(0); Text("Melhorias").tag(1) }.pickerStyle(.segmented)
                if game.state.expedition != nil {
                    Label("Volte à base para comprar ou trocar equipamentos.", systemImage: "info.circle").font(.caption).foregroundStyle(Color.deepGold)
                }
                if section == 0 { pickaxes } else { upgrades }
                Text("Use as moedas das suas descobertas para ir mais longe.").font(.caption2).foregroundStyle(.secondary)
            }.padding(20)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .alert("Comprar \(selected.name)?", isPresented: $purchaseConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Comprar e equipar") { game.buyPickaxe(selected) }
            } message: {
                Text("Custa \(selected.price) moedas e adiciona +\(selected.bonus) à força da sua picareta. O item fica no seu inventário de equipamentos.")
            }
    }
    private var pickaxes: some View {
        VStack(spacing: 18) {
            VStack(spacing: 12) {
                Text(selected.rarity.uppercased()).font(.caption.bold()).tracking(3).foregroundStyle(selected.color)
                PickaxeArt(kind: selected).frame(height: 215).padding(12)
                Text(selected.name).font(.title2.bold()).multilineTextAlignment(.center)
                Text(selected.detail).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                HStack {
                    stat("ATUAL", value: "\(game.state.miningPower)")
                    Image(systemName: "arrow.right").foregroundStyle(.secondary)
                    stat("COM ESTA", value: "\(game.state.pickaxeLevel + selected.bonus)")
                }.padding(.vertical, 8)
                if game.state.equippedPickaxe == selected {
                    Label("Equipada", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(Color.deepTeal).padding(12)
                } else if game.state.ownedPickaxes.contains(selected) {
                    Button("Equipar picareta") { game.equipPickaxe(selected) }.buttonStyle(GoldButtonStyle()).disabled(game.state.expedition != nil)
                } else {
                    Button { purchaseConfirmation = true } label: {
                        Label("Comprar • \(selected.price) moedas", systemImage: "bag.fill")
                    }.buttonStyle(GoldButtonStyle()).disabled(game.state.coins < selected.price || game.state.expedition != nil)
                    if game.state.coins < selected.price {
                        Text("Faltam \(selected.price - game.state.coins) moedas").font(.caption).foregroundStyle(.secondary)
                        ProgressView(value: Double(game.state.coins), total: Double(selected.price)).tint(selected.color)
                    }
                }
            }.padding(22).frame(maxWidth: .infinity)
                .background(LinearGradient(colors: [selected.color.opacity(0.16), Color.deepPanel], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(selected.color.opacity(0.6)))
            HStack(spacing: 10) {
                ForEach(PickaxeKind.allCases) { item in
                    Button { withAnimation(.easeInOut(duration: 0.2)) { selected = item } } label: {
                        VStack(spacing: 8) {
                            PickaxeArt(kind: item).frame(height: 75)
                            Text(item.rarity).font(.caption.bold()).foregroundStyle(item.color)
                            Text(game.state.ownedPickaxes.contains(item) ? "Obtida" : "\(item.price) ●").font(.caption2).foregroundStyle(.secondary)
                        }.padding(10).frame(maxWidth: .infinity)
                            .background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected == item ? item.color : .white.opacity(0.08), lineWidth: 2))
                    }.buttonStyle(.plain).accessibilityLabel("Ver \(item.name)")
                }
            }
        }
    }
    private func stat(_ name: String, value: String) -> some View {
        VStack(spacing: 4) { Text(name).font(.caption2.bold()).foregroundStyle(.secondary); Text(value).font(.title.bold()).foregroundStyle(Color.deepGold) }.frame(maxWidth: .infinity)
    }
    private var upgrades: some View {
        VStack(spacing: 14) {
            ForEach(Upgrade.allCases) { item in
                Panel {
                    HStack(spacing: 16) {
                        UpgradeArt(kind: item, level: game.state.upgradeLevel(item), pickaxe: game.state.equippedPickaxe).frame(width: 85, height: 95)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("\(item.name) • Nv. \(game.state.upgradeLevel(item))").font(.headline)
                            Text(upgradeDetail(item)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Text("Próximo nível").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        UpgradeArt(kind: item, level: game.state.upgradeLevel(item) + 1, pickaxe: game.state.equippedPickaxe).frame(width: 45, height: 45)
                        Text("Nv. \(game.state.upgradeLevel(item) + 1)").font(.caption.bold()).foregroundStyle(Color.deepGold)
                    }
                    if item != .pickaxe {
                        Text("Visual reforçado no Nv. 2 • visual épico no Nv. 3").font(.caption2).foregroundStyle(.secondary)
                    }
                    Button { game.upgrade(item) } label: { Label("Melhorar • \(game.state.upgradeCost(item)) moedas", systemImage: "arrow.up.circle.fill") }
                        .buttonStyle(GoldButtonStyle()).padding(.top, 12)
                        .disabled(game.state.coins < game.state.upgradeCost(item) || game.state.expedition != nil)
                }
            }
        }
    }
    private func upgradeDetail(_ item: Upgrade) -> String {
        switch item {
        case .pickaxe: return "Força \(game.state.miningPower) → \(game.state.miningPower + 1). Vale para todas as picaretas."
        case .backpack: return "Capacidade \(game.state.capacity) → \(game.state.capacity + 4) pedras."
        case .stamina: return "Energia \(game.state.maximumEnergy) → \(game.state.maximumEnergy + 8)."
        }
    }
}
