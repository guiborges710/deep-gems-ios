import Foundation

public enum GameEngine {
    public static let columns = 6
    public static let retainedRows = 14

    public static func startExpedition(state: inout GameState, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) throws {
        guard state.expedition == nil else { return }
        guard state.cutting == nil else { throw GameError.message("Termine a lapidação antes de explorar.") }
        if state.mineSeed == nil {
            state.mineSeed = seed
        }
        var expedition = Expedition(seed: state.mineSeed ?? seed, player: .init(column: 2, row: 0), energy: state.maximumEnergy,
                                    carried: [], tiles: [], deepestRow: state.deepestRow, lastGeneratedRow: -1)
        refreshWindow(in: &expedition, state: state)
        state.expedition = expedition
    }

    public static func act(state: inout GameState, at position: GridPosition) throws {
        guard var expedition = state.expedition else { throw GameError.message("Comece uma expedição.") }
        guard position.isAdjacent(to: expedition.player) else { throw GameError.message("Escolha um bloco ao lado do explorador.") }
        guard let index = expedition.tiles.firstIndex(where: { $0.position == position }) else {
            throw GameError.message("Esse trecho está fora da área acessível.")
        }
        let tile = expedition.tiles[index]
        if position.row < expedition.player.row && expedition.player.row > 0 && !state.hasLadder(at: expedition.player) {
            throw GameError.message("Instale uma escada aqui para subir. O resgate para a base está sempre disponível.")
        }
        if !tile.isEmpty {
            guard expedition.energy > 0 else { throw GameError.message("Energia esgotada. Volte à base para guardar o saque.") }
            let damage = state.miningPower
            if tile.remaining <= damage, tile.gem != nil, expedition.carried.count >= state.capacity {
                throw GameError.message("Mochila cheia! Volte à base antes de coletar outra pedra.")
            }
            expedition.energy -= 1
            expedition.tiles[index].remaining = max(0, tile.remaining - damage)
            if expedition.tiles[index].remaining == 0 {
                state.experience += 4
                // Resources do not occupy gem slots; even the early rocks advance construction.
                let yield = Progression.resourceYield(at: position)
                state.copper += yield.copper; state.iron += yield.iron
                if let relic = Progression.relicPositions.first(where: { $0.value == position })?.key,
                   !state.relics.contains(relic) { state.relics.append(relic) }
                if position == Progression.secretEntrance {
                    let room = GridPosition(column: 5, row: 18)
                    let chamber = MineTile(position: room, hardness: 1, remaining: 1, gem: Gem(kind: .amethyst, carats: 3, purity: 100))
                    if let i = expedition.tiles.firstIndex(where: { $0.position == room }) { expedition.tiles[i] = chamber }
                    remember(chamber, state: &state)
                }
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
        remember(expedition.tiles[index], state: &state)
        if expedition.tiles[index].isEmpty {
            expedition.player = position
            expedition.deepestRow = max(expedition.deepestRow, position.row)
            state.deepestRow = max(state.deepestRow, position.row)
            refreshWindow(in: &expedition, state: state)
        }
        Progression.settle(&state)
        state.expedition = expedition
    }

    public static func returnToBase(state: inout GameState) {
        guard let expedition = state.expedition else { return }
        state.inventory.append(contentsOf: expedition.carried)
        state.mineSeed = expedition.seed
        for tile in expedition.tiles where tile.remaining != tile.hardness { remember(tile, state: &state) }
        state.expedition = nil
        Progression.settle(&state)
    }

    public static func upgrade(state: inout GameState, kind: Upgrade) throws {
        guard state.expedition == nil else { throw GameError.message("Volte à base para melhorar seus equipamentos.") }
        let cost = state.upgradeCost(kind)
        guard state.coins >= cost else { throw GameError.message("Você precisa de \(cost) moedas para essa melhoria.") }
        guard state.upgradeLevel(kind) < 1000 else { throw GameError.message("Limite de equipamento desta versão atingido.") }
        state.coins -= cost
        switch kind { case .pickaxe: state.pickaxeLevel += 1; case .backpack: state.backpackLevel += 1; case .stamina: state.staminaLevel += 1 }
        Progression.settle(&state)
    }

    public static func buyPickaxe(state: inout GameState, kind: PickaxeKind) throws {
        guard state.expedition == nil else { throw GameError.message("Volte à base para trocar seus equipamentos.") }
        guard !state.ownedPickaxes.contains(kind) else { throw GameError.message("Você já possui esta picareta.") }
        guard state.coins >= kind.price else { throw GameError.message("Faltam \(kind.price - state.coins) moedas para esta picareta.") }
        state.coins -= kind.price
        state.ownedPickaxes.append(kind)
        state.equippedPickaxe = kind
    }

    public static func equipPickaxe(state: inout GameState, kind: PickaxeKind) throws {
        guard state.expedition == nil else { throw GameError.message("Volte à base para trocar seus equipamentos.") }
        guard state.ownedPickaxes.contains(kind) else { throw GameError.message("Compre esta picareta antes de equipar.") }
        state.equippedPickaxe = kind
    }

    public static func sell(state: inout GameState, gemID: UUID) throws {
        guard state.cutting?.gemID != gemID else { throw GameError.message("Termine a lapidação antes de vender esta pedra.") }
        guard let index = state.inventory.firstIndex(where: { $0.id == gemID }) else { throw GameError.message("Pedra não encontrada.") }
        state.coins += state.inventory[index].value
        state.inventory.remove(at: index)
    }

    /// Validate the complete selection before changing coins or inventory.
    public static func sellBatch(state: inout GameState, gemIDs: Set<UUID>) throws {
        guard !gemIDs.isEmpty else { throw GameError.message("Selecione pedras para vender.") }
        let gems = state.inventory.filter { gemIDs.contains($0.id) }
        guard gems.count == gemIDs.count, !gems.contains(where: { $0.id == state.cutting?.gemID }) else {
            throw GameError.message("A seleção mudou ou contém uma pedra em lapidação.")
        }
        let total = gems.reduce(0) { $0 + $1.value }
        guard state.coins <= 1_000_000_000 - total else { throw GameError.message("Limite de moedas desta versão atingido.") }
        state.coins += total
        state.inventory.removeAll { gemIDs.contains($0.id) }
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

    private static func remember(_ tile: MineTile, state: inout GameState) {
        if let i = state.mineChanges.firstIndex(where: { $0.position == tile.position }) { state.mineChanges[i] = tile }
        else { state.mineChanges.append(tile) }
    }

    private static func generatedTile(seed: UInt64, depth: Int, column: Int) -> MineTile {
        let roll = noise(seed: seed, row: depth, column: column)
        let hardness = depth == 0 ? 0 : min(12, 1 + depth / 10 + Int(roll % 3))
        var gem: Gem?
        if depth > 0 && roll % 100 < 30 {
            let available = GemKind.allCases.filter { $0.minimumDepth <= depth }
            let r = Int((roll >> 8) % 100)
            let candidate = r < 55 ? 0 : (r < 80 ? 1 : (r < 93 ? 2 : (r < 98 ? 3 : 4)))
            gem = Gem(kind: available[min(candidate, available.count - 1)], carats: 1 + Int((roll >> 16) % 3), purity: 50 + Int((roll >> 24) % 51))
        }
        if depth == 1 && column == 2 { return MineTile(position: .init(column: column, row: depth), hardness: 1, remaining: 1, gem: Gem(kind: .quartz, purity: 85)) }
        return MineTile(position: .init(column: column, row: depth), hardness: hardness, remaining: hardness, gem: gem)
    }

    private static func refreshWindow(in e: inout Expedition, state: GameState) {
        let first = max(0, e.player.row - 3)
        let last = min(Progression.maximumDepth, e.player.row + retainedRows - 1)
        let existing = Dictionary(uniqueKeysWithValues: e.tiles.map { ($0.position, $0) })
        let changes = Dictionary(uniqueKeysWithValues: state.mineChanges.map { ($0.position, $0) })
        var tiles: [MineTile] = []
        for row in first...last {
            for column in 0..<columns {
                let position = GridPosition(column: column, row: row)
                tiles.append(changes[position] ?? existing[position] ?? generatedTile(seed: e.seed, depth: row, column: column))
            }
        }
        e.tiles = tiles; e.lastGeneratedRow = last
    }

    public static func build(state: inout GameState, kind: StructureKind) throws {
        guard let e = state.expedition, e.player.row > 0 else { throw GameError.message("Instale estruturas dentro de um túnel escavado.") }
        let structure = MineStructure(kind: kind, position: e.player)
        guard !state.structures.contains(where: { $0.id == structure.id }) else { throw GameError.message("Essa estrutura já existe aqui.") }
        try pay(kind.cost, state: &state)
        state.structures.append(structure)
        Progression.settle(&state)
    }

    public static func improveCamp(state: inout GameState) throws {
        guard state.expedition == nil, state.campLevel < 3 else { throw GameError.message("Volte à base. O acampamento tem três estágios.") }
        try pay(Progression.campCost(state.campLevel), state: &state)
        state.campLevel += 1
        Progression.settle(&state)
    }

    private static func pay(_ cost: BuildCost, state: inout GameState) throws {
        guard cost.isAffordable(state) else { throw GameError.message("Requisitos: " + cost.description) }
        state.coins -= cost.coins; state.copper -= cost.copper; state.iron -= cost.iron
    }

    public static func travel(state: inout GameState, to destination: GridPosition) throws {
        guard var e = state.expedition else { throw GameError.message("Entre na mina antes de usar o elevador.") }
        let atSurface = e.player.row == 0
        let atStation = state.elevatorStops.contains { $0.position == e.player }
        let destinationValid = destination == GridPosition(column: 2, row: 0) || state.elevatorStops.contains { $0.position == destination }
        guard !state.elevatorStops.isEmpty, atSurface || atStation, destinationValid else { throw GameError.message("Use o elevador na superfície ou em uma estação construída.") }
        e.player = destination
        refreshWindow(in: &e, state: state)
        guard e.tiles.contains(where: { $0.position == destination && $0.isEmpty }) else { throw GameError.message("A estação não está acessível.") }
        state.expedition = e
    }
}
