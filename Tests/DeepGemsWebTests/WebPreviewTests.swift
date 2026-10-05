import XCTest
import DeepGemsCore
@testable import DeepGemsWebUI

final class WebPreviewTests: XCTestCase {
    func testExportsDocumentAssetsAndHonestStaticScope() throws {
        var state = GameState()
        try GameEngine.startExpedition(state: &state, seed: 710)
        let html = DeepGemsWebRenderer.render(state)
        XCTAssertTrue(html.hasPrefix("<!doctype html>"))
        XCTAssertTrue(html.contains("assets/ExplorerV2.png"))
        XCTAssertTrue(html.contains("assets/CampProgressionAtlas.png"))
        XCTAssertTrue(html.contains("Retrato estático"))
        for route in ["base", "mine", "equipment", "collection"] {
            XCTAssertTrue(html.contains("href=\"#\(route)\""))
            XCTAssertTrue(html.contains("id=\"\(route)\""))
        }
    }
    func testCollectionTextIsEscaped() {
        var state = GameState(); state.relics = ["<script>alert('x')</script>"]
        let html = DeepGemsWebRenderer.render(state)
        XCTAssertFalse(html.contains("<script>alert('x')</script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }
    func testRenderingDoesNotMutateNativeSave() throws {
        var state = GameState()
        try GameEngine.startExpedition(state: &state, seed: 710)
        let before = state
        _ = DeepGemsWebRenderer.render(state)
        XCTAssertEqual(state, before)
    }
}
