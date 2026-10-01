import XCTest
@testable import DeepGemsCore

final class SaveStoreTests: XCTestCase {
    private var directory: URL!
    private var store: SaveStore!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = SaveStore(directory: directory)
    }
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }
    func testNewGameAndRoundTripWithActiveExpedition() throws {
        XCTAssertEqual(try store.load().state.level, 0)
        var state = GameState()
        try GameEngine.startExpedition(state: &state, seed: 42)
        try GameEngine.act(state: &state, at: .init(column: 2, row: 1))
        try store.save(state)
        XCTAssertEqual(try store.load().state, state)
    }
    func testInterruptedCutCanResume() throws {
        var state = GameState()
        let gem = Gem(kind: .ruby)
        state.inventory = [gem]
        try GameEngine.beginCutting(state: &state, gemID: gem.id)
        _ = try GameEngine.applyCut(state: &state, angle: -35)
        try store.save(state)
        var restored = try store.load().state
        _ = try GameEngine.applyCut(state: &restored, angle: 10)
        _ = try GameEngine.applyCut(state: &restored, angle: 40)
        XCTAssertEqual(restored.inventory[0].cutQuality, 100)
    }
    func testCorruptMainRestoresPreviousSnapshot() throws {
        var state = GameState(); state.coins = 10
        try store.save(state)
        state.coins = 20; try store.save(state)
        try Data("corrupt".utf8).write(to: store.saveURL)
        let restored = try store.load()
        XCTAssertTrue(restored.recoveredBackup)
        XCTAssertEqual(restored.state.coins, 10)
        try store.save(restored.state)
        XCTAssertEqual(try store.load().state.coins, 10)
    }
    func testBothCorruptFilesArePreserved() throws {
        try store.save(GameState()); try store.save(GameState())
        let corrupt = Data("corrupt".utf8)
        try corrupt.write(to: store.saveURL); try corrupt.write(to: store.backupURL)
        XCTAssertThrowsError(try store.load())
        XCTAssertEqual(try Data(contentsOf: store.saveURL), corrupt)
        XCTAssertEqual(try Data(contentsOf: store.backupURL), corrupt)
    }
    func testInvalidStateCannotOverwriteValidSave() throws {
        try store.save(GameState())
        var invalid = GameState(); invalid.coins = -1
        XCTAssertThrowsError(try store.save(invalid))
        XCTAssertEqual(try store.load().state.coins, 0)
    }
    func testUnknownSchemaIsNotSilentlyReset() throws {
        try store.save(GameState())
        var unknown = GameState(); unknown.schemaVersion = 2
        try JSONEncoder().encode(unknown).write(to: store.saveURL)
        XCTAssertThrowsError(try store.load())
    }
    func testResetArchivesOldProgress() throws {
        var state = GameState(); state.coins = 100
        try store.save(state)
        try store.archiveAndReset()
        XCTAssertEqual(try store.load().state.coins, 0)
        let directories = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let archive = try XCTUnwrap(directories.first { $0.lastPathComponent.hasPrefix("archive-") })
        let old = try JSONDecoder().decode(GameState.self, from: Data(contentsOf: archive.appendingPathComponent("progress-v1.json")))
        XCTAssertEqual(old.coins, 100)
    }
}
