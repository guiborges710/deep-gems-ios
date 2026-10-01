import XCTest
@testable import DeepGemsCore

final class EquipmentTests: XCTestCase {
    func testPurchaseDeductsCoinsAndEquipsWithoutDoubleCharge() throws {
        var state = GameState(); state.coins = 500
        try GameEngine.buyPickaxe(state: &state, kind: .copper)
        XCTAssertEqual(state.coins, 320)
        XCTAssertEqual(state.equippedPickaxe, .copper)
        XCTAssertEqual(state.miningPower, 3)
        XCTAssertEqual(state.ownedPickaxes, [.iron, .copper])
        let before = state
        XCTAssertThrowsError(try GameEngine.buyPickaxe(state: &state, kind: .copper))
        XCTAssertEqual(state, before)
    }
    func testInsufficientCoinsAndUnownedEquipLeaveStateUnchanged() throws {
        var state = GameState(); state.coins = 50
        let before = state
        XCTAssertThrowsError(try GameEngine.buyPickaxe(state: &state, kind: .amethyst))
        XCTAssertThrowsError(try GameEngine.equipPickaxe(state: &state, kind: .amethyst))
        XCTAssertEqual(state, before)
    }
    func testWeaponAndExistingUpgradeCombine() throws {
        var state = GameState(); state.coins = 1000
        try GameEngine.buyPickaxe(state: &state, kind: .amethyst)
        try GameEngine.upgrade(state: &state, kind: .pickaxe)
        XCTAssertEqual(state.miningPower, 7)
        try GameEngine.equipPickaxe(state: &state, kind: .iron)
        XCTAssertEqual(state.miningPower, 2)
        XCTAssertEqual(state.coins, 290)
    }
    func testCannotBuyOrSwitchEquipmentDuringExpedition() throws {
        var state = GameState(); state.coins = 1000
        try GameEngine.buyPickaxe(state: &state, kind: .copper)
        try GameEngine.startExpedition(state: &state, seed: 42)
        let before = state
        XCTAssertThrowsError(try GameEngine.buyPickaxe(state: &state, kind: .amethyst))
        XCTAssertThrowsError(try GameEngine.equipPickaxe(state: &state, kind: .iron))
        XCTAssertEqual(state, before)
    }
    func testEquippedPowerActuallyChangesMiningDamage() throws {
        var state = GameState(); state.coins = 1000
        try GameEngine.buyPickaxe(state: &state, kind: .amethyst)
        try GameEngine.startExpedition(state: &state, seed: 22)
        try GameEngine.act(state: &state, at: .init(column: 2, row: 1))
        let index = try XCTUnwrap(state.expedition?.tiles.firstIndex { $0.position == GridPosition(column: 2, row: 2) })
        state.expedition?.tiles[index].remaining = 6
        state.expedition?.tiles[index].hardness = 6
        try GameEngine.act(state: &state, at: .init(column: 2, row: 2))
        XCTAssertEqual(state.expedition?.player.row, 2)
    }
    func testLegacySaveDefaultsEquipmentWithoutLosingProgress() throws {
        var state = GameState(); state.coins = 456; state.experience = 900; state.pickaxeLevel = 4
        state.inventory = [Gem(kind: .ruby)]
        try GameEngine.startExpedition(state: &state, seed: 5)
        try GameEngine.act(state: &state, at: .init(column: 2, row: 1))
        let encoded = try JSONEncoder().encode(state)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "ownedPickaxes"); object.removeValue(forKey: "equippedPickaxe")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(GameState.self, from: legacy)
        XCTAssertEqual(restored, state)
        XCTAssertEqual(restored.ownedPickaxes, [.iron])
        XCTAssertEqual(restored.coins, 456)
        XCTAssertEqual(restored.pickaxeLevel, 4)
    }
    func testPurchasedEquipmentSurvivesSaveAndInvalidEquipmentIsRejected() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let saves = SaveStore(directory: directory)
        var state = GameState(); state.coins = 800
        try GameEngine.buyPickaxe(state: &state, kind: .amethyst)
        try saves.save(state)
        XCTAssertEqual(try saves.load().state, state)
        state.ownedPickaxes = [.iron]
        XCTAssertThrowsError(try saves.save(state))
        XCTAssertEqual(try saves.load().state.equippedPickaxe, .amethyst)
    }
}
