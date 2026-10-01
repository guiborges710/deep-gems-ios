import SpriteKit
import UIKit

final class MineScene: SKScene {
    var onSelect: ((GridPosition) -> Void)?
    private var expedition: Expedition?
    private var outfit: Outfit = .teal
    private var visibleFirstRow = 0
    private var tileSize: CGFloat = 45
    private var boardOrigin = CGPoint.zero
    private let visibleRows = 8

    override init(size: CGSize = CGSize(width: 360, height: 480)) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.035, green: 0.065, blue: 0.12, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("Use init(size:)") }
    override func didChangeSize(_ oldSize: CGSize) { redraw() }
    func render(expedition: Expedition?, outfit: Outfit) {
        self.expedition = expedition; self.outfit = outfit
        redraw()
    }
    private func redraw() {
        removeAllChildren()
        guard let expedition else { return }
        tileSize = min(size.width / CGFloat(GameEngine.columns), size.height / CGFloat(visibleRows))
        boardOrigin = CGPoint(x: (size.width - tileSize * CGFloat(GameEngine.columns)) / 2, y: (size.height - tileSize * CGFloat(visibleRows)) / 2)
        visibleFirstRow = max(0, expedition.player.row - 2)
        let adjacent = expedition.tiles.filter { $0.position.isAdjacent(to: expedition.player) }.map(\.position)
        for tile in expedition.tiles where (visibleFirstRow..<(visibleFirstRow + visibleRows)).contains(tile.position.row) {
            let point = center(for: tile.position)
            let rect = SKShapeNode(rectOf: CGSize(width: tileSize - 4, height: tileSize - 4), cornerRadius: 7)
            rect.position = point
            rect.fillColor = tile.isEmpty ? UIColor(white: 0.08, alpha: 1) : UIColor(red: 0.21 + CGFloat(tile.hardness % 3) * 0.03, green: 0.23, blue: 0.28, alpha: 1)
            rect.strokeColor = adjacent.contains(tile.position) ? .systemOrange : UIColor(white: 0.35, alpha: 0.2)
            rect.lineWidth = adjacent.contains(tile.position) ? 2 : 1
            addChild(rect)
            if let gem = tile.gem, !tile.isEmpty {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: tileSize * 0.26))
                path.addLine(to: CGPoint(x: tileSize * 0.19, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -tileSize * 0.25))
                path.addLine(to: CGPoint(x: -tileSize * 0.19, y: 0)); path.closeSubpath()
                let crystal = SKShapeNode(path: path)
                crystal.fillColor = gem.kind.uiColor; crystal.strokeColor = .white.withAlphaComponent(0.6)
                crystal.position = point; crystal.glowWidth = 2
                addChild(crystal)
            }
            if !tile.isEmpty && tile.remaining < tile.hardness {
                let health = SKShapeNode(rectOf: CGSize(width: (tileSize - 14) * CGFloat(tile.remaining) / CGFloat(tile.hardness), height: 3), cornerRadius: 1)
                health.position = CGPoint(x: point.x, y: point.y - tileSize * 0.33)
                health.fillColor = .systemOrange; health.strokeColor = .clear
                addChild(health)
            }
        }
        let player = SKNode()
        player.position = center(for: expedition.player)
        let body = SKShapeNode(rectOf: CGSize(width: tileSize * 0.4, height: tileSize * 0.4), cornerRadius: 6)
        body.fillColor = outfit.uiColor; body.strokeColor = .clear; body.position.y = -tileSize * 0.1
        player.addChild(body)
        let head = SKShapeNode(circleOfRadius: tileSize * 0.15)
        head.fillColor = UIColor(red: 0.94, green: 0.71, blue: 0.48, alpha: 1); head.strokeColor = .clear
        head.position.y = tileSize * 0.14; player.addChild(head)
        let helmet = SKShapeNode(rectOf: CGSize(width: tileSize * 0.4, height: tileSize * 0.14), cornerRadius: 4)
        helmet.fillColor = .systemYellow; helmet.strokeColor = .clear; helmet.position.y = tileSize * 0.24
        player.addChild(helmet)
        let lamp = SKShapeNode(circleOfRadius: 3); lamp.fillColor = .white; lamp.strokeColor = .clear
        lamp.glowWidth = 4; lamp.position.y = tileSize * 0.25; player.addChild(lamp)
        addChild(player)
    }
    private func center(for position: GridPosition) -> CGPoint {
        CGPoint(x: boardOrigin.x + (CGFloat(position.column) + 0.5) * tileSize,
                y: boardOrigin.y + (CGFloat(visibleRows - (position.row - visibleFirstRow)) - 0.5) * tileSize)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let x = point.x - boardOrigin.x; let y = point.y - boardOrigin.y
        guard x >= 0, y >= 0, x < tileSize * CGFloat(GameEngine.columns), y < tileSize * CGFloat(visibleRows) else { return }
        let column = Int(x / tileSize)
        let row = visibleFirstRow + visibleRows - 1 - Int(y / tileSize)
        onSelect?(.init(column: column, row: row))
    }
}

private extension GemKind {
    var uiColor: UIColor {
        switch self { case .quartz: return .lightGray; case .amethyst: return .systemPurple; case .emerald: return .systemGreen; case .ruby: return .systemPink; case .diamond: return .systemCyan }
    }
}
private extension Outfit {
    var uiColor: UIColor { switch self { case .teal: return .systemTeal; case .purple: return .systemPurple; case .orange: return .systemOrange } }
}
