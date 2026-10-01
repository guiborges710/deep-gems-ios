import XCTest
@testable import DeepGemsCore

final class GameEngineTests: XCTestCase {
    func testFirstDiscoveryAndReturnCannotDuplicateLoot() throws {
        var state = GameState()
        try GameEngine.startExpedition(state: &state, seed: 1)
        try GameEngine.act(state: &state, at: .init(column: 2, row: 1))
        XCTAssertEqual(state.expedition?.energy, 31)
        XCTAssertEqual(state.expedition?.carried.count, 1)
        XCTAssertEqual(state.collection["quartz"]?.found, 1)
        GameEngine.returnToBase(state: &state)
        GameEngine.returnToBase(state: &state)
        XCTAssertEqual(state.inventory.count, 1)
        XCTAssertNil(state.expedition)
    }

    func testNonAdjacentTileDoesNotSpendEnergy() throws {
        var state = GameState()
        try GameEngine.startExpedition(state: &state, seed: 2)
        let before = state
        XCTAssertThrowsError(try GameEngine.act(state: &state, at: .init(column: 5, row: 5)))
        XCTAssertEqual(state, before)
    }

    func testFullBackpackDoesNotDestroyGem() throws {
        var state = GameState()
        try GameEngine.startExpedition(state: &state, seed: 3)
        state.expedition?.carried = (0..<state.capacity).map { _ in Gem(kind: .quartz) }
        let before = state
        XCTAssertThrowsError(try GameEngine.act(state: &state, at: .init(column: 2, row: 1)))
        XCTAssertEqual(state, before)
    }

    func testExhaustionStillAllowsReturn() throws {
        var state = GameState()
        try GameEngine.startExpedition(state: &state, seed: 4)
        try GameEngine.act(state: &state, at: .init(column: 2, row: 1))
        state.expedition?.energy = 0
        XCTAssertThrowsError(try GameEngine.act(state: &state, at: .init(column: 2, row: 2)))
        GameEngine.returnToBase(state: &state)
        XCTAssertEqual(state.inventory.count, 1)
        try GameEngine.startExpedition(state: &state, seed: 5)
        XCTAssertEqual(state.expedition?.energy, state.maximumEnergy)
    }

    func testPerfectCutAndSingleSale() throws {
        var state = GameState()
        let gem = Gem(kind: .quartz, purity: 80)
        state.inventory = [gem]
        try GameEngine.beginCutting(state: &state, gemID: gem.id)
        XCTAssertThrowsError(try GameEngine.sell(state: &state, gemID: gem.id))
        for cut in 0..<gem.kind.cutCount {
            _ = try GameEngine.applyCut(state: &state, angle: GameEngine.targetAngle(for: gem, cut: cut))
        }
        XCTAssertNil(state.cutting)
        XCTAssertEqual(state.inventory[0].cutQuality, 100)
        XCTAssertEqual(state.inventory[0].value, gem.value * 4)
        XCTAssertEqual(state.collection["quartz"]?.bestQuality, 100)
        let value = state.inventory[0].value
        try GameEngine.sell(state: &state, gemID: gem.id)
        XCTAssertEqual(state.coins, value)
        XCTAssertThrowsError(try GameEngine.sell(state: &state, gemID: gem.id))
        XCTAssertEqual(state.coins, value)
    }

    func testPoorCutStillHasValueAndCannotBeCutAgain() throws {
        var state = GameState()
        let gem = Gem(kind: .diamond)
        state.inventory = [gem]
        try GameEngine.beginCutting(state: &state, gemID: gem.id)
        for _ in 0..<4 { _ = try GameEngine.applyCut(state: &state, angle: 60) }
        XCTAssertGreaterThan(state.inventory[0].value, 0)
        XCTAssertThrowsError(try GameEngine.beginCutting(state: &state, gemID: gem.id))
        XCTAssertThrowsError(try GameEngine.applyCut(state: &state, angle: .nan))
    }

    func testEmeraldFissureAndGesturePenalty() throws {
        var safe = GameState(); var risky = GameState()
        let gem = Gem(kind: .emerald)
        safe.inventory = [gem]; risky.inventory = [gem]
        try GameEngine.beginCutting(state: &safe, gemID: gem.id)
        try GameEngine.beginCutting(state: &risky, gemID: gem.id)
        _ = try GameEngine.applyCut(state: &safe, angle: -35)
        _ = try GameEngine.applyCut(state: &risky, angle: -35, gestureAccuracy: 0.5)
        XCTAssertEqual(safe.cutting?.scores, [100])
        XCTAssertEqual(risky.cutting?.scores, [50])
    }

    func testUpgradeIsAtomicWhenCoinsInsufficient() throws {
        var state = GameState()
        XCTAssertThrowsError(try GameEngine.upgrade(state: &state, kind: .pickaxe))
        XCTAssertEqual(state.coins, 0)
        XCTAssertEqual(state.pickaxeLevel, 1)
        state.coins = 60
        try GameEngine.upgrade(state: &state, kind: .pickaxe)
        XCTAssertEqual(state.pickaxeLevel, 2)
        XCTAssertEqual(state.coins, 0)
        XCTAssertEqual(state.upgradeCost(.pickaxe), 240)
    }

    func testCosmeticUnlocksAndLevelThresholds() throws {
        var state = GameState()
        XCTAssertEqual(state.level, 0)
        XCTAssertThrowsError(try GameEngine.equip(state: &state, outfit: .purple))
        state.experience = state.threshold(for: 3)
        XCTAssertEqual(state.level, 3)
        XCTAssertEqual(state.levelProgress, 0)
        try GameEngine.equip(state: &state, outfit: .purple)
        XCTAssertEqual(state.outfit, .purple)
    }

    func testLongExpeditionStreamsTilesWithoutUnboundedSave() throws {
        var state = GameState()
        state.staminaLevel = 1000; state.backpackLevel = 1000; state.pickaxeLevel = 20
        try GameEngine.startExpedition(state: &state, seed: 99)
        for row in 1...500 { try GameEngine.act(state: &state, at: .init(column: 2, row: row)) }
        XCTAssertEqual(state.deepestRow, 500)
        XCTAssertLessThanOrEqual(state.expedition?.tiles.count ?? 1000, 110)
        XCTAssertEqual(state.expedition?.player.row, 500)
        XCTAssertTrue(state.expedition?.carried.contains(where: { $0.kind == .diamond }) ?? false)
    }
}
