import Foundation

public enum MineRegion: Int, CaseIterable {
    case earth, copperCaves, crystalDepths
    public static func at(_ row: Int) -> Self { row >= 30 ? .crystalDepths : (row >= 12 ? .copperCaves : .earth) }
    public var name: String { ["Terra e raízes", "Cavernas de cobre", "Abismo de cristais"][rawValue] }
}

public enum StructureKind: String, Codable, CaseIterable, Identifiable {
    case ladder, light, elevator
    public var id: String { rawValue }
    public var name: String { switch self { case .ladder: return "Escada"; case .light: return "Iluminação"; case .elevator: return "Elevador" } }
    public var symbol: String { switch self { case .ladder: return "ladder"; case .light: return "lightbulb.fill"; case .elevator: return "arrow.up.arrow.down.square.fill" } }
    public var cost: BuildCost {
        switch self {
        case .ladder: return BuildCost(coins: 0, copper: 0, iron: 1, depth: 0)
        case .light: return BuildCost(coins: 0, copper: 2, iron: 0, depth: 0)
        case .elevator: return BuildCost(coins: 120, copper: 0, iron: 8, depth: 12)
        }
    }
}

public struct BuildCost {
    public let coins: Int
    public let copper: Int
    public let iron: Int
    public let depth: Int
    public var description: String { "\(coins) moedas • \(copper) cobre • \(iron) ferro" + (depth > 0 ? " • \(depth) m" : "") }
    public func isAffordable(_ state: GameState) -> Bool {
        state.coins >= coins && state.copper >= copper && state.iron >= iron && state.deepestRow >= depth
    }
}

public struct MineStructure: Codable, Equatable, Identifiable {
    public var kind: StructureKind
    public var position: GridPosition
    public var id: String { "\(kind.rawValue):\(position.column):\(position.row)" }
}

public struct MineGoal: Identifiable {
    public let id: String
    public let title: String
    public let progress: Int
    public let target: Int
    public let reward: Int
    public var complete: Bool { progress >= target }
}

public enum Progression {
    public static let maximumDepth = 10_000_000
    public static let secretEntrance = GridPosition(column: 4, row: 18)
    public static let relicPositions: [String: GridPosition] = [
        "Fóssil ancestral": .init(column: 3, row: 6),
        "Ídolo da sala secreta": .init(column: 5, row: 18),
        "Coração de cristal": .init(column: 1, row: 32)
    ]
    public static func campCost(_ level: Int) -> BuildCost {
        level == 1 ? BuildCost(coins: 60, copper: 0, iron: 3, depth: 0) : BuildCost(coins: 180, copper: 0, iron: 8, depth: 24)
    }
    public static func goals(_ s: GameState) -> [MineGoal] {
        [MineGoal(id: "pack", title: "Melhore sua primeira mochila", progress: s.backpackLevel - 1, target: 1, reward: 30),
         MineGoal(id: "light", title: "Ilumine seu primeiro túnel", progress: s.structures.filter { $0.kind == .light }.count, target: 1, reward: 30),
         MineGoal(id: "depth", title: "Explore as cavernas de cobre", progress: min(12, s.deepestRow), target: 12, reward: 40),
         MineGoal(id: "elevator", title: "Construa seu primeiro elevador", progress: s.structures.filter { $0.kind == .elevator }.count, target: 1, reward: 60),
         MineGoal(id: "relic", title: "Encontre uma relíquia", progress: s.relics.count, target: 1, reward: 40),
         MineGoal(id: "camp", title: "Transforme sua base de mineração", progress: s.campLevel - 1, target: 2, reward: 100)]
    }
    public static func settle(_ state: inout GameState) {
        // Rewards are saved and granted once, in order, including after reopening the app.
        for goal in goals(state) {
            if state.completedGoals.contains(goal.id) { continue }
            guard goal.complete else { break }
            state.completedGoals.append(goal.id)
            state.coins = min(1_000_000_000, state.coins + goal.reward)
        }
    }
}

extension GameState {
    public var characterTier: Int { backpackLevel >= 3 || equippedPickaxe == .amethyst ? 3 : (backpackLevel >= 2 || equippedPickaxe == .copper ? 2 : 1) }
    public var currentGoal: MineGoal? { Progression.goals(self).first { !completedGoals.contains($0.id) } }
    public var elevatorStops: [MineStructure] { structures.filter { $0.kind == .elevator }.sorted { $0.position.row < $1.position.row } }
    public func isLit(_ position: GridPosition) -> Bool {
        position.row < 12 || structures.contains { $0.kind == .light && abs($0.position.row - position.row) <= 3 && abs($0.position.column - position.column) <= 3 }
    }
    public func hasLadder(at position: GridPosition) -> Bool { structures.contains { $0.kind == .ladder && $0.position == position } }
}
