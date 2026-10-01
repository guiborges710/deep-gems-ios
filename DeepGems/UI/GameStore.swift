import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state = GameState()
    @Published var message: String?
    @Published var miningNotice: String?
    @Published var acquisition: Acquisition?
    struct Acquisition: Identifiable {
        let id = UUID()
        let title: String
        let upgrade: Upgrade?
        let pickaxe: PickaxeKind
        let oldLevel: Int
        let newLevel: Int
    }
    @Published var saveError: String?
    @Published var loadError: String?
    @Published var cuttingResult: Gem?
    private let saves: SaveStore
    let mineScene = MineScene()

    init() {
        let documents = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let preview = ProcessInfo.processInfo.arguments.contains("-deepgems-preview")
        let directory = preview ? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString) : documents.appendingPathComponent("DeepGems", isDirectory: true)
        saves = SaveStore(directory: directory)
        reload()
        if preview {
            state.coins = 1250; state.experience = 650; state.backpackLevel = 3
            state.inventory = [Gem(kind: .amethyst), Gem(kind: .quartz), Gem(kind: .diamond, cutQuality: 95)]
            state.hasSeenTutorial = true
            if ProcessInfo.processInfo.arguments.contains("-deepgems-mine-preview") { try? GameEngine.startExpedition(state: &state, seed: 710) }
            if ProcessInfo.processInfo.arguments.contains("-deepgems-cut-preview") { try? GameEngine.beginCutting(state: &state, gemID: state.inventory[0].id) }
        }
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

    @discardableResult
    private func change(quiet: Bool = false, _ action: (inout GameState) throws -> Void) -> Bool {
        guard loadError == nil else { return false }
        // On a disk error, preserve the visible state and stop new actions until retry succeeds.
        guard saveError == nil else { message = "Tente salvar novamente antes de continuar."; return false }
        var next = state
        do {
            try action(&next)
            try saves.validate(next)
            state = next
            save()
            syncScene()
            return true
        } catch {
            if quiet { miningNotice = error.localizedDescription } else { message = error.localizedDescription }
            return false
        }
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
        miningNotice = nil
        guard change(quiet: true, { try GameEngine.act(state: &$0, at: position) }) else { return }
        if let beforeEnergy, let afterEnergy = state.expedition?.energy, afterEnergy < beforeEnergy {
            mineScene.strike(at: position)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if (state.expedition?.carried.count ?? 0) > before {
            mineScene.discovery(at: position)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    func move(column: Int, row: Int) {
        guard let position = state.expedition?.player else { return }
        mine(at: .init(column: position.column + column, row: position.row + row))
    }
    func returnToBase() { if change({ GameEngine.returnToBase(state: &$0) }) { miningNotice = nil } }
    func upgrade(_ kind: Upgrade) {
        let previous = state.upgradeLevel(kind)
        if change({ try GameEngine.upgrade(state: &$0, kind: kind) }) {
            acquisition = Acquisition(title: "\(kind.name) melhorada!", upgrade: kind, pickaxe: state.equippedPickaxe, oldLevel: previous, newLevel: previous + 1)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    func buyPickaxe(_ kind: PickaxeKind) {
        if change({ try GameEngine.buyPickaxe(state: &$0, kind: kind) }) {
            acquisition = Acquisition(title: "\(kind.name) adquirida!", upgrade: nil, pickaxe: kind, oldLevel: state.pickaxeLevel, newLevel: state.pickaxeLevel)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    func equipPickaxe(_ kind: PickaxeKind) { change { try GameEngine.equipPickaxe(state: &$0, kind: kind) } }
    func sell(_ gem: Gem) { change { try GameEngine.sell(state: &$0, gemID: gem.id) } }
    func sellBatch(_ ids: Set<UUID>) { change { try GameEngine.sellBatch(state: &$0, gemIDs: ids) } }
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
    func canAct(column: Int, row: Int) -> Bool {
        guard let e = state.expedition else { return false }
        let position = GridPosition(column: e.player.column + column, row: e.player.row + row)
        guard let tile = e.tiles.first(where: { $0.position == position }) else { return false }
        return tile.isEmpty || (e.energy > 0 && !(tile.gem != nil && tile.remaining <= state.miningPower && e.carried.count >= state.capacity))
    }
    private func syncScene() { mineScene.render(expedition: state.expedition, outfit: state.outfit, pickaxe: state.equippedPickaxe, backpackLevel: state.backpackLevel, staminaLevel: state.staminaLevel) }
}
