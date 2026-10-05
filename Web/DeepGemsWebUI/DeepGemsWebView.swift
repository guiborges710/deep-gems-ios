import Foundation
import DeepGemsCore
import SwiftUIWeb

/// Portable HTML presentation. Navigation is real; mining and purchases remain native app actions.
public struct DeepGemsWebView: WebView {
    public let state: GameState
    public init(state: GameState) { self.state = state }

    public var body: some WebViewContent {
        VStack(alignment: .leading, spacing: 18) {
            Text("DeepGems").font(.largeTitle)
            Text("Prévia web • SwiftUIWeb 0.1.0").font(.caption).foregroundColor(.yellow)
            Text("Retrato estático do progresso. Escavar, comprar e animar o personagem exigem a versão nativa.")
                .font(.caption).cssClass("notice")
            HStack(spacing: 14) {
                NavigationLink("Base", destination: "base")
                NavigationLink("Mina", destination: "mine")
                NavigationLink("Itens", destination: "equipment")
                NavigationLink("Coleção", destination: "collection")
            }.cssClass("navigation")
            VStack(alignment: .leading, spacing: 12) {
                Text("Sua base").font(.title)
                Text("Estágio \(state.campLevel) • \(state.coins) moedas • recorde \(state.deepestRow) m")
                CampArt(level: state.campLevel)
                if let goal = state.currentGoal {
                    Card {
                        Text(goal.title).font(.headline)
                        Text("\(min(goal.progress, goal.target)) / \(goal.target) • recompensa \(goal.reward) moedas")
                    }
                }
                Text("Cobre \(state.copper) • Ferro \(state.iron)").foregroundColor(.yellow)
            }.id("base").cssClass("section")
            VStack(alignment: .leading, spacing: 12) {
                Text("Sua mina").font(.title)
                Text("\(MineRegion.at(state.expedition?.player.row ?? state.deepestRow).name) • \(state.expedition?.player.row ?? state.deepestRow) m")
                MineSnapshot(state: state)
                Text("Blocos e túneis vêm do motor Swift do jogo. Esta imagem não aceita escavação.").font(.caption)
            }.id("mine").cssClass("section")
            VStack(alignment: .leading, spacing: 12) {
                Text("Equipamentos").font(.title)
                HStack(spacing: 12) {
                    Image("assets/ExplorerV2.png", alt: "Explorador do DeepGems").frame(width: 90, height: 135)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(state.equippedPickaxe.name).font(.headline)
                        Text("Mochila Nv. \(state.backpackLevel) • capacidade \(state.capacity)")
                        Text("Energia \(state.expedition?.energy ?? state.maximumEnergy) / \(state.maximumEnergy)")
                    }
                }
                Text("Picaretas compradas: \(state.ownedPickaxes.map { $0.name }.joined(separator: ", "))").font(.caption)
            }.id("equipment").cssClass("section")
            VStack(alignment: .leading, spacing: 12) {
                Text("Coleção e inventário").font(.title)
                if state.relics.isEmpty { Text("Nenhuma descoberta rara registrada.").font(.caption) }
                for relic in state.relics { Text(relic) }
                for kind in GemKind.allCases {
                    let gems = state.inventory.filter { $0.kind == kind }
                    HStack(spacing: 10) {
                        Text(kind.name)
                        Spacer()
                        Text("\(gems.count) • \(gems.reduce(0) { $0 + $1.value }) moedas")
                    }
                }
            }.id("collection").cssClass("section")
        }.padding(18).foregroundColor(.white).background(Color(hex: "071321"))
    }
}

private struct CampArt: WebViewContent {
    let level: Int
    func renderHTML() -> String {
        let position = min(2, max(0, level - 1)) * 50
        return "<div class=\"camp-art\" role=\"img\" aria-label=\"Acampamento estágio \(level)\" style=\"background-position:\(position)% center\"></div>"
    }
}

private struct MineSnapshot: WebViewContent {
    let state: GameState
    func renderHTML() -> String {
        guard let expedition = state.expedition else {
            return "<p>Sem expedição ativa neste progresso. Entre na mina no app e exporte novamente.</p>"
        }
        let first = max(0, expedition.player.row - 2)
        let tiles = Dictionary(uniqueKeysWithValues: expedition.tiles.map { ($0.position, $0) })
        var html = "<div class=\"mine-board\" aria-label=\"Corte da mina\">"
        for row in first..<(first + 6) {
            for column in 0..<GameEngine.columns {
                let position = GridPosition(column: column, row: row)
                guard let tile = tiles[position] else { html += "<div class=\"tile unknown\" title=\"Não explorado\"></div>"; continue }
                let index = tile.isEmpty ? 2 : tile.hardness % 3
                let classes = "tile " + (tile.isEmpty ? "dug" : "rock")
                html += "<div class=\"\(classes)\" title=\"\(row) m • resistência \(tile.remaining)\" style=\"background-position:\(Double(index) / 3 * 100)% center\">"
                if position == expedition.player { html += "<img class=\"miner\" src=\"assets/ExplorerV2.png\" alt=\"Jogador\">" }
                else if let gem = tile.gem, !tile.isEmpty {
                    let i = GemKind.allCases.firstIndex(of: gem.kind) ?? 0
                    html += "<span class=\"gem\" role=\"img\" aria-label=\"\(gem.kind.name)\" style=\"background-position:\(i * 25)% center\"></span>"
                }
                for structure in state.structures where structure.position == position {
                    let index = structure.kind == .ladder ? 0 : (structure.kind == .light ? 1 : 2)
                    html += "<span class=\"structure\" role=\"img\" aria-label=\"\(structure.kind.name)\" style=\"background-position:\(index * 50)% center\"></span>"
                }
                html += "</div>"
            }
        }
        return html + "</div>"
    }
}

public enum DeepGemsWebRenderer {
    public static func render(_ state: GameState) -> String {
        IPhoneMockupRenderer.render(DeepGemsWebView(state: state), title: "DeepGems — Windows Preview", additionalCSS: css)
    }
    private static let css = """
    .app-root { background:#071321; color:#fff; }
    .notice { border-left:3px solid #eeb443; padding:10px; background:#172338; }
    .navigation { flex-wrap:wrap; position:sticky; top:0; background:#071321; padding:10px 0; z-index:10; }
    .navigation a { color:#ffd471!important; font-weight:700; }
    .section { scroll-margin-top:60px; width:100%; border-top:1px solid #394451; padding-top:16px; }
    .sw-card { background:#172338!important; color:#fff; }
    .camp-art { width:100%; aspect-ratio:1; border-radius:18px; background-image:url('assets/CampProgressionAtlas.png'); background-size:300% 100%; }
    .mine-board { display:grid; grid-template-columns:repeat(6,minmax(0,1fr)); width:100%; gap:2px; }
    .tile { aspect-ratio:1; position:relative; border-radius:6px; background-image:url('assets/TerrainAtlas.png'); background-size:400% 100%; }
    .dug { background-color:#172338; background-blend-mode:multiply; }
    .unknown { background:#02060d; }
    .miner { height:125%; width:auto; position:absolute; bottom:0; left:8%; z-index:3; }
    .gem,.structure { position:absolute; inset:6%; background-size:500% 100%; background-image:url('assets/GemAtlas.png'); }
    .structure { background-image:url('assets/MineStructureAtlas.png'); background-size:300% 100%; }
    """
}
