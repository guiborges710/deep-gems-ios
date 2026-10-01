import Foundation

public enum GemKind: String, Codable, CaseIterable, Identifiable {
    case quartz, amethyst, emerald, ruby, diamond
    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .quartz: return "Quartzo"
        case .amethyst: return "Ametista"
        case .emerald: return "Esmeralda"
        case .ruby: return "Rubi"
        case .diamond: return "Diamante"
        }
    }
    public var minimumDepth: Int {
        switch self {
        case .quartz: return 0
        case .amethyst: return 8
        case .emerald: return 20
        case .ruby: return 35
        case .diamond: return 55
        }
    }
    public var baseValue: Int {
        switch self {
        case .quartz: return 20
        case .amethyst: return 45
        case .emerald: return 90
        case .ruby: return 140
        case .diamond: return 240
        }
    }
    public var tolerance: Double {
        switch self {
        case .quartz: return 32
        case .amethyst: return 24
        case .emerald: return 17
        case .ruby: return 13
        case .diamond: return 10
        }
    }
    public var cuttingHint: String {
        switch self {
        case .quartz: return "Alinhe o corte dourado com a linha pontilhada. O quartzo tolera pequenos desvios."
        case .amethyst: return "Repita cortes alternados para formar uma peça simétrica."
        case .emerald: return "Evite a fissura vermelha: cortar perto dela reduz a qualidade."
        case .ruby: return "Cortes curtos e precisos. A margem de erro é pequena."
        case .diamond: return "Quatro facetas com alta precisão. Cada corte conta."
        }
    }
    public var cutCount: Int { self == .diamond ? 4 : 3 }
}

public struct Gem: Codable, Equatable, Identifiable {
    public var id: UUID
    public var kind: GemKind
    public var carats: Int
    public var purity: Int
    public var cutQuality: Int?
    public init(id: UUID = UUID(), kind: GemKind, carats: Int = 1, purity: Int = 70, cutQuality: Int? = nil) {
        self.id = id; self.kind = kind; self.carats = carats
        self.purity = purity; self.cutQuality = cutQuality
    }
    public var value: Int {
        let rough = kind.baseValue * carats * purity / 100
        guard let quality = cutQuality else { return max(1, rough) }
        return max(1, rough * (100 + quality * 3) / 100)
    }
    public var qualityName: String {
        guard let quality = cutQuality else { return "Bruta" }
        switch quality {
        case 90...100: return "Excepcional"
        case 70..<90: return "Excelente"
        case 40..<70: return "Boa"
        default: return "Irregular"
        }
    }
}

public struct GridPosition: Codable, Equatable, Hashable {
    public var column: Int
    public var row: Int
    public init(column: Int, row: Int) { self.column = column; self.row = row }
    public func isAdjacent(to other: GridPosition) -> Bool {
        abs(column - other.column) + abs(row - other.row) == 1
    }
}

public struct MineTile: Codable, Equatable, Identifiable {
    public var position: GridPosition
    public var hardness: Int
    public var remaining: Int
    public var gem: Gem?
    public var id: String { "\(position.column):\(position.row)" }
    public var isEmpty: Bool { remaining == 0 }
}

public struct Expedition: Codable, Equatable {
    public var seed: UInt64
    public var player: GridPosition
    public var energy: Int
    public var carried: [Gem]
    public var tiles: [MineTile]
    public var deepestRow: Int
    public var lastGeneratedRow: Int
}

public enum Upgrade: String, CaseIterable, Identifiable {
    case pickaxe, backpack, stamina
    public var id: String { rawValue }
    public var name: String {
        switch self { case .pickaxe: return "Picareta"; case .backpack: return "Mochila"; case .stamina: return "Resistência" }
    }
}

public enum Outfit: String, CaseIterable, Codable, Identifiable {
    case teal, purple, orange
    public var id: String { rawValue }
    public var name: String {
        switch self { case .teal: return "Explorador"; case .purple: return "Cristal violeta"; case .orange: return "Chama da mina" }
    }
    public var requiredLevel: Int { self == .teal ? 0 : (self == .purple ? 3 : 6) }
}

public struct CollectionEntry: Codable, Equatable {
    public var found: Int = 0
    public var bestQuality: Int = 0
    public var bestValue: Int = 0
}

public struct CuttingSession: Codable, Equatable {
    public var gemID: UUID
    public var scores: [Int]
    public init(gemID: UUID, scores: [Int] = []) { self.gemID = gemID; self.scores = scores }
}

public struct GameState: Codable, Equatable {
    public var schemaVersion = 1
    public var coins = 0
    public var experience = 0
    public var pickaxeLevel = 1
    public var backpackLevel = 1
    public var staminaLevel = 1
    public var deepestRow = 0
    public var inventory: [Gem] = []
    public var collection: [String: CollectionEntry] = [:]
    public var outfit: Outfit = .teal
    public var expedition: Expedition?
    public var cutting: CuttingSession?
    public var ownedPickaxes: [PickaxeKind] = [.iron]
    public var equippedPickaxe: PickaxeKind = .iron
    public var miningPower: Int { pickaxeLevel + equippedPickaxe.bonus }
    public var hasSeenTutorial = false
    public init() {}
    private enum CodingKeys: String, CodingKey {
        case schemaVersion, coins, experience, pickaxeLevel, backpackLevel, staminaLevel,
             deepestRow, inventory, collection, outfit, expedition, cutting, hasSeenTutorial,
             ownedPickaxes, equippedPickaxe
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        coins = try values.decode(Int.self, forKey: .coins)
        experience = try values.decode(Int.self, forKey: .experience)
        pickaxeLevel = try values.decode(Int.self, forKey: .pickaxeLevel)
        backpackLevel = try values.decode(Int.self, forKey: .backpackLevel)
        staminaLevel = try values.decode(Int.self, forKey: .staminaLevel)
        deepestRow = try values.decode(Int.self, forKey: .deepestRow)
        inventory = try values.decode([Gem].self, forKey: .inventory)
        collection = try values.decode([String: CollectionEntry].self, forKey: .collection)
        outfit = try values.decode(Outfit.self, forKey: .outfit)
        expedition = try values.decodeIfPresent(Expedition.self, forKey: .expedition)
        cutting = try values.decodeIfPresent(CuttingSession.self, forKey: .cutting)
        hasSeenTutorial = try values.decode(Bool.self, forKey: .hasSeenTutorial)
        // Existing Swift MVP saves keep all progress; new equipment fields default to iron.
        ownedPickaxes = try values.decodeIfPresent([PickaxeKind].self, forKey: .ownedPickaxes) ?? [.iron]
        equippedPickaxe = try values.decodeIfPresent(PickaxeKind.self, forKey: .equippedPickaxe) ?? .iron
    }
    // Increasing thresholds without a fixed maximum player level.
    public var level: Int { Int((sqrt(1 + Double(experience) / 10) - 1) / 2) }
    public func threshold(for level: Int) -> Int { 40 * level * (level + 1) }
    public var levelProgress: Double {
        Double(experience - threshold(for: level)) / Double(threshold(for: level + 1) - threshold(for: level))
    }
    public var capacity: Int { 8 + (backpackLevel - 1) * 4 }
    public var maximumEnergy: Int { 32 + (staminaLevel - 1) * 8 }
    public func upgradeLevel(_ upgrade: Upgrade) -> Int {
        switch upgrade { case .pickaxe: return pickaxeLevel; case .backpack: return backpackLevel; case .stamina: return staminaLevel }
    }
    public func upgradeCost(_ upgrade: Upgrade) -> Int { let level = upgradeLevel(upgrade); return 60 * level * level }
}

public enum GameError: LocalizedError {
    case message(String)
    public var errorDescription: String? { if case let .message(text) = self { return text }; return nil }
}
