import Foundation

public struct LoadedGame {
    public var state: GameState
    public var recoveredBackup: Bool
}

public final class SaveStore {
    public let directory: URL
    public var saveURL: URL { directory.appendingPathComponent("progress-v1.json") }
    public var backupURL: URL { directory.appendingPathComponent("progress-v1.backup.json") }
    public init(directory: URL) { self.directory = directory }

    public func load() throws -> LoadedGame {
        let manager = FileManager.default
        let hasMain = manager.fileExists(atPath: saveURL.path)
        let hasBackup = manager.fileExists(atPath: backupURL.path)
        if !hasMain && !hasBackup { return LoadedGame(state: GameState(), recoveredBackup: false) }
        if hasMain, let state = try? decode(at: saveURL) { return LoadedGame(state: state, recoveredBackup: false) }
        if hasBackup, let state = try? decode(at: backupURL) { return LoadedGame(state: state, recoveredBackup: true) }
        throw GameError.message("Não foi possível ler o progresso nem a cópia anterior. Seus arquivos foram preservados. Você pode tentar novamente ou confirmar um novo jogo.")
    }

    public func save(_ state: GameState) throws {
        try validate(state)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        if let existing = try? Data(contentsOf: saveURL), (try? decode(data: existing)) != nil {
            try existing.write(to: backupURL, options: .atomic)
        }
        try data.write(to: saveURL, options: .atomic)
    }

    public func archiveAndReset() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let archive = directory.appendingPathComponent("archive-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: archive, withIntermediateDirectories: true)
        for url in [saveURL, backupURL] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.copyItem(at: url, to: archive.appendingPathComponent(url.lastPathComponent))
        }
        let encoder = JSONEncoder()
        let fresh = try encoder.encode(GameState())
        // Write both fresh snapshots only after preserving the previous files.
        try fresh.write(to: backupURL, options: .atomic)
        try fresh.write(to: saveURL, options: .atomic)
    }

    private func decode(at url: URL) throws -> GameState { try decode(data: Data(contentsOf: url)) }
    private func decode(data: Data) throws -> GameState {
        let state = try JSONDecoder().decode(GameState.self, from: data)
        try validate(state)
        return state
    }

    public func validate(_ state: GameState) throws {
        guard state.schemaVersion == 1, (0...1_000_000_000).contains(state.coins),
              (0...1_000_000_000).contains(state.experience),
              (1...1000).contains(state.pickaxeLevel), (1...1000).contains(state.backpackLevel),
              (1...1000).contains(state.staminaLevel), (0...10_000_000).contains(state.deepestRow) else {
            throw GameError.message("Formato ou valores de progresso inválidos.")
        }
        var allGems = state.inventory
        if let expedition = state.expedition {
            guard state.cutting == nil, (0...state.maximumEnergy).contains(expedition.energy),
                  expedition.carried.count <= state.capacity, (0..<GameEngine.columns).contains(expedition.player.column),
                  (0...10_000_000).contains(expedition.player.row),
                  expedition.tiles.contains(where: { $0.position == expedition.player && $0.isEmpty }),
                  Set(expedition.tiles.map(\.position)).count == expedition.tiles.count,
                  expedition.tiles.count <= 200,
                  expedition.tiles.allSatisfy({ (0..<GameEngine.columns).contains($0.position.column) && (0...10_000_100).contains($0.position.row) && (0...12).contains($0.hardness) && (0...$0.hardness).contains($0.remaining) }) else {
                throw GameError.message("Expedição inválida no arquivo de progresso.")
            }
            allGems.append(contentsOf: expedition.carried)
            allGems.append(contentsOf: expedition.tiles.compactMap(\.gem))
        }
        guard Set(allGems.map(\.id)).count == allGems.count,
              allGems.allSatisfy({ (1...3).contains($0.carats) && (50...100).contains($0.purity) && ($0.cutQuality == nil || (0...100).contains($0.cutQuality!)) }) else {
            throw GameError.message("Inventário inválido no arquivo de progresso.")
        }
        if let cutting = state.cutting {
            guard let gem = state.inventory.first(where: { $0.id == cutting.gemID }), gem.cutQuality == nil,
                  cutting.scores.count < gem.kind.cutCount, cutting.scores.allSatisfy({ (0...100).contains($0) }) else {
                throw GameError.message("Lapidação inválida no arquivo de progresso.")
            }
        }
    }
}
