import SwiftUI

struct RootView: View {
    @EnvironmentObject private var game: GameStore
    @State private var tab = 0
    @State private var resetConfirmation = false
    var body: some View {
        Group {
            if let error = game.loadError {
                VStack(spacing: 22) {
                    Image(systemName: "externaldrive.badge.exclamationmark").font(.system(size: 60)).foregroundStyle(Color.deepGold)
                    Text("Seu progresso precisa de atenção").font(.title2.bold())
                    Text(error).foregroundStyle(.secondary)
                    Button("Tentar novamente") { game.reload() }.buttonStyle(GoldButtonStyle())
                    Button("Começar novo jogo") { resetConfirmation = true }
                }.padding(24)
            } else {
                TabView(selection: $tab) {
                    NavigationStack { BaseView(onExplore: { game.start(); if game.state.expedition != nil { tab = 1 } }, onShop: { tab = 4 }) }
                        .tabItem { Label("Base", systemImage: "house.fill") }.tag(0)
                    NavigationStack { MineView() }
                        .tabItem { Label("Mina", systemImage: "mountain.2.fill") }.tag(1)
                    NavigationStack { WorkshopView() }
                        .tabItem { Label("Oficina", systemImage: "hammer.fill") }.tag(2)
                    NavigationStack { CollectionView() }
                        .tabItem { Label("Coleção", systemImage: "diamond.fill") }.tag(3)
                    NavigationStack { EquipmentView() }
                        .tabItem { Label("Loja", systemImage: "bag.fill") }.tag(4)
                }
                .toolbarBackground(Color.deepBackground, for: .tabBar)
                .safeAreaInset(edge: .top) {
                    if let error = game.saveError {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Progresso ainda não salvo").bold()
                            Text(error).font(.caption)
                            Button("Tentar salvar novamente") { game.save() }.font(.subheadline.bold())
                        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.red.opacity(0.3))
                    }
                }
            }
        }
        .background(Color.deepBackground.ignoresSafeArea())
        .alert("DeepGems", isPresented: Binding(get: { game.message != nil }, set: { if !$0 { game.message = nil } })) {
            Button("Entendi") { game.message = nil }
        } message: { Text(game.message ?? "") }
        .confirmationDialog("Começar de novo? O progresso anterior será arquivado neste aparelho.", isPresented: $resetConfirmation, titleVisibility: .visible) {
            Button("Confirmar novo jogo", role: .destructive) { game.reset() }
        }
        .sheet(isPresented: Binding(get: { game.state.cutting != nil || game.cuttingResult != nil }, set: { if !$0 { game.cuttingResult = nil } })) {
            CuttingView().environmentObject(game).interactiveDismissDisabled(game.state.cutting != nil)
        }
    }
}

struct BaseView: View {
    @EnvironmentObject private var game: GameStore
    let onExplore: () -> Void
    let onShop: () -> Void
    @State private var tutorial = false
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenTitle(title: "DeepGems", subtitle: "Cada expedição esconde uma descoberta.")
                Panel {
                    HStack {
                        Label("Nível \(game.state.level)", systemImage: "person.crop.circle.fill").font(.headline)
                        Spacer()
                        Label("\(game.state.coins)", systemImage: "circle.fill").foregroundStyle(Color.deepGold).font(.headline)
                    }
                    ProgressView(value: game.state.levelProgress).tint(.deepTeal)
                    Text("\(game.state.experience) / \(game.state.threshold(for: game.state.level + 1)) XP").font(.caption).foregroundStyle(.secondary)
                }
                BaseShowcase(outfit: game.state.outfit, pickaxe: game.state.equippedPickaxe).frame(height: 390)
                Button(action: onExplore) { Label(game.state.expedition == nil ? "Explorar a mina" : "Continuar expedição", systemImage: "mountain.2.fill") }.buttonStyle(GoldButtonStyle())
                HStack {
                    Label("Recorde: \(game.state.deepestRow) m", systemImage: "arrow.down")
                    Spacer()
                    Text("\(game.state.inventory.count) pedras na oficina")
                }.font(.caption).foregroundStyle(.secondary)
                Button(action: onShop) {
                    HStack {
                        PickaxeArt(kind: .amethyst).frame(width: 55, height: 55)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Conheça sua próxima picareta").font(.headline)
                            Text("Equipamentos e melhorias na Loja").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                    }.padding(14).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
                NavigationLink { CharacterView() } label: {
                    Label("Personalizar explorador", systemImage: "person.crop.circle").font(.headline)
                }.padding(8)
                Button("Como jogar") { tutorial = true }.padding(.bottom)
            }.padding(20)
        }.background(Color.deepBackground).toolbar(.hidden, for: .navigationBar)
            .onAppear { if !game.state.hasSeenTutorial && !ProcessInfo.processInfo.arguments.contains("-deepgems-screenshot") { tutorial = true } }
            .sheet(isPresented: $tutorial) {
                VStack(alignment: .leading, spacing: 24) {
                    ScreenTitle(title: "Sua primeira descoberta", subtitle: "Explore. Lapide. Evolua.")
                    Label("Toque nos blocos dourados ao lado do personagem para escavar ou andar.", systemImage: "hand.tap.fill")
                    Label("Energia acaba e a mochila enche. Volte à base para guardar tudo e preparar outra expedição.", systemImage: "backpack.fill")
                    Label("Na Oficina, alinhe os cortes e deslize sobre a pedra para lapidar. Venda para comprar melhorias.", systemImage: "diamond.fill")
                    Text("Novas pedras aparecem a partir de 8, 20, 35 e 55 metros. Você pode pausar fechando o app.").foregroundStyle(.secondary)
                    Button("Bora escavar!") { game.finishTutorial(); tutorial = false }.buttonStyle(GoldButtonStyle())
                }.padding(24).presentationDetents([.large])
            }
    }
    private func upgradeDescription(_ kind: Upgrade) -> String {
        switch kind {
        case .pickaxe: return "\(game.state.pickaxeLevel) de força por golpe"
        case .backpack: return "\(game.state.capacity) pedras por expedição"
        case .stamina: return "\(game.state.maximumEnergy) de energia por expedição"
        }
    }
}
