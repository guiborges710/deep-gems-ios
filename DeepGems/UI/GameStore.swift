import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state = GameState()
    @Published var message: String?
    @Published var saveError: String?
    @Published var loadError: String?
    @Published var cuttingResult: Gem?
    private let saves: SaveStore
    let mineScene = MineScene()

    init() {
        let documents = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        saves = SaveStore(directory: documents.appendingPathComponent("DeepGems", isDirectory: true))
        reload()
        mineScene.onSelect = { [weak self] position in self?.mine(at: position) }
        syncScene()
    }

    func reload() {
        do {
            let loaded = try saves.load()
            state = loaded.state; loadError = nil
            if loaded.recoveredBackup { message = "Progresso recuperado da cópia anterior. A última ação pode não estar presente." }
            syncScene()
        } catch { loadError = error.localizedDescription }
    }

    private func change(_ action: (inout GameState) throws -> Void) {
        guard loadError == nil else { return }
        // On a disk error, preserve the visible state and stop new actions until retry succeeds.
        guard saveError == nil else { message = "Tente salvar novamente antes de continuar."; return }
        var next = state
        do {
            try action(&next)
            try saves.validate(next)
            state = next
            save()
            syncScene()
        } catch { message = error.localizedDescription }
    }

    func save() {
        guard loadError == nil else { return }
        do { try saves.save(state); saveError = nil }
        catch { saveError = error.localizedDescription }
    }
    func start() { change { try GameEngine.startExpedition(state: &$0) } }
    func mine(at position: GridPosition) {
        let before = state.expedition?.carried.count ?? 0
        let beforeEnergy = state.expedition?.energy
        change { try GameEngine.act(state: &$0, at: position) }
        if let beforeEnergy, let afterEnergy = state.expedition?.energy, afterEnergy < beforeEnergy {
            mineScene.strike(at: position)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if (state.expedition?.carried.count ?? 0) > before {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    func move(column: Int, row: Int) {
        guard let position = state.expedition?.player else { return }
        mine(at: .init(column: position.column + column, row: position.row + row))
    }
    func returnToBase() { change { GameEngine.returnToBase(state: &$0) } }
    func upgrade(_ kind: Upgrade) { change { try GameEngine.upgrade(state: &$0, kind: kind) } }
    func buyPickaxe(_ kind: PickaxeKind) { change { try GameEngine.buyPickaxe(state: &$0, kind: kind) } }
    func equipPickaxe(_ kind: PickaxeKind) { change { try GameEngine.equipPickaxe(state: &$0, kind: kind) } }
    func sell(_ gem: Gem) { change { try GameEngine.sell(state: &$0, gemID: gem.id) } }
    func beginCutting(_ gem: Gem) { change { try GameEngine.beginCutting(state: &$0, gemID: gem.id) } }
    func cut(angle: Double, accuracy: Double) {
        guard let id = state.cutting?.gemID else { return }
        change { _ = try GameEngine.applyCut(state: &$0, angle: angle, gestureAccuracy: accuracy) }
        if state.cutting == nil { cuttingResult = state.inventory.first { $0.id == id } }
    }
    func equip(_ outfit: Outfit) { change { try GameEngine.equip(state: &$0, outfit: outfit) } }
    func finishTutorial() { change { $0.hasSeenTutorial = true } }
    func reset() {
        do {
            try saves.archiveAndReset()
            state = GameState(); loadError = nil; saveError = nil; cuttingResult = nil
            syncScene()
        } catch { message = error.localizedDescription }
    }
    private func syncScene() { mineScene.render(expedition: state.expedition, outfit: state.outfit, pickaxe: state.equippedPickaxe) }
}
