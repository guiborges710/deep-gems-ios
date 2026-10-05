import SwiftUI

struct RootView: View {
    @EnvironmentObject private var game: GameStore
    @State private var tab = ProcessInfo.processInfo.arguments.contains("-deepgems-shop-preview") ? 4 : (ProcessInfo.processInfo.arguments.contains("-deepgems-mine-preview") || ProcessInfo.processInfo.arguments.contains("-deepgems-depth-preview") ? 1 : (ProcessInfo.processInfo.arguments.contains("-deepgems-workshop-preview") ? 2 : 0))
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
                    NavigationStack { if ProcessInfo.processInfo.arguments.contains("-deepgems-character-preview") { CharacterView() } else { CampView(explore: { game.start(); if game.state.expedition != nil { tab = 1 } }, shop: { tab = 4 }) } }
                        .tabItem { Label("Base", systemImage: "house.fill") }.tag(0)
                    NavigationStack { MineView() }
                        .tabItem { Label("Mina", systemImage: "mountain.2.fill") }.tag(1)
                    NavigationStack { WorkshopView() }
                        .tabItem { Label("Oficina", systemImage: "hammer.fill") }.tag(2)
                    NavigationStack { CollectionView() }
                        .tabItem { Label("Coleção", systemImage: "diamond.fill") }.tag(3)
                    NavigationStack { EquipmentView() }
                        .tabItem { Label("Equipamentos", systemImage: "bag.fill") }.tag(4)
                }
                .toolbarBackground(Color.deepBackground, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
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
        .overlay {
            if let reward = game.acquisition {
                ZStack {
                    Color.black.opacity(0.7).ignoresSafeArea()
                    VStack(spacing: 22) {
                        Text("NOVA CONQUISTA").font(.caption.bold()).tracking(3).foregroundStyle(Color.deepGold)
                        Text(reward.title).font(.system(.title2, design: .serif, weight: .bold)).multilineTextAlignment(.center)
                        if let kind = reward.upgrade {
                            HStack(spacing: 20) {
                                VStack { UpgradeArt(kind: kind, level: reward.oldLevel, pickaxe: reward.pickaxe).frame(width: 90, height: 120); Text("Nv. \(reward.oldLevel)").font(.caption) }
                                Image(systemName: "arrow.right").foregroundStyle(Color.deepGold)
                                VStack { UpgradeArt(kind: kind, level: reward.newLevel, pickaxe: reward.pickaxe).frame(width: 110, height: 140); Text("Nv. \(reward.newLevel)").font(.headline).foregroundStyle(Color.deepGold) }
                            }
                        } else { PickaxeArt(kind: reward.pickaxe).frame(height: 200) }
                        Text("Equipamento pronto para sua próxima expedição.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("Continuar") { withAnimation { game.acquisition = nil } }.buttonStyle(GoldButtonStyle())
                    }.padding(26).background(Color.deepPanel, in: RoundedRectangle(cornerRadius: 28))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.deepGold, lineWidth: 2)).padding(24)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4), value: game.acquisition?.id)
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
        GeometryReader { geometry in
            ZStack {
                Image("BaseV2").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped().ignoresSafeArea(edges: .top)
                LinearGradient(colors: [.black.opacity(0.5), .clear, Color.deepBackground.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 12) {
                    HStack {
                        Text("Sua base").font(.system(.largeTitle, design: .serif, weight: .bold))
                        Spacer()
                        Label("\(game.state.coins)", systemImage: "circle.fill").font(.headline).foregroundStyle(Color.deepGold)
                            .padding(10).background(Color.deepBackground.opacity(0.85), in: Capsule())
                    }
                    HStack(spacing: 12) {
                        NavigationLink { CharacterView() } label: {
                            Image(uiImage: GameArtwork.portrait(game.state.outfit)).resizable().scaledToFill()
                                .frame(width: 52, height: 52).clipped().clipShape(Circle()).overlay(Circle().stroke(Color.deepGold, lineWidth: 2))
                        }.accessibilityLabel("Personalizar explorador")
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text("Nível \(game.state.level)").font(.headline); Spacer(); Text("\(game.state.experience) / \(game.state.threshold(for: game.state.level + 1)) XP").font(.caption2) }
                            ProgressView(value: game.state.levelProgress).tint(.deepTeal)
                        }
                    }
                    NavigationLink { CharacterView() } label: {
                        ExplorerShowcase(outfit: game.state.outfit, pickaxe: game.state.equippedPickaxe, backpackLevel: game.state.backpackLevel, staminaLevel: game.state.staminaLevel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }.buttonStyle(.plain).accessibilityLabel("Ver seu explorador e equipamentos")
                    HStack(spacing: 10) {
                        equipmentCard(.pickaxe, detail: "Força \(game.state.miningPower)")
                        equipmentCard(.backpack, detail: "\(game.state.capacity) pedras")
                    }
                    Button(action: onExplore) { Label(game.state.expedition == nil ? "Explorar" : "Continuar expedição", systemImage: "hammer.fill") }.buttonStyle(GoldButtonStyle())
                    HStack { Text("Recorde: \(game.state.deepestRow) m"); Spacer(); Button("Como jogar") { tutorial = true } }.font(.caption)
                }.padding(.horizontal, 20).padding(.vertical, 12)
            }
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
    private func equipmentCard(_ kind: Upgrade, detail: String) -> some View {
        Button(action: onShop) {
            HStack(spacing: 7) {
                UpgradeArt(kind: kind, level: game.state.upgradeLevel(kind), pickaxe: game.state.equippedPickaxe).frame(width: 48, height: 65)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(kind.name) • Nv. \(game.state.upgradeLevel(kind))").font(.caption.bold())
                    Text(detail).font(.caption2).foregroundStyle(.secondary)
                    Label("Melhorar", systemImage: "arrow.up.circle.fill").font(.caption2.bold()).foregroundStyle(Color.deepTeal)
                }
            }.padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.deepPanel.opacity(0.94), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2)))
        }.buttonStyle(.plain)
    }
    private func upgradeDescription(_ kind: Upgrade) -> String {
        switch kind {
        case .pickaxe: return "\(game.state.pickaxeLevel) de força por golpe"
        case .backpack: return "\(game.state.capacity) pedras por expedição"
        case .stamina: return "\(game.state.maximumEnergy) de energia por expedição"
        }
    }
}
