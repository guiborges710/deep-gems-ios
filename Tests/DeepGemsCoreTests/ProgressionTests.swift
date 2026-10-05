import XCTest
@testable import DeepGemsCore

final class ProgressionTests: XCTestCase {
    private func miner() -> GameState {
        var s = GameState(); s.pickaxeLevel = 20; s.staminaLevel = 100; s.backpackLevel = 100
        return s
    }
    func testReturningAndReopeningKeepsTunnelAndDoesNotRespawnLoot() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let saves = SaveStore(directory: directory)
        var state = GameState()
        try GameEngine.startExpedition(state: &state, seed: 42)
        try GameEngine.act(state: &state, at: .init(column: 2, row: 1))
        GameEngine.returnToBase(state: &state)
        try saves.save(state)
        state = try saves.load().state
        try GameEngine.startExpedition(state: &state, seed: 999)
        XCTAssertEqual(state.expedition?.seed, 42)
        try GameEngine.act(state: &state, at: .init(column: 2, row: 1))
        XCTAssertEqual(state.expedition?.energy, 32)
        XCTAssertEqual(state.expedition?.carried.count, 0)
        XCTAssertEqual(state.inventory.count, 1)
        XCTAssertEqual(state.iron, 1)
    }
    func testPartialDamageSurvivesReturn() throws {
        var s = GameState()
        try GameEngine.startExpedition(state: &s, seed: 42)
        let position = GridPosition(column: 1, row: 1)
        try GameEngine.act(state: &s, at: .init(column: 1, row: 0))
        let tile = try XCTUnwrap(s.expedition?.tiles.first { $0.position == position })
        try GameEngine.act(state: &s, at: position)
        let expected = max(0, tile.remaining - s.miningPower)
        GameEngine.returnToBase(state: &s)
        try GameEngine.startExpedition(state: &s, seed: 99)
        XCTAssertEqual(s.expedition?.tiles.first { $0.position == position }?.remaining, expected)
    }
    func testLadderMakesAscentPossibleWithZeroEnergy() throws {
        var s = GameState()
        try GameEngine.startExpedition(state: &s, seed: 1)
        try GameEngine.act(state: &s, at: .init(column: 2, row: 1))
        let before = s
        XCTAssertThrowsError(try GameEngine.act(state: &s, at: .init(column: 2, row: 0)))
        XCTAssertEqual(s, before)
        try GameEngine.build(state: &s, kind: .ladder)
        XCTAssertEqual(s.iron, 0)
        s.expedition?.energy = 0
        try GameEngine.act(state: &s, at: .init(column: 2, row: 0))
        XCTAssertEqual(s.expedition?.player.row, 0)
        XCTAssertEqual(s.expedition?.energy, 0)
    }
    func testUnaffordableAndDuplicateConstructionAreAtomic() throws {
        var s = GameState()
        try GameEngine.startExpedition(state: &s, seed: 1)
        try GameEngine.act(state: &s, at: .init(column: 2, row: 1))
        let before = s
        XCTAssertThrowsError(try GameEngine.build(state: &s, kind: .elevator))
        XCTAssertEqual(s, before)
        try GameEngine.build(state: &s, kind: .ladder)
        let built = s
        XCTAssertThrowsError(try GameEngine.build(state: &s, kind: .ladder))
        XCTAssertEqual(s, built)
    }
    func testDeepTunnelStreamingElevatorAndLighting() throws {
        var s = miner()
        try GameEngine.startExpedition(state: &s, seed: 9)
        for row in 1...35 { try GameEngine.act(state: &s, at: .init(column: 2, row: row)) }
        s.coins = 500; s.iron = 20; s.copper = 10
        XCTAssertFalse(s.isLit(.init(column: 2, row: 35)))
        try GameEngine.build(state: &s, kind: .light)
        XCTAssertTrue(s.isLit(.init(column: 2, row: 35)))
        XCTAssertEqual(s.copper, 8)
        try GameEngine.build(state: &s, kind: .elevator)
        try GameEngine.travel(state: &s, to: .init(column: 2, row: 0))
        XCTAssertTrue(s.expedition?.tiles.first { $0.position == GridPosition(column: 2, row: 1) }?.isEmpty ?? false)
        try GameEngine.travel(state: &s, to: .init(column: 2, row: 35))
        XCTAssertEqual(s.expedition?.player.row, 35)
        XCTAssertLessThanOrEqual(s.expedition?.tiles.count ?? 1000, 110)
        let before = s
        XCTAssertThrowsError(try GameEngine.travel(state: &s, to: .init(column: 0, row: 100)))
        XCTAssertEqual(s, before)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let saves = SaveStore(directory: directory)
        try saves.save(s)
        XCTAssertEqual(try saves.load().state, s)
    }
    func testRelicAndSecretChamberArePermanent() throws {
        var s = miner()
        try GameEngine.startExpedition(state: &s, seed: 9)
        for row in 1...18 { try GameEngine.act(state: &s, at: .init(column: 2, row: row)) }
        try GameEngine.act(state: &s, at: .init(column: 3, row: 18))
        try GameEngine.act(state: &s, at: Progression.secretEntrance)
        let position = GridPosition(column: 5, row: 18)
        XCTAssertEqual(s.expedition?.tiles.first { $0.position == position }?.gem?.purity, 100)
        try GameEngine.act(state: &s, at: position)
        XCTAssertTrue(s.relics.contains("Ídolo da sala secreta"))
        GameEngine.returnToBase(state: &s)
        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(restored.relics, s.relics)
        XCTAssertTrue(restored.mineChanges.first { $0.position == position }?.isEmpty ?? false)
    }
    func testCampCostsTierChangesAndGoalRewardOnlyOnce() throws {
        var s = GameState(); s.coins = 60
        try GameEngine.upgrade(state: &s, kind: .backpack)
        XCTAssertEqual(s.characterTier, 2)
        XCTAssertEqual(s.coins, 30)
        Progression.settle(&s)
        XCTAssertEqual(s.coins, 30)
        s.coins = 500; s.iron = 20
        try GameEngine.improveCamp(state: &s)
        XCTAssertEqual(s.campLevel, 2)
        XCTAssertEqual(s.coins, 440)
        XCTAssertEqual(s.iron, 17)
        let before = s
        XCTAssertThrowsError(try GameEngine.improveCamp(state: &s))
        XCTAssertEqual(s, before)
        s.deepestRow = 24
        try GameEngine.improveCamp(state: &s)
        XCTAssertEqual(s.campLevel, 3)
        s.backpackLevel = 3
        XCTAssertEqual(s.characterTier, 3)
    }
    func testLegacyActiveSaveAdoptsSeedWithoutLosingEquipmentOrLoot() throws {
        var s = GameState(); s.coins = 456
        try GameEngine.startExpedition(state: &s, seed: 7)
        try GameEngine.act(state: &s, at: .init(column: 2, row: 1))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as? [String: Any])
        for key in ["mineSeed", "mineChanges", "structures", "copper", "iron", "campLevel", "relics", "completedGoals"] { json.removeValue(forKey: key) }
        let restored = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(restored.coins, 456)
        XCTAssertEqual(restored.expedition, s.expedition)
        XCTAssertEqual(restored.mineSeed, 7)
        XCTAssertEqual(restored.campLevel, 1)
        XCTAssertTrue(restored.mineChanges.first { $0.position == GridPosition(column: 2, row: 1) }?.isEmpty ?? false)
    }
}

final class EquipmentAttachmentTests: XCTestCase {
    func testGripStaysAtHandForEveryToolAndDisplaySize() {
        for kind in PickaxeKind.allCases {
            for bodyHeight in [54.0, 155.0, 320.0] {
                for aspect in [0.95, 1.0, 1.05] {
                    let bodyWidth = bodyHeight * 2 / 3
                    let anchor = MinerEquipmentRig.grip(kind)
                    let center = MinerEquipmentRig.toolCenter(kind: kind, bodyWidth: bodyWidth, bodyHeight: bodyHeight, toolAspect: aspect)
                    let height = bodyHeight * MinerEquipmentRig.toolHeight
                    let width = height * aspect
                    // Actual top-left image location plus its normalized anchor must land on the glove.
                    XCTAssertEqual(center.x - width / 2 + anchor.x * width, (MinerEquipmentRig.handX - 0.5) * bodyWidth, accuracy: 0.000001)
                    XCTAssertEqual(center.y - height / 2 + anchor.y * height, (MinerEquipmentRig.handY - 0.5) * bodyHeight, accuracy: 0.000001)
                    // SpriteKit flips Y, but its anchor represents that same glove point.
                    let spriteBottom = -(MinerEquipmentRig.handY - 0.5) * bodyHeight - (1 - anchor.y) * height
                    XCTAssertEqual(-(spriteBottom + (1 - anchor.y) * height), center.y - height / 2 + anchor.y * height, accuracy: 0.000001)
                }
            }
        }
    }
    func testEachModelHasItsOwnGripOnTheLowerShaft() {
        let anchors = PickaxeKind.allCases.map { MinerEquipmentRig.grip($0) }
        XCTAssertEqual(Set(anchors.map(\.x)).count, 3)
        for anchor in anchors {
            XCTAssertTrue((0.19...0.23).contains(anchor.x))
            XCTAssertTrue((0.72...0.8).contains(anchor.y))
        }
    }
}
