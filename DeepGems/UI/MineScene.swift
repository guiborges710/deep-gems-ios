import SpriteKit
import UIKit

@MainActor
final class MineScene: SKScene {
    var onSelect: ((GridPosition) -> Void)?
    private var expedition: Expedition?
    private var outfit: Outfit = .teal
    private var pickaxe: PickaxeKind = .iron
    private var weaponNode: SKSpriteNode?
    private var crystalTextures: [GemKind: SKTexture] = [:]
    private var weaponTextures: [PickaxeKind: SKTexture] = [:]
    private var explorerTextures: [Outfit: SKTexture] = [:]
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
    func render(expedition: Expedition?, outfit: Outfit, pickaxe: PickaxeKind) {
        self.expedition = expedition; self.outfit = outfit; self.pickaxe = pickaxe
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
            if !tile.isEmpty {
                let fissure = CGMutablePath()
                fissure.move(to: CGPoint(x: -tileSize * 0.35, y: tileSize * 0.24))
                fissure.addLine(to: CGPoint(x: -tileSize * 0.06, y: tileSize * 0.16))
                fissure.addLine(to: CGPoint(x: tileSize * 0.12, y: -tileSize * 0.1))
                fissure.addLine(to: CGPoint(x: tileSize * 0.3, y: -tileSize * 0.15))
                let crack = SKShapeNode(path: fissure)
                crack.position = point; crack.strokeColor = UIColor.black.withAlphaComponent(0.3)
                crack.lineWidth = tile.remaining < tile.hardness ? 3 : 1
                addChild(crack)
                let ridge = SKShapeNode(rectOf: CGSize(width: tileSize - 16, height: 2), cornerRadius: 1)
                ridge.fillColor = UIColor.white.withAlphaComponent(0.07); ridge.strokeColor = .clear
                ridge.position = CGPoint(x: point.x, y: point.y + tileSize * 0.34)
                addChild(ridge)
            }
            if let gem = tile.gem, !tile.isEmpty {
                let texture = crystalTextures[gem.kind] ?? SKTexture(image: GameArtwork.gem(gem.kind))
                crystalTextures[gem.kind] = texture
                let crystal = SKSpriteNode(texture: texture)
                crystal.size = CGSize(width: tileSize * 0.64, height: tileSize * 0.7)
                crystal.position = point; crystal.zPosition = 2
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
        player.position = center(for: expedition.player); player.zPosition = 5
        let explorerTexture = explorerTextures[outfit] ?? SKTexture(image: GameArtwork.explorer(outfit))
        explorerTextures[outfit] = explorerTexture
        let body = SKSpriteNode(texture: explorerTexture)
        body.size = CGSize(width: tileSize * 0.75, height: tileSize * 1.13)
        body.position.y = tileSize * 0.17
        player.addChild(body)
        let weaponTexture = weaponTextures[pickaxe] ?? SKTexture(image: GameArtwork.pickaxe(pickaxe))
        weaponTextures[pickaxe] = weaponTexture
        let weapon = SKSpriteNode(texture: weaponTexture)
        weapon.size = CGSize(width: tileSize * 0.7, height: tileSize * 0.7)
        weapon.anchorPoint = CGPoint(x: 0.18, y: 0.15)
        weapon.position = CGPoint(x: tileSize * 0.15, y: -tileSize * 0.05)
        weapon.zRotation = -0.35; weapon.zPosition = 6
        player.addChild(weapon); weaponNode = weapon
        addChild(player)
        // Idle motion is intentionally subtle; frame-by-frame character animation is a later asset pass.
        body.run(.repeatForever(.sequence([.moveBy(x: 0, y: 1.5, duration: 1), .moveBy(x: 0, y: -1.5, duration: 1)])))
    }
    func strike(at position: GridPosition) {
        guard expedition != nil else { return }
        let point = center(for: position)
        weaponNode?.run(.sequence([.rotate(byAngle: 0.8, duration: 0.06), .rotate(byAngle: -1.1, duration: 0.09), .rotate(byAngle: 0.3, duration: 0.1)]))
        let flash = SKShapeNode(circleOfRadius: tileSize * 0.25)
        flash.position = point; flash.fillColor = pickaxe.impactColor.withAlphaComponent(0.7)
        flash.strokeColor = .clear; flash.zPosition = 10
        addChild(flash)
        flash.run(.sequence([.group([.scale(to: 1.8, duration: 0.2), .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
        for index in 0..<8 {
            let chip = SKShapeNode(circleOfRadius: pickaxe == .amethyst ? 2.5 : 1.5)
            chip.position = point; chip.fillColor = pickaxe.impactColor; chip.strokeColor = .clear; chip.zPosition = 11
            let angle = CGFloat(index) * .pi / 4
            addChild(chip)
            chip.run(.sequence([.group([.moveBy(x: cos(angle) * tileSize * 0.5, y: sin(angle) * tileSize * 0.5, duration: 0.3), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        }
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
