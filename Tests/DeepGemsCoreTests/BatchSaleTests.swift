import XCTest
@testable import DeepGemsCore

final class BatchSaleTests: XCTestCase {
    func testBatchPaysExactlyOnceAndKeepsUnselectedGemsAndCollection() throws {
        var s = GameState(); s.coins = 10
        let a = Gem(kind: .quartz), b = Gem(kind: .ruby), kept = Gem(kind: .diamond)
        s.inventory = [a, b, kept]; s.collection["quartz"] = CollectionEntry()
        let collection = s.collection
        try GameEngine.sellBatch(state: &s, gemIDs: [a.id, b.id])
        XCTAssertEqual(s.coins, 10 + a.value + b.value)
        XCTAssertEqual(s.inventory, [kept]); XCTAssertEqual(s.collection, collection)
        let before = s
        XCTAssertThrowsError(try GameEngine.sellBatch(state: &s, gemIDs: [a.id, b.id]))
        XCTAssertEqual(s, before)
    }
    func testStaleSelectionDoesNotPartiallySell() {
        var s = GameState(); let a = Gem(kind: .quartz); s.inventory = [a]
        let before = s
        XCTAssertThrowsError(try GameEngine.sellBatch(state: &s, gemIDs: [a.id, UUID()]))
        XCTAssertEqual(s, before)
        XCTAssertThrowsError(try GameEngine.sellBatch(state: &s, gemIDs: []))
        XCTAssertEqual(s, before)
    }
    func testActiveCutAndCoinLimitRejectWholeBatch() throws {
        var s = GameState(); let a = Gem(kind: .quartz), b = Gem(kind: .amethyst)
        s.inventory = [a, b]; try GameEngine.beginCutting(state: &s, gemID: b.id)
        let before = s
        XCTAssertThrowsError(try GameEngine.sellBatch(state: &s, gemIDs: [a.id, b.id]))
        XCTAssertEqual(s, before)
        s.cutting = nil; s.coins = 1_000_000_000
        let full = s
        XCTAssertThrowsError(try GameEngine.sellBatch(state: &s, gemIDs: [a.id]))
        XCTAssertEqual(s, full)
    }
    func testUpgradesCannotChangeCapacityOrEnergyDuringExpedition() throws {
        var s = GameState(); s.coins = 1000
        try GameEngine.startExpedition(state: &s, seed: 710)
        let before = s
        for kind in Upgrade.allCases {
            XCTAssertThrowsError(try GameEngine.upgrade(state: &s, kind: kind))
            XCTAssertEqual(s, before)
        }
    }
}
