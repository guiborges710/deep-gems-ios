import Foundation

public enum GameEngine {
    public static let columns = 6
    public static let retainedRows = 14

    public static func startExpedition(state: inout GameState, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) throws {
        guard state.expedition == nil else { return }
        guard state.cutting == nil else { throw GameError.message("Termine a lapidação antes de explorar.") }
        var expedition = Expedition(seed: seed, player: .init(column: 2, row: 0), energy: state.maximumEnergy,
                                    carried: [], tiles: [], deepestRow: 0, lastGeneratedRow: -1)
        generateRows(in: &expedition, through: retainedRows - 1)
        // A visible, guaranteed first discovery makes the initial expedition understandable.
        if let index = expedition.tiles.firstIndex(where: { $0.position == GridPosition(column: 2, row: 1) }) {
            expedition.tiles[index].gem = Gem(kind: .quartz, purity: 85)
            expedition.tiles[index].hardness = 1; expedition.tiles[index].remaining = 1
        }
        state.expedition = expedition
    }

    public static func act(state: inout GameState, at position: GridPosition) throws {
        guard var expedition = state.expedition else { throw GameError.message("Comece uma expedição.") }
        guard position.isAdjacent(to: expedition.player) else { throw GameError.message("Escolha um bloco ao lado do explorador.") }
        guard let index = expedition.tiles.firstIndex(where: { $0.position == position }) else {
            throw GameError.message("Esse trecho está fora da área acessível.")
        }
        let tile = expedition.tiles[index]
        if !tile.isEmpty {
            guard expedition.energy > 0 else { throw GameError.message("Energia esgotada. Volte à base para guardar o saque.") }
            let damage = state.pickaxeLevel
            if tile.remaining <= damage, tile.gem != nil, expedition.carried.count >= state.capacity {
                throw GameError.message("Mochila cheia! Volte à base antes de coletar outra pedra.")
            }
            expedition.energy -= 1
            expedition.tiles[index].remaining = max(0, tile.remaining - damage)
            if expedition.tiles[index].remaining == 0 {
                state.experience += 4
                if let gem = tile.gem {
                    expedition.carried.append(gem)
                    var entry = state.collection[gem.kind.rawValue] ?? CollectionEntry()
                    entry.found += 1
                    state.collection[gem.kind.rawValue] = entry
                    state.experience += 8
                }
                expedition.tiles[index].gem = nil
            }
        }
        if expedition.tiles[index].isEmpty {
            expedition.player = position
            expedition.deepestRow = max(expedition.deepestRow, position.row)
            state.deepestRow = max(state.deepestRow, position.row)
            generateRows(in: &expedition, through: position.row + retainedRows - 1)
            // Retain a few rows above the player; this bounds save size even in long sessions.
            let minimumRow = max(0, position.row - 3)
            expedition.tiles.removeAll { $0.position.row < minimumRow }
        }
        state.expedition = expedition
    }

    public static func returnToBase(state: inout GameState) {
        guard let expedition = state.expedition else { return }
        state.inventory.append(contentsOf: expedition.carried)
        state.expedition = nil
    }

    public static func upgrade(state: inout GameState, kind: Upgrade) throws {
        let cost = state.upgradeCost(kind)
        guard state.coins >= cost else { throw GameError.message("Você precisa de \(cost) moedas para essa melhoria.") }
        guard state.upgradeLevel(kind) < 1000 else { throw GameError.message("Limite de equipamento desta versão atingido.") }
        state.coins -= cost
        switch kind { case .pickaxe: state.pickaxeLevel += 1; case .backpack: state.backpackLevel += 1; case .stamina: state.staminaLevel += 1 }
    }

    public static func sell(state: inout GameState, gemID: UUID) throws {
        guard state.cutting?.gemID != gemID else { throw GameError.message("Termine a lapidação antes de vender esta pedra.") }
        guard let index = state.inventory.firstIndex(where: { $0.id == gemID }) else { throw GameError.message("Pedra não encontrada.") }
        state.coins += state.inventory[index].value
        state.inventory.remove(at: index)
    }

    public static func beginCutting(state: inout GameState, gemID: UUID) throws {
        guard state.expedition == nil else { throw GameError.message("Volte à oficina para lapidar.") }
        guard state.cutting == nil else { throw GameError.message("Existe uma lapidação em andamento.") }
        guard let gem = state.inventory.first(where: { $0.id == gemID }), gem.cutQuality == nil else {
            throw GameError.message("Selecione uma pedra bruta do inventário.")
        }
        state.cutting = CuttingSession(gemID: gemID)
    }

    public static func targetAngle(for gem: Gem, cut: Int) -> Double {
        let angles: [Double] = gem.kind == .amethyst ? [-30, 30, 0, 45] : [-35, 10, 40, -15]
        return angles[min(cut, angles.count - 1)]
    }

    public static func applyCut(state: inout GameState, angle: Double, gestureAccuracy: Double = 1) throws -> Int? {
        guard angle.isFinite, gestureAccuracy.isFinite else { throw GameError.message("Corte inválido.") }
        guard var session = state.cutting,
              let index = state.inventory.firstIndex(where: { $0.id == session.gemID }) else {
            throw GameError.message("Nenhuma lapidação em andamento.")
        }
        let gem = state.inventory[index]
        guard gem.cutQuality == nil, session.scores.count < gem.kind.cutCount else { throw GameError.message("Lapidação já concluída.") }
        let target = targetAngle(for: gem, cut: session.scores.count)
        let offset = abs(angle - target)
        var precision = max(0, 1 - offset / gem.kind.tolerance)
        if gem.kind == .emerald && abs(angle - 25) < 9 { precision *= 0.5 }
        let score = Int((precision * min(1, max(0, gestureAccuracy)) * 100).rounded())
        session.scores.append(score)
        if session.scores.count == gem.kind.cutCount {
            let quality = session.scores.reduce(0, +) / session.scores.count
            state.inventory[index].cutQuality = quality
            state.experience += 15 + quality / 2
            var entry = state.collection[gem.kind.rawValue] ?? CollectionEntry()
            entry.bestQuality = max(entry.bestQuality, quality)
            entry.bestValue = max(entry.bestValue, state.inventory[index].value)
            state.collection[gem.kind.rawValue] = entry
            state.cutting = nil
            return quality
        }
        state.cutting = session
        return nil
    }

    public static func equip(state: inout GameState, outfit: Outfit) throws {
        guard state.level >= outfit.requiredLevel else { throw GameError.message("Esta roupa desbloqueia no nível \(outfit.requiredLevel).") }
        state.outfit = outfit
    }

    private static func noise(seed: UInt64, row: Int, column: Int) -> UInt64 {
        var value = seed &+ UInt64(row) &* 0x9E3779B97F4A7C15 &+ UInt64(column) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    private static func generateRows(in expedition: inout Expedition, through row: Int) {
        guard row > expedition.lastGeneratedRow else { return }
        for depth in (expedition.lastGeneratedRow + 1)...row {
            for column in 0..<columns {
                let roll = noise(seed: expedition.seed, row: depth, column: column)
                let hardness = depth == 0 ? 0 : min(12, 1 + depth / 10 + Int(roll % 3))
                var gem: Gem?
                if depth > 0 && roll % 100 < 30 {
                    let available = GemKind.allCases.filter { $0.minimumDepth <= depth }
                    // Higher rarity needs both sufficient depth and a high secondary roll.
                    let rarityRoll = Int((roll >> 8) % 100)
                    let candidate = rarityRoll < 55 ? 0 : (rarityRoll < 80 ? 1 : (rarityRoll < 93 ? 2 : (rarityRoll < 98 ? 3 : 4)))
                    let kind = available[min(candidate, available.count - 1)]
                    gem = Gem(kind: kind, carats: 1 + Int((roll >> 16) % 3), purity: 50 + Int((roll >> 24) % 51))
                }
                expedition.tiles.append(MineTile(position: .init(column: column, row: depth), hardness: hardness, remaining: hardness, gem: gem))
            }
        }
        expedition.lastGeneratedRow = row
    }
}
