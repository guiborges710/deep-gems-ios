import Foundation
import DeepGemsCore
import DeepGemsWebUI

struct PreviewError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

func exportPreview() throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments.contains("--help") {
        print("swift run DeepGemsWebPreview [--output WebPreview] [--save caminho/progress-v1.json] [--assets-root DeepGems/Resources/Assets.xcassets]")
        return
    }
    var output = "WebPreview"
    var save: String?
    var assetsRoot = "DeepGems/Resources/Assets.xcassets"
    var index = 0
    while index < arguments.count {
        let option = arguments[index]
        guard ["--output", "--save", "--assets-root"].contains(option), index + 1 < arguments.count else {
            throw PreviewError(message: "Argumento inválido ou sem valor: \(option). Use --help.")
        }
        let value = arguments[index + 1]
        switch option { case "--output": output = value; case "--save": save = value; default: assetsRoot = value }
        index += 2
    }
    var state: GameState
    if let save {
        let url = URL(fileURLWithPath: save)
        state = try JSONDecoder().decode(GameState.self, from: Data(contentsOf: url))
        try SaveStore(directory: url.deletingLastPathComponent()).validate(state)
    } else {
        state = GameState()
        state.coins = 1250; state.experience = 650; state.campLevel = 2
        state.backpackLevel = 2; state.pickaxeLevel = 10
        state.ownedPickaxes = [.iron, .copper]; state.equippedPickaxe = .copper
        state.inventory = [Gem(kind: .quartz), Gem(kind: .amethyst)]
        try GameEngine.startExpedition(state: &state, seed: 710)
        for row in 1...12 { try GameEngine.act(state: &state, at: .init(column: 2, row: row)) }
        Progression.settle(&state)
    }
    let names = ["CampProgressionAtlas", "ExplorerV2", "TerrainAtlas", "GemAtlas", "MineStructureAtlas"]
    let manager = FileManager.default
    let source = URL(fileURLWithPath: assetsRoot, isDirectory: true)
    // Fail before creating a misleading preview with missing art.
    for name in names {
        let file = source.appendingPathComponent("\(name).imageset/asset.png")
        guard manager.fileExists(atPath: file.path) else { throw PreviewError(message: "Asset ausente: \(file.path). Execute na raiz do repositório ou use --assets-root.") }
    }
    let folder = URL(fileURLWithPath: output, isDirectory: true)
    let assets = folder.appendingPathComponent("assets", isDirectory: true)
    try manager.createDirectory(at: assets, withIntermediateDirectories: true)
    for name in names {
        let data = try Data(contentsOf: source.appendingPathComponent("\(name).imageset/asset.png"))
        try data.write(to: assets.appendingPathComponent("\(name).png"), options: .atomic)
    }
    let html = folder.appendingPathComponent("preview.html")
    try DeepGemsWebRenderer.render(state).write(to: html, atomically: true, encoding: .utf8)
    print("Prévia gerada: \(html.path)")
    print("Abra preview.html no navegador. HTML estático: esta integração não executa SpriteKit ou compras/escavações.")
}

do { try exportPreview() }
catch {
    FileHandle.standardError.write(Data("Erro: \(error.localizedDescription)\n".utf8))
    exit(1)
}
